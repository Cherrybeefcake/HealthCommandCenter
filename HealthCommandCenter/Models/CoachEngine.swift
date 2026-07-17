import Foundation

enum CoachRecommendationType: String, CaseIterable, Identifiable, Hashable {
    case todayBriefing = "Today Briefing"
    case primaryMission = "Primary Mission"
    case watchout = "Watchout"
    case nextAction = "Next Action"
    case workout = "Workout"
    case recovery = "Recovery"
    case nutrition = "Nutrition"
    case sleep = "Sleep"
    case weeklyReview = "Weekly Review"

    var id: String { rawValue }
}

struct CoachReason: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
}

struct CoachSafetyConstraint: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let severity: String
}

struct CoachRecommendation: Identifiable, Hashable {
    let id: String
    let type: CoachRecommendationType
    let title: String
    let message: String
    let actionTitle: String?
    let reasons: [CoachReason]
    let safetyConstraints: [CoachSafetyConstraint]
    let isConservative: Bool
}

struct CoachContext {
    let readinessCategory: ReadinessCategory?
    let dailyPlan: DailyPlan
    let recoveryStatus: RecoveryStatus
    let recoverySourceText: String
    let sleepHours: Double?
    let energy: Int?
    let stress: Int?
    let soreness: Int?
    let painNote: String
    let mood: Int?
    let availableWorkoutMinutes: Int?
    let programPhase: ProgramPhase
    let trainingLocation: TrainingLocation
    let workoutTimePreference: WorkoutTimePreference
    let recentWorkouts: [ExerciseLog]
    let programWeek: ProgramWeek
    let goals: [GoalProgress]
    let ritualCompleted: Int
    let ritualTotal: Int
    let nutritionLog: DailyNutritionLog
    let nutritionSource: String
    let nutritionDetail: String
    let bodyMetricTrendText: String
    let ouraReadinessScore: Int?
    let ouraSleepScore: Int?
    let ouraTemperatureTrend: String?

    var hasCheckIn: Bool {
        readinessCategory != nil
    }
}

protocol CoachEngine {
    func recommendations(for context: CoachContext) -> [CoachRecommendation]
    func recommendation(_ type: CoachRecommendationType, for context: CoachContext) -> CoachRecommendation?
    func weeklyReviewSummary(for review: WeeklyReview, context: CoachContext) -> String
}

struct DeterministicCoachEngine: CoachEngine {
    func recommendations(for context: CoachContext) -> [CoachRecommendation] {
        CoachRecommendationType.allCases.compactMap { recommendation($0, for: context) }
    }

    func recommendation(_ type: CoachRecommendationType, for context: CoachContext) -> CoachRecommendation? {
        let constraints = safetyConstraints(for: context)
        let conservative = !constraints.isEmpty

        switch type {
        case .todayBriefing:
            return make(
                type: type,
                title: context.hasCheckIn ? "Today is classified." : "Start with the Check In.",
                message: context.hasCheckIn
                    ? "\(context.dailyPlan.title). \(context.dailyPlan.recommendedAction)"
                    : "Classify today before choosing intensity. Any movement before that should stay easy.",
                actionTitle: context.hasCheckIn ? "Review Mission" : "Start Check In",
                context: context,
                constraints: constraints,
                conservative: conservative
            )
        case .primaryMission:
            return make(
                type: type,
                title: "Primary mission",
                message: primaryMission(for: context, constraints: constraints),
                actionTitle: context.hasCheckIn ? "Open Today" : "Start Check In",
                context: context,
                constraints: constraints,
                conservative: conservative
            )
        case .watchout:
            return make(
                type: type,
                title: "Main watchout",
                message: watchout(for: context, constraints: constraints),
                actionTitle: nil,
                context: context,
                constraints: constraints,
                conservative: conservative
            )
        case .nextAction:
            return make(
                type: type,
                title: "Next action",
                message: nextAction(for: context),
                actionTitle: context.hasCheckIn ? "Continue" : "Start Check In",
                context: context,
                constraints: constraints,
                conservative: conservative
            )
        case .workout:
            return make(
                type: type,
                title: "Workout call",
                message: workoutRecommendation(for: context, constraints: constraints),
                actionTitle: context.hasCheckIn ? "Open Train" : "Start Check In",
                context: context,
                constraints: constraints,
                conservative: conservative
            )
        case .recovery:
            return make(
                type: type,
                title: "Recovery priority",
                message: recoveryRecommendation(for: context),
                actionTitle: "Open Recovery",
                context: context,
                constraints: constraints,
                conservative: conservative
            )
        case .nutrition:
            return make(
                type: type,
                title: "Nutrition priority",
                message: nutritionPriority(for: context),
                actionTitle: "Log Nutrition",
                context: context,
                constraints: constraints,
                conservative: conservative
            )
        case .sleep:
            return make(
                type: type,
                title: "Sleep priority",
                message: "\(context.recoveryStatus.sleepSourceText): \(context.recoveryStatus.sleepDurationText). \(context.recoveryStatus.windDownGuidance)",
                actionTitle: "Open Recovery",
                context: context,
                constraints: constraints,
                conservative: conservative
            )
        case .weeklyReview:
            return make(
                type: type,
                title: "Weekly coach lens",
                message: "Review the week by signals: check-ins, training, ritual, nutrition, sleep, and recovery. Choose one next focus.",
                actionTitle: "Open Insights",
                context: context,
                constraints: constraints,
                conservative: conservative
            )
        }
    }

    func weeklyReviewSummary(for review: WeeklyReview, context: CoachContext) -> String {
        if !review.hasUsefulData {
            return "Not enough week data yet. Start with Check In, one Train log, and one Recovery ritual."
        }
        if review.lowSleepDays >= 2 {
            return "The week has useful effort, but sleep is the limiter. Next week should protect the floor before adding load."
        }
        if review.workoutDays >= 2 && review.ritualDays >= 3 && review.checkInCount >= 4 {
            return "Strong consistency week. Repeat the pattern and progress slowly instead of chasing a bigger leap."
        }
        if !safetyConstraints(for: context).isEmpty {
            return "The week has enough caution flags to stay conservative. Stack the basics first: Check In, short training, Recovery, protein, water, sleep."
        }
        return "Good base-building week. Keep the next focus narrow so the system stays repeatable."
    }
}

private extension DeterministicCoachEngine {
    func make(
        type: CoachRecommendationType,
        title: String,
        message: String,
        actionTitle: String?,
        context: CoachContext,
        constraints: [CoachSafetyConstraint],
        conservative: Bool
    ) -> CoachRecommendation {
        CoachRecommendation(
            id: type.rawValue,
            type: type,
            title: title,
            message: message,
            actionTitle: actionTitle,
            reasons: reasons(for: context),
            safetyConstraints: constraints,
            isConservative: conservative
        )
    }

    func reasons(for context: CoachContext) -> [CoachReason] {
        var reasons: [CoachReason] = [
            CoachReason(id: "phase", title: context.programPhase.rawValue, detail: context.programPhase.coachingBias),
            CoachReason(id: "source", title: "Recovery source", detail: context.recoverySourceText)
        ]

        if let readiness = context.readinessCategory {
            reasons.append(CoachReason(id: "readiness", title: readiness.rawValue, detail: context.dailyPlan.recommendedAction))
        }
        if context.ouraReadinessScore != nil || context.ouraSleepScore != nil || context.ouraTemperatureTrend != nil {
            reasons.append(CoachReason(id: "oura", title: "Oura context", detail: ouraContextLine(for: context)))
        }
        return reasons
    }

    func safetyConstraints(for context: CoachContext) -> [CoachSafetyConstraint] {
        var constraints: [CoachSafetyConstraint] = []
        let pain = context.painNote.trimmingCharacters(in: .whitespacesAndNewlines)
        if !pain.isEmpty {
            constraints.append(CoachSafetyConstraint(id: "pain", title: "Pain/problem noted", detail: "Keep range controlled and avoid forcing the painful pattern.", severity: "high"))
        }
        if let energy = context.energy, energy <= 3 {
            constraints.append(CoachSafetyConstraint(id: "low-energy", title: "Low energy", detail: "Energy is \(energy)/10. Keep the session short or recovery-based.", severity: "medium"))
        }
        if let stress = context.stress, stress >= 8 {
            constraints.append(CoachSafetyConstraint(id: "high-stress", title: "High stress", detail: "Stress is \(stress)/10. Avoid turning training into another stressor.", severity: "medium"))
        }
        if let soreness = context.soreness, soreness >= 8 {
            constraints.append(CoachSafetyConstraint(id: "high-soreness", title: "High soreness", detail: "Soreness is \(soreness)/10. Reduce load, range, or total sets.", severity: "medium"))
        }
        if let sleepHours = context.sleepHours, sleepHours < 5 {
            constraints.append(CoachSafetyConstraint(id: "low-sleep", title: "Low sleep", detail: "Sleep is under five hours. Bias toward recovery or a short version.", severity: "high"))
        }
        if context.recoveryStatus.recoveryCategory == .poor {
            constraints.append(CoachSafetyConstraint(id: "poor-recovery", title: "Poor recovery", detail: context.recoveryStatus.trainingAdjustmentText, severity: "high"))
        }
        if let readinessScore = context.ouraReadinessScore, readinessScore < 65 {
            constraints.append(CoachSafetyConstraint(id: "oura-readiness", title: "Low Oura readiness", detail: "Use Oura as supplemental caution, not as permission to push.", severity: "medium"))
        }
        if let sleepScore = context.ouraSleepScore, sleepScore < 65 {
            constraints.append(CoachSafetyConstraint(id: "oura-sleep", title: "Low Oura sleep score", detail: "Treat the sleep score as extra recovery context.", severity: "medium"))
        }
        if let trend = context.ouraTemperatureTrend?.lowercased(), trend.contains("elevated") || trend.contains("high") {
            constraints.append(CoachSafetyConstraint(id: "oura-temperature", title: "Temperature trend", detail: "Oura temperature trend suggests caution today.", severity: "medium"))
        }
        return constraints
    }

    func primaryMission(for context: CoachContext, constraints: [CoachSafetyConstraint]) -> String {
        guard context.hasCheckIn else {
            return "Classify the day first. The app should not guess training intensity."
        }
        if !constraints.isEmpty {
            return "Keep today conservative. Use the smallest version that protects consistency."
        }
        return context.dailyPlan.primaryFocus
    }

    func watchout(for context: CoachContext, constraints: [CoachSafetyConstraint]) -> String {
        if !context.hasCheckIn {
            return "No readiness category yet. Start Check In before making the training call."
        }
        if let first = constraints.first {
            return "\(first.title): \(first.detail)"
        }
        if let override = context.recoveryStatus.subjectiveOverrideText {
            return override
        }
        switch context.recoveryStatus.recoveryCategory {
        case .poor:
            return "Recovery is poor. Keep the floor low and protect sleep."
        case .limited:
            return "Recovery is limited. Shorten the session or bias toward mobility."
        case .unknown:
            return "Recovery data is incomplete. Let the Check In and basic guardrails lead."
        case .strong:
            return context.readinessCategory == .pushDay
                ? "Push intelligently. Add only clean work."
                : "Good signals are not a reason to overreach."
        case .okay:
            return "Keep the plan clean and finish with energy left."
        }
    }

    func nextAction(for context: CoachContext) -> String {
        guard context.hasCheckIn else { return "Start Check In." }
        if context.ritualTotal > 0 && context.ritualCompleted < context.ritualTotal {
            return "Finish the next Recovery ritual anchor."
        }
        if context.readinessCategory == .recoveryDay || context.readinessCategory == .bareMinimumDay {
            return "Open Recovery and keep the floor low."
        }
        return "Open Train and use today’s recommended version."
    }

    func workoutRecommendation(for context: CoachContext, constraints: [CoachSafetyConstraint]) -> String {
        guard context.hasCheckIn else {
            return "No workout recommendation until Check In is complete."
        }
        if context.readinessCategory == .recoveryDay {
            return "No hard strength work. Use mobility, walking, and breathing."
        }
        if context.readinessCategory == .bareMinimumDay {
            return "Bare-minimum movement only. Count the win."
        }
        if !constraints.isEmpty {
            return "Back off slightly. Use the short or bare-minimum version and stop clean."
        }
        return context.dailyPlan.workoutRecommendation
    }

    func recoveryRecommendation(for context: CoachContext) -> String {
        "\(context.recoveryStatus.trainingAdjustmentText) \(context.recoveryStatus.windDownGuidance)"
    }

    func nutritionPriority(for context: CoachContext) -> String {
        let log = context.nutritionLog
        if !log.cronometerCompleted {
            return "Log Cronometer or save the anchors here. Keep the food signal visible."
        }
        if log.proteinGrams == nil || !(log.proteinTargetHit || (log.proteinGrams ?? 0) >= 160) {
            return "Protein is the next anchor. Use an easy template before adding complexity."
        }
        if log.waterOunces == nil || !(log.waterTargetHit || (log.waterOunces ?? 0) >= 100) {
            return "Hydration is the next anchor. Keep it simple and visible."
        }
        return "\(context.nutritionSource): \(context.nutritionDetail)"
    }

    func ouraContextLine(for context: CoachContext) -> String {
        var parts: [String] = []
        if let readiness = context.ouraReadinessScore { parts.append("readiness \(readiness)") }
        if let sleep = context.ouraSleepScore { parts.append("sleep \(sleep)") }
        if let trend = context.ouraTemperatureTrend, !trend.isEmpty { parts.append("temperature \(trend)") }
        return parts.isEmpty ? "No active Oura context." : parts.joined(separator: ", ")
    }
}

private extension ProgramPhase {
    var coachingBias: String {
        switch self {
        case .nightShift:
            return "Protect sleep windows and avoid late intensity."
        case .dayShift:
            return "Use stable routine blocks and simple transitions."
        case .newBaby:
            return "Keep the floor tiny, flexible, and patient."
        case .normalRoutine:
            return "Build repeatability before adding more."
        }
    }
}
