#if DEBUG
import SwiftUI

/// Sample themes and a demo flow for Xcode previews and the screenshot test.
/// Not shipped in release builds.
enum OnboardingDemo {

    /// Birthday Countdown: party raspberry + candle gold on warm neutrals, SF Rounded.
    static let raspberry = OnboardingTheme(
        background: Color(light: Color(hex: 0xFBF7F4), dark: Color(hex: 0x15111A)),
        surface: Color(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x221C29)),
        surfaceSecondary: Color(light: Color(hex: 0xF3ECE7), dark: Color(hex: 0x2E2735)),
        separator: Color(light: Color(hex: 0xEAE2DC), dark: Color(hex: 0x3A3241)),
        primary: Color(light: Color(hex: 0xCF3350), dark: Color(hex: 0xD63A56)),
        onPrimary: .white,
        accent: Color(light: Color(hex: 0x8F6200), dark: Color(hex: 0xFFC764)),
        textPrimary: Color(light: Color(hex: 0x1E1724), dark: Color(hex: 0xF5F0F7)),
        textSecondary: Color(light: Color(hex: 0x625A6A), dark: Color(hex: 0xB4AABA)),
        textTertiary: Color(light: Color(hex: 0x857C8C), dark: Color(hex: 0x8E8494)),
        typography: .rounded,
        cornerRadius: 14,
        buttonHeight: 54,
        showsBackgroundGlow: true
    )

    /// Fan Noise "Midnight": lavender on deep navy. The app is dark-only; the
    /// light values here are illustrative, to show the theme in both modes.
    static let midnight = OnboardingTheme(
        background: Color(light: Color(hex: 0xF3F2FC), dark: Color(hex: 0x070B1F)),
        backgroundBottom: Color(light: Color(hex: 0xE3E1F7), dark: Color(hex: 0x121A40)),
        surface: Color(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x161E44)),
        surfaceSecondary: Color(light: Color(hex: 0xEDEBFA), dark: Color(hex: 0x1F2858)),
        separator: Color(light: Color(hex: 0xD9D6F0), dark: Color(hex: 0x2E3870)),
        primary: Color(light: Color(hex: 0x6E5CE6), dark: Color(hex: 0xA898FF)),
        onPrimary: Color(light: .white, dark: Color(hex: 0x0B0F2A)),
        accent: Color(light: Color(hex: 0xB86E1F), dark: Color(hex: 0xF3C77A)),
        textPrimary: Color(light: Color(hex: 0x14183A), dark: Color(hex: 0xF2F1FA)),
        textSecondary: Color(light: Color(hex: 0x4E5378), dark: Color(hex: 0xB4B7D4)),
        textTertiary: Color(light: Color(hex: 0x6E7398), dark: Color(hex: 0x8D92B8)),
        typography: .rounded,
        cornerRadius: 20,
        buttonHeight: 56
    )

    static let themes: [(name: String, theme: OnboardingTheme)] = [
        ("raspberry", raspberry),
        ("midnight", midnight)
    ]

    /// Every step type once, with demo copy.
    static func flow(
        theme: OnboardingTheme,
        permissionStatus: OnboardingPermissionStatus = .notDetermined,
        analytics: @escaping @MainActor (OnboardingEvent) -> Void = { print($0.name, $0.parameters) }
    ) -> OnboardingFlow {
        OnboardingFlow(
            steps: [
                .hero(
                    key: "welcome",
                    title: "Never miss a birthday again",
                    subtitle: "Countdowns for everyone you love, all in one place."
                ) {
                    DemoCountdownIllustration()
                }
                .footnote("Your list stays private on your device", systemImage: "lock.fill"),

                .question(
                    key: "who",
                    title: "Whose birthdays matter most?",
                    subtitle: "We'll set things up around them.",
                    options: [
                        OnboardingOption(id: "family", title: "Family", emoji: "🏡"),
                        OnboardingOption(id: "friends", title: "Friends", emoji: "🎉"),
                        OnboardingOption(id: "work", title: "Coworkers", emoji: "💼"),
                        OnboardingOption(id: "everyone", title: "A bit of everyone", emoji: "🌍")
                    ]
                ),

                .question(
                    key: "reminder_timing",
                    title: "When should we remind you?",
                    selection: .multiple(minimum: 1),
                    options: [
                        OnboardingOption(id: "week_before", title: "A week before", systemImage: "calendar"),
                        OnboardingOption(id: "day_before", title: "The day before", systemImage: "clock"),
                        OnboardingOption(id: "on_the_day", title: "On the day", systemImage: "gift")
                    ]
                )
                .skippable(),

                .benefits(
                    key: "benefits",
                    title: "Everything in one place",
                    items: [
                        OnboardingBenefit(systemImage: "infinity", title: "Unlimited birthdays", detail: "Family, friends and work, sorted your way."),
                        OnboardingBenefit(systemImage: "bell.badge.fill", title: "Reminders that arrive in time", detail: "A week, a day or the morning of."),
                        OnboardingBenefit(systemImage: "lock.iphone", title: "Lock Screen widgets", detail: "See the next birthday at a glance."),
                        OnboardingBenefit(systemImage: "square.and.arrow.up", title: "Export your list", detail: "Share it as CSV whenever you want.")
                    ]
                ),

                .permission(
                    key: "notifications",
                    title: "Get reminded in time",
                    subtitle: "Turn on notifications so we can tell you before each birthday. You choose when.",
                    permission: OnboardingPermission(
                        status: { permissionStatus },
                        request: { .granted }
                    )
                ) {
                    DemoNotificationIllustration()
                },

                .reviewPrePrompt(
                    title: "Enjoying it so far?",
                    subtitle: "A quick rating helps a small, independent team keep improving the app.",
                    requestReview: {}
                ),

                .loading(
                    title: "Setting up your countdowns",
                    messages: [
                        "Adding your reminder times",
                        "Preparing your widgets",
                        "Personalizing your list"
                    ],
                    duration: 3
                )
            ],
            theme: theme,
            analytics: analytics
        )
    }
}

// MARK: - Demo illustrations (built with the theme, adapt to light/dark)

struct DemoCountdownIllustration: View {
    @Environment(\.onboardingTheme) private var theme

    var body: some View {
        VStack(spacing: 12) {
            card(name: "Sofia Martinez", detail: "Turns 30 · Oct 18", days: 6, emphasized: true)
            card(name: "Liam Carter", detail: "Turns 27 · Nov 2", days: 21, emphasized: false)
            card(name: "Emma Wilson", detail: "Turns 35 · Dec 9", days: 58, emphasized: false)
                .opacity(0.7)
        }
        .padding(.horizontal, 8)
        .accessibilityHidden(true)
    }

    private func card(name: String, detail: String, days: Int, emphasized: Bool) -> some View {
        HStack(spacing: 12) {
            Text(verbatim: String(name.prefix(1)))
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(emphasized ? theme.onPrimary : theme.primary)
                .frame(width: 44, height: 44)
                .background(Circle().fill(emphasized ? theme.primary : theme.primary.opacity(0.14)))
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: name)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
                Text(verbatim: detail)
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
            }
            Spacer()
            VStack(spacing: 0) {
                Text(verbatim: "\(days)")
                    .font(.system(.title2, design: .rounded, weight: .bold).monospacedDigit())
                    .foregroundStyle(emphasized ? theme.primary : theme.textPrimary)
                Text(verbatim: "days")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius + 4, style: .continuous)
                .fill(theme.surface)
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        )
    }
}

struct DemoNotificationIllustration: View {
    @Environment(\.onboardingTheme) private var theme

    var body: some View {
        VStack(spacing: 10) {
            Text(verbatim: "9:41")
                .font(.system(size: 60, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textPrimary.opacity(0.9))
            notification(when: "1 week before", title: "Sofia turns 30 next Sunday 🎁")
            notification(when: "Tomorrow", title: "Liam's birthday is tomorrow 🎈")
                .opacity(0.75)
        }
        .accessibilityHidden(true)
    }

    private func notification(when: String, title: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "birthday.cake.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(theme.onPrimary)
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(theme.primary))
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(verbatim: "Demo App")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(theme.textSecondary)
                    Spacer()
                    Text(verbatim: when)
                        .font(.caption)
                        .foregroundStyle(theme.textTertiary)
                }
                Text(verbatim: title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.textPrimary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.surface.opacity(0.95))
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        )
    }
}

// MARK: - Previews

#Preview("Raspberry · full flow") {
    OnboardingView(flow: OnboardingDemo.flow(theme: OnboardingDemo.raspberry)) { answers in
        print("finished", answers)
    }
}

#Preview("Raspberry · dark") {
    OnboardingView(flow: OnboardingDemo.flow(theme: OnboardingDemo.raspberry)) { _ in }
        .preferredColorScheme(.dark)
}

#Preview("Midnight · full flow") {
    OnboardingView(flow: OnboardingDemo.flow(theme: OnboardingDemo.midnight)) { _ in }
        .preferredColorScheme(.dark)
}

#Preview("Midnight · light") {
    OnboardingView(flow: OnboardingDemo.flow(theme: OnboardingDemo.midnight)) { _ in }
        .preferredColorScheme(.light)
}

#Preview("Single step") {
    OnboardingView(
        flow: OnboardingFlow(
            steps: [.hero(key: "only", title: "One screen is enough", subtitle: "Single-step flows work too.", systemImage: "sparkles")],
            theme: OnboardingDemo.raspberry
        )
    ) { _ in }
}

#Preview("Accessibility XL") {
    OnboardingView(flow: OnboardingDemo.flow(theme: OnboardingDemo.raspberry)) { _ in }
        .dynamicTypeSize(.accessibility3)
}
#endif
