import Foundation

struct GeneratedWorkoutRecommendation: Hashable {
    let workout: WorkoutPlan
    let reason: String
    let cautionNotes: [String]
    let substitutions: [ExerciseSubstitution]

    var primaryCautionText: String {
        cautionNotes.first ?? "Edit before logging if equipment, pain, or timing changes the plan."
    }
}

struct DynamicWorkoutGenerator {
    static func generate(
        readiness: ReadinessCategory,
        checkIn: CheckIn?,
        recoveryStatus: RecoveryStatus,
        programPhase: ProgramPhase,
        trainingLocation: TrainingLocation,
        availableEquipment: [EquipmentType],
        recentLogs: [ExerciseLog],
        dailyPlan: DailyPlan
    ) -> GeneratedWorkoutRecommendation {
        let context = GenerationContext(
            readiness: readiness,
            checkIn: checkIn,
            recoveryStatus: recoveryStatus,
            programPhase: programPhase,
            trainingLocation: trainingLocation,
            availableEquipment: availableEquipment,
            recentLogs: recentLogs,
            dailyPlan: dailyPlan
        )
        let lane = trainingLane(for: context)
        let duration = durationText(for: context, lane: lane)
        let targetDefinitions = exerciseDefinitions(for: context, lane: lane)
        let warmupDefinitions = warmupDefinitions(for: context, lane: lane)
        let cooldownDefinitions = cooldownDefinitions(for: context)
        let reason = reasonText(for: context, lane: lane)
        let cautionNotes = cautionNotes(for: context, lane: lane)
        let substitutions = targetDefinitions.flatMap(\.substitutions).prefix(4).map { $0 }

        let fullVersion = workoutVersion(
            id: "generated-today-full",
            type: .full,
            duration: duration.full,
            intention: intentionText(for: context, lane: lane, version: .full),
            warmup: warmupDefinitions,
            strength: targetDefinitions,
            cooldown: cooldownDefinitions,
            context: context,
            lane: lane
        )
        let shortVersion = workoutVersion(
            id: "generated-today-short",
            type: .short,
            duration: duration.short,
            intention: intentionText(for: context, lane: lane, version: .short),
            warmup: Array(warmupDefinitions.prefix(1)),
            strength: Array(targetDefinitions.prefix(max(2, min(3, targetDefinitions.count)))),
            cooldown: Array(cooldownDefinitions.prefix(2)),
            context: context,
            lane: lane
        )
        let minimumVersion = workoutVersion(
            id: "generated-today-minimum",
            type: .bareMinimum,
            duration: duration.minimum,
            intention: intentionText(for: context, lane: lane, version: .bareMinimum),
            warmup: [],
            strength: Array(targetDefinitions.prefix(lane == .recovery ? 2 : 1)),
            cooldown: Array(cooldownDefinitions.prefix(1)),
            context: context,
            lane: lane
        )

        let workout = WorkoutPlan(
            id: "generated-today-\(RitualLibrary.dateKey())",
            title: title(for: context, lane: lane),
            weeklySlot: "Generated today",
            focus: focusText(for: context, lane: lane),
            category: workoutCategory(for: lane),
            estimatedDuration: duration.full,
            intensity: intensityText(for: context, lane: lane),
            recommendedCategories: recommendedCategories(for: lane),
            equipmentSummary: equipmentSummary(for: context),
            coachingNote: reason,
            versions: [fullVersion, shortVersion, minimumVersion]
        )

        return GeneratedWorkoutRecommendation(
            workout: workout,
            reason: reason,
            cautionNotes: cautionNotes,
            substitutions: substitutions
        )
    }
}

private extension DynamicWorkoutGenerator {
    enum TrainingLane {
        case strength
        case shortStrength
        case recovery
        case bareMinimum
        case conditioning
    }

    struct GenerationContext {
        let readiness: ReadinessCategory
        let checkIn: CheckIn?
        let recoveryStatus: RecoveryStatus
        let programPhase: ProgramPhase
        let trainingLocation: TrainingLocation
        let availableEquipment: [EquipmentType]
        let recentLogs: [ExerciseLog]
        let dailyPlan: DailyPlan

        var availableMinutes: Int {
            checkIn?.availableWorkoutMinutes ?? 15
        }

        var hasPainNote: Bool {
            guard let note = checkIn?.painNote.trimmingCharacters(in: .whitespacesAndNewlines) else { return false }
            return !note.isEmpty
        }

        var hasShoulderCaution: Bool {
            guard let note = checkIn?.painNote.lowercased() else { return false }
            return ["shoulder", "neck", "trap", "rotator", "overhead"].contains { note.contains($0) }
        }

        var hasLowBackCaution: Bool {
            guard let note = checkIn?.painNote.lowercased() else { return false }
            return ["low back", "lower back", "back pain", "sciatic", "sciatica", "lumbar"].contains { note.contains($0) }
        }

        var trainedMusclesRecently: Set<MuscleGroup> {
            let cutoff = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
            let recentNames = recentLogs
                .filter { $0.date >= cutoff }
                .map { "\($0.exerciseID) \($0.exerciseName)".lowercased() }
            let definitions = ExerciseLibrary.definitions.filter { definition in
                recentNames.contains { text in
                    text.contains(definition.id.lowercased()) || text.contains(definition.name.lowercased())
                }
            }
            return Set(definitions.flatMap(\.primaryMuscles))
        }

        var hasLowSleepOrRecoveryRisk: Bool {
            recoveryStatus.recoveryCategory == .poor
                || recoveryStatus.recoveryCategory == .limited
                || (checkIn?.energy ?? 10) <= 3
                || (checkIn?.stress ?? 0) >= 8
                || (checkIn?.soreness ?? 0) >= 8
        }
    }

    static func trainingLane(for context: GenerationContext) -> TrainingLane {
        if context.readiness == .bareMinimumDay { return .bareMinimum }
        if context.readiness == .recoveryDay { return .recovery }
        if context.hasPainNote || context.hasLowSleepOrRecoveryRisk { return .recovery }
        if context.readiness == .lightTrainingDay { return .shortStrength }
        if context.availableMinutes < 12 { return .bareMinimum }
        if context.availableMinutes < 22 { return .shortStrength }
        if context.trainingLocation == .outside { return .conditioning }
        if context.programPhase == .newBaby || context.programPhase == .nightShift {
            return context.readiness == .pushDay ? .shortStrength : .shortStrength
        }
        return .strength
    }

    static func exerciseDefinitions(for context: GenerationContext, lane: TrainingLane) -> [ExerciseDefinition] {
        switch lane {
        case .recovery:
            return preferredDefinitions(ids: ["shoulder-neck-reset", "hips-hamstrings-reset", "stairs-walk"], context: context)
        case .bareMinimum:
            return preferredDefinitions(ids: ["dead-bug", "band-row", "shoulder-neck-reset"], context: context)
        case .conditioning:
            return preferredDefinitions(ids: ["bike-easy-intervals", "stairs-walk", "farmer-carry"], context: context)
        case .shortStrength:
            return balancedStrengthDefinitions(context: context, limit: 3)
        case .strength:
            return balancedStrengthDefinitions(context: context, limit: 5)
        }
    }

    static func balancedStrengthDefinitions(context: GenerationContext, limit: Int) -> [ExerciseDefinition] {
        var ids = ["goblet-squat", "dumbbell-rdl", "incline-db-press", "one-arm-db-row", "farmer-carry", "dead-bug"]
        if context.hasShoulderCaution {
            ids = ["goblet-squat", "dumbbell-rdl", "band-row", "dead-bug", "farmer-carry"]
        }

        let recentMuscles = context.trainedMusclesRecently
        let definitions = preferredDefinitions(ids: ids, context: context)
        let lowerPriority = definitions.filter { definition in
            definition.primaryMuscles.contains { recentMuscles.contains($0) }
        }
        let higherPriority = definitions.filter { definition in
            !definition.primaryMuscles.contains { recentMuscles.contains($0) }
        }
        return Array((higherPriority + lowerPriority).prefix(limit))
    }

    static func warmupDefinitions(for context: GenerationContext, lane: TrainingLane) -> [ExerciseDefinition] {
        if lane == .conditioning {
            return preferredDefinitions(ids: ["stairs-walk"], context: context)
        }
        if context.hasShoulderCaution {
            return preferredDefinitions(ids: ["shoulder-neck-reset", "dead-bug"], context: context)
        }
        return preferredDefinitions(ids: ["dead-bug", "band-row"], context: context)
    }

    static func cooldownDefinitions(for context: GenerationContext) -> [ExerciseDefinition] {
        preferredDefinitions(ids: ["hips-hamstrings-reset", "shoulder-neck-reset"], context: context)
    }

    static func preferredDefinitions(ids: [String], context: GenerationContext) -> [ExerciseDefinition] {
        let candidateIDs = Set(ExerciseLibrary.automaticGenerationCandidates(
            location: context.trainingLocation,
            equipment: context.availableEquipment,
            lane: generationLane(for: ids),
            shoulderCaution: context.hasShoulderCaution,
            lowBackCaution: context.hasLowBackCaution
        ).map(\.id))
        let definitions = ids.compactMap { ExerciseLibrary.definition(for: $0) }
        let compatible = definitions.filter { definition in
            candidateIDs.contains(definition.id)
                && (definition.locationCompatibility.contains(context.trainingLocation)
                || context.trainingLocation == .mixed
                || !Set(definition.equipment).isDisjoint(with: context.availableEquipment))
        }
        return compatible.isEmpty ? definitions : compatible
    }

    static func generationLane(for ids: [String]) -> ExerciseGenerationLane {
        if ids.contains(where: { $0.contains("recovery") || $0.contains("reset") || $0.contains("hips") }) {
            return .recovery
        }
        if ids.contains(where: { $0.contains("bike") || $0.contains("stairs") }) {
            return .conditioning
        }
        if ids.count <= 3 {
            return .bareMinimum
        }
        return .strength
    }

    static func workoutVersion(
        id: String,
        type: WorkoutVersionType,
        duration: String,
        intention: String,
        warmup: [ExerciseDefinition],
        strength: [ExerciseDefinition],
        cooldown: [ExerciseDefinition],
        context: GenerationContext,
        lane: TrainingLane
    ) -> WorkoutVersion {
        var sections: [WorkoutSection] = []
        if !warmup.isEmpty {
            sections.append(WorkoutSection(id: "\(id)-warmup", kind: .warmup, title: "Warmup", exercises: warmup.map { exercisePlan(from: $0, type: type, lane: lane, isWarmup: true) }))
        }
        if !strength.isEmpty {
            let kind: WorkoutSectionKind = lane == .recovery ? .recovery : .strength
            sections.append(WorkoutSection(id: "\(id)-main", kind: kind, title: lane == .recovery ? "Recovery Work" : "Main Work", exercises: strength.map { exercisePlan(from: $0, type: type, lane: lane, isWarmup: false) }))
        }
        if !cooldown.isEmpty {
            sections.append(WorkoutSection(id: "\(id)-cooldown", kind: .cooldown, title: "Cooldown", exercises: cooldown.map { exercisePlan(from: $0, type: .bareMinimum, lane: .recovery, isWarmup: true) }))
        }
        return WorkoutVersion(id: id, type: type, duration: duration, intention: intention, sections: sections)
    }

    static func exercisePlan(from definition: ExerciseDefinition, type: WorkoutVersionType, lane: TrainingLane, isWarmup: Bool) -> ExercisePlan {
        let prescription: String
        let rest: String
        if isWarmup || lane == .recovery {
            prescription = definition.category == .bike || definition.category == .stairs ? "5-10 min easy" : "1 easy round"
            rest = "As needed"
        } else {
            switch type {
            case .full:
                prescription = "2-3 sets of 8-10"
                rest = "60-90 sec"
            case .short:
                prescription = "1-2 sets of 8"
                rest = "45-60 sec"
            case .bareMinimum, .recovery:
                prescription = "1 easy set"
                rest = "As needed"
            }
        }

        return ExercisePlan(
            id: definition.id,
            name: definition.name,
            equipment: definition.equipment.map(\.rawValue).joined(separator: ", "),
            prescription: prescription,
            rest: rest,
            formCues: definition.executionSteps,
            commonMistakes: definition.commonMistakes,
            musclesTargeted: definition.primaryMuscles.map(\.rawValue),
            feel: definition.howItShouldFeel,
            isLoggable: !isWarmup && lane != .recovery
        )
    }

    static func durationText(for context: GenerationContext, lane: TrainingLane) -> (full: String, short: String, minimum: String) {
        switch lane {
        case .strength:
            return ("30-40 min", "18-24 min", "8-10 min")
        case .shortStrength:
            return ("18-24 min", "10-14 min", "5-8 min")
        case .conditioning:
            return ("15-20 min", "8-10 min", "4-6 min")
        case .recovery:
            return ("12-18 min", "7-10 min", "3-5 min")
        case .bareMinimum:
            return ("8-10 min", "5-8 min", "2-4 min")
        }
    }

    static func title(for context: GenerationContext, lane: TrainingLane) -> String {
        switch lane {
        case .strength:
            return "Generated Full-Body Strength"
        case .shortStrength:
            return context.programPhase == .nightShift ? "Generated Shift-Friendly Strength" : "Generated Short Strength"
        case .conditioning:
            return "Generated Conditioning Dose"
        case .recovery:
            return "Generated Recovery Session"
        case .bareMinimum:
            return "Generated Bare-Minimum Session"
        }
    }

    static func focusText(for context: GenerationContext, lane: TrainingLane) -> String {
        switch lane {
        case .strength:
            return "Balanced strength without repeating recent stress too aggressively"
        case .shortStrength:
            return "A short session that keeps the training signal without draining recovery"
        case .conditioning:
            return "Easy conditioning matched to today’s location"
        case .recovery:
            return "Mobility, walking, and breathing because recovery is the limiter"
        case .bareMinimum:
            return "The smallest useful movement dose"
        }
    }

    static func reasonText(for context: GenerationContext, lane: TrainingLane) -> String {
        let base = "\(context.readiness.rawValue): \(context.dailyPlan.workoutRecommendation)"
        switch lane {
        case .strength:
            return "\(base) Recent logs shape the order, but the goal is still clean repeatable work."
        case .shortStrength:
            return "\(base) Time, phase, or recovery points toward a shorter strength dose."
        case .conditioning:
            return "\(base) Location makes walking, stairs, or bike the lowest-friction option."
        case .recovery:
            return "\(base) Recovery signals or subjective check-in concerns lower intensity today."
        case .bareMinimum:
            return "\(base) Keep the floor low and count the smallest useful session."
        }
    }

    static func cautionNotes(for context: GenerationContext, lane: TrainingLane) -> [String] {
        var notes: [String] = []
        if context.recoveryStatus.recoveryCategory == .poor || context.recoveryStatus.recoveryCategory == .limited {
            notes.append(context.recoveryStatus.trainingAdjustmentText)
        }
        if let checkIn = context.checkIn {
            if checkIn.energy <= 3 { notes.append("Low energy today: keep the first set easy and stop early if form fades.") }
            if checkIn.stress >= 8 { notes.append("High stress today: skip grinders and use the short version if needed.") }
            if checkIn.soreness >= 8 { notes.append("High soreness today: reduce range, load, or volume.") }
            if !checkIn.painNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                notes.append("Pain note present: avoid aggressive loading and stay in pain-free range.")
            }
        } else {
            notes.append("No check-in yet: classify today before pushing training.")
        }
        if context.programPhase == .newBaby {
            notes.append("New-Baby phase: flexible timing and a tiny floor beat perfection.")
        }
        if context.programPhase == .nightShift {
            notes.append("Night Shift phase: do not trade sleep protection for extra volume.")
        }
        if lane == .recovery || lane == .bareMinimum {
            notes.append("This is not a missed workout. It is today’s correct dose.")
        }
        return Array(NSOrderedSet(array: notes)) as? [String] ?? notes
    }

    static func intentionText(for context: GenerationContext, lane: TrainingLane, version: WorkoutVersionType) -> String {
        switch version {
        case .full:
            return focusText(for: context, lane: lane)
        case .short:
            return "Keep the useful parts and remove friction."
        case .bareMinimum, .recovery:
            return "Protect consistency with the smallest honest dose."
        }
    }

    static func workoutCategory(for lane: TrainingLane) -> WorkoutCategory {
        switch lane {
        case .strength:
            return .fullBodyStrength
        case .shortStrength:
            return .workShiftQuick
        case .conditioning:
            return .conditioning
        case .recovery:
            return .recoveryMobility
        case .bareMinimum:
            return .bareMinimum
        }
    }

    static func recommendedCategories(for lane: TrainingLane) -> [ReadinessCategory] {
        switch lane {
        case .strength:
            return [.pushDay, .normalTrainingDay]
        case .shortStrength:
            return [.normalTrainingDay, .lightTrainingDay]
        case .conditioning:
            return [.pushDay, .normalTrainingDay, .lightTrainingDay]
        case .recovery:
            return [.recoveryDay, .lightTrainingDay]
        case .bareMinimum:
            return [.bareMinimumDay, .recoveryDay]
        }
    }

    static func intensityText(for context: GenerationContext, lane: TrainingLane) -> String {
        switch lane {
        case .strength:
            return context.readiness == .pushDay ? "Moderate with one optional push" : "Moderate, controlled"
        case .shortStrength:
            return "Light to moderate"
        case .conditioning:
            return "Easy to moderate"
        case .recovery:
            return "Recovery"
        case .bareMinimum:
            return "Very light"
        }
    }

    static func equipmentSummary(for context: GenerationContext) -> String {
        switch context.trainingLocation {
        case .home:
            return "Home dumbbells, bands, bench, mat"
        case .work:
            return "Work gym, walking, stairs, bands"
        case .gym:
            return "Gym equipment, dumbbells, machines"
        case .outside:
            return "Walking, stairs, outside conditioning"
        case .mixed:
            return "Flexible: home, work, outside, or gym"
        }
    }
}
