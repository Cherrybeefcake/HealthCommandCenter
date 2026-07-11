import Foundation

enum WorkoutVersionType: String, Codable, CaseIterable, Identifiable {
    case full = "Full Version"
    case short = "Short Version"
    case bareMinimum = "Bare-Minimum Version"
    case recovery = "Recovery"

    var id: String { rawValue }
}

enum WorkoutSectionKind: String, Codable {
    case warmup = "Warmup"
    case strength = "Strength"
    case cooldown = "Cooldown"
    case recovery = "Recovery"
}

enum WorkoutCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case fullBodyStrength = "Full Body Strength"
    case bandsBodyweight = "Bands & Bodyweight"
    case dumbbellStrength = "Dumbbell Strength"
    case workShiftQuick = "Work Shift Quick Sessions"
    case recoveryMobility = "Recovery / Mobility"
    case conditioning = "Conditioning / Bike / Stairs"
    case bareMinimum = "Bare-Minimum Sessions"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .fullBodyStrength: return "figure.strengthtraining.traditional"
        case .bandsBodyweight: return "figure.core.training"
        case .dumbbellStrength: return "dumbbell"
        case .workShiftQuick: return "briefcase"
        case .recoveryMobility: return "figure.mind.and.body"
        case .conditioning: return "bicycle"
        case .bareMinimum: return "leaf"
        }
    }
}

struct ExercisePlan: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let equipment: String
    let prescription: String
    let rest: String
    let formCues: [String]
    let commonMistakes: [String]
    let musclesTargeted: [String]
    let feel: String
    let isLoggable: Bool
}

struct WorkoutSection: Codable, Identifiable, Hashable {
    let id: String
    let kind: WorkoutSectionKind
    let title: String
    let exercises: [ExercisePlan]
}

struct WorkoutVersion: Codable, Identifiable, Hashable {
    let id: String
    let type: WorkoutVersionType
    let duration: String
    let intention: String
    let sections: [WorkoutSection]
}

struct WorkoutPlan: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let weeklySlot: String
    let focus: String
    let category: WorkoutCategory
    let estimatedDuration: String
    let intensity: String
    let recommendedCategories: [ReadinessCategory]
    let equipmentSummary: String
    let coachingNote: String
    let versions: [WorkoutVersion]

    init(
        id: String,
        title: String,
        weeklySlot: String,
        focus: String,
        category: WorkoutCategory = .fullBodyStrength,
        estimatedDuration: String = "Flexible",
        intensity: String = "Beginner-friendly",
        recommendedCategories: [ReadinessCategory] = [.pushDay, .normalTrainingDay, .lightTrainingDay],
        equipmentSummary: String = "Dumbbells, bands, bench, mat",
        coachingNote: String = "Keep reps clean and stop before the session gets noisy.",
        versions: [WorkoutVersion]
    ) {
        self.id = id
        self.title = title
        self.weeklySlot = weeklySlot
        self.focus = focus
        self.category = category
        self.estimatedDuration = estimatedDuration
        self.intensity = intensity
        self.recommendedCategories = recommendedCategories
        self.equipmentSummary = equipmentSummary
        self.coachingNote = coachingNote
        self.versions = versions
    }

    func version(_ type: WorkoutVersionType) -> WorkoutVersion {
        versions.first { $0.type == type } ?? versions[0]
    }
}

struct ExerciseLog: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    let workoutID: String
    let workoutTitle: String
    let versionType: WorkoutVersionType
    let exerciseID: String
    let exerciseName: String
    let weight: Double?
    let reps: Int
    let setsCompleted: Int
    let effort: Int
    let notes: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        workoutID: String,
        workoutTitle: String,
        versionType: WorkoutVersionType,
        exerciseID: String,
        exerciseName: String,
        weight: Double?,
        reps: Int,
        setsCompleted: Int,
        effort: Int,
        notes: String
    ) {
        self.id = id
        self.date = date
        self.workoutID = workoutID
        self.workoutTitle = workoutTitle
        self.versionType = versionType
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.weight = weight
        self.reps = reps
        self.setsCompleted = setsCompleted
        self.effort = effort
        self.notes = notes
    }

    var summary: String {
        let weightText = weight.map { String(format: "%.0f lb", $0) } ?? "bodyweight"
        return "\(setsCompleted)x\(reps) at \(weightText), effort \(effort)/10"
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case date
        case workoutID
        case workoutTitle
        case versionType
        case exerciseID
        case exerciseName
        case weight
        case reps
        case setsCompleted
        case effort
        case notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        workoutID = try container.decodeIfPresent(String.self, forKey: .workoutID) ?? "unknown-workout"
        workoutTitle = try container.decodeIfPresent(String.self, forKey: .workoutTitle) ?? "Workout Session"
        versionType = try container.decodeIfPresent(WorkoutVersionType.self, forKey: .versionType) ?? .full
        exerciseID = try container.decodeIfPresent(String.self, forKey: .exerciseID) ?? UUID().uuidString
        exerciseName = try container.decodeIfPresent(String.self, forKey: .exerciseName) ?? "Exercise"
        weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        reps = try container.decodeIfPresent(Int.self, forKey: .reps) ?? 0
        setsCompleted = try container.decodeIfPresent(Int.self, forKey: .setsCompleted) ?? 1
        effort = try container.decodeIfPresent(Int.self, forKey: .effort) ?? 0
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
    }
}

struct ExerciseProgressionSuggestion: Hashable {
    let suggestedWeightText: String
    let suggestedRepsText: String
    let suggestedSetsText: String
    let reason: String
    let cautionNote: String?
}

struct ExerciseProgressSummary: Identifiable, Hashable {
    let id: String
    let exerciseName: String
    let timesLogged: Int
    let mostRecentDate: Date?
    let heaviestWeightText: String
    let mostRepsText: String
    let bestVolumeText: String
    let recentBestText: String
    let coachingLine: String
}

struct WorkoutSession: Identifiable, Hashable {
    let id: String
    let dateKey: String
    let logs: [ExerciseLog]

    var sortedLogs: [ExerciseLog] {
        logs.sorted { $0.date < $1.date }
    }

    var startDate: Date {
        sortedLogs.first?.date ?? Date()
    }

    var latestDate: Date {
        sortedLogs.last?.date ?? startDate
    }

    var workoutTitle: String {
        let titles = logs.map(\.workoutTitle).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return Dictionary(grouping: titles, by: { $0 })
            .max { $0.value.count < $1.value.count }?
            .key ?? "Workout Session"
    }

    var totalSets: Int {
        logs.reduce(0) { $0 + $1.setsCompleted }
    }

    var exerciseCount: Int {
        Set(logs.map(\.exerciseID)).count
    }

    var topExerciseSummary: String {
        let names = Array(NSOrderedSet(array: sortedLogs.map(\.exerciseName))) as? [String] ?? []
        if names.isEmpty { return "No exercises logged" }
        if names.count <= 3 { return names.joined(separator: ", ") }
        return names.prefix(3).joined(separator: ", ") + " +\(names.count - 3) more"
    }

    var exerciseGroups: [(name: String, logs: [ExerciseLog])] {
        let grouped = Dictionary(grouping: sortedLogs, by: \.exerciseName)
        return grouped
            .map { (name: $0.key, logs: $0.value.sorted { $0.date < $1.date }) }
            .sorted { ($0.logs.first?.date ?? Date()) < ($1.logs.first?.date ?? Date()) }
    }
}

struct StarterWorkoutLibrary {
    static let workouts: [WorkoutPlan] = [
        fullBodyA,
        fullBodyB,
        fullBodyC
    ]

    static func recommendedVersion(for category: ReadinessCategory) -> WorkoutVersionType {
        switch category {
        case .pushDay:
            return .full
        case .normalTrainingDay:
            return .full
        case .lightTrainingDay:
            return .short
        case .recoveryDay:
            return .recovery
        case .bareMinimumDay:
            return .bareMinimum
        }
    }

    static func recommendationTitle(for category: ReadinessCategory) -> String {
        switch category {
        case .pushDay:
            return "Full Version. Push intelligently."
        case .normalTrainingDay:
            return "Full Version."
        case .lightTrainingDay:
            return "Short Version."
        case .recoveryDay:
            return "Recovery and mobility."
        case .bareMinimumDay:
            return "Bare-Minimum Version."
        }
    }
}

struct WorkoutLibrary {
    static let starterProgram = StarterWorkoutLibrary.workouts

    static let libraryWorkouts: [WorkoutPlan] = [
        workShiftStrength,
        bandsBodyweightTen,
        dumbbellFullBodyTwenty,
        bareMinimumMovement,
        recoveryMobility,
        bikeConditioning,
        stairsWalkingConditioning,
        shoulderFriendlyReset,
        lowSleepRecovery
    ]

    static let allBuiltInWorkouts: [WorkoutPlan] = starterProgram + libraryWorkouts

    static func workouts(in category: WorkoutCategory) -> [WorkoutPlan] {
        if category == .fullBodyStrength {
            return starterProgram
        }
        return libraryWorkouts.filter { $0.category == category }
    }

    static func recommendedWorkout(
        for category: ReadinessCategory,
        phase: ProgramPhase,
        workoutTimePreference: WorkoutTimePreference
    ) -> WorkoutPlan {
        switch category {
        case .pushDay:
            return phase == .nightShift || phase == .newBaby ? dumbbellFullBodyTwenty : StarterWorkoutLibrary.workouts[0]
        case .normalTrainingDay:
            if phase == .nightShift || phase == .newBaby { return workShiftStrength }
            return StarterWorkoutLibrary.workouts[1]
        case .lightTrainingDay:
            return phase == .nightShift || workoutTimePreference == .beginningOfShift ? workShiftStrength : bandsBodyweightTen
        case .recoveryDay:
            return lowSleepRecovery
        case .bareMinimumDay:
            return bareMinimumMovement
        }
    }
}

private extension WorkoutLibrary {
    static let workShiftStrength = WorkoutPlan(
        id: "work-shift-strength-15",
        title: "15-Minute Work-Shift Strength",
        weeklySlot: "Work quick",
        focus: "Shift-friendly strength dose with no warmup drama",
        category: .workShiftQuick,
        estimatedDuration: "15 min",
        intensity: "Moderate, contained",
        recommendedCategories: [.normalTrainingDay, .lightTrainingDay],
        equipmentSummary: "Work gym, dumbbells, bench, bands",
        coachingNote: "Good for the beginning of shift: get the signal, avoid turning it into a whole event.",
        versions: [
            version("work-shift-strength-15-full", .full, "15 min", "A clean work-shift strength floor.", [
                section("work-shift-warm", .warmup, "Warmup", [
                    exercise("work-shift-walk", "Treadmill or Hall Walk", "Work gym or hallway", "3 min", "None", ["Easy pace", "Shoulders down"], ["Starting too fast"], ["Calves", "Hips"], "Warm, not tired", false)
                ]),
                section("work-shift-strength", .strength, "Strength", [
                    exercise("db-goblet-squat", "Goblet Squat", "Dumbbell", "2 sets of 8-10", "60 sec", ["Tall chest", "Knees track toes", "Stop before grind"], ["Collapsing inward", "Rushing"], ["Quads", "Glutes", "Core"], "Strong and controlled", true),
                    exercise("db-bench-press", "Dumbbell Bench Press", "Bench, dumbbells", "2 sets of 8-10", "60 sec", ["Shoulders packed", "Smooth lower"], ["Flaring hard", "Bouncing"], ["Chest", "Triceps"], "Clean effort", true),
                    exercise("band-row", "Band Row", "Resistance band", "2 sets of 12", "45 sec", ["Pull elbows to ribs", "Pause briefly"], ["Shrugging"], ["Upper back", "Lats"], "Upper back awake", true)
                ])
            ]),
            version("work-shift-strength-15-short", .short, "9-10 min", "Keep the promise with one pass.", [
                section("work-shift-short", .strength, "Short Dose", [
                    exercise("db-goblet-squat", "Goblet Squat", "Dumbbell", "1-2 sets of 8", "45 sec", ["Tall chest", "Smooth reps"], ["Forcing depth"], ["Quads", "Glutes"], "Easy strength", true),
                    exercise("band-row", "Band Row", "Resistance band", "1-2 sets of 12", "45 sec", ["Shoulders low"], ["Leaning back"], ["Upper back"], "Posture reset", true)
                ])
            ]),
            version("work-shift-strength-15-bare", .bareMinimum, "5 min", "One tiny shift-friendly dose.", [
                section("work-shift-bare", .strength, "Minimum Dose", [
                    exercise("incline-push-up", "Incline Push-Up", "Bench or counter", "1 set of 8", "None", ["Body straight", "Stop easy"], ["Sagging"], ["Chest", "Triceps"], "Clean and easy", true),
                    exercise("easy-walk", "Easy Walk", "Hallway or treadmill", "3 min", "None", ["Relax shoulders"], ["Turning it into cardio"], ["Hips", "Heart"], "Clearer", false)
                ])
            ])
        ]
    )

    static let bandsBodyweightTen = WorkoutPlan(
        id: "bands-bodyweight-10",
        title: "10-Minute Bands / Bodyweight",
        weeklySlot: "Quick reset",
        focus: "Bands, push, hinge, and posture",
        category: .bandsBodyweight,
        estimatedDuration: "10 min",
        intensity: "Light to moderate",
        recommendedCategories: [.lightTrainingDay, .normalTrainingDay],
        equipmentSummary: "Resistance band, mat, bench/counter",
        coachingNote: "Use this when consistency matters more than load.",
        versions: [
            version("bands-bodyweight-10-full", .full, "10 min", "A low-friction strength circuit.", [
                section("bands-bodyweight-circuit", .strength, "Circuit", [
                    exercise("band-good-morning", "Band Good Morning", "Resistance band", "2 rounds of 12", "30 sec", ["Hips back", "Soft knees"], ["Rounding"], ["Hamstrings", "Glutes"], "Light hinge", true),
                    exercise("incline-push-up", "Incline Push-Up", "Bench or counter", "2 rounds of 8-10", "30 sec", ["Straight body", "Smooth lower"], ["Sagging"], ["Chest", "Triceps"], "Clean reps", true),
                    exercise("band-pull-apart", "Band Pull-Apart", "Resistance band", "2 rounds of 12", "30 sec", ["Shoulders low", "Control out and back"], ["Snapping band"], ["Rear delts", "Upper back"], "Posture burn", true)
                ])
            ]),
            version("bands-bodyweight-10-short", .short, "6 min", "One calm circuit.", [
                section("bands-bodyweight-short", .strength, "Short Circuit", [
                    exercise("band-good-morning", "Band Good Morning", "Resistance band", "1 round of 12", "30 sec", ["Hips back"], ["Rounding"], ["Hamstrings"], "Easy", true),
                    exercise("band-pull-apart", "Band Pull-Apart", "Resistance band", "1 round of 12", "30 sec", ["Shoulders low"], ["Shrugging"], ["Upper back"], "Awake", true)
                ])
            ]),
            version("bands-bodyweight-10-bare", .bareMinimum, "3-4 min", "A tiny posture and hinge reset.", [
                section("bands-bodyweight-bare", .strength, "Minimum Dose", [
                    exercise("band-pull-apart", "Band Pull-Apart", "Resistance band", "1 set of 12", "None", ["Smooth", "Shoulders low"], ["Rushing"], ["Upper back"], "Better posture", true),
                    exercise("childs-pose-breath", "Child's Pose Breathing", "Mat", "1 min", "None", ["Long exhale"], ["Forcing"], ["Back", "Breathing"], "Settled", false)
                ])
            ])
        ]
    )

    static let dumbbellFullBodyTwenty = WorkoutPlan(
        id: "dumbbell-full-body-20",
        title: "20-Minute Dumbbell Full-Body",
        weeklySlot: "Dumbbell",
        focus: "Dumbbell strength when the full starter session is too much",
        category: .dumbbellStrength,
        estimatedDuration: "20 min",
        intensity: "Moderate",
        recommendedCategories: [.pushDay, .normalTrainingDay, .lightTrainingDay],
        equipmentSummary: "Adjustable dumbbells, incline bench, mat",
        coachingNote: "A compact full-body option. Match clean reps before adding load.",
        versions: [
            version("db-full-body-20-full", .full, "18-22 min", "Compact full-body strength.", [
                section("db20-warm", .warmup, "Warmup", [
                    exercise("march-glute-bridge", "March + Glute Bridge", "Mat", "3 min", "None", ["Move slowly", "Breathe"], ["Rushing"], ["Hips", "Core"], "Ready", false)
                ]),
                section("db20-strength", .strength, "Strength", [
                    exercise("db-rdl", "Dumbbell Romanian Deadlift", "Dumbbells", "2-3 sets of 8", "75 sec", ["Hips back", "Lats tight"], ["Rounding"], ["Hamstrings", "Glutes"], "Solid hinge", true),
                    exercise("db-floor-press", "Dumbbell Floor Press", "Dumbbells, mat", "2-3 sets of 8-10", "75 sec", ["Elbows controlled", "Pause lightly"], ["Bouncing"], ["Chest", "Triceps"], "Controlled push", true),
                    exercise("one-arm-db-row", "One-Arm Dumbbell Row", "Dumbbell, bench", "2-3 sets of 10 each", "60 sec", ["Pull to hip", "Back flat"], ["Twisting"], ["Lats", "Upper back"], "Back working", true)
                ])
            ]),
            version("db-full-body-20-short", .short, "12 min", "Short dumbbell strength dose.", [
                section("db20-short", .strength, "Short Strength", [
                    exercise("db-rdl", "Dumbbell Romanian Deadlift", "Dumbbells", "2 sets of 8", "60 sec", ["Hips back"], ["Rounding"], ["Hamstrings"], "Moderate", true),
                    exercise("db-floor-press", "Dumbbell Floor Press", "Dumbbells, mat", "2 sets of 8", "60 sec", ["Control lower"], ["Bouncing"], ["Chest"], "Clean", true)
                ])
            ]),
            version("db-full-body-20-bare", .bareMinimum, "6 min", "One hinge, one push, done.", [
                section("db20-bare", .strength, "Minimum Dose", [
                    exercise("db-rdl", "Dumbbell Romanian Deadlift", "Dumbbells", "1 set of 8", "45 sec", ["Stop easy"], ["Rounding"], ["Hamstrings"], "Easy", true),
                    exercise("db-floor-press", "Dumbbell Floor Press", "Dumbbells, mat", "1 set of 8", "45 sec", ["Smooth"], ["Bouncing"], ["Chest"], "Easy", true)
                ])
            ])
        ]
    )

    static let bareMinimumMovement = WorkoutPlan(
        id: "bare-minimum-movement-8",
        title: "8-Minute Bare-Minimum Movement",
        weeklySlot: "Minimum",
        focus: "Protect the floor when life is loud",
        category: .bareMinimum,
        estimatedDuration: "8 min",
        intensity: "Very light",
        recommendedCategories: [.bareMinimumDay, .recoveryDay],
        equipmentSummary: "Mat or open floor",
        coachingNote: "This counts. Do the small thing and move on.",
        versions: [mobilityVersion("bare-minimum-movement-8", .bareMinimum, "8 min", "Tiny movement floor", "Minimum Dose")]
    )

    static let recoveryMobility = WorkoutPlan(
        id: "recovery-mobility-12",
        title: "12-Minute Recovery Mobility",
        weeklySlot: "Recovery",
        focus: "Hips, t-spine, breathing, and downshift",
        category: .recoveryMobility,
        estimatedDuration: "12 min",
        intensity: "Recovery",
        recommendedCategories: [.recoveryDay, .lightTrainingDay],
        equipmentSummary: "Mat",
        coachingNote: "Leave the session feeling better than when you started.",
        versions: [
            mobilityVersion("recovery-mobility-12", .full, "12 min", "A calm recovery flow.", "Recovery Flow"),
            mobilityVersion("recovery-mobility-12-short", .short, "7 min", "Short recovery flow.", "Short Flow"),
            mobilityVersion("recovery-mobility-12-bare", .bareMinimum, "4 min", "Bare-minimum mobility.", "Minimum Flow")
        ]
    )

    static let bikeConditioning = WorkoutPlan(
        id: "bike-conditioning-15",
        title: "15-Minute Bike Conditioning",
        weeklySlot: "Conditioning",
        focus: "Low-impact cardio without crushing recovery",
        category: .conditioning,
        estimatedDuration: "15 min",
        intensity: "Easy to moderate",
        recommendedCategories: [.pushDay, .normalTrainingDay, .lightTrainingDay],
        equipmentSummary: "Bike",
        coachingNote: "Keep it conversational unless the day is clearly a Push Day.",
        versions: [
            conditioningVersion("bike-conditioning-15", .full, "15 min", "Easy bike with a little structure.", "Bike"),
            conditioningVersion("bike-conditioning-15-short", .short, "8 min", "Short bike flush.", "Bike"),
            conditioningVersion("bike-conditioning-15-bare", .bareMinimum, "4 min", "Minimum bike spin.", "Bike")
        ]
    )

    static let stairsWalkingConditioning = WorkoutPlan(
        id: "stairs-walking-conditioning-10",
        title: "10-Minute Stairs / Walking Conditioning",
        weeklySlot: "Conditioning",
        focus: "Shift-friendly conditioning with easy exits",
        category: .conditioning,
        estimatedDuration: "10 min",
        intensity: "Light to moderate",
        recommendedCategories: [.normalTrainingDay, .lightTrainingDay],
        equipmentSummary: "Stairs, hallway, treadmill, or outside",
        coachingNote: "If stress or sleep is poor, make this a walk instead of a push.",
        versions: [
            conditioningVersion("stairs-walking-conditioning-10", .full, "10 min", "Walk/stairs conditioning without drama.", "Stairs or walk"),
            conditioningVersion("stairs-walking-conditioning-10-short", .short, "6 min", "Short walk/stairs dose.", "Stairs or walk"),
            conditioningVersion("stairs-walking-conditioning-10-bare", .bareMinimum, "3 min", "Walk the floor.", "Walk")
        ]
    )

    static let shoulderFriendlyReset = WorkoutPlan(
        id: "shoulder-friendly-upper-reset",
        title: "Shoulder-Friendly Upper Body Reset",
        weeklySlot: "Upper reset",
        focus: "Upper-back work and controlled pressing without aggressive overhead work",
        category: .bandsBodyweight,
        estimatedDuration: "12-15 min",
        intensity: "Light to moderate",
        recommendedCategories: [.lightTrainingDay, .normalTrainingDay],
        equipmentSummary: "Bands, light dumbbells, bench",
        coachingNote: "Stay in a pain-free range. This is a reset, not a test.",
        versions: [
            version("shoulder-reset-full", .full, "12-15 min", "Shoulder-friendly upper reset.", [
                section("shoulder-reset", .strength, "Reset", [
                    exercise("band-face-pull", "Band Face Pull", "Resistance band", "2 sets of 12", "45 sec", ["Elbows high but easy", "Shoulders down"], ["Cranking neck"], ["Rear delts", "Upper back"], "Clean upper-back work", true),
                    exercise("incline-push-up", "Incline Push-Up", "Bench or counter", "2 sets of 8-10", "45 sec", ["Pain-free range", "Smooth lower"], ["Diving head"], ["Chest", "Triceps"], "Easy push", true),
                    exercise("side-lying-open-book", "Side-Lying Open Book", "Mat", "5 reps each side", "None", ["Breathe out into rotation"], ["Forcing range"], ["T-spine", "Shoulders"], "Open", false)
                ])
            ]),
            version("shoulder-reset-short", .short, "7 min", "Short shoulder reset.", [
                section("shoulder-reset-short-section", .strength, "Short Reset", [
                    exercise("band-face-pull", "Band Face Pull", "Resistance band", "1-2 sets of 12", "30 sec", ["Smooth"], ["Shrugging"], ["Upper back"], "Awake", true),
                    exercise("side-lying-open-book", "Side-Lying Open Book", "Mat", "4 reps each side", "None", ["Easy range"], ["Forcing"], ["T-spine"], "Open", false)
                ])
            ]),
            version("shoulder-reset-bare", .bareMinimum, "4 min", "Minimum shoulder reset.", [
                section("shoulder-reset-bare-section", .recovery, "Minimum Reset", [
                    exercise("band-pull-apart", "Band Pull-Apart", "Resistance band", "1 set of 12", "None", ["Shoulders low"], ["Snapping"], ["Upper back"], "Better posture", true)
                ])
            ])
        ]
    )

    static let lowSleepRecovery = WorkoutPlan(
        id: "low-sleep-recovery-session",
        title: "Low-Sleep Recovery Session",
        weeklySlot: "Low sleep",
        focus: "Walking, breathing, and mobility when recovery is thin",
        category: .recoveryMobility,
        estimatedDuration: "10-15 min",
        intensity: "Recovery",
        recommendedCategories: [.recoveryDay, .bareMinimumDay],
        equipmentSummary: "Mat, walking space",
        coachingNote: "Low sleep is not a moral problem. Keep the floor low and protect tomorrow.",
        versions: [
            mobilityVersion("low-sleep-recovery-session", .recovery, "10-15 min", "Low-sleep recovery session.", "Low-Sleep Flow"),
            mobilityVersion("low-sleep-recovery-session-bare", .bareMinimum, "5 min", "Tiny low-sleep floor.", "Minimum Flow")
        ]
    )

    static func version(_ id: String, _ type: WorkoutVersionType, _ duration: String, _ intention: String, _ sections: [WorkoutSection]) -> WorkoutVersion {
        WorkoutVersion(id: id, type: type, duration: duration, intention: intention, sections: sections)
    }

    static func section(_ id: String, _ kind: WorkoutSectionKind, _ title: String, _ exercises: [ExercisePlan]) -> WorkoutSection {
        WorkoutSection(id: id, kind: kind, title: title, exercises: exercises)
    }

    static func exercise(
        _ id: String,
        _ name: String,
        _ equipment: String,
        _ prescription: String,
        _ rest: String,
        _ formCues: [String],
        _ commonMistakes: [String],
        _ musclesTargeted: [String],
        _ feel: String,
        _ isLoggable: Bool
    ) -> ExercisePlan {
        ExercisePlan(id: id, name: name, equipment: equipment, prescription: prescription, rest: rest, formCues: formCues, commonMistakes: commonMistakes, musclesTargeted: musclesTargeted, feel: feel, isLoggable: isLoggable)
    }

    static func mobilityVersion(_ baseID: String, _ type: WorkoutVersionType, _ duration: String, _ intention: String, _ title: String) -> WorkoutVersion {
        version("\(baseID)-\(type.id)", type, duration, intention, [
            section("\(baseID)-mobility", .recovery, title, [
                exercise("\(baseID)-easy-walk", "Easy Walk", "None or treadmill", "3-6 min", "None", ["Relax shoulders", "Keep pace easy"], ["Turning it into cardio"], ["Calves", "Hips", "Heart"], "A little clearer", false),
                exercise("\(baseID)-hip-flow", "Hip and T-Spine Flow", "Mat", "3-5 min", "None", ["Move slowly", "Stay comfortable"], ["Forcing positions"], ["Hips", "Mid-back"], "Looser", false),
                exercise("\(baseID)-breathing", "Supine Breathing Reset", "Mat", "2 min", "None", ["Long exhale", "Jaw soft"], ["Trying too hard"], ["Breathing"], "Settled", false)
            ])
        ])
    }

    static func conditioningVersion(_ baseID: String, _ type: WorkoutVersionType, _ duration: String, _ intention: String, _ mode: String) -> WorkoutVersion {
        version("\(baseID)-\(type.id)", type, duration, intention, [
            section("\(baseID)-conditioning", .recovery, "Conditioning", [
                exercise("\(baseID)-easy-start", "\(mode) Easy Start", mode, "3 min easy", "None", ["Start too easy", "Breathe steadily"], ["Opening too hard"], ["Heart", "Legs"], "Warm", false),
                exercise("\(baseID)-steady", "\(mode) Steady Work", mode, type == .full ? "8-10 min steady" : "3-5 min steady", "None", ["Conversational pace", "Keep posture calm"], ["Chasing intensity"], ["Heart", "Legs"], "Worked but not crushed", false),
                exercise("\(baseID)-cooldown", "\(mode) Cooldown", mode, "2 min easy", "None", ["Let breathing settle"], ["Stopping abruptly"], ["Heart", "Calves"], "Recovered", false)
            ])
        ])
    }
}

private extension StarterWorkoutLibrary {
    static let fullBodyA = WorkoutPlan(
        id: "full-body-a",
        title: "Full Body A",
        weeklySlot: "Day 1",
        focus: "Squat pattern, horizontal push, supported pull",
        versions: [
            WorkoutVersion(
                id: "full-body-a-full",
                type: .full,
                duration: "42-50 min",
                intention: "Rebuild strength with clean reps and no grinders.",
                sections: [
                    section("a-full-warmup", .warmup, "Warmup", [
                        exercise("a-cat-camel", "Cat-Camel to Child's Pose", "Mat", "2 rounds, 5 slow reps each", "Easy pace", ["Move slowly", "Breathe into the back ribs"], ["Rushing the positions", "Forcing range"], ["Spine", "Hips", "Breathing"], "Gentle and opening", false),
                        exercise("a-band-row-warm", "Band Row Warmup", "Resistance band", "2 sets of 12", "30 sec", ["Shoulders down", "Pull elbows to ribs"], ["Shrugging", "Leaning back"], ["Upper back", "Lats"], "Light activation", false)
                    ]),
                    section("a-full-strength", .strength, "Strength", [
                        exercise("db-goblet-squat", "Dumbbell Goblet Squat", "Adjustable dumbbell", "3 sets of 8-10", "90 sec", ["Brace before lowering", "Knees track over toes", "Stand tall at the top"], ["Collapsing knees", "Rounding the back", "Bouncing out of the bottom"], ["Quads", "Glutes", "Core"], "Solid, controlled, two reps in reserve", true),
                        exercise("incline-db-press", "Incline Dumbbell Press", "Incline bench, dumbbells", "3 sets of 8-10", "90 sec", ["Wrists stacked", "Shoulder blades stay back", "Press slightly up and in"], ["Flaring elbows hard", "Losing bench contact"], ["Chest", "Shoulders", "Triceps"], "Smooth pressure through the chest", true),
                        exercise("bench-supported-db-row", "Bench-Supported Dumbbell Row", "Incline bench, dumbbells", "3 sets of 10 each side", "75 sec", ["Pull elbow toward hip", "Pause at the top", "Keep neck long"], ["Twisting the torso", "Yanking from the hand"], ["Lats", "Upper back", "Biceps"], "Back working more than arms", true),
                        exercise("dead-bug", "Dead Bug", "Mat", "2 sets of 6 each side", "45 sec", ["Low back gently heavy", "Move opposite arm and leg", "Exhale as you reach"], ["Arching the back", "Moving too fast"], ["Deep core", "Hip flexors"], "Controlled and quiet", true)
                    ]),
                    section("a-full-cooldown", .cooldown, "Cooldown", [
                        exercise("a-hip-flexor", "Half-Kneeling Hip Flexor Stretch", "Mat", "45 sec each side", "None", ["Glute gently on", "Ribs stacked over pelvis"], ["Overarching low back", "Forcing the stretch"], ["Hip flexors", "Quads"], "Easy stretch, not strain", false)
                    ])
                ]
            ),
            WorkoutVersion(
                id: "full-body-a-short",
                type: .short,
                duration: "24-30 min",
                intention: "Keep the pattern, reduce volume, leave fresh.",
                sections: [
                    section("a-short-warmup", .warmup, "Warmup", [
                        exercise("a-short-mobility", "Mobility Primer", "Mat, band", "4 min easy flow", "None", ["Move smoothly", "Stay nasal if possible"], ["Turning it into conditioning"], ["Hips", "T-spine", "Shoulders"], "Warm, not tired", false)
                    ]),
                    section("a-short-strength", .strength, "Strength", [
                        exercise("db-goblet-squat", "Dumbbell Goblet Squat", "Adjustable dumbbell", "2 sets of 8", "75 sec", ["Brace before lowering", "Stay tall"], ["Rushing depth", "Knees caving"], ["Quads", "Glutes", "Core"], "Clean and repeatable", true),
                        exercise("incline-db-press", "Incline Dumbbell Press", "Incline bench, dumbbells", "2 sets of 8", "75 sec", ["Wrists stacked", "Control the lower"], ["Flaring elbows", "Grinding reps"], ["Chest", "Shoulders", "Triceps"], "Moderate effort", true),
                        exercise("bench-supported-db-row", "Bench-Supported Dumbbell Row", "Incline bench, dumbbells", "2 sets of 10 each side", "60 sec", ["Pause at top", "Elbow to hip"], ["Twisting", "Shrugging"], ["Lats", "Upper back"], "Back engaged", true)
                    ]),
                    section("a-short-cooldown", .cooldown, "Cooldown", [
                        exercise("a-short-breathing", "Supine Breathing Reset", "Mat", "2 min", "None", ["Long exhales", "Relax jaw"], ["Checking out completely"], ["Diaphragm", "Nervous system"], "Downshifted", false)
                    ])
                ]
            ),
            WorkoutVersion(
                id: "full-body-a-bare",
                type: .bareMinimum,
                duration: "10-14 min",
                intention: "Protect consistency with the smallest useful dose.",
                sections: [
                    section("a-bare-strength", .strength, "Minimum Dose", [
                        exercise("db-goblet-squat", "Dumbbell Goblet Squat", "Adjustable dumbbell", "1-2 sets of 8", "60 sec", ["Slow lower", "Stand tall"], ["Holding breath too long"], ["Quads", "Glutes"], "Easy to moderate", true),
                        exercise("band-row", "Band Row", "Resistance band", "1-2 sets of 12", "45 sec", ["Elbows to ribs", "Shoulders low"], ["Shrugging"], ["Upper back", "Lats"], "Light pump", true)
                    ]),
                    section("a-bare-cooldown", .cooldown, "Cooldown", [
                        exercise("easy-walk", "Easy Walk or March", "None", "5 min", "None", ["Keep it easy", "Breathe calmly"], ["Making it a test"], ["Calves", "Hips", "Heart"], "Better than when you started", false)
                    ])
                ]
            ),
            recoveryVersion("full-body-a-recovery")
        ]
    )

    static let fullBodyB = WorkoutPlan(
        id: "full-body-b",
        title: "Full Body B",
        weeklySlot: "Day 2",
        focus: "Hinge pattern, vertical push, band pull",
        versions: [
            WorkoutVersion(
                id: "full-body-b-full",
                type: .full,
                duration: "40-48 min",
                intention: "Build posterior chain and shoulder control.",
                sections: [
                    section("b-full-warmup", .warmup, "Warmup", [
                        exercise("b-hip-hinge-drill", "Hip Hinge Drill", "Wall or bench", "2 sets of 8", "30 sec", ["Push hips back", "Keep ribs quiet"], ["Squatting the hinge", "Rounding low back"], ["Hamstrings", "Glutes"], "Hamstrings lightly loaded", false),
                        exercise("band-pull-apart", "Band Pull-Apart", "Resistance band", "2 sets of 12", "30 sec", ["Soft elbows", "Shoulders down"], ["Arching ribs", "Snapping the band"], ["Rear delts", "Upper back"], "Upper back awake", false)
                    ]),
                    section("b-full-strength", .strength, "Strength", [
                        exercise("db-rdl", "Dumbbell Romanian Deadlift", "Dumbbells", "3 sets of 8-10", "90 sec", ["Hips back", "Dumbbells close", "Stop when hamstrings say enough"], ["Reaching for the floor", "Rounding back", "Locking knees"], ["Hamstrings", "Glutes", "Back"], "Strong stretch, clean spine", true),
                        exercise("seated-db-press", "Seated Dumbbell Press", "Incline bench, dumbbells", "3 sets of 8", "90 sec", ["Ribs down", "Press overhead smoothly", "Finish biceps near ears"], ["Leaning back", "Shrugging early"], ["Shoulders", "Triceps", "Core"], "Stable and controlled", true),
                        exercise("band-lat-pulldown", "Band Lat Pulldown", "Resistance band", "3 sets of 12", "60 sec", ["Pull elbows to pockets", "Pause low", "Control up"], ["Pulling with wrists", "Losing tension"], ["Lats", "Upper back"], "Lats doing the work", true),
                        exercise("split-squat-supported", "Supported Split Squat", "Dumbbells optional, bench/wall support", "2 sets of 8 each side", "75 sec", ["Use support", "Front foot heavy", "Stay tall"], ["Turning it into a balance test", "Knee collapse"], ["Quads", "Glutes", "Adductors"], "Challenging but stable", true)
                    ]),
                    section("b-full-cooldown", .cooldown, "Cooldown", [
                        exercise("b-hamstring-floss", "Hamstring Floss", "Mat", "8 slow reps each side", "None", ["Move gently", "Stop before nerve tension"], ["Forcing a stretch"], ["Hamstrings", "Calves"], "Released, not stretched hard", false)
                    ])
                ]
            ),
            WorkoutVersion(
                id: "full-body-b-short",
                type: .short,
                duration: "22-28 min",
                intention: "Touch hinge, press, pull without draining the tank.",
                sections: [
                    section("b-short-warmup", .warmup, "Warmup", [
                        exercise("b-short-primer", "Hinge and Band Primer", "Band, wall", "4 min", "None", ["Stay smooth", "No fatigue"], ["Rushing"], ["Hips", "Upper back"], "Prepared", false)
                    ]),
                    section("b-short-strength", .strength, "Strength", [
                        exercise("db-rdl", "Dumbbell Romanian Deadlift", "Dumbbells", "2 sets of 8", "75 sec", ["Hips back", "Dumbbells close"], ["Chasing depth"], ["Hamstrings", "Glutes"], "Strong but safe", true),
                        exercise("seated-db-press", "Seated Dumbbell Press", "Incline bench, dumbbells", "2 sets of 8", "75 sec", ["Ribs down", "Smooth lockout"], ["Leaning back"], ["Shoulders", "Triceps"], "Controlled", true),
                        exercise("band-lat-pulldown", "Band Lat Pulldown", "Resistance band", "2 sets of 12", "45 sec", ["Elbows to pockets", "Slow return"], ["Shrugging"], ["Lats", "Upper back"], "Light pump", true)
                    ]),
                    section("b-short-cooldown", .cooldown, "Cooldown", [
                        exercise("b-short-reset", "90/90 Breathing", "Mat", "2 min", "None", ["Feet supported", "Long exhale"], ["Forcing breath"], ["Diaphragm", "Core"], "Settled", false)
                    ])
                ]
            ),
            WorkoutVersion(
                id: "full-body-b-bare",
                type: .bareMinimum,
                duration: "10-12 min",
                intention: "Keep posterior chain and shoulders online.",
                sections: [
                    section("b-bare-strength", .strength, "Minimum Dose", [
                        exercise("db-rdl", "Dumbbell Romanian Deadlift", "Dumbbells", "1-2 sets of 8", "60 sec", ["Hips back", "Stop early"], ["Rounding"], ["Hamstrings", "Glutes"], "Easy stretch", true),
                        exercise("band-pull-apart", "Band Pull-Apart", "Resistance band", "1-2 sets of 12", "45 sec", ["Shoulders low", "Control back"], ["Snapping band"], ["Rear delts", "Upper back"], "Posture reset", true)
                    ]),
                    section("b-bare-cooldown", .cooldown, "Cooldown", [
                        exercise("b-bare-walk", "Easy Walk", "None", "5 min", "None", ["Keep pace relaxed"], ["Turning it into cardio"], ["Hips", "Heart"], "Clearer", false)
                    ])
                ]
            ),
            recoveryVersion("full-body-b-recovery")
        ]
    )

    static let fullBodyC = WorkoutPlan(
        id: "full-body-c",
        title: "Full Body C",
        weeklySlot: "Day 3",
        focus: "Single-leg strength, chest-supported pull, carry",
        versions: [
            WorkoutVersion(
                id: "full-body-c-full",
                type: .full,
                duration: "38-46 min",
                intention: "Round out the week with balance, core, and carries.",
                sections: [
                    section("c-full-warmup", .warmup, "Warmup", [
                        exercise("c-worlds-greatest", "World's Greatest Stretch", "Mat", "3 reps each side", "Easy pace", ["Long exhale", "Rotate gently"], ["Forcing range", "Collapsing shoulder"], ["Hips", "T-spine"], "Open and warm", false),
                        exercise("glute-bridge", "Glute Bridge", "Mat", "2 sets of 10", "30 sec", ["Ribs down", "Squeeze glutes", "Pause at top"], ["Arching low back"], ["Glutes", "Hamstrings"], "Glutes switched on", false)
                    ]),
                    section("c-full-strength", .strength, "Strength", [
                        exercise("db-step-up", "Dumbbell Step-Up", "Bench, dumbbells optional", "3 sets of 8 each side", "90 sec", ["Whole foot on bench", "Drive through front leg", "Control down"], ["Pushing off back foot", "Dropping down"], ["Quads", "Glutes", "Calves"], "Stable and athletic", true),
                        exercise("push-up-incline", "Incline Push-Up", "Bench", "3 sets of 8-12", "75 sec", ["Body straight", "Chest to bench", "Hands under shoulders"], ["Hips sagging", "Neck reaching"], ["Chest", "Shoulders", "Triceps", "Core"], "Clean reps before fatigue", true),
                        exercise("chest-supported-rear-delt-row", "Chest-Supported Rear Delt Row", "Incline bench, dumbbells", "3 sets of 10", "75 sec", ["Elbows out slightly", "Pause high", "Neck relaxed"], ["Shrugging", "Throwing weights"], ["Rear delts", "Upper back"], "Upper back burn", true),
                        exercise("suitcase-carry", "Suitcase Carry", "Dumbbell", "3 carries of 30-45 sec each side", "60 sec", ["Stand tall", "Do not lean", "Walk quietly"], ["Leaning away", "Rushing"], ["Obliques", "Grip", "Hips"], "Strong and braced", true)
                    ]),
                    section("c-full-cooldown", .cooldown, "Cooldown", [
                        exercise("c-childs-breath", "Child's Pose Breathing", "Mat", "2 min", "None", ["Breathe into back", "Relax shoulders"], ["Forcing the stretch"], ["Back", "Lats", "Breathing"], "Downshifted", false)
                    ])
                ]
            ),
            WorkoutVersion(
                id: "full-body-c-short",
                type: .short,
                duration: "22-28 min",
                intention: "Keep coordination and strength without overreaching.",
                sections: [
                    section("c-short-warmup", .warmup, "Warmup", [
                        exercise("c-short-flow", "Bridge and Stretch Flow", "Mat", "4 min", "None", ["Breathe", "Move slowly"], ["Rushing"], ["Glutes", "Hips"], "Ready", false)
                    ]),
                    section("c-short-strength", .strength, "Strength", [
                        exercise("db-step-up", "Dumbbell Step-Up", "Bench, dumbbells optional", "2 sets of 8 each side", "75 sec", ["Drive through front foot", "Control down"], ["Pushing off back foot"], ["Quads", "Glutes"], "Stable", true),
                        exercise("push-up-incline", "Incline Push-Up", "Bench", "2 sets of 8-10", "60 sec", ["Body straight", "Smooth lower"], ["Hips sagging"], ["Chest", "Shoulders", "Triceps"], "Moderate", true),
                        exercise("suitcase-carry", "Suitcase Carry", "Dumbbell", "2 carries of 30 sec each side", "45 sec", ["Tall posture", "Quiet steps"], ["Leaning"], ["Obliques", "Grip"], "Braced", true)
                    ]),
                    section("c-short-cooldown", .cooldown, "Cooldown", [
                        exercise("c-short-breathing", "Child's Pose Breathing", "Mat", "90 sec", "None", ["Long exhales"], ["Forcing depth"], ["Back", "Breathing"], "Calm", false)
                    ])
                ]
            ),
            WorkoutVersion(
                id: "full-body-c-bare",
                type: .bareMinimum,
                duration: "9-12 min",
                intention: "A tiny session that keeps the weekly chain intact.",
                sections: [
                    section("c-bare-strength", .strength, "Minimum Dose", [
                        exercise("push-up-incline", "Incline Push-Up", "Bench", "1-2 sets of 8", "45 sec", ["Straight body", "Stop before grind"], ["Sagging hips"], ["Chest", "Triceps"], "Easy strength", true),
                        exercise("suitcase-carry", "Suitcase Carry", "Dumbbell", "1 carry of 30 sec each side", "45 sec", ["Tall", "Do not lean"], ["Rushing"], ["Core", "Grip"], "Steady", true)
                    ]),
                    section("c-bare-cooldown", .cooldown, "Cooldown", [
                        exercise("c-bare-stretch", "Easy Floor Mobility", "Mat", "5 min", "None", ["Keep it comfortable"], ["Chasing intensity"], ["Hips", "Back"], "Looser", false)
                    ])
                ]
            ),
            recoveryVersion("full-body-c-recovery")
        ]
    )

    static func recoveryVersion(_ id: String) -> WorkoutVersion {
        WorkoutVersion(
            id: id,
            type: .recovery,
            duration: "12-20 min",
            intention: "Reduce load, restore motion, and keep the promise without training stress.",
            sections: [
                section("\(id)-recovery", .recovery, "Recovery Flow", [
                    exercise("recovery-walk", "Easy Walk", "None or treadmill", "8-12 min", "None", ["Nasal breathing if comfortable", "Keep shoulders relaxed"], ["Turning it into a workout"], ["Calves", "Hips", "Heart"], "Better, not taxed", false),
                    exercise("recovery-hips", "Hip and T-Spine Flow", "Mat", "5 min", "None", ["Slow transitions", "Stay inside comfortable range"], ["Forcing positions"], ["Hips", "Mid-back", "Shoulders"], "Open and calm", false),
                    exercise("recovery-breathing", "Supine Breathing Reset", "Mat", "2-3 min", "None", ["Long exhale", "Jaw soft", "Ribs settle"], ["Trying too hard"], ["Diaphragm", "Nervous system"], "Settled", false)
                ])
            ]
        )
    }

    static func section(_ id: String, _ kind: WorkoutSectionKind, _ title: String, _ exercises: [ExercisePlan]) -> WorkoutSection {
        WorkoutSection(id: id, kind: kind, title: title, exercises: exercises)
    }

    static func exercise(
        _ id: String,
        _ name: String,
        _ equipment: String,
        _ prescription: String,
        _ rest: String,
        _ formCues: [String],
        _ commonMistakes: [String],
        _ musclesTargeted: [String],
        _ feel: String,
        _ isLoggable: Bool
    ) -> ExercisePlan {
        ExercisePlan(
            id: id,
            name: name,
            equipment: equipment,
            prescription: prescription,
            rest: rest,
            formCues: formCues,
            commonMistakes: commonMistakes,
            musclesTargeted: musclesTargeted,
            feel: feel,
            isLoggable: isLoggable
        )
    }
}
