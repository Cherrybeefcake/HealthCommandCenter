import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum CommandDesign {
    static let pagePadding: CGFloat = 24
    static let stackSpacing: CGFloat = 22
    static let cardRadius: CGFloat = 22
    static let innerRadius: CGFloat = 14
}

#if canImport(UIKit)
@MainActor
func dismissCommandKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

private struct CommandKeyboardDismissalModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        dismissCommandKeyboard()
                    }
                }
            }
    }
}

extension View {
    func commandKeyboardDismissal() -> some View {
        modifier(CommandKeyboardDismissalModifier())
    }
}
#else
@MainActor
func dismissCommandKeyboard() {}

extension View {
    func commandKeyboardDismissal() -> some View { self }
}
#endif

struct CommandBackground: View {
    let category: ReadinessCategory

    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.03, green: 0.04, blue: 0.06),
                category.accent.opacity(0.22),
                Color(red: 0.02, green: 0.02, blue: 0.03)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct ScreenHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .lineSpacing(2)
                .minimumScaleFactor(0.82)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var accent: Color = .white

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundStyle(accent)
                }
                Text(title)
                    .font(.headline)
            }

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct PrimaryActionButton: View {
    let title: String
    let icon: String
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 56)
                .padding(.horizontal, 12)
                .background(accent)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct SecondaryActionButton: View {
    let title: String
    let icon: String
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .padding(.horizontal, 12)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous)
                        .stroke(accent.opacity(0.45), lineWidth: 1)
                )
                .foregroundStyle(accent)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct CommandCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(20)
            .background(.white.opacity(0.075), in: RoundedRectangle(cornerRadius: CommandDesign.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CommandDesign.cardRadius, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
    }
}

typealias GlassPanel = CommandCard

struct StatusPill: View {
    let title: String
    var icon: String? = nil
    let accent: Color

    var body: some View {
        Label {
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        } icon: {
            if let icon {
                Image(systemName: icon)
            } else {
                EmptyView()
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(accent.opacity(0.14), in: Capsule())
        .overlay(
            Capsule()
                .stroke(accent.opacity(0.25), lineWidth: 1)
        )
    }
}

struct EmptyStateCard: View {
    let title: String
    let message: String
    let icon: String
    let accent: Color
    var actionTitle: String?
    var actionIcon: String = "arrow.right"
    var action: (() -> Void)?

    var body: some View {
        CommandCard {
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(accent)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let actionTitle, let action {
                    SecondaryActionButton(title: actionTitle, icon: actionIcon, accent: accent, action: action)
                }
            }
        }
    }
}

struct CheckInSliderRow: View {
    let title: String
    let lowLabel: String
    let highLabel: String
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(value)")
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
            }

            Slider(value: Binding(
                get: { Double(value) },
                set: { value = Int($0.rounded()) }
            ), in: 1...10, step: 1)

            HStack {
                Text(lowLabel)
                Spacer()
                Text(highLabel)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    var status: String? = nil
    let icon: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(accent)
            Text(value)
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let status {
                Text(status)
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 116, alignment: .topLeading)
        .padding(14)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
    }
}

struct HealthStatusPanel: View {
    let state: AppViewModel.HealthConnectionState
    let isLoading: Bool
    let accent: Color
    let refresh: () -> Void

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: iconName)
                        .font(.title3)
                        .foregroundStyle(accent)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(state.title)
                            .font(.headline)
                        Text(state.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                    }
                    Spacer(minLength: 8)
                    if isLoading {
                        ProgressView()
                    }
                }

                SecondaryActionButton(title: buttonTitle, icon: "arrow.clockwise", accent: accent, action: refresh)
            }
        }
    }

    private var iconName: String {
        switch state {
        case .ready:
            return "checkmark.seal"
        case .loading:
            return "heart.text.square"
        case .empty:
            return "tray"
        case .unavailable:
            return "exclamationmark.triangle"
        case .notRequested:
            return "heart.text.square"
        }
    }

    private var buttonTitle: String {
        switch state {
        case .notRequested:
            return "Connect Apple Health"
        default:
            return "Refresh Apple Health"
        }
    }
}
