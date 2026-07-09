import Foundation

final class LocalStorageService {
    private let userDefaults: UserDefaults
    private let checkInsURL: URL
    private let exerciseLogsURL: URL
    private let ritualLogsURL: URL
    private let nutritionLogsURL: URL
    private let ouraManualSnapshotsURL: URL
    private let bodyMetricsEntriesURL: URL

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.checkInsURL = documentsURL.appendingPathComponent("checkins.json")
        self.exerciseLogsURL = documentsURL.appendingPathComponent("workout_logs.json")
        self.ritualLogsURL = documentsURL.appendingPathComponent("daily_ritual_logs.json")
        self.nutritionLogsURL = documentsURL.appendingPathComponent("daily_nutrition_logs.json")
        self.ouraManualSnapshotsURL = documentsURL.appendingPathComponent("oura_manual_snapshots.json")
        self.bodyMetricsEntriesURL = documentsURL.appendingPathComponent("body_metrics_entries.json")
    }

    var userName: String {
        get { userDefaults.string(forKey: "userName") ?? "Brian" }
        set { userDefaults.set(newValue, forKey: "userName") }
    }

    var hasSeenGreeting: Bool {
        get { userDefaults.bool(forKey: "hasSeenGreeting") }
        set { userDefaults.set(newValue, forKey: "hasSeenGreeting") }
    }

    func resetGreetingState() {
        userDefaults.set(false, forKey: "hasSeenGreeting")
    }

    var programPhase: ProgramPhase {
        get {
            userDefaults.string(forKey: "programPhase").flatMap(ProgramPhase.init(rawValue:)) ?? .normalRoutine
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: "programPhase")
        }
    }

    var trainingLocation: TrainingLocation {
        get {
            userDefaults.string(forKey: "trainingLocation").flatMap(TrainingLocation.init(rawValue:)) ?? .home
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: "trainingLocation")
        }
    }

    var workoutTimePreference: WorkoutTimePreference {
        get {
            userDefaults.string(forKey: "workoutTimePreference").flatMap(WorkoutTimePreference.init(rawValue:)) ?? .flexible
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: "workoutTimePreference")
        }
    }

    var personalizationSettings: PersonalizationSettings {
        get {
            guard let data = userDefaults.data(forKey: "personalizationSettings"),
                  let settings = try? JSONDecoder.healthCommand.decode(PersonalizationSettings.self, from: data) else {
                return .brianDefault
            }
            return settings
        }
        set {
            guard let data = try? JSONEncoder.healthCommand.encode(newValue) else { return }
            userDefaults.set(data, forKey: "personalizationSettings")
        }
    }

    var reminderSettings: ReminderSettings {
        get {
            guard let data = userDefaults.data(forKey: "reminderSettings"),
                  let settings = try? JSONDecoder.healthCommand.decode(ReminderSettings.self, from: data) else {
                return .default
            }
            return settings
        }
        set {
            guard let data = try? JSONEncoder.healthCommand.encode(newValue) else { return }
            userDefaults.set(data, forKey: "reminderSettings")
        }
    }

    var ouraConnectionSettings: OuraConnectionSettings {
        get {
            guard let data = userDefaults.data(forKey: "ouraConnectionSettings"),
                  let settings = try? JSONDecoder.healthCommand.decode(OuraConnectionSettings.self, from: data) else {
                return .default
            }
            return settings
        }
        set {
            guard let data = try? JSONEncoder.healthCommand.encode(newValue) else { return }
            userDefaults.set(data, forKey: "ouraConnectionSettings")
        }
    }

    func loadCheckIns() -> [CheckIn] {
        guard let data = try? Data(contentsOf: checkInsURL) else { return [] }
        return (try? JSONDecoder.healthCommand.decode([CheckIn].self, from: data)) ?? []
    }

    func save(_ checkIns: [CheckIn]) {
        guard let data = try? JSONEncoder.healthCommand.encode(checkIns) else { return }
        try? data.write(to: checkInsURL, options: [.atomic])
    }

    func loadExerciseLogs() -> [ExerciseLog] {
        guard let data = try? Data(contentsOf: exerciseLogsURL) else { return [] }
        return (try? JSONDecoder.healthCommand.decode([ExerciseLog].self, from: data)) ?? []
    }

    func saveExerciseLogs(_ logs: [ExerciseLog]) {
        guard let data = try? JSONEncoder.healthCommand.encode(logs) else { return }
        try? data.write(to: exerciseLogsURL, options: [.atomic])
    }

    func loadRitualLogs() -> [DailyRitualLog] {
        guard let data = try? Data(contentsOf: ritualLogsURL) else { return [] }
        return (try? JSONDecoder.healthCommand.decode([DailyRitualLog].self, from: data)) ?? []
    }

    func saveRitualLogs(_ logs: [DailyRitualLog]) {
        guard let data = try? JSONEncoder.healthCommand.encode(logs) else { return }
        try? data.write(to: ritualLogsURL, options: [.atomic])
    }

    func loadNutritionLogs() -> [DailyNutritionLog] {
        guard let data = try? Data(contentsOf: nutritionLogsURL) else { return [] }
        return (try? JSONDecoder.healthCommand.decode([DailyNutritionLog].self, from: data)) ?? []
    }

    func saveNutritionLogs(_ logs: [DailyNutritionLog]) {
        guard let data = try? JSONEncoder.healthCommand.encode(logs) else { return }
        try? data.write(to: nutritionLogsURL, options: [.atomic])
    }

    func loadOuraManualSnapshots() -> [OuraManualSnapshot] {
        guard let data = try? Data(contentsOf: ouraManualSnapshotsURL) else { return [] }
        return (try? JSONDecoder.healthCommand.decode([OuraManualSnapshot].self, from: data)) ?? []
    }

    func saveOuraManualSnapshots(_ snapshots: [OuraManualSnapshot]) {
        guard let data = try? JSONEncoder.healthCommand.encode(snapshots) else { return }
        try? data.write(to: ouraManualSnapshotsURL, options: [.atomic])
    }

    func loadBodyMetricsEntries() -> [BodyMetricsEntry] {
        guard let data = try? Data(contentsOf: bodyMetricsEntriesURL) else { return [] }
        return (try? JSONDecoder.healthCommand.decode([BodyMetricsEntry].self, from: data)) ?? []
    }

    func saveBodyMetricsEntries(_ entries: [BodyMetricsEntry]) {
        guard let data = try? JSONEncoder.healthCommand.encode(entries) else { return }
        try? data.write(to: bodyMetricsEntriesURL, options: [.atomic])
    }

    func resetTodaysRitual(dateKey: String) {
        var logs = loadRitualLogs()
        if let index = logs.firstIndex(where: { $0.dateKey == dateKey }) {
            logs[index].completedItemIDs = []
            logs[index].updatedAt = Date()
            saveRitualLogs(logs)
        }
    }

    func deleteWorkoutLogs() {
        try? FileManager.default.removeItem(at: exerciseLogsURL)
    }

    func deleteAllLocalData() {
        try? FileManager.default.removeItem(at: checkInsURL)
        try? FileManager.default.removeItem(at: exerciseLogsURL)
        try? FileManager.default.removeItem(at: ritualLogsURL)
        try? FileManager.default.removeItem(at: nutritionLogsURL)
        try? FileManager.default.removeItem(at: ouraManualSnapshotsURL)
        try? FileManager.default.removeItem(at: bodyMetricsEntriesURL)
        ["userName", "hasSeenGreeting", "programPhase", "trainingLocation", "workoutTimePreference", "personalizationSettings", "reminderSettings", "ouraConnectionSettings"].forEach {
            userDefaults.removeObject(forKey: $0)
        }
    }
}

private extension JSONEncoder {
    static var healthCommand: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var healthCommand: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
