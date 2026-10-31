-- Phase 4: purchaser accounts and subscriptions (same model as Weblume).
-- Guests never have an account; a profile exists only for people who sign in to buy or restore.

create type public.plan_id as enum ('free', 'premium');
create type public.payment_provider as enum ('google_play', 'paddle', 'dodo');
create type public.subscription_status as enum (
  'trialing', 'active', 'grace_period', 'on_hold', 'paused', 'canceled', 'expired', 'refunded'
);
create type public.webhook_status as enum ('received', 'processed', 'ignored', 'failed');

-- ---------------------------------------------------------------------------
-- Shared trigger: keep updated_at current
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Profiles (1:1 with auth.users)
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  -- Set when the person deletes their account; the auth user is then removed (cascade).
  deletion_requested_at timestamptz,
  -- Opaque account reference given to Google Play (HMAC of the user id), so Real-time Developer
  -- Notifications for a first purchase can be matched to the user before the app reports it.
  billing_account_ref text unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger profiles_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();

-- Create a profile automatically for every new auth user.
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Trigger-only function: nobody should be able to call it directly.
revoke execute on function public.handle_new_user() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Subscriptions (written only by the API from verified store/provider events)
-- ---------------------------------------------------------------------------
create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  provider public.payment_provider not null,
  -- Google Play purchase token, or the web provider's subscription id.
  provider_subscription_id text not null,
  provider_customer_id text,
  product_id text not null,
  plan_id public.plan_id not null,
  status public.subscription_status not null,
  current_period_start timestamptz,
  current_period_end timestamptz,
  cancel_at_period_end boolean not null default false,
  -- Timestamp of the provider event that produced this state; used to ignore out-of-order events.
  last_event_at timestamptz not null,
  provider_account_ref text,
  -- Google Play purchase tokens are replaced on resubscribe/upgrade; keep the link to the previous one.
  linked_provider_subscription_id text,
  billing_interval text check (billing_interval in ('monthly', 'annual')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (provider, provider_subscription_id)
);

create index subscriptions_user_idx on public.subscriptions (user_id, status);
create index subscriptions_account_ref_idx on public.subscriptions (provider, provider_account_ref);

create trigger subscriptions_updated_at before update on public.subscriptions
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Webhook events (idempotency + audit trail; payload purged after 30 days)
-- ---------------------------------------------------------------------------
create table public.webhook_events (
  id uuid primary key default gen_random_uuid(),
  provider public.payment_provider not null,
  event_id text not null,
  event_type text not null,
  status public.webhook_status not null default 'received',
  error text,
  payload jsonb,
  received_at timestamptz not null default now(),
  processed_at timestamptz,
  unique (provider, event_id)
);

-- ---------------------------------------------------------------------------
-- Feature flags / kill switches (service role only)
-- ---------------------------------------------------------------------------
create table public.feature_flags (
  key text primary key,
  enabled boolean not null,
  description text,
  updated_at timestamptz not null default now()
);

create trigger feature_flags_updated_at before update on public.feature_flags
  for each row execute function public.set_updated_at();

insert into public.feature_flags (key, enabled, description) values
  ('billing', false, 'Enable premium purchases and subscription entitlements');

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.subscriptions enable row level security;
alter table public.webhook_events enable row level security;
alter table public.feature_flags enable row level security;

create policy profiles_select_own on public.profiles
  for select to authenticated using (id = (select auth.uid()));

create policy subscriptions_select_own on public.subscriptions
  for select to authenticated using (user_id = (select auth.uid()));

-- webhook_events and feature_flags intentionally have no policies: only privileged roles can
-- access them. All writes go through the API, so no insert/update/delete policies are granted.
