import Foundation
import HealthKit

final class HealthKitHealthDataService: HealthDataProviding {
    private let store = HKHealthStore()

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { throw HealthDataError.unavailable }

        let readTypes = Set([
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
            HKObjectType.quantityType(forIdentifier: .stepCount),
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .restingHeartRate),
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            HKObjectType.quantityType(forIdentifier: .bodyMass)
        ].compactMap { $0 })

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            store.requestAuthorization(toShare: [], read: readTypes) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthDataError.authorizationDenied)
                }
            }
        }
    }

    func fetchTodaySnapshot() async throws -> HealthSnapshot {
        guard HKHealthStore.isHealthDataAvailable() else { throw HealthDataError.unavailable }

        let sleep = await sleepResult()
        let steps = await quantitySumResult(
            id: "steps",
            title: "Steps",
            identifier: .stepCount,
            unit: .count(),
            unitText: "steps",
            window: .today
        )
        let activeEnergy = await quantitySumResult(
            id: "active-energy",
            title: "Active Energy",
            identifier: .activeEnergyBurned,
            unit: .kilocalorie(),
            unitText: "kcal",
            window: .today
        )
        let restingHeartRate = await recentQuantityResult(
            id: "resting-hr",
            title: "Resting HR",
            identifier: .restingHeartRate,
            unit: HKUnit.count().unitDivided(by: HKUnit.minute()),
            unitText: "bpm"
        )
        let hrv = await recentQuantityResult(
            id: "hrv",
            title: "HRV",
            identifier: .heartRateVariabilitySDNN,
            unit: .secondUnit(with: .milli),
            unitText: "ms"
        )
        let weight = await recentQuantityResult(
            id: "weight",
            title: "Body Weight",
            identifier: .bodyMass,
            unit: .pound(),
            unitText: "lb"
        )
        let workoutSummary = await workoutResult()

        return HealthSnapshot(
            sleepHours: sleep.value,
            steps: steps.value.map { Int($0.rounded()) },
            workoutCount: workoutSummary.count,
            workoutMinutes: workoutSummary.minutes,
            restingHeartRate: restingHeartRate.value,
            hrvSDNN: hrv.value,
            activeEnergy: activeEnergy.value,
            weightPounds: weight.value,
            metricDiagnostics: [
                sleep.diagnostic,
                steps.diagnostic,
                activeEnergy.diagnostic,
                workoutSummary.diagnostic,
                restingHeartRate.diagnostic,
                hrv.diagnostic,
                weight.diagnostic
            ]
        )
    }

    private enum QueryWindow {
        case today
        case lastHours(Int)
        case lastDays(Int)

        var text: String {
            switch self {
            case .today:
                return "Calendar today"
            case .lastHours(let hours):
                return "Last \(hours) hours"
            case .lastDays(let days):
                return "Last \(days) days"
            }
        }

        var predicate: NSPredicate {
            let now = Date()
            let start: Date
            switch self {
            case .today:
                start = Calendar.current.startOfDay(for: now)
            case .lastHours(let hours):
                start = Calendar.current.date(byAdding: .hour, value: -hours, to: now) ?? now
            case .lastDays(let days):
                start = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
            }
            return HKQuery.predicateForSamples(withStart: start, end: now, options: .strictEndDate)
        }
    }

    private struct QuantityResult {
        let value: Double?
        let diagnostic: HealthMetricDiagnostic
    }

    private struct WorkoutResult {
        let count: Int?
        let minutes: Double?
        let diagnostic: HealthMetricDiagnostic
    }

    private func quantitySumResult(
        id: String,
        title: String,
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        unitText: String,
        window: QueryWindow
    ) async -> QuantityResult {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return QuantityResult(value: nil, diagnostic: diagnostic(id: id, title: title, value: "Unavailable", status: "Unavailable", window: window.text, detail: "HealthKit type is unavailable on this device."))
        }

        do {
            let samples = try await quantitySamples(type: type, predicate: window.predicate)
            let sum = try await quantitySum(type: type, unit: unit, predicate: window.predicate)
            let latest = samples.first?.endDate

            if samples.isEmpty {
                return QuantityResult(value: nil, diagnostic: diagnostic(id: id, title: title, value: "No sample", status: "No sample in window", window: window.text, detail: "\(title) query succeeded, but Apple Health returned no samples in this window. Testing just after midnight can do this.", sampleDate: nil))
            }

            let value = sum ?? 0
            if value == 0 {
                return QuantityResult(value: 0, diagnostic: diagnostic(id: id, title: title, value: "0 \(unitText)", status: "Zero in window", window: window.text, detail: "\(title) is authorized/readable, and the returned total is zero for this window.", sampleDate: latest))
            }

            return QuantityResult(value: value, diagnostic: diagnostic(id: id, title: title, value: formatted(value, unitText: unitText), status: "Value returned", window: window.text, detail: "\(samples.count) sample\(samples.count == 1 ? "" : "s") contributed to this total.", sampleDate: latest))
        } catch {
            return QuantityResult(value: nil, diagnostic: diagnostic(id: id, title: title, value: "Query error", status: "Query error", window: window.text, detail: "The HealthKit query failed. This can mean unavailable data or denied access.", error: error))
        }
    }

    private func recentQuantityResult(
        id: String,
        title: String,
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        unitText: String
    ) async -> QuantityResult {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return QuantityResult(value: nil, diagnostic: diagnostic(id: id, title: title, value: "Unavailable", status: "Unavailable", window: "Most recent", detail: "HealthKit type is unavailable on this device."))
        }

        do {
            let sample = try await mostRecentQuantitySample(type: type)
            guard let sample else {
                return QuantityResult(value: nil, diagnostic: diagnostic(id: id, title: title, value: "No sample", status: "No sample in window", window: "Most recent", detail: "\(title) query succeeded, but Apple Health returned no samples."))
            }

            let value = sample.quantity.doubleValue(for: unit)
            return QuantityResult(value: value, diagnostic: diagnostic(id: id, title: title, value: formatted(value, unitText: unitText), status: "Value returned", window: "Most recent", detail: "Most recent \(title.lowercased()) sample returned.", sampleDate: sample.endDate))
        } catch {
            return QuantityResult(value: nil, diagnostic: diagnostic(id: id, title: title, value: "Query error", status: "Query error", window: "Most recent", detail: "The HealthKit query failed. This can mean unavailable data or denied access.", error: error))
        }
    }

    private func sleepResult() async -> QuantityResult {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return QuantityResult(value: nil, diagnostic: diagnostic(id: "sleep", title: "Sleep", value: "Unavailable", status: "Unavailable", window: QueryWindow.lastHours(36).text, detail: "Sleep analysis is unavailable on this device."))
        }

        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue
        ]
        let window = QueryWindow.lastHours(36)

        do {
            let samples = try await categorySamples(type: type, predicate: window.predicate)
            let asleepSamples = samples.filter { asleepValues.contains($0.value) }
            let seconds = asleepSamples.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            let latest = asleepSamples.first?.endDate ?? samples.first?.endDate

            guard seconds > 0 else {
                return QuantityResult(value: nil, diagnostic: diagnostic(id: "sleep", title: "Sleep", value: "No sample", status: "No sleep sample in window", window: window.text, detail: "Sleep checks the recent sleep window, not just calendar today. No asleep samples returned.", sampleDate: latest))
            }

            let hours = seconds / 3600
            return QuantityResult(value: hours, diagnostic: diagnostic(id: "sleep", title: "Sleep", value: String(format: "%.1f hr", hours), status: "Value returned", window: window.text, detail: "\(asleepSamples.count) asleep sample\(asleepSamples.count == 1 ? "" : "s") returned from the recent sleep window.", sampleDate: latest))
        } catch {
            return QuantityResult(value: nil, diagnostic: diagnostic(id: "sleep", title: "Sleep", value: "Query error", status: "Query error", window: window.text, detail: "The HealthKit sleep query failed. Check Sleep permission in Health/Settings.", error: error))
        }
    }

    private func workoutResult() async -> WorkoutResult {
        let window = QueryWindow.lastDays(7)
        do {
            let workouts = try await workouts(predicate: window.predicate)
            let minutes = workouts.reduce(0) { $0 + $1.duration / 60 }
            let latest = workouts.first?.endDate

            guard !workouts.isEmpty else {
                return WorkoutResult(count: nil, minutes: nil, diagnostic: diagnostic(id: "workouts", title: "Workouts", value: "No sample", status: "No workouts in window", window: window.text, detail: "Workout query succeeded, but Apple Health returned no workouts in the recent window.", sampleDate: nil))
            }

            return WorkoutResult(count: workouts.count, minutes: minutes, diagnostic: diagnostic(id: "workouts", title: "Workouts", value: "\(workouts.count)", status: "Value returned", window: window.text, detail: String(format: "%.0f workout minutes returned in the recent window.", minutes), sampleDate: latest))
        } catch {
            return WorkoutResult(count: nil, minutes: nil, diagnostic: diagnostic(id: "workouts", title: "Workouts", value: "Query error", status: "Query error", window: window.text, detail: "The HealthKit workout query failed. This can mean unavailable data or denied access.", error: error))
        }
    }

    private func quantitySamples(type: HKQuantityType, predicate: NSPredicate) async throws -> [HKQuantitySample] {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
                }
            }
            store.execute(query)
        }
    }

    private func quantitySum(type: HKQuantityType, unit: HKUnit, predicate: NSPredicate) async throws -> Double? {
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit))
                }
            }
            store.execute(query)
        }
    }

    private func mostRecentQuantitySample(type: HKQuantityType) async throws -> HKQuantitySample? {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples?.first as? HKQuantitySample)
                }
            }
            store.execute(query)
        }
    }

    private func categorySamples(type: HKCategoryType, predicate: NSPredicate) async throws -> [HKCategorySample] {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples as? [HKCategorySample] ?? [])
                }
            }
            store.execute(query)
        }
    }

    private func workouts(predicate: NSPredicate) async throws -> [HKWorkout] {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples as? [HKWorkout] ?? [])
                }
            }
            store.execute(query)
        }
    }

    private func diagnostic(
        id: String,
        title: String,
        value: String,
        status: String,
        window: String,
        detail: String,
        sampleDate: Date? = nil,
        error: Error? = nil
    ) -> HealthMetricDiagnostic {
        HealthMetricDiagnostic(
            id: id,
            title: title,
            valueText: value,
            statusText: status,
            queryWindow: window,
            detail: detail,
            sampleDate: sampleDate,
            errorText: error?.localizedDescription
        )
    }

    private func formatted(_ value: Double, unitText: String) -> String {
        switch unitText {
        case "lb":
            return String(format: "%.1f %@", value, unitText)
        case "ms", "bpm", "kcal", "steps":
            return String(format: "%.0f %@", value, unitText)
        default:
            return String(format: "%.1f %@", value, unitText)
        }
    }
}
