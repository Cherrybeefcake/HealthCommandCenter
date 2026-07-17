import Foundation

struct RecordSchemaMetadata: Codable, Hashable {
    let schemaVersion: Int
    let source: String
    let updatedAt: Date

    static func local(version: Int = 1, updatedAt: Date = Date()) -> RecordSchemaMetadata {
        RecordSchemaMetadata(schemaVersion: version, source: "local", updatedAt: updatedAt)
    }
}

protocol CheckInRepository {
    func loadCheckIns() -> [CheckIn]
    func save(_ checkIns: [CheckIn])
}

protocol WorkoutLogRepository {
    func loadExerciseLogs() -> [ExerciseLog]
    func saveExerciseLogs(_ logs: [ExerciseLog])
    func deleteWorkoutLogs()
}

protocol CustomWorkoutRepository {
    func loadCustomWorkouts() -> [CustomWorkout]
    func saveCustomWorkouts(_ workouts: [CustomWorkout])
}

protocol RitualLogRepository {
    func loadRitualLogs() -> [DailyRitualLog]
    func saveRitualLogs(_ logs: [DailyRitualLog])
    func resetTodaysRitual(dateKey: String)
}

protocol NutritionLogRepository {
    func loadNutritionLogs() -> [DailyNutritionLog]
    func saveNutritionLogs(_ logs: [DailyNutritionLog])
}

protocol BodyMetricsRepository {
    func loadBodyMetricsEntries() -> [BodyMetricsEntry]
    func saveBodyMetricsEntries(_ entries: [BodyMetricsEntry])
}

protocol OuraSnapshotRepository {
    func loadOuraManualSnapshots() -> [OuraManualSnapshot]
    func saveOuraManualSnapshots(_ snapshots: [OuraManualSnapshot])
}

protocol ProgressPhotoRepository {
    func loadProgressPhotos() -> [ProgressPhotoEntry]
    func saveProgressPhotos(_ photos: [ProgressPhotoEntry])
    func saveProgressPhotoImage(_ data: Data, fileName: String) throws
    func progressPhotoImageURL(fileName: String) -> URL
    func deleteProgressPhotoImage(fileName: String)
}

protocol GoalSettingsRepository {
    var goalSettings: GoalSettings { get set }
}

protocol ProfilePreferencesRepository {
    var userName: String { get set }
    var hasSeenGreeting: Bool { get set }
    var programPhase: ProgramPhase { get set }
    var trainingLocation: TrainingLocation { get set }
    var workoutTimePreference: WorkoutTimePreference { get set }
    var personalizationSettings: PersonalizationSettings { get set }
    var reminderSettings: ReminderSettings { get set }
    var ouraConnectionSettings: OuraConnectionSettings { get set }
    var programScheduleOverrides: [ProgramScheduleOverride] { get set }
    var favoriteExerciseIDs: [String] { get set }
    var recentlyViewedExerciseIDs: [String] { get set }
    var recentlyUsedExerciseIDs: [String] { get set }
    var savedRecoveryFlowExerciseIDs: [String] { get set }
}

protocol LocalAppDataRepository:
    CheckInRepository,
    WorkoutLogRepository,
    CustomWorkoutRepository,
    RitualLogRepository,
    NutritionLogRepository,
    BodyMetricsRepository,
    OuraSnapshotRepository,
    ProgressPhotoRepository,
    GoalSettingsRepository,
    ProfilePreferencesRepository {
    func resetGreetingState()
    func deleteAllLocalData()
}

extension LocalStorageService: LocalAppDataRepository {}
