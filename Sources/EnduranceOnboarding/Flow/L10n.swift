import Foundation

/// Package strings, from `Resources/Localizable.xcstrings`
/// (en, es, pt-BR, de, fr, it, ja, ko). App copy is the app's own
/// `LocalizedStringResource`.
enum L10n {
    static var continueButton: String {
        String(localized: "button.continue", defaultValue: "Continue", bundle: .module, comment: "Primary button that moves to the next onboarding step")
    }

    static var getStarted: String {
        String(localized: "button.get_started", defaultValue: "Get started", bundle: .module, comment: "Primary button on the last onboarding step")
    }

    static var skip: String {
        String(localized: "button.skip", defaultValue: "Skip", bundle: .module, comment: "Skips the current onboarding step")
    }

    static var back: String {
        String(localized: "button.back", defaultValue: "Back", bundle: .module, comment: "Goes back to the previous onboarding step")
    }

    static var selectAllThatApply: String {
        String(localized: "question.select_all", defaultValue: "Select all that apply", bundle: .module, comment: "Hint under a multiple-choice question")
    }

    /// Visible counter, e.g. "2 of 5".
    static func progress(_ current: Int, _ total: Int) -> String {
        let format = String(localized: "progress.short", defaultValue: "%1$lld of %2$lld", bundle: .module, comment: "Onboarding progress: current step and total steps")
        return String(format: format, locale: .current, current, total)
    }

    /// VoiceOver label, e.g. "Step 2 of 5".
    static func progressAccessibility(_ current: Int, _ total: Int) -> String {
        let format = String(localized: "progress.accessibility", defaultValue: "Step %1$lld of %2$lld", bundle: .module, comment: "VoiceOver label for the onboarding progress: current step and total steps")
        return String(format: format, locale: .current, current, total)
    }

    static var bundle: Bundle { .module }
}
