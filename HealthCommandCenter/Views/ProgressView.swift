import SwiftUI
import PhotosUI
import UIKit

struct ProgressDashboardView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var selectedWorkoutSession: WorkoutSession?
    @State private var selectedRitualDay: RitualDaySummary?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var progressPhotoAngle: ProgressPhotoAngle = .front
    @State private var progressPhotoNotes = ""
    @State private var progressPhotoFeedback: String?
    @State private var photoToDelete: ProgressPhotoEntry?

    private var category: ReadinessCategory {
        appModel.activeCategory
    }

    private var weekCheckIns: [CheckIn] {
        appModel.checkInsThisWeek()
    }

    private var weekExerciseLogs: [ExerciseLog] {
        appModel.exerciseLogsThisWeek()
    }

    private var weekRitualSummary: (completed: Int, available: Int) {
        appModel.ritualCompletionSummaryThisWeek()
    }

    var body: some View {
        ZStack {
            CommandBackground(category: category)

            ScrollView {
                VStack(alignment: .leading, spacing: CommandDesign.stackSpacing) {
                    ScreenHeader(
                        eyebrow: "INSIGHTS",
                        title: "Signals over time.",
                        subtitle: "Local trends, recent sessions, and consistency context without turning the app into a scoreboard."
                    )

                    overviewSection
                    thisWeekSection
                    weeklyCoachReportSection
                    goalsProgressSection
                    chartsSection
                    workoutHistorySection
                    consistencyStreaksSection
                    ritualHistorySection
                    recoveryProgressSection
                    nutritionProgressSection
                    bodyMetricsProgressSection
                    progressPhotosSection
                    exerciseProgressSection
                    ouraProgressSection
                    readinessHistorySection
                }
                .padding(CommandDesign.pagePadding)
            }
        }
        .sheet(item: $selectedWorkoutSession) { session in
            WorkoutSessionDetailView(session: session, accent: category.accent)
        }
        .sheet(item: $selectedRitualDay) { day in
            RitualDayDetailView(day: day, accent: category.accent)
        }
        .alert("Delete progress photo?", isPresented: Binding(
            get: { photoToDelete != nil },
            set: { if !$0 { photoToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let photoToDelete {
                    appModel.deleteProgressPhoto(photoToDelete)
                    progressPhotoFeedback = "Progress photo deleted"
                }
                photoToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                photoToDelete = nil
            }
        } message: {
            Text("This deletes the local copy stored by Health Command Center. It does not delete anything from Photos.")
        }
        .task(id: selectedPhotoItem) {
            guard let selectedPhotoItem else { return }
            selectedPhotoData = try? await selectedPhotoItem.loadTransferable(type: Data.self)
        }
    }

    private var overviewSection: some View {
        HeroCard(accent: category.accent) {
            VStack(alignment: .leading, spacing: 16) {
                StatusPill(title: appModel.hasCheckedInToday ? category.rawValue : "CHECK-IN NEEDED", icon: "chart.xyaxis.line", accent: category.accent)
                Text(coachingSummary)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    overviewMetric("Check-ins", "\(weekCheckIns.count)", "This week")
                    overviewMetric("Sets", "\(weeklySetCount)", "Logged")
                    overviewMetric("Ritual", ritualPercentText, "\(weekRitualSummary.completed)/\(weekRitualSummary.available)")
                    overviewMetric("Consistency", "\(appModel.consistencyDatesThisWeek().count)", "Days active")
                }
            }
        }
    }

    private var thisWeekSection: some View {
        let programWeek = appModel.currentProgramWeek()
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Weekly overview",
                subtitle: "The useful signals for this week, grouped before the details.",
                icon: "calendar.badge.clock",
                accent: category.accent
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ProgressStatCard(title: "Workouts", value: "\(workoutSessionsThisWeekCount) sessions", detail: "\(weeklySetCount) sets logged", icon: "figure.strengthtraining.traditional", accent: category.accent)
                ProgressStatCard(title: "Program", value: programWeek.summaryText, detail: "Planned vs completed", icon: "calendar.badge.clock", accent: category.accent)
                ProgressStatCard(title: "Ritual", value: ritualPercentText, detail: "\(weekRitualSummary.completed) of \(weekRitualSummary.available) items", icon: "moon.stars", accent: category.accent)
                ProgressStatCard(title: "Readiness", value: appModel.mostCommonReadinessThisWeek()?.rawValue ?? "No data", detail: "Most common category", icon: "gauge.with.dots.needle.bottom.100percent", accent: category.accent)
                ProgressStatCard(title: "Consistency", value: "\(appModel.consistencyDatesThisWeek().count) days", detail: "Check-in, workout, or ritual", icon: "checkmark.seal", accent: category.accent)
            }

            CommandCard {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(
                        title: "Program schedule",
                        subtitle: "Moved or downgraded sessions are treated as adjustments, not misses.",
                        icon: "calendar",
                        accent: category.accent
                    )
                    ForEach(programWeek.sessions.prefix(5)) { session in
                        HStack(alignment: .top, spacing: 10) {
                            StatusPill(title: session.status.rawValue, accent: session.status == .completed ? Color.green : category.accent)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(session.dateKey) · \(session.workoutTitle)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(session.note)
                                    .font(.caption)
                                    .foregroundStyle(CommandDesign.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
    }

    private var weeklyCoachReportSection: some View {
        let review = appModel.currentWeeklyReview()
        return CommandSection(
            title: "Weekly Coach Report",
            subtitle: "\(review.weekStartDate.formatted(date: .abbreviated, time: .omitted)) - \(review.weekEndDate.formatted(date: .abbreviated, time: .omitted))",
            icon: "doc.text.magnifyingglass",
            accent: category.accent
        ) {
            CommandCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(category.accent)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Coach summary")
                                .font(.caption.weight(.semibold))
                                .textCase(.uppercase)
                                .foregroundStyle(CommandDesign.secondaryText)
                            Text(review.coachSummary)
                                .font(.headline)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if !review.hasUsefulData {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Not enough week data yet", systemImage: "chart.bar.doc.horizontal")
                                .font(.headline)
                                .foregroundStyle(category.accent)
                            Text("Start with Check In, one Train log, and one Recovery ritual. The report will become more useful as the week gets signals.")
                                .font(.subheadline)
                                .foregroundStyle(CommandDesign.secondaryText)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                            SecondaryActionButton(title: "Start Check In", icon: "slider.horizontal.3", accent: category.accent) {
                                appModel.startNewCheckIn()
                            }
                        }
                        .padding(12)
                        .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        coachMetric("Check-ins", "\(review.checkInCount)", "This week")
                        coachMetric("Workout days", "\(review.workoutDays)", "\(review.totalSets) sets")
                        coachMetric("Ritual days", "\(review.ritualDays)", "\(review.ritualCompletionPercent)% complete")
                        coachMetric("Nutrition", "\(review.nutritionLoggedDays)", "Logged days")
                        coachMetric("Avg sleep", review.averageSleep.map { String(format: "%.1f hr", $0) } ?? "--", "\(review.lowSleepDays) low-sleep days")
                        coachMetric("Protein / water", "\(review.averageProtein.map { "\($0)g" } ?? "--") / \(review.averageWater.map { "\($0) oz" } ?? "--")", "Averages")
                    }

                    coachList(title: "Wins this week", items: review.wins, icon: "checkmark.seal")
                    coachList(title: "Watchouts", items: review.watchouts, icon: "exclamationmark.triangle")
                    coachList(title: "Next week focus", items: review.nextWeekFocus, icon: "arrow.forward.circle")

                    HStack(spacing: 8) {
                        StatusPill(title: review.consistencyScoreText, icon: "checkmark.circle", accent: category.accent)
                        if let readiness = review.mostCommonReadiness {
                            StatusPill(title: readiness.rawValue, icon: "gauge.with.dots.needle.bottom.100percent", accent: readiness.accent)
                        }
                    }

                    Text("Body trend: \(review.bodyWeightTrendText)")
                        .font(.caption)
                        .foregroundStyle(CommandDesign.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Charts",
                subtitle: "Simple local views. No pressure, just visibility.",
                icon: "chart.bar",
                accent: category.accent
            )

            WeeklyBarChartCard(
                title: "Consistency",
                subtitle: "Check-in, ritual, and workout signals by day.",
                points: appModel.weeklyConsistencyChartPoints(),
                maxValue: 3,
                unit: "signals",
                emptyTitle: "No consistency signals yet",
                emptyMessage: "Start with Check In, one Ritual item, or one logged set.",
                accent: category.accent
            )

            WeeklyBarChartCard(
                title: "Workout Sets",
                subtitle: "Total logged sets per day.",
                points: appModel.weeklyWorkoutSetChartPoints(),
                maxValue: nil,
                unit: "sets",
                emptyTitle: "No workout sets this week",
                emptyMessage: "Open Workouts and log one honest set to start the chart.",
                accent: category.accent
            )

            WeeklyBarChartCard(
                title: "Ritual Completion",
                subtitle: "Daily completion percentage.",
                points: appModel.weeklyRitualChartPoints(),
                maxValue: 100,
                unit: "%",
                emptyTitle: "No ritual chart yet",
                emptyMessage: "Toggle one Ritual item today. The chart will fill in from there.",
                accent: category.accent
            )

            WeeklyDualBarChartCard(
                title: "Nutrition",
                subtitle: "Protein and water on logged days.",
                points: appModel.weeklyNutritionChartPoints(),
                primaryLabel: "Protein",
                secondaryLabel: "Water",
                emptyTitle: "No nutrition chart yet",
                emptyMessage: "Save today's nutrition anchors in Ritual.",
                accent: category.accent
            )

            WeeklyBarChartCard(
                title: "Sleep",
                subtitle: "Stored check-in sleep summaries when available.",
                points: appModel.weeklySleepChartPoints(),
                maxValue: 9,
                unit: "hr",
                emptyTitle: "No sleep chart yet",
                emptyMessage: "Complete Check In with sleep data available, or connect Apple Health.",
                accent: category.accent
            )
        }
    }

    private var goalsProgressSection: some View {
        let goals = appModel.currentGoalProgress()
        return CommandSection(
            title: "Goals & Targets",
            subtitle: "Simple targets for recomposition, strength, recovery, and consistency. Trend, not judgment.",
            icon: "target",
            accent: category.accent
        ) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(goals.prefix(6)) { goal in
                    goalProgressCard(goal)
                }
            }
            DisclosureGroup {
                VStack(spacing: 10) {
                    ForEach(goals.dropFirst(6)) { goal in
                        goalProgressCard(goal)
                    }
                }
                .padding(.top, 8)
            } label: {
                Label("Body and trend targets", systemImage: "scalemass")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .tint(category.accent)
        }
    }

    private func goalProgressCard(_ goal: GoalProgress) -> some View {
        CommandCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(goal.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    StatusPill(title: goal.statusText, accent: goal.status == .onTrack ? Color.green : category.accent)
                }
                Text(goal.currentText)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(category.accent)
                Text("Target: \(goal.targetText)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CommandDesign.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                if let fraction = goal.progressFraction {
                    ProgressView(value: fraction)
                        .tint(category.accent)
                }
                Text(goal.coachingLine)
                    .font(.caption)
                    .foregroundStyle(CommandDesign.secondaryText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var recoveryProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Recovery context",
                subtitle: "Recovery history from stored check-ins. Historical Apple/Oura sleep summaries can come later.",
                icon: "bed.double",
                accent: category.accent
            )

            let recent = appModel.recentRecoveryCheckIns()
            if appModel.averageSleepThisWeek() == nil && recent.isEmpty {
                EmptyStateCard(
                    title: "No recovery history yet",
                    message: "Complete Check In with Health sleep available, or connect Apple Health. Recovery history starts with one useful sleep signal.",
                    icon: "bed.double",
                    accent: category.accent,
                    actionTitle: "Start Check In",
                    actionIcon: "slider.horizontal.3",
                    action: {
                        appModel.startNewCheckIn()
                    }
                )
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    overviewMetric("Avg sleep", appModel.averageSleepThisWeek().map { String(format: "%.1f hr", $0) } ?? "--", "This week")
                    overviewMetric("Low sleep", "\(appModel.lowSleepDaysThisWeek())", "Under 5 hr")
                }

                VStack(spacing: 10) {
                    ForEach(recent) { checkIn in
                        RecoveryHistoryRow(checkIn: checkIn, accent: category.accent)
                    }
                }
            }
        }
    }

    private var ouraProgressSection: some View {
        let snapshots = appModel.recentOuraManualSnapshots()
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Oura Test Snapshots",
                subtitle: "Manual/mock Oura values for testing recovery source behavior. OAuth is not connected yet.",
                icon: "ring",
                accent: category.accent
            )

            if snapshots.isEmpty {
                EmptyStateCard(
                    title: "No Oura test data yet",
                    message: "Add a manual/mock Oura snapshot in Profile to test how Oura affects recovery guidance.",
                    icon: "ring",
                    accent: category.accent,
                    actionTitle: "Open Profile",
                    actionIcon: "person.crop.circle",
                    action: {
                        appModel.selectedTab = .profile
                    }
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(snapshots) { snapshot in
                        HistoryRow(
                            title: "Oura test snapshot",
                            subtitle: "\(snapshot.dateKey) | updated \(snapshot.updatedAt.formatted(date: .abbreviated, time: .shortened))",
                            detail: ouraSnapshotDetail(snapshot),
                            icon: "ring",
                            accent: category.accent
                        )
                    }
                }
            }
        }
    }

    private var workoutHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Training history",
                subtitle: "Grouped by calendar day for now, using the logs already stored on this device.",
                icon: "dumbbell",
                accent: category.accent
            )

            let sessions = appModel.recentWorkoutSessions()
            if sessions.isEmpty {
                EmptyStateCard(
                    title: "No workout sessions yet",
                    message: "Open Workouts and log one honest set. That is enough to start a session history.",
                    icon: "dumbbell",
                    accent: category.accent,
                    actionTitle: "Open Workouts",
                    actionIcon: "calendar",
                    action: {
                        appModel.goToPlan()
                    }
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(sessions) { session in
                        Button {
                            selectedWorkoutSession = session
                        } label: {
                            WorkoutSessionCard(session: session, accent: category.accent)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open workout session from \(session.startDate.formatted(date: .abbreviated, time: .omitted))")
                    }
                }

                DisclosureGroup {
                    VStack(spacing: 10) {
                        ForEach(appModel.exerciseLogs.prefix(6)) { log in
                            HistoryRow(
                                title: log.exerciseName,
                                subtitle: log.date.formatted(date: .abbreviated, time: .shortened),
                                detail: log.summary + (log.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : " | notes"),
                                icon: "list.bullet.rectangle",
                                accent: category.accent
                            )
                        }
                    }
                    .padding(.top, 10)
                } label: {
                    Label("Individual recent sets", systemImage: "list.bullet.rectangle")
                        .font(.headline)
                }
                .tint(category.accent)
            }
        }
    }

    private var exerciseProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Exercise progress",
                subtitle: "Best-so-far summaries from local workout logs. No charts, no testing pressure.",
                icon: "chart.line.uptrend.xyaxis",
                accent: category.accent
            )

            let summaries = appModel.recentExerciseProgressSummaries()
            if summaries.isEmpty {
                EmptyStateCard(
                    title: "No exercise summaries yet",
                    message: "Log one set in Workouts. The app will start showing best-so-far summaries without turning it into a max test.",
                    icon: "chart.line.uptrend.xyaxis",
                    accent: category.accent,
                    actionTitle: "Open Workouts",
                    actionIcon: "calendar",
                    action: {
                        appModel.goToPlan()
                    }
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(summaries) { summary in
                        ExerciseProgressCard(summary: summary, accent: category.accent)
                    }
                }
            }
        }
    }

    private var nutritionProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Nutrition",
                subtitle: "Manual HCC anchors plus Apple Health nutrition when another app writes samples there.",
                icon: "fork.knife",
                accent: category.accent
            )

            let recent = appModel.recentNutritionLogs()
            let display = appModel.todayNutritionDisplay()
            let hasAppleHealthNutrition = display.source == "Apple Health"
            if recent.isEmpty && !hasAppleHealthNutrition {
                EmptyStateCard(
                    title: "No nutrition summaries yet",
                    message: "Open Ritual and save today's anchors, or let Cronometer write nutrition to Apple Health so HCC can read the summary.",
                    icon: "fork.knife",
                    accent: category.accent,
                    actionTitle: "Open Ritual",
                    actionIcon: "moon.stars",
                    action: {
                        appModel.goToRitual()
                    }
                )
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    overviewMetric("Cronometer", "\(appModel.cronometerCompletionsThisWeek())", "This week")
                    overviewMetric("Protein", appModel.averageProteinThisWeek().map { "\($0)g" } ?? "--", "Avg logged")
                    overviewMetric("Water", appModel.averageWaterThisWeek().map { "\($0) oz" } ?? "--", "Avg logged")
                }

                VStack(spacing: 10) {
                    if hasAppleHealthNutrition {
                        NutritionDayRow(log: display.log, source: display.source, accent: category.accent)
                    }
                    ForEach(recent) { log in
                        NutritionDayRow(log: log, source: "HCC manual", accent: category.accent)
                    }
                }
            }
        }
    }

    private var bodyMetricsProgressSection: some View {
        let summary = appModel.latestBodyMetricsSummary()
        let recent = appModel.recentBodyMetricsEntries()
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Body metrics",
                subtitle: "Trend-focused recomposition notes. Smart-scale composition values are direction data.",
                icon: "scalemass",
                accent: category.accent
            )

            if recent.isEmpty && summary.appleHealthWeightPounds == nil {
                EmptyStateCard(
                    title: "No body metrics yet",
                    message: "Log a simple weight, waist, or smart-scale snapshot in Profile. One entry is enough to start.",
                    icon: "scalemass",
                    accent: category.accent,
                    actionTitle: "Open Profile",
                    actionIcon: "person.crop.circle",
                    action: {
                        appModel.selectedTab = .profile
                    }
                )
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    overviewMetric("Latest", summary.latestWeightText, summary.sourceText)
                    overviewMetric("Direction", "Trend", summary.trendText)
                }

                VStack(alignment: .leading, spacing: 8) {
                    if let bodyFat = summary.bodyFatTrendText {
                        Text(bodyFat)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let waist = summary.waistTrendText {
                        Text(waist)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("Use direction over time. Body composition estimates from smart scales are not exact measurements.")
                        .font(.caption2)
                        .foregroundStyle(.secondary.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if recent.isEmpty {
                    EmptyStateCard(
                        title: "Apple Health weight only",
                        message: "Apple Health weight is visible as context. Save a manual or smart-scale entry in Profile to build local trends.",
                        icon: "heart.text.square",
                        accent: category.accent,
                        actionTitle: "Open Profile",
                        actionIcon: "person.crop.circle",
                        action: {
                            appModel.selectedTab = .profile
                        }
                    )
                } else {
                    VStack(spacing: 10) {
                        ForEach(recent) { entry in
                            BodyMetricsRow(entry: entry, accent: category.accent)
                        }
                    }
                }
            }
        }
    }

    private var progressPhotosSection: some View {
        CommandSection(
            title: "Progress Photos",
            subtitle: "Optional local photos for front, side, and back comparisons. Private on device.",
            icon: "photo.on.rectangle",
            accent: category.accent
        ) {
            CommandCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Use photos as quiet context, not judgment. Nothing uploads; the app stores a local copy only after you tap Save.")
                        .font(.caption)
                        .foregroundStyle(CommandDesign.secondaryText)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Picker("Angle", selection: $progressPhotoAngle) {
                        ForEach(ProgressPhotoAngle.allCases) { angle in
                            Text(angle.rawValue).tag(angle)
                        }
                    }
                    .pickerStyle(.segmented)

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label(selectedPhotoData == nil ? "Choose Photo" : "Photo Selected", systemImage: "photo")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                            .foregroundStyle(category.accent)
                    }
                    .accessibilityLabel("Choose progress photo")

                    TextField("Optional notes", text: $progressPhotoNotes, axis: .vertical)
                        .lineLimit(2...4)
                        .commandFieldStyle()

                    PrimaryActionButton(title: "Save Progress Photo", icon: "square.and.arrow.down", accent: category.accent) {
                        guard let selectedPhotoData else {
                            progressPhotoFeedback = "Choose a photo first"
                            return
                        }
                        appModel.saveProgressPhoto(angle: progressPhotoAngle, notes: progressPhotoNotes, imageData: selectedPhotoData)
                        self.selectedPhotoData = nil
                        selectedPhotoItem = nil
                        progressPhotoNotes = ""
                        progressPhotoFeedback = "Progress photo saved locally"
                    }

                    if let progressPhotoFeedback {
                        CommandFeedbackPill(message: progressPhotoFeedback, icon: "info.circle", accent: category.accent)
                    }
                }
            }

            if appModel.progressPhotos.isEmpty {
                EmptyStateCard(
                    title: "No progress photos yet",
                    message: "Add one front, side, or back photo when it feels useful. This is optional and local-only.",
                    icon: "photo",
                    accent: category.accent
                )
            } else {
                progressPhotoCompareCard
                ForEach(appModel.progressPhotos.prefix(6)) { entry in
                    progressPhotoRow(entry)
                }
            }
        }
    }

    private var progressPhotoCompareCard: some View {
        let photos = Array(appModel.progressPhotos.prefix(2))
        return CommandCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Compare latest", subtitle: photos.count >= 2 ? "Two most recent local photos." : "Add a second photo to compare.", icon: "rectangle.split.2x1", accent: category.accent)
                if photos.count >= 2 {
                    HStack(spacing: 10) {
                        ForEach(photos) { photo in
                            VStack(alignment: .leading, spacing: 6) {
                                ProgressPhotoImageView(url: appModel.progressPhotoImageURL(for: photo))
                                    .frame(height: 170)
                                    .clipShape(RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                                Text("\(photo.angle.rawValue) · \(photo.date.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(CommandDesign.secondaryText)
                                    .lineLimit(1)
                            }
                        }
                    }
                } else {
                    Text("One photo saved. Add another later for a side-by-side check.")
                        .font(.caption)
                        .foregroundStyle(CommandDesign.secondaryText)
                }
            }
        }
    }

    private func progressPhotoRow(_ entry: ProgressPhotoEntry) -> some View {
        CommandCard {
            HStack(alignment: .top, spacing: 12) {
                ProgressPhotoImageView(url: appModel.progressPhotoImageURL(for: entry))
                    .frame(width: 76, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 7) {
                        StatusPill(title: entry.angle.rawValue, accent: category.accent)
                        Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CommandDesign.secondaryText)
                    }
                    Text(entry.notes.isEmpty ? "No notes" : entry.notes)
                        .font(.caption)
                        .foregroundStyle(CommandDesign.secondaryText)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Button(role: .destructive) {
                    photoToDelete = entry
                } label: {
                    Image(systemName: "trash")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red.opacity(0.9))
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.06), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete progress photo")
            }
        }
    }

    private var consistencyStreaksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Recovery / ritual consistency",
                subtitle: "Quiet momentum, not pressure. A streak just means the system has a recent signal.",
                icon: "flame",
                accent: category.accent
            )

            let streaks = [
                ("Check-ins", appModel.currentCheckInStreak(), "slider.horizontal.3"),
                ("Ritual", appModel.currentRitualStreak(), "moon.stars"),
                ("Workouts", appModel.currentWorkoutStreak(), "figure.walk"),
                ("Overall", appModel.currentOverallConsistencyStreak(), "checkmark.seal")
            ]

            if streaks.allSatisfy({ $0.1 == 0 }) {
                EmptyStateCard(
                    title: "No active streak yet",
                    message: "Start with a Check In, one Ritual item, or one logged set today. That is enough to put a signal on the board.",
                    icon: "sparkle",
                    accent: category.accent,
                    actionTitle: "Start Check In",
                    actionIcon: "slider.horizontal.3",
                    action: {
                        appModel.startNewCheckIn()
                    }
                )
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(streaks, id: \.0) { streak in
                        StreakCard(title: streak.0, days: streak.1, icon: streak.2, accent: category.accent)
                    }
                }
            }
        }
    }

    private var ritualHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Ritual days",
                subtitle: "Review the daily floor over time. One completed item counts as a ritual signal.",
                icon: "moon.stars",
                accent: category.accent
            )

            let days = appModel.recentRitualDays()
            if days.allSatisfy({ $0.completedCount == 0 }) {
                EmptyStateCard(
                    title: "No ritual history yet",
                    message: "Toggle one Ritual item today. The system only needs one completed anchor to start tracking.",
                    icon: "moon.stars",
                    accent: category.accent,
                    actionTitle: "Open Ritual",
                    actionIcon: "moon.stars",
                    action: {
                        appModel.goToRitual()
                    }
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(days) { day in
                        Button {
                            selectedRitualDay = day
                        } label: {
                            RitualDayCard(day: day, accent: category.accent)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open ritual day from \(day.date.formatted(date: .abbreviated, time: .omitted))")
                    }
                }
            }
        }
    }

    private var readinessHistorySection: some View {
        historySection(
            title: "Recent Readiness",
            emptyTitle: "No check-ins yet",
            emptyText: "Complete today's Check In first. Readiness history starts with one clear body report.",
            emptyIcon: "gauge.with.dots.needle.bottom.100percent",
            actionTitle: "Start Check In",
            actionIcon: "slider.horizontal.3",
            action: {
                appModel.startNewCheckIn()
            }
        ) {
            ForEach(appModel.checkIns.prefix(8)) { checkIn in
                HistoryRow(
                    title: checkIn.category.rawValue,
                    subtitle: checkIn.date.formatted(date: .abbreviated, time: .shortened),
                    detail: "Energy \(checkIn.energy) · Stress \(checkIn.stress) · Soreness \(checkIn.soreness) · Mood \(checkIn.mood)",
                    icon: "gauge.with.dots.needle.bottom.100percent",
                    accent: checkIn.category.accent
                )
            }
        }
    }

    private func historySection<Content: View>(
        title: String,
        emptyTitle: String,
        emptyText: String,
        emptyIcon: String,
        actionTitle: String? = nil,
        actionIcon: String = "arrow.right",
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title, icon: emptyIcon, accent: category.accent)

            let isEmpty = historyIsEmpty(title)
            if isEmpty {
                EmptyStateCard(
                    title: emptyTitle,
                    message: emptyText,
                    icon: emptyIcon,
                    accent: category.accent,
                    actionTitle: actionTitle,
                    actionIcon: actionIcon,
                    action: action
                )
            } else {
                VStack(spacing: 10) {
                    content()
                }
            }
        }
    }

    private func historyIsEmpty(_ title: String) -> Bool {
        switch title {
        case "Recent Workout Logs":
            return appModel.exerciseLogs.isEmpty
        case "Recent Ritual Days":
            return appModel.ritualLogs.allSatisfy { $0.completedItemIDs.isEmpty }
        default:
            return appModel.checkIns.isEmpty
        }
    }

    private func overviewMetric(_ title: String, _ value: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.title3.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }

    private func coachMetric(_ title: String, _ value: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CommandDesign.secondaryText)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(CommandDesign.tertiaryText)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }

    private func coachList(title: String, items: [String], icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(category.accent)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(category.accent)
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)
                        Text(item)
                            .font(.subheadline)
                            .foregroundStyle(CommandDesign.secondaryText)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(12)
            .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
        }
    }

    private var weeklySetCount: Int {
        weekExerciseLogs.reduce(0) { $0 + $1.setsCompleted }
    }

    private var workoutDaysThisWeek: Int {
        Set(weekExerciseLogs.map { RitualLibrary.dateKey(for: $0.date) }).count
    }

    private var workoutSessionsThisWeekCount: Int {
        appModel.workoutSessionsThisWeek().count
    }

    private func ouraSnapshotDetail(_ snapshot: OuraManualSnapshot) -> String {
        let readiness = snapshot.readinessScore.map { "Readiness \($0)" } ?? "readiness --"
        let sleepScore = snapshot.sleepScore.map { "Sleep score \($0)" } ?? "sleep score --"
        let sleep = snapshot.sleepDurationHours.map { String(format: "%.1f hr sleep", $0) } ?? "sleep --"
        let hrv = snapshot.hrv.map { String(format: "HRV %.0f", $0) } ?? "HRV --"
        let note = snapshot.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : " | notes"
        return "\(readiness) | \(sleepScore) | \(sleep) | \(hrv)\(note)"
    }

    private var ritualPercentText: String {
        guard weekRitualSummary.available > 0 else { return "0%" }
        return "\(Int((Double(weekRitualSummary.completed) / Double(weekRitualSummary.available) * 100).rounded()))%"
    }

    private var coachingSummary: String {
        if appModel.consistencyDatesThisWeek().isEmpty {
            return "Start with one check-in, one ritual item, or one logged set. The system only needs a first signal."
        }
        if appModel.consistencyDatesThisWeek().count >= 5 {
            return "The week has a real rhythm. Keep protecting consistency before chasing intensity."
        }
        return "You are building the week in small signals: check-ins, logged sets, and ritual completions."
    }

    private func readinessForDateKey(_ dateKey: String) -> ReadinessCategory? {
        appModel.readinessCategory(for: dateKey)
    }
}

private struct StreakCard: View {
    let title: String
    let days: Int
    let icon: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(accent)
            Text(days == 0 ? "No active streak" : "\(days) day\(days == 1 ? "" : "s")")
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(days == 0 ? "Start with one small signal today." : "Current streak ending today.")
                .font(.caption2)
                .foregroundStyle(.secondary.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 128, alignment: .topLeading)
        .padding(14)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }
}

private struct ProgressStatCard: View {
    let title: String
    let value: String
    let detail: String
    let icon: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(accent)
            Text(value)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary.opacity(0.9))
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 128, alignment: .topLeading)
        .padding(14)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }
}

private struct RitualDayCard: View {
    let day: RitualDaySummary
    let accent: Color

    var body: some View {
        CommandCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(day.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(day.category?.rawValue ?? "No check-in")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 8)

                    StatusPill(title: day.status.rawValue, icon: statusIcon, accent: accent)
                }

                HStack(spacing: 10) {
                    ritualMetric("\(day.completedCount)/\(day.totalCount)", "Items", "checklist")
                    ritualMetric("\(day.completionPercent)%", "Complete", "gauge.with.dots.needle.bottom.100percent")
                }

                Text(day.coachingLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                if !day.dailyWinText.isEmpty {
                    Label(day.dailyWinText, systemImage: "sparkle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(accent)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var statusIcon: String {
        switch day.status {
        case .complete:
            return "checkmark.seal"
        case .solid:
            return "checkmark.circle"
        case .partial:
            return "circle.lefthalf.filled"
        case .bareMinimum:
            return "shield"
        case .missed:
            return "arrow.clockwise"
        }
    }

    private func ritualMetric(_ value: String, _ label: String, _ icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline.weight(.bold))
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }
}

private struct RitualDayDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let day: RitualDaySummary
    let accent: Color

    var body: some View {
        NavigationStack {
            ZStack {
                CommandBackground(category: day.category ?? .normalTrainingDay)

                ScrollView {
                    VStack(alignment: .leading, spacing: CommandDesign.stackSpacing) {
                        ScreenHeader(
                            eyebrow: "Ritual Day",
                            title: day.date.formatted(date: .complete, time: .omitted),
                            subtitle: day.category?.rawValue ?? "No readiness check-in recorded for this day."
                        )

                        summaryCard

                        if day.usedBareMinimumRitual {
                            CommandCard {
                                SectionHeader(
                                    title: "Bare-Minimum Context",
                                    subtitle: "This day used the reduced ritual floor. The goal was to keep the system alive, not to force a full routine.",
                                    icon: "shield",
                                    accent: accent
                                )
                            }
                        }

                        ritualItemSection(
                            title: "Completed Items",
                            emptyTitle: "No completed items",
                            emptyMessage: "Nothing to punish here. The next day can restart with one small anchor.",
                            items: day.completedItems,
                            icon: "checkmark.circle"
                        )

                        ritualItemSection(
                            title: "Open Items",
                            emptyTitle: "Nothing left open",
                            emptyMessage: "Clean ritual day. Let that be enough.",
                            items: day.incompleteItems,
                            icon: "circle"
                        )
                    }
                    .padding(CommandDesign.pagePadding)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var summaryCard: some View {
        CommandCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    title: "Ritual Summary",
                    subtitle: day.coachingLine,
                    icon: "moon.stars",
                    accent: accent
                )

                HStack(spacing: 10) {
                    summaryMetric("\(day.completedCount)/\(day.totalCount)", "Completed", "checklist")
                    summaryMetric("\(day.completionPercent)%", "Percent", "gauge.with.dots.needle.bottom.100percent")
                    summaryMetric(day.status.rawValue, "Status", "checkmark.seal")
                }

                if !day.dailyWinText.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Daily Win")
                            .font(.caption.weight(.semibold))
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                        Text(day.dailyWinText)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(accent)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                }
            }
        }
    }

    private func summaryMetric(_ value: String, _ label: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: icon)
                .foregroundStyle(accent)
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }

    private func ritualItemSection(title: String, emptyTitle: String, emptyMessage: String, items: [RitualItem], icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title, icon: icon, accent: accent)

            if items.isEmpty {
                EmptyStateCard(title: emptyTitle, message: emptyMessage, icon: icon, accent: accent)
            } else {
                VStack(spacing: 10) {
                    ForEach(items) { item in
                        RitualHistoryItemRow(item: item, icon: icon, accent: accent)
                    }
                }
            }
        }
    }
}

private struct RitualHistoryItemRow: View {
    let item: RitualItem
    let icon: String
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                Text(item.recommendation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)
        }
        .padding(14)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }
}

private struct WorkoutSessionCard: View {
    let session: WorkoutSession
    let accent: Color

    var body: some View {
        CommandCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(session.workoutTitle)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(session.startDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 8)

                    StatusPill(
                        title: session.latestDate.formatted(date: .omitted, time: .shortened),
                        icon: "clock",
                        accent: accent
                    )
                }

                HStack(spacing: 10) {
                    sessionMetric("\(session.totalSets)", "Sets", "checklist")
                    sessionMetric("\(session.exerciseCount)", "Exercises", "figure.strengthtraining.traditional")
                }

                Text(session.topExerciseSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func sessionMetric(_ value: String, _ label: String, _ icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline.weight(.bold))
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }
}

private struct ProgressPhotoImageView: View {
    let url: URL

    var body: some View {
        if let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .accessibilityLabel("Local progress photo")
        } else {
            ZStack {
                CommandDesign.elevatedSurface
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(CommandDesign.secondaryText)
            }
            .accessibilityLabel("Missing local progress photo")
        }
    }
}

private struct WorkoutSessionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let session: WorkoutSession
    let accent: Color

    var body: some View {
        NavigationStack {
            ZStack {
                CommandBackground(category: .normalTrainingDay)

                ScrollView {
                    VStack(alignment: .leading, spacing: CommandDesign.stackSpacing) {
                        ScreenHeader(
                            eyebrow: "Workout Session",
                            title: session.workoutTitle,
                            subtitle: session.startDate.formatted(date: .complete, time: .shortened)
                        )

                        summaryCard

                        ForEach(session.exerciseGroups, id: \.name) { group in
                            SessionExerciseGroupView(
                                exerciseName: group.name,
                                logs: group.logs,
                                accent: accent
                            )
                        }
                    }
                    .padding(CommandDesign.pagePadding)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var summaryCard: some View {
        CommandCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    title: "Workout Summary",
                    subtitle: coachingLine,
                    icon: "checkmark.seal",
                    accent: accent
                )

                HStack(spacing: 10) {
                    summaryMetric("\(session.totalSets)", "Total sets", "checklist")
                    summaryMetric("\(session.exerciseCount)", "Exercises", "figure.strengthtraining.traditional")
                    summaryMetric(session.latestDate.formatted(date: .omitted, time: .shortened), "Latest", "clock")
                }
            }
        }
    }

    private var coachingLine: String {
        if session.totalSets <= 3 {
            return "Good consistency win. Next time, try to match these sets before adding more."
        }
        if session.exerciseCount >= 4 {
            return "Solid full-body touchpoint. Keep the next session clean before chasing more volume."
        }
        return "Good work logged. Match this quality next time, then build gradually."
    }

    private func summaryMetric(_ value: String, _ label: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: icon)
                .foregroundStyle(accent)
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }
}

private struct SessionExerciseGroupView: View {
    let exerciseName: String
    let logs: [ExerciseLog]
    let accent: Color

    private var totalSets: Int {
        logs.reduce(0) { $0 + $1.setsCompleted }
    }

    var body: some View {
        CommandCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exerciseName)
                            .font(.headline)
                        Text("\(totalSets) sets logged")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                ForEach(Array(logs.enumerated()), id: \.element.id) { index, log in
                    SessionSetRow(setNumber: index + 1, log: log, accent: accent)
                }
            }
        }
    }
}

private struct SessionSetRow: View {
    let setNumber: Int
    let log: ExerciseLog
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Set \(setNumber)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
                    .frame(width: 48, alignment: .leading)

                Text(weightText)
                Text("\(log.reps) reps")
                Text("RPE \(log.effort)")

                if hasNotes {
                    Image(systemName: "note.text")
                        .foregroundStyle(accent)
                        .accessibilityLabel("Notes included")
                }

                Spacer(minLength: 4)
            }
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.75)

            HStack(spacing: 8) {
                if log.setsCompleted > 1 {
                    Text("\(log.setsCompleted) sets in entry")
                }
                Text(log.date.formatted(date: .omitted, time: .shortened))
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            if hasNotes {
                Text(log.notes.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }

    private var hasNotes: Bool {
        !log.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var weightText: String {
        log.weight.map { String(format: "%.0f lb", $0) } ?? "BW"
    }
}

private struct WeeklyBarChartCard: View {
    let title: String
    let subtitle: String
    let points: [DailyChartPoint]
    let maxValue: Double?
    let unit: String
    let emptyTitle: String
    let emptyMessage: String
    let accent: Color

    var body: some View {
        CommandCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: title, subtitle: subtitle, icon: "chart.bar", accent: accent)

                if points.allSatisfy({ !$0.hasValue }) {
                    EmptyStateCard(title: emptyTitle, message: emptyMessage, icon: "chart.bar", accent: accent)
                } else {
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(points) { point in
                            VStack(spacing: 7) {
                                Text(valueText(point.value))
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)

                                GeometryReader { proxy in
                                    VStack {
                                        Spacer(minLength: 0)
                                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                                            .fill(point.hasValue ? accent.opacity(0.82) : Color.white.opacity(0.10))
                                            .frame(height: barHeight(for: point.value, in: proxy.size.height))
                                    }
                                }
                                .frame(height: 82)

                                Text(point.label)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel("\(point.label): \(point.detail)")
                        }
                    }

                    Text(summaryText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
            }
        }
    }

    private var chartMax: Double {
        max(maxValue ?? (points.map(\.value).max() ?? 1), 1)
    }

    private var summaryText: String {
        let active = points.filter(\.hasValue)
        guard !active.isEmpty else { return emptyMessage }
        let best = active.max { $0.value < $1.value }
        return best.map { "Best day: \($0.label), \($0.detail)." } ?? "Keep stacking small signals."
    }

    private func barHeight(for value: Double, in height: Double) -> Double {
        guard value > 0 else { return 6 }
        return max(6, min(height, height * value / chartMax))
    }

    private func valueText(_ value: Double) -> String {
        if unit == "%" || unit == "sets" || unit == "signals" {
            return "\(Int(value.rounded()))"
        }
        return String(format: "%.1f", value)
    }
}

private struct WeeklyDualBarChartCard: View {
    let title: String
    let subtitle: String
    let points: [DailyChartPoint]
    let primaryLabel: String
    let secondaryLabel: String
    let emptyTitle: String
    let emptyMessage: String
    let accent: Color

    var body: some View {
        CommandCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: title, subtitle: subtitle, icon: "chart.bar.xaxis", accent: accent)

                if points.isEmpty {
                    EmptyStateCard(title: emptyTitle, message: emptyMessage, icon: "fork.knife", accent: accent)
                } else {
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(points) { point in
                            VStack(spacing: 7) {
                                HStack(alignment: .bottom, spacing: 3) {
                                    bar(value: point.value, maxValue: primaryMax, color: accent)
                                    bar(value: point.secondaryValue ?? 0, maxValue: secondaryMax, color: .white.opacity(0.48))
                                }
                                .frame(height: 82)

                                Text(point.label)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel("\(point.label): \(point.detail)")
                        }
                    }

                    HStack(spacing: 10) {
                        legend(primaryLabel, accent)
                        legend(secondaryLabel, .white.opacity(0.48))
                    }

                    Text("Logged days only. \(points.last?.detail ?? "")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
            }
        }
    }

    private var primaryMax: Double {
        max(points.map(\.value).max() ?? 1, 1)
    }

    private var secondaryMax: Double {
        max(points.compactMap(\.secondaryValue).max() ?? 1, 1)
    }

    private func bar(value: Double, maxValue: Double, color: Color) -> some View {
        GeometryReader { proxy in
            VStack {
                Spacer(minLength: 0)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(value > 0 ? color : Color.white.opacity(0.10))
                    .frame(height: value > 0 ? max(6, proxy.size.height * value / maxValue) : 6)
            }
        }
        .frame(width: 9)
    }

    private func legend(_ label: String, _ color: Color) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
}

private struct ExerciseProgressCard: View {
    let summary: ExerciseProgressSummary
    let accent: Color

    var body: some View {
        CommandCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundStyle(accent)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(summary.exerciseName)
                            .font(.headline)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(summary.mostRecentDate?.formatted(date: .abbreviated, time: .omitted) ?? "No recent date")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 8)

                    StatusPill(title: "\(summary.timesLogged)x", accent: accent)
                }

                Text(summary.recentBestText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accent)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    miniMetric(summary.heaviestWeightText, "Weight")
                    miniMetric(summary.mostRepsText, "Reps")
                    miniMetric(summary.bestVolumeText, "Volume")
                }

                Text(summary.coachingLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func miniMetric(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .fixedSize(horizontal: false, vertical: true)
            Text(label)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }
}

private struct NutritionDayRow: View {
    let log: DailyNutritionLog
    var source: String = "HCC manual"
    let accent: Color

    var body: some View {
        CommandCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: log.cronometerCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(log.cronometerCompleted ? accent : .secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 7) {
                    Text(dateText)
                        .font(.headline)
                    Text(summaryText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                    if !log.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(log.notes)
                            .font(.caption)
                            .foregroundStyle(.secondary.opacity(0.9))
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 8)

                StatusPill(title: source, icon: source == "Apple Health" ? "heart.text.square" : nil, accent: accent)
            }
        }
    }

    private var dateText: String {
        if let date = dateFromKey(log.dateKey) {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
        return log.dateKey
    }

    private var summaryText: String {
        let protein = log.proteinGrams.map { "\($0)g protein" } ?? "protein not entered"
        let water = log.waterOunces.map { "\($0) oz water" } ?? "water not entered"
        let fiber = log.fiberGrams.map { "\($0)g fiber" } ?? "fiber optional"
        return "\(protein) | \(water) | \(fiber)"
    }

    private func dateFromKey(_ key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key)
    }
}

private struct BodyMetricsRow: View {
    let entry: BodyMetricsEntry
    let accent: Color

    var body: some View {
        CommandCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "scalemass")
                    .font(.title3)
                    .foregroundStyle(accent)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 7) {
                    Text(dateText)
                        .font(.headline)
                    Text(summaryText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                    if !entry.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(entry.notes)
                            .font(.caption)
                            .foregroundStyle(.secondary.opacity(0.9))
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 8)

                StatusPill(title: entry.source.rawValue, accent: accent)
            }
        }
    }

    private var dateText: String {
        if let date = dateFromKey(entry.dateKey) {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
        return entry.dateKey
    }

    private var summaryText: String {
        let weight = entry.weightPounds.map { String(format: "%.1f lb", $0) } ?? "weight --"
        let bodyFat = entry.bodyFatPercent.map { String(format: "%.1f%% body fat", $0) } ?? "body fat --"
        let muscle = entry.muscleMassPounds.map { String(format: "%.1f lb muscle", $0) } ?? "muscle --"
        let waist = entry.waistInches.map { String(format: "%.1f in waist", $0) } ?? "waist --"
        return "\(weight) | \(bodyFat) | \(muscle) | \(waist)"
    }

    private func dateFromKey(_ key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key)
    }
}

private struct RecoveryHistoryRow: View {
    let checkIn: CheckIn
    let accent: Color

    var body: some View {
        CommandCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "bed.double")
                    .font(.title3)
                    .foregroundStyle(accent)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 6) {
                    Text(checkIn.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.headline)
                    Text(checkIn.category.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(checkIn.category.accent)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)
            }
        }
    }

    private var detail: String {
        let sleep = checkIn.healthSnapshot.sleepHours.map { String(format: "%.1f hr sleep", $0) } ?? "sleep unavailable"
        return "\(sleep) | Energy \(checkIn.energy) | Stress \(checkIn.stress) | Soreness \(checkIn.soreness)"
    }
}

private struct HistoryRow: View {
    let title: String
    let subtitle: String
    let detail: String
    let icon: String
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)
        }
        .padding(14)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }
}
