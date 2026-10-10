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

## Cómo validar

```sh
xcodebuild -scheme EnduranceOnboarding -destination 'generic/platform=iOS Simulator' build
xcodebuild test -scheme EnduranceOnboarding -destination 'platform=iOS Simulator,id=986D141E-378F-4B6E-BF19-323757DC46B9'
```

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
- Las apps fijan la versión exacta (`exactVersion`) y suben a mano después de
  probar.
- Antes de cambiar la API pública, buscar quién la usa
  (`grep -rl EnduranceOnboarding ../*/*.xcodeproj`) y avisar.
