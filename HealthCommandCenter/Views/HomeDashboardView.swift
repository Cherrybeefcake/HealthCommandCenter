import SwiftUI

struct HomeDashboardView: View {
    @EnvironmentObject private var appModel: AppViewModel

    var body: some View {
        TabView(selection: $appModel.selectedTab) {
            TodayDashboard()
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(AppViewModel.AppTab.today)

            PlanView()
                .tabItem { Label("Plan", systemImage: "calendar") }
                .tag(AppViewModel.AppTab.plan)

            RitualView()
                .tabItem { Label("Ritual", systemImage: "moon.stars") }
                .tag(AppViewModel.AppTab.ritual)

            ProgressDashboardView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(AppViewModel.AppTab.progress)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(AppViewModel.AppTab.profile)
        }
        .tint(appModel.activeCategory.accent)
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
                        ScreenHeader(
                            eyebrow: greeting,
                            title: appModel.hasCheckedInToday ? dailyPlan.readinessCategory.rawValue : "Start Check In",
                            subtitle: mission.coachingMessage
                        )

                        GlassPanel {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Today's Mission")
                                    .font(.caption.weight(.semibold))
                                    .textCase(.uppercase)
                                    .foregroundStyle(.secondary)

                                Text(dailyPlan.primaryFocus)
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(category.accent)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(dailyPlan.todaysMission)
                                    .font(.headline)
                                    .lineSpacing(3)
                                    .fixedSize(horizontal: false, vertical: true)

                                VStack(alignment: .leading, spacing: 10) {
                                    missionLine("Ritual", mission.ritualProgressText, "moon.stars", category.accent)
                                    if mission.totalSetsLogged > 0 {
                                        missionLine("Workout", "\(mission.totalSetsLogged) sets logged today", "checklist", category.accent)
                                    } else {
                                        missionLine("Workout", dailyPlan.workoutRecommendation, "figure.strengthtraining.traditional", category.accent)
                                    }
                                }

                                PrimaryActionButton(title: mission.nextActionTitle, icon: mission.nextActionIcon, accent: category.accent) {
                                    mission.performNextAction()
                                }
                            }
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            MissionStatusCard(title: "Plan", value: mission.planStatusValue, detail: mission.planStatusDetail, icon: "calendar", accent: category.accent)
                            MissionStatusCard(title: "Ritual", value: mission.ritualStatusValue, detail: mission.ritualStatusDetail, icon: "moon.stars", accent: category.accent)
                            MissionStatusCard(title: "Recovery", value: mission.recoveryStatus.recoveryCategory.rawValue, detail: mission.recoveryStatus.sleepDurationText, icon: "bed.double", accent: category.accent)
                            MissionStatusCard(title: "Nutrition", value: mission.nutritionStatusValue, detail: mission.nutritionStatusDetail, icon: "fork.knife", accent: category.accent)
                        }

                        SleepRecoveryHomeCard(status: mission.recoveryStatus, accent: category.accent) {
                            appModel.goToRitual()
                        }

                        GlassPanel {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(
                                    title: "Health context",
                                    subtitle: "\(appModel.healthAuthorizationSummary). Last refresh: \(appModel.lastHealthRefreshText).",
                                    icon: "heart.text.square",
                                    accent: category.accent
                                )
                                HStack(spacing: 12) {
                                    healthMini("Sleep", snapshot.sleepHours.map { String(format: "%.1f hr", $0) } ?? "No data")
                                    healthMini("Steps", snapshot.steps.map { "\($0)" } ?? "No data")
                                    healthMini("HRV", snapshot.hrvSDNN.map { String(format: "%.0f ms", $0) } ?? "No data")
                                }
                                Text("Missing values may be timing, no sample, or permissions. Sleep checks a recent window; steps and active energy can be empty just after midnight.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineSpacing(3)
                                    .fixedSize(horizontal: false, vertical: true)

                                SecondaryActionButton(
                                    title: appModel.isLoadingHealth ? "Refreshing Health Data" : "Refresh Health Data",
                                    icon: "arrow.clockwise",
                                    accent: category.accent
                                ) {
                                    Task { await appModel.refreshHealthData() }
                                }
                                .disabled(appModel.isLoadingHealth)
                            }
                        }
                    }
                    .padding(CommandDesign.pagePadding)
                }
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning, Brian" }
        if hour < 18 { return "Good afternoon, Brian" }
        return "Good evening, Brian"
    }

    private func missionLine(_ label: String, _ text: String, _ icon: String, _ accent: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(text)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func healthMini(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(title)
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
                    recoveryMetric(status.sleepQualityText, "Status")
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
    var nutritionLog: DailyNutritionLog { appModel.todayNutritionLog() }
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
        return "Open Plan"
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
        appModel.nutritionDetailLine(for: nutritionLog)
    }

    var nutritionStatusValue: String {
        appModel.nutritionStatusLine(for: nutritionLog)
    }
}
