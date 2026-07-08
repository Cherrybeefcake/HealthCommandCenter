import SwiftUI

struct PlanView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var selectedWorkoutID = StarterWorkoutLibrary.workouts[0].id

    private var selectedWorkout: WorkoutPlan {
        StarterWorkoutLibrary.workouts.first { $0.id == selectedWorkoutID } ?? StarterWorkoutLibrary.workouts[0]
    }

    private var recommendedVersionType: WorkoutVersionType {
        guard appModel.hasCheckedInToday else { return .bareMinimum }
        return StarterWorkoutLibrary.recommendedVersion(for: appModel.activeCategory)
    }

    private var selectedVersion: WorkoutVersion {
        selectedWorkout.version(recommendedVersionType)
    }

    var body: some View {
        let category = appModel.activeCategory
        let dailyPlan = appModel.todayDailyPlan

        ZStack {
            CommandBackground(category: category)

            ScrollView {
                VStack(alignment: .leading, spacing: CommandDesign.stackSpacing) {
                    ScreenHeader(
                        eyebrow: "Plan",
                        title: "Brian's weekly base",
                        subtitle: "Three full-body sessions, scaled by today's readiness so consistency stays protected."
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
                    weeklyPlanSelector(category: category)
                    workoutVersionPanel(category: category)
                }
                .padding(CommandDesign.pagePadding)
            }
        }
    }

    private func recommendationPanel(category: ReadinessCategory, dailyPlan: DailyPlan) -> some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    title: "Daily Plan Generator",
                    subtitle: dailyPlan.title,
                    icon: "sparkles",
                    accent: category.accent
                )

                Text(dailyPlan.workoutRecommendation)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(category.accent)
                    .fixedSize(horizontal: false, vertical: true)

                Text(dailyPlan.recommendedAction)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()
                    .overlay(.white.opacity(0.16))

                VStack(alignment: .leading, spacing: 8) {
                    planVersionLine("Full", dailyPlan.fullVersionText, category.accent)
                    planVersionLine("Short", dailyPlan.shortVersionText, category.accent)
                    planVersionLine("Minimum", dailyPlan.bareMinimumVersionText, category.accent)
                }
            }
        }
    }

    private func planVersionLine(_ title: String, _ text: String, _ accent: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            StatusPill(title: title, accent: accent)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func weeklyPlanSelector(category: ReadinessCategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Weekly structure",
                subtitle: "Pick the session. The version still adapts from today's readiness.",
                icon: "calendar",
                accent: category.accent
            )

            ForEach(StarterWorkoutLibrary.workouts) { workout in
                Button {
                    selectedWorkoutID = workout.id
                } label: {
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(workout.weeklySlot)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(workout.title)
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text(workout.focus)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        Image(systemName: selectedWorkoutID == workout.id ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedWorkoutID == workout.id ? category.accent : .secondary)
                    }
                    .padding(16)
                    .background(.white.opacity(selectedWorkoutID == workout.id ? 0.11 : 0.06), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous)
                            .stroke(selectedWorkoutID == workout.id ? category.accent.opacity(0.7) : .white.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Select \(workout.title)")
            }
        }
    }

    private func workoutVersionPanel(category: ReadinessCategory) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedWorkout.title)
                        .font(.title2.weight(.bold))
                    Text("\(selectedVersion.type.rawValue) · \(selectedVersion.duration)")
                        .font(.subheadline)
                        .foregroundStyle(category.accent)
                }
                Spacer()
            }

            Text(selectedVersion.intention)
                .foregroundStyle(.secondary)
                .lineSpacing(4)

            WorkoutSessionSummary(
                workout: selectedWorkout,
                accent: category.accent
            )

            ForEach(selectedVersion.sections) { section in
                workoutSectionView(section, workout: selectedWorkout, version: selectedVersion, accent: category.accent)
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

}

private struct ExercisePlanCard: View {
    @EnvironmentObject private var appModel: AppViewModel
    let workout: WorkoutPlan
    let version: WorkoutVersion
    let exercise: ExercisePlan
    let accent: Color
    @State private var isExpanded = false
    @State private var isProgressExpanded = false
    @State private var isLogging = false

    var body: some View {
        let todayLogs = appModel.todayExerciseLogs(for: exercise.id, exerciseName: exercise.name)
        let suggestion = appModel.progressionSuggestion(for: exercise, workout: workout)
        let progressSummary = appModel.exerciseProgressSummary(for: exercise)

        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(exercise.name)
                            .font(.headline)
                        Text(exercise.equipment)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        isExpanded.toggle()
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
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)

                if exercise.isLoggable {
                    CoachSuggestionPanel(suggestion: suggestion, accent: accent)
                    ExerciseProgressSummaryPanel(
                        summary: progressSummary,
                        isExpanded: $isProgressExpanded,
                        accent: accent
                    )
                }

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
                                .foregroundStyle(.secondary)
                        }

                        VStack(spacing: 8) {
                            ForEach(Array(todayLogs.enumerated()), id: \.element.id) { index, log in
                                TodaySetRow(
                                    setNumber: index + 1,
                                    log: log,
                                    accent: accent
                                ) {
                                    appModel.deleteExerciseLog(log)
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                } else if exercise.isLoggable {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(accent)
                            .frame(width: 20)
                        Text("No sets logged today. Log the first honest set and this card will keep today's work visible.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                    }
                    .padding(12)
                    .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                }

                if let lastLog = appModel.lastExerciseLog(for: exercise.id, exerciseName: exercise.name) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(accent)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Last time")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(lastLog.summary)
                                .font(.subheadline)
                            Text(lastLog.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                }

                if isExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        detailList("Form cues", exercise.formCues)
                        detailList("Common mistakes", exercise.commonMistakes)
                        detailList("Muscles targeted", exercise.musclesTargeted)
                    }
                    .padding(.top, 2)
                }

                if exercise.isLoggable {
                    SecondaryActionButton(title: todayLogs.isEmpty ? "Log Exercise" : "Log Next Set", icon: "square.and.pencil", accent: accent) {
                        isLogging = true
                    }
                }
            }
        }
        .sheet(isPresented: $isLogging) {
            ExerciseLogSheet(
                workout: workout,
                version: version,
                exercise: exercise,
                accent: accent
            )
            .environmentObject(appModel)
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
            .background(.white.opacity(0.08), in: Capsule())
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
                                    .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 14))

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
                                    .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 14))
                            }
                        }

                        PrimaryActionButton(title: "Save Log", icon: "checkmark", accent: accent) {
                            save()
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

    private func save() {
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
        dismiss()
    }
}
