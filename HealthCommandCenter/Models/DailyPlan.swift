import Foundation

struct DailyPlan: Hashable {
    let title: String
    let readinessCategory: ReadinessCategory
    let primaryFocus: String
    let recommendedAction: String
    let workoutRecommendation: String
    let ritualRecommendation: String
    let nutritionFocus: String
    let recoveryFocus: String
    let caffeineCutoffGuidance: String
    let sleepPriority: String
    let todaysMission: String
    let fullVersionText: String
    let shortVersionText: String
    let bareMinimumVersionText: String
}

struct DailyPlanGenerator {
    static func generate(
        category: ReadinessCategory,
        checkIn: CheckIn?,
        programPhase: ProgramPhase,
        trainingLocation: TrainingLocation,
        workoutTimePreference: WorkoutTimePreference,
        workoutLogsToday: [ExerciseLog],
        ritualCompletedCount: Int,
        ritualTotalCount: Int,
        nutritionLog: DailyNutritionLog,
        nutritionTargets: NutritionTargets,
        recoveryStatus: RecoveryStatus
    ) -> DailyPlan {
        let readiness = readinessGuidance(for: category)
        let phase = phaseGuidance(for: programPhase, workoutTimePreference: workoutTimePreference)
        let location = locationGuidance(for: trainingLocation)
        let context = checkInContext(checkIn)
        let loggedSets = workoutLogsToday.reduce(0) { $0 + $1.setsCompleted }
        let ritualProgress = ritualTotalCount > 0 ? "\(ritualCompletedCount)/\(ritualTotalCount) ritual items" : "ritual not loaded yet"

        if checkIn == nil {
            let progressAcknowledgement = progressText(loggedSets: loggedSets, ritualCompletedCount: ritualCompletedCount)
            let workoutText = loggedSets > 0
                ? "\(loggedSets) sets already logged today. Start Check In before deciding whether to add more."
                : "Training waits until the day is classified. \(location.wording) \(phase.timing)"
            return DailyPlan(
                title: "Start with today's Check In",
                readinessCategory: category,
                primaryFocus: "Classify the day first.",
                recommendedAction: "Start Check In before choosing today's training version.",
                workoutRecommendation: workoutText,
                ritualRecommendation: "If you need one move before Check In, do water, breathing, or a short walk.",
                nutritionFocus: nutritionFocus(for: category, checkIn: checkIn, log: nutritionLog, targets: nutritionTargets),
                recoveryFocus: "\(recoveryStatus.sleepSourceText): \(recoveryStatus.sleepDurationText). \(recoveryStatus.coachingLine)",
                caffeineCutoffGuidance: phase.caffeineCutoff,
                sleepPriority: phase.sleepPriority,
                todaysMission: "Start Check In. \(progressAcknowledgement) \(location.wording) \(phase.timing) \(context)",
                fullVersionText: "Full Version: unlock after Check In confirms a training day.",
                shortVersionText: "Short Version: unlock after Check In if the day needs lower friction.",
                bareMinimumVersionText: "Bare-Minimum Version: water, protein, two-minute reset, tiny movement, sleep off-ramp."
            )
        }

        return DailyPlan(
            title: title(for: category, programPhase: programPhase),
            readinessCategory: category,
            primaryFocus: readiness.primaryFocus,
            recommendedAction: recommendedAction(readiness: readiness, recoveryStatus: recoveryStatus),
            workoutRecommendation: workoutRecommendation(
                readiness: readiness,
                phase: phase,
                location: location,
                loggedSets: loggedSets,
                recoveryStatus: recoveryStatus
            ),
            ritualRecommendation: "\(readiness.ritualRecommendation) \(phase.ritualBias)",
            nutritionFocus: nutritionFocus(for: category, checkIn: checkIn, log: nutritionLog, targets: nutritionTargets),
            recoveryFocus: "\(recoveryStatus.sleepSourceText): \(recoveryStatus.sleepDurationText). \(recoveryStatus.trainingAdjustmentText) \(recoveryStatus.windDownGuidance)",
            caffeineCutoffGuidance: phase.caffeineCutoff,
            sleepPriority: phase.sleepPriority,
            todaysMission: todaysMission(
                readiness: readiness,
                phase: phase,
                location: location,
                context: context,
                loggedSets: loggedSets,
                ritualProgress: ritualProgress
            ),
            fullVersionText: fullVersionText(for: category, location: location, phase: phase),
            shortVersionText: shortVersionText(for: category, location: location, phase: phase),
            bareMinimumVersionText: bareMinimumVersionText(for: category, phase: phase)
        )
    }

    private struct ReadinessGuidance {
        let primaryFocus: String
        let recommendedAction: String
        let workoutRecommendation: String
        let ritualRecommendation: String
        let recoveryFocus: String
    }

    private struct PhaseGuidance {
        let timing: String
        let caffeineCutoff: String
        let sleepPriority: String
        let ritualBias: String
        let recoveryBias: String
    }

    private struct LocationGuidance {
        let label: String
        let wording: String
    }

    private static func title(for category: ReadinessCategory, programPhase: ProgramPhase) -> String {
        "\(category.rawValue) plan for \(programPhase.rawValue)"
    }

    private static func readinessGuidance(for category: ReadinessCategory) -> ReadinessGuidance {
        switch category {
        case .pushDay:
            return ReadinessGuidance(
                primaryFocus: "Train normally, then stop before overreaching.",
                recommendedAction: "Use the full workout. Add one optional set or easy cardio only if reps stay clean.",
                workoutRecommendation: "Full Version with one intelligent push option.",
                ritualRecommendation: "Keep the basic ritual tight so the extra work has support.",
                recoveryFocus: "Use the day, but protect tomorrow with cooldown, food, and sleep."
            )
        case .normalTrainingDay:
            return ReadinessGuidance(
                primaryFocus: "Run the planned training day.",
                recommendedAction: "Use the full workout at steady effort.",
                workoutRecommendation: "Full Version. Clean reps, no grinders.",
                ritualRecommendation: "Normal daily ritual. Keep the anchors visible.",
                recoveryFocus: "Mobility, water, and sleep routine keep the next day available."
            )
        case .lightTrainingDay:
            return ReadinessGuidance(
                primaryFocus: "Short workout plus mobility.",
                recommendedAction: "Use the Short Version and leave fresher than you started.",
                workoutRecommendation: "Short Version. Touch the patterns, skip the grind.",
                ritualRecommendation: "Emphasize mobility, hydration, and stress control.",
                recoveryFocus: "Reduce training stress and make the evening clean."
            )
        case .recoveryDay:
            return ReadinessGuidance(
                primaryFocus: "Recovery, walking, mobility, and mental reset.",
                recommendedAction: "Skip strength work. Walk, move gently, breathe, and protect sleep.",
                workoutRecommendation: "Recovery day: walking, mobility, and breathing only.",
                ritualRecommendation: "Make the ritual the main plan today.",
                recoveryFocus: "Keep intensity low and treat fatigue as useful information."
            )
        case .bareMinimumDay:
            return ReadinessGuidance(
                primaryFocus: "Tiny checklist only.",
                recommendedAction: "Do the bare-minimum version and count it.",
                workoutRecommendation: "Bare-Minimum Version. One small movement dose.",
                ritualRecommendation: "Shrink the ritual until it is impossible to miss.",
                recoveryFocus: "Protect the floor. Tomorrow can be bigger."
            )
        }
    }

    private static func phaseGuidance(for phase: ProgramPhase, workoutTimePreference: WorkoutTimePreference) -> PhaseGuidance {
        let timing = timingText(for: workoutTimePreference)
        switch phase {
        case .nightShift:
            return PhaseGuidance(
                timing: "Aim for \(timing), ideally near the beginning of shift if training fits.",
                caffeineCutoff: "Set caffeine cutoff early enough to protect the post-shift sleep window.",
                sleepPriority: "Sleep protection is the main recovery priority today.",
                ritualBias: "Night shift rule: lower friction and do not borrow from sleep.",
                recoveryBias: "Be recovery-aware around the shift and avoid late intensity."
            )
        case .dayShift:
            return PhaseGuidance(
                timing: "Use \(timing) and keep the routine stable.",
                caffeineCutoff: "Keep caffeine earlier in the day so the evening routine stays clean.",
                sleepPriority: "Keep bedtime boring and repeatable.",
                ritualBias: "Day shift rule: use the stable routine and do the anchors early.",
                recoveryBias: "Protect the after-work transition from turning into drift."
            )
        case .newBaby:
            return PhaseGuidance(
                timing: "Use flexible timing. Take the first real opening instead of waiting for ideal.",
                caffeineCutoff: "Use caffeine carefully. Do not let survival caffeine steal the next sleep chance.",
                sleepPriority: "Any sleep window is valuable. Protect it without perfection.",
                ritualBias: "New-baby rule: tiny floor, flexible timing, patient expectations.",
                recoveryBias: "Patience is productive here. Keep the floor low."
            )
        case .normalRoutine:
            return PhaseGuidance(
                timing: "Use \(timing) and build the pattern gradually.",
                caffeineCutoff: "Use a consistent cutoff that protects tonight's sleep.",
                sleepPriority: "Sleep keeps progression available.",
                ritualBias: "Normal routine rule: balanced progression, boring anchors.",
                recoveryBias: "Progress by repeating clean days before adding more."
            )
        }
    }

    private static func locationGuidance(for location: TrainingLocation) -> LocationGuidance {
        switch location {
        case .home:
            return LocationGuidance(label: "Home", wording: "Use dumbbells, bands, bench, and mat.")
        case .work:
            return LocationGuidance(label: "Work", wording: "Use the work gym, walking, stairs, and shift-friendly timing.")
        case .gym:
            return LocationGuidance(label: "Gym", wording: "Use gym equipment while keeping the same movement patterns.")
        case .outside:
            return LocationGuidance(label: "Outside", wording: "Use walking or easy conditioning as the main lever.")
        case .mixed:
            return LocationGuidance(label: "Mixed", wording: "Keep the location flexible and choose the lowest-friction option.")
        }
    }

    private static func timingText(for preference: WorkoutTimePreference) -> String {
        switch preference {
        case .beginningOfShift:
            return "the beginning of shift"
        case .afterShift:
            return "after shift"
        case .morning:
            return "the morning"
        case .afternoon:
            return "the afternoon"
        case .evening:
            return "the evening"
        case .flexible:
            return "the first practical opening"
        }
    }

    private static func checkInContext(_ checkIn: CheckIn?) -> String {
        guard let checkIn else {
            return "No check-in yet today."
        }

        return "Energy \(checkIn.energy), stress \(checkIn.stress), soreness \(checkIn.soreness), mood \(checkIn.mood), \(checkIn.availableWorkoutMinutes) minutes available."
    }

    private static func nutritionFocus(for category: ReadinessCategory, checkIn: CheckIn?, log: DailyNutritionLog, targets: NutritionTargets) -> String {
        let base: String
        switch category {
        case .pushDay, .normalTrainingDay:
            base = "Protein floor, water early, and Cronometer visibility."
        case .lightTrainingDay:
            base = "Protein and hydration are the recovery levers today."
        case .recoveryDay:
            base = "Simple meals, protein, water, no perfection project."
        case .bareMinimumDay:
            base = "One protein anchor, water, and enough tracking to stay honest."
        }

        if let checkIn, checkIn.stress >= 8 {
            return nutritionAction(for: log, targets: targets, fallback: base + " Keep food simple because stress is already high.")
        }

        return nutritionAction(for: log, targets: targets, fallback: base)
    }

    private static func nutritionAction(for log: DailyNutritionLog, targets: NutritionTargets, fallback: String) -> String {
        if !log.cronometerCompleted {
            return "Log food in Cronometer first. Then use this app for the daily summary anchors."
        }
        if let protein = log.proteinGrams {
            if protein < targets.proteinGrams {
                return "Protein is at \(protein)g. Use one easy template today: shake, griddle meal, or chicken/rice bowl."
            }
        } else {
            return "Add protein grams after Cronometer. If you need a simple move, use a shake, griddle meal, or Greek yogurt bowl."
        }
        if let water = log.waterOunces {
            if water < targets.waterOunces {
                return "Water is at \(water) oz. Keep hydration visible and aim toward \(targets.waterOunces) oz."
            }
        } else {
            return "Add water ounces so hydration is visible."
        }
        return fallback
    }

    private static func workoutRecommendation(
        readiness: ReadinessGuidance,
        phase: PhaseGuidance,
        location: LocationGuidance,
        loggedSets: Int,
        recoveryStatus: RecoveryStatus
    ) -> String {
        if loggedSets > 0 {
            return "\(loggedSets) sets already logged today. Match quality before adding volume."
        }

        switch recoveryStatus.recoveryCategory {
        case .poor:
            return "Recovery is the limiter today. Use walking, mobility, breathing, or the bare-minimum movement dose."
        case .limited:
            return "Use the Short Version or reduce one set. \(location.wording) Keep it easy enough to protect tonight."
        case .unknown:
            return "Start Check In before choosing training intensity. Protect caffeine, light, and wind-down basics."
        case .strong, .okay:
            break
        }

        return "\(readiness.workoutRecommendation) \(location.wording) \(phase.timing)"
    }

    private static func recommendedAction(readiness: ReadinessGuidance, recoveryStatus: RecoveryStatus) -> String {
        switch recoveryStatus.recoveryCategory {
        case .poor:
            return "Recovery is the limiter. Choose lighter training, walking, mobility, or the tiny floor."
        case .limited:
            return "Use the short version or reduce one set. Protect tonight's sleep."
        case .strong:
            return readiness.recommendedAction + " \(recoveryStatus.sleepSourceText) looks supportive, but do not overreach."
        case .unknown:
            return "Start with Check In and protect basics: caffeine, light, and wind-down."
        case .okay:
            return readiness.recommendedAction
        }
    }

    private static func todaysMission(
        readiness: ReadinessGuidance,
        phase: PhaseGuidance,
        location: LocationGuidance,
        context: String,
        loggedSets: Int,
        ritualProgress: String
    ) -> String {
        let progress = loggedSets > 0 ? "\(loggedSets) sets logged, \(ritualProgress)." : ritualProgress
        return "\(readiness.primaryFocus) \(location.wording) \(phase.timing) \(progress) \(context)"
    }

    private static func progressText(loggedSets: Int, ritualCompletedCount: Int) -> String {
        switch (loggedSets, ritualCompletedCount) {
        case (0, 0):
            return "No training or ritual progress logged yet."
        case (let sets, 0):
            return "\(sets) sets are already logged today."
        case (0, let rituals):
            return "\(rituals) ritual items are already complete today."
        case (let sets, let rituals):
            return "\(sets) sets and \(rituals) ritual items are already logged today."
        }
    }

    private static func fullVersionText(for category: ReadinessCategory, location: LocationGuidance, phase: PhaseGuidance) -> String {
        if category == .pushDay {
            return "Full Version: run the planned session, then add one optional set only if the work still looks clean. \(location.wording)"
        }
        return "Full Version: run the planned session at steady effort. \(location.wording) \(phase.timing)"
    }

    private static func shortVersionText(for category: ReadinessCategory, location: LocationGuidance, phase: PhaseGuidance) -> String {
        if category == .recoveryDay || category == .bareMinimumDay {
            return "Short Version: skip formal lifting today unless movement makes you feel better. Keep it easy."
        }
        return "Short Version: touch the main patterns, reduce volume, and leave fresh. \(location.wording) \(phase.timing)"
    }

    private static func bareMinimumVersionText(for category: ReadinessCategory, phase: PhaseGuidance) -> String {
        if category == .bareMinimumDay {
            return "Bare-Minimum Version: water, protein, two-minute reset, tiny movement, sleep off-ramp. Done counts."
        }
        return "Bare-Minimum Version: one movement dose and one ritual anchor. \(phase.recoveryBias)"
    }
}
