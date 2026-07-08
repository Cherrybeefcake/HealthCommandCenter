import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var resetAction: ResetAction?

    var body: some View {
        ZStack {
            CommandBackground(category: appModel.activeCategory)

            ScrollView {
                VStack(alignment: .leading, spacing: CommandDesign.stackSpacing) {
                    ScreenHeader(
                        eyebrow: "Profile",
                        title: appModel.userName,
                        subtitle: "Build the daily system. Keep the floor low. Stack wins."
                    )

                    profileSummary
                    programPhaseSection
                    trainingPreferencesSection
                    nutritionPreferencesSection
                    dataStorageSection
                    resetControlsSection
                    aboutSection
                }
                .padding(CommandDesign.pagePadding)
            }
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
    }

    private var profileSummary: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(appModel.programPhase.rawValue)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(appModel.activeCategory.accent)
                        Text("Current phase")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "person.crop.circle")
                        .font(.largeTitle)
                        .foregroundStyle(appModel.activeCategory.accent)
                }

                Text("5'6\" | around 174 lb | restarting training")
                    .font(.headline)

                Text("Private, local-first command center for rebuilding consistency around real life constraints.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }
        }
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
                .foregroundStyle(.secondary)
                .lineSpacing(3)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "bed.double")
                    .foregroundStyle(appModel.activeCategory.accent)
                Text(recoveryCopy(for: appModel.programPhase))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
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
            }
        }
    }

    private var nutritionPreferencesSection: some View {
        settingsSection("Nutrition Preferences", icon: "fork.knife") {
            let targets = NutritionTargets.brianDefault
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

    private var dataStorageSection: some View {
        settingsSection("Data & Storage", icon: "externaldrive") {
            Text("Data is stored locally on this device in the app sandbox. There is no account login, cloud sync, or export in this MVP.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                storageMetric("Check-ins", "\(appModel.checkIns.count)")
                storageMetric("Workout logs", "\(appModel.exerciseLogs.count)")
                storageMetric("Ritual days", "\(appModel.ritualLogs.count)")
                storageMetric("Nutrition", "\(appModel.nutritionLogs.count)")
            }

            DisclosureGroup {
                VStack(alignment: .leading, spacing: 12) {
                    fileRow("checkins.json", "Daily Check In and readiness records")
                    fileRow("workout_logs.json", "Exercise set logs")
                    fileRow("daily_ritual_logs.json", "Ritual completions by calendar day")
                    fileRow("daily_nutrition_logs.json", "Manual nutrition summaries by calendar day")

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
            Text("This is Brian's private Health Command Center MVP: a local-first app for readiness, training, rituals, and weekly review.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)

            Text("Direction: Apple Health context, future Oura OAuth, and future Cronometer integration. This app is not medical diagnosis, treatment, or clinical decision support.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
    }

    private func settingsSection<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        GlassPanel {
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
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
            "Greeting screen appears on first run",
            "Greeting completion routes to Home",
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
        case .greeting: return "Reset Opening Screen?"
        case .todayRitual: return "Reset Today's Ritual?"
        case .workoutLogs: return "Delete Workout Logs?"
        case .allLocalData: return "Delete All Local Data?"
        }
    }

    var message: String {
        switch self {
        case .greeting:
            return "This resets only the greeting/onboarding flag so you can test the original opening screen again. Check-ins, workout logs, rituals, and settings stay stored."
        case .todayRitual:
            return "This clears today's ritual checkmarks only. Previous days stay stored."
        case .workoutLogs:
            return "This removes all locally stored exercise logs from workout_logs.json."
        case .allLocalData:
            return "This removes check-ins, workout logs, ritual logs, and local preferences. The app returns to first-run state."
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
