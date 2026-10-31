import { HttpStatus, Injectable } from '@nestjs/common';
import { eq } from 'drizzle-orm';
import {
  getPlan,
  planRank,
  subscriptionGrantsAccess,
  type Entitlements,
  type PlanConfig,
} from '@mirthmix/plans';
import { ApiError } from '../common/api-error';
import { FeatureFlags } from '../common/feature-flags.service';
import { Database } from '../database/database.module';
import { profiles, subscriptions } from '../database/schema';

export interface ResolvedPlan {
  plan: PlanConfig;
  entitlements: Entitlements;
  /** Where the plan came from: a verified subscription, or the free default. */
  source: 'default' | 'subscription';
  /**
   * End of the paid period of the granting subscription. The app caches the entitlement until this
   * moment (plus a short offline grace window) and re-checks with the API before relying on it longer.
   */
  validUntil: Date | null;
}

/**
 * The single place that decides what a user may do. Plans come only from server-side subscription
 * records written by verified store/provider events, never from clients.
 */
@Injectable()
export class EntitlementService {
  constructor(
    private readonly database: Database,
    private readonly flags: FeatureFlags,
  ) {}

  /** Resolves the user's plan. Throws 403 account_deleted for accounts being deleted. */
  async forUser(userId: string, now = new Date()): Promise<ResolvedPlan> {
    const db = this.database.db;
    const [profile] = await db
      .select({ deletionRequestedAt: profiles.deletionRequestedAt })
      .from(profiles)
      .where(eq(profiles.id, userId))
      .limit(1);
    if (!profile || profile.deletionRequestedAt) {
      throw new ApiError(HttpStatus.FORBIDDEN, 'account_deleted', 'This account has been deleted.');
    }

    const free = getPlan('free');
    const fallback: ResolvedPlan = {
      plan: free,
      entitlements: free.entitlements,
      source: 'default',
      validUntil: null,
    };
    // With billing switched off, everyone gets free-plan entitlements.
    if (!(await this.flags.isEnabled('billing'))) return fallback;

    const subs = await db.select().from(subscriptions).where(eq(subscriptions.userId, userId));
    let best: ResolvedPlan = fallback;
    for (const s of subs) {
      if (!subscriptionGrantsAccess(s.status, s.currentPeriodEnd, now)) continue;
      const plan = getPlan(s.planId);
      const outranks = planRank(plan.id) > planRank(best.plan.id);
      const lastsLonger =
        plan.id === best.plan.id &&
        (s.currentPeriodEnd?.getTime() ?? 0) > (best.validUntil?.getTime() ?? 0);
      if (!plan.paid || !(outranks || lastsLonger)) continue;
      best = {
        plan,
        entitlements: plan.entitlements,
        source: 'subscription',
        validUntil: s.currentPeriodEnd,
      };
    }
    return best;
  }
}
