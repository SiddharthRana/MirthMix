import type { Metadata } from 'next';
import { LegalDraftNotice } from '@/components/legal-draft';

export const metadata: Metadata = {
  title: 'Privacy',
  description: 'What MirthMix collects (very little) and why.',
  alternates: { canonical: '/privacy' },
};

export default function PrivacyPage() {
  return (
    <article className="max-w-3xl py-12">
      <h1 className="font-display text-5xl font-bold">Privacy</h1>
      <LegalDraftNotice />
      <h2 className="mt-10 font-display text-3xl font-semibold">What the app stores</h2>
      <ul className="mt-3 list-disc space-y-2 pl-6">
        <li>Your settings (theme, big text, motion and vibration preferences).</li>
        <li>The game you are playing, so it survives the app closing, and your last game setup.</li>
      </ul>
      <p className="mt-3">
        All of this stays on your phone. There are no analytics and no advertising, and nothing you
        play is sent to us.
      </p>
      <h2 className="mt-10 font-display text-3xl font-semibold">Accounts and Premium</h2>
      <p className="mt-3">
        You never need an account to play. If you buy Premium, you sign in with your email so the
        purchase works on your other devices. For that we store:
      </p>
      <ul className="mt-3 list-disc space-y-2 pl-6">
        <li>Your email address and when the account was created (with our sign-in provider).</li>
        <li>
          Your subscription: which store or payment partner you used, its status and renewal date.
          Card and payment details are handled by Google Play or our payment partner, never by us.
        </li>
        <li>
          Messages from the store about your subscription, kept for 30 days for troubleshooting.
        </li>
      </ul>
      <p className="mt-3">
        You can delete your account at any time from the Account page on this website or in the app.
        Deleting the account does not cancel a store subscription, so cancel that first.
      </p>
      <h2 className="mt-10 font-display text-3xl font-semibold">This website</h2>
      <p className="mt-3">
        This website uses no analytics. If you sign in, your browser keeps your session in local
        storage so you stay signed in. Our hosting provider may keep standard server logs (such as
        IP address and pages requested) for security.
      </p>
      <h2 className="mt-10 font-display text-3xl font-semibold">Age</h2>
      <p className="mt-3">
        MirthMix is made for ages 13 and up. We do not knowingly collect personal data from
        children.
      </p>
      <h2 className="mt-10 font-display text-3xl font-semibold">Changes</h2>
      <p className="mt-3">
        If we add analytics later, this page will be updated before they launch, and analytics will
        ask for consent where the law requires it.
      </p>
    </article>
  );
}
