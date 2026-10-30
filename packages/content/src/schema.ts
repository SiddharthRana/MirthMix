import { z } from 'zod';

export const MODE_IDS = ['would-you-rather', 'this-or-that', 'trivia', 'guess'] as const;
export type ModeId = (typeof MODE_IDS)[number];

/** Short id prefix used in item ids, e.g. `wyr-casual-001`. */
export const MODE_PREFIX: Record<ModeId, string> = {
  'would-you-rather': 'wyr',
  'this-or-that': 'tot',
  trivia: 'triv',
  guess: 'gta',
};

const slug = z
  .string()
  .regex(/^[a-z0-9]+(-[a-z0-9]+)*$/, 'must be lowercase-kebab-case')
  .max(40);

const text = (max: number) =>
  z
    .string()
    .trim()
    .min(1)
    .max(max)
    .refine((s) => !/\s{2,}/.test(s), 'must not contain repeated whitespace');

const itemId = (prefix: string) => z.string().regex(new RegExp(`^${prefix}-[a-z0-9-]+-\\d{3}$`));

export const categorySchema = z.strictObject({
  id: slug,
  name: text(40),
  description: text(140),
  /** Entitlement tier. Game logic never reads this; only the entitlement layer does. */
  tier: z.enum(['free', 'premium']),
  ageRating: z.enum(['all', '13+']),
  region: z.enum(['global', 'in']),
  /** Shown before play when a category touches on sensitive themes. */
  contentNote: text(140).optional(),
});

export const wyrItemSchema = z.strictObject({
  id: itemId('wyr'),
  category: slug,
  a: text(90),
  b: text(90),
});

export const totItemSchema = z.strictObject({
  id: itemId('tot'),
  category: slug,
  a: text(40),
  b: text(40),
});

export const triviaItemSchema = z.strictObject({
  id: itemId('triv'),
  category: slug,
  difficulty: z.enum(['easy', 'medium', 'hard']),
  question: text(160),
  choices: z.array(text(60)).length(4),
  /** Index into `choices`. */
  answer: z.int().min(0).max(3),
  explanation: text(200),
  /** Where the fact can be checked. */
  source: text(200),
  verifiedOn: z.iso.date(),
  /**
   * `draft`: never shipped. `self-checked`: checked by the author only; fine for testing.
   * `verified`: a second person checked it against `source`; required before launch.
   */
  reviewStatus: z.enum(['draft', 'self-checked', 'verified']),
});

export const guessItemSchema = z.strictObject({
  id: itemId('gta'),
  category: slug,
  answer: text(40),
  /** Revealed in order, hardest first. */
  clues: z.array(text(120)).length(3),
});

const packBase = {
  $schema: z.string().optional(),
  version: z.int().positive(),
  categories: z.array(categorySchema).min(1),
};

export const wyrPackSchema = z.strictObject({
  ...packBase,
  mode: z.literal('would-you-rather'),
  items: z.array(wyrItemSchema).min(1),
});
export const totPackSchema = z.strictObject({
  ...packBase,
  mode: z.literal('this-or-that'),
  items: z.array(totItemSchema).min(1),
});
export const triviaPackSchema = z.strictObject({
  ...packBase,
  mode: z.literal('trivia'),
  items: z.array(triviaItemSchema).min(1),
});
export const guessPackSchema = z.strictObject({
  ...packBase,
  mode: z.literal('guess'),
  items: z.array(guessItemSchema).min(1),
});

export const packSchema = z.discriminatedUnion('mode', [
  wyrPackSchema,
  totPackSchema,
  triviaPackSchema,
  guessPackSchema,
]);

export type Category = z.infer<typeof categorySchema>;
export type WyrItem = z.infer<typeof wyrItemSchema>;
export type TotItem = z.infer<typeof totItemSchema>;
export type TriviaItem = z.infer<typeof triviaItemSchema>;
export type GuessItem = z.infer<typeof guessItemSchema>;
export type WyrPack = z.infer<typeof wyrPackSchema>;
export type TotPack = z.infer<typeof totPackSchema>;
export type TriviaPack = z.infer<typeof triviaPackSchema>;
export type GuessPack = z.infer<typeof guessPackSchema>;
export type Pack = z.infer<typeof packSchema>;
