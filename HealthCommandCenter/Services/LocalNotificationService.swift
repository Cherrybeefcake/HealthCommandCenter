import Foundation
import UserNotifications

struct NotificationDebugStatus: Hashable {
    let permissionStatusText: String
    let scheduledReminderCount: Int
}

struct TestNotificationResult: Hashable {
    let didSchedule: Bool
    let message: String
    let status: NotificationDebugStatus
}

final class LocalNotificationService {
    private let center: UNUserNotificationCenter
    private let testReminderIdentifier = "hcc.test.10sec"
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
            await scheduleDailyReminder(
                identifier: "hcc.checkin.daily",
                title: "Health Command Center",
                body: "Start with the data. Classify today.",
                time: settings.checkInReminderTime
            )
        }

        if settings.ritualReminderEnabled {
            await scheduleDailyReminder(
                identifier: "hcc.ritual.daily",
                title: "Today’s Ritual",
                body: "Keep the floor low. Finish today’s ritual.",
                time: settings.ritualReminderTime
            )
        }

        if settings.sleepReminderEnabled {
            await scheduleDailyReminder(
                identifier: "hcc.sleep.daily",
                title: "Sleep Prep",
                body: "Start the wind-down. Protect tomorrow.",
                time: settings.sleepReminderTime
            )
        }

        if settings.nutritionReminderEnabled {
            await scheduleDailyReminder(
                identifier: "hcc.nutrition.daily",
                title: "Nutrition Anchors",
                body: "Log Cronometer and hit the anchors.",
                time: settings.nutritionReminderTime
            )
        }

        return await debugStatus()
    }

    func scheduleTestReminder(secondsFromNow: TimeInterval = 10) async -> TestNotificationResult {
        center.removePendingNotificationRequests(withIdentifiers: [testReminderIdentifier])
        let granted = await requestPermission()
        guard granted else {
            return TestNotificationResult(
                didSchedule: false,
                message: "Notifications are not allowed. Enable them in iOS Settings, then test again.",
                status: await debugStatus()
            )
        }

        let content = UNMutableNotificationContent()
        content.title = "Health Command Center Test"
        content.body = "Test reminder: local notifications are working."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(secondsFromNow, 1), repeats: false)
        let request = UNNotificationRequest(identifier: testReminderIdentifier, content: content, trigger: trigger)
        try? await center.add(request)

        return TestNotificationResult(
            didSchedule: true,
            message: "Test reminder scheduled for about 10 seconds from now.",
            status: await debugStatus()
        )
    }

    func cancelAllHealthCommandReminders() {
        center.removePendingNotificationRequests(withIdentifiers: reminderIdentifiers + [testReminderIdentifier])
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
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: time.dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
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
