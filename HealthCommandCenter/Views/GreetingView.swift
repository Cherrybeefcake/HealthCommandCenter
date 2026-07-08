import SwiftUI

struct GreetingView: View {
    @EnvironmentObject private var appModel: AppViewModel

    var body: some View {
        ZStack {
            CommandBackground(category: .normalTrainingDay)

            VStack(alignment: .leading, spacing: 28) {
                Spacer()

                ScreenHeader(
                    eyebrow: "Health Command Center",
                    title: "Good morning, \(appModel.userName).",
                    subtitle: "A calmer way to choose the right version of today's training."
                )

                GlassPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Personalization")
                            .font(.headline)
                        Text("This keeps the app direct and personal without sending anything off device.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("Name", text: $appModel.userName)
                            .padding(14)
                            .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius))
                    }
                }

                PrimaryActionButton(title: "Begin Check In", icon: "arrow.right", accent: .white) {
                    appModel.completeGreeting()
                }
            }
            .padding(CommandDesign.pagePadding)
        }
    }
}
