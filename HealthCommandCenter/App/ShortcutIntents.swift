import AppIntents
import Foundation

@available(iOS 16.0, *)
struct StartCheckInIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Check In"
    static var description = IntentDescription("Open Health Command Center to start today's Check In.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: "Open Health Command Center and start Check In from Today.")
    }
}

@available(iOS 16.0, *)
struct OpenTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Today"
    static var description = IntentDescription("Open the Today command center.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: "Opening Today.")
    }
}

@available(iOS 16.0, *)
struct OpenTrainIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Train"
    static var description = IntentDescription("Open Health Command Center for training and workout logging.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: "Opening Train.")
    }
}

@available(iOS 16.0, *)
struct RefreshHealthDataIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Health Data"
    static var description = IntentDescription("Open Health Command Center so Apple Health data can be refreshed.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: "Open Health Command Center and tap Refresh Health Data.")
    }
}

@available(iOS 16.0, *)
struct LogDailyWinIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Daily Win"
    static var description = IntentDescription("Save a short Daily Win for today's Recovery ritual.")
    static var openAppWhenRun = false

    @Parameter(title: "Daily Win")
    var dailyWin: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let cleanText = dailyWin.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else {
            return .result(dialog: "Daily Win was empty, so nothing changed.")
        }

        let storage = LocalStorageService()
        let dateKey = RitualLibrary.dateKey()
        let dailyWinItemID = RitualItemKind.dailyWin.rawValue
            .lowercased()
            .replacingOccurrences(of: " / ", with: "-")
            .replacingOccurrences(of: " ", with: "-")
        var logs = storage.loadRitualLogs()
        if let index = logs.firstIndex(where: { $0.dateKey == dateKey }) {
            logs[index].dailyWinText = cleanText
            logs[index].completedItemIDs.insert(dailyWinItemID)
            logs[index].updatedAt = Date()
        } else {
            logs.insert(
                DailyRitualLog(
                    dateKey: dateKey,
                    completedItemIDs: [dailyWinItemID],
                    dailyWinText: cleanText
                ),
                at: 0
            )
        }
        storage.saveRitualLogs(logs)
        return .result(dialog: "Daily Win saved.")
    }
}

@available(iOS 16.0, *)
struct HealthCommandCenterShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenTodayIntent(),
            phrases: ["Open \(.applicationName)", "Open Today in \(.applicationName)"],
            shortTitle: "Open Today",
            systemImageName: "sun.max"
        )
        AppShortcut(
            intent: StartCheckInIntent(),
            phrases: ["Start Check In in \(.applicationName)", "Classify today in \(.applicationName)"],
            shortTitle: "Start Check In",
            systemImageName: "slider.horizontal.3"
        )
        AppShortcut(
            intent: OpenTrainIntent(),
            phrases: ["Open Train in \(.applicationName)", "Log workout in \(.applicationName)"],
            shortTitle: "Open Train",
            systemImageName: "dumbbell"
        )
        AppShortcut(
            intent: LogDailyWinIntent(),
            phrases: ["Log Daily Win in \(.applicationName)"],
            shortTitle: "Log Daily Win",
            systemImageName: "checkmark.seal"
        )
        AppShortcut(
            intent: RefreshHealthDataIntent(),
            phrases: ["Refresh Health Data in \(.applicationName)"],
            shortTitle: "Refresh Health",
            systemImageName: "heart.text.square"
        )
    }
}
