import { seededShuffle } from './random.ts';

export type Side = 'a' | 'b';

export interface WyrConfig {
  categoryIds: string[];
  rounds: number;
  seed: number;
  /** When set, a round accepts at most this many votes. */
  playerCount?: number;
}

export interface WyrRound {
  questionId: string;
  a: number;
  b: number;
  /** Votes in the order cast. In pass-the-phone play, index i is player i's pick. */
  votes: Side[];
  skipped: boolean;
}

/** Anything dealt from a pack: only the id and category matter to the engine. */
export interface PoolItem {
  id: string;
  category: string;
}

export interface WyrCurrent {
  questionId: string;
  /** Votes in the order they were cast, so undo removes the latest. */
  votes: Side[];
  revealed: boolean;
}

export interface WyrState {
  config: WyrConfig;
  /** Question ids in play order: the first `totalRounds` are dealt, the rest are skip replacements. */
  order: string[];
  /** Index in `order` of the next unused question. */
  cursor: number;
  totalRounds: number;
  rounds: WyrRound[];
  current: WyrCurrent | null;
  skips: number;
  status: 'playing' | 'finished';
}

export type WyrAction =
  | { type: 'vote'; side: Side }
  | { type: 'undo' }
  | { type: 'reveal' }
  | { type: 'next' }
  | { type: 'skip' };

export class EmptyPoolError extends Error {
  constructor() {
    super('No questions available for the selected categories.');
  }
}

/** Items in the chosen categories, in a stable (id) order so shuffles are reproducible. */
export function buildPool<T extends PoolItem>(
  items: readonly T[],
  categoryIds: readonly string[],
): T[] {
  const wanted = new Set(categoryIds);
  return items.filter((i) => wanted.has(i.category)).sort((x, y) => (x.id < y.id ? -1 : 1));
}

export function createWyrSession(pool: readonly PoolItem[], config: WyrConfig): WyrState {
  if (pool.length === 0) throw new EmptyPoolError();
  if (!Number.isInteger(config.rounds) || config.rounds < 1) {
    throw new RangeError('rounds must be a positive integer');
  }
  const order = seededShuffle(
    pool.map((i) => i.id),
    config.seed,
  );
  return {
    config,
    order,
    cursor: 1,
    totalRounds: Math.min(config.rounds, order.length),
    rounds: [],
    current: { questionId: order[0]!, votes: [], revealed: false },
    skips: 0,
    status: 'playing',
  };
}

const count = (votes: Side[], side: Side) => votes.filter((v) => v === side).length;

/** Pure reducer: returns the same state object when an action doesn't apply. */
export function reduceWyr(state: WyrState, action: WyrAction): WyrState {
  const cur = state.current;
  if (state.status === 'finished' || !cur) return state;

  switch (action.type) {
    case 'vote': {
      const cap = state.config.playerCount;
      if (cur.revealed || (cap !== undefined && cur.votes.length >= cap)) return state;
      return { ...state, current: { ...cur, votes: [...cur.votes, action.side] } };
    }
    case 'undo':
      if (cur.revealed || cur.votes.length === 0) return state;
      return { ...state, current: { ...cur, votes: cur.votes.slice(0, -1) } };
    case 'reveal':
      if (cur.revealed) return state;
      return { ...state, current: { ...cur, revealed: true } };
    case 'next':
      return advance(state, {
        questionId: cur.questionId,
        a: count(cur.votes, 'a'),
        b: count(cur.votes, 'b'),
        votes: cur.votes,
        skipped: false,
      });
    case 'skip': {
      // Swap in an unused question when one is left; otherwise the round is spent as skipped.
      if (state.cursor < state.order.length) {
        return {
          ...state,
          cursor: state.cursor + 1,
          skips: state.skips + 1,
          current: { questionId: state.order[state.cursor]!, votes: [], revealed: false },
        };
      }
      return advance(
        { ...state, skips: state.skips + 1 },
        { questionId: cur.questionId, a: 0, b: 0, votes: [], skipped: true },
      );
    }
  }
}

function advance(state: WyrState, round: WyrRound): WyrState {
  const rounds = [...state.rounds, round];
  if (rounds.length >= state.totalRounds || state.cursor >= state.order.length) {
    return { ...state, rounds, current: null, status: 'finished' };
  }
  return {
    ...state,
    rounds,
    cursor: state.cursor + 1,
    current: { questionId: state.order[state.cursor]!, votes: [], revealed: false },
  };
}

export interface WyrResults {
  roundsPlayed: number;
  roundsSkipped: number;
  totalVotes: number;
  /** Closest split (needs ≥ 2 votes). Ties go to the earliest round. */
  mostDivisive: string | null;
  /** Largest share for one side (needs ≥ 2 votes). Ties go to the earliest round. */
  mostUnanimous: string | null;
}

export function wyrResults(state: WyrState): WyrResults {
  const voted = state.rounds.filter((r) => !r.skipped && r.a + r.b >= 2);
  const share = (r: WyrRound) => Math.max(r.a, r.b) / (r.a + r.b);
  let divisive: WyrRound | null = null;
  let unanimous: WyrRound | null = null;
  for (const r of voted) {
    if (!divisive || share(r) < share(divisive)) divisive = r;
    if (!unanimous || share(r) > share(unanimous)) unanimous = r;
  }
  return {
    roundsPlayed: state.rounds.filter((r) => !r.skipped).length,
    roundsSkipped: state.rounds.filter((r) => r.skipped).length,
    totalVotes: state.rounds.reduce((n, r) => n + r.a + r.b, 0),
    mostDivisive: divisive?.questionId ?? null,
    // With a single voted round both highlights would be the same question; show only one.
    mostUnanimous: unanimous && unanimous !== divisive ? unanimous.questionId : null,
  };
}

export interface Agreement {
  /** Player indexes, lowest first. */
  players: [number, number];
  matches: number;
  rounds: number;
}

/**
 * For pass-the-phone play: the pair of players who picked the same side most often, over rounds
 * where both voted. Ties go to the lowest player indexes. Null with fewer than two players.
 */
export function bestAgreement(rounds: readonly WyrRound[], playerCount: number): Agreement | null {
  let best: Agreement | null = null;
  for (let i = 0; i < playerCount; i++) {
    for (let j = i + 1; j < playerCount; j++) {
      let matches = 0;
      let both = 0;
      for (const r of rounds) {
        const vi = r.votes[i];
        const vj = r.votes[j];
        if (vi === undefined || vj === undefined) continue;
        both++;
        if (vi === vj) matches++;
      }
      if (both > 0 && (!best || matches * best.rounds > best.matches * both)) {
        best = { players: [i, j], matches, rounds: both };
      }
    }
  }
  return best;
}
