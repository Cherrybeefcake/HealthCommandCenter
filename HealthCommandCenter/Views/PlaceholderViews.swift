import SwiftUI

struct PlaceholderTabView: View {
    @EnvironmentObject private var appModel: AppViewModel
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        ZStack {
            CommandBackground(category: appModel.activeCategory)

            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: icon)
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(appModel.activeCategory.accent)

                Text(title)
                    .font(.system(size: 38, weight: .bold, design: .rounded))

                Text(subtitle)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
    }
}
