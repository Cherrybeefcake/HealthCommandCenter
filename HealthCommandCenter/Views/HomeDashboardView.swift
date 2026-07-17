import SwiftUI

struct HomeDashboardView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        .animation(CommandMotion.standard(reduceMotion), value: appModel.selectedTab)
    }
}

private struct TodayDashboard: View {
    @EnvironmentObject private var appModel: AppViewModel

    var body: some View {
        let category = appModel.activeCategory
        let snapshot = appModel.latestCheckIn?.healthSnapshot ?? appModel.todaySnapshot
        let mission = TodayMission(appModel: appModel)

        NavigationStack {
            ZStack {
                CommandBackground(category: category)

                ScrollView {
                    VStack(alignment: .leading, spacing: CommandDesign.stackSpacing) {
                        briefHeader

                        MorningBriefHero(
                            greeting: greeting,
                            phaseLine: phaseBriefLine,
                            dateText: Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()),
                            mission: mission,
                            snapshot: snapshot,
                            accent: category.accent
                        )

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

                            CommandFeedbackPill(message: mission.goalFocusText, icon: "target", accent: category.accent)
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
                                .accessibilityLabel(AppStrings.Action.refreshHealthData)
                                .accessibilityHint("Reads available Apple Health data without writing to Apple Health.")

                                if appModel.isLoadingHealth {
                                    CommandFeedbackPill(message: "Refreshing Apple Health", icon: "arrow.clockwise", accent: category.accent)
                                } else if appModel.lastHealthRefreshAt != nil || appModel.healthStatusMessage != "HealthKit not requested yet" {
                                    CommandFeedbackPill(message: appModel.healthStatusMessage, icon: snapshot.hasAnyData ? "checkmark.circle.fill" : "info.circle", accent: category.accent)
                                }
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

    private var briefHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            CommandBrandMark(accent: appModel.activeCategory.accent, size: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text("TODAY")
                    .font(.caption.weight(.semibold))
                    .tracking(0.6)
                    .foregroundStyle(CommandDesign.secondaryText)
                Text("Morning Brief")
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
            .accessibilityLabel(AppStrings.Accessibility.openProfile)
        }
    }

    private var phaseBriefLine: String {
        switch appModel.programPhase {
        case .nightShift:
            return "Night Shift: protect the sleep window and keep training near the front of the shift when possible."
        case .dayShift:
            return "Day Shift: use the stable rhythm. Train early or after work, then shut it down cleanly."
        case .newBaby:
            return "New-Baby: flexible timing, tiny floor, no heroics. Consistency beats pressure."
        case .normalRoutine:
            return "Normal Routine: balanced progression, recovery protected, next action first."
        }
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

private struct MorningBriefHero: View {
    let greeting: String
    let phaseLine: String
    let dateText: String
    let mission: TodayMission
    let snapshot: HealthSnapshot
    let accent: Color

    var body: some View {
        HeroCard(accent: accent) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(greeting)
                            .font(.caption.weight(.semibold))
                            .tracking(0.6)
                            .foregroundStyle(CommandDesign.secondaryText)
                        Text(dateText)
                            .font(.title3.weight(.bold))
                    }
                    Spacer()
                    StatusPill(title: mission.briefCallTitle, icon: mission.briefCallIcon, accent: accent)
                }

                Text(mission.primaryMissionTitle)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 10) {
                    briefRow("Today’s call", mission.todaysCallText, "gauge.with.dots.needle.bottom.100percent")
                    briefRow("Primary mission", mission.primaryMissionDetail, "scope")
                    briefRow("Main watchout", mission.mainWatchout, "exclamationmark.triangle")
                    briefRow("Health context", mission.supportingHealthContext(snapshot: snapshot), "heart.text.square")
                }

                Text(phaseLine)
                    .font(.caption)
                    .foregroundStyle(CommandDesign.secondaryText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))

                PrimaryActionButton(title: mission.nextActionTitle, icon: mission.nextActionIcon, accent: accent) {
                    mission.performNextAction()
                }
            }
        }
    }

    private func briefRow(_ title: String, _ value: String, _ icon: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(CommandDesign.tertiaryText)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
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
    var goals: [GoalProgress] { appModel.currentGoalProgress() }
    var plannedSession: PlannedSession? { appModel.todaysPlannedSession() }
    var totalSetsLogged: Int { todayLogs.reduce(0) { $0 + $1.setsCompleted } }
    var hasWorkoutProgress: Bool { !todayLogs.isEmpty }
    var hasRitualProgress: Bool { ritualCompleted > 0 }
    var isRecoveryBiased: Bool { category == .recoveryDay || category == .bareMinimumDay }

    var briefCallTitle: String {
        appModel.hasCheckedInToday ? category.rawValue : "Check-in needed"
    }

    var briefCallIcon: String {
        appModel.hasCheckedInToday ? "bolt.heart.fill" : "waveform.path.ecg"
    }

    var primaryMissionTitle: String {
        if !appModel.hasCheckedInToday { return "Classify the day before choosing intensity." }
        return appModel.coachRecommendation(.primaryMission)?.message ?? dailyPlan.primaryFocus
    }

    var todaysCallText: String {
        if !appModel.hasCheckedInToday {
            if hasWorkoutProgress || hasRitualProgress {
                return "No readiness category yet. Today’s progress counts, but training guidance waits for Check In."
            }
            return "No readiness category yet. Start Check In so the plan does not guess."
        }
        return "\(category.rawValue): \(dailyPlan.recommendedAction)"
    }

    var primaryMissionDetail: String {
        if !appModel.hasCheckedInToday {
            return "Start Check In, then Today will route you to Train or Recovery."
        }
        return dailyPlan.todaysMission
    }

    var mainWatchout: String {
        if !appModel.hasCheckedInToday {
            return "Do not treat the day as a training day until Brian classifies readiness."
        }
        if let coachWatchout = appModel.coachRecommendation(.watchout)?.message {
            return coachWatchout
        }
        if let subjectiveOverride = recoveryStatus.subjectiveOverrideText {
            return subjectiveOverride
        }
        switch recoveryStatus.recoveryCategory {
        case .poor:
            return "Recovery is poor. Keep the floor low and protect sleep before adding load."
        case .limited:
            return "Recovery is limited. Shorten the session or bias toward mobility."
        case .unknown:
            return "Recovery data is incomplete. Use the Check In and basic guardrails."
        case .strong:
            return category == .pushDay ? "Push intelligently. Extra work only if reps stay clean." : "Do not overreach just because the signals look good."
        case .okay:
            return "Keep the plan clean. Finish with energy left for tomorrow."
        }
    }

    func supportingHealthContext(snapshot: HealthSnapshot) -> String {
        let sleep = recoveryStatus.sleepDurationText
        let source = recoveryStatus.sleepSourceText
        let steps = snapshot.steps.map { "\($0) steps" } ?? "steps unavailable"
        let hrv = snapshot.hrvSDNN.map { String(format: "HRV %.0f ms", $0) } ?? "HRV unavailable"
        if !appModel.hasCheckedInToday {
            return "\(source): \(sleep). \(steps), \(hrv). Apple Health can support the call, but Check In owns readiness."
        }
        return "\(source): \(sleep). \(steps), \(hrv). Oura stays supplemental unless explicitly selected."
    }

    var coachingMessage: String {
        if !appModel.hasCheckedInToday {
            return "Start with the check-in. The dashboard gets sharper once the day is classified."
        }
        return appModel.coachRecommendation(.todayBriefing)?.message ?? dailyPlan.recommendedAction
    }

    var focus: String {
        if !appModel.hasCheckedInToday {
            return "Classify the day first"
        }
        if isRecoveryBiased {
            return category == .recoveryDay ? "Recovery, mobility, and sleep protection" : "Minimum viable day"
        }
        return appModel.coachRecommendation(.workout)?.message ?? dailyPlan.workoutRecommendation
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

    var goalFocusText: String {
        if let goal = goals.first(where: { $0.status == .building || $0.status == .noData }) {
            return "Goal focus: \(goal.title). \(goal.coachingLine)"
        }
        return "Goal focus: keep the rhythm steady. Progress slowly and protect recovery."
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
        if let plannedSession {
            return plannedSession.recommendedVersion.rawValue
        }
        return StarterWorkoutLibrary.recommendedVersion(for: category).rawValue
    }

    var planStatusDetail: String {
        if totalSetsLogged > 0 {
            let exercises = Set(todayLogs.map(\.exerciseID)).count
            return "\(exercises) exercises touched today."
        }
        if let plannedSession {
            return "\(plannedSession.workoutTitle): \(plannedSession.note)"
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
        appModel.coachRecommendation(.nutrition)?.message ?? "\(nutritionDisplay.source): \(nutritionDisplay.detail)"
    }

    var nutritionStatusValue: String {
        appModel.nutritionStatusLine(for: nutritionDisplay.log)
    }
}
