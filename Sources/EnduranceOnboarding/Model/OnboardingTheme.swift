import SwiftUI
import UIKit

/// Visual tokens. Build it from your app's design tokens: pass the same
/// `Color("…")` assets your app uses (with light/dark variants) and they
/// resolve automatically.
public struct OnboardingTheme: Sendable {
    /// Screen background.
    public var background: Color
    /// Optional second background color; draws a top-to-bottom gradient.
    public var backgroundBottom: Color?
    /// Cards and option rows.
    public var surface: Color
    /// Nested surfaces (icon badges, empty indicators).
    public var surfaceSecondary: Color
    /// Hairlines, unselected borders, inactive progress capsules.
    public var separator: Color
    /// Main brand color: primary button fill, selection, active progress.
    public var primary: Color
    /// Text and icons on `primary`.
    public var onPrimary: Color
    /// Secondary highlight: benefit icons, stars, checkmarks.
    public var accent: Color
    public var textPrimary: Color
    public var textSecondary: Color
    public var textTertiary: Color
    public var typography: OnboardingTypography
    /// Corner radius of buttons, cards and option rows (continuous corners).
    public var cornerRadius: CGFloat
    /// Minimum height of the primary button (grows with Dynamic Type).
    public var buttonHeight: CGFloat
    /// Two soft blurred glows (primary + accent) behind the content.
    public var showsBackgroundGlow: Bool
    /// Force a color scheme (e.g. `.dark` for dark-only apps). `nil` follows the system.
    public var colorScheme: ColorScheme?

    public init(
        background: Color,
        backgroundBottom: Color? = nil,
        surface: Color,
        surfaceSecondary: Color,
        separator: Color,
        primary: Color,
        onPrimary: Color = .white,
        accent: Color,
        textPrimary: Color,
        textSecondary: Color,
        textTertiary: Color,
        typography: OnboardingTypography = .system(),
        cornerRadius: CGFloat = 16,
        buttonHeight: CGFloat = 56,
        showsBackgroundGlow: Bool = false,
        colorScheme: ColorScheme? = nil
    ) {
        self.background = background
        self.backgroundBottom = backgroundBottom
        self.surface = surface
        self.surfaceSecondary = surfaceSecondary
        self.separator = separator
        self.primary = primary
        self.onPrimary = onPrimary
        self.accent = accent
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.textTertiary = textTertiary
        self.typography = typography
        self.cornerRadius = cornerRadius
        self.buttonHeight = buttonHeight
        self.showsBackgroundGlow = showsBackgroundGlow
        self.colorScheme = colorScheme
    }

    /// System colors and the app's accent color. Good for a first pass.
    public static let `default` = OnboardingTheme(
        background: Color(uiColor: .systemBackground),
        surface: Color(uiColor: .secondarySystemBackground),
        surfaceSecondary: Color(uiColor: .tertiarySystemFill),
        separator: Color(uiColor: .separator),
        primary: .accentColor,
        accent: .accentColor,
        textPrimary: Color(uiColor: .label),
        textSecondary: Color(uiColor: .secondaryLabel),
        textTertiary: Color(uiColor: .tertiaryLabel)
    )
}

/// Fonts used by the onboarding. Use text styles so they scale with Dynamic Type.
public struct OnboardingTypography: Sendable {
    /// Step titles.
    public var title: Font
    /// Option and benefit titles.
    public var headline: Font
    /// Subtitles.
    public var body: Font
    /// Benefit details.
    public var callout: Font
    /// Footnotes and small labels.
    public var footnote: Font
    /// Primary button.
    public var button: Font
    /// Large numbers (loading percentage).
    public var number: Font

    public init(title: Font, headline: Font, body: Font, callout: Font, footnote: Font, button: Font, number: Font) {
        self.title = title
        self.headline = headline
        self.body = body
        self.callout = callout
        self.footnote = footnote
        self.button = button
        self.number = number
    }

    /// System fonts. `.rounded` gives SF Rounded titles, buttons and numbers
    /// (body text stays SF Pro for readability).
    public static func system(design: Font.Design = .default) -> OnboardingTypography {
        OnboardingTypography(
            title: .system(.largeTitle, design: design, weight: .bold),
            headline: .system(.headline, design: design),
            body: .body,
            callout: .callout,
            footnote: .footnote.weight(.medium),
            button: .system(.headline, design: design, weight: .semibold),
            number: .system(.title, design: design, weight: .bold).monospacedDigit()
        )
    }

    /// SF Rounded for display text.
    public static let rounded = system(design: .rounded)
}

extension Color {
    /// A color with explicit light and dark values, for apps that don't keep
    /// their tokens in an asset catalog.
    public init(light: Color, dark: Color) {
        let lightColor = UIColor(light)
        let darkColor = UIColor(dark)
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? darkColor : lightColor
        })
    }

    /// `Color(hex: 0xCF3350)`.
    public init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

extension EnvironmentValues {
    @Entry var onboardingTheme: OnboardingTheme = .default
    /// Freezes animations at a representative frame (previews, screenshots).
    @Entry var onboardingSnapshotMode: Bool = false
}
