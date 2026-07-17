import Foundation

enum TargetPeriod: String, Codable, CaseIterable, Identifiable, Hashable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"

    var id: String { rawValue }
}

enum GoalStatus: String, Hashable {
    case noData = "No data yet"
    case building = "Building"
    case onTrack = "On track"
    case steady = "Steady"
}

struct GoalSettings: Codable, Hashable {
    var bodyRecompositionEnabled: Bool
    var strengthEnabled: Bool
    var workoutFrequencyPerWeek: Int
    var proteinTargetGrams: Int
    var hydrationTargetOunces: Int
    var sleepTargetHours: Double
    var meditationDaysPerWeek: Int
    var mobilityDaysPerWeek: Int
    var consistencyDaysPerWeek: Int
    var weightTrendGoalText: String
    var waistTrendGoalText: String

    static let brianDefault = GoalSettings(
        bodyRecompositionEnabled: true,
        strengthEnabled: true,
        workoutFrequencyPerWeek: 3,
        proteinTargetGrams: 160,
        hydrationTargetOunces: 100,
        sleepTargetHours: 7.0,
        meditationDaysPerWeek: 4,
        mobilityDaysPerWeek: 4,
        consistencyDaysPerWeek: 5,
        weightTrendGoalText: "Trend slowly while recomposition anchors stay consistent.",
        waistTrendGoalText: "Watch direction over weeks, not daily noise."
    )
}

struct GoalDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let targetText: String
    let period: TargetPeriod
}

struct GoalProgress: Identifiable, Hashable {
    let id: String
    let title: String
    let currentText: String
    let targetText: String
    let status: GoalStatus
    let coachingLine: String
    let progressFraction: Double?

    var statusText: String {
        status.rawValue
    }
}
