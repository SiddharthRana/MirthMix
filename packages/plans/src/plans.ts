/**
 * Plan and entitlement configuration, shared by the API and the website. Prices are hypotheses
 * (BUILD_PROMPT §11): change them here and in the store/provider dashboards. Game logic never reads
 * this; the app and website only ask "is premium content unlocked?".
 */
export const PLAN_IDS = ['free', 'premium'] as const;
export type PlanId = (typeof PLAN_IDS)[number];

export interface Entitlements {
  /** Premium packs and categories. */
  premiumContent: boolean;
}

export interface DisplayPrice {
  currency: 'INR' | 'USD';
  /** Minor units (paise / cents) to avoid float rounding. */
  monthly: number;
  annual: number;
}

export interface PlanConfig {
  id: PlanId;
  name: string;
  /** Paid plans are purchasable; free is not. */
  paid: boolean;
  entitlements: Entitlements;
  /**
   * Indicative prices for marketing pages only. The amount actually charged always comes from the
   * store or payment provider (localised by country), never from this table.
   */
  displayPrices?: DisplayPrice[];
}

export const PLANS: Record<PlanId, PlanConfig> = {
  free: {
    id: 'free',
    name: 'Free',
    paid: false,
    entitlements: { premiumContent: false },
  },
  premium: {
    id: 'premium',
    name: 'MirthMix Premium',
    paid: true,
    entitlements: { premiumContent: true },
    displayPrices: [
      { currency: 'INR', monthly: 9900, annual: 69900 },
      { currency: 'USD', monthly: 299, annual: 1999 },
    ],
  },
};

export function getPlan(id: PlanId): PlanConfig {
  return PLANS[id];
}

export function formatPrice(
  minor: number,
  currency: DisplayPrice['currency'],
  locale = 'en',
): string {
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency,
    minimumFractionDigits: minor % 100 === 0 ? 0 : 2,
  }).format(minor / 100);
}

export const SUBSCRIPTION_STATUSES = [
  'trialing',
  'active',
  'grace_period',
  'on_hold',
  'paused',
  'canceled',
  'expired',
  'refunded',
] as const;
export type SubscriptionStatus = (typeof SUBSCRIPTION_STATUSES)[number];

/**
 * Whether a subscription in this state grants its plan right now. `canceled` keeps access until
 * the end of the paid period; `grace_period` keeps access while the store retries payment.
 */
export function subscriptionGrantsAccess(
  status: SubscriptionStatus,
  currentPeriodEnd: Date | null,
  now = new Date(),
): boolean {
  switch (status) {
    case 'trialing':
    case 'active':
    case 'grace_period':
      return true;
    case 'canceled':
      return currentPeriodEnd !== null && currentPeriodEnd > now;
    default:
      return false;
  }
}

/** Plans ordered from least to most generous; used to pick the best of several subscriptions. */
export function planRank(id: PlanId): number {
  return PLAN_IDS.indexOf(id);
}
