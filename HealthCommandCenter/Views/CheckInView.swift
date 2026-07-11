import SwiftUI

struct CheckInView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @StateObject var viewModel: CheckInViewModel

    private let timeOptions = [10, 20, 30, 45, 60]

    var body: some View {
        ZStack {
            CommandBackground(category: .normalTrainingDay)

            ScrollView {
                VStack(alignment: .leading, spacing: CommandDesign.stackSpacing) {
                    ScreenHeader(
                        eyebrow: "DAILY CHECK-IN • ABOUT 30 SECONDS",
                        title: "How are you showing up today?",
                        subtitle: "Your body report makes the final call. Apple Health adds context when it is available."
                    )

                    HealthStatusPanel(
                        state: appModel.healthState,
                        isLoading: appModel.isLoadingHealth,
                        accent: CommandPalette.brand
                    ) {
                        Task { await appModel.refreshHealthData() }
                    }

                    CommandCard {
                        VStack(alignment: .leading, spacing: 24) {
                            SectionHeader(
                                title: "Your body report",
                                subtitle: "Choose the closest answer. Honest and approximate beats perfect.",
                                icon: "waveform.path.ecg",
                                accent: CommandPalette.brand
                            )
                            RatingSelector(title: "Energy", lowLabel: "Drained", highLabel: "Excellent", value: $viewModel.energy)
                            Divider().overlay(CommandDesign.hairline)
                            RatingSelector(title: "Soreness", lowLabel: "Fresh", highLabel: "Very sore", value: $viewModel.soreness)
                            Divider().overlay(CommandDesign.hairline)
                            RatingSelector(title: "Stress", lowLabel: "Calm", highLabel: "Overloaded", value: $viewModel.stress)
                            Divider().overlay(CommandDesign.hairline)
                            RatingSelector(title: "Mood", lowLabel: "Low", highLabel: "Excellent", value: $viewModel.mood)
                        }
                    }

                    CommandCard {
                        VStack(alignment: .leading, spacing: 18) {
                            SectionHeader(
                                title: "Today’s constraints",
                                subtitle: "The plan should fit the day you actually have.",
                                icon: "clock",
                                accent: CommandPalette.brand
                            )

                            Text("Available workout time")
                                .font(.headline)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 9) {
                                ForEach(timeOptions, id: \.self) { minutes in
                                    Button {
                                        viewModel.availableWorkoutMinutes = minutes
                                    } label: {
                                        Text("\(minutes) min")
                                            .font(.subheadline.weight(.semibold))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 44)
                                            .background(viewModel.availableWorkoutMinutes == minutes ? CommandPalette.brand : CommandDesign.elevatedSurface)
                                            .foregroundStyle(viewModel.availableWorkoutMinutes == minutes ? Color.black.opacity(0.82) : .white)
                                            .clipShape(RoundedRectangle(cornerRadius: CommandDesign.compactRadius, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            VStack(alignment: .leading, spacing: 9) {
                                Text("Pain, illness, or a problem to work around")
                                    .font(.headline)
                                TextField("Optional note — for example, right shoulder is sore", text: $viewModel.painNote, axis: .vertical)
                                    .lineLimit(2...5)
                                    .padding(14)
                                    .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous)
                                            .stroke(CommandDesign.hairline)
                                    }
                            }
                        }
                    }

                    PrimaryActionButton(title: "Build Today’s Plan", icon: "arrow.right", accent: CommandPalette.brand) {
                        dismissCommandKeyboard()
                        Task { await appModel.submitCheckIn(from: viewModel) }
                    }
                    .padding(.bottom, 28)
                }
                .padding(CommandDesign.pagePadding)
            }
            .commandKeyboardDismissal()
        }
    }
}
