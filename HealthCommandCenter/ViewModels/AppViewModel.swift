import Foundation

@MainActor
final class AppViewModel: ObservableObject {
    enum HealthConnectionState: Equatable {
        case notRequested
        case loading
        case ready(metricCount: Int)
        case empty
        case unavailable(String)

        var title: String {
            switch self {
            case .notRequested:
                return "Apple Health is optional"
            case .loading:
                return "Reading Apple Health"
            case .ready:
                return "Apple Health connected"
            case .empty:
                return "Apple Health connected, no data yet"
            case .unavailable:
                return "Apple Health unavailable"
            }
        }

        var detail: String {
            switch self {
            case .notRequested:
                return "Connect Health for more context, or continue with your body report."
            case .loading:
                return "Pulling today's sleep, activity, and recovery signals."
            case .ready(let metricCount):
                return "\(metricCount) health signals available for today's classification."
            case .empty:
                return "No readable metrics came back. The check-in still works from your inputs."
            case .unavailable(let message):
                return message
            }
        }
    }

    enum Route {
        case greeting
        case checkIn
        case result
        case home
    }

    enum AppTab: Hashable {
        case today
        case plan
        case ritual
        case progress
        case profile
    }

    @Published var route: Route = .greeting
    @Published var selectedTab: AppTab = .today
    @Published var userName: String
    @Published var checkIns: [CheckIn] = []
    @Published var todaySnapshot: HealthSnapshot = .empty
    @Published var latestCheckIn: CheckIn?
    @Published var healthStatusMessage: String = "HealthKit not requested yet"
    @Published var healthState: HealthConnectionState = .notRequested
    @Published var isLoadingHealth = false
    @Published var lastHealthRefreshAt: Date?
    @Published var debugLog: [String] = []
    @Published var exerciseLogs: [ExerciseLog] = []
    @Published var ritualLogs: [DailyRitualLog] = []
    @Published var nutritionLogs: [DailyNutritionLog] = []
    @Published var ouraManualSnapshots: [OuraManualSnapshot] = []
    @Published var bodyMetricsEntries: [BodyMetricsEntry] = []
    @Published var todayRitualDateKey: String = RitualLibrary.dateKey()
    @Published var programPhase: ProgramPhase
    @Published var trainingLocation: TrainingLocation
    @Published var workoutTimePreference: WorkoutTimePreference
    @Published var reminderSettings: ReminderSettings
    @Published var ouraConnectionSettings: OuraConnectionSettings
    @Published var notificationPermissionStatus: String = "Not requested"
    @Published var scheduledReminderCount: Int = 0
    @Published var reminderTestStatus: String = "No test reminder sent yet"
    @Published var pendingHealthCommandNotificationCount: Int = 0
    @Published var isTestReminderPending = false
    @Published var lastTestReminderScheduledAt: Date?

    private let storage: LocalStorageService
    private let healthService: HealthDataProviding
    private let ouraService: OuraService
    private let classifier: ReadinessClassifier
    private let notificationService: LocalNotificationService
    private var didBootstrap = false
    private var didRequestHealth = false

    init(
        storage: LocalStorageService,
        healthService: HealthDataProviding,
        ouraService: OuraService,
        classifier: ReadinessClassifier,
        notificationService: LocalNotificationService = LocalNotificationService()
    ) {
        self.storage = storage
        self.healthService = healthService
        self.ouraService = ouraService
        self.classifier = classifier
        self.notificationService = notificationService
        self.userName = storage.userName
        self.programPhase = storage.programPhase
        self.trainingLocation = storage.trainingLocation
        self.workoutTimePreference = storage.workoutTimePreference
        self.reminderSettings = storage.reminderSettings
        self.ouraConnectionSettings = storage.ouraConnectionSettings
    }

    func bootstrap() async {
        guard !didBootstrap else { return }
        didBootstrap = true
        checkIns = storage.loadCheckIns().sorted { $0.date > $1.date }
        exerciseLogs = storage.loadExerciseLogs().sorted { $0.date > $1.date }
        ritualLogs = storage.loadRitualLogs().sorted { $0.dateKey > $1.dateKey }
        nutritionLogs = storage.loadNutritionLogs().sorted { $0.dateKey > $1.dateKey }
        ouraManualSnapshots = storage.loadOuraManualSnapshots().sorted { $0.updatedAt > $1.updatedAt }
        bodyMetricsEntries = storage.loadBodyMetricsEntries().sorted { $0.updatedAt > $1.updatedAt }
        prepareTodayStateIfNeeded()
        latestCheckIn = checkIns.first
        await refreshNotificationStatus()
        route = storage.hasSeenGreeting ? .home : .greeting
    }

    var hasCheckedInToday: Bool {
        guard let latestCheckIn else { return false }
        return Calendar.current.isDateInToday(latestCheckIn.date)
    }

    var activeCategory: ReadinessCategory {
        latestCheckIn?.category ?? .normalTrainingDay
    }

    var todayDailyPlan: DailyPlan {
        let ritualItems = todayRitualItems()
        return DailyPlanGenerator.generate(
            category: activeCategory,
            checkIn: hasCheckedInToday ? latestCheckIn : nil,
            programPhase: programPhase,
            trainingLocation: trainingLocation,
            workoutTimePreference: workoutTimePreference,
            workoutLogsToday: todayExerciseLogs(),
            ritualCompletedCount: todayRitualCompletedCount(),
            ritualTotalCount: ritualItems.count,
            nutritionLog: todayNutritionLog(),
            nutritionTargets: NutritionTargets.brianDefault,
            recoveryStatus: todayRecoveryStatus()
        )
    }

    var healthAvailabilityText: String {
        healthService.isHealthDataAvailable ? "Available on this device" : "Unavailable on this device"
    }

    var healthAuthorizationSummary: String {
        switch healthState {
        case .notRequested:
            return "Not requested"
        case .loading:
            return "Authorization/fetch in progress"
        case .ready:
            let count = todaySnapshot.availableMetricCount
            return count >= 7 ? "Requested; all tracked data returned" : "Some data returned (\(count)/7)"
        case .empty:
            return "Requested; no readable data returned yet"
        case .unavailable:
            return "Unavailable, denied, or no readable access"
        }
    }

    var lastHealthRefreshText: String {
        guard let lastHealthRefreshAt else { return "No successful refresh yet" }
        return lastHealthRefreshAt.formatted(date: .abbreviated, time: .shortened)
    }

    func completeGreeting() {
        storage.userName = userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Brian" : userName
        storage.hasSeenGreeting = true
        route = .home
    }

    func refreshHealthData() async {
        didRequestHealth = true
        isLoadingHealth = true
        healthState = .loading
        defer { isLoadingHealth = false }

        do {
            try await healthService.requestAuthorization()
            todaySnapshot = try await healthService.fetchTodaySnapshot()
            lastHealthRefreshAt = Date()
            if todaySnapshot.hasAnyData {
                healthState = .ready(metricCount: todaySnapshot.availableMetricCount)
            } else {
                healthState = .empty
            }
        } catch {
            todaySnapshot = .empty
            healthState = .unavailable(error.localizedDescription)
        }

        healthStatusMessage = healthState.title
        appendDebug("Health refresh: \(healthState.title) - \(healthState.detail)")
    }

    func submitCheckIn(from form: CheckInViewModel) async {
        let ouraSummary: OuraDailySummary?
        if let localOura = selectedOuraSnapshotForRecovery()?.dailySummary {
            ouraSummary = localOura
        } else {
            do {
                ouraSummary = try await ouraService.fetchDailySummary()
            } catch {
                ouraSummary = nil
            }
        }
        let result = classifier.classify(
            energy: form.energy,
            soreness: form.soreness,
            stress: form.stress,
            mood: form.mood,
            availableWorkoutMinutes: form.availableWorkoutMinutes,
            painNote: form.painNote,
            health: todaySnapshot,
            oura: ouraSummary
        )

        let checkIn = CheckIn(
            energy: form.energy,
            soreness: form.soreness,
            stress: form.stress,
            mood: form.mood,
            availableWorkoutMinutes: form.availableWorkoutMinutes,
            painNote: form.painNote,
            healthSnapshot: todaySnapshot,
            ouraSummary: ouraSummary,
            readinessScore: result.score,
            readinessReasons: result.reasons,
            category: result.category
        )

        checkIns.removeAll { Calendar.current.isDateInToday($0.date) }
        checkIns.insert(checkIn, at: 0)
        storage.save(checkIns)
        latestCheckIn = checkIn
        appendDebug("""
        Check-in: energy \(form.energy), soreness \(form.soreness), stress \(form.stress), mood \(form.mood), time \(form.availableWorkoutMinutes), category \(result.category.rawValue)
        """)
        route = .result
    }

    func goHome() {
        selectedTab = .today
        route = .home
    }

    func startNewCheckIn() {
        route = .checkIn
    }

    func saveExerciseLog(_ log: ExerciseLog) {
        exerciseLogs.insert(log, at: 0)
        exerciseLogs.sort { $0.date > $1.date }
        storage.saveExerciseLogs(exerciseLogs)
        appendDebug("Exercise log: \(log.exerciseName) - \(log.summary)")
    }

    func lastExerciseLog(for exerciseID: String, exerciseName: String) -> ExerciseLog? {
        exerciseLogs.first {
            ($0.exerciseID == exerciseID || $0.exerciseName == exerciseName) &&
            !Calendar.current.isDateInToday($0.date)
        }
    }

    func todayExerciseLogs(for exerciseID: String, exerciseName: String) -> [ExerciseLog] {
        exerciseLogs
            .filter {
                ($0.exerciseID == exerciseID || $0.exerciseName == exerciseName) &&
                Calendar.current.isDateInToday($0.date)
            }
            .sorted { $0.date < $1.date }
    }

    func todayWorkoutLogs(for workoutID: String) -> [ExerciseLog] {
        exerciseLogs
            .filter { $0.workoutID == workoutID && Calendar.current.isDateInToday($0.date) }
            .sorted { $0.date < $1.date }
    }

    func todayExerciseLogs() -> [ExerciseLog] {
        exerciseLogs
            .filter { Calendar.current.isDateInToday($0.date) }
            .sorted { $0.date < $1.date }
    }

    func todayNutritionLog() -> DailyNutritionLog {
        let dateKey = RitualLibrary.dateKey()
        return nutritionLogs.first { $0.dateKey == dateKey } ?? DailyNutritionLog(dateKey: dateKey)
    }

    func saveNutritionLog(_ log: DailyNutritionLog) {
        var updatedLog = log
        updatedLog.updatedAt = Date()
        nutritionLogs.removeAll { $0.dateKey == updatedLog.dateKey }
        nutritionLogs.insert(updatedLog, at: 0)
        nutritionLogs.sort { $0.dateKey > $1.dateKey }
        storage.saveNutritionLogs(nutritionLogs)
        appendDebug("Nutrition log saved: \(updatedLog.dateKey)")
    }

    func nutritionLogsThisWeek() -> [DailyNutritionLog] {
        nutritionLogs.filter { dateFromRitualKey($0.dateKey).map(isInCurrentWeek) ?? false }
    }

    func recentNutritionLogs(limit: Int = 8) -> [DailyNutritionLog] {
        Array(nutritionLogs.sorted { $0.dateKey > $1.dateKey }.prefix(limit))
    }

    func cronometerCompletionsThisWeek() -> Int {
        nutritionLogsThisWeek().filter(\.cronometerCompleted).count
    }

    func averageProteinThisWeek() -> Int? {
        averageInt(nutritionLogsThisWeek().compactMap(\.proteinGrams))
    }

    func averageWaterThisWeek() -> Int? {
        averageInt(nutritionLogsThisWeek().compactMap(\.waterOunces))
    }

    func saveBodyMetricsEntry(_ entry: BodyMetricsEntry) {
        var updatedEntry = entry
        updatedEntry.updatedAt = Date()
        bodyMetricsEntries.removeAll { $0.dateKey == updatedEntry.dateKey && $0.source == updatedEntry.source }
        bodyMetricsEntries.insert(updatedEntry, at: 0)
        bodyMetricsEntries.sort { $0.updatedAt > $1.updatedAt }
        storage.saveBodyMetricsEntries(bodyMetricsEntries)
        appendDebug("Body metrics saved: \(updatedEntry.dateKey)")
    }

    func recentBodyMetricsEntries(limit: Int = 8) -> [BodyMetricsEntry] {
        Array(bodyMetricsEntries.sorted { $0.updatedAt > $1.updatedAt }.prefix(limit))
    }

    func latestBodyMetricsSummary() -> BodyMetricsSummary {
        let latestManual = bodyMetricsEntries.sorted { $0.updatedAt > $1.updatedAt }.first
        let recent = recentBodyMetricsEntries(limit: 8).sorted { $0.dateKey < $1.dateKey }
        return BodyMetricsSummary(
            latestEntry: latestManual,
            appleHealthWeightPounds: todaySnapshot.weightPounds,
            trendText: bodyMetricTrendText(
                title: "Weight",
                unit: "lb",
                values: recent.compactMap { entry in
                    entry.weightPounds.map { (entry.dateKey, $0) }
                }
            ),
            bodyFatTrendText: optionalBodyMetricTrendText(
                title: "Body fat",
                unit: "%",
                values: recent.compactMap { entry in
                    entry.bodyFatPercent.map { (entry.dateKey, $0) }
                }
            ),
            waistTrendText: optionalBodyMetricTrendText(
                title: "Waist",
                unit: "in",
                values: recent.compactMap { entry in
                    entry.waistInches.map { (entry.dateKey, $0) }
                }
            )
        )
    }

    func nutritionStatusLine(for log: DailyNutritionLog? = nil) -> String {
        let log = log ?? todayNutritionLog()
        if !log.cronometerCompleted {
            return "Log Cronometer"
        }
        if log.proteinGrams == nil || !(log.proteinTargetHit || (log.proteinGrams ?? 0) >= NutritionTargets.brianDefault.proteinGrams) {
            return "Protein next"
        }
        if log.waterOunces == nil || !(log.waterTargetHit || (log.waterOunces ?? 0) >= NutritionTargets.brianDefault.waterOunces) {
            return "Hydrate"
        }
        return "Anchors logged"
    }

    func nutritionDetailLine(for log: DailyNutritionLog? = nil) -> String {
        let log = log ?? todayNutritionLog()
        let cronometer = log.cronometerCompleted ? "Cronometer done" : "Cronometer not logged"
        let protein = log.proteinGrams.map { "\($0)g protein" } ?? "protein missing"
        let water = log.waterOunces.map { "\($0) oz water" } ?? "water missing"
        return "\(cronometer) | \(protein) | \(water)"
    }

    func todayRecoveryStatus() -> RecoveryStatus {
        let checkIn = hasCheckedInToday ? latestCheckIn : nil
        let sleepSummary = currentSleepSummary(checkIn: checkIn)
        let ouraSnapshot = selectedOuraSnapshotForRecovery()
        let sourceDecision = recoverySourceDecision(
            checkIn: checkIn,
            sleepSummary: sleepSummary,
            ouraSnapshot: ouraSnapshot
        )
        let sleepHours = sleepSummary.durationHours
        let baseCategory = recoveryCategory(
            sleepHours: sleepHours,
            checkIn: checkIn,
            readiness: hasCheckedInToday ? activeCategory : nil
        )
        let category = adjustedRecoveryCategory(baseCategory, ouraSnapshot: ouraSnapshot)

        return RecoveryStatus(
            sleepDurationText: sleepSummary.durationText,
            sleepSourceText: sourceDecision.primaryReason,
            sleepDetailText: sleepSummary.detailText,
            supportingContextText: sourceDecision.supportingContext,
            subjectiveOverrideText: sourceDecision.subjectiveOverrideText,
            sleepQualityText: sleepQualityText(for: category, sleepHours: sleepHours),
            recoveryCategory: category,
            trainingAdjustmentText: trainingAdjustmentText(for: category, readiness: hasCheckedInToday ? activeCategory : nil),
            caffeineGuidance: caffeineGuidance(for: programPhase),
            windDownGuidance: windDownGuidance(for: programPhase),
            napGuidance: napGuidance(for: programPhase, category: category),
            coachingLine: recoveryCoachingLine(for: category, phase: programPhase)
        )
    }

    func averageSleepThisWeek() -> Double? {
        let values = checkInsThisWeek().compactMap(\.healthSnapshot.sleepHours)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    func lowSleepDaysThisWeek() -> Int {
        checkInsThisWeek().compactMap(\.healthSnapshot.sleepHours).filter { $0 < 5 }.count
    }

    func recentRecoveryCheckIns(limit: Int = 6) -> [CheckIn] {
        Array(checkIns.filter { $0.healthSnapshot.sleepHours != nil || !$0.readinessReasons.isEmpty }.prefix(limit))
    }

    func progressionSuggestion(for exercise: ExercisePlan, workout: WorkoutPlan) -> ExerciseProgressionSuggestion {
        let lastLog = lastExerciseLog(for: exercise.id, exerciseName: exercise.name)
        let todayLogs = todayExerciseLogs(for: exercise.id, exerciseName: exercise.name)
        let todaySetCount = todayLogs.reduce(0) { $0 + $1.setsCompleted }
        let plannedSets = plannedSetCount(from: exercise.prescription)
        let plannedReps = plannedRepRange(from: exercise.prescription)
        let shoulderCaution = shoulderCautionNote(for: exercise)
        let dailyPlan = todayDailyPlan

        if !hasCheckedInToday {
            return ExerciseProgressionSuggestion(
                suggestedWeightText: startingWeightText(for: exercise),
                suggestedRepsText: plannedReps.map { "Aim for \($0.lower)-\($0.upper) reps" } ?? "Aim for the written target",
                suggestedSetsText: todaySetCount > 0 ? "\(todaySetCount) sets logged" : "Start with 1 honest set",
                reason: "Start Check In before deciding whether to push. \(dailyPlan.workoutRecommendation)",
                cautionNote: shoulderCaution
            )
        }

        switch activeCategory {
        case .recoveryDay:
            return ExerciseProgressionSuggestion(
                suggestedWeightText: "No strength push",
                suggestedRepsText: "Use mobility range only",
                suggestedSetsText: "0 hard sets",
                reason: "Keep it easy today. \(dailyPlan.workoutRecommendation)",
                cautionNote: shoulderCaution ?? "Recovery days are for walking, mobility, and breathing."
            )
        case .bareMinimumDay:
            return ExerciseProgressionSuggestion(
                suggestedWeightText: "Bodyweight, band, or very light",
                suggestedRepsText: "Aim for easy reps only",
                suggestedSetsText: "1 tiny set if useful",
                reason: "Protect the floor. Count the smallest useful movement dose.",
                cautionNote: shoulderCaution
            )
        case .lightTrainingDay:
            let sets = max(1, min(plannedSets - 1, plannedSets))
            let reps = plannedReps.map { "Aim for \($0.lower)-\($0.upper) easy reps" } ?? "Aim for easy technique reps"
            return ExerciseProgressionSuggestion(
                suggestedWeightText: lastLog.flatMap(weightText(for:)) ?? startingWeightText(for: exercise),
                suggestedRepsText: reps,
                suggestedSetsText: todaySetCount > 0 ? "\(todaySetCount)/\(sets) sets logged" : "\(sets) set\(sets == 1 ? "" : "s")",
                reason: "Light Training Day: reduce volume and leave fresher than you started.",
                cautionNote: shoulderCaution
            )
        case .pushDay, .normalTrainingDay:
            break
        }

        guard let lastLog else {
            return ExerciseProgressionSuggestion(
                suggestedWeightText: startingWeightText(for: exercise),
                suggestedRepsText: plannedReps.map { "Aim for \($0.lower)-\($0.upper) reps" } ?? "Aim for the written target",
                suggestedSetsText: todaySetCount > 0 ? "\(todaySetCount)/\(plannedSets) sets logged" : "\(plannedSets) set\(plannedSets == 1 ? "" : "s")",
                reason: "No previous log for this exercise. Start conservative and make the first data point clean.",
                cautionNote: shoulderCaution
            )
        }

        let baseWeight = weightText(for: lastLog) ?? startingWeightText(for: exercise)
        let setText = todaySetCount > 0 ? "\(todaySetCount)/\(plannedSets) sets logged" : "\(plannedSets) set\(plannedSets == 1 ? "" : "s")"

        if lastLog.effort <= 7 {
            let nearTop = plannedReps.map { lastLog.reps >= max($0.upper - 1, $0.lower) } ?? false
            if nearTop, let weight = lastLog.weight {
                return ExerciseProgressionSuggestion(
                    suggestedWeightText: "Aim for \(formatWeight(weight + weightStep(for: weight)))",
                    suggestedRepsText: plannedReps.map { "Repeat \($0.lower)-\($0.upper) reps" } ?? "Repeat clean reps",
                    suggestedSetsText: setText,
                    reason: "Last time was RPE \(lastLog.effort), and reps were near the top of the range.",
                    cautionNote: shoulderCaution
                )
            }

            let nextReps = plannedReps.map { min(lastLog.reps + 1, $0.upper) } ?? lastLog.reps + 1
            return ExerciseProgressionSuggestion(
                suggestedWeightText: "Repeat \(baseWeight)",
                suggestedRepsText: "Aim for \(nextReps)-\(min(nextReps + 1, plannedReps?.upper ?? nextReps + 1)) reps",
                suggestedSetsText: setText,
                reason: "Last time was RPE \(lastLog.effort). Add a rep or two before chasing load.",
                cautionNote: shoulderCaution
            )
        }

        if lastLog.effort == 8 {
            return ExerciseProgressionSuggestion(
                suggestedWeightText: "Repeat \(baseWeight)",
                suggestedRepsText: "Repeat \(lastLog.reps) reps",
                suggestedSetsText: setText,
                reason: "Last time was RPE 8. Repeat the same work and make it cleaner.",
                cautionNote: shoulderCaution
            )
        }

        return ExerciseProgressionSuggestion(
            suggestedWeightText: reducedWeightText(from: lastLog) ?? "Back off slightly",
            suggestedRepsText: "Repeat \(max(lastLog.reps - 1, 1))-\(lastLog.reps) easy reps",
            suggestedSetsText: "\(max(plannedSets - 1, 1)) set\(max(plannedSets - 1, 1) == 1 ? "" : "s")",
            reason: "Last time was RPE \(lastLog.effort). Back off slightly so consistency stays protected.",
            cautionNote: shoulderCaution
        )
    }

    func exerciseProgressSummary(for exercise: ExercisePlan) -> ExerciseProgressSummary {
        let logs = logs(for: exercise.id, exerciseName: exercise.name)
        return exerciseProgressSummary(
            id: exercise.id,
            exerciseName: exercise.name,
            logs: logs
        )
    }

    func recentExerciseProgressSummaries(limit: Int = 6) -> [ExerciseProgressSummary] {
        let grouped = Dictionary(grouping: exerciseLogs) { log in
            log.exerciseID.isEmpty ? log.exerciseName : log.exerciseID
        }

        return grouped.values
            .map { logs in
                let sorted = logs.sorted { $0.date > $1.date }
                let first = sorted.first
                return exerciseProgressSummary(
                    id: first?.exerciseID ?? first?.exerciseName ?? UUID().uuidString,
                    exerciseName: first?.exerciseName ?? "Exercise",
                    logs: sorted
                )
            }
            .sorted {
                let left = $0.mostRecentDate ?? .distantPast
                let right = $1.mostRecentDate ?? .distantPast
                if left == right { return $0.timesLogged > $1.timesLogged }
                return left > right
            }
            .prefix(limit)
            .map { $0 }
    }

    func deleteExerciseLog(_ log: ExerciseLog) {
        exerciseLogs.removeAll { $0.id == log.id }
        storage.saveExerciseLogs(exerciseLogs)
        appendDebug("Deleted exercise log: \(log.exerciseName)")
    }

    func prepareTodayStateIfNeeded(date: Date = Date()) {
        let dateKey = RitualLibrary.dateKey(for: date)
        if todayRitualDateKey != dateKey {
            todayRitualDateKey = dateKey
        }
        if !ritualLogs.contains(where: { $0.dateKey == dateKey }) {
            ritualLogs.insert(DailyRitualLog(dateKey: dateKey, completedItemIDs: [], updatedAt: date), at: 0)
            ritualLogs.sort { $0.dateKey > $1.dateKey }
            storage.saveRitualLogs(ritualLogs)
        }
    }

    func isRitualItemComplete(_ itemID: String) -> Bool {
        ritualLogs.first { $0.dateKey == RitualLibrary.dateKey() }?.completedItemIDs.contains(itemID) ?? false
    }

    func setRitualItem(_ itemID: String, completed: Bool) {
        prepareTodayStateIfNeeded()
        let dateKey = RitualLibrary.dateKey()
        guard let index = ritualLogs.firstIndex(where: { $0.dateKey == dateKey }) else { return }
        if completed {
            ritualLogs[index].completedItemIDs.insert(itemID)
        } else {
            ritualLogs[index].completedItemIDs.remove(itemID)
        }
        ritualLogs[index].updatedAt = Date()
        storage.saveRitualLogs(ritualLogs)
        appendDebug("Ritual \(completed ? "complete" : "incomplete"): \(itemID)")
    }

    func todayRitualItems() -> [RitualItem] {
        // Render-time helpers must stay side-effect free; prepare missing daily state from lifecycle hooks or actions.
        return RitualLibrary.items(for: activeCategory)
    }

    func todayRitualCompletedCount() -> Int {
        let completedIDs = ritualLogs.first { $0.dateKey == RitualLibrary.dateKey() }?.completedItemIDs ?? []
        return todayRitualItems().filter { completedIDs.contains($0.id) }.count
    }

    func goToPlan() {
        selectedTab = .plan
        route = .home
    }

    func goToRitual() {
        selectedTab = .ritual
        route = .home
    }

    func setProgramPhase(_ phase: ProgramPhase) {
        programPhase = phase
        storage.programPhase = phase
        appendDebug("Program phase set: \(phase.rawValue)")
    }

    func setTrainingLocation(_ location: TrainingLocation) {
        trainingLocation = location
        storage.trainingLocation = location
        appendDebug("Training location set: \(location.rawValue)")
    }

    func setWorkoutTimePreference(_ preference: WorkoutTimePreference) {
        workoutTimePreference = preference
        storage.workoutTimePreference = preference
        appendDebug("Workout time set: \(preference.rawValue)")
    }

    func saveOuraConnectionSettings(_ settings: OuraConnectionSettings) {
        ouraConnectionSettings = settings
        storage.ouraConnectionSettings = settings
        appendDebug("Oura settings saved: \(settings.connectionMode.rawValue), source \(settings.preferredRecoverySource.rawValue)")
    }

    func saveOuraManualSnapshot(_ snapshot: OuraManualSnapshot) {
        var updated = snapshot
        updated.updatedAt = Date()
        ouraManualSnapshots.removeAll { $0.dateKey == updated.dateKey }
        ouraManualSnapshots.insert(updated, at: 0)
        ouraManualSnapshots.sort { $0.updatedAt > $1.updatedAt }
        storage.saveOuraManualSnapshots(ouraManualSnapshots)

        var settings = ouraConnectionSettings
        if settings.connectionMode == .notConnected || settings.connectionMode == .futureOAuth {
            settings.connectionMode = .manual
        }
        settings.isEnabled = settings.connectionMode == .manual || settings.connectionMode == .mock
        settings.lastMockUpdate = updated.updatedAt
        ouraConnectionSettings = settings
        storage.ouraConnectionSettings = settings
        appendDebug("Oura manual/mock snapshot saved: \(updated.dateKey)")
    }

    func saveReminderSettings(_ settings: ReminderSettings) async {
        reminderSettings = settings
        storage.reminderSettings = settings

        let status: NotificationDebugStatus
        if settings.remindersEnabled {
            status = await notificationService.scheduleDailyReminders(settings: settings)
            if status.permissionStatusText == "Denied" {
                appendDebug("Notifications denied. Reminder settings saved, but no reminders scheduled.")
            } else {
                appendDebug("Reminders scheduled: \(status.scheduledReminderCount)")
            }
        } else {
            notificationService.cancelAllHealthCommandReminders()
            status = await notificationService.debugStatus()
            appendDebug("Reminders disabled")
        }

        applyNotificationStatus(status)
    }

    func refreshNotificationStatus() async {
        let status = await notificationService.debugStatus()
        applyNotificationStatus(status)
    }

    func scheduleTestReminder() async {
        let result = await notificationService.scheduleTestReminder()
        applyNotificationStatus(result.status)
        reminderTestStatus = result.message
        if result.didSchedule {
            lastTestReminderScheduledAt = Date()
        }
        appendDebug(result.didSchedule ? "Test reminder scheduled" : "Test reminder not scheduled: \(result.message)")
    }

    func resetTodaysRitual() {
        prepareTodayStateIfNeeded()
        let dateKey = RitualLibrary.dateKey()
        storage.resetTodaysRitual(dateKey: dateKey)
        ritualLogs = storage.loadRitualLogs().sorted { $0.dateKey > $1.dateKey }
        appendDebug("Reset today's ritual")
    }

    func deleteWorkoutLogs() {
        storage.deleteWorkoutLogs()
        exerciseLogs = []
        appendDebug("Deleted workout logs")
    }

    func resetGreetingState() {
        storage.resetGreetingState()
        selectedTab = .today
        route = .greeting
        appendDebug("Reset greeting state only")
    }

    func deleteAllLocalAppData() {
        storage.deleteAllLocalData()
        notificationService.cancelAllHealthCommandReminders()
        userName = storage.userName
        programPhase = storage.programPhase
        trainingLocation = storage.trainingLocation
        workoutTimePreference = storage.workoutTimePreference
        reminderSettings = storage.reminderSettings
        ouraConnectionSettings = storage.ouraConnectionSettings
        notificationPermissionStatus = "Not requested"
        scheduledReminderCount = 0
        pendingHealthCommandNotificationCount = 0
        isTestReminderPending = false
        lastTestReminderScheduledAt = nil
        checkIns = []
        latestCheckIn = nil
        exerciseLogs = []
        ritualLogs = []
        nutritionLogs = []
        ouraManualSnapshots = []
        bodyMetricsEntries = []
        debugLog = []
        todaySnapshot = .empty
        lastHealthRefreshAt = nil
        healthState = .notRequested
        healthStatusMessage = "HealthKit not requested yet"
        todayRitualDateKey = RitualLibrary.dateKey()
        didBootstrap = false
        didRequestHealth = false
        route = .greeting
        selectedTab = .today
    }

    func checkInsThisWeek() -> [CheckIn] {
        checkIns.filter { isInCurrentWeek($0.date) }
    }

    func exerciseLogsThisWeek() -> [ExerciseLog] {
        exerciseLogs.filter { isInCurrentWeek($0.date) }
    }

    func recentWorkoutSessions(limit: Int = 8) -> [WorkoutSession] {
        workoutSessions(from: exerciseLogs, limit: limit)
    }

    func workoutSessionsThisWeek() -> [WorkoutSession] {
        workoutSessions(from: exerciseLogsThisWeek())
    }

    func ritualLogsThisWeek() -> [DailyRitualLog] {
        ritualLogs.filter { dateFromRitualKey($0.dateKey).map(isInCurrentWeek) ?? false }
    }

    func recentRitualDays(limit: Int = 10, includeEmptyToday: Bool = true) -> [RitualDaySummary] {
        let summaries = ritualLogs
            .compactMap(ritualDaySummary(for:))
            .filter { includeEmptyToday || !$0.log.completedItemIDs.isEmpty }
            .sorted { $0.date > $1.date }
        return Array(summaries.prefix(limit))
    }

    func currentCheckInStreak() -> Int {
        currentStreak(from: Set(checkIns.map { RitualLibrary.dateKey(for: $0.date) }))
    }

    func currentRitualStreak() -> Int {
        currentStreak(from: Set(ritualLogs.filter { !$0.completedItemIDs.isEmpty }.map(\.dateKey)))
    }

    func currentWorkoutStreak() -> Int {
        currentStreak(from: Set(exerciseLogs.map { RitualLibrary.dateKey(for: $0.date) }))
    }

    func currentOverallConsistencyStreak() -> Int {
        var keys = Set(checkIns.map { RitualLibrary.dateKey(for: $0.date) })
        keys.formUnion(exerciseLogs.map { RitualLibrary.dateKey(for: $0.date) })
        keys.formUnion(ritualLogs.filter { !$0.completedItemIDs.isEmpty }.map(\.dateKey))
        return currentStreak(from: keys)
    }

    func readinessCategory(for dateKey: String) -> ReadinessCategory? {
        checkIns.first { RitualLibrary.dateKey(for: $0.date) == dateKey }?.category
    }

    func ritualDaySummary(for log: DailyRitualLog) -> RitualDaySummary? {
        guard let date = dateFromRitualKey(log.dateKey) else { return nil }
        let category = readinessCategory(for: log.dateKey)
        let items = RitualLibrary.items(for: category ?? activeCategory)
        return RitualDaySummary(log: log, date: date, category: category, items: items)
    }

    func consistencyDatesThisWeek() -> Set<String> {
        var days = Set<String>()
        checkInsThisWeek().forEach { days.insert(RitualLibrary.dateKey(for: $0.date)) }
        exerciseLogsThisWeek().forEach { days.insert(RitualLibrary.dateKey(for: $0.date)) }
        ritualLogsThisWeek()
            .filter { !$0.completedItemIDs.isEmpty }
            .forEach { days.insert($0.dateKey) }
        return days
    }

    func mostCommonReadinessThisWeek() -> ReadinessCategory? {
        let counts = Dictionary(grouping: checkInsThisWeek(), by: \.category)
            .mapValues(\.count)
        return counts.max { $0.value < $1.value }?.key
    }

    func ritualCapacity(for log: DailyRitualLog) -> Int {
        let category = readinessCategory(for: log.dateKey) ?? activeCategory
        return RitualLibrary.items(for: category).count
    }

    func ritualCompletionSummaryThisWeek() -> (completed: Int, available: Int) {
        ritualLogsThisWeek().reduce(into: (completed: 0, available: 0)) { result, log in
            result.completed += log.completedItemIDs.count
            result.available += ritualCapacity(for: log)
        }
    }

    func weeklyConsistencyChartPoints() -> [DailyChartPoint] {
        currentWeekDateKeys().map { day in
            var signals = 0
            if checkIns.contains(where: { RitualLibrary.dateKey(for: $0.date) == day.key }) { signals += 1 }
            if exerciseLogs.contains(where: { RitualLibrary.dateKey(for: $0.date) == day.key }) { signals += 1 }
            if ritualLogs.contains(where: { $0.dateKey == day.key && !$0.completedItemIDs.isEmpty }) { signals += 1 }
            return DailyChartPoint(
                id: "consistency-\(day.key)",
                dateKey: day.key,
                label: day.label,
                value: Double(signals),
                secondaryValue: nil,
                detail: signals == 0 ? "No signal yet" : "\(signals) signal\(signals == 1 ? "" : "s")"
            )
        }
    }

    func weeklyWorkoutSetChartPoints() -> [DailyChartPoint] {
        currentWeekDateKeys().map { day in
            let sets = exerciseLogs
                .filter { RitualLibrary.dateKey(for: $0.date) == day.key }
                .reduce(0) { $0 + $1.setsCompleted }
            return DailyChartPoint(
                id: "sets-\(day.key)",
                dateKey: day.key,
                label: day.label,
                value: Double(sets),
                secondaryValue: nil,
                detail: "\(sets) set\(sets == 1 ? "" : "s")"
            )
        }
    }

    func weeklyRitualChartPoints() -> [DailyChartPoint] {
        currentWeekDateKeys().map { day in
            guard let log = ritualLogs.first(where: { $0.dateKey == day.key }) else {
                return DailyChartPoint(id: "ritual-\(day.key)", dateKey: day.key, label: day.label, value: 0, secondaryValue: nil, detail: "No ritual signal")
            }
            let available = max(ritualCapacity(for: log), 1)
            let percent = Double(log.completedItemIDs.count) / Double(available) * 100
            return DailyChartPoint(
                id: "ritual-\(day.key)",
                dateKey: day.key,
                label: day.label,
                value: percent,
                secondaryValue: nil,
                detail: "\(log.completedItemIDs.count)/\(available) complete"
            )
        }
    }

    func weeklyNutritionChartPoints() -> [DailyChartPoint] {
        currentWeekDateKeys().compactMap { day in
            guard let log = nutritionLogs.first(where: { $0.dateKey == day.key }),
                  log.proteinGrams != nil || log.waterOunces != nil else {
                return nil
            }
            let protein = Double(log.proteinGrams ?? 0)
            let water = Double(log.waterOunces ?? 0)
            return DailyChartPoint(
                id: "nutrition-\(day.key)",
                dateKey: day.key,
                label: day.label,
                value: protein,
                secondaryValue: water,
                detail: "\(log.proteinGrams.map { "\($0)g protein" } ?? "protein --") | \(log.waterOunces.map { "\($0) oz water" } ?? "water --")"
            )
        }
    }

    func weeklySleepChartPoints() -> [DailyChartPoint] {
        currentWeekDateKeys().compactMap { day in
            guard let checkIn = checkIns.first(where: { RitualLibrary.dateKey(for: $0.date) == day.key }),
                  let sleep = checkIn.healthSnapshot.sleepHours else {
                return nil
            }
            return DailyChartPoint(
                id: "sleep-\(day.key)",
                dateKey: day.key,
                label: day.label,
                value: sleep,
                secondaryValue: nil,
                detail: String(format: "%.1f hr sleep", sleep)
            )
        }
    }

    var debugSummary: String {
        let snapshot = latestCheckIn?.healthSnapshot ?? todaySnapshot
        let checkIn = latestCheckIn
        return """
        Health state: \(healthState.title)
        Health availability: \(healthAvailabilityText)
        Health authorization: \(healthAuthorizationSummary)
        Last Health refresh: \(lastHealthRefreshText)
        Sleep: \(snapshot.sleepHours.map { String(format: "%.1f hr", $0) } ?? "nil")
        Sleep source: \(currentSleepSummary(checkIn: checkIn).sourceLabel)
        Steps: \(snapshot.steps.map(String.init) ?? "nil")
        Workouts: \(snapshot.workoutCount.map(String.init) ?? "nil")
        Workout minutes: \(snapshot.workoutMinutes.map { String(format: "%.0f", $0) } ?? "nil")
        Resting HR: \(snapshot.restingHeartRate.map { String(format: "%.0f", $0) } ?? "nil")
        HRV: \(snapshot.hrvSDNN.map { String(format: "%.0f", $0) } ?? "nil")
        Active energy: \(snapshot.activeEnergy.map { String(format: "%.0f", $0) } ?? "nil")
        Weight: \(snapshot.weightPounds.map { String(format: "%.1f", $0) } ?? "nil")
        Body metric entries: \(bodyMetricsEntries.count)
        Energy: \(checkIn?.energy.description ?? "nil")
        Soreness: \(checkIn?.soreness.description ?? "nil")
        Stress: \(checkIn?.stress.description ?? "nil")
        Mood: \(checkIn?.mood.description ?? "nil")
        Time: \(checkIn?.availableWorkoutMinutes.description ?? "nil")
        Pain note: \(checkIn?.painNote.isEmpty == false ? checkIn?.painNote ?? "" : "nil")
        Category: \(checkIn?.category.rawValue ?? "nil")
        Exercise logs: \(exerciseLogs.count)
        Ritual date: \(todayRitualDateKey)
        Ritual logs: \(ritualLogs.count)
        Nutrition logs: \(nutritionLogs.count)
        Oura mode: \(ouraConnectionSettings.connectionMode.rawValue)
        Oura source: \(ouraConnectionSettings.preferredRecoverySource.rawValue)
        Oura snapshots: \(ouraManualSnapshots.count)
        Notification permission: \(notificationPermissionStatus)
        Pending HCC notifications: \(pendingHealthCommandNotificationCount)
        Test reminder pending: \(isTestReminderPending ? "yes" : "no")
        """
    }

    func healthMetricStatusItems(snapshot: HealthSnapshot? = nil) -> [DeviceStatusItem] {
        let snapshot = snapshot ?? todaySnapshot
        if let diagnostics = snapshot.metricDiagnostics, !diagnostics.isEmpty {
            return diagnostics.map { diagnostic in
                let sampleText = diagnostic.sampleDate.map { "Sample: \($0.formatted(date: .abbreviated, time: .shortened))" } ?? "Sample: none"
                let errorText = diagnostic.errorText.map { "\nError: \($0)" } ?? ""
                return DeviceStatusItem(
                    id: diagnostic.id,
                    title: diagnostic.title,
                    value: diagnostic.valueText,
                    detail: "\(diagnostic.statusText) | \(diagnostic.queryWindow)\n\(sampleText)\n\(diagnostic.detail)\(errorText)"
                )
            }
        }

        return [
            DeviceStatusItem(
                id: "sleep",
                title: "Sleep",
                value: snapshot.sleepHours.map { String(format: "%.1f hr", $0) } ?? "No value",
                detail: snapshot.sleepHours == nil ? "No latest sleep summary returned." : "Sleep sample returned."
            ),
            DeviceStatusItem(
                id: "steps",
                title: "Steps",
                value: snapshot.steps.map(String.init) ?? "No value",
                detail: snapshot.steps == nil ? "No step count returned yet." : "Step count returned."
            ),
            DeviceStatusItem(
                id: "resting-hr",
                title: "Resting HR",
                value: snapshot.restingHeartRate.map { String(format: "%.0f bpm", $0) } ?? "No value",
                detail: snapshot.restingHeartRate == nil ? "No recent resting heart rate returned." : "Recent resting heart rate returned."
            ),
            DeviceStatusItem(
                id: "hrv",
                title: "HRV",
                value: snapshot.hrvSDNN.map { String(format: "%.0f ms", $0) } ?? "No value",
                detail: snapshot.hrvSDNN == nil ? "No recent HRV value returned." : "Recent HRV value returned."
            ),
            DeviceStatusItem(
                id: "active-energy",
                title: "Active Energy",
                value: snapshot.activeEnergy.map { String(format: "%.0f kcal", $0) } ?? "No value",
                detail: snapshot.activeEnergy == nil ? "No active energy returned today." : "Active energy returned."
            ),
            DeviceStatusItem(
                id: "workouts",
                title: "Workouts",
                value: snapshot.workoutCount.map { "\($0)" } ?? "No value",
                detail: snapshot.workoutMinutes.map { String(format: "%.0f workout minutes returned.", $0) } ?? "No workouts returned today."
            ),
            DeviceStatusItem(
                id: "weight",
                title: "Body Weight",
                value: snapshot.weightPounds.map { String(format: "%.1f lb", $0) } ?? "No value",
                detail: snapshot.weightPounds == nil ? "No recent body weight returned." : "Recent body weight returned."
            )
        ]
    }

    private func currentSleepSummary(checkIn: CheckIn?) -> SleepSummary {
        let appleSummary = appleHealthSleepSummary(checkIn: checkIn)
        let ouraSummary = ouraSleepSummary(checkIn: checkIn)
        let manualSummary = manualSleepSummary(checkIn: checkIn)

        switch ouraConnectionSettings.preferredRecoverySource {
        case .oura:
            return ouraSummary ?? appleSummary ?? manualSummary ?? .none
        case .appleHealth:
            return appleSummary ?? manualSummary ?? .none
        case .manualCheckIn:
            return manualSummary ?? .none
        case .automaticBestAvailable:
            return appleSummary ?? ouraSummary ?? manualSummary ?? .none
        }
    }

    func latestOuraManualSnapshot() -> OuraManualSnapshot? {
        ouraManualSnapshots.sorted { $0.updatedAt > $1.updatedAt }.first
    }

    func recentOuraManualSnapshots(limit: Int = 6) -> [OuraManualSnapshot] {
        Array(ouraManualSnapshots.sorted { $0.updatedAt > $1.updatedAt }.prefix(limit))
    }

    private func selectedOuraSnapshotForRecovery() -> OuraManualSnapshot? {
        guard ouraConnectionSettings.isEnabled else { return nil }
        guard ouraConnectionSettings.connectionMode == .mock || ouraConnectionSettings.connectionMode == .manual else { return nil }
        return latestOuraManualSnapshot()
    }

    private func ouraSleepSummary(checkIn: CheckIn?) -> SleepSummary? {
        guard ouraConnectionSettings.isEnabled else { return nil }
        if let oura = checkIn?.ouraSummary,
           let hours = oura.sleepDurationHours {
            return SleepSummary(
                durationHours: hours,
                durationText: String(format: "%.1f hr", hours),
                source: .oura,
                label: "Oura latest sleep",
                detailText: "Using Oura's latest sleep duration from the service layer.",
                endDate: nil,
                includesNapContext: false,
                lookupWindowDescription: nil
            )
        }
        if let snapshot = selectedOuraSnapshotForRecovery(),
           let hours = snapshot.sleepDurationHours {
            return SleepSummary(
                durationHours: hours,
                durationText: String(format: "%.1f hr", hours),
                source: .oura,
                label: "Oura latest sleep",
                detailText: "Using local Oura manual/mock latest sleep. OAuth is not connected yet.",
                endDate: nil,
                includesNapContext: false,
                lookupWindowDescription: nil
            )
        }
        return nil
    }

    private func appleHealthSleepSummary(checkIn: CheckIn?) -> SleepSummary? {
        if let summary = checkIn?.healthSnapshot.sleepSummary, summary.durationHours != nil {
            return summary
        }
        if let summary = todaySnapshot.sleepSummary, summary.durationHours != nil {
            return summary
        }
        return nil
    }

    private func manualSleepSummary(checkIn: CheckIn?) -> SleepSummary? {
        guard let legacySleep = checkIn?.healthSnapshot.sleepHours ?? todaySnapshot.sleepHours else { return nil }
        return SleepSummary(
            durationHours: legacySleep,
            durationText: String(format: "%.1f hr", legacySleep),
            source: .manualCheckIn,
            label: "Manual check-in sleep",
            detailText: "Using stored check-in sleep because no structured Apple Health or Oura summary is available.",
            endDate: nil,
            includesNapContext: false,
            lookupWindowDescription: nil
        )
    }

    private func recoverySourceDecision(
        checkIn: CheckIn?,
        sleepSummary: SleepSummary,
        ouraSnapshot: OuraManualSnapshot?
    ) -> RecoverySourceDecision {
        let primaryReason: String
        switch ouraConnectionSettings.preferredRecoverySource {
        case .automaticBestAvailable:
            switch sleepSummary.source {
            case .appleHealth:
                primaryReason = "Apple Health primary"
            case .oura:
                primaryReason = "Oura fallback"
            case .manualCheckIn:
                primaryReason = "Manual fallback"
            case .none:
                primaryReason = "No primary source"
            }
        case .appleHealth:
            primaryReason = sleepSummary.source == .appleHealth ? "Apple Health primary" : sleepSummary.sourceLabel
        case .oura:
            primaryReason = sleepSummary.source == .oura ? "Oura primary" : sleepSummary.sourceLabel
        case .manualCheckIn:
            primaryReason = sleepSummary.source == .manualCheckIn ? "Manual Check-In primary" : sleepSummary.sourceLabel
        }

        return RecoverySourceDecision(
            primarySource: sleepSummary.source,
            primaryReason: primaryReason,
            supportingContext: ouraSupportingContext(from: ouraSnapshot),
            subjectiveOverrideText: subjectiveOverrideText(for: checkIn),
            usesAppleHealthPrimary: sleepSummary.source == .appleHealth,
            usesOuraSupplement: ouraSnapshot?.hasRecoveryValues == true && sleepSummary.source != .oura
        )
    }

    private func ouraSupportingContext(from snapshot: OuraManualSnapshot?) -> String {
        guard ouraConnectionSettings.isEnabled,
              let snapshot,
              snapshot.hasRecoveryValues else {
            return "Supporting context: no Oura snapshot active."
        }

        var parts: [String] = []
        if let readiness = snapshot.readinessScore {
            parts.append("readiness \(readiness)")
        }
        if let sleepScore = snapshot.sleepScore {
            parts.append("sleep score \(sleepScore)")
        }
        if let trend = snapshot.bodyTemperatureTrend, !trend.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append("temperature \(trend)")
        }
        if !snapshot.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append("notes saved")
        }

        let context = parts.isEmpty ? "Oura snapshot saved" : "Oura " + parts.joined(separator: ", ")
        return "Supporting context: \(context). It can make the plan more conservative, not more aggressive."
    }

    private func subjectiveOverrideText(for checkIn: CheckIn?) -> String? {
        guard let checkIn else { return nil }
        var flags: [String] = []
        if checkIn.energy <= 3 { flags.append("low energy") }
        if checkIn.stress >= 8 { flags.append("high stress") }
        if checkIn.soreness >= 8 { flags.append("high soreness") }
        if !checkIn.painNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { flags.append("pain note") }
        guard !flags.isEmpty else { return nil }
        return "Subjective check-in keeps the plan conservative: \(flags.joined(separator: ", "))."
    }

    private func adjustedRecoveryCategory(_ category: RecoveryCategory, ouraSnapshot: OuraManualSnapshot?) -> RecoveryCategory {
        guard ouraConnectionSettings.isEnabled, let ouraSnapshot else { return category }
        let lowReadiness = (ouraSnapshot.readinessScore ?? 100) < 55
        let veryLowReadiness = (ouraSnapshot.readinessScore ?? 100) < 40
        let lowSleepScore = (ouraSnapshot.sleepScore ?? 100) < 55
        let lowSleepHours = (ouraSnapshot.sleepDurationHours ?? 99) < 5.5
        let elevatedTemperature = isElevatedTemperatureTrend(ouraSnapshot.bodyTemperatureTrend)

        if veryLowReadiness || lowSleepHours {
            return .poor
        }
        if lowReadiness || lowSleepScore || elevatedTemperature {
            return category == .poor ? .poor : .limited
        }
        return category
    }

    private func isElevatedTemperatureTrend(_ trend: String?) -> Bool {
        guard let trend = trend?.lowercased() else { return false }
        return trend.contains("high")
            || trend.contains("elevated")
            || trend.contains("above")
            || trend.contains("warm")
            || trend.contains("+")
    }

    private func optionalBodyMetricTrendText(title: String, unit: String, values: [(String, Double)]) -> String? {
        guard values.count >= 2 else { return nil }
        return bodyMetricTrendText(title: title, unit: unit, values: values)
    }

    private func bodyMetricTrendText(title: String, unit: String, values: [(String, Double)]) -> String {
        guard let first = values.first, let last = values.last else {
            return "\(title) trend starts after one local entry."
        }
        guard values.count >= 2 else {
            return "\(title) logged. Add another entry later to see direction."
        }
        let delta = last.1 - first.1
        if abs(delta) < 0.05 {
            return "\(title) is steady across recent entries."
        }
        let direction = delta > 0 ? "up" : "down"
        return String(format: "\(title) %.1f %@ %@", abs(delta), unit, direction)
    }

    private func plannedSetCount(from prescription: String) -> Int {
        let lower = prescription.lowercased()
        if let range = lower.range(of: #"(\d+)\s*sets"#, options: .regularExpression),
           let value = Int(lower[range].components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
            return max(value, 1)
        }
        if let range = lower.range(of: #"(\d+)\s*x"#, options: .regularExpression),
           let value = Int(lower[range].components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
            return max(value, 1)
        }
        return 2
    }

    private func logs(for exerciseID: String, exerciseName: String) -> [ExerciseLog] {
        exerciseLogs
            .filter { $0.exerciseID == exerciseID || $0.exerciseName == exerciseName }
            .sorted { $0.date > $1.date }
    }

    private func exerciseProgressSummary(id: String, exerciseName: String, logs: [ExerciseLog]) -> ExerciseProgressSummary {
        guard !logs.isEmpty else {
            return ExerciseProgressSummary(
                id: id,
                exerciseName: exerciseName,
                timesLogged: 0,
                mostRecentDate: nil,
                heaviestWeightText: "No logs yet",
                mostRepsText: "No reps yet",
                bestVolumeText: "No session yet",
                recentBestText: "First clean log starts the summary.",
                coachingLine: "Start with one honest set. Best-so-far records will appear after logging."
            )
        }

        let sorted = logs.sorted { $0.date > $1.date }
        let heaviest = logs.compactMap(\.weight).max()
        let mostReps = logs.map(\.reps).max() ?? 0
        let bestVolume = bestDailySetVolume(from: logs)
        let recentBest = bestRecentPerformance(from: logs)
        let latest = sorted.first

        return ExerciseProgressSummary(
            id: id,
            exerciseName: exerciseName,
            timesLogged: logs.count,
            mostRecentDate: latest?.date,
            heaviestWeightText: heaviest.map { formatWeight($0) } ?? "Bodyweight / band",
            mostRepsText: mostReps > 0 ? "\(mostReps) reps" : "No reps yet",
            bestVolumeText: bestVolume,
            recentBestText: recentBest,
            coachingLine: progressCoachingLine(timesLogged: logs.count, latest: latest)
        )
    }

    private func bestDailySetVolume(from logs: [ExerciseLog]) -> String {
        let grouped = Dictionary(grouping: logs) { RitualLibrary.dateKey(for: $0.date) }
        let best = grouped.values
            .map { dayLogs in
                (
                    sets: dayLogs.reduce(0) { $0 + $1.setsCompleted },
                    date: dayLogs.map(\.date).max() ?? Date.distantPast
                )
            }
            .max { left, right in
                if left.sets == right.sets { return left.date < right.date }
                return left.sets < right.sets
            }

        guard let best else { return "No session yet" }
        return "\(best.sets) set\(best.sets == 1 ? "" : "s") in one day"
    }

    private func bestRecentPerformance(from logs: [ExerciseLog]) -> String {
        let weighted = logs
            .filter { $0.weight != nil }
            .max { left, right in
                let leftScore = (left.weight ?? 0) * Double(max(left.reps, 1))
                let rightScore = (right.weight ?? 0) * Double(max(right.reps, 1))
                if leftScore == rightScore { return left.date < right.date }
                return leftScore < rightScore
            }

        if let weighted {
            return "\(formatWeight(weighted.weight ?? 0)) x \(weighted.reps) reps"
        }

        let bodyweight = logs.max { left, right in
            if left.reps == right.reps { return left.date < right.date }
            return left.reps < right.reps
        }

        guard let bodyweight else { return "First clean log starts the summary." }
        return "\(bodyweight.reps) reps, easy setup"
    }

    private func progressCoachingLine(timesLogged: Int, latest: ExerciseLog?) -> String {
        guard timesLogged > 0 else {
            return "Start with one honest set. Best-so-far records will appear after logging."
        }
        guard let latest else {
            return "Keep logging clean work. The summary gets better with each signal."
        }
        if latest.effort >= 9 {
            return "Recent effort was high. Repeat or back off before chasing a new best."
        }
        if timesLogged < 3 {
            return "Good early signal. Build the baseline before chasing bigger numbers."
        }
        return "Best so far is just a reference point. Match clean reps before adding more."
    }

    private func averageInt(_ values: [Int]) -> Int? {
        guard !values.isEmpty else { return nil }
        return Int((Double(values.reduce(0, +)) / Double(values.count)).rounded())
    }

    private func currentWeekDateKeys() -> [(key: String, label: String)] {
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "E"

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            return (RitualLibrary.dateKey(for: date), String(formatter.string(from: date).prefix(1)))
        }
    }

    private func recoveryCategory(sleepHours: Double?, checkIn: CheckIn?, readiness: ReadinessCategory?) -> RecoveryCategory {
        if readiness == .recoveryDay || readiness == .bareMinimumDay {
            return .poor
        }
        if let sleepHours {
            if sleepHours < 5 { return .poor }
            if sleepHours < 6 { return .limited }
            if sleepHours < 7 { return .okay }
        }
        if let checkIn {
            if checkIn.energy <= 3 || checkIn.stress >= 8 || checkIn.soreness >= 8 {
                return .limited
            }
            if checkIn.energy >= 8 && checkIn.stress <= 4 && checkIn.soreness <= 5 {
                return .strong
            }
            return .okay
        }
        guard sleepHours != nil else { return .unknown }
        return .strong
    }

    private func sleepQualityText(for category: RecoveryCategory, sleepHours: Double?) -> String {
        switch category {
        case .strong: return "Recovery looks strong"
        case .okay: return "Usable recovery"
        case .limited: return "Limited recovery"
        case .poor: return sleepHours.map { $0 < 5 ? "Low sleep day" : "Recovery needs protection" } ?? "Recovery needs protection"
        case .unknown: return "Check in to sharpen this"
        }
    }

    private func trainingAdjustmentText(for category: RecoveryCategory, readiness: ReadinessCategory?) -> String {
        if readiness == nil {
            return "Start Check In before choosing training intensity."
        }
        switch category {
        case .strong:
            return "Train normally. Push intelligently only if reps stay clean."
        case .okay:
            return "Run the plan, cap intensity, and keep one rep in reserve."
        case .limited:
            return "Use the short version or reduce one set."
        case .poor:
            return "Choose recovery, walking, mobility, or bare-minimum movement."
        case .unknown:
            return "Protect basics until sleep and readiness are clearer."
        }
    }

    private func caffeineGuidance(for phase: ProgramPhase) -> String {
        switch phase {
        case .nightShift:
            return "Set caffeine relative to the planned sleep window, not the clock. Avoid late-shift drift."
        case .dayShift:
            return "Keep caffeine earlier so the evening wind-down stays clean."
        case .newBaby:
            return "Use caffeine carefully. Do not let survival caffeine steal the next sleep chance."
        case .normalRoutine:
            return "Use a consistent cutoff that protects tonight's sleep."
        }
    }

    private func windDownGuidance(for phase: ProgramPhase) -> String {
        switch phase {
        case .nightShift:
            return "Dark room, cool room, phone dimmed, and a short post-shift off-ramp."
        case .dayShift:
            return "Regular wind-down, stable wake time, dim screens, boring routine."
        case .newBaby:
            return "Lower the floor. Use any quiet window for a short reset and sleep chance."
        case .normalRoutine:
            return "Keep the sleep routine repeatable: light down, screens down, same off-ramp."
        }
    }

    private func napGuidance(for phase: ProgramPhase, category: RecoveryCategory) -> String {
        switch phase {
        case .nightShift:
            return "A strategic nap before or after shift can protect the sleep bank."
        case .newBaby:
            return "Take the useful nap when it appears. Perfect timing is not required."
        default:
            return category == .poor || category == .limited ? "Use a short nap if it will not steal tonight's sleep." : "Nap optional. Protect the main sleep window first."
        }
    }

    private func recoveryCoachingLine(for category: RecoveryCategory, phase: ProgramPhase) -> String {
        switch (category, phase) {
        case (.poor, .newBaby):
            return "Lower the floor today. Patience is productive."
        case (.poor, .nightShift):
            return "Protect the next sleep window. Training can wait."
        case (.limited, _):
            return "Reduce friction and avoid borrowing from tomorrow."
        case (.strong, _):
            return "Good recovery signal. Use it without overreaching."
        case (.unknown, _):
            return "Check in, then protect caffeine, light, and wind-down basics."
        default:
            return "Keep the day steady and make tonight easier."
        }
    }

    private func plannedRepRange(from prescription: String) -> (lower: Int, upper: Int)? {
        let lower = prescription.lowercased()
        if let range = lower.range(of: #"\d+\s*-\s*\d+"#, options: .regularExpression) {
            let values = lower[range]
                .split(separator: "-")
                .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            if values.count == 2 {
                return (min(values[0], values[1]), max(values[0], values[1]))
            }
        }
        if let range = lower.range(of: #"\d+\s*reps"#, options: .regularExpression),
           let value = Int(lower[range].components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
            return (value, value)
        }
        return nil
    }

    private func startingWeightText(for exercise: ExercisePlan) -> String {
        let equipment = exercise.equipment.lowercased()
        if equipment.contains("dumbbell") {
            return "Aim for a light dumbbell you can control"
        }
        if equipment.contains("band") {
            return "Aim for an easy band setup"
        }
        if equipment.contains("bodyweight") || equipment.contains("mat") {
            return "Aim for bodyweight control"
        }
        return "Aim for the easiest useful setup"
    }

    private func weightText(for log: ExerciseLog) -> String? {
        log.weight.map(formatWeight)
    }

    private func reducedWeightText(from log: ExerciseLog) -> String? {
        guard let weight = log.weight else { return nil }
        return "Back off to \(formatWeight(max(weight - weightStep(for: weight), 0)))"
    }

    private func formatWeight(_ weight: Double) -> String {
        "\(Int(weight.rounded())) lb"
    }

    private func weightStep(for weight: Double) -> Double {
        weight < 30 ? 2.5 : 5
    }

    private func shoulderCautionNote(for exercise: ExercisePlan) -> String? {
        guard hasShoulderContext else { return nil }
        let text = ([exercise.name, exercise.equipment] + exercise.musclesTargeted + exercise.formCues)
            .joined(separator: " ")
            .lowercased()
        let shoulderRelated = ["shoulder", "press", "overhead", "upper back", "row"].contains { text.contains($0) }
        return shoulderRelated ? "Shoulder note today: keep range cautious and avoid aggressive overhead work." : nil
    }

    private var hasShoulderContext: Bool {
        guard hasCheckedInToday, let note = latestCheckIn?.painNote.lowercased() else { return false }
        return ["shoulder", "neck", "trap", "rotator", "overhead"].contains { note.contains($0) }
    }

    private func appendDebug(_ message: String) {
        debugLog.insert("[\(Date().formatted(date: .omitted, time: .standard))] \(message)", at: 0)
        debugLog = Array(debugLog.prefix(12))
    }

    private func applyNotificationStatus(_ status: NotificationDebugStatus) {
        notificationPermissionStatus = status.permissionStatusText
        scheduledReminderCount = status.scheduledReminderCount
        pendingHealthCommandNotificationCount = status.pendingHealthCommandCount
        isTestReminderPending = status.isTestReminderPending
    }

    private func isInCurrentWeek(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }

    private func dateFromRitualKey(_ key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key)
    }

    private func currentStreak(from dateKeys: Set<String>) -> Int {
        guard !dateKeys.isEmpty else { return 0 }

        var streak = 0
        var currentDate = Date()

        while dateKeys.contains(RitualLibrary.dateKey(for: currentDate)) {
            streak += 1
            guard let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDate
        }

        return streak
    }

    private func workoutSessions(from logs: [ExerciseLog], limit: Int? = nil) -> [WorkoutSession] {
        let grouped = Dictionary(grouping: logs) { log in
            RitualLibrary.dateKey(for: log.date)
        }

        let sessions = grouped.map { dateKey, logs in
            WorkoutSession(id: dateKey, dateKey: dateKey, logs: logs)
        }
        .sorted { $0.latestDate > $1.latestDate }

        if let limit {
            return Array(sessions.prefix(limit))
        }

        return sessions
    }
}
