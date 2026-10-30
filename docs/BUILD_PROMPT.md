# MirthMix — Build Prompt (v2)

You are a senior full-stack engineer, Flutter developer, product designer, game designer, and pragmatic startup CTO. Build a production-minded MVP for a subscription-based social party games product called **MirthMix**.

> v2 changes from v1: concrete single-device group rules for every mode, a player model, a defined share link, content targets and trivia verification, payments aligned with the Weblume stack (Google Play Billing + Paddle/Dodo MoR, verified by a NestJS API), Play Console launch requirements, India DPDP age policy, i18n-ready structure, shared content schema and engine test vectors, checkpoints with PROGRESS/DECISIONS files, pinned latest stable toolchains, performance budgets, and success metrics.

---

## 0. PRODUCT

MirthMix is a social party games product for friends, couples, families, and groups. It offers quick, easy-to-start games — Would You Rather, This or That, Trivia Blitz, Guess the Answer, and custom party packs — **played together on one shared device**.

- Markets: India and international. English first; structure for more languages later.
- Priorities: a delightful shared-phone experience, repeat engagement without manipulation, low infrastructure cost, and a scope a solo part-time developer can maintain.
- Audience: **13+**. Accounts and purchases are for **18+** (India's DPDP Act treats everyone under 18 as a child and requires verifiable parental consent to process their data). Do not target children and do not enrol in Google Play's Families programme.
- No real-time multiplayer until the single-device product is polished and validated (section 13).

## 1. WORKING RULES

- Inspect the workspace and its instructions (`README`, `CLAUDE.md`, `docs/`) before changing anything. Preserve useful existing work.
- Build working software, not only a proposal.
- **Work in phases and stop at each checkpoint** (section 12). At each checkpoint, summarise what was built, what was verified (with command output), and what is incomplete, then wait for a go-ahead.
- Maintain, and commit with the code:
  - `docs/PROGRESS.md`: current phase, done / in progress / blocked, next steps — accurate enough that a fresh session can resume from it alone.
  - `docs/DECISIONS.md`: short dated entries for every non-trivial choice (what, why, alternatives rejected).
- Commit in small, logical commits; at least once per phase.
- Run formatters, linters, type checks, tests and production builds. **If a toolchain is missing** (Flutter SDK, Android SDK, Chromium, Postgres), try to install it. If that fails, report exactly what was skipped and why. Never claim a build or test passed without running it.
- Never claim features, tests, integrations or deployments succeeded unless verified in this session.
- Do not spend money, create paid resources, register accounts, or deploy publicly without explicit authorisation. Prepare configuration and document the manual steps instead.
- Use only original content. No questions, images, logos or rules copied from existing products. Do not recreate a specific existing game.
- Choose sensible defaults when a decision does not block implementation, and record them in `DECISIONS.md`.

## 2. TECH STACK (latest stable, pinned)

Use the latest stable versions at build time, pinned in lockfiles. Where the newest major breaks a required tool, use the newest compatible version and record why. Baseline as of this prompt:

| Area      | Choice                                                                                                                                                                   |
| --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Monorepo  | pnpm 10 workspaces, Node 22 LTS, TypeScript 6.0 (7.x once typescript-eslint supports it), ESLint 10 flat config, Prettier 3, Vitest 5                                    |
| Mobile    | Flutter 3.47 / Dart 3.13, Material 3 with a custom playful theme, Riverpod 3, go_router 18, shared_preferences, `in_app_purchase` (Phase 4), ARB localisation            |
| Website   | Next.js 16 (App Router, React Compiler, typed routes), React 19, Tailwind CSS 4, MDX for guides, Playwright + axe for e2e/accessibility                                  |
| Backend   | **Phase 4 only**: NestJS 12 API for billing and entitlements, Drizzle ORM, zod, Supabase (Auth + Postgres 17) with SQL migrations and RLS                               |
| Ops       | GitHub Actions CI, optional Sentry, optional privacy-friendly analytics (PostHog or none), all behind env configuration                                                 |

Keep the architecture ready for iOS, but do not build iOS payments.

## 3. REPOSITORY (MONOREPO)

Use **this repository** (`siddharthrana/mirthmix`).

```
/
├── apps/
│   ├── mobile/          # Flutter — Android-first app
│   ├── web/             # Next.js — marketing site + web player (Phase 3)
│   └── api/             # NestJS — billing + entitlements (Phase 4)
├── packages/
│   ├── design-tokens/   # tokens.json → CSS variables (web) + Dart constants (mobile)
│   ├── content/         # starter packs (JSON), JSON Schema, validator
│   └── game-engine/     # TypeScript session engine (web) + shared test vectors
├── supabase/            # migrations (Phase 4)
├── docs/                # PROGRESS, DECISIONS, BUILD_PROMPT, QA checklist, legal placeholders
└── .github/workflows/   # CI
```

- **Content is shared.** `packages/content` is the single source; a script copies it into `apps/mobile/assets/content/`, and CI fails if the copy is stale.
- **Game logic exists twice** (Dart for mobile, TypeScript for web). Prevent drift with **shared test vectors** in `packages/game-engine/test-vectors/` (seed + actions → expected order, state and results) that both engines must pass.
- **Shuffling is seeded and deterministic** so tests are reproducible and a share link can recreate a session.
- Root README: prerequisites, setup, commands, environment variables, architecture, testing, deployment, troubleshooting. `.env.example` files contain placeholders only.

## 4. PLAYERS AND SHARED-DEVICE MODEL

- **Quick play** needs no setup: a group of unspecified size plays together.
- **Optional player setup**: 2–12 named players or 2–4 teams. Names stay on the device and are never sent to analytics or a server.
- The phone is either held by a host who reads aloud and records the group's answers, or passed around in turn order. Every mode states which it uses.
- Keep the screen awake during play, use large touch targets (≥ 56 dp for game controls), offer a big-text reading option, and confirm before quitting a game in progress.

## 5. GAME MODES

All modes support: category choice, configurable rounds (5 / 10 / 15 / 20), skip, round progress, a results screen, restart, and play-another.

**A. Would You Rather** — *host reads, group votes.* Two options are shown. Players raise hands; the host taps each side to count votes (with undo), or taps once for a quick group pick. Reveal shows the split. Results highlight the most divisive and most unanimous questions. Categories: casual, funny, thoughtful, group-friendly.

**B. This or That** — *rapid fire.* Two short options with big tap areas. Optional per-round timer (5 s) and optional discussion prompt ("Defend your pick in 10 seconds"). Pass-the-phone variant: each player picks in turn; results show who agreed most.

**C. Trivia Blitz** — *teams or players take turns.* Four-option multiple choice with a per-question timer (default 20 s, pausable). Score per player or team, with a bonus for speed. Clear right/wrong feedback and a short explanation. Results: leaderboard for this session only.

**D. Guess the Answer** — *one reader, group guesses.* A card has a hidden answer and up to three clues, revealed one at a time. The group guesses aloud; the reader taps "Got it" or reveals the next clue. Points: 3 / 2 / 1 by clue used, 0 if revealed. Score per team or as one group.

**E. Custom Party Pack** — pick modes, categories, round counts, timers and order; build a mixed session; save favourite configurations locally (account sync only if it clearly helps, Phase 4+).

## 6. CONTENT

- Original only. Organised by mode, category, difficulty, age rating (`all`, `13+`) and region (`global`, `in`).
- JSON with stable IDs (`wyr-casual-001`), validated against a JSON Schema in tests and CI. Content lives outside UI code; adding a pack means adding a file.
- Each item records `tier` (`free` / `premium`) so entitlements never touch game logic.
- **Targets by launch (Phase 5):** Would You Rather 150, This or That 150, Trivia 200, Guess 80, with roughly 60 % free. Do not claim counts that do not exist.
- **Trivia accuracy:** each question has `source`, `verifiedOn` and `reviewStatus`. Only `reviewStatus: "verified"` questions ship to users. No time-sensitive facts ("current champion", "tallest building").
- Admin path: edit JSON → run `pnpm content:validate` → commit. No CMS until there is evidence it is needed.
- Category labels and content notes are visible before play.

## 7. SAFETY, PRIVACY, AGE

- Default content suitable for a broad 13+ audience. No explicit sexual content, harassment, hateful prompts, or dangerous challenges.
- Custom questions stay on the device: validated (length, profanity filter), editable and deletable, never published.
- Collect no unnecessary personal data. Player names never leave the device.
- Privacy policy, terms and age guidance pages, clearly marked as placeholders for legal review.
- Analytics consent where required (EU/UK); analytics off by default until configured.

## 8. SHARING

A share link encodes a **session configuration** (mode(s), categories, rounds, timers, seed), e.g. `https://<domain>/play?c=<compact-encoded-config>`. It opens the Android app if installed (App Links) or the web player otherwise. It does not sync live state. No accounts are needed to open one.

## 9. WEBSITE

Pages: Home, Game library, one page per mode, How to play, Pricing, FAQ, Guides (MDX), Account and subscription (Phase 4), Privacy, Terms, Contact. Responsive, accessible (WCAG 2.2 AA), SEO metadata, sitemap and robots, no thin SEO pages. A web player for the core modes in Phase 3.

## 10. MOBILE APP

Onboarding (≤ 3 short screens, skippable), home, game library, mode setup, session with progress, timers, scoring, results and replay, favourites and recent games, subscription screen (Phase 4), settings (theme, reduced motion, sound and haptics, big text, privacy), and real empty / loading / error states. Not a WebView wrapper. Session state survives navigation, backgrounding and process death. Timers pause when the app is backgrounded.

## 11. MONETISATION — same architecture as Weblume

Pricing hypotheses (not validated): India **₹99/month or ₹699/year**; international **$2.99/month or $19.99/year**.

- Free: every mode playable with the free content. Premium: premium packs and categories, advanced customisation, longer sessions. Basic play never needs a subscription.
- **Android:** Google Play Billing via `in_app_purchase`. One subscription product with `monthly` and `annual` base plans. Purchase carries an HMAC-derived `obfuscatedAccountId`; the app sends the token to the API, which verifies it with the Google Play Developer API (`subscriptionsv2`), binds it to the user, **acknowledges it server-side**, and only then lets the app complete the purchase. Real-time Developer Notifications (Pub/Sub push, OIDC-verified) keep renewals, grace, hold, pause, cancel, expiry and refunds current.
- **Web:** a Merchant of Record — **Paddle or Dodo Payments**, selected by `WEB_PAYMENT_PROVIDER` — with server-created checkouts carrying the user id, signed webhooks verified over raw bytes, and the provider's customer portal.
- **One entitlement model** for both channels: a single `SubscriptionStore` writer, an idempotent webhook ledger, out-of-order protection, a `billing` feature-flag kill switch, and plan definitions in shared config so prices and entitlements change without touching game logic. Never trust a client-side premium flag.
- Accounts are required **only for the purchaser** (to restore across devices and web). Guests never need one.
- **Offline:** cache the last verified entitlement with its expiry plus a grace window so premium doesn't vanish at a party with bad signal.
- Premium content may ship in the app bundle in v1 (extractable); record the trade-off. Keep an option to download premium packs after verification.
- Keep the entitlement model flexible enough to test a lifetime unlock or a short "party pass" later; build subscriptions only.
- No iOS payments until iOS is in scope.

## 12. PHASES AND CHECKPOINTS

**Phase 1 — Foundation.** Monorepo, tooling, CI, design tokens and brand, README, PROGRESS/DECISIONS. Content schema, validator and starter Would You Rather pack. Landing page and legal placeholders. Flutter app: onboarding, home, game library, and a polished end-to-end Would You Rather session with results and replay. Engine test vectors. **Checkpoint.**

**Phase 2 — Core modes.** This or That, Trivia Blitz, Guess the Answer, player/team setup, timers, scoring, custom party packs, favourites and recent games, lifecycle handling. **Checkpoint.**

**Phase 3 — Web player and sharing.** TypeScript engine passing the shared vectors, web game library and player, share links and App Links. **Checkpoint.**

**Phase 4 — Monetisation.** NestJS API, Supabase auth for purchasers, Play Billing + Paddle/Dodo, entitlements, subscription screens, `docs/payments-setup.md`. **Checkpoint.**

**Phase 5 — Polish and launch prep.** Content to target counts, accessibility review, performance budgets, analytics and crash reporting (optional, configurable), privacy review, Play Store listing, Data Safety form answers, IARC questionnaire notes, app signing, and the **closed test (≥ 12 testers for 14 consecutive days)** that new personal Play Console accounts need before production. Manual QA checklist. List unfinished work separately.

## 13. SUCCESS METRICS (decide what "validated" means)

Track, with privacy-safe events only: session start → completion rate per mode, rounds played, mode and category popularity, D1/D7 retention, sessions per week, paywall views and free→paid conversion. Revisit multiplayer only if completion and D7 are healthy and users ask for remote play.

## 14. QUALITY BUDGETS

- Android: cold start < 2 s on a low-end device; release APK < 25 MB per ABI; min SDK 24.
- Web: Lighthouse ≥ 90 performance and 100 accessibility on the landing page.
- Reduced motion is respected everywhere (`MediaQuery.disableAnimations`, `prefers-reduced-motion`).
- Text contrast ≥ 4.5:1, tested from the tokens.

## 15. TESTING

Unit tests for rules, progression, scoring, timers and content validation; widget tests for controls and full session flows; lifecycle tests (backgrounded mid-timer → paused; process death → session restored; navigation away and back); entitlement tests (free vs premium, offline grace); invalid / missing content and empty categories; website navigation and player e2e with axe; the same engine test vectors on Dart and TypeScript. Manual QA checklist per mode.

## 16. FUTURE — DO NOT BUILD BY DEFAULT

Real-time multiplayer, rooms and invite codes, friends and profiles, public user-created packs and their moderation, global leaderboards, additional languages (structure is ready), advanced host features, lifetime unlock or party pass, iOS payments.

## 17. DEFINITION OF DONE

A guest can start any mode without an account; every mode works start to finish; progression, timers, scoring and results behave as specified and match across Dart and TypeScript; original content is validated; the Android app builds in release mode; the website has a useful landing page and working web player; free and premium are clearly separated when billing is configured; tests and builds have run where the environment permits; setup and deployment are documented; limitations are disclosed honestly.

## 18. NON-CODE TASKS FOR THE OWNER

Check "MirthMix" trademark, domain and Play Store name availability; confirm Paddle / Dodo seller eligibility; set up the Play Console account and closed-test testers; legal review of privacy and terms.
