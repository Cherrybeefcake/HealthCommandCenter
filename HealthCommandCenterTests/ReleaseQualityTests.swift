import XCTest
@testable import HealthCommandCenter

final class ReleaseQualityTests: XCTestCase {
    func testReadinessClassifierPushAndPainCaution() {
        let classifier = ReadinessClassifier()

        let strong = classifier.classify(
            energy: 9,
            soreness: 2,
            stress: 2,
            mood: 8,
            availableWorkoutMinutes: 70,
            painNote: "",
            health: HealthSnapshot(sleepHours: 8, restingHeartRate: 58, hrvSDNN: 65),
            oura: nil
        )
        XCTAssertEqual(strong.category, .pushDay)

        let cautious = classifier.classify(
            energy: 4,
            soreness: 8,
            stress: 8,
            mood: 4,
            availableWorkoutMinutes: 20,
            painNote: "Shoulder feels sharp overhead",
            health: HealthSnapshot(sleepHours: 4.5, restingHeartRate: 76, hrvSDNN: 24),
            oura: OuraDailySummary(readinessScore: 50, sleepScore: 50)
        )
        XCTAssertTrue([.recoveryDay, .bareMinimumDay].contains(cautious.category))
        XCTAssertLessThanOrEqual(cautious.score, 34)
    }

    func testDailyPlanDoesNotRecommendTrainingBeforeCheckIn() {
        let plan = DailyPlanGenerator.generate(
            category: .normalTrainingDay,
            checkIn: nil,
            programPhase: .nightShift,
            trainingLocation: .home,
            workoutTimePreference: .beginningOfShift,
            workoutLogsToday: [],
            ritualCompletedCount: 0,
            ritualTotalCount: 9,
            nutritionLog: DailyNutritionLog(dateKey: "2026-07-16"),
            nutritionTargets: .brianDefault,
            recoveryStatus: Self.recoveryStatus(category: .unknown, sleepHoursText: "No sleep data")
        )

        XCTAssertTrue(plan.title.contains("Check In"))
        XCTAssertTrue(plan.recommendedAction.contains("Start Check In"))
        XCTAssertTrue(plan.fullVersionText.contains("unlock after Check In"))
    }

    func testCoachEngineKeepsSubjectiveConcernConservative() {
        let context = Self.coachContext(
            readiness: .pushDay,
            energy: 3,
            stress: 9,
            soreness: 8,
            painNote: "Low back is cranky",
            sleepHours: 4.8,
            recovery: .poor
        )
        let recommendation = DeterministicCoachEngine().recommendation(.workout, for: context)

        XCTAssertEqual(recommendation?.isConservative, true)
        XCTAssertFalse(recommendation?.safetyConstraints.isEmpty ?? true)
        XCTAssertTrue(recommendation?.message.contains("Back off") ?? false)
    }

    func testNutritionSourcePriorityManualOverridesAppleHealth() {
        let dateKey = "2026-07-16"
        let manual = DailyNutritionLog(
            dateKey: dateKey,
            proteinGrams: 120,
            waterOunces: 80,
            cronometerCompleted: true
        )
        let decision = NutritionSourceResolver.resolve(
            manual: ManualNutritionProvider(logs: [manual]),
            appleHealth: AppleHealthNutritionProvider(
                summary: HealthNutritionSummary(proteinGrams: 160, waterOunces: 100)
            ),
            dateKey: dateKey,
            targets: .brianDefault,
            detailBuilder: { "\($0.proteinGrams ?? 0)g protein" }
        )

        XCTAssertEqual(decision.source, .manualHCC)
        XCTAssertEqual(decision.log.proteinGrams, 120)
    }

    func testDynamicWorkoutGeneratorDowngradesRecoveryAndPain() {
        let checkIn = CheckIn(
            energy: 3,
            soreness: 8,
            stress: 8,
            mood: 4,
            availableWorkoutMinutes: 20,
            painNote: "Shoulder pain today",
            healthSnapshot: HealthSnapshot(sleepHours: 4.5),
            ouraSummary: nil,
            readinessScore: 35,
            category: .recoveryDay
        )
        let recommendation = DynamicWorkoutGenerator.generate(
            readiness: .recoveryDay,
            checkIn: checkIn,
            recoveryStatus: Self.recoveryStatus(category: .poor, sleepHoursText: "4.5 hr"),
            programPhase: .nightShift,
            trainingLocation: .home,
            availableEquipment: [.dumbbells, .resistanceBands, .mat],
            recentLogs: [],
            dailyPlan: Self.dailyPlan(category: .recoveryDay, checkIn: checkIn)
        )

        XCTAssertEqual(recommendation.workout.category, WorkoutCategory.recoveryMobility)
        XCTAssertFalse(recommendation.cautionNotes.isEmpty)
    }

    func testAdaptiveProgramSchedulerMarksTodayWithoutFailureLanguage() {
        let week = AdaptiveProgramScheduler.currentWeek(
            readiness: .bareMinimumDay,
            recoveryStatus: Self.recoveryStatus(category: .poor, sleepHoursText: "4.0 hr"),
            programPhase: .newBaby,
            workoutTimePreference: .flexible,
            exerciseLogs: [],
            overrides: []
        )

        XCTAssertFalse(week.sessions.isEmpty)
        XCTAssertTrue(week.sessions.contains { $0.status == .downgraded || $0.status == .recommendedToday || $0.status == .optional })
    }

    func testRitualDailyWinCountsAsCompletion() {
        let log = DailyRitualLog(dateKey: "2026-07-16", dailyWinText: "Did the floor.")
        let summary = RitualDaySummary(
            log: log,
            date: Date(),
            category: .normalTrainingDay,
            items: RitualLibrary.items(for: .normalTrainingDay)
        )

        XCTAssertTrue(summary.completedItems.contains { $0.kind == .dailyWin })
        XCTAssertGreaterThan(summary.completedCount, 0)
    }

    func testBackwardCompatibleRitualDecoding() throws {
        let json = #"{"dateKey":"2026-07-16","completedItemIDs":["water"]}"#.data(using: .utf8)!
        let log = try JSONDecoder().decode(DailyRitualLog.self, from: json)

        XCTAssertEqual(log.dateKey, "2026-07-16")
        XCTAssertEqual(log.dailyWinText, "")
        XCTAssertEqual(log.completedItemIDs, ["water"])
    }

    func testBodyMetricsEncodeDecodeRoundTrip() throws {
        let entry = BodyMetricsEntry(
            dateKey: "2026-07-16",
            weightPounds: 174.2,
            bodyFatPercent: 22.5,
            waistInches: 34,
            notes: "Trend data",
            source: .smartScaleManual
        )
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(BodyMetricsEntry.self, from: data)

        XCTAssertEqual(decoded.dateKey, entry.dateKey)
        XCTAssertEqual(decoded.source, .smartScaleManual)
        XCTAssertEqual(decoded.weightPounds, 174.2)
    }

    func testSleepSourceLabelsRemainExplicit() {
        XCTAssertEqual(SleepSummary.none.sourceLabel, "No sleep data")
        let apple = SleepSummary(
            durationHours: 7.2,
            durationText: "7.2 hr",
            source: .appleHealth,
            label: "Apple Health latest sleep",
            detailText: "Latest sleep summary.",
            endDate: nil,
            includesNapContext: true,
            lookupWindowDescription: "Internal lookup only"
        )

        XCTAssertEqual(apple.sourceLabel, "Apple Health latest sleep")
    }
}

private extension ReleaseQualityTests {
    static func recoveryStatus(category: RecoveryCategory, sleepHoursText: String) -> RecoveryStatus {
        RecoveryStatus(
            sleepDurationText: sleepHoursText,
            sleepSourceText: "Apple Health primary",
            sleepDetailText: "Test sleep detail",
            supportingContextText: "Supporting context: no Oura snapshot active.",
            subjectiveOverrideText: nil,
            sleepQualityText: category.rawValue,
            recoveryCategory: category,
            trainingAdjustmentText: category == .poor ? "Keep training recovery-based." : "Training can stay normal.",
            caffeineGuidance: "Keep caffeine cutoff clear.",
            windDownGuidance: "Use the sleep prep routine.",
            napGuidance: "Nap if useful.",
            coachingLine: "Protect the floor."
        )
    }

    static func dailyPlan(category: ReadinessCategory, checkIn: CheckIn?) -> DailyPlan {
        DailyPlanGenerator.generate(
            category: category,
            checkIn: checkIn,
            programPhase: .normalRoutine,
            trainingLocation: .home,
            workoutTimePreference: .flexible,
            workoutLogsToday: [],
            ritualCompletedCount: 0,
            ritualTotalCount: 9,
            nutritionLog: DailyNutritionLog(dateKey: "2026-07-16"),
            nutritionTargets: .brianDefault,
            recoveryStatus: recoveryStatus(category: .okay, sleepHoursText: "7.0 hr")
        )
    }

    static func coachContext(
        readiness: ReadinessCategory?,
        energy: Int?,
        stress: Int?,
        soreness: Int?,
        painNote: String,
        sleepHours: Double?,
        recovery: RecoveryCategory
    ) -> CoachContext {
        let health = HealthSnapshot(sleepHours: sleepHours)
        let checkIn = readiness.map {
            CheckIn(
                energy: energy ?? 5,
                soreness: soreness ?? 5,
                stress: stress ?? 5,
                mood: 5,
                availableWorkoutMinutes: 30,
                painNote: painNote,
                healthSnapshot: health,
                ouraSummary: nil,
                readinessScore: 70,
                category: $0
            )
        }
        let recoveryStatus = recoveryStatus(
            category: recovery,
            sleepHoursText: sleepHours.map { String(format: "%.1f hr", $0) } ?? "No sleep data"
        )

        return CoachContext(
            readinessCategory: readiness,
            dailyPlan: dailyPlan(category: readiness ?? .normalTrainingDay, checkIn: checkIn),
            recoveryStatus: recoveryStatus,
            recoverySourceText: recoveryStatus.sleepSourceText,
            sleepHours: sleepHours,
            energy: energy,
            stress: stress,
            soreness: soreness,
            painNote: painNote,
            mood: 5,
            availableWorkoutMinutes: 30,
            programPhase: .normalRoutine,
            trainingLocation: .home,
            workoutTimePreference: .flexible,
            recentWorkouts: [],
            programWeek: AdaptiveProgramScheduler.currentWeek(
                readiness: readiness,
                recoveryStatus: recoveryStatus,
                programPhase: .normalRoutine,
                workoutTimePreference: .flexible,
                exerciseLogs: [],
                overrides: []
            ),
            goals: [],
            ritualCompleted: 0,
            ritualTotal: 9,
            nutritionLog: DailyNutritionLog(dateKey: "2026-07-16"),
            nutritionSource: NutritionDataSource.none.rawValue,
            nutritionDetail: "No nutrition source",
            bodyMetricTrendText: "No weight trend yet",
            ouraReadinessScore: nil,
            ouraSleepScore: nil,
            ouraTemperatureTrend: nil
        )
    }
}
