# Handoff — resume MirthMix in a new chat

Paste this into a new Claude Code session on the `siddharthrana/mirthmix` repository:

> Continue building MirthMix. Read `docs/HANDOFF.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md` and `docs/BUILD_PROMPT.md` first, then carry on from "Next steps" in PROGRESS.md. Work on branch `claude/upbeat-feynman-o2ywiv`. Payments must match the Weblume repo (`siddharthrana/weblume`, `apps/api/src/billing`): Google Play Billing verified by NestJS + Paddle/Dodo on the web. Commit and push after each step.

## Status

Phases 1 and 2 are complete and pushed. **Phase 3 (web player and share links) is in progress** — check `git log` and `docs/PROGRESS.md` for what landed.

Phase 3 plan, in order (each step committed separately):

1. `packages/game-engine/src/share.ts`: encode/decode a game setup + seed as a URL-safe string (`/play?c=...`), with tests.
2. `apps/web/src/app/play/`: client-side web player using `@mirthmix/game-engine` and the content packs — Would You Rather first, then This or That, Trivia, Guess. No accounts.
3. Share button in the web player (copies the `/play?c=` link); Playwright tests for playing each mode.
4. Android App Links (`assetlinks.json` placeholder + intent filter) so links open the app; document the manual domain step.
5. Update PROGRESS, DECISIONS and this file; stop at the Phase 3 checkpoint.

## Where things are

- **Branch:** `claude/upbeat-feynman-o2ywiv` (all work pushed). No PR yet.
- **Status and next steps:** `docs/PROGRESS.md` (always the source of truth; updated at every commit).
- **Why things are the way they are:** `docs/DECISIONS.md`.
- **The full product spec and phases:** `docs/BUILD_PROMPT.md`.

## Environment setup (cloud container)

```bash
pnpm install
pnpm --filter "./packages/*" run build
# Flutter isn't preinstalled; this worked here:
curl -sSLO https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.9-stable.tar.xz
tar xf flutter_linux_3.47.9-stable.tar.xz -C /opt && git config --global --add safe.directory /opt/flutter
export PATH=/opt/flutter/bin:$PATH
cd apps/mobile && flutter pub get
```

The Android SDK host (dl.google.com) was blocked in the container, so APK builds only run in GitHub Actions.

## Checks to run before every commit

```bash
pnpm format && pnpm format:check && pnpm content:validate && pnpm lint && pnpm typecheck && pnpm test
pnpm --filter @mirthmix/web build && pnpm --filter @mirthmix/web test:e2e
cd apps/mobile && dart format lib test && flutter analyze && flutter test
```

## Conventions that matter

- Content lives in `packages/content/packs/*.json`; after editing run `pnpm content:validate` and `pnpm content:sync`.
- Game rules exist twice: TypeScript (`packages/game-engine`) is the reference, Dart (`apps/mobile/lib/game`) is a port. After changing rules, run `pnpm --filter @mirthmix/game-engine vectors` and make `flutter test` pass.
- UI strings go in `apps/mobile/lib/l10n/app_en.arb`.
- Never trust a client-side premium flag; `premiumProvider` stays `false` until Phase 4.
- Commit after each step and push to the branch; keep `docs/PROGRESS.md` accurate.
- Widget tests: use the scroll-aware `tapText`/`reveal` helpers; on screens with a running countdown use `tester.pump(...)` instead of `pumpAndSettle()`.
