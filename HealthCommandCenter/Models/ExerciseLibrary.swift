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
    case other = "Other"

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
    case barbell = "Barbell"
    case cable = "Cable"
    case dumbbells = "Dumbbells"
    case resistanceBands = "Resistance Bands"
    case inclineBench = "Incline Bench"
    case mat = "Mat"
    case bike = "Bike"
    case stairs = "Stairs"
    case ezCurlBar = "EZ Curl Bar"
    case exerciseBall = "Exercise Ball"
    case foamRoll = "Foam Roll"
    case kettlebells = "Kettlebells"
    case machine = "Machine"
    case medicineBall = "Medicine Ball"
    case workGym = "Work Gym"
    case outside = "Outside"
    case other = "Other"

    var id: String { rawValue }
}

enum ExerciseDifficulty: String, Codable, CaseIterable, Identifiable, Hashable {
    case starter = "Starter"
    case beginner = "Beginner"
    case moderate = "Moderate"
    case advanced = "Advanced"

    var id: String { rawValue }
}

enum ExerciseMovementPattern: String, Codable, CaseIterable, Identifiable, Hashable {
    case squat = "Squat"
    case hinge = "Hinge"
    case lunge = "Lunge"
    case push = "Push"
    case pull = "Pull"
    case carry = "Carry"
    case core = "Core"
    case conditioning = "Conditioning"
    case mobility = "Mobility"
    case recovery = "Recovery"
    case arms = "Arms"
    case other = "Other"

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
    let aliases: [String]
    let movementPattern: ExerciseMovementPattern
    let primaryMuscles: [MuscleGroup]
    let secondaryMuscles: [MuscleGroup]
    let equipment: [EquipmentType]
    let difficulty: ExerciseDifficulty
    let force: String?
    let mechanic: String?
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
    let sourceName: String
    let sourceLicense: String
    let sourceURL: String?
    let importedAt: String?

    init(
        id: String,
        name: String,
        category: ExerciseCategory,
        aliases: [String] = [],
        movementPattern: ExerciseMovementPattern? = nil,
        primaryMuscles: [MuscleGroup],
        secondaryMuscles: [MuscleGroup],
        equipment: [EquipmentType],
        difficulty: ExerciseDifficulty,
        force: String? = nil,
        mechanic: String? = nil,
        setup: String,
        executionSteps: [String],
        breathingCue: String,
        commonMistakes: [String],
        howItShouldFeel: String,
        painCautionGuidance: String,
        variations: [ExerciseVariation],
        substitutions: [ExerciseSubstitution],
        locationCompatibility: [TrainingLocation],
        isShoulderFriendly: Bool,
        isLowBackFriendly: Bool,
        sourceName: String = "Health Command Center",
        sourceLicense: String = "HCC curated",
        sourceURL: String? = nil,
        importedAt: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.aliases = aliases
        self.movementPattern = movementPattern ?? ExerciseDefinition.defaultMovementPattern(for: category)
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.equipment = equipment
        self.difficulty = difficulty
        self.force = force
        self.mechanic = mechanic
        self.setup = setup
        self.executionSteps = executionSteps
        self.breathingCue = breathingCue
        self.commonMistakes = commonMistakes
        self.howItShouldFeel = howItShouldFeel
        self.painCautionGuidance = painCautionGuidance
        self.variations = variations
        self.substitutions = substitutions
        self.locationCompatibility = locationCompatibility
        self.isShoulderFriendly = isShoulderFriendly
        self.isLowBackFriendly = isLowBackFriendly
        self.sourceName = sourceName
        self.sourceLicense = sourceLicense
        self.sourceURL = sourceURL
        self.importedAt = importedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, category, aliases, movementPattern, primaryMuscles, secondaryMuscles, equipment, difficulty, force, mechanic, setup, executionSteps, breathingCue, commonMistakes, howItShouldFeel, painCautionGuidance, variations, substitutions, locationCompatibility, isShoulderFriendly, isLowBackFriendly, sourceName, sourceLicense, sourceURL, importedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let category = try container.decodeIfPresent(ExerciseCategory.self, forKey: .category) ?? .other
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        self.category = category
        aliases = try container.decodeIfPresent([String].self, forKey: .aliases) ?? []
        movementPattern = try container.decodeIfPresent(ExerciseMovementPattern.self, forKey: .movementPattern) ?? ExerciseDefinition.defaultMovementPattern(for: category)
        primaryMuscles = try container.decodeIfPresent([MuscleGroup].self, forKey: .primaryMuscles) ?? [.fullBody]
        secondaryMuscles = try container.decodeIfPresent([MuscleGroup].self, forKey: .secondaryMuscles) ?? []
        equipment = try container.decodeIfPresent([EquipmentType].self, forKey: .equipment) ?? [.other]
        difficulty = try container.decodeIfPresent(ExerciseDifficulty.self, forKey: .difficulty) ?? .beginner
        force = try container.decodeIfPresent(String.self, forKey: .force)
        mechanic = try container.decodeIfPresent(String.self, forKey: .mechanic)
        setup = try container.decodeIfPresent(String.self, forKey: .setup) ?? "Set up with control and choose a range that fits today."
        executionSteps = try container.decodeIfPresent([String].self, forKey: .executionSteps) ?? []
        breathingCue = try container.decodeIfPresent(String.self, forKey: .breathingCue) ?? "Keep breathing steady and avoid bracing so hard that form gets noisy."
        commonMistakes = try container.decodeIfPresent([String].self, forKey: .commonMistakes) ?? ["Rushing the setup.", "Chasing load or range before control."]
        howItShouldFeel = try container.decodeIfPresent(String.self, forKey: .howItShouldFeel) ?? "Controlled, repeatable, and appropriate for today's readiness."
        painCautionGuidance = try container.decodeIfPresent(String.self, forKey: .painCautionGuidance) ?? "Stop or substitute if pain sharpens, radiates, or changes your movement."
        variations = try container.decodeIfPresent([ExerciseVariation].self, forKey: .variations) ?? []
        substitutions = try container.decodeIfPresent([ExerciseSubstitution].self, forKey: .substitutions) ?? []
        locationCompatibility = try container.decodeIfPresent([TrainingLocation].self, forKey: .locationCompatibility) ?? [.gym, .mixed]
        isShoulderFriendly = try container.decodeIfPresent(Bool.self, forKey: .isShoulderFriendly) ?? false
        isLowBackFriendly = try container.decodeIfPresent(Bool.self, forKey: .isLowBackFriendly) ?? false
        sourceName = try container.decodeIfPresent(String.self, forKey: .sourceName) ?? "Unknown"
        sourceLicense = try container.decodeIfPresent(String.self, forKey: .sourceLicense) ?? "Unknown"
        sourceURL = try container.decodeIfPresent(String.self, forKey: .sourceURL)
        importedAt = try container.decodeIfPresent(String.self, forKey: .importedAt)
    }

    static func defaultMovementPattern(for category: ExerciseCategory) -> ExerciseMovementPattern {
        switch category {
        case .squat: return .squat
        case .hinge: return .hinge
        case .push: return .push
        case .pull: return .pull
        case .carry: return .carry
        case .core: return .core
        case .bike, .stairs: return .conditioning
        case .mobility: return .mobility
        case .recovery: return .recovery
        case .bands, .dumbbells, .bodyweight, .other: return .other
        }
    }
}

enum ExerciseLibrary {
    static let definitions: [ExerciseDefinition] = {
        var seen = Set<String>()
        var combined: [ExerciseDefinition] = []
        for definition in curatedDefinitions + importedDefinitions {
            let key = definition.id.lowercased()
            let nameKey = definition.name.lowercased()
            guard !seen.contains(key), !seen.contains(nameKey) else { continue }
            combined.append(definition)
            seen.insert(key)
            seen.insert(nameKey)
        }
        return combined
    }()

    static let curatedDefinitions: [ExerciseDefinition] = [
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

    static let importedDefinitions: [ExerciseDefinition] = {
        guard let url = Bundle.main.url(forResource: "ImportedExerciseLibrary", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return []
        }
        return decodeImportedDefinitions(from: data)
    }()

    static func decodeImportedDefinitions(from data: Data) -> [ExerciseDefinition] {
        (try? JSONDecoder().decode([ExerciseDefinition].self, from: data)) ?? []
    }

    static var libraryLoadStatusText: String {
        importedDefinitions.isEmpty
            ? "Bundled exercise resource did not load. Curated HCC exercises are still available."
            : "\(definitions.count) local exercise records loaded."
    }

    static func search(
        query: String,
        category: ExerciseCategory?,
        equipment: EquipmentType?,
        muscle: MuscleGroup?,
        location: TrainingLocation?,
        movementPattern: ExerciseMovementPattern? = nil,
        difficulty: ExerciseDifficulty? = nil,
        shoulderFriendly: Bool? = nil,
        lowBackFriendly: Bool? = nil,
        bandsOnly: Bool = false,
        mobilityOnly: Bool = false
    ) -> [ExerciseDefinition] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let ranked: [(definition: ExerciseDefinition, score: Int)] = definitions.compactMap { definition in
            let score = searchScore(for: definition, query: cleanQuery)
            let matchesQuery = cleanQuery.isEmpty || score > 0
            let matchesCategory = category.map { definition.category == $0 } ?? true
            let matchesEquipment = equipment.map { definition.equipment.contains($0) } ?? true
            let matchesMuscle = muscle.map { definition.primaryMuscles.contains($0) || definition.secondaryMuscles.contains($0) } ?? true
            let matchesLocation = location.map { definition.locationCompatibility.contains($0) } ?? true
            let matchesMovement = movementPattern.map { definition.movementPattern == $0 } ?? true
            let matchesDifficulty = difficulty.map { definition.difficulty == $0 } ?? true
            let matchesShoulder = shoulderFriendly.map { definition.isShoulderFriendly == $0 } ?? true
            let matchesLowBack = lowBackFriendly.map { definition.isLowBackFriendly == $0 } ?? true
            let matchesBands = !bandsOnly || definition.equipment.contains(.resistanceBands) || definition.category == .bands
            let matchesMobility = !mobilityOnly || definition.category == .mobility || definition.category == .recovery || definition.movementPattern == .mobility || definition.movementPattern == .recovery
            guard matchesQuery && matchesCategory && matchesEquipment && matchesMuscle && matchesLocation && matchesMovement && matchesDifficulty && matchesShoulder && matchesLowBack && matchesBands && matchesMobility else {
                return nil
            }
            return (definition: definition, score: score)
        }
        return ranked.sorted {
            if $0.score == $1.score { return $0.definition.name < $1.definition.name }
            return $0.score > $1.score
        }
        .map(\.definition)
    }

    private static func searchScore(for definition: ExerciseDefinition, query: String) -> Int {
        guard !query.isEmpty else { return 1 }
        let q = query.lowercased()
        let name = definition.name.lowercased()
        if name == q { return 100 }
        if name.hasPrefix(q) { return 94 }
        let lowerAliases = definition.aliases.map { $0.lowercased() }
        if lowerAliases.contains(q) { return 90 }
        if lowerAliases.contains(where: { $0.hasPrefix(q) }) { return 86 }
        if name.contains(q) { return 78 }
        if lowerAliases.contains(where: { $0.contains(q) }) { return 72 }

        let equipmentMovement = [
            definition.equipment.map(\.rawValue).joined(separator: " "),
            definition.movementPattern.rawValue,
            definition.category.rawValue
        ].joined(separator: " ").lowercased()
        if equipmentMovement.contains(q) { return 58 }

        let muscles = [
            definition.primaryMuscles.map(\.rawValue).joined(separator: " "),
            definition.secondaryMuscles.map(\.rawValue).joined(separator: " ")
        ].joined(separator: " ").lowercased()
        if muscles.contains(q) { return 50 }

        let lowPriorityInstructionText = [
            definition.setup,
            definition.executionSteps.joined(separator: " "),
            definition.commonMistakes.joined(separator: " "),
            definition.howItShouldFeel,
            definition.painCautionGuidance
        ].joined(separator: " ").lowercased()
        return lowPriorityInstructionText.contains(q) ? 18 : 0
    }

    static func automaticGenerationCandidates(
        location: TrainingLocation,
        equipment: [EquipmentType],
        lane: ExerciseGenerationLane,
        shoulderCaution: Bool,
        lowBackCaution: Bool
    ) -> [ExerciseDefinition] {
        let allowedCategories: Set<ExerciseCategory>
        switch lane {
        case .strength:
            allowedCategories = [.squat, .hinge, .push, .pull, .carry, .core, .bands, .dumbbells, .bodyweight]
        case .conditioning:
            allowedCategories = [.bike, .stairs, .carry, .bodyweight]
        case .recovery:
            allowedCategories = [.mobility, .recovery, .bodyweight, .bands]
        case .bareMinimum:
            allowedCategories = [.core, .bands, .bodyweight, .mobility, .recovery]
        }

        let candidates = definitions.filter { definition in
            let isCurated = definition.sourceName.localizedCaseInsensitiveContains("Health Command Center")
                || definition.sourceName.localizedCaseInsensitiveContains("curated")
            let compatibleLocation = location == .mixed || definition.locationCompatibility.contains(location)
            let compatibleEquipment = Set(definition.equipment).isDisjoint(with: equipment) == false
                || definition.equipment.contains(.bodyweight)
                || definition.equipment.contains(.other)
            let safeForShoulder = !shoulderCaution || definition.isShoulderFriendly
            let safeForLowBack = !lowBackCaution || definition.isLowBackFriendly
            return isCurated
                && allowedCategories.contains(definition.category)
                && (compatibleLocation || compatibleEquipment)
                && safeForShoulder
                && safeForLowBack
        }

        return candidates.sorted {
            if $0.difficulty == $1.difficulty { return $0.name < $1.name }
            return difficultyRank($0.difficulty) < difficultyRank($1.difficulty)
        }
    }

    static func updatedRecentIDs(_ ids: [String], adding id: String, limit: Int = 12) -> [String] {
        guard !id.isEmpty else { return ids }
        var updated = ids.filter { $0 != id }
        updated.insert(id, at: 0)
        return Array(updated.prefix(limit))
    }

    static func toggledFavoriteIDs(_ ids: [String], id: String) -> [String] {
        guard !id.isEmpty else { return ids }
        var updated = ids
        if let index = updated.firstIndex(of: id) {
            updated.remove(at: index)
        } else {
            updated.insert(id, at: 0)
        }
        return updated
    }

    private static func difficultyRank(_ difficulty: ExerciseDifficulty) -> Int {
        switch difficulty {
        case .starter: return 0
        case .beginner: return 1
        case .moderate: return 2
        case .advanced: return 3
        }
    }
}

enum ExerciseGenerationLane: String, Hashable {
    case strength
    case conditioning
    case recovery
    case bareMinimum
}

extension ExerciseDefinition {
    var isHCCCurated: Bool {
        sourceName.localizedCaseInsensitiveContains("Health Command Center")
            || sourceName.localizedCaseInsensitiveContains("curated")
    }

    var shortMetadataText: String {
        [
            category.rawValue,
            movementPattern.rawValue,
            difficulty.rawValue
        ].joined(separator: " · ")
    }

    var equipmentText: String {
        equipment.map(\.rawValue).joined(separator: ", ")
    }

    var muscleText: String {
        primaryMuscles.map(\.rawValue).joined(separator: ", ")
    }
}
