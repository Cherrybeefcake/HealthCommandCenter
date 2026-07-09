import Foundation

struct HealthSnapshot: Codable, Equatable {
    var sleepHours: Double?
    var steps: Int?
    var workoutCount: Int?
    var workoutMinutes: Double?
    var restingHeartRate: Double?
    var hrvSDNN: Double?
    var activeEnergy: Double?
    var weightPounds: Double?
    var metricDiagnostics: [HealthMetricDiagnostic]?

    static let empty = HealthSnapshot()

    var availableMetricCount: Int {
        [
            sleepHours.map { _ in true },
            steps.map { _ in true },
            workoutCount.map { _ in true },
            restingHeartRate.map { _ in true },
            hrvSDNN.map { _ in true },
            activeEnergy.map { _ in true },
            weightPounds.map { _ in true }
        ].compactMap { $0 }.count
    }

    var hasAnyData: Bool {
        availableMetricCount > 0
    }
}

struct HealthMetricDiagnostic: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var valueText: String
    var statusText: String
    var queryWindow: String
    var detail: String
    var sampleDate: Date?
    var errorText: String?
}

struct OuraDailySummary: Codable, Equatable {
    var readinessScore: Int?
    var sleepScore: Int?
    var restingHeartRate: Double?
    var hrvBalance: String?
}
