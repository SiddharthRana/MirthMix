import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import type { WyrItem } from '@mirthmix/content';
import { describe, expect, it } from 'vitest';
import { createRng, seededShuffle } from '../src/random.ts';
import {
  buildPool,
  createWyrSession,
  EmptyPoolError,
  reduceWyr,
  wyrResults,
  type WyrAction,
  type WyrConfig,
  type WyrResults,
  type WyrState,
} from '../src/would-you-rather.ts';

const item = (cat: string, n: number): WyrItem => ({
  id: `wyr-${cat}-${String(n).padStart(3, '0')}`,
  category: cat,
  a: `${cat} a${n}`,
  b: `${cat} b${n}`,
});
const pool = [1, 2, 3, 4, 5].map((n) => item('casual', n));
const play = (s: WyrState, ...actions: WyrAction[]) => actions.reduce(reduceWyr, s);
const vote = (side: 'a' | 'b'): WyrAction => ({ type: 'vote', side });

describe('random', () => {
  it('is deterministic per seed and differs between seeds', () => {
    const a = createRng(5);
    const b = createRng(5);
    const c = createRng(6);
    const seqA = [a(), a(), a()];
    expect([b(), b(), b()]).toEqual(seqA);
    expect([c(), c(), c()]).not.toEqual(seqA);
    for (const v of seqA) expect(v).toBeGreaterThanOrEqual(0);
    for (const v of seqA) expect(v).toBeLessThan(2 ** 32);
  });

  it('shuffles without losing or duplicating items, and leaves the input alone', () => {
    const input = Array.from({ length: 50 }, (_, i) => i);
    const out = seededShuffle(input, 3);
    expect([...out].sort((x, y) => x - y)).toEqual(input);
    expect(out).not.toEqual(input);
    expect(input[0]).toBe(0);
  });
});

describe('buildPool', () => {
  it('keeps only the chosen categories in id order regardless of input order', () => {
    const mixed = [item('funny', 2), item('casual', 2), item('funny', 1), item('casual', 1)];
    expect(buildPool(mixed, ['funny']).map((i) => i.id)).toEqual(['wyr-funny-001', 'wyr-funny-002']);
  });
});

describe('Would You Rather session', () => {
  it('rejects an empty pool and invalid round counts', () => {
    expect(() => createWyrSession([], { categoryIds: [], rounds: 5, seed: 1 })).toThrow(EmptyPoolError);
    expect(() => createWyrSession(pool, { categoryIds: ['casual'], rounds: 0, seed: 1 })).toThrow(
      RangeError,
    );
  });

  it('plays the configured number of rounds and records votes', () => {
    let s = createWyrSession(pool, { categoryIds: ['casual'], rounds: 2, seed: 1 });
    expect(s.totalRounds).toBe(2);
    s = play(s, vote('a'), vote('a'), vote('b'), { type: 'next' });
    expect(s.rounds[0]).toMatchObject({ a: 2, b: 1, skipped: false });
    expect(s.status).toBe('playing');
    s = play(s, { type: 'next' });
    expect(s.status).toBe('finished');
    expect(s.current).toBeNull();
    expect(s.rounds).toHaveLength(2);
  });

  it('never repeats a question within a session', () => {
    let s = createWyrSession(pool, { categoryIds: ['casual'], rounds: 5, seed: 9 });
    const seen: string[] = [];
    while (s.current) {
      seen.push(s.current.questionId);
      s = play(s, { type: 'next' });
    }
    expect(new Set(seen).size).toBe(5);
  });

  it('caps rounds at the pool size', () => {
    const s = createWyrSession(pool, { categoryIds: ['casual'], rounds: 20, seed: 1 });
    expect(s.totalRounds).toBe(5);
  });

  it('undo removes the latest vote and does nothing when there are none', () => {
    let s = createWyrSession(pool, { categoryIds: ['casual'], rounds: 1, seed: 1 });
    expect(play(s, { type: 'undo' })).toBe(s);
    s = play(s, vote('a'), vote('b'), { type: 'undo' });
    expect(s.current?.votes).toEqual(['a']);
  });

  it('locks votes after reveal', () => {
    const s = play(createWyrSession(pool, { categoryIds: ['casual'], rounds: 1, seed: 1 }), vote('a'), {
      type: 'reveal',
    });
    expect(play(s, vote('b'))).toBe(s);
    expect(play(s, { type: 'undo' })).toBe(s);
    expect(play(s, { type: 'reveal' })).toBe(s);
  });

  it('respects the player cap', () => {
    const s = play(
      createWyrSession(pool, { categoryIds: ['casual'], rounds: 1, seed: 1, playerCount: 2 }),
      vote('a'),
      vote('b'),
      vote('a'),
    );
    expect(s.current?.votes).toEqual(['a', 'b']);
  });

  it('skip replaces the question without using up a round', () => {
    let s = createWyrSession(pool, { categoryIds: ['casual'], rounds: 2, seed: 1 });
    const first = s.current!.questionId;
    s = play(s, vote('a'), { type: 'skip' });
    expect(s.current!.questionId).not.toBe(first);
    expect(s.current!.votes).toEqual([]);
    expect(s.rounds).toHaveLength(0);
    expect(s.skips).toBe(1);
  });

  it('skip spends the round when no spare questions remain', () => {
    let s = createWyrSession(pool.slice(0, 1), { categoryIds: ['casual'], rounds: 1, seed: 1 });
    s = play(s, { type: 'skip' });
    expect(s.status).toBe('finished');
    expect(s.rounds[0]).toMatchObject({ skipped: true, a: 0, b: 0 });
  });

  it('ignores every action once finished', () => {
    const s = play(createWyrSession(pool, { categoryIds: ['casual'], rounds: 1, seed: 1 }), {
      type: 'next',
    });
    for (const a of [vote('a'), { type: 'next' }, { type: 'skip' }] as WyrAction[]) {
      expect(play(s, a)).toBe(s);
    }
  });
});

describe('wyrResults', () => {
  const base = createWyrSession(pool, { categoryIds: ['casual'], rounds: 4, seed: 1 });

  it('finds the most divisive and most unanimous rounds', () => {
    const s = play(
      base,
      ...[vote('a'), vote('a'), vote('a'), { type: 'next' } as WyrAction],
      ...[vote('a'), vote('b'), { type: 'next' } as WyrAction],
      ...[{ type: 'skip' } as WyrAction, { type: 'next' } as WyrAction],
      ...[vote('b'), { type: 'next' } as WyrAction],
    );
    const r = wyrResults(s);
    expect(r.totalVotes).toBe(6);
    expect(r.roundsPlayed).toBe(4);
    expect(r.roundsSkipped).toBe(0);
    expect(r.mostUnanimous).toBe(s.rounds[0]!.questionId);
    expect(r.mostDivisive).toBe(s.rounds[1]!.questionId);
  });

  it('has no highlights without enough votes', () => {
    const r = wyrResults(play(base, vote('a'), { type: 'next' }));
    expect(r.mostDivisive).toBeNull();
    expect(r.mostUnanimous).toBeNull();
  });

  it('does not show the same question twice', () => {
    const r = wyrResults(play(base, vote('a'), vote('b'), { type: 'next' }));
    expect(r.mostDivisive).not.toBeNull();
    expect(r.mostUnanimous).toBeNull();
  });
});

describe('shared test vectors', () => {
  type Vector = {
    name: string;
    config: WyrConfig;
    actions: WyrAction[];
    expected: Pick<WyrState, 'order' | 'rounds' | 'current'> & { results: WyrResults };
  };
  const vectors = JSON.parse(
    readFileSync(join(import.meta.dirname, '../test-vectors/would-you-rather.json'), 'utf8'),
  ) as { items: WyrItem[]; wyr: Vector[] };

  it.each(vectors.wyr)('$name', ({ config, actions, expected }) => {
    let s = createWyrSession(buildPool(vectors.items, config.categoryIds), config);
    for (const a of actions) s = reduceWyr(s, a);
    expect(s.order).toEqual(expected.order);
    expect(s.rounds).toEqual(expected.rounds);
    expect(s.current).toEqual(expected.current);
    expect(wyrResults(s)).toEqual(expected.results);
  });
});
