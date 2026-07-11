import SwiftUI

struct ReadinessResultView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var showsWhy = false

    var body: some View {
        let checkIn = appModel.latestCheckIn
        let category = checkIn?.category ?? .normalTrainingDay
        let plan = appModel.todayDailyPlan

        ZStack {
            CommandBackground(category: category)

            ScrollView {
                VStack(alignment: .leading, spacing: CommandDesign.stackSpacing) {
                    Spacer(minLength: 18)

                    Text("TODAY’S COACHING CALL")
                        .font(.caption.weight(.semibold))
                        .tracking(0.7)
                        .foregroundStyle(CommandDesign.secondaryText)

                    HeroCard(accent: category.accent) {
                        VStack(alignment: .leading, spacing: 18) {
                            StatusPill(title: category.rawValue, icon: "bolt.heart.fill", accent: category.accent)

                            Text(plan.primaryFocus)
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(plan.recommendedAction)
                                .font(.body)
                                .foregroundStyle(CommandDesign.secondaryText)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)

                            Divider().overlay(CommandDesign.hairline)

                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "scope")
                                    .foregroundStyle(category.accent)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Today’s mission")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(CommandDesign.secondaryText)
                                    Text(plan.todaysMission)
                                        .font(.headline)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }

                            PrimaryActionButton(title: "Open Today’s Mission", icon: "arrow.right", accent: category.accent) {
                                appModel.goHome()
                            }
                        }
                    }

                    CommandCard {
                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeader(title: "Plan at a glance", icon: "list.bullet.rectangle", accent: category.accent)
                            planLine(icon: "dumbbell", title: "Training", detail: plan.workoutRecommendation, accent: category.accent)
                            planLine(icon: "figure.mind.and.body", title: "Recovery", detail: plan.recoveryFocus, accent: category.accent)
                            planLine(icon: "fork.knife", title: "Nutrition", detail: plan.nutritionFocus, accent: category.accent)
                        }
                    }

                    CommandCard {
                        DisclosureGroup(isExpanded: $showsWhy) {
                            VStack(alignment: .leading, spacing: 11) {
                                ForEach(reasons(for: checkIn), id: \.self) { reason in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(category.accent)
                                            .padding(.top, 2)
                                        Text(reason)
                                            .font(.subheadline)
                                            .foregroundStyle(CommandDesign.secondaryText)
                                            .lineSpacing(3)
                                    }
                                }
                            }
                            .padding(.top, 14)
                        } label: {
                            Label("Why this recommendation?", systemImage: "info.circle")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        .tint(category.accent)
                    }

                    Text("The goal is not to win the readiness score. It is to choose the right dose and keep momentum.")
                        .font(.callout)
                        .foregroundStyle(CommandDesign.secondaryText)
                        .lineSpacing(4)
                        .padding(.bottom, 28)
                }
                .padding(CommandDesign.pagePadding)
            }
        }
    }

    private func planLine(icon: String, title: String, detail: String, accent: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(accent)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(CommandDesign.secondaryText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func reasons(for checkIn: CheckIn?) -> [String] {
        guard let checkIn else { return ["The app used the available check-in and health context."] }
        if !checkIn.readinessReasons.isEmpty { return Array(checkIn.readinessReasons.prefix(4)) }
        return ["The recommendation used your energy, soreness, stress, mood, available time, pain note, and readable health metrics."]
    }
}
