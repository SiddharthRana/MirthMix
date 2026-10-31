# Payments setup

MirthMix sells one paid plan, **MirthMix Premium** (monthly or annual), through two channels that grant the same entitlement (`premiumContent`). The design and code are ported from Weblume (`apps/api/src/billing`), so the steps match Weblume's `docs/payments-setup.md`.

| Channel                                                   | Who it's for                                                                 | How it works                                                                                                       |
| --------------------------------------------------------- | ---------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| **Google Play Billing**                                   | Android app users (required by Play policy for in-app digital subscriptions) | Purchase in app → API verifies with Google and acknowledges → Real-time Developer Notifications keep state current |
| **Web**: a Merchant of Record (Paddle _or_ Dodo Payments) | Website visitors                                                             | Hosted checkout → signed webhooks → `subscriptions`                                                                |

Guests never need an account. Only purchasers sign in (Supabase email one-time code, in the app and on the website), so one subscription works on every device.

Everything below uses **sandbox/test** modes. Nothing is charged until you switch to live keys. Nothing here has been set up yet: no Supabase project, Play Console app or provider account exists.

## 0. Before you start: choose the web provider

A Merchant of Record (MoR) is the legal seller: it charges the customer, handles VAT/GST/sales tax worldwide, issues invoices and handles refunds and chargebacks.

|                            | Paddle Billing                                                                | Dodo Payments                                                                                   |
| -------------------------- | ----------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| Seller based in India      | **Not confirmed**; Weblume's research found individual review, payouts in USD | Yes: India-based, built for Indian founders selling globally                                    |
| Indian buyers: UPI / RuPay | Not found                                                                     | Yes, including UPI AutoPay subscriptions (RBI e-mandates)                                       |
| Adapter status             | Built against Paddle's documented API and webhook signature format            | Built on the Standard Webhooks spec and Dodo's documented fields; **not verified against live** |

**Confirm with each provider** that they accept your country and business type, support recurring payments for Indian buyers, and pay out in a currency you can use. Set `WEB_PAYMENT_PROVIDER=paddle` or `dodo` in the API env (only one web provider is active at a time), or leave it `none` to sell only on Android.

## 1. Supabase (purchaser accounts)

1. Create a project. Copy the **project URL** and the **publishable key** (or legacy anon key).
2. **Authentication → Providers → Email:** enabled. **Authentication → Email templates:** edit both **Confirm signup** (first sign-in) and **Magic Link** (later sign-ins) to show `{{ .Token }}`, so people get a 6-digit code rather than a link. Check the OTP length is 6. Not verified against a live project from the build environment; test one sign-in from the app and the website.
3. **Authentication → URL configuration:** site URL = your website. No redirect URLs are needed (codes, not links).
4. Apply the database migration: `supabase db push`, or run `supabase/migrations/*.sql` in the SQL editor. It creates `profiles`, `subscriptions`, `webhook_events` and `feature_flags` with row-level security (users can only read their own rows; all writes go through the API).
5. Copy the **pooled connection string** into the API's `DATABASE_URL`, and the **secret key** (`sb_secret_…`) into `SUPABASE_SECRET_KEY` (used only to delete auth users on account deletion).
6. Set up custom SMTP (Supabase's built-in email is rate-limited and meant for testing).

## 2. Plans and prices

- **Entitlements** live in `packages/plans/src/plans.ts` (`premiumContent`). Indicative prices shown on the website live there too.
- **Real prices** live in Google Play Console and the provider dashboard. Hypotheses from BUILD_PROMPT §11:
  - **Monthly:** ₹99 / $2.99
  - **Annual:** ₹699 / $19.99
- Put the provider IDs in the API env:
  - **Paddle:** `PADDLE_PRICE_PREMIUM_MONTHLY`, `PADDLE_PRICE_PREMIUM_ANNUAL` (price IDs, `pri_…`)
  - **Dodo:** `DODO_PRODUCT_PREMIUM_MONTHLY`, `DODO_PRODUCT_PREMIUM_ANNUAL` (product IDs)
- Decide whether displayed prices include tax, and keep `/pricing` consistent.

## 3. Paddle (sandbox)

1. Create a sandbox account at sandbox-vendors.paddle.com.
2. **Catalog:** create the product "MirthMix Premium" with two prices (monthly, annual). Copy the price IDs.
3. **Developer tools → Authentication:**
   - **API key** → `PADDLE_API_KEY` (API, server-only); `PADDLE_ENV=sandbox`.
   - **Client-side token** → `NEXT_PUBLIC_PADDLE_CLIENT_TOKEN` (website), and `NEXT_PUBLIC_PADDLE_ENV=sandbox`.
4. **Checkout → Checkout settings → Default payment link:** `https://<your-site>/checkout/paddle`, and approve your domain. The API creates a transaction carrying the user id; Paddle sends the customer to this page, which opens Paddle.js.
5. **Developer tools → Notifications:** destination `https://<your-api>/v1/billing/webhooks/paddle`, subscribed to `subscription.created`, `.activated`, `.updated`, `.trialing`, `.past_due`, `.paused`, `.resumed`, `.canceled`. Copy the secret key into `PADDLE_WEBHOOK_SECRET`.
6. Set `BILLING_RETURN_URL=https://<your-site>/account?checkout=success`.
7. Test with Paddle's sandbox cards; **Account** on the website should then say "Premium is on".

## 4. Dodo Payments (test mode)

1. Create an account, complete business verification, and stay in **Test mode**.
2. **Products:** subscription products "Premium monthly" and "Premium annual". Copy the product IDs.
3. **Developer → API keys:** `DODO_API_KEY`; `DODO_ENV=test`.
4. **Developer → Webhooks:** `https://<your-api>/v1/billing/webhooks/dodo`, `subscription.*` events; signing secret (`whsec_…`) → `DODO_WEBHOOK_SECRET`.
5. Run one purchase end to end and check checkout URL, a processed `subscription.active` webhook in the API logs, Premium on **Account**, and "Manage subscription" opening the portal. If field names differ, adjust `apps/api/src/billing/providers/dodo.provider.ts` and its tests.

## 5. Google Play Billing

### Play Console

1. Create the app with package name **`com.mirthmix.app`** and upload a release (internal testing is fine) signed with the upload key (`apps/mobile/README.md`). Play only offers billing to uploaded apps.
2. **Monetize → Products → Subscriptions:** create **`mirthmix_premium`** (must match `GOOGLE_PLAY_SUBSCRIPTION_ID`) with base plans **`monthly`** (1 month, auto-renewing) and **`annual`** (1 year). The app and API map base-plan IDs containing "month" / "annual" or "year" to intervals. Set prices per country and activate both.
3. **Setup → License testing:** add tester accounts so test purchases aren't charged.

### Google Cloud: server access

1. In the Cloud project linked to Play Console, enable the **Google Play Android Developer API**.
2. Create a service account and a JSON key → **`GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`** (raw or base64; API-only secret).
3. **Play Console → Users and permissions:** invite the service account with **View financial data** and **Manage orders and subscriptions**.
4. Set **`BILLING_ACCOUNT_SECRET`** to at least 32 random characters (`openssl rand -hex 32`). It derives the opaque account id sent to Play with each purchase. **Set it once**: changing it breaks matching for existing Play subscriptions. The API refuses to start in production with Play configured and no secret.

### Real-time Developer Notifications (RTDN)

1. **Pub/Sub:** create a topic (e.g. `play-billing`) and grant `google-play-developer-notifications@system.gserviceaccount.com` the **Pub/Sub Publisher** role on it.
2. **Play Console → Monetization setup:** set the topic and send a test notification (logged and ignored).
3. Create a **push subscription** to `https://<your-api>/v1/billing/google-play/rtdn` with **authentication** on: a service account (e.g. `pubsub-push@<project>.iam.gserviceaccount.com`) and audience `https://<your-api>/v1/billing/google-play/rtdn`. Put the same values in **`GOOGLE_PLAY_RTDN_SERVICE_ACCOUNT`** and **`GOOGLE_PLAY_RTDN_AUDIENCE`**.

### How a Play purchase flows

1. The person signs in (email code), opens **Premium**, and taps a price. The app gets their account reference (`GET /v1/billing/google-play/account-ref`) and starts the purchase with it as `obfuscatedAccountId`.
2. Play returns a purchase token; the app sends it to `POST /v1/billing/google-play/verify`.
3. The API reads `purchases.subscriptionsv2` from Google, checks the product is ours and the account reference matches the signed-in user (so a token can't be claimed by another account), saves the subscription and **acknowledges** it (unacknowledged purchases are refunded after 3 days).
4. Only then does the app complete the purchase on the device and refresh the entitlement. If the app is killed mid-way, Play redelivers the purchase on next launch, and RTDN also acknowledges it as a fallback.
5. Renewals, grace, holds, pauses, cancellations, expiries and refunds (`SUBSCRIPTION_REVOKED` → `refunded`) arrive via RTDN; the API re-reads the subscription from Google each time.

## 6. Building the app and website with accounts

App (`--dart-define`; without these the app is fully playable and Premium says it isn't available in this build):

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.<domain> \
  --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable key> \
  --dart-define=SITE_URL=https://<domain>
```

Website: `NEXT_PUBLIC_API_URL`, `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`, and for Paddle `NEXT_PUBLIC_PADDLE_CLIENT_TOKEN` / `NEXT_PUBLIC_PADDLE_ENV`. Add the website origin to the API's `CORS_ORIGINS`.

## 7. Switching billing on

1. Set the env vars above and deploy the API (`apps/api`, `pnpm --filter @mirthmix/api build && node dist/main.js`; health at `/health`, readiness at `/ready`).
2. Flip the kill switch: `update public.feature_flags set enabled = true where key = 'billing';`. It takes effect within 30 seconds.
3. `GET /v1/billing/config` shows what's available per channel; the website and app read it.

Switching `billing` off again stops new purchases **and** makes everyone Free (entitlements ignore subscriptions while it's off), and the app's cached entitlement follows on its next refresh. Use it only before launch or in an emergency.

## 8. Behaviour reference

- **Entitlements** come only from `subscriptions` rows written by verified events (`apps/api/src/billing/subscription-store.ts`); status → access rules are in `packages/plans/src/plans.ts` (`canceled` keeps access to the period end, `grace_period` keeps it while the store retries).
- **App offline grace:** the app caches the last verified answer with its `validUntil` (end of the paid period) and keeps Premium until **`validUntil` + 3 days** without a connection (`apps/mobile/lib/account/entitlement.dart`). It refreshes on launch, on resume, after sign-in and on the Premium screen; a refresh that says "free" removes Premium at once.
- **Idempotency:** each provider event ID (Pub/Sub `messageId` for Play) is stored once in `webhook_events`; duplicates return `{"status":"duplicate"}`. Payloads are purged after 30 days.
- **Out-of-order events:** a row is updated only if the event is newer than the last applied one (`last_event_at`).
- **Failures** return 5xx so the provider retries. Signature failures return 401 and nothing is recorded.
- **Two channels at once:** web checkout is refused if any active subscription exists; the app shows "manage it on the website" instead of prices for a web subscriber; both account pages warn when someone has two active subscriptions.
- **Account deletion** (`DELETE /v1/me`, in the app and on the website) disables the account at once and deletes the auth user (and by cascade its subscriptions). It does not cancel store subscriptions; both UIs say so.
- **iOS:** no App Store purchases until iOS is in scope.
