'use client';

import Link from 'next/link';
import { useState } from 'react';
import { apiFetch, ApiError, errorMessage } from '@/lib/api';
import { useBillingConfig } from '@/lib/billing';
import { useSession } from '@/lib/supabase';
import { primary, secondary } from '@/lib/ui';

/** Web checkout for Premium; honest about availability. */
export function SubscribeButtons() {
  const config = useBillingConfig();
  const session = useSession();
  const [busy, setBusy] = useState<'monthly' | 'annual' | null>(null);
  const [error, setError] = useState<{ text: string; already?: boolean } | null>(null);

  if (!config || session === undefined)
    return <p className="mt-6 text-muted">Checking availability…</p>;
  if (!config.enabled || !config.web.available) {
    return (
      <p className="mt-6 rounded-card bg-surface-muted p-4">
        Premium isn’t on sale on the website yet. Everything free works today.
      </p>
    );
  }
  if (!session) {
    return (
      <Link href="/account?next=pricing" className={`${primary} mt-6 inline-flex items-center`}>
        Sign in to subscribe
      </Link>
    );
  }

  async function start(interval: 'monthly' | 'annual') {
    setBusy(interval);
    setError(null);
    try {
      const { url } = await apiFetch<{ url: string }>('/v1/billing/checkout', {
        method: 'POST',
        body: { interval },
      });
      window.location.assign(url);
      return;
    } catch (err) {
      setError({
        text: errorMessage(err),
        already: err instanceof ApiError && err.code === 'already_subscribed',
      });
    }
    setBusy(null);
  }

  return (
    <div className="mt-6 flex flex-col gap-3">
      {config.web.intervals.includes('monthly') && (
        <button
          type="button"
          disabled={busy !== null}
          onClick={() => start('monthly')}
          className={primary}
        >
          {busy === 'monthly' ? 'Opening checkout…' : 'Subscribe monthly'}
        </button>
      )}
      {config.web.intervals.includes('annual') && (
        <button
          type="button"
          disabled={busy !== null}
          onClick={() => start('annual')}
          className={secondary}
        >
          {busy === 'annual' ? 'Opening checkout…' : 'Subscribe yearly'}
        </button>
      )}
      {error && (
        <p role="alert" className="font-bold">
          {error.text}{' '}
          {error.already && (
            <Link href="/account" className="underline">
              Manage your subscription
            </Link>
          )}
        </p>
      )}
      <p className="text-sm text-muted">
        Secure checkout by our payment partner, who handles taxes and invoices.
      </p>
    </div>
  );
}
