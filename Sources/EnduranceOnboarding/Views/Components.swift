import SwiftUI

// MARK: - Progress

/// Capsules: the current step is wide, done steps are filled. Switches to a
/// continuous bar for long flows so it never overflows.
struct OnboardingProgressIndicator: View {
    let index: Int
    let count: Int
    @Environment(\.onboardingTheme) private var theme

    var body: some View {
        Group {
            if count > 10 {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(theme.separator)
                        Capsule()
                            .fill(theme.primary)
                            .frame(width: proxy.size.width * Double(index + 1) / Double(max(count, 1)))
                    }
                }
                .frame(width: 160, height: 6)
            } else {
                HStack(spacing: 6) {
                    ForEach(0..<max(count, 1), id: \.self) { position in
                        Capsule()
                            .fill(position <= index ? theme.primary : theme.separator)
                            .frame(width: position == index ? 24 : 8, height: 8)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.progressAccessibility(index + 1, count))
    }
}

// MARK: - Buttons

struct OnboardingPrimaryButtonStyle: ButtonStyle {
    @Environment(\.onboardingTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.typography.button)
            .foregroundStyle(theme.onPrimary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: theme.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                    .fill(theme.primary)
            )
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

// MARK: - Text

/// Title + subtitle used by every built-in step.
struct StepHeader: View {
    let title: LocalizedStringResource
    let subtitle: LocalizedStringResource?
    var subtitleFallback: String?
    var alignment: TextAlignment = .center
    @Environment(\.onboardingTheme) private var theme

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(theme.typography.title)
                .foregroundStyle(theme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.textSecondary)
            } else if let subtitleFallback {
                Text(subtitleFallback)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .multilineTextAlignment(alignment)
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .center)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// Symbol in a filled circle, for steps without a custom visual.
struct SymbolBadge: View {
    let systemImage: String
    var size: CGFloat = 112
    @Environment(\.onboardingTheme) private var theme

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundStyle(theme.onPrimary)
            .frame(width: size, height: size)
            .background(Circle().fill(theme.primary))
            .background(Circle().fill(theme.primary.opacity(0.18)).padding(-18))
            .accessibilityHidden(true)
    }
}

// MARK: - Background

struct OnboardingBackground: View {
    @Environment(\.onboardingTheme) private var theme

    var body: some View {
        ZStack {
            if let bottom = theme.backgroundBottom {
                LinearGradient(colors: [theme.background, bottom], startPoint: .top, endPoint: .bottom)
            } else {
                theme.background
            }
            if theme.showsBackgroundGlow {
                Circle()
                    .fill(theme.primary.opacity(0.16))
                    .frame(width: 360, height: 360)
                    .blur(radius: 90)
                    .offset(x: -120, y: -260)
                Circle()
                    .fill(theme.accent.opacity(0.14))
                    .frame(width: 300, height: 300)
                    .blur(radius: 90)
                    .offset(x: 150, y: -60)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

// MARK: - Layout

/// Fits the content without scrolling when it fits, scrolls otherwise
/// (large Dynamic Type sizes, many options).
struct FittingScroll<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ViewThatFits(in: .vertical) {
            content
                .frame(maxHeight: .infinity)
            ScrollView {
                content.padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
    }
}
