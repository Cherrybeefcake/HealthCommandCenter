import Foundation

struct CustomWorkout: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    var exercises: [CustomExercise]

    init(
        id: String = UUID().uuidString,
        name: String,
        notes: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        exercises: [CustomExercise] = []
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.exercises = exercises
    }
}

struct CustomExercise: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var category: String
    var equipment: String
    var targetSets: Int
    var targetReps: String
    var notes: String
    var isLoggable: Bool
    var libraryExerciseID: String?

    init(
        id: String = UUID().uuidString,
        name: String,
        category: String = "Strength",
        equipment: String = "Available equipment",
        targetSets: Int = 2,
        targetReps: String = "8-12",
        notes: String = "",
        isLoggable: Bool = true,
        libraryExerciseID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.equipment = equipment
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.notes = notes
        self.isLoggable = isLoggable
        self.libraryExerciseID = libraryExerciseID
    }

    init(from definition: ExerciseDefinition, targetSets: Int = 2, targetReps: String = "8-12") {
        self.init(
            id: UUID().uuidString,
            name: definition.name,
            category: definition.category.rawValue,
            equipment: definition.equipmentText,
            targetSets: targetSets,
            targetReps: targetReps,
            notes: definition.painCautionGuidance,
            isLoggable: definition.movementPattern != .mobility && definition.movementPattern != .recovery,
            libraryExerciseID: definition.id
        )
    }
}

extension CustomWorkout {
    init(fromGeneratedWorkout workout: WorkoutPlan) {
        let generatedExercises = workout
            .version(.full)
            .sections
            .flatMap(\.exercises)
            .filter(\.isLoggable)
            .map { exercise in
                CustomExercise(
                    id: UUID().uuidString,
                    name: exercise.name,
                    category: exercise.musclesTargeted.first ?? "Strength",
                    equipment: exercise.equipment,
                    targetSets: Self.targetSets(from: exercise.prescription),
                    targetReps: Self.targetReps(from: exercise.prescription),
                    notes: "Generated from today's plan. Adjust before logging if needed.",
                    isLoggable: exercise.isLoggable,
                    libraryExerciseID: ExerciseLibrary.definition(matching: exercise)?.id
                )
            }

        self.init(
            name: "\(workout.title) Copy",
            notes: workout.coachingNote,
            exercises: generatedExercises
        )
    }

    var asWorkoutPlan: WorkoutPlan {
        let customExercises = exercises.map { exercise in
            let definition = ExerciseLibrary.definition(for: exercise.libraryExerciseID)
            return ExercisePlan(
                id: exercise.id,
                name: exercise.name,
                equipment: exercise.equipment,
                prescription: "\(max(exercise.targetSets, 1)) sets x \(exercise.targetReps)",
                rest: "60-90 sec",
                formCues: definition?.executionSteps ?? [
                    "Move with control.",
                    "Leave one clean rep in reserve.",
                    exercise.notes.isEmpty ? "Use a range that feels honest today." : exercise.notes
                ],
                commonMistakes: definition?.commonMistakes ?? [
                    "Rushing reps to finish faster.",
                    "Chasing load before form feels steady."
                ],
                musclesTargeted: definition?.primaryMuscles.map(\.rawValue) ?? [exercise.category],
                feel: definition?.howItShouldFeel ?? "Challenging but controlled. Stop before form gets noisy.",
                isLoggable: exercise.isLoggable
            )
        }

        let section = WorkoutSection(id: "\(id)-custom-section", kind: .strength, title: "Custom Workout", exercises: customExercises)
        let version = WorkoutVersion(
            id: "\(id)-custom-full",
            type: .full,
            duration: "Flexible",
            intention: notes.isEmpty ? "Brian-built session. Log the work and keep the floor reasonable." : notes,
            sections: [section]
        )

        return WorkoutPlan(
            id: id,
            title: name,
            weeklySlot: "Custom",
            focus: notes.isEmpty ? "Flexible session" : notes,
            versions: [version]
        )
    }

    private static func targetSets(from prescription: String) -> Int {
        let lower = prescription.lowercased()
        if let range = lower.range(of: #"\d+\s*-\s*\d+\s*sets"#, options: .regularExpression) {
            let values = lower[range]
                .components(separatedBy: CharacterSet.decimalDigits.inverted)
                .compactMap(Int.init)
            return values.last ?? values.first ?? 2
        }
        if let range = lower.range(of: #"\d+\s*sets"#, options: .regularExpression),
           let value = Int(lower[range].components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
            return value
        }
        return 2
    }

    private static func targetReps(from prescription: String) -> String {
        let lower = prescription.lowercased()
        if let range = lower.range(of: #"\d+\s*-\s*\d+"#, options: .regularExpression) {
            return lower[range].replacingOccurrences(of: " ", with: "")
        }
        if let range = lower.range(of: #"\d+\s*reps"#, options: .regularExpression) {
            let value = lower[range].components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            return value.isEmpty ? "8-10" : value
        }
        return "8-10"
    }
}
