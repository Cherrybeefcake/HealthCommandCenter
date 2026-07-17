import SwiftUI

struct ExerciseLibraryBrowserView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    let title: String
    let subtitle: String
    let accent: Color
    let initialMobilityOnly: Bool
    let selectActionTitle: String?
    let selectActionIcon: String
    let onSelect: ((ExerciseDefinition) -> Void)?

    @State private var query = ""
    @State private var category: ExerciseCategory?
    @State private var equipment: EquipmentType?
    @State private var muscle: MuscleGroup?
    @State private var movementPattern: ExerciseMovementPattern?
    @State private var difficulty: ExerciseDifficulty?
    @State private var location: TrainingLocation?
    @State private var bandsOnly = false
    @State private var bodyweightOnly = false
    @State private var mobilityOnly = false
    @State private var shoulderFriendly = false
    @State private var lowBackFriendly = false
    @State private var favoritesOnly = false
    @State private var recentlyUsedOnly = false
    @State private var showingFilters = false
    @State private var selectedDefinition: ExerciseDefinition?
    @State private var recentSearches: [String] = []

    init(
        title: String = "Exercise Library",
        subtitle: String = "Browse local exercises, substitutions, and coaching notes.",
        accent: Color,
        initialMobilityOnly: Bool = false,
        selectActionTitle: String? = nil,
        selectActionIcon: String = "plus",
        onSelect: ((ExerciseDefinition) -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.accent = accent
        self.initialMobilityOnly = initialMobilityOnly
        self.selectActionTitle = selectActionTitle
        self.selectActionIcon = selectActionIcon
        self.onSelect = onSelect
        _mobilityOnly = State(initialValue: initialMobilityOnly)
    }

    private var filteredDefinitions: [ExerciseDefinition] {
        var definitions = ExerciseLibrary.search(
            query: query,
            category: category,
            equipment: equipment,
            muscle: muscle,
            location: location ?? appModel.trainingLocation,
            movementPattern: movementPattern,
            difficulty: difficulty,
            shoulderFriendly: shoulderFriendly ? true : nil,
            lowBackFriendly: lowBackFriendly ? true : nil,
            bandsOnly: bandsOnly,
            mobilityOnly: mobilityOnly
        )

        if bodyweightOnly {
            definitions = definitions.filter { $0.equipment.contains(.bodyweight) }
        }
        if favoritesOnly {
            definitions = definitions.filter { appModel.favoriteExerciseIDs.contains($0.id) }
        }
        if recentlyUsedOnly {
            let used = Set(appModel.recentlyUsedExerciseIDs)
            definitions = definitions.filter { used.contains($0.id) }
        }
        return definitions
    }

    private var hasActiveFilters: Bool {
        !query.isEmpty || category != nil || equipment != nil || muscle != nil || movementPattern != nil || difficulty != nil || location != nil || bandsOnly || bodyweightOnly || mobilityOnly || shoulderFriendly || lowBackFriendly || favoritesOnly || recentlyUsedOnly
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CommandBackground(category: appModel.activeCategory)

                ScrollView {
                    VStack(alignment: .leading, spacing: CommandDesign.stackSpacing) {
                        ScreenHeader(
                            eyebrow: "LIBRARY",
                            title: title,
                            subtitle: subtitle
                        )

                        searchCard
                        activeChips

                        if query.isEmpty && !appModel.recentViewedExercises().isEmpty {
                            recentlyViewedCard
                        }

                        if !query.isEmpty || !recentSearches.isEmpty {
                            recentSearchesCard
                        }

                        resultSummary
                        resultsList
                    }
                    .padding(CommandDesign.pagePadding)
                }
                .commandKeyboardDismissal()
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingFilters = true
                    } label: {
                        Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Open exercise library filters")
                }
            }
            .sheet(isPresented: $showingFilters) {
                ExerciseLibraryFilterSheet(
                    accent: accent,
                    category: $category,
                    equipment: $equipment,
                    muscle: $muscle,
                    movementPattern: $movementPattern,
                    difficulty: $difficulty,
                    location: $location,
                    bandsOnly: $bandsOnly,
                    bodyweightOnly: $bodyweightOnly,
                    mobilityOnly: $mobilityOnly,
                    shoulderFriendly: $shoulderFriendly,
                    lowBackFriendly: $lowBackFriendly,
                    favoritesOnly: $favoritesOnly,
                    recentlyUsedOnly: $recentlyUsedOnly,
                    clear: clearFilters
                )
            }
            .sheet(item: $selectedDefinition) { definition in
                ExerciseLibraryDetailView(
                    definition: definition,
                    accent: accent,
                    selectActionTitle: selectActionTitle,
                    selectActionIcon: selectActionIcon,
                    onSelect: onSelect.map { action in
                        { selected in
                            action(selected)
                            dismiss()
                        }
                    }
                )
                .environmentObject(appModel)
            }
        }
    }

    private var searchCard: some View {
        CommandCard {
            VStack(alignment: .leading, spacing: 14) {
                TextField("Search by name, alias, equipment, muscle, or movement", text: $query)
                    .textInputAutocapitalization(.words)
                    .commandFieldStyle()
                    .onSubmit { rememberSearch() }

                HStack(spacing: 10) {
                    SecondaryActionButton(title: "Filters", icon: "slider.horizontal.3", accent: accent) {
                        showingFilters = true
                    }
                    if hasActiveFilters {
                        SecondaryActionButton(title: "Clear", icon: "xmark.circle", accent: Color.gray) {
                            clearFilters()
                        }
                    }
                }

                Text(ExerciseLibrary.libraryLoadStatusText)
                    .font(.caption)
                    .foregroundStyle(CommandDesign.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var activeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(appModel.trainingLocation.rawValue, icon: "location")
                if let category { filterChip(category.rawValue, icon: "square.grid.2x2") }
                if let equipment { filterChip(equipment.rawValue, icon: "shippingbox") }
                if let muscle { filterChip(muscle.rawValue, icon: "figure.strengthtraining.traditional") }
                if let movementPattern { filterChip(movementPattern.rawValue, icon: "arrow.triangle.branch") }
                if let difficulty { filterChip(difficulty.rawValue, icon: "speedometer") }
                if bandsOnly { filterChip("Bands", icon: "link") }
                if bodyweightOnly { filterChip("Bodyweight", icon: "figure.core.training") }
                if mobilityOnly { filterChip("Mobility", icon: "figure.cooldown") }
                if shoulderFriendly { filterChip("Shoulder-friendly", icon: "checkmark.shield") }
                if lowBackFriendly { filterChip("Low-back-friendly", icon: "checkmark.shield") }
                if favoritesOnly { filterChip("Favorites", icon: "star.fill") }
                if recentlyUsedOnly { filterChip("Recently used", icon: "clock.arrow.circlepath") }
            }
        }
    }

    private func filterChip(_ title: String, icon: String) -> some View {
        StatusPill(title: title, icon: icon, accent: accent)
    }

    private var recentSearchesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !recentSearches.isEmpty {
                Text("Recent searches")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(CommandDesign.secondaryText)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(recentSearches, id: \.self) { search in
                            Button {
                                query = search
                            } label: {
                                Text(search)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(CommandDesign.surface, in: Capsule())
                                    .overlay { Capsule().stroke(CommandDesign.hairline) }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var recentlyViewedCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recently viewed")
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(CommandDesign.secondaryText)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(appModel.recentViewedExercises(limit: 8)) { definition in
                        Button {
                            selectedDefinition = definition
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(definition.name)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Text(definition.category.rawValue)
                                    .font(.caption2)
                                    .foregroundStyle(CommandDesign.secondaryText)
                            }
                            .frame(width: 150, alignment: .leading)
                            .padding(12)
                            .background(CommandDesign.surface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous)
                                    .stroke(CommandDesign.hairline, lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open recently viewed exercise \(definition.name)")
                    }
                }
            }
        }
    }

    private var resultSummary: some View {
        HStack {
            Text("\(filteredDefinitions.count) results")
                .font(.headline)
            Spacer()
            Text("Tap a card for details")
                .font(.caption)
                .foregroundStyle(CommandDesign.secondaryText)
        }
    }

    private var resultsList: some View {
        VStack(spacing: 12) {
            if filteredDefinitions.isEmpty {
                EmptyStateCard(
                    title: "No matching exercises",
                    message: "Clear a filter or search a broader term like row, squat, band, hips, bike, or mobility.",
                    icon: "magnifyingglass",
                    accent: accent,
                    actionTitle: hasActiveFilters ? "Clear Filters" : nil,
                    actionIcon: "xmark.circle",
                    action: hasActiveFilters ? clearFilters : nil
                )
            } else {
                ForEach(filteredDefinitions.prefix(80)) { definition in
                    ExerciseLibraryResultCard(
                        definition: definition,
                        accent: accent,
                        isFavorite: appModel.isFavoriteExercise(definition.id),
                        onFavorite: { appModel.toggleFavoriteExercise(definition) },
                        onOpen: {
                            rememberSearch()
                            selectedDefinition = definition
                        },
                        onSelect: onSelect.map { action in
                            {
                                action(definition)
                                appModel.markExerciseUsed(definition)
                                dismiss()
                            }
                        }
                    )
                }
                if filteredDefinitions.count > 80 {
                    Text("\(filteredDefinitions.count - 80) more matches. Narrow the search for a calmer list.")
                        .font(.caption)
                        .foregroundStyle(CommandDesign.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func rememberSearch() {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        recentSearches = ExerciseLibrary.updatedRecentIDs(recentSearches, adding: clean, limit: 6)
    }

    private func clearFilters() {
        query = ""
        category = nil
        equipment = nil
        muscle = nil
        movementPattern = nil
        difficulty = nil
        location = nil
        bandsOnly = false
        bodyweightOnly = false
        mobilityOnly = initialMobilityOnly
        shoulderFriendly = false
        lowBackFriendly = false
        favoritesOnly = false
        recentlyUsedOnly = false
    }
}

private struct ExerciseLibraryResultCard: View {
    let definition: ExerciseDefinition
    let accent: Color
    let isFavorite: Bool
    let onFavorite: () -> Void
    let onOpen: () -> Void
    let onSelect: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 9) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(definition.name)
                                .font(.headline)
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(definition.shortMetadataText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(accent)
                        }
                        Spacer()
                        if definition.isHCCCurated {
                            StatusPill(title: "HCC", icon: "checkmark.seal", accent: accent)
                        }
                    }

                    Text(definition.equipmentText)
                        .font(.caption)
                        .foregroundStyle(CommandDesign.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(definition.muscleText)
                        .font(.caption)
                        .foregroundStyle(CommandDesign.secondaryText)
                        .lineLimit(2)

                    HStack(spacing: 7) {
                        if definition.isShoulderFriendly {
                            StatusPill(title: "Shoulder", icon: "checkmark", accent: accent)
                        }
                        if definition.isLowBackFriendly {
                            StatusPill(title: "Low back", icon: "checkmark", accent: Color.gray)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open exercise details for \(definition.name)")

            VStack(spacing: 8) {
                Button(action: onFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.headline)
                        .foregroundStyle(isFavorite ? accent : CommandDesign.secondaryText)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.06), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isFavorite ? "Remove \(definition.name) from favorites" : "Favorite \(definition.name)")

                if let onSelect {
                    Button(action: onSelect) {
                        Image(systemName: "plus.circle.fill")
                            .font(.headline)
                            .foregroundStyle(accent)
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.06), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add \(definition.name)")
                }
            }
        }
        .padding(15)
        .background(CommandDesign.surface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous)
                .stroke(CommandDesign.hairline, lineWidth: 1)
        }
    }
}

private struct ExerciseLibraryFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    let accent: Color
    @Binding var category: ExerciseCategory?
    @Binding var equipment: EquipmentType?
    @Binding var muscle: MuscleGroup?
    @Binding var movementPattern: ExerciseMovementPattern?
    @Binding var difficulty: ExerciseDifficulty?
    @Binding var location: TrainingLocation?
    @Binding var bandsOnly: Bool
    @Binding var bodyweightOnly: Bool
    @Binding var mobilityOnly: Bool
    @Binding var shoulderFriendly: Bool
    @Binding var lowBackFriendly: Bool
    @Binding var favoritesOnly: Bool
    @Binding var recentlyUsedOnly: Bool
    let clear: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                CommandBackground(category: .normalTrainingDay)
                ScrollView {
                    VStack(alignment: .leading, spacing: CommandDesign.stackSpacing) {
                        ScreenHeader(
                            eyebrow: "FILTERS",
                            title: "Narrow the library.",
                            subtitle: "Use only the filters that help today. Clear them when the list gets too tight."
                        )

                        CommandCard {
                            VStack(alignment: .leading, spacing: 14) {
                                optionalPicker("Category", selection: $category, cases: ExerciseCategory.allCases)
                                optionalPicker("Equipment", selection: $equipment, cases: EquipmentType.allCases)
                                optionalPicker("Muscle", selection: $muscle, cases: MuscleGroup.allCases)
                                optionalPicker("Movement", selection: $movementPattern, cases: ExerciseMovementPattern.allCases)
                                optionalPicker("Difficulty", selection: $difficulty, cases: ExerciseDifficulty.allCases)
                                optionalPicker("Location", selection: $location, cases: TrainingLocation.allCases)
                            }
                        }

                        CommandCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Quick filters", icon: "line.3.horizontal.decrease.circle", accent: accent)
                                Toggle("Bands only", isOn: $bandsOnly).tint(accent)
                                Toggle("Bodyweight only", isOn: $bodyweightOnly).tint(accent)
                                Toggle("Mobility / stretch only", isOn: $mobilityOnly).tint(accent)
                                Toggle("Shoulder-friendly", isOn: $shoulderFriendly).tint(accent)
                                Toggle("Low-back-friendly", isOn: $lowBackFriendly).tint(accent)
                                Toggle("Favorites", isOn: $favoritesOnly).tint(accent)
                                Toggle("Recently used", isOn: $recentlyUsedOnly).tint(accent)
                            }
                        }

                        SecondaryActionButton(title: "Clear Filters", icon: "xmark.circle", accent: Color.gray) {
                            clear()
                        }
                    }
                    .padding(CommandDesign.pagePadding)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func optionalPicker<Value: RawRepresentable & CaseIterable & Identifiable & Hashable>(
        _ title: String,
        selection: Binding<Value?>,
        cases: Value.AllCases
    ) -> some View where Value.RawValue == String, Value.AllCases: RandomAccessCollection {
        Picker(title, selection: selection) {
            Text("Any \(title)").tag(nil as Value?)
            ForEach(cases) { value in
                Text(value.rawValue).tag(Optional(value))
            }
        }
        .pickerStyle(.menu)
        .tint(accent)
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .padding(.horizontal, 12)
        .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }
}

struct ExerciseLibraryDetailView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    let definition: ExerciseDefinition
    let accent: Color
    var selectActionTitle: String?
    var selectActionIcon: String = "plus"
    var onSelect: ((ExerciseDefinition) -> Void)?

    private var hasRichGuidance: Bool {
        definition.isHCCCurated || !definition.executionSteps.isEmpty || !definition.commonMistakes.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CommandBackground(category: appModel.activeCategory)
                ScrollView {
                    VStack(alignment: .leading, spacing: CommandDesign.stackSpacing) {
                        ScreenHeader(
                            eyebrow: definition.category.rawValue.uppercased(),
                            title: definition.name,
                            subtitle: "\(definition.difficulty.rawValue) · \(definition.equipmentText)"
                        )

                        if let selectActionTitle, let onSelect {
                            PrimaryActionButton(title: selectActionTitle, icon: selectActionIcon, accent: accent) {
                                appModel.markExerciseUsed(definition)
                                onSelect(definition)
                            }
                        }

                        CommandCard {
                            VStack(alignment: .leading, spacing: 14) {
                                SectionHeader(
                                    title: definition.isHCCCurated ? "HCC coaching notes" : "Imported exercise metadata",
                                    subtitle: definition.isHCCCurated ? definition.setup : "Imported entries show available metadata only. Use HCC coaching or substitutions when form guidance is limited.",
                                    icon: "figure.strengthtraining.traditional",
                                    accent: accent
                                )

                                if !definition.isHCCCurated {
                                    Text(definition.setup)
                                        .font(.subheadline)
                                        .foregroundStyle(CommandDesign.secondaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                if !definition.executionSteps.isEmpty {
                                    ForEach(Array(definition.executionSteps.enumerated()), id: \.offset) { index, step in
                                        Label("\(index + 1). \(step)", systemImage: "checkmark.circle")
                                            .font(.subheadline)
                                            .foregroundStyle(.white.opacity(0.9))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                } else {
                                    Text("No detailed execution steps are bundled for this imported record yet.")
                                        .font(.subheadline)
                                        .foregroundStyle(CommandDesign.secondaryText)
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
                                detailLine("Movement", definition.movementPattern.rawValue)
                                detailLine("Primary", definition.muscleText)
                                if !definition.secondaryMuscles.isEmpty {
                                    detailLine("Secondary", definition.secondaryMuscles.map(\.rawValue).joined(separator: ", "))
                                }
                                HStack(spacing: 8) {
                                    StatusPill(title: definition.isShoulderFriendly ? "Shoulder-friendly" : "Shoulder caution", icon: definition.isShoulderFriendly ? "checkmark" : "exclamationmark.triangle", accent: accent)
                                    StatusPill(title: definition.isLowBackFriendly ? "Back-friendly" : "Back caution", icon: definition.isLowBackFriendly ? "checkmark" : "exclamationmark.triangle", accent: Color.gray)
                                }
                            }
                        }

                        if hasRichGuidance {
                            CommandCard {
                                VStack(alignment: .leading, spacing: 14) {
                                    SectionHeader(title: "Common mistakes", icon: "exclamationmark.triangle", accent: accent)
                                    if definition.commonMistakes.isEmpty {
                                        Text("No specific mistakes are bundled for this imported record yet.")
                                            .font(.subheadline)
                                            .foregroundStyle(CommandDesign.secondaryText)
                                    } else {
                                        ForEach(definition.commonMistakes, id: \.self) { mistake in
                                            Text("• \(mistake)")
                                                .font(.subheadline)
                                                .foregroundStyle(CommandDesign.secondaryText)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                            }
                        }

                        if !definition.variations.isEmpty || !definition.substitutions.isEmpty {
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

                        DisclosureGroup {
                            VStack(alignment: .leading, spacing: 8) {
                                detailLine("Source", definition.sourceName)
                                detailLine("License", definition.sourceLicense)
                                if let sourceURL = definition.sourceURL {
                                    detailLine("Source URL", sourceURL)
                                }
                                if let importedAt = definition.importedAt {
                                    detailLine("Imported", importedAt)
                                }
                                if !definition.aliases.isEmpty {
                                    detailLine("Aliases", definition.aliases.prefix(8).joined(separator: ", "))
                                }
                            }
                            .padding(.top, 8)
                        } label: {
                            Label("About this exercise", systemImage: "info.circle")
                                .font(.headline)
                        }
                        .tint(accent)
                        .padding(18)
                        .background(CommandDesign.surface, in: RoundedRectangle(cornerRadius: CommandDesign.cardRadius, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: CommandDesign.cardRadius, style: .continuous)
                                .stroke(CommandDesign.hairline, lineWidth: 1)
                        }
                    }
                    .padding(CommandDesign.pagePadding)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        appModel.toggleFavoriteExercise(definition)
                    } label: {
                        Label(appModel.isFavoriteExercise(definition.id) ? "Unfavorite" : "Favorite", systemImage: appModel.isFavoriteExercise(definition.id) ? "star.fill" : "star")
                    }
                    .accessibilityLabel(appModel.isFavoriteExercise(definition.id) ? "Remove \(definition.name) from favorites" : "Favorite \(definition.name)")
                }
            }
        }
        .onAppear {
            appModel.markExerciseViewed(definition)
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
