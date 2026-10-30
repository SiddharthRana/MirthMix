import { z } from 'zod';

export const MODE_IDS = ['would-you-rather'] as const;
export type ModeId = (typeof MODE_IDS)[number];

/** Short id prefix used in item ids, e.g. `wyr-casual-001`. */
export const MODE_PREFIX: Record<ModeId, string> = {
  'would-you-rather': 'wyr',
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
  id: z.string().regex(/^wyr-[a-z0-9-]+-\d{3}$/),
  category: slug,
  a: text(90),
  b: text(90),
});

export const wyrPackSchema = z.strictObject({
  $schema: z.string().optional(),
  mode: z.literal('would-you-rather'),
  version: z.int().positive(),
  categories: z.array(categorySchema).min(1),
  items: z.array(wyrItemSchema).min(1),
});

export const packSchema = z.discriminatedUnion('mode', [wyrPackSchema]);

export type Category = z.infer<typeof categorySchema>;
export type WyrItem = z.infer<typeof wyrItemSchema>;
export type WyrPack = z.infer<typeof wyrPackSchema>;
export type Pack = z.infer<typeof packSchema>;
