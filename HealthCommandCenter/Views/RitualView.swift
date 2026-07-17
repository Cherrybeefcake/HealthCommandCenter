import SwiftUI

struct RitualView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var showingRecoveryLibrary = false
    @State private var selectedRecoveryDefinition: ExerciseDefinition?

    private var category: ReadinessCategory {
        appModel.activeCategory
    }

    private var items: [RitualItem] {
        RitualLibrary.items(for: category)
    }

    private var completedCount: Int {
        items.filter { appModel.isRitualItemComplete($0.id) }.count
    }

    private var dailyPlan: DailyPlan {
        appModel.todayDailyPlan
    }

    var body: some View {
        ZStack {
            CommandBackground(category: category)

            ScrollView {
                VStack(alignment: .leading, spacing: CommandDesign.stackSpacing) {
                    ScreenHeader(
                        eyebrow: "RECOVERY",
                        title: "Protect the floor.",
                        subtitle: "Brian, this is the recovery protocol for the day you actually have."
                    )

                    ritualSummary
                    dailyPlanPanel
                    recoveryLibrarySection
                    CommandSection(
                        title: "Recovery protocol",
                        subtitle: "Sleep, nutrition, and small anchors before anything fancy.",
                        icon: "figure.mind.and.body",
                        accent: category.accent
                    ) {
                        SleepPrepSection(status: appModel.todayRecoveryStatus(), phase: appModel.programPhase, accent: category.accent)
                        NutritionLogSection(accent: category.accent)
                    }

                    if completedCount == 0 {
                        EmptyStateCard(
                            title: "Start with the smallest useful win",
                            message: "Pick one ritual item that lowers friction for the rest of the day. Brian does not need a perfect streak to keep the system alive.",
                            icon: "sparkle",
                            accent: category.accent
                        )
                    }

                    ForEach(items) { item in
                        RitualItemCard(item: item, accent: category.accent)
                    }
                }
                .padding(CommandDesign.pagePadding)
            }
            .commandKeyboardDismissal()
        }
        .onAppear {
            DispatchQueue.main.async {
                appModel.prepareTodayStateIfNeeded()
            }
        }
        .sheet(isPresented: $showingRecoveryLibrary) {
            ExerciseLibraryBrowserView(
                title: "Recovery Movement Library",
                subtitle: "Search mobility, stretching, desk resets, shoulder-friendly work, and low-sleep recovery options.",
                accent: category.accent,
                initialMobilityOnly: true,
                selectActionTitle: "Add to Today’s Recovery",
                selectActionIcon: "plus.circle.fill",
                onSelect: { definition in
                    appModel.addRecoveryExerciseToToday(definition)
                }
            )
            .environmentObject(appModel)
        }
        .sheet(item: $selectedRecoveryDefinition) { definition in
            ExerciseLibraryDetailView(definition: definition, accent: category.accent)
                .environmentObject(appModel)
        }
    }

    private var ritualSummary: some View {
        HeroCard(accent: category.accent) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(category.rawValue)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(category.accent)
                        Text(RitualLibrary.coachingLine(for: category))
                            .font(.subheadline)
                            .foregroundStyle(CommandDesign.secondaryText)
                            .lineSpacing(3)
                    }
                    Spacer()
                    Text("\(completedCount)/\(items.count)")
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(category.accent)
                }

                ProgressView(value: Double(completedCount), total: Double(max(items.count, 1)))
                    .tint(category.accent)

                Text(summaryLine)
                    .font(.caption)
                    .foregroundStyle(CommandDesign.secondaryText)
            }
        }
    }

    private var dailyPlanPanel: some View {
        CommandCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    title: "Today’s recovery call",
                    subtitle: dailyPlan.ritualRecommendation,
                    icon: "moon.stars",
                    accent: category.accent
                )

                HStack(spacing: 10) {
                    ritualPlanMetric("Recovery", dailyPlan.recoveryFocus, "bed.double")
                    ritualPlanMetric("Caffeine", dailyPlan.caffeineCutoffGuidance, "cup.and.saucer")
                }

                Text(dailyPlan.sleepPriority)
                    .font(.caption)
                    .foregroundStyle(CommandDesign.secondaryText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var recoveryLibrarySection: some View {
        let selected = appModel.todayRecoveryExercises()
        let saved = appModel.savedRecoveryFlowExercises()

        return CommandSection(
            title: "Recovery Library",
            subtitle: "Add mobility or stretch movements to today's recovery routine without changing the built-in ritual.",
            icon: "figure.cooldown",
            accent: category.accent
        ) {
            CommandCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Today’s selected movements")
                                .font(.headline)
                            Text(selected.isEmpty ? "No library movements added yet. Browse shoulder, hip, desk, and pre-sleep options." : "\(selected.count) movements added for today.")
                                .font(.caption)
                                .foregroundStyle(CommandDesign.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        SecondaryActionButton(title: "Browse", icon: "books.vertical", accent: category.accent) {
                            showingRecoveryLibrary = true
                        }
                    }

                    if selected.isEmpty {
                        EmptyStateCard(
                            title: "No recovery movements added",
                            message: "Browse the mobility library and add one movement that makes tonight easier.",
                            icon: "figure.mind.and.body",
                            accent: category.accent,
                            actionTitle: "Browse Recovery Library",
                            actionIcon: "books.vertical",
                            action: { showingRecoveryLibrary = true }
                        )
                    } else {
                        ForEach(selected) { definition in
                            recoveryMovementRow(definition)
                        }

                        SecondaryActionButton(title: "Save Today as Recovery Flow", icon: "tray.and.arrow.down", accent: category.accent) {
                            appModel.saveTodayRecoveryFlow()
                        }
                    }

                    if !saved.isEmpty {
                        DisclosureGroup {
                            VStack(spacing: 8) {
                                ForEach(saved) { definition in
                                    recoveryMovementRow(definition, showRemove: false)
                                }
                            }
                            .padding(.top, 8)
                        } label: {
                            Label("Saved recovery flow", systemImage: "bookmark")
                                .font(.headline)
                        }
                        .tint(category.accent)
                    }
                }
            }
        }
    }

    private func recoveryMovementRow(_ definition: ExerciseDefinition, showRemove: Bool = true) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                Text(definition.name)
                    .font(.subheadline.weight(.semibold))
                Text(definition.shortMetadataText)
                    .font(.caption)
                    .foregroundStyle(category.accent)
                Text(definition.howItShouldFeel)
                    .font(.caption)
                    .foregroundStyle(CommandDesign.secondaryText)
                    .lineLimit(2)
            }
            Spacer()
            Button {
                selectedRecoveryDefinition = definition
            } label: {
                Image(systemName: "info.circle")
                    .font(.headline)
                    .foregroundStyle(category.accent)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("View details for \(definition.name)")
            if showRemove {
                Button(role: .destructive) {
                    appModel.removeRecoveryExerciseFromToday(definition)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red.opacity(0.9))
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.06), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(definition.name) from today's recovery")
            }
        }
        .padding(12)
        .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }

    private func ritualPlanMetric(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: icon)
                .foregroundStyle(category.accent)
            Text(title)
                .font(.caption.weight(.semibold))
                Text(value)
                .font(.caption2)
                .foregroundStyle(CommandDesign.secondaryText)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }

    private var summaryLine: String {
        if completedCount == 0 {
            return "Start with the easiest useful item."
        }
        if completedCount == items.count {
            return "Ritual complete. Let that be enough."
        }
        return "\(items.count - completedCount) items left. Keep it calm and direct."
    }
}

private struct RitualItemCard: View {
    @EnvironmentObject private var appModel: AppViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let item: RitualItem
    let accent: Color
    @State private var isExpanded = false
    @State private var dailyWinText = ""
    @State private var dailyWinFeedback: String?

    private var isComplete: Bool {
        appModel.isRitualItemComplete(item.id)
    }

    var body: some View {
        CommandCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Button {
                        CommandMotion.animate(reduceMotion, animation: .spring(response: 0.22, dampingFraction: 0.82)) {
                            appModel.setRitualItem(item.id, completed: !isComplete)
                        }
                    } label: {
                        Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(isComplete ? accent : .secondary)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isComplete ? AppStrings.Accessibility.markRitualIncomplete : AppStrings.Accessibility.markRitualComplete)
                    .accessibilityValue(item.title)

                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 8) {
                            Text(item.title)
                                .font(.headline)
                            if !item.isRequired {
                                StatusPill(title: "Optional", accent: Color.gray)
                            }
                        }

                        Text(item.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                    }

                    Spacer(minLength: 6)

                    Button {
                        CommandMotion.animate(reduceMotion, animation: .easeInOut(duration: 0.18)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                            .font(.title3)
                            .foregroundStyle(accent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isExpanded ? "Collapse \(item.title) details" : "Expand \(item.title) details")
                }

                Text(item.recommendation)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(accent)
                    .lineSpacing(3)

                if item.kind == .dailyWin {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("One sentence is enough. Name the win, then let it count.")
                            .font(.caption)
                            .foregroundStyle(CommandDesign.secondaryText)
                        TextField("What is today's win?", text: $dailyWinText, axis: .vertical)
                            .lineLimit(2...4)
                            .padding(12)
                            .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous)
                                    .stroke(accent.opacity(0.20), lineWidth: 1)
                            }
                            .onSubmit {
                                appModel.saveDailyWinText(dailyWinText)
                                showDailyWinFeedback(dailyWinText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Daily Win cleared" : "Daily Win saved")
                            }

                        SecondaryActionButton(title: "Save Daily Win", icon: "checkmark", accent: accent) {
                            dismissCommandKeyboard()
                            appModel.saveDailyWinText(dailyWinText)
                            showDailyWinFeedback(dailyWinText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Daily Win cleared" : "Daily Win saved")
                        }

                        if let dailyWinFeedback {
                            CommandFeedbackPill(message: dailyWinFeedback, accent: accent)
                        }
                    }
                    .onAppear {
                        dailyWinText = appModel.todayDailyWinText()
                    }
                }

                if isExpanded {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(item.detailTitle)
                            .font(.caption.weight(.semibold))
                            .textCase(.uppercase)
                            .foregroundStyle(CommandDesign.secondaryText)

                        ForEach(item.details, id: \.self) { detail in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(accent)
                                    .frame(width: 5, height: 5)
                                    .padding(.top, 7)
                                Text(detail)
                                    .font(.subheadline)
                                    .foregroundStyle(CommandDesign.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(12)
                    .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                }
            }
        }
        .animation(CommandMotion.standard(reduceMotion), value: isExpanded)
        .animation(CommandMotion.spring(reduceMotion), value: isComplete)
    }

    private func showDailyWinFeedback(_ message: String) {
        CommandMotion.animate(reduceMotion, animation: .easeOut(duration: 0.16)) {
            dailyWinFeedback = message
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            CommandMotion.animate(reduceMotion, animation: .easeOut(duration: 0.18)) {
                dailyWinFeedback = nil
            }
        }
    }
}

private struct SleepPrepSection: View {
    let status: RecoveryStatus
    let phase: ProgramPhase
    let accent: Color

    var body: some View {
        CommandCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    title: "Sleep Prep",
                    subtitle: status.coachingLine,
                    icon: "moon.zzz",
                    accent: accent
                )

                sleepPrepRow("Caffeine cutoff", status.caffeineGuidance, "cup.and.saucer")
                sleepPrepRow("Wind-down", status.windDownGuidance, "lightswitch.off")
                sleepPrepRow("Screen and light", "Dim screens, lower light, and make the room boring before sleep.", "sunset")
                sleepPrepRow("2-minute reset", "Breathe in for 4, out for 6. Keep shoulders easy and jaw unclenched.", "lungs")
                sleepPrepRow("Nap strategy", status.napGuidance, "bed.double")

                if phase == .nightShift {
                    phaseNote("Night shift", "Protect the sleep window after shift. Use dark, cool, quiet, and treat caffeine timing as part of recovery.")
                } else if phase == .newBaby {
                    phaseNote("New-baby season", "Lower the floor. Naps, patience, and avoiding overreach count as productive work.")
                }
            }
        }
    }

    private func sleepPrepRow(_ title: String, _ text: String, _ icon: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(accent)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func phaseNote(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            StatusPill(title: title, accent: accent)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }
}

private struct NutritionLogSection: View {
    @EnvironmentObject private var appModel: AppViewModel
    let accent: Color

    @State private var caloriesText = ""
    @State private var proteinText = ""
    @State private var waterText = ""
    @State private var fiberText = ""
    @State private var cronometerCompleted = false
    @State private var notes = ""
    @State private var saveFeedback: String?

    var body: some View {
        CommandCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    title: "Nutrition Anchors",
                    subtitle: "Cronometer stays the detailed food log. This is Brian's daily summary.",
                    icon: "fork.knife",
                    accent: accent
                )

                let display = appModel.todayNutritionDisplay()
                VStack(alignment: .leading, spacing: 6) {
                    StatusPill(title: display.source, icon: display.source == "Apple Health" ? "heart.text.square" : "square.and.pencil", accent: accent)
                    Text(display.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))

                Toggle(isOn: $cronometerCompleted) {
                    Label("Cronometer completed", systemImage: cronometerCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.subheadline.weight(.semibold))
                }
                .tint(accent)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    nutritionField("Calories", text: $caloriesText, placeholder: "Optional")
                    nutritionField("Protein", text: $proteinText, placeholder: "160g target")
                    nutritionField("Water", text: $waterText, placeholder: "100 oz target")
                    nutritionField("Fiber", text: $fiberText, placeholder: "25-35g guide")
                }

                TextField("Notes: meal quality, appetite, simple wins", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(12)
                    .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "target")
                        .foregroundStyle(accent)
                    Text("Body recomposition anchors: protein floor, hydration, fiber, and enough Cronometer visibility to stay honest.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }

                SecondaryActionButton(title: "Save Nutrition Summary", icon: "checkmark", accent: accent) {
                    save()
                }
                .accessibilityLabel(AppStrings.Action.saveNutrition)

                if let saveFeedback {
                    CommandFeedbackPill(message: saveFeedback, accent: accent)
                }

                nutritionGuidance
            }
        }
        .onAppear {
            loadFromToday()
        }
    }

    private func nutritionField(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .padding(12)
                .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
        }
    }

    private var nutritionGuidance: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .overlay(.white.opacity(0.16))

            SectionHeader(
                title: "Nutrition Guidance",
                subtitle: "Flexible templates, not a rigid meal plan.",
                icon: "list.bullet.rectangle",
                accent: accent
            )

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "plus.circle")
                    .foregroundStyle(accent)
                Text("Simple formula: protein + carb + fruit or vegetable + healthy fat.")
                    .font(.subheadline.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("Work-shift note: use the griddle for protein, the fridge for rice/produce, and the blender for a quick shake when time is thin.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(MealTemplateLibrary.todaySuggestions) { template in
                MealTemplateCompactRow(template: template, accent: accent)
            }
        }
    }

    private func loadFromToday() {
        let log = appModel.todayNutritionDisplay().log
        caloriesText = log.caloriesLogged.map(String.init) ?? ""
        proteinText = log.proteinGrams.map(String.init) ?? ""
        waterText = log.waterOunces.map(String.init) ?? ""
        fiberText = log.fiberGrams.map(String.init) ?? ""
        cronometerCompleted = log.cronometerCompleted
        notes = log.notes
    }

    private func save() {
        dismissCommandKeyboard()
        let protein = intValue(proteinText)
        let water = intValue(waterText)
        let targets = appModel.nutritionTargets
        appModel.saveNutritionLog(
            DailyNutritionLog(
                dateKey: RitualLibrary.dateKey(),
                caloriesLogged: intValue(caloriesText),
                proteinGrams: protein,
                waterOunces: water,
                fiberGrams: intValue(fiberText),
                cronometerCompleted: cronometerCompleted,
                proteinTargetHit: protein.map { $0 >= targets.proteinGrams } ?? false,
                waterTargetHit: water.map { $0 >= targets.waterOunces } ?? false,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )
        showSaveFeedback("Nutrition anchors saved")
    }

    private func showSaveFeedback(_ message: String) {
        withAnimation(.easeOut(duration: 0.16)) {
            saveFeedback = message
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeOut(duration: 0.18)) {
                saveFeedback = nil
            }
        }
    }

    private func intValue(_ text: String) -> Int? {
        Int(text.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

private struct MealTemplateCompactRow: View {
    let template: MealTemplate
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(template.title)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 8)
                StatusPill(title: template.mealType.rawValue, accent: accent)
            }

            Text("\(template.proteinIdea) + \(template.carbIdea)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(template.prepNotes)
                .font(.caption2)
                .foregroundStyle(.secondary.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }
}
