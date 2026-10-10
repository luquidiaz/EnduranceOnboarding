import Foundation

/// The whole onboarding: steps, look and analytics.
///
/// ```swift
/// let flow = OnboardingFlow(
///     steps: [.hero(…), .question(…), .permission(…)],
///     theme: .birthday,
///     analytics: { event in Analytics.logEvent(event.name, parameters: event.parameters) }
/// )
/// OnboardingView(flow: flow) { answers in showPaywall(answers) }
/// ```
public struct OnboardingFlow: Sendable {
    public var steps: [OnboardingStep]
    public var theme: OnboardingTheme
    public var options: OnboardingOptions
    public var analytics: @MainActor (OnboardingEvent) -> Void

    public init(
        steps: [OnboardingStep],
        theme: OnboardingTheme = .default,
        options: OnboardingOptions = OnboardingOptions(),
        analytics: @escaping @MainActor (OnboardingEvent) -> Void = { _ in }
    ) {
        assert(
            Set(steps.map(\.key)).count == steps.count,
            "OnboardingFlow: step keys must be unique (\(steps.map(\.key)))"
        )
        self.steps = steps
        self.theme = theme
        self.options = options
        self.analytics = analytics
    }
}

public struct OnboardingOptions: Sendable {
    /// Progress capsules at the top (hidden anyway for single-step flows).
    public var showsProgress: Bool
    /// Back button from the second step on.
    public var allowsBack: Bool
    /// Light haptics on selection and on step changes.
    public var hapticsEnabled: Bool
    /// Resume an interrupted onboarding where the user left it. `nil` = off.
    public var persistence: OnboardingPersistence?

    public init(
        showsProgress: Bool = true,
        allowsBack: Bool = true,
        hapticsEnabled: Bool = true,
        persistence: OnboardingPersistence? = nil
    ) {
        self.showsProgress = showsProgress
        self.allowsBack = allowsBack
        self.hapticsEnabled = hapticsEnabled
        self.persistence = persistence
    }
}

/// Stores the current step key and the answers so far; cleared on finish.
/// Whether onboarding was completed (`hasCompletedOnboarding`) stays the
/// app's responsibility.
public struct OnboardingPersistence: Sendable {
    let key: String
    /// UserDefaults is documented as thread-safe; it is only touched on the main actor anyway.
    nonisolated(unsafe) let store: UserDefaults

    public static func userDefaults(key: String = "endurance_onboarding_progress", store: UserDefaults = .standard) -> OnboardingPersistence {
        OnboardingPersistence(key: key, store: store)
    }

    struct State: Codable, Equatable {
        var stepKey: String
        var answers: OnboardingAnswers
    }

    func load() -> State? {
        guard let data = store.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(State.self, from: data)
    }

    func save(_ state: State) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        store.set(data, forKey: key)
    }

    func clear() {
        store.removeObject(forKey: key)
    }
}
