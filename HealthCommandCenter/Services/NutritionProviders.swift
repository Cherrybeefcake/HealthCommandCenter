import Foundation

enum NutritionDataSource: String, Codable, CaseIterable, Identifiable, Hashable {
    case manualHCC = "HCC manual"
    case appleHealth = "Apple Health"
    case cronometerAppleHealth = "Cronometer via Apple Health"
    case external = "External provider"
    case none = "No nutrition source"

    var id: String { rawValue }
}

struct NutritionSourceDecision: Hashable {
    let log: DailyNutritionLog
    let source: NutritionDataSource
    let detail: String

    var sourceLabel: String {
        source.rawValue
    }
}

protocol NutritionDataProvider {
    var source: NutritionDataSource { get }
    func todayLog(dateKey: String, targets: NutritionTargets) -> DailyNutritionLog?
}

struct ManualNutritionProvider: NutritionDataProvider {
    let logs: [DailyNutritionLog]
    var source: NutritionDataSource { .manualHCC }

    func todayLog(dateKey: String, targets: NutritionTargets) -> DailyNutritionLog? {
        guard let log = logs.first(where: { $0.dateKey == dateKey }) else { return nil }
        let hasManual = log.caloriesLogged != nil
            || log.proteinGrams != nil
            || log.waterOunces != nil
            || log.fiberGrams != nil
            || log.cronometerCompleted
            || !log.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasManual ? log : nil
    }
}

struct AppleHealthNutritionProvider: NutritionDataProvider {
    let summary: HealthNutritionSummary?
    var source: NutritionDataSource {
        summary?.appearsFromCronometer == true ? .cronometerAppleHealth : .appleHealth
    }

    func todayLog(dateKey: String, targets: NutritionTargets) -> DailyNutritionLog? {
        guard let nutrition = summary, nutrition.availableMetricCount > 0 else { return nil }
        return DailyNutritionLog(
            dateKey: dateKey,
            caloriesLogged: nutrition.calories.map { Int($0.rounded()) },
            proteinGrams: nutrition.proteinGrams.map { Int($0.rounded()) },
            waterOunces: nutrition.waterOunces.map { Int($0.rounded()) },
            fiberGrams: nutrition.fiberGrams.map { Int($0.rounded()) },
            cronometerCompleted: false,
            proteinTargetHit: (nutrition.proteinGrams ?? 0) >= Double(targets.proteinGrams),
            waterTargetHit: (nutrition.waterOunces ?? 0) >= Double(targets.waterOunces),
            notes: nutrition.sourceLabel
        )
    }
}

protocol ExternalNutritionProvider: NutritionDataProvider {
    var providerName: String { get }
}

struct PlaceholderExternalNutritionProvider: ExternalNutritionProvider {
    let providerName: String
    var source: NutritionDataSource { .external }

    func todayLog(dateKey: String, targets: NutritionTargets) -> DailyNutritionLog? {
        nil
    }
}

struct NutritionSourceResolver {
    static func resolve(
        manual: ManualNutritionProvider,
        appleHealth: AppleHealthNutritionProvider,
        external: NutritionDataProvider? = nil,
        dateKey: String,
        targets: NutritionTargets,
        detailBuilder: (DailyNutritionLog) -> String
    ) -> NutritionSourceDecision {
        if let manualLog = manual.todayLog(dateKey: dateKey, targets: targets) {
            return NutritionSourceDecision(log: manualLog, source: manual.source, detail: detailBuilder(manualLog))
        }
        if let appleLog = appleHealth.todayLog(dateKey: dateKey, targets: targets) {
            return NutritionSourceDecision(log: appleLog, source: appleHealth.source, detail: detailBuilder(appleLog))
        }
        if let externalLog = external?.todayLog(dateKey: dateKey, targets: targets) {
            return NutritionSourceDecision(log: externalLog, source: external?.source ?? .external, detail: detailBuilder(externalLog))
        }
        return NutritionSourceDecision(
            log: DailyNutritionLog(dateKey: dateKey),
            source: .none,
            detail: "No Apple Health nutrition samples found. Save anchors manually in Ritual."
        )
    }
}
