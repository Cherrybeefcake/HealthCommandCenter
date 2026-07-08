import SwiftUI

struct ReadinessResultView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var showsWhy = false

    var body: some View {
        let checkIn = appModel.latestCheckIn
        let category = checkIn?.category ?? .normalTrainingDay

        ZStack {
            CommandBackground(category: category)

            ScrollView {
                VStack(alignment: .leading, spacing: CommandDesign.stackSpacing) {
                    Spacer(minLength: 34)

                    ScreenHeader(
                        eyebrow: "Today's readiness",
                        title: category.rawValue,
                        subtitle: "Recommended action first. No score-chasing today."
                    )

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Recommended action", icon: "sparkles", accent: category.accent)

                            Text(category.recommendedAction)
                                .font(.title2.weight(.semibold))
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)

                            Divider()
                                .overlay(.white.opacity(0.18))

                            Text(category.missionTitle)
                                .font(.headline)
                            Text(category.missionBody)
                                .foregroundStyle(.secondary)
                                .lineSpacing(4)
                        }
                    }

                    GlassPanel {
                        DisclosureGroup(isExpanded: $showsWhy) {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(reasons(for: checkIn), id: \.self) { reason in
                                    HStack(alignment: .top, spacing: 10) {
                                        Circle()
                                            .fill(category.accent)
                                            .frame(width: 6, height: 6)
                                            .padding(.top, 7)
                                        Text(reason)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .lineSpacing(3)
                                    }
                                }
                            }
                            .padding(.top, 12)
                        } label: {
                            Label("Why this category?", systemImage: "questionmark.circle")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        .tint(category.accent)
                    }

                    Text("Brian, the aim is to choose the right version of the day before the day chooses for you.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)

                    PrimaryActionButton(title: "Open Today's Mission", icon: "house", accent: category.accent) {
                        appModel.goHome()
                    }
                    .padding(.bottom, 24)
                }
                .padding(CommandDesign.pagePadding)
            }
        }
    }

    private func reasons(for checkIn: CheckIn?) -> [String] {
        guard let checkIn else {
            return ["The app used the available check-in and health context."]
        }

        if !checkIn.readinessReasons.isEmpty {
            return checkIn.readinessReasons
        }

        return ["The app used your energy, soreness, stress, mood, available time, pain note, and any readable health metrics."]
    }
}
