import Foundation

enum AppStrings {
    enum Action {
        static let startCheckIn = String(localized: "Start Check In")
        static let refreshHealthData = String(localized: "Refresh health data")
        static let saveNutrition = String(localized: "Save nutrition summary")
        static let saveBodyMetrics = String(localized: "Save today's body metrics")
        static let scheduleTestReminder = String(localized: "Schedule test reminder")
    }

    enum Accessibility {
        static let deleteLoggedSet = String(localized: "Delete logged set")
        static let deleteCustomWorkout = String(localized: "Delete custom workout")
        static let deleteProgressPhoto = String(localized: "Delete progress photo")
        static let openProfile = String(localized: "Open profile")
        static let markRitualComplete = String(localized: "Mark ritual item complete")
        static let markRitualIncomplete = String(localized: "Mark ritual item incomplete")
    }
}
