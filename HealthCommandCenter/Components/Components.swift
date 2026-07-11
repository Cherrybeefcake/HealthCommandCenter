import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum CommandDesign {
    static let pagePadding: CGFloat = 20
    static let stackSpacing: CGFloat = 18
    static let cardRadius: CGFloat = 24
    static let innerRadius: CGFloat = 16
    static let compactRadius: CGFloat = 12
    static let hairline = Color.white.opacity(0.09)
    static let surface = Color.white.opacity(0.055)
    static let elevatedSurface = Color.white.opacity(0.085)
    static let secondaryText = Color.white.opacity(0.62)
    static let tertiaryText = Color.white.opacity(0.45)
}

enum CommandPalette {
    static let background = Color(red: 0.025, green: 0.03, blue: 0.045)
    static let backgroundRaised = Color(red: 0.045, green: 0.052, blue: 0.072)
    static let brand = Color(red: 0.58, green: 0.86, blue: 0.98)
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
                    Button("Done") { dismissCommandKeyboard() }
                }
            }
    }
}

extension View {
    func commandKeyboardDismissal() -> some View { modifier(CommandKeyboardDismissalModifier()) }
}
#else
@MainActor func dismissCommandKeyboard() {}
extension View { func commandKeyboardDismissal() -> some View { self } }
#endif

struct CommandBackground: View {
    let category: ReadinessCategory

    var body: some View {
        ZStack {
            CommandPalette.background
            RadialGradient(
                colors: [category.accent.opacity(0.16), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 460
            )
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.28)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

struct ScreenHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(eyebrow)
                .font(.caption.weight(.semibold))
                .tracking(0.6)
                .foregroundStyle(CommandDesign.secondaryText)
            Text(title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .lineSpacing(1)
                .minimumScaleFactor(0.78)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(CommandDesign.secondaryText)
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
            HStack(spacing: 9) {
                if let icon {
                    Image(systemName: icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(accent)
                }
                Text(title).font(.headline)
            }
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(CommandDesign.secondaryText)
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
            HStack(spacing: 9) {
                Text(title)
                Image(systemName: icon)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .padding(.horizontal, 16)
            .background(accent, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
            .foregroundStyle(Color.black.opacity(0.84))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .medium), trigger: title)
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
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 50)
                .padding(.horizontal, 14)
                .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous)
                        .stroke(accent.opacity(0.24), lineWidth: 1)
                }
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
            .padding(18)
            .background(CommandDesign.surface, in: RoundedRectangle(cornerRadius: CommandDesign.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CommandDesign.cardRadius, style: .continuous)
                    .stroke(CommandDesign.hairline, lineWidth: 1)
            }
    }
}

typealias GlassPanel = CommandCard

struct CommandSection<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    let accent: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title, subtitle: subtitle, icon: icon, accent: accent)
            content
        }
    }
}

struct CommandDivider: View {
    var body: some View {
        Divider().overlay(CommandDesign.hairline)
    }
}

private struct CommandFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .padding(12)
            .frame(minHeight: 46)
            .background(CommandDesign.elevatedSurface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous)
                    .stroke(CommandDesign.hairline, lineWidth: 1)
            }
    }
}

extension View {
    func commandFieldStyle() -> some View {
        modifier(CommandFieldStyle())
    }
}

struct HeroCard<Content: View>: View {
    let accent: Color
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(22)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(CommandPalette.backgroundRaised)
                    .overlay(alignment: .topTrailing) {
                        Circle()
                            .fill(accent.opacity(0.19))
                            .frame(width: 180, height: 180)
                            .blur(radius: 30)
                            .offset(x: 60, y: -75)
                            .clipped()
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(accent.opacity(0.18), lineWidth: 1)
            }
    }
}

struct StatusPill: View {
    let title: String
    var icon: String? = nil
    let accent: Color

    var body: some View {
        Label {
            Text(title).lineLimit(1).minimumScaleFactor(0.78)
        } icon: {
            if let icon { Image(systemName: icon) }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(accent)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(accent.opacity(0.12), in: Capsule())
        .overlay { Capsule().stroke(accent.opacity(0.22), lineWidth: 1) }
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
                Image(systemName: icon).font(.title3).foregroundStyle(accent)
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.headline)
                    Text(message).font(.subheadline).foregroundStyle(CommandDesign.secondaryText).lineSpacing(3)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Text("\(value)").font(.title3.weight(.bold)).monospacedDigit().foregroundStyle(.white)
            }
            Slider(value: Binding(get: { Double(value) }, set: { value = Int($0.rounded()) }), in: 1...10, step: 1)
            HStack {
                Text(lowLabel)
                Spacer()
                Text(highLabel)
            }
            .font(.caption)
            .foregroundStyle(CommandDesign.secondaryText)
        }
    }
}

struct RatingSelector: View {
    let title: String
    let lowLabel: String
    let highLabel: String
    @Binding var value: Int
    var accent: Color = CommandPalette.brand

    private let options = [2, 4, 6, 8, 10]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Text(label).font(.subheadline.weight(.semibold)).foregroundStyle(accent)
            }
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    Button {
                        value = option
                    } label: {
                        Text("\(option)")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(selectedOption == option ? accent : CommandDesign.elevatedSurface)
                            .foregroundStyle(selectedOption == option ? Color.black.opacity(0.82) : .white)
                            .clipShape(RoundedRectangle(cornerRadius: CommandDesign.compactRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack {
                Text(lowLabel)
                Spacer()
                Text(highLabel)
            }
            .font(.caption2)
            .foregroundStyle(CommandDesign.secondaryText)
        }
    }

    private var label: String {
        switch value {
        case ...2: return lowLabel
        case ...4: return "Low"
        case ...6: return "Okay"
        case ...8: return "Good"
        default: return highLabel
        }
    }

    private var selectedOption: Int {
        options.min { abs($0 - value) < abs($1 - value) } ?? value
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    var status: String? = nil
    let icon: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Image(systemName: icon).font(.title3).foregroundStyle(accent)
            Text(value).font(.title3.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.72)
            Text(title).font(.caption).foregroundStyle(CommandDesign.secondaryText)
            if let status {
                Text(status).font(.caption2).foregroundStyle(CommandDesign.secondaryText).lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 116, alignment: .topLeading)
        .padding(14)
        .background(CommandDesign.surface, in: RoundedRectangle(cornerRadius: CommandDesign.innerRadius, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: CommandDesign.innerRadius).stroke(CommandDesign.hairline) }
    }
}

struct HealthStatusPanel: View {
    let state: AppViewModel.HealthConnectionState
    let isLoading: Bool
    let accent: Color
    let refresh: () -> Void

    var body: some View {
        CommandCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: iconName)
                        .font(.title3)
                        .foregroundStyle(accent)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(state.title).font(.headline)
                        Text(state.detail).font(.subheadline).foregroundStyle(CommandDesign.secondaryText).lineSpacing(3)
                    }
                    Spacer(minLength: 8)
                    if isLoading { ProgressView() }
                }
                SecondaryActionButton(title: buttonTitle, icon: "arrow.clockwise", accent: accent, action: refresh)
            }
        }
    }

    private var iconName: String {
        switch state {
        case .ready: return "checkmark.seal.fill"
        case .loading: return "heart.text.square"
        case .empty: return "tray"
        case .unavailable: return "exclamationmark.triangle"
        case .notRequested: return "heart.text.square"
        }
    }

    private var buttonTitle: String { state == .notRequested ? "Connect Apple Health" : "Refresh Apple Health" }
}
