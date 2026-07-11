import SwiftUI

struct HomeDashboardView: View {
    @EnvironmentObject private var appModel: AppViewModel

    var body: some View {
        TabView(selection: $appModel.selectedTab) {
            TodayDashboard()
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(AppViewModel.AppTab.today)

            PlanView()
                .tabItem { Label("Train", systemImage: "dumbbell.fill") }
                .tag(AppViewModel.AppTab.plan)

            RitualView()
                .tabItem { Label("Recovery", systemImage: "figure.mind.and.body") }
                .tag(AppViewModel.AppTab.ritual)

            ProgressDashboardView()
                .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }
                .tag(AppViewModel.AppTab.progress)

            ProfileView()
                .tabItem { Label("You", systemImage: "person.crop.circle.fill") }
                .tag(AppViewModel.AppTab.profile)
        }
        .tint(CommandPalette.brand)
    }
}

private struct TodayDashboard: View {
    @EnvironmentObject private var appModel: AppViewModel

    var body: some View {
        let category = appModel.activeCategory
        let snapshot = appModel.latestCheckIn?.healthSnapshot ?? appModel.todaySnapshot
        let mission = TodayMission(appModel: appModel)
        let dailyPlan = appModel.todayDailyPlan

        NavigationStack {
            ZStack {
                CommandBackground(category: category)

                ScrollView {
                    VStack(alignment: .leading, spacing: CommandDesign.stackSpacing) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(greeting)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(CommandDesign.secondaryText)
                                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                                    .font(.title2.weight(.bold))
                            }
                            Spacer()
                            Button {
                                appModel.selectedTab = .profile
                            } label: {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white.opacity(0.82))
                                    .frame(width: 44, height: 44)
                                    .background(CommandDesign.elevatedSurface, in: Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Open profile")
                        }

                        HeroCard(accent: category.accent) {
                            VStack(alignment: .leading, spacing: 18) {
                                StatusPill(
                                    title: appModel.hasCheckedInToday ? dailyPlan.readinessCategory.rawValue : "CHECK-IN NEEDED",
                                    icon: appModel.hasCheckedInToday ? "bolt.heart.fill" : "waveform.path.ecg",
                                    accent: category.accent
                                )

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(appModel.hasCheckedInToday ? dailyPlan.primaryFocus : "Build the right plan for today.")
                                        .font(.system(size: 30, weight: .bold, design: .rounded))
                                        .lineSpacing(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(mission.coachingMessage)
                                        .font(.body)
                                        .foregroundStyle(CommandDesign.secondaryText)
                                        .lineSpacing(4)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                if appModel.hasCheckedInToday {
                                    HStack(alignment: .top, spacing: 11) {
                                        Image(systemName: "scope")
                                            .foregroundStyle(category.accent)
                                        Text(dailyPlan.todaysMission)
                                            .font(.subheadline.weight(.semibold))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }

                                PrimaryActionButton(title: mission.nextActionTitle, icon: mission.nextActionIcon, accent: category.accent) {
                                    mission.performNextAction()
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(
                                title: "Today at a glance",
                                subtitle: "Four signals. One next action.",
                                icon: "square.grid.2x2",
                                accent: category.accent
                            )

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                MissionStatusCard(title: "Training", value: mission.planStatusValue, detail: mission.planStatusDetail, icon: "dumbbell", accent: category.accent)
                                MissionStatusCard(title: "Recovery", value: mission.recoveryStatus.sleepDurationText, detail: mission.recoveryStatus.trainingAdjustmentText, icon: "bed.double.fill", accent: category.accent)
                                MissionStatusCard(title: "Nutrition", value: mission.nutritionStatusValue, detail: mission.nutritionStatusDetail, icon: "fork.knife", accent: category.accent)
                                MissionStatusCard(title: "Daily essentials", value: mission.ritualStatusValue, detail: mission.ritualStatusDetail, icon: "checkmark.circle", accent: category.accent)
                            }
                        }

                        CommandCard {
                            VStack(alignment: .leading, spacing: 15) {
                                SectionHeader(
                                    title: "Health context",
                                    subtitle: "Supporting evidence, not the final authority.",
                                    icon: "heart.text.square.fill",
                                    accent: category.accent
                                )
                                HStack(spacing: 10) {
                                    healthMini("Sleep", snapshot.sleepHours.map { String(format: "%.1f hr", $0) } ?? "—")
                                    healthMini("Steps", snapshot.steps.map { "\($0)" } ?? "—")
                                    healthMini("HRV", snapshot.hrvSDNN.map { String(format: "%.0f ms", $0) } ?? "—")
                                }
                                HStack {
                                    Text(appModel.healthAuthorizationSummary)
                                        .font(.caption)
                                        .foregroundStyle(CommandDesign.secondaryText)
                                    Spacer()
                                    Text(appModel.lastHealthRefreshText)
                                        .font(.caption2)
                                        .foregroundStyle(CommandDesign.secondaryText)
                                }
                                Button {
                                    Task { await appModel.refreshHealthData() }
                                } label: {
                                    Label(appModel.isLoadingHealth ? "Refreshing" : "Refresh health data", systemImage: "arrow.clockwise")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(category.accent)
                                }
                                .buttonStyle(.plain)
                                .disabled(appModel.isLoadingHealth)
                            }
                        }

                        SleepRecoveryHomeCard(status: mission.recoveryStatus, accent: category.accent) {
                            appModel.goToRitual()
                        }

                        BodyMetricsHomeCard(summary: appModel.latestBodyMetricsSummary(), accent: category.accent) {
                            appModel.selectedTab = .profile
                        }
                    }
                    .padding(CommandDesign.pagePadding)
                    .padding(.bottom, 14)
                }
                .refreshable { await appModel.refreshHealthData() }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "GOOD MORNING, BRIAN" }
        if hour < 18 { return "GOOD AFTERNOON, BRIAN" }
        return "GOOD EVENING, BRIAN"
    }

    private func healthMini(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CommandDesign.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }
}

private struct BodyMetricsHomeCard: View {
    let summary: BodyMetricsSummary
    let accent: Color
    let action: () -> Void

    var body: some View {
        CommandCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    title: "Body Metrics",
                    subtitle: "Trend data for recomposition, not a daily judgment.",
                    icon: "scalemass",
                    accent: accent
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    recoveryMetric(summary.latestWeightText, "Latest weight")
                    recoveryMetric(summary.sourceText, "Source")
                }

                Text(summary.trendText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                if summary.latestEntry == nil, summary.appleHealthWeightPounds != nil {
                    Text("Apple Health weight is shown as context only. It is not copied into local body metrics unless Brian saves a manual entry.")
                        .font(.caption2)
                        .foregroundStyle(.secondary.opacity(0.9))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                SecondaryActionButton(title: "Log Body Metrics", icon: "square.and.pencil", accent: accent, action: action)
            }
        }
    }

    private func recoveryMetric(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }
}

private struct SleepRecoveryHomeCard: View {
    let status: RecoveryStatus
    let accent: Color
    let action: () -> Void

    var body: some View {
        CommandCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    title: "Sleep & Recovery",
                    subtitle: status.coachingLine,
                    icon: "bed.double",
                    accent: accent
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    recoveryMetric(status.sleepDurationText, "Sleep")
                    recoveryMetric(status.sleepSourceText, "Source")
                    recoveryMetric(status.sleepQualityText, "Status")
                }

                Text(status.sleepDetailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text(status.supportingContextText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                if let subjectiveOverrideText = status.subjectiveOverrideText {
                    Text(subjectiveOverrideText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(accent)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(status.trainingAdjustmentText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(accent)
                    .fixedSize(horizontal: false, vertical: true)

                Text(status.caffeineGuidance)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                SecondaryActionButton(title: "Open Sleep Prep", icon: "moon.zzz", accent: accent, action: action)
            }
        }
    }

    private func recoveryMetric(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }
}

private struct MissionStatusCard: View {
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
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 136, alignment: .topLeading)
        .padding(14)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }
}

@MainActor
private struct TodayMission {
    let appModel: AppViewModel

    var category: ReadinessCategory { appModel.activeCategory }
    var ritualItems: [RitualItem] { appModel.todayRitualItems() }
    var ritualCompleted: Int { appModel.todayRitualCompletedCount() }
    var ritualTotal: Int { ritualItems.count }
    var nutritionDisplay: (log: DailyNutritionLog, source: String, detail: String) { appModel.todayNutritionDisplay() }
    var recoveryStatus: RecoveryStatus { appModel.todayRecoveryStatus() }
    var todayLogs: [ExerciseLog] { appModel.todayExerciseLogs() }
    var dailyPlan: DailyPlan { appModel.todayDailyPlan }
    var totalSetsLogged: Int { todayLogs.reduce(0) { $0 + $1.setsCompleted } }
    var hasWorkoutProgress: Bool { !todayLogs.isEmpty }
    var hasRitualProgress: Bool { ritualCompleted > 0 }
    var isRecoveryBiased: Bool { category == .recoveryDay || category == .bareMinimumDay }

    var coachingMessage: String {
        if !appModel.hasCheckedInToday {
            return "Start with the check-in. The dashboard gets sharper once the day is classified."
        }
        return dailyPlan.recommendedAction
    }

    var focus: String {
        if !appModel.hasCheckedInToday {
            return "Classify the day first"
        }
        if isRecoveryBiased {
            return category == .recoveryDay ? "Recovery, mobility, and sleep protection" : "Minimum viable day"
        }
        return dailyPlan.workoutRecommendation
    }

    var workoutRecommendation: String {
        let version = StarterWorkoutLibrary.recommendedVersion(for: category)
        switch version {
        case .full:
            return category == .pushDay ? "Full-body strength. Push intelligently." : "Full-body strength. Clean reps."
        case .short:
            return "Short strength session. Leave fresh."
        case .bareMinimum:
            return "Bare-minimum movement dose."
        case .recovery:
            return "Walk, mobility, and breathing."
        }
    }

    var ritualProgressText: String {
        ritualCompleted == 0 ? "No ritual items complete yet" : "\(ritualCompleted) of \(ritualTotal) ritual items complete"
    }

    var nextActionTitle: String {
        if !appModel.hasCheckedInToday { return "Start Check In" }
        if hasRitualProgress && ritualCompleted < ritualTotal { return "Continue Ritual" }
        if isRecoveryBiased { return "Open Ritual" }
        return "Open Workouts"
    }

    var nextActionIcon: String {
        if !appModel.hasCheckedInToday { return "slider.horizontal.3" }
        if hasRitualProgress || isRecoveryBiased { return "moon.stars" }
        return "calendar"
    }

    func performNextAction() {
        if !appModel.hasCheckedInToday {
            appModel.startNewCheckIn()
        } else if hasRitualProgress && ritualCompleted < ritualTotal {
            appModel.goToRitual()
        } else if isRecoveryBiased {
            appModel.goToRitual()
        } else {
            appModel.goToPlan()
        }
    }

    var planStatusValue: String {
        if !appModel.hasCheckedInToday {
            return totalSetsLogged > 0 ? "\(totalSetsLogged) sets logged" : "Start Check In"
        }
        if totalSetsLogged > 0 {
            return "\(totalSetsLogged) sets logged"
        }
        return StarterWorkoutLibrary.recommendedVersion(for: category).rawValue
    }

    var planStatusDetail: String {
        if totalSetsLogged > 0 {
            let exercises = Set(todayLogs.map(\.exerciseID)).count
            return "\(exercises) exercises touched today."
        }
        return dailyPlan.workoutRecommendation
    }

    var ritualStatusValue: String {
        if !appModel.hasCheckedInToday && ritualCompleted == 0 {
            return "Start Check In"
        }
        return "\(ritualCompleted)/\(ritualTotal) complete"
    }

    var ritualStatusDetail: String {
        if !appModel.hasCheckedInToday {
            return ritualCompleted > 0
                ? "\(ritualCompleted) ritual items already complete. Check in before choosing the rest of the day."
                : dailyPlan.ritualRecommendation
        }
        if ritualCompleted == 0 { return "No ritual items checked off yet." }
        if ritualCompleted == ritualTotal { return "Daily ritual complete." }
        return dailyPlan.ritualRecommendation
    }

    func recoveryStatusDetail(snapshot: HealthSnapshot) -> String {
        if isRecoveryBiased {
            return "Prioritize mobility, caffeine cutoff, and a clean sleep routine."
        }
        if snapshot.sleepHours == nil {
            return "Sleep data missing. Use caffeine cutoff and evening routine as the guardrails."
        }
        return "Keep mobility light and protect tonight's sleep window."
    }

    var nutritionStatusDetail: String {
        "\(nutritionDisplay.source): \(nutritionDisplay.detail)"
    }

    var nutritionStatusValue: String {
        appModel.nutritionStatusLine(for: nutritionDisplay.log)
    }
}
