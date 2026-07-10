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
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime),
            HKObjectType.quantityType(forIdentifier: .appleStandTime),
            HKObjectType.quantityType(forIdentifier: .flightsClimbed),
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
            HKObjectType.quantityType(forIdentifier: .restingHeartRate),
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
            HKObjectType.quantityType(forIdentifier: .heartRate),
            HKObjectType.quantityType(forIdentifier: .respiratoryRate),
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation),
            HKObjectType.quantityType(forIdentifier: .bodyTemperature),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            HKObjectType.quantityType(forIdentifier: .bodyMass),
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage),
            HKObjectType.quantityType(forIdentifier: .leanBodyMass),
            HKObjectType.quantityType(forIdentifier: .waistCircumference),
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed),
            HKObjectType.quantityType(forIdentifier: .dietaryProtein),
            HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates),
            HKObjectType.quantityType(forIdentifier: .dietaryFatTotal),
            HKObjectType.quantityType(forIdentifier: .dietaryFiber),
            HKObjectType.quantityType(forIdentifier: .dietarySugar),
            HKObjectType.quantityType(forIdentifier: .dietarySodium),
            HKObjectType.quantityType(forIdentifier: .dietaryWater),
            HKObjectType.quantityType(forIdentifier: .dietaryCaffeine)
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
        let exerciseMinutes = await quantitySumResult(id: "exercise-minutes", title: "Exercise Minutes", identifier: .appleExerciseTime, unit: .minute(), unitText: "min", window: .today)
        let standMinutes = await quantitySumResult(id: "stand-time", title: "Stand Time", identifier: .appleStandTime, unit: .minute(), unitText: "min", window: .today)
        let flights = await quantitySumResult(id: "flights", title: "Flights Climbed", identifier: .flightsClimbed, unit: .count(), unitText: "flights", window: .today)
        let distance = await quantitySumResult(id: "walking-running-distance", title: "Walking + Running Distance", identifier: .distanceWalkingRunning, unit: .mile(), unitText: "mi", window: .today)
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
        let heartRate = await recentQuantityResult(id: "heart-rate", title: "Heart Rate", identifier: .heartRate, unit: HKUnit.count().unitDivided(by: HKUnit.minute()), unitText: "bpm")
        let respiratoryRate = await recentQuantityResult(id: "respiratory-rate", title: "Respiratory Rate", identifier: .respiratoryRate, unit: HKUnit.count().unitDivided(by: HKUnit.minute()), unitText: "breaths/min")
        let bloodOxygen = await recentQuantityResult(id: "blood-oxygen", title: "Blood Oxygen", identifier: .oxygenSaturation, unit: .percent(), unitText: "%")
        let bodyTemperature = await recentQuantityResult(id: "body-temperature", title: "Body Temperature", identifier: .bodyTemperature, unit: .degreeFahrenheit(), unitText: "F")
        let weight = await recentQuantityResult(
            id: "weight",
            title: "Body Weight",
            identifier: .bodyMass,
            unit: .pound(),
            unitText: "lb"
        )
        let bodyFat = await recentQuantityResult(id: "body-fat", title: "Body Fat", identifier: .bodyFatPercentage, unit: .percent(), unitText: "%")
        let leanBodyMass = await recentQuantityResult(id: "lean-body-mass", title: "Lean Body Mass", identifier: .leanBodyMass, unit: .pound(), unitText: "lb")
        let waist = await recentQuantityResult(id: "waist", title: "Waist Circumference", identifier: .waistCircumference, unit: .inch(), unitText: "in")
        let workoutSummary = await workoutResult()
        let nutritionResults = await nutritionResults()
        let nutrition = HealthNutritionSummary(
            calories: nutritionResults.calories.value,
            proteinGrams: nutritionResults.protein.value,
            carbohydratesGrams: nutritionResults.carbs.value,
            fatGrams: nutritionResults.fat.value,
            fiberGrams: nutritionResults.fiber.value,
            sugarGrams: nutritionResults.sugar.value,
            sodiumMilligrams: nutritionResults.sodium.value,
            waterOunces: nutritionResults.water.value,
            caffeineMilligrams: nutritionResults.caffeine.value
        )

        return HealthSnapshot(
            sleepHours: sleep.value,
            sleepSummary: sleep.summary,
            steps: steps.value.map { Int($0.rounded()) },
            workoutCount: workoutSummary.count,
            workoutMinutes: workoutSummary.minutes,
            exerciseMinutes: exerciseMinutes.value,
            standMinutes: standMinutes.value,
            flightsClimbed: flights.value,
            walkingRunningDistanceMiles: distance.value,
            restingHeartRate: restingHeartRate.value,
            hrvSDNN: hrv.value,
            heartRate: heartRate.value,
            respiratoryRate: respiratoryRate.value,
            bloodOxygenPercent: bloodOxygen.value.map { $0 * 100 },
            bodyTemperatureFahrenheit: bodyTemperature.value,
            activeEnergy: activeEnergy.value,
            weightPounds: weight.value,
            bodyFatPercent: bodyFat.value.map { $0 * 100 },
            leanBodyMassPounds: leanBodyMass.value,
            waistInches: waist.value,
            nutrition: nutrition.availableMetricCount > 0 ? nutrition : nil,
            metricDiagnostics: [
                sleep.diagnostic,
                steps.diagnostic,
                activeEnergy.diagnostic,
                exerciseMinutes.diagnostic,
                standMinutes.diagnostic,
                flights.diagnostic,
                distance.diagnostic,
                workoutSummary.diagnostic,
                restingHeartRate.diagnostic,
                hrv.diagnostic,
                heartRate.diagnostic,
                respiratoryRate.diagnostic,
                bloodOxygen.diagnostic,
                bodyTemperature.diagnostic,
                weight.diagnostic,
                bodyFat.diagnostic,
                leanBodyMass.diagnostic,
                waist.diagnostic,
                nutritionResults.calories.diagnostic,
                nutritionResults.protein.diagnostic,
                nutritionResults.carbs.diagnostic,
                nutritionResults.fat.diagnostic,
                nutritionResults.fiber.diagnostic,
                nutritionResults.sugar.diagnostic,
                nutritionResults.sodium.diagnostic,
                nutritionResults.water.diagnostic,
                nutritionResults.caffeine.diagnostic
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
        let summary: SleepSummary?

        init(value: Double?, diagnostic: HealthMetricDiagnostic, summary: SleepSummary? = nil) {
            self.value = value
            self.diagnostic = diagnostic
            self.summary = summary
        }
    }

    private struct WorkoutResult {
        let count: Int?
        let minutes: Double?
        let diagnostic: HealthMetricDiagnostic
    }

    private struct NutritionResults {
        let calories: QuantityResult
        let protein: QuantityResult
        let carbs: QuantityResult
        let fat: QuantityResult
        let fiber: QuantityResult
        let sugar: QuantityResult
        let sodium: QuantityResult
        let water: QuantityResult
        let caffeine: QuantityResult
    }

    private func nutritionResults() async -> NutritionResults {
        NutritionResults(
            calories: await quantitySumResult(id: "nutrition-calories", title: "Dietary Calories", identifier: .dietaryEnergyConsumed, unit: .kilocalorie(), unitText: "kcal", window: .today),
            protein: await quantitySumResult(id: "nutrition-protein", title: "Protein", identifier: .dietaryProtein, unit: .gram(), unitText: "g", window: .today),
            carbs: await quantitySumResult(id: "nutrition-carbs", title: "Carbohydrates", identifier: .dietaryCarbohydrates, unit: .gram(), unitText: "g", window: .today),
            fat: await quantitySumResult(id: "nutrition-fat", title: "Fat", identifier: .dietaryFatTotal, unit: .gram(), unitText: "g", window: .today),
            fiber: await quantitySumResult(id: "nutrition-fiber", title: "Fiber", identifier: .dietaryFiber, unit: .gram(), unitText: "g", window: .today),
            sugar: await quantitySumResult(id: "nutrition-sugar", title: "Sugar", identifier: .dietarySugar, unit: .gram(), unitText: "g", window: .today),
            sodium: await quantitySumResult(id: "nutrition-sodium", title: "Sodium", identifier: .dietarySodium, unit: .gramUnit(with: .milli), unitText: "mg", window: .today),
            water: await quantitySumResult(id: "nutrition-water", title: "Water", identifier: .dietaryWater, unit: .fluidOunceUS(), unitText: "oz", window: .today),
            caffeine: await quantitySumResult(id: "nutrition-caffeine", title: "Caffeine", identifier: .dietaryCaffeine, unit: .gramUnit(with: .milli), unitText: "mg", window: .today)
        )
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
            return QuantityResult(
                value: nil,
                diagnostic: diagnostic(id: "sleep", title: "Sleep", value: "Unavailable", status: "Unavailable", window: QueryWindow.lastHours(48).text, detail: "Sleep analysis is unavailable on this device."),
                summary: SleepSummary.none
            )
        }

        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue
        ]
        let window = QueryWindow.lastHours(48)

        do {
            let samples = try await categorySamples(type: type, predicate: window.predicate)
            let asleepSamples = samples.filter { asleepValues.contains($0.value) }
            let grouped = Dictionary(grouping: asleepSamples, by: sleepDayKey(for:))
            let latestGroup = grouped
                .map { (key: $0.key, samples: $0.value) }
                .sorted { $0.key > $1.key }
                .first
            let latestSamples = latestGroup?.samples ?? []
            let seconds = latestSamples.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            let sortedLatestSamples = latestSamples.sorted { $0.endDate > $1.endDate }
            let latest = sortedLatestSamples.first?.endDate ?? asleepSamples.first?.endDate ?? samples.first?.endDate
            let includesNapContext = latestSamples.count > 1 && hasSeparatedSleepBlocks(latestSamples)

            guard seconds > 0 else {
                return QuantityResult(
                    value: nil,
                    diagnostic: diagnostic(id: "sleep", title: "Sleep", value: "No sample", status: "No sleep sample in lookup", window: window.text, detail: "The wider lookup is only used to find Apple Health sleep samples. No asleep samples returned.", sampleDate: latest),
                    summary: SleepSummary.none
                )
            }

            let hours = seconds / 3600
            let summary = SleepSummary(
                durationHours: hours,
                durationText: String(format: "%.1f hr", hours),
                source: .appleHealth,
                label: "Apple Health latest sleep",
                detailText: includesNapContext
                    ? "Built from the latest Apple Health sleep-day group, including separated sleep blocks or naps in that sleep day."
                    : "Built from the latest Apple Health sleep-day group.",
                endDate: latest,
                includesNapContext: includesNapContext,
                lookupWindowDescription: window.text
            )
            return QuantityResult(
                value: hours,
                diagnostic: diagnostic(
                    id: "sleep",
                    title: "Sleep",
                    value: summary.durationText,
                    status: "Apple Health latest sleep",
                    window: window.text,
                    detail: "Lookup window is only used to find Apple Health sleep samples. Readiness uses the latest sleep-day summary, not the raw lookup-window total.",
                    sampleDate: latest
                ),
                summary: summary
            )
        } catch {
            return QuantityResult(
                value: nil,
                diagnostic: diagnostic(id: "sleep", title: "Sleep", value: "Query error", status: "Query error", window: window.text, detail: "The HealthKit sleep query failed. Check Sleep permission in Health/Settings.", error: error),
                summary: SleepSummary.none
            )
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

    /// Approximation for Apple's displayed latest sleep day:
    /// fetch a recent window for overnight/naps, then group samples by a sleep day
    /// that rolls over in the evening instead of at midnight. This avoids treating
    /// the full lookup window as "sleep" while still catching naps tied to the
    /// latest overnight sleep block.
    private func sleepDayKey(for sample: HKCategorySample) -> Date {
        let calendar = Calendar.current
        let end = sample.endDate
        let hour = calendar.component(.hour, from: end)
        let anchor = hour < 18
            ? (calendar.date(byAdding: .day, value: -1, to: end) ?? end)
            : end
        return calendar.startOfDay(for: anchor)
    }

    private func hasSeparatedSleepBlocks(_ samples: [HKCategorySample]) -> Bool {
        let sorted = samples.sorted { $0.startDate < $1.startDate }
        guard sorted.count > 1 else { return false }

        for index in 1..<sorted.count {
            if sorted[index].startDate.timeIntervalSince(sorted[index - 1].endDate) > 90 * 60 {
                return true
            }
        }
        return false
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
        case "%":
            return String(format: "%.0f%%", value * 100)
        case "F":
            return String(format: "%.1f °F", value)
        case "ms", "bpm", "kcal", "steps", "min", "flights", "mg":
            return String(format: "%.0f %@", value, unitText)
        case "mi", "in":
            return String(format: "%.2f %@", value, unitText)
        default:
            return String(format: "%.1f %@", value, unitText)
        }
    }
}
