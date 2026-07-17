import SwiftUI

struct PlanView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var selectedWorkoutID = WorkoutLibrary.starterProgram[0].id
    @State private var selectedCustomWorkoutID: String?
    @State private var usesGeneratedWorkout = false
    @State private var showingCustomWorkoutSheet = false
    @State private var customWorkoutToEdit: CustomWorkout?
    @State private var customWorkoutToDelete: CustomWorkout?
    @State private var customWorkoutFeedback: String?
    @State private var expandedLibraryCategories: Set<WorkoutCategory> = [.workShiftQuick, .dumbbellStrength, .recoveryMobility, .bareMinimum]
    @State private var exerciseSearchText = ""
    @State private var exerciseCategoryFilter: ExerciseCategory?
    @State private var exerciseEquipmentFilter: EquipmentType?
    @State private var exerciseMuscleFilter: MuscleGroup?
    @State private var selectedExerciseDefinition: ExerciseDefinition?

    private var selectedBuiltInWorkout: WorkoutPlan {
        WorkoutLibrary.allBuiltInWorkouts.first { $0.id == selectedWorkoutID } ?? WorkoutLibrary.starterProgram[0]
    }

    private var selectedCustomWorkout: CustomWorkout? {
        guard let selectedCustomWorkoutID else { return nil }
        return appModel.customWorkouts.first { $0.id == selectedCustomWorkoutID }
    }

    private var activeWorkout: WorkoutPlan {
        if let selectedCustomWorkout {
            return selectedCustomWorkout.asWorkoutPlan
        }
        if usesGeneratedWorkout {
            return appModel.generatedWorkoutRecommendation().workout
        }
        return selectedBuiltInWorkout
    }

    private var recommendedVersionType: WorkoutVersionType {
        guard appModel.hasCheckedInToday else { return .bareMinimum }
        return StarterWorkoutLibrary.recommendedVersion(for: appModel.activeCategory)
    }

    private var recommendedLibraryWorkout: WorkoutPlan {
        WorkoutLibrary.recommendedWorkout(
            for: appModel.activeCategory,
            phase: appModel.programPhase,
            workoutTimePreference: appModel.workoutTimePreference
        )
    }

    private var selectedVersion: WorkoutVersion {
        activeWorkout.version(selectedCustomWorkout == nil ? recommendedVersionType : .full)
    }

    var body: some View {
        let category = appModel.activeCategory
        let dailyPlan = appModel.todayDailyPlan

        ZStack {
            CommandBackground(category: category)

            ScrollView {
                VStack(alignment: .leading, spacing: CommandDesign.stackSpacing) {
                    ScreenHeader(
                        eyebrow: "TRAIN",
                        title: "Train with the right dose.",
                        subtitle: "Pick the session, log the work, and keep the next action obvious."
                    )

                    recommendationPanel(category: category, dailyPlan: dailyPlan)
                    if !appModel.hasCheckedInToday {
                        EmptyStateCard(
                            title: "Classify today before training",
                            message: "The weekly plan is here, but Brian should start Check In before choosing a full workout version. Until then, keep movement tiny and easy.",
                            icon: "slider.horizontal.3",
                            accent: category.accent,
                            actionTitle: "Start Check In",
                            actionIcon: "slider.horizontal.3",
                            action: {
                                appModel.startNewCheckIn()
                            }
                        )
                    }
                    generatedWorkoutSection(category: category)
                    weeklyPlanSelector(category: category)
                    workoutLibrarySection(category: category)
                    exerciseLibrarySection(category: category)
                    customWorkoutSection(category: category)
                    if let customWorkoutFeedback {
                        CommandFeedbackPill(message: customWorkoutFeedback, accent: category.accent)
                    }
                    workoutVersionPanel(category: category)
                }
                .padding(CommandDesign.pagePadding)
            }
        }
        .sheet(isPresented: $showingCustomWorkoutSheet) {
            CustomWorkoutSheet(workoutToEdit: customWorkoutToEdit, accent: category.accent)
                .environmentObject(appModel)
                .onDisappear {
                    customWorkoutToEdit = nil
                }
        }
        .sheet(item: $selectedExerciseDefinition) { definition in
            ExerciseDetailView(definition: definition, accent: category.accent)
        }
        .alert("Delete custom workout?", isPresented: Binding(
            get: { customWorkoutToDelete != nil },
            set: { if !$0 { customWorkoutToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let customWorkoutToDelete {
                    appModel.deleteCustomWorkout(customWorkoutToDelete)
                    if selectedCustomWorkoutID == customWorkoutToDelete.id {
                        selectedCustomWorkoutID = nil
                        usesGeneratedWorkout = false
                    }
                    showCustomWorkoutFeedback("Custom workout deleted")
                }
                customWorkoutToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                customWorkoutToDelete = nil
            }
        } message: {
            Text("This removes the custom workout template only. Existing workout logs stay in history.")
        }
    }

    private func recommendationPanel(category: ReadinessCategory, dailyPlan: DailyPlan) -> some View {
        HeroCard(accent: category.accent) {
            VStack(alignment: .leading, spacing: 16) {
                StatusPill(title: "TODAY'S TRAINING CALL", icon: "sparkles", accent: category.accent)

                Text(dailyPlan.workoutRecommendation)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(category.accent)
                    .fixedSize(horizontal: false, vertical: true)

                Text(dailyPlan.recommendedAction)
                    .foregroundStyle(CommandDesign.secondaryText)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                CommandDivider()

                Button {
                    selectedWorkoutID = recommendedLibraryWorkout.id
                    selectedCustomWorkoutID = nil
                    usesGeneratedWorkout = false
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: recommendedLibraryWorkout.category.icon)
                            .foregroundStyle(category.accent)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Recommended workout")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(CommandDesign.secondaryText)
                                .textCase(.uppercase)
                            Text(recommendedLibraryWorkout.title)
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("\(recommendedLibraryWorkout.estimatedDuration) · \(recommendedLibraryWorkout.intensity)")
                                .font(.caption)
                                .foregroundStyle(CommandDesign.secondaryText)
                        }
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundStyle(category.accent)
                    }
                    .padding(12)
                    .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Select recommended workout \(recommendedLibraryWorkout.title)")

                VStack(alignment: .leading, spacing: 8) {
                    planVersionLine("Full", dailyPlan.fullVersionText, category.accent)
                    planVersionLine("Short", dailyPlan.shortVersionText, category.accent)
                    planVersionLine("Minimum", dailyPlan.bareMinimumVersionText, category.accent)
                }
            }
        }
    }

    private func generatedWorkoutSection(category: ReadinessCategory) -> some View {
        let recommendation = appModel.generatedWorkoutRecommendation()
        let workout = recommendation.workout

        return CommandSection(
            title: "Generated for Today",
            subtitle: "A deterministic local plan from readiness, recovery, time, location, and recent training.",
            icon: "wand.and.stars",
            accent: category.accent
        ) {
            CommandCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: workout.category.icon)
                            .foregroundStyle(category.accent)
                            .frame(width: 26)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(workout.title)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                            Text("\(workout.estimatedDuration) · \(workout.intensity)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(category.accent)
                            Text(recommendation.reason)
                                .font(.subheadline)
                                .foregroundStyle(CommandDesign.secondaryText)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }

                    Text(recommendation.primaryCautionText)
                        .font(.caption)
                        .foregroundStyle(CommandDesign.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(12)
                        .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))

                    if !recommendation.substitutions.isEmpty {
                        DisclosureGroup {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(recommendation.substitutions.prefix(3)) { substitution in
                                    Label("\(substitution.name): \(substitution.reason)", systemImage: "arrow.triangle.branch")
                                        .font(.caption)
                                        .foregroundStyle(CommandDesign.secondaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.top, 8)
                        } label: {
                            Label("Substitution ideas", systemImage: "arrow.triangle.branch")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                    }

                    HStack(spacing: 10) {
                        SecondaryActionButton(
                            title: usesGeneratedWorkout ? "Selected" : "Use Generated",
                            icon: usesGeneratedWorkout ? "checkmark" : "wand.and.stars",
                            accent: category.accent
                        ) {
                            selectedCustomWorkoutID = nil
                            usesGeneratedWorkout = true
                            selectedWorkoutID = workout.id
                        }

                        SecondaryActionButton(title: "Customize", icon: "square.and.pencil", accent: category.accent) {
                            customWorkoutToEdit = CustomWorkout(fromGeneratedWorkout: workout)
                            showingCustomWorkoutSheet = true
                        }
                    }
                }
            }
        }
    }

    private func planVersionLine(_ title: String, _ text: String, _ accent: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            StatusPill(title: title, accent: accent)
            Text(text)
                .font(.caption)
                .foregroundStyle(CommandDesign.secondaryText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func weeklyPlanSelector(category: ReadinessCategory) -> some View {
        CommandSection(
                title: "Starter Program",
                subtitle: "Full Body A, B, and C remain the weekly backbone. The version adapts from today’s readiness.",
                icon: "calendar",
                accent: category.accent
        ) {
            ForEach(WorkoutLibrary.starterProgram) { workout in
                builtInWorkoutRow(workout, category: category)
            }
        }
    }

    private func workoutLibrarySection(category: ReadinessCategory) -> some View {
        CommandSection(
            title: "Workout Library",
            subtitle: "Local built-in options for strength, shift days, recovery, conditioning, and minimum-dose movement.",
            icon: "books.vertical",
            accent: category.accent
        ) {
            ForEach(WorkoutCategory.allCases) { libraryCategory in
                let workouts = WorkoutLibrary.workouts(in: libraryCategory)
                if !workouts.isEmpty {
                    DisclosureGroup(isExpanded: Binding(
                        get: { expandedLibraryCategories.contains(libraryCategory) },
                        set: { isExpanded in
                            withAnimation(.easeInOut(duration: 0.18)) {
                                if isExpanded {
                                    expandedLibraryCategories.insert(libraryCategory)
                                } else {
                                    expandedLibraryCategories.remove(libraryCategory)
                                }
                            }
                        }
                    )) {
                        VStack(spacing: 10) {
                            ForEach(workouts) { workout in
                                builtInWorkoutRow(workout, category: category)
                            }
                        }
                        .padding(.top, 10)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: libraryCategory.icon)
                                .foregroundStyle(category.accent)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(libraryCategory.rawValue)
                                    .font(.headline)
                                Text("\(workouts.count) sessions")
                                    .font(.caption)
                                    .foregroundStyle(CommandDesign.secondaryText)
                            }
                        }
                    }
                    .tint(category.accent)
                    .padding(14)
                    .background(CommandDesign.surface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous)
                            .stroke(CommandDesign.hairline, lineWidth: 1)
                    }
                }
            }
        }
    }

    private func exerciseLibrarySection(category: ReadinessCategory) -> some View {
        let definitions = ExerciseLibrary.search(
            query: exerciseSearchText,
            category: exerciseCategoryFilter,
            equipment: exerciseEquipmentFilter,
            muscle: exerciseMuscleFilter,
            location: appModel.trainingLocation
        )

        return CommandSection(
            title: "Exercise Library",
            subtitle: "Search movements, see form details, and find safer substitutions for custom or changed workouts.",
            icon: "magnifyingglass.circle",
            accent: category.accent
        ) {
            CommandCard {
                VStack(alignment: .leading, spacing: 14) {
                    TextField("Search exercises", text: $exerciseSearchText)
                        .textInputAutocapitalization(.words)
                        .commandFieldStyle()

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        libraryPicker("Category", selection: $exerciseCategoryFilter, cases: ExerciseCategory.allCases, accent: category.accent)
                        libraryPicker("Equipment", selection: $exerciseEquipmentFilter, cases: EquipmentType.allCases, accent: category.accent)
                        libraryPicker("Muscle", selection: $exerciseMuscleFilter, cases: MuscleGroup.allCases, accent: category.accent)
                        Button {
                            withAnimation(.easeOut(duration: 0.18)) {
                                exerciseSearchText = ""
                                exerciseCategoryFilter = nil
                                exerciseEquipmentFilter = nil
                                exerciseMuscleFilter = nil
                            }
                        } label: {
                            Label("Clear filters", systemImage: "xmark.circle")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(category.accent)
                                .frame(maxWidth: .infinity, minHeight: 46)
                                .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear exercise library filters")
                    }

                    Text("Filtered for \(appModel.trainingLocation.rawValue). Change training location in You if today’s context changes.")
                        .font(.caption)
                        .foregroundStyle(CommandDesign.secondaryText)

                    if definitions.isEmpty {
                        EmptyStateCard(
                            title: "No matching exercises",
                            message: "Clear a filter or search a broader movement pattern like squat, row, carry, bike, or mobility.",
                            icon: "magnifyingglass",
                            accent: category.accent
                        )
                    } else {
                        ForEach(definitions.prefix(8)) { definition in
                            exerciseDefinitionRow(definition, accent: category.accent)
                        }

                        if definitions.count > 8 {
                            Text("\(definitions.count - 8) more matches. Narrow the search to keep this screen calm.")
                                .font(.caption)
                                .foregroundStyle(CommandDesign.secondaryText)
                        }
                    }
                }
            }
        }
    }

    private func libraryPicker<Value: RawRepresentable & CaseIterable & Identifiable & Hashable>(
        _ title: String,
        selection: Binding<Value?>,
        cases: Value.AllCases,
        accent: Color
    ) -> some View where Value.RawValue == String, Value.AllCases: RandomAccessCollection {
        Picker(title, selection: selection) {
            Text("All \(title)").tag(nil as Value?)
            ForEach(cases) { value in
                Text(value.rawValue).tag(Optional(value))
            }
        }
        .pickerStyle(.menu)
        .tint(accent)
        .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
        .padding(.horizontal, 12)
        .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }

    private func exerciseDefinitionRow(_ definition: ExerciseDefinition, accent: Color) -> some View {
        Button {
            selectedExerciseDefinition = definition
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(definition.name)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("\(definition.category.rawValue) · \(definition.difficulty.rawValue)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(accent)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(CommandDesign.secondaryText)
                }

                Text(definition.primaryMuscles.map(\.rawValue).joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(CommandDesign.secondaryText)
                    .lineLimit(2)

                HStack(spacing: 7) {
                    if definition.isShoulderFriendly {
                        StatusPill(title: "Shoulder-aware", icon: "checkmark", accent: accent)
                    }
                    if definition.isLowBackFriendly {
                        StatusPill(title: "Back-friendly", icon: "checkmark", accent: Color.gray)
                    }
                }
            }
            .padding(14)
            .background(CommandDesign.surface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous)
                    .stroke(CommandDesign.hairline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open exercise details for \(definition.name)")
    }

    private func builtInWorkoutRow(_ workout: WorkoutPlan, category: ReadinessCategory) -> some View {
        let isSelected = !usesGeneratedWorkout && selectedCustomWorkoutID == nil && selectedWorkoutID == workout.id
        return Button {
            selectedWorkoutID = workout.id
            selectedCustomWorkoutID = nil
            usesGeneratedWorkout = false
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        StatusPill(title: workout.weeklySlot, accent: isSelected ? category.accent : Color.gray)
                        StatusPill(title: workout.estimatedDuration, icon: "clock", accent: Color.gray)
                    }
                    Text(workout.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(workout.focus)
                        .font(.caption)
                        .foregroundStyle(CommandDesign.secondaryText)
                        .lineLimit(2)
                    Text(workout.coachingNote)
                        .font(.caption2)
                        .foregroundStyle(CommandDesign.tertiaryText)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? category.accent : CommandDesign.secondaryText)
            }
            .padding(16)
            .background(isSelected ? CommandDesign.elevatedSurface : CommandDesign.surface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous)
                    .stroke(isSelected ? category.accent.opacity(0.45) : CommandDesign.hairline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select \(workout.title)")
    }

    private func customWorkoutSection(category: ReadinessCategory) -> some View {
        CommandSection(
            title: "Custom workouts",
            subtitle: "Use this when Brian changes the workout but still wants the log in one place.",
            icon: "plus.square.on.square",
            accent: category.accent
        ) {
            HStack {
                Text("Brian-built templates")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CommandDesign.secondaryText)
                Spacer()
                Button {
                    customWorkoutToEdit = nil
                    showingCustomWorkoutSheet = true
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(category.accent)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add custom workout")
            }

            if appModel.customWorkouts.isEmpty {
                EmptyStateCard(
                    title: "No custom workouts yet",
                    message: "Add one when the planned workout changes. It will still use the same simple logging flow.",
                    icon: "square.and.pencil",
                    accent: category.accent,
                    actionTitle: "Add Custom Workout",
                    actionIcon: "plus",
                    action: {
                        customWorkoutToEdit = nil
                        showingCustomWorkoutSheet = true
                    }
                )
            } else {
                ForEach(appModel.customWorkouts) { workout in
                    customWorkoutRow(workout, category: category)
                }
            }
        }
    }

    private func customWorkoutRow(_ workout: CustomWorkout, category: ReadinessCategory) -> some View {
        let isSelected = !usesGeneratedWorkout && selectedCustomWorkoutID == workout.id
        return HStack(alignment: .top, spacing: 12) {
            Button {
                selectedCustomWorkoutID = workout.id
                usesGeneratedWorkout = false
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        StatusPill(title: "Custom", icon: "wand.and.stars", accent: isSelected ? category.accent : Color.gray)
                        Text(workout.name)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("\(workout.exercises.count) exercises")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CommandDesign.secondaryText)
                    }
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? category.accent : CommandDesign.secondaryText)
                }
            }
            .buttonStyle(.plain)

            Button {
                customWorkoutToEdit = workout
                showingCustomWorkoutSheet = true
            } label: {
                Image(systemName: "pencil")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(category.accent)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit \(workout.name)")

            Button(role: .destructive) {
                customWorkoutToDelete = workout
            } label: {
                Image(systemName: "trash")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red.opacity(0.9))
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete \(workout.name)")
        }
        .padding(16)
        .background(isSelected ? CommandDesign.elevatedSurface : CommandDesign.surface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous)
                .stroke(isSelected ? category.accent.opacity(0.45) : CommandDesign.hairline, lineWidth: 1)
        }
    }

    private func workoutVersionPanel(category: ReadinessCategory) -> some View {
        CommandSection(
            title: "Selected session",
            subtitle: "Log the work here. Today’s rows stay visible while Brian trains.",
            icon: "figure.strengthtraining.traditional",
            accent: category.accent
        ) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(activeWorkout.title)
                        .font(.title2.weight(.bold))
                    Text("\(selectedVersion.type.rawValue) · \(selectedVersion.duration)")
                        .font(.subheadline)
                        .foregroundStyle(category.accent)
                }
                Spacer()
            }

            HStack(spacing: 8) {
                StatusPill(title: activeWorkout.category.rawValue, icon: activeWorkout.category.icon, accent: category.accent)
                StatusPill(title: activeWorkout.intensity, accent: Color.gray)
            }

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "shippingbox")
                    .foregroundStyle(category.accent)
                    .frame(width: 20)
                Text(activeWorkout.equipmentSummary)
                    .font(.caption)
                    .foregroundStyle(CommandDesign.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(selectedVersion.intention)
                .foregroundStyle(CommandDesign.secondaryText)
                .lineSpacing(4)

            Text(activeWorkout.coachingNote)
                .font(.caption)
                .foregroundStyle(CommandDesign.tertiaryText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            WorkoutSessionSummary(
                workout: activeWorkout,
                accent: category.accent
            )

            ForEach(selectedVersion.sections) { section in
                workoutSectionView(section, workout: activeWorkout, version: selectedVersion, accent: category.accent)
            }
        }
    }

    private func workoutSectionView(_ section: WorkoutSection, workout: WorkoutPlan, version: WorkoutVersion, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: section.title, icon: section.title == "Warmup" ? "flame" : nil, accent: accent)

            ForEach(section.exercises) { exercise in
                ExercisePlanCard(
                    workout: workout,
                    version: version,
                    exercise: exercise,
                    accent: accent
                )
            }
        }
    }

    private func showCustomWorkoutFeedback(_ message: String) {
        withAnimation(.easeOut(duration: 0.16)) {
            customWorkoutFeedback = message
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeOut(duration: 0.18)) {
                customWorkoutFeedback = nil
            }
        }
    }

}

private struct ExercisePlanCard: View {
    @EnvironmentObject private var appModel: AppViewModel
    let workout: WorkoutPlan
    let version: WorkoutVersion
    let exercise: ExercisePlan
    let accent: Color
    @State private var isExpanded = false
    @State private var isProgressExpanded = false
    @State private var isCoachExpanded = false
    @State private var isLogging = false
    @State private var actionFeedback: String?

    var body: some View {
        let todayLogs = appModel.todayExerciseLogs(for: exercise.id, exerciseName: exercise.name)
        let suggestion = appModel.progressionSuggestion(for: exercise, workout: workout)
        let progressSummary = appModel.exerciseProgressSummary(for: exercise)

        CommandCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(exercise.name)
                            .font(.headline)
                        Text(exercise.equipment)
                            .font(.caption)
                            .foregroundStyle(CommandDesign.secondaryText)
                    }
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                            .font(.title3)
                            .foregroundStyle(accent)
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 10) {
                    planChip(exercise.prescription, "list.bullet.rectangle")
                    planChip(exercise.rest, "timer")
                }

                Text(exercise.feel)
                    .font(.subheadline)
                    .foregroundStyle(CommandDesign.secondaryText)
                    .lineSpacing(3)

                if !todayLogs.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Today", systemImage: "checklist")
                                .font(.caption.weight(.semibold))
                                .textCase(.uppercase)
                                .foregroundStyle(accent)
                            Spacer()
                            Text("\(todayLogs.reduce(0) { $0 + $1.setsCompleted }) sets")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(CommandDesign.secondaryText)
                        }

                        VStack(spacing: 8) {
                            ForEach(Array(todayLogs.enumerated()), id: \.element.id) { index, log in
                                TodaySetRow(
                                    setNumber: index + 1,
                                    log: log,
                                    accent: accent
                                ) {
                                    withAnimation(.easeOut(duration: 0.18)) {
                                        appModel.deleteExerciseLog(log)
                                    }
                                    showActionFeedback("Set deleted")
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                } else if exercise.isLoggable {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(accent)
                            .frame(width: 20)
                        Text("No sets logged today. Log the first honest set and this card will keep today's work visible.")
                            .font(.caption)
                            .foregroundStyle(CommandDesign.secondaryText)
                            .lineSpacing(3)
                    }
                    .padding(12)
                    .background(CommandDesign.surface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                }

                if exercise.isLoggable {
                    DisclosureGroup(isExpanded: $isCoachExpanded) {
                        VStack(alignment: .leading, spacing: 12) {
                            CoachSuggestionPanel(suggestion: suggestion, accent: accent)
                            ExerciseProgressSummaryPanel(
                                summary: progressSummary,
                                isExpanded: $isProgressExpanded,
                                accent: accent
                            )
                            if let lastLog = appModel.lastExerciseLog(for: exercise.id, exerciseName: exercise.name) {
                                lastTimePanel(lastLog)
                            }
                        }
                        .padding(.top, 10)
                    } label: {
                        Label("Coach + history", systemImage: "sparkles")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .tint(accent)
                    .animation(.easeInOut(duration: 0.18), value: isCoachExpanded)
                }

                if isExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        detailList("Form cues", exercise.formCues)
                        detailList("Common mistakes", exercise.commonMistakes)
                        detailList("Muscles targeted", exercise.musclesTargeted)
                        if let definition = ExerciseLibrary.definition(matching: exercise) {
                            libraryBackedDetails(definition)
                        }
                    }
                    .padding(.top, 2)
                }

                if exercise.isLoggable {
                    SecondaryActionButton(title: todayLogs.isEmpty ? "Log Exercise" : "Log Next Set", icon: "square.and.pencil", accent: accent) {
                        isLogging = true
                    }
                }

                if let actionFeedback {
                    CommandFeedbackPill(message: actionFeedback, accent: accent)
                }
            }
        }
        .animation(.easeInOut(duration: 0.18), value: isExpanded)
        .animation(.spring(response: 0.24, dampingFraction: 0.86), value: todayLogs.count)
        .sheet(isPresented: $isLogging) {
            ExerciseLogSheet(
                workout: workout,
                version: version,
                exercise: exercise,
                accent: accent,
                onSaved: { showActionFeedback("Set saved") }
            )
            .environmentObject(appModel)
        }
    }

    private func showActionFeedback(_ message: String) {
        withAnimation(.easeOut(duration: 0.16)) {
            actionFeedback = message
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeOut(duration: 0.18)) {
                actionFeedback = nil
            }
        }
    }

    private func planChip(_ text: String, _ icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(CommandDesign.elevatedSurface, in: Capsule())
            .overlay { Capsule().stroke(CommandDesign.hairline) }
    }

    private func lastTimePanel(_ lastLog: ExerciseLog) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(accent)
            VStack(alignment: .leading, spacing: 3) {
                Text("Last time")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CommandDesign.secondaryText)
                Text(lastLog.summary)
                    .font(.subheadline)
                Text(lastLog.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(CommandDesign.secondaryText)
            }
        }
        .padding(12)
        .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }

    private func detailList(_ title: String, _ values: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            ForEach(values, id: \.self) { value in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(accent)
                        .frame(width: 5, height: 5)
                        .padding(.top, 7)
                    Text(value)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func libraryBackedDetails(_ definition: ExerciseDefinition) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Library context")
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            Text(definition.painCautionGuidance)
                .font(.caption)
                .foregroundStyle(CommandDesign.secondaryText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(definition.substitutions.prefix(2)) { substitution in
                Label("\(substitution.name): \(substitution.reason)", systemImage: "arrow.triangle.branch")
                    .font(.caption)
                    .foregroundStyle(CommandDesign.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }
}

private struct CoachSuggestionPanel: View {
    let suggestion: ExerciseProgressionSuggestion
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(accent)
                Text("Coach Suggestion")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                suggestionMetric("Weight", suggestion.suggestedWeightText)
                suggestionMetric("Reps", suggestion.suggestedRepsText)
                suggestionMetric("Sets", suggestion.suggestedSetsText)
            }

            Text(suggestion.reason)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if let caution = suggestion.cautionNote {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(accent)
                    Text(caution)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
            }
        }
        .padding(12)
        .background(.black.opacity(0.20), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }

    private func suggestionMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(3)
                .minimumScaleFactor(0.72)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }
}

private struct ExerciseProgressSummaryPanel: View {
    let summary: ExerciseProgressSummary
    @Binding var isExpanded: Bool
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                isExpanded.toggle()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(accent)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Progress Summary")
                            .font(.caption.weight(.semibold))
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                        Text(summary.timesLogged == 0 ? "No history yet" : summary.recentBestText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                        .font(.title3)
                        .foregroundStyle(accent)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Toggle Progress Summary for \(summary.exerciseName)")

            if isExpanded {
                if summary.timesLogged == 0 {
                    Text(summary.coachingLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        progressMetric("\(summary.timesLogged)", "Times logged")
                        progressMetric(summary.heaviestWeightText, "Best so far")
                        progressMetric(summary.mostRepsText, "Most reps")
                        progressMetric(summary.bestVolumeText, "Best day")
                    }

                    if let date = summary.mostRecentDate {
                        Text("Most recent: \(date.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Text(summary.coachingLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }

    private func progressMetric(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
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

private struct WorkoutSessionSummary: View {
    @EnvironmentObject private var appModel: AppViewModel
    let workout: WorkoutPlan
    let accent: Color

    private var todayLogs: [ExerciseLog] {
        appModel.todayWorkoutLogs(for: workout.id)
    }

    var body: some View {
        let exerciseCount = Set(todayLogs.map(\.exerciseID)).count
        let setCount = todayLogs.reduce(0) { $0 + $1.setsCompleted }
        let latest = todayLogs.last?.date

        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(
                    title: "Workout session",
                    subtitle: todayLogs.isEmpty ? "No sets yet. Start small and let the log keep the thread." : "Today's logged work stays visible while you train.",
                    icon: "checklist",
                    accent: accent
                )

                HStack(spacing: 12) {
                    summaryMetric("\(exerciseCount)", "Exercises", "figure.strengthtraining.traditional")
                    summaryMetric("\(setCount)", "Sets", "checklist")
                    summaryMetric(latest?.formatted(date: .omitted, time: .shortened) ?? "--", "Latest", "clock")
                }
            }
        }
    }

    private func summaryMetric(_ value: String, _ label: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
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
        .padding(12)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }
}

private struct TodaySetRow: View {
    let setNumber: Int
    let log: ExerciseLog
    let accent: Color
    let delete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text("Set \(setNumber)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 44, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(weightText)
                    Text("\(log.reps) reps")
                    Text("RPE \(log.effort)")
                }
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

                HStack(spacing: 8) {
                    if log.setsCompleted > 1 {
                        Text("\(log.setsCompleted) sets in entry")
                    }
                    if !log.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Label("Notes", systemImage: "note.text")
                    }
                    Text(log.date.formatted(date: .omitted, time: .shortened))
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 6)

            Button(role: .destructive, action: delete) {
                Image(systemName: "trash")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red.opacity(0.9))
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete logged set")
        }
        .padding(10)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }

    private var weightText: String {
        log.weight.map { String(format: "%.0f lb", $0) } ?? "BW"
    }
}

private struct ExerciseLogSheet: View {
    @EnvironmentObject private var appModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    let workout: WorkoutPlan
    let version: WorkoutVersion
    let exercise: ExercisePlan
    let accent: Color
    let onSaved: () -> Void

    @State private var weightText = ""
    @State private var reps = 8
    @State private var setsCompleted = 1
    @State private var effort = 6
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ZStack {
                CommandBackground(category: appModel.activeCategory)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ScreenHeader(
                            eyebrow: "Log Exercise",
                            title: exercise.name,
                            subtitle: "Keep it honest and simple. This is for the next time you see the movement."
                        )

                        GlassPanel {
                            VStack(alignment: .leading, spacing: 18) {
                                TextField("Weight used, lb", text: $weightText)
                                    .padding(14)
                                    .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous)
                                            .stroke(CommandDesign.hairline, lineWidth: 1)
                                    }

                                Stepper("Reps: \(reps)", value: $reps, in: 1...50)
                                Stepper("Sets completed: \(setsCompleted)", value: $setsCompleted, in: 1...10)

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Effort")
                                        Spacer()
                                        Text("\(effort)/10")
                                            .monospacedDigit()
                                    }
                                    Slider(value: Binding(
                                        get: { Double(effort) },
                                        set: { effort = Int($0.rounded()) }
                                    ), in: 1...10, step: 1)
                                }

                                TextField("Optional notes", text: $notes, axis: .vertical)
                                    .lineLimit(2...5)
                                    .padding(14)
                                    .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous)
                                            .stroke(CommandDesign.hairline, lineWidth: 1)
                                    }
                            }
                        }

                        PrimaryActionButton(title: "Save Log", icon: "checkmark", accent: accent) {
                            save()
                        }
                    }
                    .padding(CommandDesign.pagePadding)
                }
                .commandKeyboardDismissal()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func save() {
        dismissCommandKeyboard()
        let trimmedWeight = weightText.trimmingCharacters(in: .whitespacesAndNewlines)
        let weight = trimmedWeight.isEmpty ? nil : Double(trimmedWeight)
        appModel.saveExerciseLog(
            ExerciseLog(
                workoutID: workout.id,
                workoutTitle: workout.title,
                versionType: version.type,
                exerciseID: exercise.id,
                exerciseName: exercise.name,
                weight: weight,
                reps: reps,
                setsCompleted: setsCompleted,
                effort: effort,
                notes: notes
            )
        )
        onSaved()
        dismiss()
    }
}

private struct ExerciseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let definition: ExerciseDefinition
    let accent: Color

    var body: some View {
        NavigationStack {
            ZStack {
                CommandBackground(category: .normalTrainingDay)

                ScrollView {
                    VStack(alignment: .leading, spacing: CommandDesign.stackSpacing) {
                        ScreenHeader(
                            eyebrow: definition.category.rawValue.uppercased(),
                            title: definition.name,
                            subtitle: "\(definition.difficulty.rawValue) · \(definition.equipment.map(\.rawValue).joined(separator: ", "))"
                        )

                        CommandCard {
                            VStack(alignment: .leading, spacing: 14) {
                                SectionHeader(title: "How to do it", subtitle: definition.setup, icon: "figure.strengthtraining.traditional", accent: accent)
                                ForEach(Array(definition.executionSteps.enumerated()), id: \.offset) { index, step in
                                    Label("\(index + 1). \(step)", systemImage: "checkmark.circle")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.9))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                CommandDivider()
                                detailLine("Breathing", definition.breathingCue)
                                detailLine("How it should feel", definition.howItShouldFeel)
                                detailLine("Pain / caution", definition.painCautionGuidance)
                            }
                        }

                        CommandCard {
                            VStack(alignment: .leading, spacing: 14) {
                                SectionHeader(title: "Targets", icon: "scope", accent: accent)
                                detailLine("Primary", definition.primaryMuscles.map(\.rawValue).joined(separator: ", "))
                                detailLine("Secondary", definition.secondaryMuscles.map(\.rawValue).joined(separator: ", "))
                                HStack(spacing: 8) {
                                    StatusPill(title: definition.isShoulderFriendly ? "Shoulder-friendly" : "Shoulder caution", icon: definition.isShoulderFriendly ? "checkmark" : "exclamationmark.triangle", accent: accent)
                                    StatusPill(title: definition.isLowBackFriendly ? "Back-friendly" : "Back caution", icon: definition.isLowBackFriendly ? "checkmark" : "exclamationmark.triangle", accent: Color.gray)
                                }
                            }
                        }

                        CommandCard {
                            VStack(alignment: .leading, spacing: 14) {
                                SectionHeader(title: "Common mistakes", icon: "exclamationmark.triangle", accent: accent)
                                ForEach(definition.commonMistakes, id: \.self) { mistake in
                                    Text("• \(mistake)")
                                        .font(.subheadline)
                                        .foregroundStyle(CommandDesign.secondaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }

                        CommandCard {
                            VStack(alignment: .leading, spacing: 14) {
                                SectionHeader(title: "Variations & substitutions", subtitle: "Use these when equipment, readiness, or joints change the plan.", icon: "arrow.triangle.branch", accent: accent)
                                ForEach(definition.variations) { variation in
                                    detailLine(variation.name, variation.note)
                                }
                                ForEach(definition.substitutions) { substitution in
                                    detailLine(substitution.name, substitution.reason)
                                }
                            }
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

    private func detailLine(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(CommandDesign.tertiaryText)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(CommandDesign.secondaryText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct CustomWorkoutSheet: View {
    @EnvironmentObject private var appModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    let workoutToEdit: CustomWorkout?
    let accent: Color

    @State private var name = ""
    @State private var notes = ""
    @State private var exerciseName = ""
    @State private var exerciseCategory = "Strength"
    @State private var exerciseEquipment = "Dumbbells / bands / bodyweight"
    @State private var targetSets = 2
    @State private var targetReps = "8-12"
    @State private var exerciseNotes = ""
    @State private var selectedLibraryExerciseID: String?
    @State private var exercises: [CustomExercise] = []
    @State private var validationMessage: String?

    private var isEditing: Bool {
        guard let workoutToEdit else { return false }
        return appModel.customWorkouts.contains { $0.id == workoutToEdit.id }
    }
    private var librarySuggestions: [ExerciseDefinition] {
        Array(ExerciseLibrary.search(
            query: exerciseName,
            category: nil,
            equipment: nil,
            muscle: nil,
            location: appModel.trainingLocation
        ).prefix(5))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CommandBackground(category: appModel.activeCategory)

                ScrollView {
                    VStack(alignment: .leading, spacing: CommandDesign.stackSpacing) {
                        ScreenHeader(
                            eyebrow: "Custom Workout",
                            title: isEditing ? "Edit custom session" : "Build today's session",
                            subtitle: isEditing ? "Adjust the template. Existing workout logs stay in history." : "Use this when the planned workout changes. Keep it practical and loggable."
                        )

                        workoutDetailsCard
                        addExerciseCard
                        exercisePreview

                        PrimaryActionButton(title: isEditing ? "Save Changes" : "Save Custom Workout", icon: "checkmark", accent: accent) {
                            save()
                        }

                        if let validationMessage {
                            CommandFeedbackPill(message: validationMessage, icon: "info.circle", accent: accent)
                        }
                    }
                    .padding(CommandDesign.pagePadding)
                }
                .commandKeyboardDismissal()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                loadWorkoutIfNeeded()
            }
        }
    }

    private var workoutDetailsCard: some View {
        CommandCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Workout details", icon: "square.and.pencil", accent: accent)
                TextField("Workout name", text: $name)
                    .textInputAutocapitalization(.words)
                    .commandFieldStyle()
                TextField("Notes or focus", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
                    .commandFieldStyle()
            }
        }
    }

    private var addExerciseCard: some View {
        CommandCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    title: "Add exercise",
                    subtitle: "A custom exercise can be logged like any starter-plan exercise.",
                    icon: "dumbbell",
                    accent: accent
                )

                TextField("Exercise name", text: $exerciseName)
                    .textInputAutocapitalization(.words)
                    .commandFieldStyle()

                if !librarySuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 9) {
                        Text("Library suggestions")
                            .font(.caption.weight(.semibold))
                            .textCase(.uppercase)
                            .foregroundStyle(CommandDesign.secondaryText)
                        ForEach(librarySuggestions) { definition in
                            Button {
                                applyLibraryExercise(definition)
                            } label: {
                                HStack(alignment: .top, spacing: 10) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(definition.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white)
                                        Text("\(definition.category.rawValue) · \(definition.equipment.map(\.rawValue).joined(separator: ", "))")
                                            .font(.caption2)
                                            .foregroundStyle(CommandDesign.secondaryText)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer()
                                    Image(systemName: selectedLibraryExerciseID == definition.id ? "checkmark.circle.fill" : "plus.circle")
                                        .foregroundStyle(accent)
                                }
                                .padding(10)
                                .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Use \(definition.name) from exercise library")
                        }
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    TextField("Category", text: $exerciseCategory)
                        .textInputAutocapitalization(.words)
                        .commandFieldStyle()
                    TextField("Equipment", text: $exerciseEquipment)
                        .textInputAutocapitalization(.words)
                        .commandFieldStyle()
                    TextField("Reps/time", text: $targetReps)
                        .commandFieldStyle()
                    Stepper("Sets: \(targetSets)", value: $targetSets, in: 1...8)
                        .padding(.horizontal, 10)
                        .frame(minHeight: 46)
                        .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                }

                TextField("Exercise notes", text: $exerciseNotes, axis: .vertical)
                    .lineLimit(2...4)
                    .commandFieldStyle()

                SecondaryActionButton(title: "Add Exercise", icon: "plus", accent: accent) {
                    addExercise()
                }

                if exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Add an exercise name before adding it to the custom workout.")
                        .font(.caption)
                        .foregroundStyle(CommandDesign.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var exercisePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Exercises", subtitle: exercises.isEmpty ? "Add at least one exercise before saving." : nil, icon: "list.bullet", accent: accent)

            if exercises.isEmpty {
                EmptyStateCard(
                    title: "No exercises added",
                    message: "Start with one or two movements. You can build the library slowly.",
                    icon: "plus.circle",
                    accent: accent
                )
            } else {
                ForEach(exercises) { exercise in
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name)
                                .font(.headline)
                            Text("\(exercise.targetSets) sets x \(exercise.targetReps) · \(exercise.equipment)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        Button(role: .destructive) {
                            exercises.removeAll { $0.id == exercise.id }
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.red.opacity(0.9))
                                .frame(width: 44, height: 44)
                                .background(.white.opacity(0.06), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(14)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                }
            }
        }
    }

    private func addExercise() {
        dismissCommandKeyboard()
        let cleanName = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            showValidation("Exercise needs a name first")
            return
        }
        withAnimation(.easeOut(duration: 0.18)) {
            exercises.append(
                CustomExercise(
                    name: cleanName,
                    category: exerciseCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Strength" : exerciseCategory.trimmingCharacters(in: .whitespacesAndNewlines),
                    equipment: exerciseEquipment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Available equipment" : exerciseEquipment.trimmingCharacters(in: .whitespacesAndNewlines),
                    targetSets: targetSets,
                    targetReps: targetReps.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "8-12" : targetReps.trimmingCharacters(in: .whitespacesAndNewlines),
                    notes: exerciseNotes.trimmingCharacters(in: .whitespacesAndNewlines),
                    libraryExerciseID: selectedLibraryExerciseID
                )
            )
        }
        showValidation("Exercise added")
        exerciseName = ""
        exerciseNotes = ""
        selectedLibraryExerciseID = nil
        targetSets = 2
        targetReps = "8-12"
    }

    private func applyLibraryExercise(_ definition: ExerciseDefinition) {
        exerciseName = definition.name
        exerciseCategory = definition.category.rawValue
        exerciseEquipment = definition.equipment.map(\.rawValue).joined(separator: " / ")
        exerciseNotes = definition.painCautionGuidance
        selectedLibraryExerciseID = definition.id
        showValidation("Loaded \(definition.name) from library")
    }

    private func save() {
        dismissCommandKeyboard()
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            showValidation("Custom workout needs a name")
            return
        }
        guard !exercises.isEmpty else {
            showValidation("Add at least one exercise before saving")
            return
        }
        appModel.saveCustomWorkout(
            CustomWorkout(
                id: workoutToEdit?.id ?? UUID().uuidString,
                name: cleanName,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: workoutToEdit?.createdAt ?? Date(),
                exercises: exercises
            )
        )
        dismiss()
    }

    private func loadWorkoutIfNeeded() {
        guard let workoutToEdit, name.isEmpty, exercises.isEmpty else { return }
        name = workoutToEdit.name
        notes = workoutToEdit.notes
        exercises = workoutToEdit.exercises
    }

    private func showValidation(_ message: String) {
        withAnimation(.easeOut(duration: 0.16)) {
            validationMessage = message
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeOut(duration: 0.18)) {
                validationMessage = nil
            }
        }
    }
}
