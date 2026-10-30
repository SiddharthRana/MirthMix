import type { Metadata } from 'next';
import { wyr, wyrCount } from '@/lib/content';

export const metadata: Metadata = {
  title: 'Would You Rather',
  description:
    'Play Would You Rather on one phone: read two choices aloud, everyone votes, and see how the room splits.',
  alternates: { canonical: '/games/would-you-rather' },
};

const rules = [
  'Pick categories and how many rounds to play (5 to 20).',
  'Read both options aloud. Everyone raises a hand for their pick.',
  'Tap each side once per vote. Made a mistake? Undo.',
  'Reveal to see the split, then move on to the next round.',
  'At the end, see the most divisive and the most unanimous questions.',
];

const tips = [
  'Set a group size so nobody can vote twice.',
  'Skip any question that doesn’t suit your group. It won’t use up a round.',
  'Ask the minority to defend their pick before you reveal the next one.',
];

export default function WouldYouRatherPage() {
  const sample = wyr.items.find((i) => i.category === 'funny') ?? wyr.items[0]!;
  return (
    <div className="py-12">
      <p className="font-bold text-primary">Game guide</p>
      <h1 className="mt-1 font-display text-5xl font-bold">Would You Rather</h1>
      <p className="mt-3 max-w-2xl text-lg text-muted">
        Two choices, one room, no fence-sitting. The classic conversation starter, built for passing
        around a single phone.
      </p>

      <figure className="mt-8 grid gap-3 sm:grid-cols-2" aria-label="Example question">
        <div className="rounded-panel bg-option-a p-6 font-display text-2xl font-semibold text-on-option">
          {sample.a}
        </div>
        <div className="rounded-panel bg-option-b p-6 font-display text-2xl font-semibold text-on-option">
          {sample.b}
        </div>
      </figure>

      <section aria-labelledby="rules" className="mt-12">
        <h2 id="rules" className="font-display text-3xl font-semibold">
          How to play
        </h2>
        <ol className="mt-4 list-decimal space-y-2 pl-6 text-lg">
          {rules.map((r) => (
            <li key={r}>{r}</li>
          ))}
        </ol>
      </section>

      <section aria-labelledby="categories" className="mt-12">
        <h2 id="categories" className="font-display text-3xl font-semibold">
          Categories
        </h2>
        <p className="mt-2 text-muted">{wyrCount()} original questions in the starter pack.</p>
        <ul className="mt-6 grid gap-4 sm:grid-cols-2">
          {wyr.categories.map((c) => (
            <li key={c.id} className="rounded-card border border-border bg-surface p-5">
              <div className="flex flex-wrap items-center gap-2">
                <h3 className="font-display text-2xl font-semibold">{c.name}</h3>
                {c.tier === 'premium' && (
                  <span className="rounded-full bg-accent px-3 py-1 text-sm font-bold text-on-accent">
                    Premium
                  </span>
                )}
                {c.ageRating === '13+' && (
                  <span className="rounded-full bg-surface-muted px-3 py-1 text-sm font-bold">
                    13+
                  </span>
                )}
              </div>
              <p className="mt-1 text-muted">{c.description}</p>
              {c.contentNote && <p className="mt-2 text-sm">Note: {c.contentNote}</p>}
              <p className="mt-2 text-sm font-bold">{wyrCount(c.id)} questions</p>
            </li>
          ))}
        </ul>
      </section>

      <section aria-labelledby="tips" className="mt-12">
        <h2 id="tips" className="font-display text-3xl font-semibold">
          Tips for a great round
        </h2>
        <ul className="mt-4 list-disc space-y-2 pl-6 text-lg">
          {tips.map((t) => (
            <li key={t}>{t}</li>
          ))}
        </ul>
      </section>
    </div>
  );
}
