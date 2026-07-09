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

struct RecoverySourceDecision: Hashable {
    let primarySource: SleepSource
    let primaryReason: String
    let supportingContext: String
    let subjectiveOverrideText: String?
    let usesAppleHealthPrimary: Bool
    let usesOuraSupplement: Bool
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
    var hrv: Double?
    var bodyTemperatureTrend: String?
    var hrvBalance: String?
}

enum OuraConnectionMode: String, Codable, CaseIterable, Identifiable, Hashable {
    case notConnected = "Not Connected"
    case mock = "Mock/Test"
    case manual = "Manual Entry"
    case futureOAuth = "Future OAuth"

    var id: String { rawValue }
}

enum RecoveryDataSource: String, Codable, CaseIterable, Identifiable, Hashable {
    case appleHealth = "Apple Health"
    case oura = "Oura"
    case manualCheckIn = "Manual Check-In"
    case automaticBestAvailable = "Automatic Best Available"

    var id: String { rawValue }
}

struct OuraConnectionSettings: Codable, Hashable {
    var isEnabled: Bool
    var connectionMode: OuraConnectionMode
    var preferredRecoverySource: RecoveryDataSource
    var lastMockUpdate: Date?
    var notes: String

    static let `default` = OuraConnectionSettings(
        isEnabled: false,
        connectionMode: .notConnected,
        preferredRecoverySource: .automaticBestAvailable,
        lastMockUpdate: nil,
        notes: ""
    )
}

struct OuraManualSnapshot: Codable, Identifiable, Hashable {
    var id: String { dateKey }
    var dateKey: String
    var readinessScore: Int?
    var sleepScore: Int?
    var sleepDurationHours: Double?
    var hrv: Double?
    var restingHeartRate: Double?
    var bodyTemperatureTrend: String?
    var notes: String
    var updatedAt: Date

    init(
        dateKey: String = RitualLibrary.dateKey(),
        readinessScore: Int? = nil,
        sleepScore: Int? = nil,
        sleepDurationHours: Double? = nil,
        hrv: Double? = nil,
        restingHeartRate: Double? = nil,
        bodyTemperatureTrend: String? = nil,
        notes: String = "",
        updatedAt: Date = Date()
    ) {
        self.dateKey = dateKey
        self.readinessScore = readinessScore
        self.sleepScore = sleepScore
        self.sleepDurationHours = sleepDurationHours
        self.hrv = hrv
        self.restingHeartRate = restingHeartRate
        self.bodyTemperatureTrend = bodyTemperatureTrend
        self.notes = notes
        self.updatedAt = updatedAt
    }

    var dailySummary: OuraDailySummary {
        OuraDailySummary(
            readinessScore: readinessScore,
            sleepScore: sleepScore,
            sleepDurationHours: sleepDurationHours,
            restingHeartRate: restingHeartRate,
            hrv: hrv,
            bodyTemperatureTrend: bodyTemperatureTrend,
            hrvBalance: nil
        )
    }

    var hasRecoveryValues: Bool {
        readinessScore != nil || sleepScore != nil || sleepDurationHours != nil || hrv != nil || restingHeartRate != nil
    }
}
