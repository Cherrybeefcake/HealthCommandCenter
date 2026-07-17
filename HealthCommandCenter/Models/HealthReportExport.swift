import Foundation

struct HealthReportExport: Codable {
    let generatedAt: Date
    let appVersion: String
    let weeklyCoachSummary: String
    let checkIns: [CheckIn]
    let exerciseLogs: [ExerciseLog]
    let ritualLogs: [DailyRitualLog]
    let nutritionLogs: [DailyNutritionLog]
    let bodyMetricsEntries: [BodyMetricsEntry]
    let customWorkouts: [CustomWorkout]
    let ouraManualSnapshots: [OuraManualSnapshot]
    let goalSettings: GoalSettings
}

struct ExportedReportFile: Identifiable, Hashable {
    let id: String
    let title: String
    let url: URL
}
