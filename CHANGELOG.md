# Changelog

All notable changes to this package. Apps pin an exact version; see the README.

## 0.1.2 (2026-10-11)

### Added
- Package strings in six more languages: Simplified Chinese (zh-Hans), Traditional Chinese (zh-Hant), Dutch (nl), Swedish (sv), Polish (pl) and Turkish (tr). Informal register (je/du/ty/sen/你). Buttons, progress and the multiple-choice hint no longer fall back to English there. No API changes.

## 0.1.1 (2026-10-11)

### Fixed
- **Crash on iOS 26** when a question step appeared right after a screen with nothing animating. SwiftUI built the option rows on its async renderer thread (`com.apple.SwiftUI.AsyncRenderer`), and the `ForEach` row closure, main-actor isolated under Swift 6, trapped on its isolation check (`_dispatch_assert_queue_fail` in `QuestionStepView.body`). Every closure that SwiftUI evaluates lazily (`ForEach` rows, `GeometryReader`, `sensoryFeedback` conditions) is now `@Sendable` and only builds views whose initializers are not main-actor isolated. Apps can drop workarounds such as a `TimelineView(.animation)` keep-alive.
- Landscape on iPhone: the hero step puts the visual beside the text and scrolls if it still doesn't fit, instead of squeezing or cutting the title. The other steps already scrolled.

### Added
- `OnboardingOption.subtitle`: optional second line under the option title. Source compatible (`init(id:title:subtitle:systemImage:emoji:)`, `subtitle` defaults to `nil`).
- Accessibility identifiers `onboarding.option.<id>` on option rows, for UI tests.
- `Example/OnboardingExample.xcodeproj`: host app with UI tests that walk the full flow, including the iOS 26 crash case and landscape.

## 0.1.0 (2026-10-10)

- First release: typed flow, hero, benefits, question, permission, review pre-prompt, custom and loading steps, theming, 8 languages, analytics events, optional progress persistence.
