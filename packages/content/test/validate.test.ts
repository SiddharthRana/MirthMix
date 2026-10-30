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
