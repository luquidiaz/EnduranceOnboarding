# EnduranceOnboarding

Aplica el `CLAUDE.md` de la raíz del workspace (proceso, git, convenciones).

## Qué es

Paquete Swift con **el** onboarding de todas las apps del portfolio, pensado
para llevar al paywall. Reemplaza a `enduranceApptitudeOnboardingPackage`
(JSON, respuestas por índice, strings hardcodeados, permiso falso).
iOS 17+, swift-tools 6.0, Swift 6 estricto, sin dependencias. No importa
RevenueCat: el paywall lo presenta la app en `onFinish`.

## API

- `OnboardingFlow(steps:theme:options:analytics:)` + `OnboardingView(flow:onFinish:)`.
- Pasos: `.hero`, `.benefits`, `.question` (single/multi, respuestas por `key`
  como `[String: [String]]`), `.permission` (pedido real; se saltea si ya está
  decidido; sin "Not now" por la guideline 5.1.1), `.reviewPrePrompt`
  (opcional, apagado si no se agrega), `.custom`, `.loading`.
  Modificadores: `.skippable()`, `.footnote(_:systemImage:)`, `.buttonTitle(_:)`.
- `OnboardingTheme`: tokens de la app (Color assets light/dark),
  `OnboardingTypography.rounded` para SF Rounded, `cornerRadius`, `colorScheme`
  para apps solo dark.
- `OnboardingEvent`: `name`/`parameters` listos para Firebase (`onboarding_*`).
- `OnboardingController`: la lógica (navegación, respuestas, eventos), testeable sin UI.
- Strings del paquete en `Resources/Localizable.xcstrings` (en, es, pt-BR, de,
  fr, it, ja, ko). Un string nuevo va en los 8 idiomas. El copy de la app es
  `LocalizedStringResource` y se traduce en la app.
- `hasCompletedOnboarding` lo maneja la app. La persistencia de progreso es opcional.

## Render safety (iOS 26)

En iOS 26 SwiftUI puede armar partes del árbol en un hilo de fondo
(`com.apple.SwiftUI.AsyncRenderer`). Con Swift 6, un closure escrito dentro de
un `body` queda aislado al main actor y crashea ahí (fue el crash de 0.1.0 en
`QuestionStepView`). Regla: todo closure que SwiftUI evalúa después (contenido
de `ForEach`, `GeometryReader`, condiciones de `sensoryFeedback`, etc.) va
`@Sendable`, captura valores planos (no `theme` vía `self`, no el controller) y
solo crea vistas con `init` no aislado: tipos con la conformidad a `View` en una
extensión (`OptionRow`, `BenefitRow`, `ChecklistRow`). El compilador valida el
resto. No usar parches de animación.

## Cómo validar

```sh
xcodebuild -scheme EnduranceOnboarding -destination 'generic/platform=iOS Simulator' build
xcodebuild test -scheme EnduranceOnboarding -destination 'platform=iOS Simulator,id=<udid>'
# UI tests del flujo completo (iOS 26, caso del crash, landscape) sobre la app de ejemplo
xcodebuild test -project Example/OnboardingExample.xcodeproj -scheme OnboardingExample \
  -destination 'platform=iOS Simulator,id=<udid>'
```

Usar un simulador libre (o uno propio con `xcrun simctl create`, y borrarlo al
terminar). `Example/` usa el paquete por ruta local (`..`).

`swift build` no anda porque el paquete es solo iOS. Para generar las capturas
del demo (2 temas, light y dark) hay que agregar
`TEST_RUNNER_ONBOARDING_SCREENSHOT_DIR=<dir>` al `xcodebuild test`. Los
previews están en `Demo/OnboardingPreviews.swift` (solo en DEBUG).

## Publicar versiones

- Semver: un patch para fixes, un minor para features compatibles, un major
  (o un minor mientras estemos en 0.x) si se rompe la API pública.
- Tag anotado sobre `main` después de que pasen el build y los tests:
  `git tag -a 0.2.0 -m "..." && git push origin 0.2.0`.
- **Los tags son inmutables**: nunca mover ni borrar un tag publicado. Si salió
  mal, se publica el siguiente patch.
- Cada versión va en `CHANGELOG.md` y en un GitHub release.
- Las apps fijan la versión exacta (`exactVersion`) y suben a mano después de
  probar.
- Antes de cambiar la API pública, buscar quién la usa
  (`grep -rl EnduranceOnboarding ../*/*.xcodeproj`) y avisar.
