import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';
import { validatePack } from '../src/validate.ts';

const packsDir = join(import.meta.dirname, '../packs');

const basePack = () => ({
  mode: 'would-you-rather',
  version: 1,
  categories: [
    {
      id: 'casual',
      name: 'Casual',
      description: 'Easy ones.',
      tier: 'free',
      ageRating: 'all',
      region: 'global',
    },
  ],
  items: [
    { id: 'wyr-casual-001', category: 'casual', a: 'Tea', b: 'Coffee' },
    { id: 'wyr-casual-002', category: 'casual', a: 'Beach', b: 'Mountains' },
  ],
});

const errorsOf = (pack: unknown) => {
  const r = validatePack(pack);
  return r.ok ? [] : r.errors;
};

describe('shipped packs', () => {
  const files = readdirSync(packsDir).filter((f) => f.endsWith('.json'));

  it('exist', () => expect(files.length).toBeGreaterThan(0));

  it.each(files)('%s is valid', (file) => {
    expect(errorsOf(JSON.parse(readFileSync(join(packsDir, file), 'utf8')))).toEqual([]);
  });

  it('would-you-rather has free content in every free category and at least 100 items', () => {
    const pack = JSON.parse(readFileSync(join(packsDir, 'would-you-rather.json'), 'utf8'));
    expect(pack.items.length).toBeGreaterThanOrEqual(100);
    const free = pack.categories.filter((c: { tier: string }) => c.tier === 'free');
    expect(free.length).toBeGreaterThanOrEqual(4);
  });
});

describe('validatePack', () => {
  it('accepts a minimal valid pack', () => {
    expect(validatePack(basePack()).ok).toBe(true);
  });

  it('rejects an unknown mode', () => {
    expect(errorsOf({ ...basePack(), mode: 'charades' })[0]).toMatch(/mode/);
  });

  it('rejects missing and over-long fields', () => {
    const pack = basePack();
    pack.items[0] = { id: 'wyr-casual-001', category: 'casual', a: '', b: 'x'.repeat(91) };
    const errors = errorsOf(pack);
    expect(errors.some((e) => e.startsWith('items.0.a'))).toBe(true);
    expect(errors.some((e) => e.startsWith('items.0.b'))).toBe(true);
  });

  it('rejects unexpected fields (typos)', () => {
    const pack = basePack();
    (pack.items[0] as Record<string, unknown>).optionA = 'Tea';
    expect(errorsOf(pack).length).toBeGreaterThan(0);
  });

  it('rejects duplicate ids', () => {
    const pack = basePack();
    pack.items[1]!.id = 'wyr-casual-001';
    expect(errorsOf(pack)).toContain('items: duplicate id "wyr-casual-001"');
  });

  it('rejects items in unknown categories', () => {
    const pack = basePack();
    pack.items[1] = { id: 'wyr-spicy-001', category: 'spicy', a: 'A', b: 'B' };
    expect(errorsOf(pack)).toContain('wyr-spicy-001: unknown category "spicy"');
  });

  it('rejects ids that do not match their category', () => {
    const pack = basePack();
    pack.categories.push({ ...pack.categories[0]!, id: 'funny', name: 'Funny' });
    pack.items[1]!.category = 'funny';
    expect(errorsOf(pack)).toContain('wyr-casual-002: id must start with "wyr-funny-"');
  });

  it('rejects empty categories', () => {
    const pack = basePack();
    pack.categories.push({ ...pack.categories[0]!, id: 'empty', name: 'Empty' });
    expect(errorsOf(pack)).toContain('category "empty" has no items');
  });

  it('rejects duplicate questions, even with options swapped or different punctuation', () => {
    const pack = basePack();
    pack.items[1] = { id: 'wyr-casual-002', category: 'casual', a: 'coffee!', b: 'Tea' };
    expect(errorsOf(pack)).toContain('wyr-casual-002: duplicate of wyr-casual-001');
  });

  it('rejects identical options', () => {
    const pack = basePack();
    pack.items[1] = { id: 'wyr-casual-002', category: 'casual', a: 'Pizza', b: 'pizza' };
    expect(errorsOf(pack)).toContain('wyr-casual-002: both options are the same');
  });

  it('rejects non-objects', () => {
    expect(validatePack(null).ok).toBe(false);
    expect(validatePack([]).ok).toBe(false);
  });
});

describe('other modes', () => {
  const cat = {
    id: 'science',
    name: 'Science',
    description: 'x',
    tier: 'free',
    ageRating: 'all',
    region: 'global',
  };
  const trivia = (over: Record<string, unknown> = {}) => ({
    mode: 'trivia',
    version: 1,
    categories: [cat],
    items: [
      {
        id: 'triv-science-001',
        category: 'science',
        difficulty: 'easy',
        question: 'Q?',
        choices: ['A', 'B', 'C', 'D'],
        answer: 0,
        explanation: 'E',
        source: 'S',
        verifiedOn: '2026-10-30',
        reviewStatus: 'self-checked',
        ...over,
      },
    ],
  });
  const guess = (clues: string[]) => ({
    mode: 'guess',
    version: 1,
    categories: [cat],
    items: [{ id: 'gta-science-001', category: 'science', answer: 'Magnet', clues }],
  });

  it('accepts valid trivia and guess packs', () => {
    expect(errorsOf(trivia())).toEqual([]);
    expect(errorsOf(guess(['One', 'Two', 'Three']))).toEqual([]);
  });

  it('rejects trivia with the wrong number of choices, a bad answer index or a bad date', () => {
    expect(errorsOf(trivia({ choices: ['A', 'B', 'C'] })).length).toBeGreaterThan(0);
    expect(errorsOf(trivia({ answer: 4 })).length).toBeGreaterThan(0);
    expect(errorsOf(trivia({ verifiedOn: 'yesterday' })).length).toBeGreaterThan(0);
    expect(errorsOf(trivia({ reviewStatus: 'trust-me' })).length).toBeGreaterThan(0);
  });

  it('rejects duplicate trivia choices', () => {
    expect(errorsOf(trivia({ choices: ['A', 'a', 'C', 'D'] }))).toContain(
      'triv-science-001: choices must be different',
    );
  });

  it('rejects guess clues that give away the answer', () => {
    expect(errorsOf(guess(['It sticks to fridges', 'A magnet!', 'Three']))).toContain(
      'gta-science-001: a clue gives away the answer',
    );
  });

  it('rejects ids with the wrong mode prefix', () => {
    const pack = guess(['One', 'Two', 'Three']);
    pack.items[0]!.id = 'wyr-science-001';
    expect(errorsOf(pack).length).toBeGreaterThan(0);
  });

  it.each(['this-or-that', 'trivia', 'guess'])('%s ships free and premium categories', (mode) => {
    const pack = JSON.parse(readFileSync(join(packsDir, `${mode}.json`), 'utf8'));
    const tiers = new Set(pack.categories.map((c: { tier: string }) => c.tier));
    expect(tiers).toEqual(new Set(['free', 'premium']));
  });
});
