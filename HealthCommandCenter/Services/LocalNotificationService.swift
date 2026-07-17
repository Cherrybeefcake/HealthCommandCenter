import Foundation
import UserNotifications

struct NotificationDebugStatus: Hashable {
    let permissionStatusText: String
    let scheduledReminderCount: Int
    let pendingHealthCommandCount: Int
    let isTestReminderPending: Bool
}

struct TestNotificationResult: Hashable {
    let didSchedule: Bool
    let message: String
    let status: NotificationDebugStatus
}

final class LocalNotificationService: NSObject, UNUserNotificationCenterDelegate {
    private let center: UNUserNotificationCenter
    private let testReminderIdentifier = "hcc.test.10sec"
    private let reminderIdentifiers = [
        "hcc.checkin.daily",
        "hcc.ritual.daily",
        "hcc.sleep.daily",
        "hcc.nutrition.daily",
        "hcc.workout.planned",
        "hcc.recovery.daily",
        "hcc.weekly.review"
    ]

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        super.init()
        self.center.delegate = self
    }

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleDailyReminders(
        settings: ReminderSettings,
        programPhase: ProgramPhase = .normalRoutine,
        workoutTimePreference: WorkoutTimePreference = .flexible,
        plannedSession: PlannedSession? = nil
    ) async -> NotificationDebugStatus {
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
                body: checkInReminderBody(for: programPhase),
                time: adaptiveCheckInTime(settings.checkInReminderTime, phase: programPhase)
            )
        }

        if settings.plannedWorkoutReminderEnabled, let plannedSession {
            await scheduleOneTimeReminder(
                identifier: "hcc.workout.planned",
                title: "Today’s Training",
                body: "\(plannedSession.workoutTitle): \(plannedSession.note)",
                time: adaptiveWorkoutTime(settings.plannedWorkoutReminderTime, phase: programPhase, preference: workoutTimePreference)
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

        if settings.recoveryReminderEnabled {
            await scheduleDailyReminder(
                identifier: "hcc.recovery.daily",
                title: "Recovery Check",
                body: "Mobility, hydration, and stress downshift. Keep the floor low.",
                time: settings.recoveryReminderTime
            )
        }

        if settings.sleepReminderEnabled {
            await scheduleDailyReminder(
                identifier: "hcc.sleep.daily",
                title: "Sleep Prep",
                body: sleepReminderBody(for: programPhase),
                time: adaptiveSleepTime(settings.sleepReminderTime, phase: programPhase)
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

        if settings.weeklyReviewReminderEnabled {
            await scheduleWeeklyReminder(
                identifier: "hcc.weekly.review",
                title: "Weekly Coach Report",
                body: "Review the week. Pick the next focus, not a punishment.",
                time: settings.weeklyReviewReminderTime
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
        do {
            try await center.add(request)
        } catch {
            return TestNotificationResult(
                didSchedule: false,
                message: "Test reminder could not be scheduled: \(error.localizedDescription)",
                status: await debugStatus()
            )
        }

        return TestNotificationResult(
            didSchedule: true,
            message: "Test reminder scheduled for about 10 seconds from now.",
            status: await debugStatus()
        )
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    func cancelAllHealthCommandReminders() {
        center.removePendingNotificationRequests(withIdentifiers: reminderIdentifiers + [testReminderIdentifier])
    }

    func debugStatus() async -> NotificationDebugStatus {
        async let settings = notificationSettings()
        async let requests = pendingRequests()
        let status = await settings.authorizationStatus
        let pending = await requests
        let count = pending.filter { reminderIdentifiers.contains($0.identifier) }.count
        let testPending = pending.contains { $0.identifier == testReminderIdentifier }
        let healthCommandCount = pending.filter { $0.identifier.hasPrefix("hcc.") }.count
        return NotificationDebugStatus(
            permissionStatusText: permissionText(for: status),
            scheduledReminderCount: count,
            pendingHealthCommandCount: healthCommandCount,
            isTestReminderPending: testPending
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

    private func scheduleWeeklyReminder(
        identifier: String,
        title: String,
        body: String,
        time: ReminderTime
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = time.dateComponents
        components.weekday = 1
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    private func scheduleOneTimeReminder(
        identifier: String,
        title: String,
        body: String,
        time: ReminderTime
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let triggerDate = nextDate(for: time)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    private func nextDate(for time: ReminderTime) -> Date {
        let candidate = time.date()
        if candidate > Date() { return candidate }
        return Calendar.current.date(byAdding: .day, value: 1, to: candidate) ?? candidate
    }

    private func adaptiveCheckInTime(_ time: ReminderTime, phase: ProgramPhase) -> ReminderTime {
        phase == .nightShift ? ReminderTime(hour: 15, minute: 0) : time
    }

    private func adaptiveSleepTime(_ time: ReminderTime, phase: ProgramPhase) -> ReminderTime {
        switch phase {
        case .nightShift:
            return ReminderTime(hour: 8, minute: 30)
        case .newBaby:
            return ReminderTime(hour: 20, minute: 30)
        case .dayShift, .normalRoutine:
            return time
        }
    }

    private func adaptiveWorkoutTime(_ time: ReminderTime, phase: ProgramPhase, preference: WorkoutTimePreference) -> ReminderTime {
        if phase == .nightShift || preference == .beginningOfShift { return ReminderTime(hour: 15, minute: 30) }
        if preference == .morning { return ReminderTime(hour: 8, minute: 30) }
        if preference == .afterShift { return ReminderTime(hour: 17, minute: 30) }
        return time
    }

    private func checkInReminderBody(for phase: ProgramPhase) -> String {
        switch phase {
        case .nightShift:
            return "Classify the shift before intensity. Protect the sleep window."
        case .newBaby:
            return "Tiny floor first. Classify today without pressure."
        case .dayShift, .normalRoutine:
            return "Start with the data. Classify today."
        }
    }

    private func sleepReminderBody(for phase: ProgramPhase) -> String {
        switch phase {
        case .nightShift:
            return "Start the post-shift wind-down. Protect the next sleep window."
        case .newBaby:
            return "Take the next real sleep chance. Lower the floor."
        case .dayShift, .normalRoutine:
            return "Start the wind-down. Protect tomorrow."
        }
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
