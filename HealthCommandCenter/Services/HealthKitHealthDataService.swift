import Foundation
import HealthKit

final class HealthKitHealthDataService: HealthDataProviding {
    private let store = HKHealthStore()

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

        let sleep: Double? = (try? await fetchSleepHours()) ?? nil
        let steps: Double? = (try? await fetchQuantitySum(.stepCount, unit: .count())) ?? nil
        let activeEnergy: Double? = (try? await fetchQuantitySum(.activeEnergyBurned, unit: .kilocalorie())) ?? nil
        let restingHeartRate: Double? = (try? await fetchMostRecentQuantity(.restingHeartRate, unit: HKUnit.count().unitDivided(by: HKUnit.minute()))) ?? nil
        let hrv: Double? = (try? await fetchMostRecentQuantity(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli))) ?? nil
        let weight: Double? = (try? await fetchMostRecentQuantity(.bodyMass, unit: .pound())) ?? nil
        let workoutSummary = (try? await fetchTodayWorkouts()) ?? (count: nil, minutes: nil)

        return HealthSnapshot(
            sleepHours: sleep,
            steps: steps.map { Int($0) },
            workoutCount: workoutSummary.count,
            workoutMinutes: workoutSummary.minutes,
            restingHeartRate: restingHeartRate,
            hrvSDNN: hrv,
            activeEnergy: activeEnergy,
            weightPounds: weight
        )
    }

    private func todayPredicate() -> NSPredicate {
        let start = Calendar.current.startOfDay(for: Date())
        return HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
    }

    private func fetchQuantitySum(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: todayPredicate(), options: .cumulativeSum) { _, stats, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit))
                }
            }
            store.execute(query)
        }
    }

    private func fetchMostRecentQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    let quantity = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                    continuation.resume(returning: quantity)
                }
            }
            store.execute(query)
        }
    }

    private func fetchSleepHours() async throws -> Double? {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue
        ]

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: todayPredicate(), limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let seconds = (samples as? [HKCategorySample] ?? [])
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

                continuation.resume(returning: seconds > 0 ? seconds / 3600 : nil)
            }
            store.execute(query)
        }
    }

    private func fetchTodayWorkouts() async throws -> (count: Int?, minutes: Double?) {
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: .workoutType(), predicate: todayPredicate(), limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let workouts = samples as? [HKWorkout] ?? []
                let minutes = workouts.reduce(0) { $0 + $1.duration / 60 }
                continuation.resume(returning: (workouts.isEmpty ? nil : workouts.count, workouts.isEmpty ? nil : minutes))
            }
            store.execute(query)
        }
    }
}
