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

struct OuraDailySummary: Codable, Equatable {
    var readinessScore: Int?
    var sleepScore: Int?
    var restingHeartRate: Double?
    var hrvBalance: String?
}
