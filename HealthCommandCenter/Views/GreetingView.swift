import SwiftUI

struct GreetingView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var didLoadDefaults = false
    @State private var name = "Brian"
    @State private var goal = PersonalizationSettings.brianDefault.goal
    @State private var heightText = PersonalizationSettings.brianDefault.heightText
    @State private var startingWeight = "174"
    @State private var programPhase: ProgramPhase = .normalRoutine
    @State private var trainingLocation: TrainingLocation = .home
    @State private var workoutTimePreference: WorkoutTimePreference = .flexible
    @State private var equipmentConfirmed = true
    @State private var avoidsSeafood = true
    @State private var avoidsMushrooms = true
    @State private var proteinTarget = "160"
    @State private var waterTarget = "100"
    @State private var recoverySource: RecoveryDataSource = .automaticBestAvailable

    var body: some View {
        ZStack {
            CommandBackground(category: .normalTrainingDay)

            ScrollView {
                VStack(alignment: .leading, spacing: CommandDesign.stackSpacing) {
                    ScreenHeader(
                        eyebrow: "Health Command Center",
                        title: "Set the baseline.",
                        subtitle: "Confirm Brian's defaults once. You can change this later in Profile."
                    )

                    identitySection
                    scheduleSection
                    nutritionSection
                    recoverySection

                    PrimaryActionButton(title: "Start Command Center", icon: "arrow.right", accent: .white) {
                        finishOnboarding()
                    }

                    Text("Private and local-first. This setup only shapes language, targets, and daily recommendations on this device.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(CommandDesign.pagePadding)
            }
        }
        .onAppear(perform: loadDefaultsIfNeeded)
    }

    private var identitySection: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Brian's Baseline", subtitle: "Fast defaults for recomposition and consistency.", icon: "person.crop.circle", accent: .white)

                onboardingField("Name", text: $name, placeholder: "Brian")
                onboardingField("Goal", text: $goal, placeholder: "Body recomposition")

                HStack(spacing: 10) {
                    onboardingField("Height", text: $heightText, placeholder: "5'6\"")
                    onboardingField("Starting weight", text: $startingWeight, placeholder: "174")
                        .keyboardType(.decimalPad)
                }

                Toggle("Equipment confirmed", isOn: $equipmentConfirmed)
                    .font(.subheadline.weight(.semibold))
                    .tint(.white)

                Text("Adjustable dumbbells 5-55 lb, resistance bands, incline bench, mat, and work gym access.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var scheduleSection: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Routine Defaults", subtitle: "This shapes timing and pressure level.", icon: "calendar.badge.clock", accent: .white)
                onboardingPicker("Program phase", selection: $programPhase, cases: ProgramPhase.allCases)
                onboardingPicker("Training location", selection: $trainingLocation, cases: TrainingLocation.allCases)
                onboardingPicker("Workout time", selection: $workoutTimePreference, cases: WorkoutTimePreference.allCases)
            }
        }
    }

    private var nutritionSection: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Nutrition Anchors", subtitle: "Simple targets, not a rigid meal plan.", icon: "fork.knife", accent: .white)

                Toggle("Avoid seafood", isOn: $avoidsSeafood)
                    .tint(.white)
                Toggle("Avoid mushrooms", isOn: $avoidsMushrooms)
                    .tint(.white)

                HStack(spacing: 10) {
                    onboardingField("Protein", text: $proteinTarget, placeholder: "160")
                        .keyboardType(.numberPad)
                    onboardingField("Water", text: $waterTarget, placeholder: "100")
                        .keyboardType(.numberPad)
                }

                Text("Defaults: 160g protein and 100 oz water. Cronometer stays the detailed food log.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }
        }
    }

    private var recoverySection: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Recovery Source", subtitle: "Apple Health stays primary. Oura can supplement later.", icon: "heart.text.square", accent: .white)
                onboardingPicker("Recovery preference", selection: $recoverySource, cases: RecoveryDataSource.allCases)

                Text("Recommended: Automatic Best Available. Apple Health drives overlapping metrics, Oura adds readiness/sleep score/temperature context, and manual Check In is the fallback.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func onboardingField(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .font(.subheadline.weight(.semibold))
                .padding(12)
                .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func onboardingPicker<Value: CaseIterable & Hashable & RawRepresentable & Identifiable>(
        _ title: String,
        selection: Binding<Value>,
        cases: Value.AllCases
    ) -> some View where Value.RawValue == String, Value.AllCases: RandomAccessCollection {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            Picker(title, selection: selection) {
                ForEach(cases) { value in
                    Text(value.rawValue).tag(value)
                }
            }
            .pickerStyle(.menu)
            .tint(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
        }
    }

    private func loadDefaultsIfNeeded() {
        guard !didLoadDefaults else { return }
        didLoadDefaults = true
        let profile = appModel.personalizationSettings
        name = appModel.userName
        goal = profile.goal
        heightText = profile.heightText
        startingWeight = profile.startingWeightPounds.map { String(format: "%.0f", $0) } ?? ""
        programPhase = appModel.programPhase
        trainingLocation = appModel.trainingLocation
        workoutTimePreference = appModel.workoutTimePreference
        equipmentConfirmed = profile.equipmentConfirmed
        avoidsSeafood = profile.avoidsSeafood
        avoidsMushrooms = profile.avoidsMushrooms
        proteinTarget = "\(profile.proteinTargetGrams)"
        waterTarget = "\(profile.waterTargetOunces)"
        recoverySource = appModel.ouraConnectionSettings.preferredRecoverySource
    }

    private func finishOnboarding() {
        let settings = PersonalizationSettings(
            goal: goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? PersonalizationSettings.brianDefault.goal : goal,
            heightText: heightText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? PersonalizationSettings.brianDefault.heightText : heightText,
            startingWeightPounds: Double(startingWeight.trimmingCharacters(in: .whitespacesAndNewlines)),
            equipmentConfirmed: equipmentConfirmed,
            avoidsSeafood: avoidsSeafood,
            avoidsMushrooms: avoidsMushrooms,
            proteinTargetGrams: Int(proteinTarget.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 160,
            waterTargetOunces: Int(waterTarget.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 100
        )
        appModel.completeOnboarding(
            name: name,
            personalization: settings,
            programPhase: programPhase,
            trainingLocation: trainingLocation,
            workoutTimePreference: workoutTimePreference,
            recoverySource: recoverySource
        )
    }
}
