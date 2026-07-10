import SwiftUI

struct CheckInView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @StateObject var viewModel: CheckInViewModel

    var body: some View {
        ZStack {
            CommandBackground(category: .normalTrainingDay)

            ScrollView {
                VStack(alignment: .leading, spacing: CommandDesign.stackSpacing) {
                    ScreenHeader(
                        eyebrow: "Daily Check In",
                        title: "Brian, how ready are you really?",
                        subtitle: "Answer this first. Apple Health can add context, but your body report leads the call."
                    )

                    HealthStatusPanel(
                        state: appModel.healthState,
                        isLoading: appModel.isLoadingHealth,
                        accent: .white
                    ) {
                        Task { await appModel.refreshHealthData() }
                    }

                    GlassPanel {
                        VStack(spacing: 26) {
                            CheckInSliderRow(title: "Energy", lowLabel: "Flat", highLabel: "Charged", value: $viewModel.energy)
                            CheckInSliderRow(title: "Soreness", lowLabel: "Fresh", highLabel: "Heavy", value: $viewModel.soreness)
                            CheckInSliderRow(title: "Stress", lowLabel: "Calm", highLabel: "Loaded", value: $viewModel.stress)
                            CheckInSliderRow(title: "Mood", lowLabel: "Low", highLabel: "Clear", value: $viewModel.mood)
                        }
                    }

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 18) {
                            HStack {
                                Text("Available workout time")
                                    .font(.headline)
                                Spacer()
                                Text("\(viewModel.availableWorkoutMinutes) min")
                                    .font(.title3.weight(.semibold))
                                    .monospacedDigit()
                            }

                            Stepper(value: $viewModel.availableWorkoutMinutes, in: 10...120, step: 5) {
                                Text("Adjust time")
                            }

                            Text("Pain or problem today")
                                .font(.headline)
                            TextField("Optional note", text: $viewModel.painNote, axis: .vertical)
                                .lineLimit(2...5)
                                .padding(14)
                                .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius))
                        }
                    }

                    PrimaryActionButton(title: "Classify Today", icon: "sparkles", accent: .white) {
                        dismissCommandKeyboard()
                        Task { await appModel.submitCheckIn(from: viewModel) }
                    }
                    .padding(.bottom, 24)
                }
                .padding(CommandDesign.pagePadding)
            }
            .commandKeyboardDismissal()
        }
    }
}
