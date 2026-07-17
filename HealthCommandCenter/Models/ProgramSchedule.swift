import Foundation

struct Program: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
}

struct ProgramWeek: Hashable {
    let program: Program
    let weekStartDate: Date
    let weekEndDate: Date
    let sessions: [PlannedSession]

    var completedCount: Int {
        sessions.filter { $0.status == .completed }.count
    }

    var plannedCount: Int {
        sessions.filter { !$0.isOptional }.count
    }

    var summaryText: String {
        "\(completedCount)/\(plannedCount) planned sessions complete"
    }
}

struct PlannedSession: Identifiable, Hashable {
    let id: String
    let dateKey: String
    let title: String
    let workoutID: String
    let workoutTitle: String
    let category: WorkoutCategory
    let status: SessionStatus
    let adjustmentReason: ScheduleAdjustmentReason?
    let recommendedVersion: WorkoutVersionType
    let note: String
    let isOptional: Bool
}

enum SessionStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case planned = "Planned"
    case recommendedToday = "Recommended Today"
    case downgraded = "Downgraded"
    case completed = "Completed"
    case moved = "Moved"
    case optional = "Optional"

    var id: String { rawValue }
}

enum ScheduleAdjustmentReason: String, Codable, CaseIterable, Identifiable, Hashable {
    case readiness = "Readiness"
    case recovery = "Recovery"
    case nightShift = "Night Shift"
    case newBaby = "New-Baby"
    case manualReschedule = "Manual Reschedule"
    case optionalDay = "Optional Day"

    var id: String { rawValue }
}

struct ProgramScheduleOverride: Codable, Identifiable, Hashable {
    let id: String
    var sessionID: String
    var dateKey: String
    var reason: ScheduleAdjustmentReason
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        sessionID: String,
        dateKey: String,
        reason: ScheduleAdjustmentReason,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.sessionID = sessionID
        self.dateKey = dateKey
        self.reason = reason
        self.updatedAt = updatedAt
    }
}

struct AdaptiveProgramScheduler {
    static let defaultProgram = Program(
        id: "brian-rebuild-3-day",
        name: "Brian Rebuild Program",
        description: "Three full-body strength sessions with optional recovery and conditioning days."
    )

    static func currentWeek(
        readiness: ReadinessCategory?,
        recoveryStatus: RecoveryStatus,
        programPhase: ProgramPhase,
        workoutTimePreference: WorkoutTimePreference,
        exerciseLogs: [ExerciseLog],
        overrides: [ProgramScheduleOverride],
        calendar: Calendar = .current,
        today: Date = Date()
    ) -> ProgramWeek {
        let interval = calendar.dateInterval(of: .weekOfYear, for: today)
        let weekStart = interval?.start ?? calendar.startOfDay(for: today)
        let weekEnd = interval?.end.addingTimeInterval(-1) ?? today
        let templates = sessionTemplates(programPhase: programPhase, workoutTimePreference: workoutTimePreference)
        let sessions = templates.map { template in
            plannedSession(
                template: template,
                weekStart: weekStart,
                today: today,
                readiness: readiness,
                recoveryStatus: recoveryStatus,
                programPhase: programPhase,
                logs: exerciseLogs,
                overrides: overrides,
                calendar: calendar
            )
        }
        .sorted { left, right in
            if left.dateKey == right.dateKey { return left.title < right.title }
            return left.dateKey < right.dateKey
        }

        return ProgramWeek(program: defaultProgram, weekStartDate: weekStart, weekEndDate: weekEnd, sessions: sessions)
    }
}

private extension AdaptiveProgramScheduler {
    struct SessionTemplate {
        let key: String
        let offset: Int
        let workout: WorkoutPlan
        let isOptional: Bool
    }

    static func sessionTemplates(programPhase: ProgramPhase, workoutTimePreference: WorkoutTimePreference) -> [SessionTemplate] {
        let strengthOffsets: [Int]
        switch programPhase {
        case .nightShift:
            strengthOffsets = [0, 2, 5]
        case .newBaby:
            strengthOffsets = [0, 3, 6]
        case .dayShift, .normalRoutine:
            strengthOffsets = [0, 2, 4]
        }

        return [
            SessionTemplate(key: "strength-a", offset: strengthOffsets[0], workout: WorkoutLibrary.starterProgram[0], isOptional: false),
            SessionTemplate(key: "recovery-a", offset: 1, workout: WorkoutLibrary.libraryWorkouts.first { $0.id == "recovery-mobility-12" } ?? WorkoutLibrary.starterProgram[0], isOptional: true),
            SessionTemplate(key: "strength-b", offset: strengthOffsets[1], workout: WorkoutLibrary.starterProgram[1], isOptional: false),
            SessionTemplate(key: "conditioning-a", offset: 5, workout: WorkoutLibrary.libraryWorkouts.first { $0.id == "bike-conditioning-15" } ?? WorkoutLibrary.starterProgram[2], isOptional: true),
            SessionTemplate(key: "strength-c", offset: strengthOffsets[2], workout: WorkoutLibrary.starterProgram[2], isOptional: false)
        ]
    }

    static func plannedSession(
        template: SessionTemplate,
        weekStart: Date,
        today: Date,
        readiness: ReadinessCategory?,
        recoveryStatus: RecoveryStatus,
        programPhase: ProgramPhase,
        logs: [ExerciseLog],
        overrides: [ProgramScheduleOverride],
        calendar: Calendar
    ) -> PlannedSession {
        let baseID = "\(RitualLibrary.dateKey(for: weekStart))-\(template.key)"
        let baseDate = calendar.date(byAdding: .day, value: template.offset, to: weekStart) ?? weekStart
        let override = overrides.first { $0.sessionID == baseID }
        let dateKey = override?.dateKey ?? RitualLibrary.dateKey(for: baseDate)
        let isToday = dateKey == RitualLibrary.dateKey(for: today)
        let logsForDay = logs.filter { RitualLibrary.dateKey(for: $0.date) == dateKey }
        let completed = logsForDay.contains { $0.workoutID == template.workout.id || $0.workoutTitle == template.workout.title }
        let downgraded = isToday && shouldDowngrade(template: template, readiness: readiness, recoveryStatus: recoveryStatus, programPhase: programPhase)
        let status: SessionStatus
        if completed {
            status = .completed
        } else if override != nil {
            status = .moved
        } else if downgraded {
            status = .downgraded
        } else if isToday {
            status = .recommendedToday
        } else if template.isOptional {
            status = .optional
        } else {
            status = .planned
        }

        let adjustedWorkout = downgraded ? downgradedWorkout(for: readiness, recoveryStatus: recoveryStatus) : template.workout
        let reason = override?.reason ?? adjustmentReason(template: template, readiness: readiness, recoveryStatus: recoveryStatus, programPhase: programPhase, isDowngraded: downgraded)

        return PlannedSession(
            id: baseID,
            dateKey: dateKey,
            title: template.isOptional ? "Optional \(adjustedWorkout.weeklySlot)" : adjustedWorkout.weeklySlot,
            workoutID: adjustedWorkout.id,
            workoutTitle: adjustedWorkout.title,
            category: adjustedWorkout.category,
            status: status,
            adjustmentReason: reason,
            recommendedVersion: version(for: readiness, isDowngraded: downgraded),
            note: note(for: status, reason: reason, workout: adjustedWorkout),
            isOptional: template.isOptional
        )
    }

    static func shouldDowngrade(
        template: SessionTemplate,
        readiness: ReadinessCategory?,
        recoveryStatus: RecoveryStatus,
        programPhase: ProgramPhase
    ) -> Bool {
        guard !template.isOptional else { return false }
        if readiness == .recoveryDay || readiness == .bareMinimumDay { return true }
        if recoveryStatus.recoveryCategory == .poor || recoveryStatus.recoveryCategory == .limited { return true }
        return programPhase == .newBaby && readiness == .lightTrainingDay
    }

    static func downgradedWorkout(for readiness: ReadinessCategory?, recoveryStatus: RecoveryStatus) -> WorkoutPlan {
        if readiness == .bareMinimumDay {
            return WorkoutLibrary.libraryWorkouts.first { $0.id == "bare-minimum-movement-8" } ?? WorkoutLibrary.starterProgram[0]
        }
        return WorkoutLibrary.libraryWorkouts.first { $0.id == "low-sleep-recovery-session" }
            ?? WorkoutLibrary.libraryWorkouts.first { $0.id == "recovery-mobility-12" }
            ?? WorkoutLibrary.starterProgram[0]
    }

    static func version(for readiness: ReadinessCategory?, isDowngraded: Bool) -> WorkoutVersionType {
        if isDowngraded {
            return readiness == .bareMinimumDay ? .bareMinimum : .recovery
        }
        guard let readiness else { return .short }
        return StarterWorkoutLibrary.recommendedVersion(for: readiness)
    }

    static func adjustmentReason(
        template: SessionTemplate,
        readiness: ReadinessCategory?,
        recoveryStatus: RecoveryStatus,
        programPhase: ProgramPhase,
        isDowngraded: Bool
    ) -> ScheduleAdjustmentReason? {
        if isDowngraded {
            if recoveryStatus.recoveryCategory == .poor || recoveryStatus.recoveryCategory == .limited { return .recovery }
            return .readiness
        }
        if template.isOptional { return .optionalDay }
        if programPhase == .nightShift { return .nightShift }
        if programPhase == .newBaby { return .newBaby }
        return nil
    }

    static func note(for status: SessionStatus, reason: ScheduleAdjustmentReason?, workout: WorkoutPlan) -> String {
        switch status {
        case .completed:
            return "Logged in Train. Preserve the history and move on."
        case .downgraded:
            return "Adjusted down for today. \(workout.coachingNote)"
        case .moved:
            return "Manually moved. No skipped-session penalty."
        case .optional:
            return "Optional support day. Useful, not mandatory."
        case .recommendedToday:
            return "Best scheduled session for today."
        case .planned:
            return "Planned session. Move it if life changes."
        }
    }
}
