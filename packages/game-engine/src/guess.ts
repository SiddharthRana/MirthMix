import { seededShuffle } from './random.ts';
import { EmptyPoolError, type PoolItem } from './would-you-rather.ts';

export const CLUES_PER_CARD = 3;

export interface GuessConfig {
  categoryIds: string[];
  rounds: number;
  seed: number;
  /** Players or teams taking turns; 1 means the whole group plays together. */
  teams: number;
}

export interface GuessCurrent {
  questionId: string;
  team: number;
  /** How many clues are visible (1–3). */
  cluesShown: number;
  outcome: 'got' | 'revealed' | null;
}

export interface GuessRound {
  questionId: string;
  team: number;
  cluesShown: number;
  outcome: 'got' | 'revealed' | 'skipped';
  points: number;
}

export interface GuessState {
  config: GuessConfig;
  order: string[];
  cursor: number;
  totalRounds: number;
  rounds: GuessRound[];
  current: GuessCurrent | null;
  scores: number[];
  status: 'playing' | 'finished';
}

export type GuessAction =
  { type: 'clue' } | { type: 'got' } | { type: 'reveal' } | { type: 'next' } | { type: 'skip' };

/** 3 points on the first clue, 2 on the second, 1 on the third. */
export const pointsFor = (cluesShown: number) => CLUES_PER_CARD + 1 - cluesShown;

export function createGuessSession(pool: readonly PoolItem[], config: GuessConfig): GuessState {
  if (pool.length === 0) throw new EmptyPoolError();
  if (!Number.isInteger(config.rounds) || config.rounds < 1) {
    throw new RangeError('rounds must be a positive integer');
  }
  if (!Number.isInteger(config.teams) || config.teams < 1) {
    throw new RangeError('teams must be a positive integer');
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
    current: { questionId: order[0]!, team: 0, cluesShown: 1, outcome: null },
    scores: Array.from({ length: config.teams }, () => 0),
    status: 'playing',
  };
}

export function reduceGuess(state: GuessState, action: GuessAction): GuessState {
  const cur = state.current;
  if (state.status === 'finished' || !cur) return state;

  switch (action.type) {
    case 'clue':
      if (cur.outcome || cur.cluesShown >= CLUES_PER_CARD) return state;
      return { ...state, current: { ...cur, cluesShown: cur.cluesShown + 1 } };
    case 'got':
    case 'reveal':
      if (cur.outcome) return state;
      return {
        ...state,
        current: { ...cur, outcome: action.type === 'got' ? 'got' : 'revealed' },
      };
    case 'next':
      if (!cur.outcome) return state;
      return advance(state, {
        questionId: cur.questionId,
        team: cur.team,
        cluesShown: cur.cluesShown,
        outcome: cur.outcome,
        points: cur.outcome === 'got' ? pointsFor(cur.cluesShown) : 0,
      });
    case 'skip':
      if (cur.outcome) return state;
      if (state.cursor < state.order.length) {
        return {
          ...state,
          cursor: state.cursor + 1,
          current: {
            questionId: state.order[state.cursor]!,
            team: cur.team,
            cluesShown: 1,
            outcome: null,
          },
        };
      }
      return advance(state, {
        questionId: cur.questionId,
        team: cur.team,
        cluesShown: cur.cluesShown,
        outcome: 'skipped',
        points: 0,
      });
  }
}

function advance(state: GuessState, round: GuessRound): GuessState {
  const rounds = [...state.rounds, round];
  const scores = state.scores.map((s, t) => (t === round.team ? s + round.points : s));
  if (rounds.length >= state.totalRounds || state.cursor >= state.order.length) {
    return { ...state, rounds, scores, current: null, status: 'finished' };
  }
  return {
    ...state,
    rounds,
    scores,
    cursor: state.cursor + 1,
    current: {
      questionId: state.order[state.cursor]!,
      team: rounds.length % state.config.teams,
      cluesShown: 1,
      outcome: null,
    },
  };
}

export interface GuessResults {
  /** Team indexes, highest score first; ties keep team order. */
  ranking: number[];
  winners: number[];
  solved: number;
  played: number;
}

export function guessResults(state: GuessState): GuessResults {
  const ranking = state.scores
    .map((score, team) => ({ score, team }))
    .sort((x, y) => y.score - x.score || x.team - y.team)
    .map((s) => s.team);
  const top = Math.max(0, ...state.scores);
  return {
    ranking,
    winners: top > 0 ? ranking.filter((t) => state.scores[t] === top) : [],
    solved: state.rounds.filter((r) => r.outcome === 'got').length,
    played: state.rounds.filter((r) => r.outcome !== 'skipped').length,
  };
}
