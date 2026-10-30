# MirthMix mobile (Flutter)

Android-first Flutter app. iOS is structurally supported but not in scope yet (no iOS builds or payments).

- Flutter 3.47 stable / Dart 3.13, Material 3 with a custom playful theme
- State: Riverpod 3 · Routing: go_router 18 · Storage: shared_preferences · Screen-awake: wakelock_plus · i18n: `flutter gen-l10n` (ARB in `lib/l10n`)
- Fonts: Fredoka (display) and Nunito (body), bundled under the SIL Open Font License (`assets/fonts/OFL.txt`)
- Package: `com.mirthmix.app` (permanent once published on Google Play)

## Structure

```
lib/
  main.dart, app.dart     Entry point: loads prefs + content, then MaterialApp.router
  content/content.dart    Pack models + defensive parsing of assets/content/*.json
  game/
    random.dart           mulberry32 + seeded shuffle (port of packages/game-engine)
    wyr_engine.dart       Would You Rather reducer (port of packages/game-engine)
  state/                  Riverpod providers: prefs, content, settings, session (persisted)
  router/router.dart      Routes + first-launch onboarding redirect
  features/               Screens: onboarding, home, library, settings, wyr/{setup,play,results}
  widgets/                Brand mark, gradient panel, mode tile
  theme/
    tokens.g.dart         GENERATED from packages/design-tokens/tokens.json — don't edit
    app_theme.dart        Light/dark ThemeData + MmPalette extension
  l10n/                   app_en.arb (+ generated localizations)
assets/content/           GENERATED copy of packages/content/packs (`pnpm content:sync`) — don't edit
```

## Run

```bash
flutter pub get
flutter run
```

No configuration is needed: the app has no backend in Phase 1.

## Check

```bash
dart format --set-exit-if-changed $(find lib test -name '*.dart' ! -name '*.g.dart' ! -name 'app_localizations*')
flutter analyze
flutter test
```

`flutter test` also replays the shared engine test vectors from `packages/game-engine/test-vectors/`, so run it from a full checkout of the monorepo.

## Release builds

```bash
flutter build apk --release --split-per-abi   # sideload / size check
flutter build appbundle --release             # Play upload
```

Without a keystore, release builds are signed with the debug key (fine locally; **not** accepted by Play). To sign for Play:

1. Create an upload keystore (keep it and its passwords safe, outside the repo):
   `keytool -genkey -v -keystore ~/mirthmix-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. Create `android/key.properties` (git-ignored):
   ```
   storeFile=/absolute/path/to/mirthmix-upload.jks
   storePassword=...
   keyAlias=upload
   keyPassword=...
   ```
3. Enrol in Play App Signing when you create the app in Play Console.
