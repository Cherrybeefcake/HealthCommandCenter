import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var resetAction: ResetAction?
    @State private var ouraReadinessScore = ""
    @State private var ouraSleepScore = ""
    @State private var ouraSleepDuration = ""
    @State private var ouraHRV = ""
    @State private var ouraRestingHeartRate = ""
    @State private var ouraBodyTemperatureTrend = ""
    @State private var ouraNotes = ""
    @State private var bodyWeight = ""
    @State private var bodyFatPercent = ""
    @State private var muscleMass = ""
    @State private var visceralFat = ""
    @State private var waist = ""
    @State private var bodyMetricsNotes = ""
    @State private var bodyMetricsSource: BodyMetricsSource = .manual
    @State private var profileFeedback: String?

    var body: some View {
        ZStack {
            CommandBackground(category: appModel.activeCategory)

            ScrollView {
                VStack(alignment: .leading, spacing: CommandDesign.stackSpacing) {
                    ScreenHeader(
                        eyebrow: "YOU",
                        title: appModel.userName,
                        subtitle: "Personalization, sources, reminders, storage, and reset controls."
                    )

                    profileSummary
                    if let profileFeedback {
                        CommandFeedbackPill(message: profileFeedback, accent: appModel.activeCategory.accent)
                    }
                    profileGroupHeader("Personalization", "Brian’s phase, training preferences, and nutrition anchors.", "person.crop.circle")
                    programPhaseSection
                    trainingPreferencesSection
                    nutritionPreferencesSection
                    profileGroupHeader("Data Sources", "Apple Health is primary where available; Oura stays supplemental until OAuth exists.", "externaldrive.connected.to.line.below")
                    healthKitStatusSection
                    ouraFoundationSection
                    profileGroupHeader("Notifications", "Optional local reminders only. No push service, no account.", "bell.badge")
                    remindersSection
                    profileGroupHeader("Body Metrics", "Trend context for recomposition, not daily judgment.", "scalemass")
                    bodyMetricsSection
                    profileGroupHeader("Storage & Reset", "Local files, debug context, and confirmed destructive actions.", "lock.doc")
                    dataStorageSection
                    resetControlsSection
                    profileGroupHeader("About", "Current MVP scope and integration direction.", "info.circle")
                    aboutSection
                }
                .padding(CommandDesign.pagePadding)
            }
            .commandKeyboardDismissal()
        }
        .alert(item: $resetAction) { action in
            let confirmButton: Alert.Button = action.isDestructive
                ? .destructive(Text(action.confirmTitle)) { perform(action) }
                : .default(Text(action.confirmTitle)) { perform(action) }
            return Alert(
                title: Text(action.title),
                message: Text(action.message),
                primaryButton: confirmButton,
                secondaryButton: .cancel()
            )
        }
        .task {
            await appModel.refreshNotificationStatus()
        }
    }

    private var profileSummary: some View {
        HeroCard(accent: appModel.activeCategory.accent) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(appModel.programPhase.rawValue)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(appModel.activeCategory.accent)
                        Text("Current phase")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CommandDesign.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "person.crop.circle")
                        .font(.largeTitle)
                        .foregroundStyle(appModel.activeCategory.accent)
                }

                Text("\(appModel.personalizationSettings.baselineText) | body composition as trend data")
                    .font(.headline)

                Text("Private, local-first command center for rebuilding consistency around real life constraints.")
                    .font(.subheadline)
                    .foregroundStyle(CommandDesign.secondaryText)
                    .lineSpacing(3)
            }
        }
    }

    private func profileGroupHeader(_ title: String, _ subtitle: String, _ icon: String) -> some View {
        SectionHeader(title: title, subtitle: subtitle, icon: icon, accent: appModel.activeCategory.accent)
            .padding(.top, 4)
    }

    private var programPhaseSection: some View {
        settingsSection("Program Phase", icon: "moonphase.first.quarter") {
            Picker("Program phase", selection: Binding(
                get: { appModel.programPhase },
                set: { appModel.setProgramPhase($0) }
            )) {
                ForEach(ProgramPhase.allCases) { phase in
                    Text(phase.rawValue).tag(phase)
                }
            }
            .pickerStyle(.menu)
            .tint(appModel.activeCategory.accent)

            Text("Manual for now. This lets the app shape language and expectations around shift work, baby season, or a normal routine.")
                .font(.caption)
                .foregroundStyle(CommandDesign.secondaryText)
                .lineSpacing(3)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "bed.double")
                    .foregroundStyle(appModel.activeCategory.accent)
                Text(recoveryCopy(for: appModel.programPhase))
                    .font(.caption)
                    .foregroundStyle(CommandDesign.secondaryText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
        }
    }

    private var healthKitStatusSection: some View {
        settingsSection("HealthKit", icon: "heart.text.square") {
            Text("Best-effort real-device status. Sleep uses Apple Health latest sleep when available; any wider lookup shown below is only used to find Apple sleep samples. Steps and active energy may be zero or empty just after midnight.")
                .font(.caption)
                .foregroundStyle(CommandDesign.secondaryText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                storageMetric("Availability", appModel.healthAvailabilityText)
                storageMetric("Permission", appModel.healthAuthorizationSummary)
                storageMetric("Last refresh", appModel.lastHealthRefreshText)
                storageMetric("Values returned", "\(appModel.todaySnapshot.availableMetricCount)")
            }

            SecondaryActionButton(
                title: appModel.isLoadingHealth ? "Refreshing Health Data" : "Refresh Health Data",
                icon: "arrow.clockwise",
                accent: appModel.activeCategory.accent
            ) {
                Task {
                    await appModel.refreshHealthData()
                    showProfileFeedback(appModel.healthStatusMessage)
                }
            }
            .disabled(appModel.isLoadingHealth)
            .accessibilityLabel("Refresh health data")

            if appModel.isLoadingHealth {
                CommandFeedbackPill(message: "Refreshing Apple Health", icon: "arrow.clockwise", accent: appModel.activeCategory.accent)
            } else if appModel.lastHealthRefreshAt != nil || appModel.healthStatusMessage != "HealthKit not requested yet" {
                CommandFeedbackPill(message: appModel.healthStatusMessage, icon: appModel.todaySnapshot.hasAnyData ? "checkmark.circle.fill" : "info.circle", accent: appModel.activeCategory.accent)
            }

            DisclosureGroup {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(healthMetricGroups.enumerated()), id: \.offset) { _, group in
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: group.title, icon: group.icon, accent: appModel.activeCategory.accent)
                            ForEach(group.items) { item in
                                statusRow(item)
                            }
                        }
                    }
                }
                .padding(.top, 10)
            } label: {
                Label("Detailed HealthKit coverage", systemImage: "waveform.path.ecg")
                    .font(.headline)
            }
            .tint(appModel.activeCategory.accent)
        }
    }

    private var healthMetricGroups: [(title: String, icon: String, items: [DeviceStatusItem])] {
        let items = appModel.healthMetricStatusItems()
        let activityIDs: Set<String> = ["steps", "active-energy", "workouts", "exercise-minutes", "stand-minutes", "flights", "distance"]
        let recoveryIDs: Set<String> = ["sleep", "resting-hr", "hrv", "heart-rate", "respiratory-rate", "blood-oxygen", "body-temperature"]
        let bodyIDs: Set<String> = ["weight", "body-fat", "lean-body-mass", "waist"]
        let nutritionIDs = Set(items.map(\.id).filter { $0.hasPrefix("nutrition-") })
        return [
            ("Activity", "figure.walk", items.filter { activityIDs.contains($0.id) }),
            ("Recovery / Vitals", "waveform.path.ecg", items.filter { recoveryIDs.contains($0.id) }),
            ("Body", "scalemass", items.filter { bodyIDs.contains($0.id) }),
            ("Nutrition", "fork.knife", items.filter { nutritionIDs.contains($0.id) })
        ].filter { !$0.items.isEmpty }
    }

    private var ouraFoundationSection: some View {
        settingsSection("Oura", icon: "ring") {
            Text("Oura OAuth is not connected yet. Automatic uses Apple Health as the primary source for overlapping metrics and Oura as supplemental recovery context. Manual/mock mode helps test that behavior without storing real tokens.")
                .font(.caption)
                .foregroundStyle(CommandDesign.secondaryText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Toggle("Enable Oura foundation", isOn: ouraEnabledBinding)
                .font(.headline)
                .tint(appModel.activeCategory.accent)

            preferencePicker("Mode", value: ouraModeBinding, cases: OuraConnectionMode.allCases)
            preferencePicker("Recovery source", value: recoverySourceBinding, cases: RecoveryDataSource.allCases)

            if !appModel.ouraConnectionSettings.isEnabled {
                CommandFeedbackPill(message: "Oura is not connected. Apple Health remains primary.", icon: "info.circle", accent: appModel.activeCategory.accent)
            }

            let latest = appModel.latestOuraManualSnapshot()
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                storageMetric("Status", appModel.ouraConnectionSettings.connectionMode.rawValue)
                storageMetric("Snapshots", "\(appModel.ouraManualSnapshots.count)")
                storageMetric("Readiness", latest?.readinessScore.map(String.init) ?? "--")
                storageMetric("Sleep", latest?.sleepDurationHours.map { String(format: "%.1f hr", $0) } ?? "--")
            }

            DisclosureGroup {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Save a local test snapshot for today. Cronometer-style precision is not needed; this is only for testing source behavior.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)

                    manualOuraField("Readiness score", text: $ouraReadinessScore, placeholder: "0-100")
                    manualOuraField("Sleep score", text: $ouraSleepScore, placeholder: "0-100")
                    manualOuraField("Sleep duration", text: $ouraSleepDuration, placeholder: "hours")
                    manualOuraField("HRV", text: $ouraHRV, placeholder: "ms")
                    manualOuraField("Resting HR", text: $ouraRestingHeartRate, placeholder: "bpm")

                    styledProfileField("Body temperature trend", text: $ouraBodyTemperatureTrend)
                    styledProfileField("Notes", text: $ouraNotes, axis: .vertical)
                        .lineLimit(2...4)

                    PrimaryActionButton(title: "Save Oura Test Snapshot", icon: "square.and.arrow.down", accent: appModel.activeCategory.accent) {
                        saveOuraSnapshot()
                    }
                }
                .padding(.top, 10)
            } label: {
                Label("Manual/mock Oura entry", systemImage: "square.and.pencil")
                    .font(.headline)
            }
            .tint(appModel.activeCategory.accent)

            if let latest {
                Text("Latest Oura test data updated \(latest.updatedAt.formatted(date: .abbreviated, time: .shortened)).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var persistenceStatusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Close and reopen the app after testing. These local counts should still make sense after relaunch.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                storageMetric("Check-ins", "\(appModel.checkIns.count)")
                storageMetric("Workout logs", "\(appModel.exerciseLogs.count)")
                storageMetric("Ritual days", "\(appModel.ritualLogs.count)")
                storageMetric("Nutrition", "\(appModel.nutritionLogs.count)")
                storageMetric("Oura tests", "\(appModel.ouraManualSnapshots.count)")
                storageMetric("Body metrics", "\(appModel.bodyMetricsEntries.count)")
                storageMetric("Custom workouts", "\(appModel.customWorkouts.count)")
                storageMetric("Reminders", appModel.reminderSettings.remindersEnabled ? "Enabled" : "Disabled")
                storageMetric("Scheduled", "\(appModel.scheduledReminderCount)")
            }
        }
    }

    private var trainingPreferencesSection: some View {
        settingsSection("Training Preferences", icon: "figure.strengthtraining.traditional") {
            preferencePicker("Location", value: Binding(
                get: { appModel.trainingLocation },
                set: { appModel.setTrainingLocation($0) }
            ), cases: TrainingLocation.allCases)

            preferencePicker("Workout time", value: Binding(
                get: { appModel.workoutTimePreference },
                set: { appModel.setWorkoutTimePreference($0) }
            ), cases: WorkoutTimePreference.allCases)

            Divider()
                .overlay(.white.opacity(0.16))

            VStack(alignment: .leading, spacing: 8) {
                Text("Equipment")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                Text("Adjustable dumbbells 5-55 lb, resistance bands, incline bench, mat, and work gym access.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                StatusPill(
                    title: appModel.personalizationSettings.equipmentConfirmed ? "Confirmed in onboarding" : "Needs confirmation",
                    accent: appModel.activeCategory.accent
                )
            }
        }
    }

    private var remindersSection: some View {
        settingsSection("Reminders", icon: "bell.badge") {
            Text("Optional local reminders. Turn them on only if they help Brian start the next right action without noise.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)

            Toggle("Enable reminders", isOn: reminderToggleBinding(\.remindersEnabled))
                .font(.headline)
                .tint(appModel.activeCategory.accent)

            if !appModel.reminderSettings.remindersEnabled {
                CommandFeedbackPill(message: "Reminders are off. Nothing schedules until Brian enables them.", icon: "bell.slash", accent: appModel.activeCategory.accent)
            }

            Divider()
                .overlay(.white.opacity(0.16))

            reminderRow(
                title: "Daily Check In",
                subtitle: "Start with the data. Classify today.",
                icon: "checkmark.seal",
                enabledKeyPath: \.checkInReminderEnabled,
                timeKeyPath: \.checkInReminderTime
            )

            reminderRow(
                title: "Ritual",
                subtitle: "Keep the floor low. Finish today's ritual.",
                icon: "sparkles",
                enabledKeyPath: \.ritualReminderEnabled,
                timeKeyPath: \.ritualReminderTime
            )

            reminderRow(
                title: "Sleep Wind-Down",
                subtitle: "Start the wind-down. Protect tomorrow.",
                icon: "bed.double",
                enabledKeyPath: \.sleepReminderEnabled,
                timeKeyPath: \.sleepReminderTime
            )

            reminderRow(
                title: "Nutrition / Cronometer",
                subtitle: "Log Cronometer and hit the anchors.",
                icon: "fork.knife",
                enabledKeyPath: \.nutritionReminderEnabled,
                timeKeyPath: \.nutritionReminderTime
            )

            HStack(spacing: 10) {
                StatusPill(title: "Permission: \(appModel.notificationPermissionStatus)", accent: appModel.activeCategory.accent)
                StatusPill(title: "\(appModel.pendingHealthCommandNotificationCount) pending", accent: appModel.activeCategory.accent)
            }

            if appModel.notificationPermissionStatus == "Denied" {
                Text("Notifications are denied in iOS Settings. Open Settings > Notifications > Health Command Center and allow notifications, then return here and test again.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }

            VStack(alignment: .leading, spacing: 6) {
                preferenceRow("Daily reminders", "\(appModel.scheduledReminderCount)")
                preferenceRow("Test reminder pending", appModel.isTestReminderPending ? "Yes" : "No")
                preferenceRow("Last test scheduled", appModel.lastTestReminderScheduledAt?.formatted(date: .abbreviated, time: .shortened) ?? "Not yet")
            }
            .padding(10)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))

            SecondaryActionButton(
                title: "Schedule Test Reminder in 10 Seconds",
                icon: "bell.and.waves.left.and.right",
                accent: appModel.activeCategory.accent
            ) {
                Task {
                    await appModel.scheduleTestReminder()
                    showProfileFeedback(appModel.reminderTestStatus)
                }
            }
            .accessibilityLabel("Schedule test reminder")

            Text(appModel.reminderTestStatus)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Text("For the test alert, lock the phone or leave the app if you do not see a banner while the app is open. Focus or Silent mode can suppress alert presentation.")
                .font(.caption2)
                .foregroundStyle(.secondary.opacity(0.9))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var nutritionPreferencesSection: some View {
        settingsSection("Nutrition Preferences", icon: "fork.knife") {
            let targets = appModel.nutritionTargets
            preferenceRow("Goal", targets.goal)
            preferenceRow("Protein target", "\(targets.proteinGrams)g/day")
            preferenceRow("Water target", "\(targets.waterOunces) oz/day")
            preferenceRow("Fiber guide", targets.fiberGuidance)
            preferenceRow("Avoids", targets.avoids)
            preferenceRow("Protein powder", targets.proteinPowder)
            preferenceRow("Creatine", targets.creatine)
            Text("Nutrition stays simple for the MVP: Cronometer visibility, protein floor, water, and sleep-protective caffeine timing.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(3)

            DisclosureGroup {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Use these as flexible examples: protein + carb + fruit/vegetable + healthy fat. Cronometer remains the source of detailed tracking.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)

                    ForEach(MealTemplateLibrary.templates) { template in
                        profileMealTemplateRow(template)
                    }
                }
                .padding(.top, 10)
            } label: {
                Label("Default meal templates", systemImage: "list.bullet.rectangle")
                    .font(.headline)
            }
            .tint(appModel.activeCategory.accent)
        }
    }

    private var bodyMetricsSection: some View {
        settingsSection("Body Metrics", icon: "scalemass") {
            let summary = appModel.latestBodyMetricsSummary()

            Text("For recomposition, use body metrics as trend data. Smart-scale body composition estimates are useful for direction, not exact medical measurement.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                storageMetric("Latest weight", summary.latestWeightText)
                storageMetric("Source", summary.sourceText)
            }

            if let appleWeight = summary.appleHealthWeightPounds {
                Text("Apple Health weight available: \(String(format: "%.1f lb", appleWeight)). This is read-only context unless you choose to save a manual entry.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Picker("Entry source", selection: $bodyMetricsSource) {
                Text(BodyMetricsSource.manual.rawValue).tag(BodyMetricsSource.manual)
                Text(BodyMetricsSource.smartScaleManual.rawValue).tag(BodyMetricsSource.smartScaleManual)
            }
            .pickerStyle(.segmented)

            manualBodyMetricField("Weight", text: $bodyWeight, placeholder: "lb")
            manualBodyMetricField("Body fat", text: $bodyFatPercent, placeholder: "%")
            manualBodyMetricField("Muscle mass", text: $muscleMass, placeholder: "lb")
            manualBodyMetricField("Visceral fat", text: $visceralFat, placeholder: "level")
            manualBodyMetricField("Waist", text: $waist, placeholder: "in")

            styledProfileField("Notes", text: $bodyMetricsNotes, axis: .vertical)
                .lineLimit(2...4)

            PrimaryActionButton(title: "Save Today's Body Metrics", icon: "square.and.arrow.down", accent: appModel.activeCategory.accent) {
                saveBodyMetricsEntry()
            }
        }
    }

    private var dataStorageSection: some View {
        settingsSection("Data & Storage", icon: "externaldrive") {
            Text("Data is stored locally on this device in the app sandbox. There is no account login, cloud sync, or export in this MVP.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)

            persistenceStatusSection

            DisclosureGroup {
                VStack(alignment: .leading, spacing: 12) {
                    fileRow("checkins.json", "Daily Check In and readiness records")
                    fileRow("workout_logs.json", "Exercise set logs")
                    fileRow("daily_ritual_logs.json", "Ritual completions by calendar day")
                    fileRow("daily_nutrition_logs.json", "Manual nutrition summaries by calendar day")
                    fileRow("oura_manual_snapshots.json", "Manual/mock Oura recovery test snapshots")
                    fileRow("body_metrics_entries.json", "Manual body metrics and smart-scale trend entries")
                    fileRow("custom_workouts.json", "Brian-built workout templates stored locally")
                    fileRow("UserDefaults personalizationSettings", "Onboarding baseline, goal, equipment, and nutrition anchors")
                    fileRow("UserDefaults reminderSettings", "Reminder toggles, times, and local settings")
                    fileRow("UserDefaults ouraConnectionSettings", "Oura foundation mode and preferred recovery source")

                    Divider()
                        .overlay(.white.opacity(0.16))

                    Text(appModel.debugSummary)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)

                    if !appModel.debugLog.isEmpty {
                        ForEach(appModel.debugLog, id: \.self) { line in
                            Text(line)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 10)
            } label: {
                Label("Debug and storage files", systemImage: "wrench.and.screwdriver")
                    .font(.headline)
            }
            .tint(appModel.activeCategory.accent)

            DisclosureGroup {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(realDeviceChecklist, id: \.self) { item in
                        Label(item, systemImage: "circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 10)
            } label: {
                Label("Real device checklist", systemImage: "checklist")
                    .font(.headline)
            }
            .tint(appModel.activeCategory.accent)
        }
    }

    private var resetControlsSection: some View {
        settingsSection("Reset Controls", icon: "exclamationmark.triangle") {
            Text("Use these only while testing. Each action asks for confirmation.")
                .font(.caption)
                .foregroundStyle(.secondary)

            resetButton(.greeting)
            resetButton(.todayRitual)
            resetButton(.workoutLogs)
            resetButton(.allLocalData)
        }
    }

    private var aboutSection: some View {
        settingsSection("About MVP", icon: "info.circle") {
            HStack(spacing: 12) {
                CommandBrandMark(accent: appModel.activeCategory.accent, size: 44)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Health Command Center")
                        .font(.headline)
                    Text("Private MVP for Brian")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CommandDesign.secondaryText)
                }
            }

            Text("This is Brian's private Health Command Center MVP: a local-first app for readiness, training, rituals, weekly review, and practical next actions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)

            Text("Data is stored locally on this device. Apple Health access is read-only. Oura OAuth and Cronometer API integration are not connected yet.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)

            Text("This app is coaching and personal organization software, not medical advice, diagnosis, treatment, or clinical decision support.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
    }

    private func settingsSection<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        CommandCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: title, icon: icon, accent: appModel.activeCategory.accent)
                content()
            }
        }
    }

    private func preferencePicker<T: RawRepresentable & CaseIterable & Identifiable & Hashable>(_ title: String, value: Binding<T>, cases: T.AllCases) -> some View where T.RawValue == String, T.AllCases: RandomAccessCollection {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Picker(title, selection: value) {
                ForEach(cases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(appModel.activeCategory.accent)
        }
    }

    private func reminderRow(
        title: String,
        subtitle: String,
        icon: String,
        enabledKeyPath: WritableKeyPath<ReminderSettings, Bool>,
        timeKeyPath: WritableKeyPath<ReminderSettings, ReminderTime>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(appModel.activeCategory.accent)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Toggle(title, isOn: reminderToggleBinding(enabledKeyPath))
                        .font(.subheadline.weight(.semibold))
                        .tint(appModel.activeCategory.accent)
                        .disabled(!appModel.reminderSettings.remindersEnabled)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
            }

            DatePicker(
                "Time",
                selection: reminderTimeBinding(timeKeyPath),
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.compact)
            .tint(appModel.activeCategory.accent)
            .disabled(!appModel.reminderSettings.remindersEnabled || !appModel.reminderSettings[keyPath: enabledKeyPath])
        }
        .padding(10)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }

    private func reminderToggleBinding(_ keyPath: WritableKeyPath<ReminderSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { appModel.reminderSettings[keyPath: keyPath] },
            set: { newValue in
                var settings = appModel.reminderSettings
                settings[keyPath: keyPath] = newValue
                Task { await appModel.saveReminderSettings(settings) }
            }
        )
    }

    private func reminderTimeBinding(_ keyPath: WritableKeyPath<ReminderSettings, ReminderTime>) -> Binding<Date> {
        Binding(
            get: { appModel.reminderSettings[keyPath: keyPath].date() },
            set: { newValue in
                var settings = appModel.reminderSettings
                settings[keyPath: keyPath] = ReminderTime.from(date: newValue)
                Task { await appModel.saveReminderSettings(settings) }
            }
        )
    }

    private var ouraEnabledBinding: Binding<Bool> {
        Binding(
            get: { appModel.ouraConnectionSettings.isEnabled },
            set: { isEnabled in
                var settings = appModel.ouraConnectionSettings
                settings.isEnabled = isEnabled
                if !isEnabled {
                    settings.connectionMode = .notConnected
                } else if settings.connectionMode == .notConnected {
                    settings.connectionMode = .manual
                }
                appModel.saveOuraConnectionSettings(settings)
            }
        )
    }

    private var ouraModeBinding: Binding<OuraConnectionMode> {
        Binding(
            get: { appModel.ouraConnectionSettings.connectionMode },
            set: { mode in
                var settings = appModel.ouraConnectionSettings
                settings.connectionMode = mode
                settings.isEnabled = mode == .mock || mode == .manual
                if mode == .futureOAuth {
                    settings.notes = "Future OAuth placeholder. No real Oura tokens are stored."
                }
                appModel.saveOuraConnectionSettings(settings)
            }
        )
    }

    private var recoverySourceBinding: Binding<RecoveryDataSource> {
        Binding(
            get: { appModel.ouraConnectionSettings.preferredRecoverySource },
            set: { source in
                var settings = appModel.ouraConnectionSettings
                settings.preferredRecoverySource = source
                appModel.saveOuraConnectionSettings(settings)
            }
        )
    }

    private func manualOuraField(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            TextField(placeholder, text: text)
                .multilineTextAlignment(.trailing)
                .padding(.horizontal, 12)
                .frame(minHeight: 42)
                .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous)
                        .stroke(CommandDesign.hairline, lineWidth: 1)
                }
                .frame(maxWidth: 140)
        }
    }

    private func manualBodyMetricField(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            TextField(placeholder, text: text)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .padding(.horizontal, 12)
                .frame(minHeight: 42)
                .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous)
                        .stroke(CommandDesign.hairline, lineWidth: 1)
                }
                .frame(maxWidth: 140)
        }
    }

    private func styledProfileField(_ title: String, text: Binding<String>, axis: Axis = .horizontal) -> some View {
        TextField(title, text: text, axis: axis)
            .padding(12)
            .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous)
                    .stroke(CommandDesign.hairline, lineWidth: 1)
            }
    }

    private func saveOuraSnapshot() {
        dismissCommandKeyboard()
        let snapshot = OuraManualSnapshot(
            readinessScore: optionalInt(ouraReadinessScore),
            sleepScore: optionalInt(ouraSleepScore),
            sleepDurationHours: optionalDouble(ouraSleepDuration),
            hrv: optionalDouble(ouraHRV),
            restingHeartRate: optionalDouble(ouraRestingHeartRate),
            bodyTemperatureTrend: ouraBodyTemperatureTrend.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            notes: ouraNotes
        )
        appModel.saveOuraManualSnapshot(snapshot)
        showProfileFeedback("Oura test snapshot saved")
    }

    private func saveBodyMetricsEntry() {
        dismissCommandKeyboard()
        let entry = BodyMetricsEntry(
            weightPounds: optionalDouble(bodyWeight),
            bodyFatPercent: optionalDouble(bodyFatPercent),
            muscleMassPounds: optionalDouble(muscleMass),
            visceralFatLevel: optionalDouble(visceralFat),
            waistInches: optionalDouble(waist),
            notes: bodyMetricsNotes,
            source: bodyMetricsSource
        )
        guard entry.hasAnyMetric || !entry.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showProfileFeedback("Add at least one body metric or note")
            return
        }
        appModel.saveBodyMetricsEntry(entry)
        showProfileFeedback("Body metrics saved")
    }

    private func showProfileFeedback(_ message: String) {
        withAnimation(.easeOut(duration: 0.16)) {
            profileFeedback = message
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.4))
            withAnimation(.easeOut(duration: 0.18)) {
                profileFeedback = nil
            }
        }
    }

    private func optionalInt(_ text: String) -> Int? {
        Int(text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func optionalDouble(_ text: String) -> Double? {
        Double(text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func recoveryCopy(for phase: ProgramPhase) -> String {
        switch phase {
        case .nightShift:
            return "Night Shift: protect the planned sleep window, time caffeine relative to sleep, and use naps strategically."
        case .dayShift:
            return "Day Shift: regular wind-down, stable wake/sleep rhythm, and earlier caffeine."
        case .newBaby:
            return "New-Baby: lower the floor, use naps when they appear, and avoid overreaching after low sleep."
        case .normalRoutine:
            return "Normal Routine: consistent sleep routine keeps gradual progression available."
        }
    }

    private func preferenceRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.trailing)
        }
    }

    private func profileMealTemplateRow(_ template: MealTemplate) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Text(template.title)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 8)
                StatusPill(title: template.mealType.rawValue, accent: appModel.activeCategory.accent)
            }

            Text("Protein: \(template.proteinIdea)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Carb: \(template.carbIdea) | Produce: \(template.fruitOrVegetableIdea) | Fat: \(template.fatIdea)")
                .font(.caption2)
                .foregroundStyle(.secondary.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            Text(template.prepNotes)
                .font(.caption2)
                .foregroundStyle(.secondary.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }

    private func storageMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }

    private func statusRow(_ item: DeviceStatusItem) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 8)
                Text(item.value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(appModel.activeCategory.accent)
                    .multilineTextAlignment(.trailing)
            }

            Text(item.detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }

    private func fileRow(_ filename: String, _ description: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(filename)
                .font(.system(.caption, design: .monospaced).weight(.semibold))
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func resetButton(_ action: ResetAction) -> some View {
        let color = action.isDestructive ? Color.red : appModel.activeCategory.accent

        return Button(role: action.isDestructive ? .destructive : nil) {
            resetAction = action
        } label: {
            Label(action.buttonTitle, systemImage: action.icon)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 48)
                .padding(12)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(color.opacity(0.95))
    }

    private func perform(_ action: ResetAction) {
        switch action {
        case .greeting:
            appModel.resetGreetingState()
        case .todayRitual:
            appModel.resetTodaysRitual()
        case .workoutLogs:
            appModel.deleteWorkoutLogs()
        case .allLocalData:
            appModel.deleteAllLocalAppData()
        }
    }

    private var realDeviceChecklist: [String] {
        [
            "App launches on a real iPhone",
            "Greeting/setup appears on first run",
            "Setup completion routes to Home",
            "Check In starts from Home",
            "Apple Health connection is user-initiated",
            "HealthKit permissions appear",
            "Denied permissions do not crash the app",
            "Missing metrics show empty states",
            "Check-in completes",
            "Readiness category appears without a numeric score",
            "\"Why this category?\" is hidden by default and expands",
            "Home dashboard reflects latest check-in",
            "Local storage persists after app relaunch",
            "Nutrition targets and body metrics reflect Profile settings",
            "Debug inputs show raw health values, check-in values, and logs"
        ]
    }
}

private enum ResetAction: Identifiable {
    case greeting
    case todayRitual
    case workoutLogs
    case allLocalData

    var id: String { buttonTitle }

    var buttonTitle: String {
        switch self {
        case .greeting: return "Reset opening screen only"
        case .todayRitual: return "Reset today's ritual only"
        case .workoutLogs: return "Delete workout logs"
        case .allLocalData: return "Delete all local app data"
        }
    }

    var icon: String {
        switch self {
        case .greeting: return "rectangle.portrait.and.arrow.right"
        case .todayRitual: return "arrow.counterclockwise"
        case .workoutLogs: return "trash"
        case .allLocalData: return "xmark.octagon"
        }
    }

    var title: String {
        switch self {
        case .greeting: return "Reset Opening Setup?"
        case .todayRitual: return "Reset Today's Ritual?"
        case .workoutLogs: return "Delete Workout Logs?"
        case .allLocalData: return "Delete All Local Data?"
        }
    }

    var message: String {
        switch self {
        case .greeting:
            return "This resets only the greeting/onboarding flag so you can test the setup flow again. Check-ins, workout logs, rituals, body metrics, and settings stay stored."
        case .todayRitual:
            return "This clears today's ritual checkmarks and Daily Win answer only. Previous days stay stored."
        case .workoutLogs:
            return "This removes all locally stored exercise logs from workout_logs.json."
        case .allLocalData:
            return "This removes check-ins, workout logs, custom workouts, ritual logs, nutrition logs, Oura test snapshots, body metrics entries, and local preferences. Apple Health data is not deleted. The app returns to first-run state."
        }
    }

    var confirmTitle: String {
        switch self {
        case .greeting: return "Reset Opening"
        case .todayRitual: return "Reset"
        case .workoutLogs: return "Delete Logs"
        case .allLocalData: return "Delete All"
        }
    }

    var isDestructive: Bool {
        switch self {
        case .greeting, .todayRitual:
            return false
        case .workoutLogs, .allLocalData:
            return true
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
