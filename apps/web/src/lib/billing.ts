'use client';

import { useEffect, useState } from 'react';
import { apiFetch } from './api';

export interface BillingConfig {
  enabled: boolean;
  web: {
    provider: 'none' | 'paddle' | 'dodo';
    available: boolean;
    intervals: ('monthly' | 'annual')[];
  };
  googlePlay: { available: boolean; packageName: string; subscriptionId: string };
}

export interface AccountSubscription {
  provider: 'google_play' | 'paddle' | 'dodo';
  planId: string;
  status: string;
  interval: 'monthly' | 'annual' | null;
  currentPeriodEnd: string | null;
  cancelAtPeriodEnd: boolean;
}

export interface Account {
  id: string;
  email?: string;
  plan: { id: string; name: string; paid: boolean; source: 'default' | 'subscription' };
  entitlements: { premiumContent: boolean };
  validUntil: string | null;
  subscriptions: AccountSubscription[];
}

/** Whether Premium can be bought on the web right now. `null` while loading; unavailable on error. */
export function useBillingConfig(): BillingConfig | null {
  const [config, setConfig] = useState<BillingConfig | null>(null);
  useEffect(() => {
    let active = true;
    apiFetch<BillingConfig>('/v1/billing/config').then(
      (data) => active && setConfig(data),
      () =>
        active &&
        setConfig({
          enabled: false,
          web: { provider: 'none', available: false, intervals: [] },
          googlePlay: { available: false, packageName: '', subscriptionId: '' },
        }),
    );
    return () => {
      active = false;
    };
  }, []);
  return config;
}

const ACCESS_STATUSES = new Set(['trialing', 'active', 'grace_period']);

/** Mirrors subscriptionGrantsAccess in @mirthmix/plans for display (the server decides access). */
export function grantsAccess(s: { status: string; currentPeriodEnd: string | null }): boolean {
  if (s.status === 'canceled')
    return s.currentPeriodEnd !== null && new Date(s.currentPeriodEnd) > new Date();
  return ACCESS_STATUSES.has(s.status);
}

export function playManageUrl(packageName: string, subscriptionId: string): string {
  return `https://play.google.com/store/account/subscriptions?sku=${encodeURIComponent(subscriptionId)}&package=${encodeURIComponent(packageName)}`;
}

export const providerName: Record<AccountSubscription['provider'], string> = {
  google_play: 'Google Play',
  paddle: 'the website (Paddle)',
  dodo: 'the website (Dodo Payments)',
};
