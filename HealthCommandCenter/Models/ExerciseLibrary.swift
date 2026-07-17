import Foundation

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case squat = "Squat"
    case hinge = "Hinge"
    case push = "Push"
    case pull = "Pull"
    case carry = "Carry"
    case core = "Core"
    case bands = "Bands"
    case dumbbells = "Dumbbells"
    case bodyweight = "Bodyweight"
    case bike = "Bike"
    case stairs = "Stairs"
    case mobility = "Mobility"
    case recovery = "Recovery"

    var id: String { rawValue }
}

enum MuscleGroup: String, Codable, CaseIterable, Identifiable, Hashable {
    case quads = "Quads"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case core = "Core"
    case hips = "Hips"
    case neck = "Neck"
    case fullBody = "Full Body"

    var id: String { rawValue }
}

enum EquipmentType: String, Codable, CaseIterable, Identifiable, Hashable {
    case bodyweight = "Bodyweight"
    case dumbbells = "Dumbbells"
    case resistanceBands = "Resistance Bands"
    case inclineBench = "Incline Bench"
    case mat = "Mat"
    case bike = "Bike"
    case stairs = "Stairs"
    case workGym = "Work Gym"
    case outside = "Outside"

    var id: String { rawValue }
}

enum ExerciseDifficulty: String, Codable, CaseIterable, Identifiable, Hashable {
    case starter = "Starter"
    case beginner = "Beginner"
    case moderate = "Moderate"

    var id: String { rawValue }
}

struct ExerciseVariation: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let note: String
}

struct ExerciseSubstitution: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let reason: String
}

struct ExerciseDefinition: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: ExerciseCategory
    let primaryMuscles: [MuscleGroup]
    let secondaryMuscles: [MuscleGroup]
    let equipment: [EquipmentType]
    let difficulty: ExerciseDifficulty
    let setup: String
    let executionSteps: [String]
    let breathingCue: String
    let commonMistakes: [String]
    let howItShouldFeel: String
    let painCautionGuidance: String
    let variations: [ExerciseVariation]
    let substitutions: [ExerciseSubstitution]
    let locationCompatibility: [TrainingLocation]
    let isShoulderFriendly: Bool
    let isLowBackFriendly: Bool
}

enum ExerciseLibrary {
    static let definitions: [ExerciseDefinition] = [
        ExerciseDefinition(
            id: "goblet-squat",
            name: "Goblet Squat",
            category: .squat,
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [.core, .hamstrings],
            equipment: [.dumbbells],
            difficulty: .beginner,
            setup: "Hold one dumbbell at chest height with ribs stacked over hips and feet just outside hip width.",
            executionSteps: ["Sit between the hips.", "Keep the whole foot heavy.", "Stand tall without snapping the knees."],
            breathingCue: "Inhale before the descent, exhale through the stand.",
            commonMistakes: ["Collapsing knees inward.", "Letting the dumbbell pull the chest down.", "Rushing depth before control."],
            howItShouldFeel: "Legs working, trunk braced, no sharp knee or back pain.",
            painCautionGuidance: "Reduce depth or switch to box squat if knees or low back complain.",
            variations: [ExerciseVariation(id: "box-goblet-squat", name: "Box Goblet Squat", note: "Use bench height to control depth.")],
            substitutions: [ExerciseSubstitution(id: "sit-to-stand", name: "Sit-to-Stand", reason: "Lower floor on low-readiness days.")],
            locationCompatibility: [.home, .work, .gym, .mixed],
            isShoulderFriendly: true,
            isLowBackFriendly: true
        ),
        ExerciseDefinition(
            id: "dumbbell-rdl",
            name: "Dumbbell Romanian Deadlift",
            category: .hinge,
            primaryMuscles: [.hamstrings, .glutes],
            secondaryMuscles: [.back, .core],
            equipment: [.dumbbells],
            difficulty: .beginner,
            setup: "Stand tall with dumbbells in front of thighs, soft knees, and lats lightly packed.",
            executionSteps: ["Push hips back.", "Keep dumbbells close.", "Stop when hamstrings say enough, then stand tall."],
            breathingCue: "Inhale and brace before the hinge; exhale as hips come through.",
            commonMistakes: ["Squatting the hinge.", "Reaching the weights away from the body.", "Chasing range by rounding the back."],
            howItShouldFeel: "Hamstrings and glutes loaded with a quiet low back.",
            painCautionGuidance: "Shorten range, reduce load, or swap for glute bridge if low back feels loud.",
            variations: [ExerciseVariation(id: "kickstand-rdl", name: "Kickstand RDL", note: "Use one leg as a support kickstand.")],
            substitutions: [ExerciseSubstitution(id: "glute-bridge", name: "Glute Bridge", reason: "More back-friendly hinge pattern.")],
            locationCompatibility: [.home, .work, .gym, .mixed],
            isShoulderFriendly: true,
            isLowBackFriendly: false
        ),
        ExerciseDefinition(
            id: "incline-db-press",
            name: "Incline Dumbbell Press",
            category: .push,
            primaryMuscles: [.chest, .triceps],
            secondaryMuscles: [.shoulders],
            equipment: [.dumbbells, .inclineBench],
            difficulty: .beginner,
            setup: "Set bench to a low incline, shoulder blades gently back, dumbbells over mid-chest.",
            executionSteps: ["Lower with control.", "Keep elbows slightly tucked.", "Press up without shrugging."],
            breathingCue: "Inhale on the lower; exhale through the press.",
            commonMistakes: ["Flaring elbows hard.", "Shrugging into the neck.", "Bouncing out of the bottom."],
            howItShouldFeel: "Chest and triceps working with shoulders calm.",
            painCautionGuidance: "Use a neutral grip, reduce range, or swap to incline push-up if shoulders feel irritated.",
            variations: [ExerciseVariation(id: "neutral-grip-press", name: "Neutral-Grip Press", note: "Palms face each other for shoulder comfort.")],
            substitutions: [ExerciseSubstitution(id: "incline-push-up", name: "Incline Push-Up", reason: "Lower load and easier shoulder control.")],
            locationCompatibility: [.home, .work, .gym, .mixed],
            isShoulderFriendly: true,
            isLowBackFriendly: true
        ),
        ExerciseDefinition(
            id: "one-arm-db-row",
            name: "One-Arm Dumbbell Row",
            category: .pull,
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps, .core],
            equipment: [.dumbbells, .inclineBench],
            difficulty: .beginner,
            setup: "Support one hand on bench, long spine, dumbbell under shoulder.",
            executionSteps: ["Pull elbow toward back pocket.", "Pause without twisting.", "Lower under control."],
            breathingCue: "Exhale as the elbow drives back; inhale on the lower.",
            commonMistakes: ["Rotating the torso.", "Yanking from the neck.", "Letting the shoulder dump forward."],
            howItShouldFeel: "Lats and upper back working; neck stays quiet.",
            painCautionGuidance: "Support the torso more or reduce load if low back or neck takes over.",
            variations: [ExerciseVariation(id: "chest-supported-row", name: "Chest-Supported Row", note: "Use incline bench for more support.")],
            substitutions: [ExerciseSubstitution(id: "band-row", name: "Band Row", reason: "Portable and lower setup cost.")],
            locationCompatibility: [.home, .work, .gym, .mixed],
            isShoulderFriendly: true,
            isLowBackFriendly: true
        ),
        ExerciseDefinition(
            id: "band-row",
            name: "Band Row",
            category: .bands,
            primaryMuscles: [.back],
            secondaryMuscles: [.biceps, .shoulders],
            equipment: [.resistanceBands],
            difficulty: .starter,
            setup: "Anchor band around a stable point or hold in a staggered stance with tension at start.",
            executionSteps: ["Pull elbows back.", "Squeeze shoulder blades lightly.", "Return slowly."],
            breathingCue: "Exhale on the pull; inhale on the return.",
            commonMistakes: ["Overarching ribs.", "Shrugging.", "Letting the band snap back."],
            howItShouldFeel: "Upper back wakes up without joint strain.",
            painCautionGuidance: "Keep range smaller if shoulders feel pinchy.",
            variations: [ExerciseVariation(id: "seated-band-row", name: "Seated Band Row", note: "Sit on mat and loop band around feet.")],
            substitutions: [ExerciseSubstitution(id: "one-arm-db-row", name: "One-Arm Dumbbell Row", reason: "Use when dumbbells and bench are available.")],
            locationCompatibility: [.home, .work, .gym, .mixed],
            isShoulderFriendly: true,
            isLowBackFriendly: true
        ),
        ExerciseDefinition(
            id: "farmer-carry",
            name: "Farmer Carry",
            category: .carry,
            primaryMuscles: [.fullBody, .core],
            secondaryMuscles: [.back, .shoulders],
            equipment: [.dumbbells],
            difficulty: .beginner,
            setup: "Hold dumbbells at sides, stand tall, ribs stacked, eyes forward.",
            executionSteps: ["Walk slowly.", "Keep shoulders down.", "Set weights down before posture breaks."],
            breathingCue: "Use steady nasal or quiet mouth breathing.",
            commonMistakes: ["Leaning back.", "Rushing steps.", "Letting grip failure distort posture."],
            howItShouldFeel: "Whole-body tension and grip work without breath panic.",
            painCautionGuidance: "Use lighter load or shorter distance if low back or shoulders complain.",
            variations: [ExerciseVariation(id: "suitcase-carry", name: "Suitcase Carry", note: "One dumbbell at a time for anti-lean core work.")],
            substitutions: [ExerciseSubstitution(id: "march-in-place", name: "Loaded March in Place", reason: "Use when space is tight.")],
            locationCompatibility: [.home, .work, .gym, .mixed],
            isShoulderFriendly: true,
            isLowBackFriendly: true
        ),
        ExerciseDefinition(
            id: "dead-bug",
            name: "Dead Bug",
            category: .core,
            primaryMuscles: [.core],
            secondaryMuscles: [.hips],
            equipment: [.bodyweight, .mat],
            difficulty: .starter,
            setup: "Lie on back, knees over hips, arms up, ribs gently down.",
            executionSteps: ["Reach opposite arm and leg.", "Keep low back quiet.", "Return and switch sides."],
            breathingCue: "Exhale during the reach; inhale to reset.",
            commonMistakes: ["Arching the back.", "Moving too fast.", "Chasing range before control."],
            howItShouldFeel: "Deep core working, hip flexors calm, low back supported.",
            painCautionGuidance: "Shorten the reach or keep feet closer if back arches.",
            variations: [ExerciseVariation(id: "heel-tap", name: "Heel Tap", note: "Simpler version with arms still.")],
            substitutions: [ExerciseSubstitution(id: "plank", name: "Short Plank", reason: "Use if floor position feels better.")],
            locationCompatibility: [.home, .work, .gym, .mixed],
            isShoulderFriendly: true,
            isLowBackFriendly: true
        ),
        ExerciseDefinition(
            id: "bike-easy-intervals",
            name: "Easy Bike Intervals",
            category: .bike,
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [.calves],
            equipment: [.bike, .workGym],
            difficulty: .starter,
            setup: "Set resistance low enough to breathe through the nose or speak in short sentences.",
            executionSteps: ["Warm up easy.", "Alternate short steady pushes with easy pedaling.", "Finish easier than you started."],
            breathingCue: "Keep breathing smooth; no panic intervals in the MVP.",
            commonMistakes: ["Turning recovery work into a test.", "Cranking resistance too high.", "Skipping cooldown."],
            howItShouldFeel: "Warm, awake, and better after than before.",
            painCautionGuidance: "Stop if knee, hip, or back pain sharpens.",
            variations: [ExerciseVariation(id: "steady-bike", name: "Steady Easy Ride", note: "One calm pace for 10-20 minutes.")],
            substitutions: [ExerciseSubstitution(id: "walking", name: "Walking", reason: "Use outside or on low-equipment days.")],
            locationCompatibility: [.work, .gym, .mixed],
            isShoulderFriendly: true,
            isLowBackFriendly: true
        ),
        ExerciseDefinition(
            id: "stairs-walk",
            name: "Stairs / Walking Conditioning",
            category: .stairs,
            primaryMuscles: [.quads, .glutes, .calves],
            secondaryMuscles: [.core],
            equipment: [.stairs, .outside, .bodyweight],
            difficulty: .starter,
            setup: "Pick stairs or a walking route that feels repeatable, not heroic.",
            executionSteps: ["Start easy.", "Keep posture tall.", "Stop while you could still do more."],
            breathingCue: "Breathe through the nose if possible; back off if breathing gets frantic.",
            commonMistakes: ["Racing the stairs.", "Ignoring knee feedback.", "Adding volume too quickly."],
            howItShouldFeel: "Light conditioning and a mood reset.",
            painCautionGuidance: "Use flat walking if knees or calves feel irritated.",
            variations: [ExerciseVariation(id: "flat-walk", name: "Flat Walk", note: "Best low-sleep substitution.")],
            substitutions: [ExerciseSubstitution(id: "bike-easy-intervals", name: "Easy Bike Intervals", reason: "Lower impact option at work gym.")],
            locationCompatibility: [.work, .outside, .mixed],
            isShoulderFriendly: true,
            isLowBackFriendly: true
        ),
        ExerciseDefinition(
            id: "shoulder-neck-reset",
            name: "Shoulder / Neck Reset",
            category: .mobility,
            primaryMuscles: [.shoulders, .neck],
            secondaryMuscles: [.back],
            equipment: [.bodyweight, .resistanceBands],
            difficulty: .starter,
            setup: "Stand or sit tall. Keep range small and smooth.",
            executionSteps: ["Slow neck turns.", "Shoulder rolls.", "Band pull-aparts or wall slides if comfortable."],
            breathingCue: "Slow exhale on each range-of-motion rep.",
            commonMistakes: ["Forcing end range.", "Shrugging through every rep.", "Turning a reset into a workout."],
            howItShouldFeel: "Looser and calmer, not stretched aggressively.",
            painCautionGuidance: "Avoid sharp, radiating, or worsening symptoms; keep range easy.",
            variations: [ExerciseVariation(id: "wall-slide", name: "Wall Slide", note: "Use a wall for gentle shoulder motion.")],
            substitutions: [ExerciseSubstitution(id: "breathing-reset", name: "2-Minute Breathing Reset", reason: "Use when stress is the main limiter.")],
            locationCompatibility: [.home, .work, .gym, .outside, .mixed],
            isShoulderFriendly: true,
            isLowBackFriendly: true
        ),
        ExerciseDefinition(
            id: "hips-hamstrings-reset",
            name: "Hips / Hamstrings Reset",
            category: .recovery,
            primaryMuscles: [.hips, .hamstrings],
            secondaryMuscles: [.glutes, .calves],
            equipment: [.bodyweight, .mat],
            difficulty: .starter,
            setup: "Use the mat and keep each position below a hard stretch.",
            executionSteps: ["Hip flexor breathing.", "Hamstring flossing.", "Easy glute bridge or child’s pose finish."],
            breathingCue: "Long exhale, then move into a little more range only if it stays easy.",
            commonMistakes: ["Pushing stretch pain.", "Holding breath.", "Skipping the easy finish."],
            howItShouldFeel: "Restorative, light, and sleep-friendly.",
            painCautionGuidance: "Back off immediately if tingling, sharp pain, or back symptoms appear.",
            variations: [ExerciseVariation(id: "low-sleep-mobility", name: "Low-Sleep Mobility", note: "Shorter, slower, and all floor-based.")],
            substitutions: [ExerciseSubstitution(id: "walk", name: "Easy Walk", reason: "Use if floor work is not practical.")],
            locationCompatibility: [.home, .work, .gym, .mixed],
            isShoulderFriendly: true,
            isLowBackFriendly: true
        )
    ]

    static func definition(for id: String?) -> ExerciseDefinition? {
        guard let id else { return nil }
        return definitions.first { $0.id == id }
    }

    static func definition(matching exercise: ExercisePlan) -> ExerciseDefinition? {
        definitions.first { $0.id == exercise.id }
            ?? definitions.first { $0.name.localizedCaseInsensitiveCompare(exercise.name) == .orderedSame }
    }

    static func search(
        query: String,
        category: ExerciseCategory?,
        equipment: EquipmentType?,
        muscle: MuscleGroup?,
        location: TrainingLocation?
    ) -> [ExerciseDefinition] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return definitions.filter { definition in
            let matchesQuery = cleanQuery.isEmpty
                || definition.name.localizedCaseInsensitiveContains(cleanQuery)
                || definition.setup.localizedCaseInsensitiveContains(cleanQuery)
            let matchesCategory = category.map { definition.category == $0 } ?? true
            let matchesEquipment = equipment.map { definition.equipment.contains($0) } ?? true
            let matchesMuscle = muscle.map { definition.primaryMuscles.contains($0) || definition.secondaryMuscles.contains($0) } ?? true
            let matchesLocation = location.map { definition.locationCompatibility.contains($0) } ?? true
            return matchesQuery && matchesCategory && matchesEquipment && matchesMuscle && matchesLocation
        }
    }
}
