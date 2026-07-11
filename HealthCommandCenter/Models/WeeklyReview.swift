import Foundation

struct WeeklyReview: Hashable {
    let weekStartDate: Date
    let weekEndDate: Date
    let checkInCount: Int
    let workoutDays: Int
    let totalSets: Int
    let ritualDays: Int
    let ritualCompletionPercent: Int
    let nutritionLoggedDays: Int
    let averageProtein: Int?
    let averageWater: Int?
    let averageSleep: Double?
    let lowSleepDays: Int
    let bodyWeightTrendText: String
    let mostCommonReadiness: ReadinessCategory?
    let consistencyScoreText: String
    let wins: [String]
    let watchouts: [String]
    let nextWeekFocus: [String]
    let coachSummary: String

    var hasUsefulData: Bool {
        checkInCount > 0 || workoutDays > 0 || ritualDays > 0 || nutritionLoggedDays > 0
    }
}
