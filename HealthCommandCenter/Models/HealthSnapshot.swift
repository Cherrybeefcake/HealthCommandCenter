import Foundation

struct HealthSnapshot: Codable, Equatable {
    var sleepHours: Double?
    var sleepSummary: SleepSummary?
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

enum SleepSource: String, Codable, Equatable, Hashable {
    case appleHealth = "Apple Health"
    case oura = "Oura"
    case manualCheckIn = "Manual Check In"
    case none = "None"
}

struct SleepSummary: Codable, Equatable, Hashable {
    var durationHours: Double?
    var durationText: String
    var source: SleepSource
    var label: String
    var detailText: String
    var endDate: Date?
    var includesNapContext: Bool
    var lookupWindowDescription: String?

    static let none = SleepSummary(
        durationHours: nil,
        durationText: "No sleep data",
        source: .none,
        label: "No sleep data",
        detailText: "No sleep source returned a usable latest sleep value.",
        endDate: nil,
        includesNapContext: false,
        lookupWindowDescription: nil
    )

    var sourceLabel: String {
        switch source {
        case .appleHealth:
            return "Apple Health latest sleep"
        case .oura:
            return "Oura latest sleep"
        case .manualCheckIn:
            return "Manual check-in sleep"
        case .none:
            return "No sleep data"
        }
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
    var sleepDurationHours: Double?
    var restingHeartRate: Double?
    var hrvBalance: String?
}
