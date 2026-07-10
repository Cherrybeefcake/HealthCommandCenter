import Foundation

enum BodyMetricsSource: String, Codable, CaseIterable, Identifiable, Hashable {
    case appleHealth = "Apple Health"
    case manual = "Manual"
    case smartScaleManual = "Smart Scale Manual"
    case unknown = "Unknown"

    var id: String { rawValue }
}

struct BodyMetricsEntry: Codable, Identifiable, Hashable {
    var id: String { "\(dateKey)-\(source.rawValue)" }
    var dateKey: String
    var weightPounds: Double?
    var bodyFatPercent: Double?
    var muscleMassPounds: Double?
    var visceralFatLevel: Double?
    var waistInches: Double?
    var notes: String
    var source: BodyMetricsSource
    var updatedAt: Date

    init(
        dateKey: String = RitualLibrary.dateKey(),
        weightPounds: Double? = nil,
        bodyFatPercent: Double? = nil,
        muscleMassPounds: Double? = nil,
        visceralFatLevel: Double? = nil,
        waistInches: Double? = nil,
        notes: String = "",
        source: BodyMetricsSource = .manual,
        updatedAt: Date = Date()
    ) {
        self.dateKey = dateKey
        self.weightPounds = weightPounds
        self.bodyFatPercent = bodyFatPercent
        self.muscleMassPounds = muscleMassPounds
        self.visceralFatLevel = visceralFatLevel
        self.waistInches = waistInches
        self.notes = notes
        self.source = source
        self.updatedAt = updatedAt
    }

    var hasAnyMetric: Bool {
        weightPounds != nil
            || bodyFatPercent != nil
            || muscleMassPounds != nil
            || visceralFatLevel != nil
            || waistInches != nil
    }
}

struct BodyMetricsSummary: Hashable {
    let latestEntry: BodyMetricsEntry?
    let appleHealthEntry: BodyMetricsEntry?
    let appleHealthWeightPounds: Double?
    let trendText: String
    let bodyFatTrendText: String?
    let waistTrendText: String?

    var latestWeightText: String {
        let latest = [latestEntry, appleHealthEntry].compactMap { $0 }.sorted { $0.updatedAt > $1.updatedAt }.first
        if let weight = latest?.weightPounds {
            return String(format: "%.1f lb", weight)
        }
        return "No weight yet"
    }

    var sourceText: String {
        let latest = [latestEntry, appleHealthEntry].compactMap { $0 }.sorted { $0.updatedAt > $1.updatedAt }.first
        if let latest { return latest.source.rawValue }
        return "No source"
    }
}
