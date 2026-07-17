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

    func testCronometerAppleHealthNutritionSourceLabel() {
        let dateKey = "2026-07-16"
        let summary = HealthNutritionSummary(
            calories: 2200,
            proteinGrams: 165,
            waterOunces: 96,
            sourceNames: ["Cronometer"],
            sourceBundleIdentifiers: ["com.cronometer.Cronometer"],
            latestSampleDate: Date(),
            sampleCount: 12,
            appearsFromCronometer: true
        )
        let decision = NutritionSourceResolver.resolve(
            manual: ManualNutritionProvider(logs: []),
            appleHealth: AppleHealthNutritionProvider(summary: summary),
            dateKey: dateKey,
            targets: .brianDefault,
            detailBuilder: { $0.notes }
        )

        XCTAssertEqual(summary.sourceLabel, "Cronometer via Apple Health")
        XCTAssertEqual(decision.source, .cronometerAppleHealth)
        XCTAssertEqual(decision.log.notes, "Cronometer via Apple Health")
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

    func testImportedExerciseLibraryDecodesAndKeepsCuratedRecordsPreferred() {
        XCTAssertGreaterThanOrEqual(ExerciseLibrary.importedDefinitions.count, 1_000)
        XCTAssertGreaterThanOrEqual(ExerciseLibrary.definitions.count, 1_000)

        let bandRow = ExerciseLibrary.definition(for: "band-row")
        XCTAssertEqual(bandRow?.sourceName, "Health Command Center")
        XCTAssertEqual(bandRow?.id, "band-row")
    }

    func testExerciseLibraryBandAndMobilityFilters() {
        let bandMatches = ExerciseLibrary.search(query: "", category: nil, equipment: nil, muscle: nil, location: nil, bandsOnly: true)
        let mobilityMatches = ExerciseLibrary.search(query: "", category: nil, equipment: nil, muscle: nil, location: nil, mobilityOnly: true)

        XCTAssertGreaterThanOrEqual(bandMatches.filter { $0.sourceName.contains("curated") }.count, 100)
        XCTAssertGreaterThanOrEqual(mobilityMatches.filter { $0.sourceName.contains("curated") }.count, 100)
        XCTAssertTrue(bandMatches.allSatisfy { $0.equipment.contains(.resistanceBands) || $0.category == .bands })
        XCTAssertTrue(mobilityMatches.allSatisfy { $0.category == .mobility || $0.category == .recovery || $0.movementPattern == .mobility || $0.movementPattern == .recovery })
    }

    func testExerciseLibraryAliasAndNormalizationSearch() {
        let aliasMatches = ExerciseLibrary.search(query: "Alternate_Incline_Dumbbell_Curl", category: nil, equipment: nil, muscle: nil, location: nil)
        XCTAssertEqual(aliasMatches.first?.name, "Alternate Incline Dumbbell Curl")

        let dumbbellMatches = ExerciseLibrary.search(query: "bench press", category: nil, equipment: .dumbbells, muscle: .chest, location: nil)
        XCTAssertTrue(dumbbellMatches.contains { $0.name.localizedCaseInsensitiveContains("Dumbbell") })
    }

    func testExerciseLibraryResourceCountAndMalformedFallback() {
        XCTAssertEqual(ExerciseLibrary.importedDefinitions.count, 1_073)
        XCTAssertEqual(ExerciseLibrary.decodeImportedDefinitions(from: Data("not-json".utf8)), [])
    }

    func testExerciseLibrarySearchRankingPrioritizesNameBeforeInstructions() {
        let matches = ExerciseLibrary.search(query: "Goblet", category: nil, equipment: nil, muscle: nil, location: nil)
        XCTAssertEqual(matches.first?.name, "Goblet Squat")

        let instructionFallback = ExerciseLibrary.search(query: "borrowed phrase unlikely load before form", category: nil, equipment: nil, muscle: nil, location: nil)
        XCTAssertTrue(instructionFallback.isEmpty || instructionFallback.first?.name != "Goblet Squat")
    }

    func testExerciseLibraryFavoritesAndRecentsHelpers() {
        let recents = ExerciseLibrary.updatedRecentIDs(["band-row", "dead-bug"], adding: "band-row")
        XCTAssertEqual(recents, ["band-row", "dead-bug"])

        let addedFavorite = ExerciseLibrary.toggledFavoriteIDs([], id: "goblet-squat")
        XCTAssertEqual(addedFavorite, ["goblet-squat"])
        XCTAssertEqual(ExerciseLibrary.toggledFavoriteIDs(addedFavorite, id: "goblet-squat"), [])
    }

    func testCustomExerciseCanBeCreatedFromLibraryDefinition() throws {
        let definition = try XCTUnwrap(ExerciseLibrary.definition(for: "band-row"))
        let exercise = CustomExercise(from: definition, targetSets: 3, targetReps: "10-12")

        XCTAssertEqual(exercise.name, definition.name)
        XCTAssertEqual(exercise.libraryExerciseID, definition.id)
        XCTAssertEqual(exercise.targetSets, 3)
        XCTAssertEqual(exercise.targetReps, "10-12")
    }

    func testGeneratorAutomaticCandidatesStayCuratedAndCautionAware() {
        let candidates = ExerciseLibrary.automaticGenerationCandidates(
            location: .home,
            equipment: [.dumbbells, .resistanceBands, .mat],
            lane: .strength,
            shoulderCaution: true,
            lowBackCaution: true
        )

        XCTAssertFalse(candidates.isEmpty)
        XCTAssertTrue(candidates.allSatisfy(\.isHCCCurated))
        XCTAssertTrue(candidates.allSatisfy(\.isShoulderFriendly))
        XCTAssertTrue(candidates.allSatisfy(\.isLowBackFriendly))
    }

    func testRitualLogRecoveryExercisesDecodeBackwardCompatible() throws {
        let oldJSON = #"{"dateKey":"2026-07-16","completedItemIDs":["water"],"dailyWinText":"Did the floor."}"#.data(using: .utf8)!
        let oldLog = try JSONDecoder().decode(DailyRitualLog.self, from: oldJSON)
        XCTAssertEqual(oldLog.recoveryExerciseIDs, [])

        let newLog = DailyRitualLog(dateKey: "2026-07-16", recoveryExerciseIDs: ["shoulder-neck-reset"])
        let data = try JSONEncoder().encode(newLog)
        let decoded = try JSONDecoder().decode(DailyRitualLog.self, from: data)
        XCTAssertEqual(decoded.recoveryExerciseIDs, ["shoulder-neck-reset"])
    }

    func testHistoricalExerciseLogDecodingStillToleratesOldRecords() throws {
        let json = #"{"exerciseName":"Old Custom Row","reps":8,"setsCompleted":2,"effort":7}"#.data(using: .utf8)!
        let log = try JSONDecoder().decode(ExerciseLog.self, from: json)

        XCTAssertEqual(log.workoutTitle, "Workout Session")
        XCTAssertEqual(log.exerciseName, "Old Custom Row")
        XCTAssertEqual(log.setsCompleted, 2)
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
