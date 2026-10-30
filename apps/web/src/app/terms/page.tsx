import type { Metadata } from 'next';
import { LegalDraftNotice } from '@/components/legal-draft';

export const metadata: Metadata = {
  title: 'Terms',
  description: 'Terms of use for MirthMix.',
  alternates: { canonical: '/terms' },
};

export default function TermsPage() {
  return (
    <article className="max-w-3xl py-12">
      <h1 className="font-display text-5xl font-bold">Terms</h1>
      <LegalDraftNotice />
      <h2 className="mt-10 font-display text-3xl font-semibold">Using MirthMix</h2>
      <p className="mt-3">
        MirthMix is a party game for people playing together in person. Play kindly: skip any
        question that doesn&rsquo;t suit your group, and never pressure anyone to answer.
      </p>
      <h2 className="mt-10 font-display text-3xl font-semibold">Content</h2>
      <p className="mt-3">
        Questions are original to MirthMix and provided for entertainment. They are not advice.
      </p>
      <h2 className="mt-10 font-display text-3xl font-semibold">Subscriptions</h2>
      <p className="mt-3">
        Paid features are not available yet. These terms will describe billing, renewal,
        cancellation and refunds before any purchase is offered.
      </p>
    </article>
  );
}
