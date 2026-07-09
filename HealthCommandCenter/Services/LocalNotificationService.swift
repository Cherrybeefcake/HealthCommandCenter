import Foundation
import UserNotifications

struct NotificationDebugStatus: Hashable {
    let permissionStatusText: String
    let scheduledReminderCount: Int
}

final class LocalNotificationService {
    private let center: UNUserNotificationCenter
    private let reminderIdentifiers = [
        "hcc.checkin.daily",
        "hcc.ritual.daily",
        "hcc.sleep.daily",
        "hcc.nutrition.daily"
    ]

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleDailyReminders(settings: ReminderSettings) async -> NotificationDebugStatus {
        cancelAllHealthCommandReminders()
        guard settings.remindersEnabled else {
            return await debugStatus()
        }

        let granted = await requestPermission()
        guard granted else {
            return await debugStatus()
        }

        if settings.checkInReminderEnabled {
            scheduleDailyReminder(
                identifier: "hcc.checkin.daily",
                title: "Health Command Center",
                body: "Start with the data. Classify today.",
                time: settings.checkInReminderTime
            )
        }

        if settings.ritualReminderEnabled {
            scheduleDailyReminder(
                identifier: "hcc.ritual.daily",
                title: "Today’s Ritual",
                body: "Keep the floor low. Finish today’s ritual.",
                time: settings.ritualReminderTime
            )
        }

        if settings.sleepReminderEnabled {
            scheduleDailyReminder(
                identifier: "hcc.sleep.daily",
                title: "Sleep Prep",
                body: "Start the wind-down. Protect tomorrow.",
                time: settings.sleepReminderTime
            )
        }

        if settings.nutritionReminderEnabled {
            scheduleDailyReminder(
                identifier: "hcc.nutrition.daily",
                title: "Nutrition Anchors",
                body: "Log Cronometer and hit the anchors.",
                time: settings.nutritionReminderTime
            )
        }

        return await debugStatus()
    }

    func cancelAllHealthCommandReminders() {
        center.removePendingNotificationRequests(withIdentifiers: reminderIdentifiers)
    }

    func debugStatus() async -> NotificationDebugStatus {
        async let settings = notificationSettings()
        async let requests = pendingRequests()
        let status = await settings.authorizationStatus
        let count = await requests.filter { reminderIdentifiers.contains($0.identifier) }.count
        return NotificationDebugStatus(
            permissionStatusText: permissionText(for: status),
            scheduledReminderCount: count
        )
    }

    private func scheduleDailyReminder(
        identifier: String,
        title: String,
        body: String,
        time: ReminderTime
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: time.dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request) { _ in }
    }

    private func notificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    private func pendingRequests() async -> [UNNotificationRequest] {
        await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }

    private func permissionText(for status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "Not requested"
        case .denied:
            return "Denied"
        case .authorized:
            return "Authorized"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }
}
