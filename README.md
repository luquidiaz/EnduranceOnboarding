# EnduranceOnboarding

One onboarding for every Endurance Apptitude app, built to lead into the paywall.

- Typed Swift configuration (no JSON). Answers are keyed by the step `key`, never by index.
- Step types: hero, benefits, question (single/multi), permission (real system prompt), review pre-prompt, custom view and loading.
- Theming from your app's own tokens and Color assets, so light and dark mode follow your app.
- Package strings in 8 languages (en, es, pt-BR, de, fr, it, ja, ko). Your copy is `LocalizedStringResource`, so it lives in your app's String Catalog.
- Analytics hooks with Firebase-ready names and parameters.
- Dynamic Type, VoiceOver, Reduce Motion and optional haptics.
- iOS 17+, Swift 6 strict concurrency, no dependencies. RevenueCat stays in the app: `onFinish` hands you the answers so you can present the paywall.

## Install

In Xcode, go to File → Add Package Dependencies and use `https://github.com/luquidiaz/EnduranceOnboarding`. Set the rule to **Exact Version** (for example `0.1.1`). See [CHANGELOG.md](CHANGELOG.md).

## Integration

```swift
import EnduranceOnboarding
import FirebaseAnalytics
import SwiftUI

extension OnboardingTheme {
    // Built from the app's own tokens (Color assets with light/dark variants).
    static let app = OnboardingTheme(
        background: Theme.Colors.background,
        surface: Theme.Colors.surface,
        surfaceSecondary: Theme.Colors.surfaceSecondary,
        separator: Theme.Colors.separator,
        primary: Theme.Colors.brandFill,
        onPrimary: Theme.Colors.onBrand,
        accent: Theme.Colors.accent,
        textPrimary: Theme.Colors.textPrimary,
        textSecondary: Theme.Colors.textSecondary,
        textTertiary: Theme.Colors.textTertiary,
        typography: .rounded,          // SF Rounded titles/buttons
        cornerRadius: 14,
        showsBackgroundGlow: true
    )
}

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showPaywall = false

    var body: some View {
        if hasCompletedOnboarding {
            MainView()
        } else {
            OnboardingView(flow: flow) { answers in
                // answers: ["use_case": ["family"], "notifications": ["granted"], ...]
                Personalization.apply(answers)
                showPaywall = true            // RevenueCat paywall lives in the app
            }
            .sheet(isPresented: $showPaywall, onDismiss: { hasCompletedOnboarding = true }) {
                PaywallScreen(source: "onboarding")
            }
        }
    }

    private var flow: OnboardingFlow {
        OnboardingFlow(
            steps: [
                .hero(key: "welcome",
                      title: "Never miss a birthday again",
                      subtitle: "Countdowns for everyone you love, all in one place.") {
                    CountdownIllustration()        // your real UI
                }
                .footnote("Your list stays private on your device", systemImage: "lock.fill"),

                .question(key: "use_case",
                          title: "Whose birthdays matter most?",
                          options: [
                              OnboardingOption(id: "family", title: "Family", emoji: "🏡"),
                              OnboardingOption(id: "friends", title: "Friends", emoji: "🎉"),
                          ]),

                .question(key: "reminder_timing",
                          title: "When should we remind you?",
                          selection: .multiple(minimum: 1),
                          options: [
                              OnboardingOption(id: "week_before", title: "A week before", systemImage: "calendar"),
                              OnboardingOption(id: "day_before", title: "The day before",
                                               subtitle: "Time to grab a gift", systemImage: "clock"),
                          ])
                    .skippable(),

                .benefits(key: "benefits", title: "Everything in one place", items: [
                    OnboardingBenefit(systemImage: "infinity", title: "Unlimited birthdays"),
                    OnboardingBenefit(systemImage: "lock.iphone", title: "Lock Screen widgets"),
                ]),

                .permission(key: "notifications",
                            title: "Get reminded in time",
                            subtitle: "We'll tell you before each birthday.",
                            permission: .notifications()),

                .loading(title: "Setting up your countdowns",
                         messages: ["Adding your reminders", "Preparing your widgets"]),
            ],
            theme: .app,
            options: OnboardingOptions(persistence: .userDefaults()),
            analytics: { event in
                Analytics.logEvent(event.name, parameters: event.parameters)
            }
        )
    }
}
```

## Step types

| Step | What it does |
|------|--------------|
| `.hero(key:title:subtitle:visual:)` | Big visual (pass your real UI or illustration) with a headline. There's also a variant with `systemImage:`. |
| `.benefits(key:title:subtitle:items:)` | List of `OnboardingBenefit` items, each with an SF Symbol. |
| `.question(key:title:subtitle:selection:options:autoAdvance:)` | `.single` or `.multiple(minimum:maximum:)`. Stores the selected option `id`s under `key`, in declaration order. |
| `.permission(key:title:subtitle:permission:)` | Continue triggers the **real** system request (`OnboardingPermission.notifications()` or your own closures). It's skipped automatically if the permission is already granted or denied. There's no "Not now" button and it can't be skipped (App Review 5.1.1). |
| `.reviewPrePrompt(title:subtitle:requestReview:)` | Optional and **off by default** (only shows if you add it). Continue calls the system review request. |
| `.custom(key:showsContinueButton:requiresAnswer:content:)` | Any SwiftUI view. The `OnboardingStepContext` gives you `setAnswer(_:)` and `advance()`. |
| `.loading(title:messages:duration:)` | Progress ring with a checklist that advances on its own. |

Modifiers: `.skippable()`, `.footnote(_:systemImage:)` and `.buttonTitle(_:)`.

`OnboardingOption(id:title:subtitle:systemImage:emoji:)`: `subtitle` is optional and is shown under the title in a smaller, secondary style. Each option row has the accessibility identifier `onboarding.option.<id>` for UI tests (the primary button is `onboarding.primary`).

In landscape on iPhone, every step scrolls when it doesn't fit (the hero switches to visual-beside-text), so nothing gets cut.

## Answers

`onFinish` receives `OnboardingAnswers` (`[String: [String]]`):

- question: the selected option ids (`["day_before", "on_the_day"]`)
- permission: `["granted"]` or `["denied"]`
- custom: whatever you stored with `context.setAnswer`
- skipped steps have no entry

Keep keys and option ids stable across versions. They're your analytics and personalization contract.

## Analytics

| Event (`event.name`) | Parameters |
|----------------------|------------|
| `onboarding_step_viewed` | `step_key`, `step_index` |
| `onboarding_step_completed` | `step_key`, `step_index` |
| `onboarding_answer_selected` | `step_key`, `values` (comma-separated) |
| `onboarding_permission_result` | `step_key`, `status`, `was_prompted` (0/1) |
| `onboarding_step_skipped` | `step_key`, `step_index` |
| `onboarding_finished` | `duration_seconds` |

`OnboardingEvent` is also a Swift enum, so you can switch over it.

## Options

```swift
OnboardingOptions(
    showsProgress: true,        // capsules; hidden for single-step flows
    allowsBack: true,
    hapticsEnabled: true,
    persistence: .userDefaults(key: "my_onboarding")   // resume where the user left; cleared on finish
)
```

`hasCompletedOnboarding` is the app's responsibility.

## iOS 26 and custom steps

On iOS 26, SwiftUI may build parts of the view tree on a background thread (`com.apple.SwiftUI.AsyncRenderer`), for example the rows of a `ForEach` during a step transition. With Swift 6, a closure written inside a `body` is main-actor isolated and traps there. 0.1.0 crashed this way on question steps; 0.1.1 fixes it inside the package, so apps need no workaround.

If your `.custom` steps or hero visuals use `ForEach`, `GeometryReader` or other closures that SwiftUI calls later, apply the same rule in your code: make the closure `@Sendable` and capture plain values (see `QuestionStepView` and `OptionRow` in `Views/StepViews.swift`).

## Development

`swift build` doesn't work because the package is iOS-only (SwiftUI/UIKit). Use:

```sh
xcodebuild -scheme EnduranceOnboarding -destination 'generic/platform=iOS Simulator' build
xcodebuild test -scheme EnduranceOnboarding -destination 'platform=iOS Simulator,name=iPhone Air'

# Render the demo flow (2 themes × light/dark) to PNGs
TEST_RUNNER_ONBOARDING_SCREENSHOT_DIR=/tmp/onboarding-shots \
  xcodebuild test -scheme EnduranceOnboarding -destination 'platform=iOS Simulator,name=iPhone Air'
```

`Example/OnboardingExample.xcodeproj` is a small host app that uses the package from this checkout, with UI tests that walk the whole flow on a simulator (including the iOS 26 async-renderer case and landscape):

```sh
xcodebuild test -project Example/OnboardingExample.xcodeproj -scheme OnboardingExample \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

`Sources/EnduranceOnboarding/Demo/OnboardingPreviews.swift` holds Xcode previews with two sample themes (Birthday raspberry and Fan Noise midnight). It's only compiled in DEBUG.
