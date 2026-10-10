import SwiftUI

/// Answers collected during the flow, keyed by the step `key` (never by index).
/// Single-choice questions hold one value, multi-choice questions hold the
/// selected option ids in the order the options were declared, and permission
/// steps hold the resulting status (`"granted"` / `"denied"`).
public typealias OnboardingAnswers = [String: [String]]

/// One screen of the onboarding. Build steps with the static factories
/// (`.hero`, `.benefits`, `.question`, `.permission`, `.reviewPrePrompt`,
/// `.custom`, `.loading`) and adjust them with the modifiers
/// (`skippable()`, `footnote(_:systemImage:)`, `buttonTitle(_:)`).
///
/// `key` must be unique and stable: it identifies the step in analytics,
/// in the answers dictionary and in persisted progress.
public struct OnboardingStep: Identifiable, Sendable {
    public let key: String
    public var id: String { key }

    let kind: Kind
    var isSkippableFlag: Bool = false
    var customButtonTitle: LocalizedStringResource?
    var footnoteValue: OnboardingFootnote?

    /// The kind of step, for apps that want to branch on it (e.g. analytics).
    public var type: OnboardingStepType { kind.type }

    /// Whether the Skip button is shown. Permission and loading steps are
    /// never skippable (Apple rejects pre-permission screens that let the user
    /// avoid the system prompt).
    public var isSkippable: Bool {
        switch kind {
        case .permission, .loading: false
        default: isSkippableFlag
        }
    }

    init(key: String, kind: Kind) {
        self.key = key
        self.kind = kind
    }
}

public enum OnboardingStepType: String, Sendable, CaseIterable {
    case hero, benefits, question, permission, reviewPrePrompt, custom, loading
}

// MARK: - Factories

extension OnboardingStep {

    /// A big visual (your real UI, an illustration…) with a headline and subtitle.
    public static func hero<Visual: View>(
        key: String,
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource? = nil,
        @ViewBuilder visual: @escaping @MainActor () -> Visual
    ) -> OnboardingStep {
        OnboardingStep(key: key, kind: .hero(Hero(
            title: title,
            subtitle: subtitle,
            symbol: nil,
            visual: { AnyView(visual()) }
        )))
    }

    /// A hero step that uses an SF Symbol as its visual.
    public static func hero(
        key: String,
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource? = nil,
        systemImage: String? = nil
    ) -> OnboardingStep {
        OnboardingStep(key: key, kind: .hero(Hero(
            title: title,
            subtitle: subtitle,
            symbol: systemImage,
            visual: nil
        )))
    }

    /// A list of benefits, each with an SF Symbol.
    public static func benefits(
        key: String,
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource? = nil,
        items: [OnboardingBenefit]
    ) -> OnboardingStep {
        OnboardingStep(key: key, kind: .benefits(Benefits(title: title, subtitle: subtitle, items: items)))
    }

    /// A single- or multi-choice question. The answer is stored under `key`
    /// as the ids of the selected options.
    ///
    /// - Parameter autoAdvance: for single choice, move on right after a tap
    ///   (disabled automatically while VoiceOver is running).
    public static func question(
        key: String,
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource? = nil,
        selection: OnboardingSelection = .single,
        options: [OnboardingOption],
        autoAdvance: Bool = false
    ) -> OnboardingStep {
        OnboardingStep(key: key, kind: .question(Question(
            title: title,
            subtitle: subtitle,
            selection: selection,
            options: options,
            autoAdvance: autoAdvance
        )))
    }

    /// Explains a permission and triggers the real system request when the
    /// user taps Continue. Skipped automatically if the permission was already
    /// granted or denied. There is no "Not now": the user always proceeds to
    /// the system prompt (App Review guideline 5.1.1).
    public static func permission(
        key: String,
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource? = nil,
        systemImage: String = "bell.badge.fill",
        permission: OnboardingPermission
    ) -> OnboardingStep {
        OnboardingStep(key: key, kind: .permission(Permission(
            title: title,
            subtitle: subtitle,
            symbol: systemImage,
            visual: nil,
            permission: permission
        )))
    }

    /// A permission step with a custom visual (e.g. a mock notification).
    public static func permission<Visual: View>(
        key: String,
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource? = nil,
        permission: OnboardingPermission,
        @ViewBuilder visual: @escaping @MainActor () -> Visual
    ) -> OnboardingStep {
        OnboardingStep(key: key, kind: .permission(Permission(
            title: title,
            subtitle: subtitle,
            symbol: "bell.badge.fill",
            visual: { AnyView(visual()) },
            permission: permission
        )))
    }

    /// Optional "Enjoying the app?" screen. Continue calls the system review
    /// request (`requestReview` environment action, or your own closure) and
    /// moves on. Not part of any flow unless the app adds it.
    public static func reviewPrePrompt(
        key: String = "review_pre_prompt",
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource? = nil,
        requestReview: (@MainActor () -> Void)? = nil
    ) -> OnboardingStep {
        OnboardingStep(key: key, kind: .reviewPrePrompt(ReviewPrePrompt(
            title: title,
            subtitle: subtitle,
            request: requestReview
        )))
    }

    /// Any SwiftUI view. Use the context to store an answer under this step's
    /// key or to advance from inside your view.
    ///
    /// - Parameters:
    ///   - showsContinueButton: show the package's Continue button below.
    ///   - requiresAnswer: keep Continue disabled until `context.setAnswer`
    ///     stored a non-empty value.
    public static func custom<Content: View>(
        key: String,
        showsContinueButton: Bool = true,
        requiresAnswer: Bool = false,
        @ViewBuilder content: @escaping @MainActor (OnboardingStepContext) -> Content
    ) -> OnboardingStep {
        OnboardingStep(key: key, kind: .custom(Custom(
            showsContinueButton: showsContinueButton,
            requiresAnswer: requiresAnswer,
            content: { AnyView(content($0)) }
        )))
    }

    /// A "building your plan" screen with a progress ring and a checklist.
    /// Advances by itself after `duration` seconds.
    public static func loading(
        key: String = "loading",
        title: LocalizedStringResource,
        messages: [LocalizedStringResource] = [],
        duration: TimeInterval = 3
    ) -> OnboardingStep {
        OnboardingStep(key: key, kind: .loading(Loading(
            title: title,
            messages: messages,
            duration: max(0, duration)
        )))
    }
}

// MARK: - Modifiers

extension OnboardingStep {
    /// Shows a Skip button on this step. Skipping stores no answer.
    /// Ignored on permission and loading steps.
    public func skippable(_ isSkippable: Bool = true) -> OnboardingStep {
        var copy = self
        copy.isSkippableFlag = isSkippable
        return copy
    }

    /// A short trust line under the button ("No account needed").
    public func footnote(_ text: LocalizedStringResource, systemImage: String? = nil) -> OnboardingStep {
        var copy = self
        copy.footnoteValue = OnboardingFootnote(text: text, systemImage: systemImage)
        return copy
    }

    /// Replaces the default button title (Continue / Get started).
    public func buttonTitle(_ title: LocalizedStringResource) -> OnboardingStep {
        var copy = self
        copy.customButtonTitle = title
        return copy
    }
}

// MARK: - Supporting types

public struct OnboardingBenefit: Identifiable, Sendable {
    public let id = UUID()
    public var systemImage: String
    public var title: LocalizedStringResource
    public var detail: LocalizedStringResource?

    public init(systemImage: String, title: LocalizedStringResource, detail: LocalizedStringResource? = nil) {
        self.systemImage = systemImage
        self.title = title
        self.detail = detail
    }
}

/// A choice in a question. `id` is the value stored in the answers, so keep
/// it stable across versions and languages (e.g. `"falling_asleep"`).
public struct OnboardingOption: Identifiable, Sendable {
    public var id: String
    public var title: LocalizedStringResource
    public var systemImage: String?
    public var emoji: String?

    public init(id: String, title: LocalizedStringResource, systemImage: String? = nil, emoji: String? = nil) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.emoji = emoji
    }
}

public enum OnboardingSelection: Sendable, Equatable {
    case single
    /// Multi choice. Continue is enabled once `minimum` options are selected;
    /// new selections are ignored past `maximum`.
    case multiple(minimum: Int = 1, maximum: Int? = nil)

    var minimum: Int {
        switch self {
        case .single: 1
        case .multiple(let minimum, _): max(0, minimum)
        }
    }
}

public struct OnboardingFootnote: Sendable {
    public var text: LocalizedStringResource
    public var systemImage: String?
}

/// Handed to `.custom` steps.
@MainActor
public struct OnboardingStepContext {
    /// The step's key.
    public let key: String
    /// What is currently stored under `key` (empty if nothing).
    public let answer: [String]
    let advanceAction: @MainActor () -> Void
    let setAnswerAction: @MainActor ([String]) -> Void

    /// Completes the step and moves to the next one.
    public func advance() { advanceAction() }

    /// Stores `values` under this step's key (an empty array removes it).
    public func setAnswer(_ values: [String]) { setAnswerAction(values) }
}

// MARK: - Internal step payloads

extension OnboardingStep {
    enum Kind {
        case hero(Hero)
        case benefits(Benefits)
        case question(Question)
        case permission(Permission)
        case reviewPrePrompt(ReviewPrePrompt)
        case custom(Custom)
        case loading(Loading)

        var type: OnboardingStepType {
            switch self {
            case .hero: .hero
            case .benefits: .benefits
            case .question: .question
            case .permission: .permission
            case .reviewPrePrompt: .reviewPrePrompt
            case .custom: .custom
            case .loading: .loading
            }
        }
    }

    struct Hero {
        let title: LocalizedStringResource
        let subtitle: LocalizedStringResource?
        let symbol: String?
        let visual: (@MainActor () -> AnyView)?
    }

    struct Benefits {
        let title: LocalizedStringResource
        let subtitle: LocalizedStringResource?
        let items: [OnboardingBenefit]
    }

    struct Question {
        let title: LocalizedStringResource
        let subtitle: LocalizedStringResource?
        let selection: OnboardingSelection
        let options: [OnboardingOption]
        let autoAdvance: Bool
    }

    struct Permission {
        let title: LocalizedStringResource
        let subtitle: LocalizedStringResource?
        let symbol: String
        let visual: (@MainActor () -> AnyView)?
        let permission: OnboardingPermission
    }

    struct ReviewPrePrompt {
        let title: LocalizedStringResource
        let subtitle: LocalizedStringResource?
        let request: (@MainActor () -> Void)?
    }

    struct Custom {
        let showsContinueButton: Bool
        let requiresAnswer: Bool
        let content: @MainActor (OnboardingStepContext) -> AnyView
    }

    struct Loading {
        let title: LocalizedStringResource
        let messages: [LocalizedStringResource]
        let duration: TimeInterval
    }
}
