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
}

extension CustomWorkout {
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
}
