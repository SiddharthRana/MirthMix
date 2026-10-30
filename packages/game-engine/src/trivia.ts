import { seededShuffle } from './random.ts';
import { EmptyPoolError, type PoolItem } from './would-you-rather.ts';

export interface TriviaPoolItem extends PoolItem {
  /** Index of the correct choice in the pack's (unshuffled) choices. */
  answer: number;
}

export interface TriviaConfig {
  categoryIds: string[];
  rounds: number;
  seed: number;
  /** Players or teams taking turns; 1 means the whole group plays together. */
  teams: number;
  /** Per-question time limit; 0 turns the timer (and the speed bonus) off. */
  timeLimitMs: number;
}

export const CORRECT_POINTS = 100;
export const MAX_SPEED_BONUS = 50;

export interface TriviaCurrent {
  questionId: string;
  team: number;
  /** Display order: `choiceOrder[i]` is the pack index of the choice shown in position i. */
  choiceOrder: number[];
  /** Pack index of the correct choice. */
  answer: number;
  /** Pack index of the picked choice; null until answered (and after a timeout). */
  picked: number | null;
  timedOut: boolean;
  points: number;
}

export interface TriviaRound {
  questionId: string;
  team: number;
  picked: number | null;
  correct: boolean;
  timedOut: boolean;
  skipped: boolean;
  points: number;
}

export interface TriviaState {
  config: TriviaConfig;
  order: string[];
  /** Pack answer index per entry in `order`. */
  answers: number[];
  cursor: number;
  totalRounds: number;
  rounds: TriviaRound[];
  current: TriviaCurrent | null;
  scores: number[];
  status: 'playing' | 'finished';
}

export type TriviaAction =
  | { type: 'answer'; choice: number; elapsedMs: number }
  | { type: 'timeout' }
  | { type: 'next' }
  | { type: 'skip' };

export function createTriviaSession(
  pool: readonly TriviaPoolItem[],
  config: TriviaConfig,
): TriviaState {
  if (pool.length === 0) throw new EmptyPoolError();
  if (!Number.isInteger(config.rounds) || config.rounds < 1) {
    throw new RangeError('rounds must be a positive integer');
  }
  if (!Number.isInteger(config.teams) || config.teams < 1) {
    throw new RangeError('teams must be a positive integer');
  }
  const shuffled = seededShuffle(pool, config.seed);
  const base: TriviaState = {
    config,
    order: shuffled.map((i) => i.id),
    answers: shuffled.map((i) => i.answer),
    cursor: 0,
    totalRounds: Math.min(config.rounds, shuffled.length),
    rounds: [],
    current: null,
    scores: Array.from({ length: config.teams }, () => 0),
    status: 'playing',
  };
  return deal(base, 0);
}

/** Puts the question at `cursor` in play for `team`, with its own seeded choice order. */
function deal(state: TriviaState, team: number): TriviaState {
  const i = state.cursor;
  return {
    ...state,
    cursor: i + 1,
    current: {
      questionId: state.order[i]!,
      team,
      choiceOrder: seededShuffle([0, 1, 2, 3], (state.config.seed + i + 1) >>> 0),
      answer: state.answers[i]!,
      picked: null,
      timedOut: false,
      points: 0,
    },
  };
}

export function speedBonus(elapsedMs: number, timeLimitMs: number): number {
  if (timeLimitMs <= 0) return 0;
  const left = Math.min(timeLimitMs, Math.max(0, timeLimitMs - Math.max(0, Math.floor(elapsedMs))));
  return Math.floor((MAX_SPEED_BONUS * left) / timeLimitMs);
}

export function reduceTrivia(state: TriviaState, action: TriviaAction): TriviaState {
  const cur = state.current;
  if (state.status === 'finished' || !cur) return state;
  const answered = cur.picked !== null || cur.timedOut;

  switch (action.type) {
    case 'answer': {
      const picked = cur.choiceOrder[action.choice];
      if (answered || picked === undefined) return state;
      const points =
        picked === cur.answer
          ? CORRECT_POINTS + speedBonus(action.elapsedMs, state.config.timeLimitMs)
          : 0;
      return { ...state, current: { ...cur, picked, points } };
    }
    case 'timeout':
      if (answered || state.config.timeLimitMs <= 0) return state;
      return { ...state, current: { ...cur, timedOut: true } };
    case 'next':
      if (!answered) return state;
      return advance(state, {
        questionId: cur.questionId,
        team: cur.team,
        picked: cur.picked,
        correct: cur.picked === cur.answer,
        timedOut: cur.timedOut,
        skipped: false,
        points: cur.points,
      });
    case 'skip':
      if (answered) return state;
      if (state.cursor < state.order.length) return deal(state, cur.team);
      return advance(state, {
        questionId: cur.questionId,
        team: cur.team,
        picked: null,
        correct: false,
        timedOut: false,
        skipped: true,
        points: 0,
      });
  }
}

function advance(state: TriviaState, round: TriviaRound): TriviaState {
  const rounds = [...state.rounds, round];
  const scores = state.scores.map((s, t) => (t === round.team ? s + round.points : s));
  if (rounds.length >= state.totalRounds || state.cursor >= state.order.length) {
    return { ...state, rounds, scores, current: null, status: 'finished' };
  }
  return deal({ ...state, rounds, scores }, rounds.length % state.config.teams);
}

export interface TeamResult {
  team: number;
  score: number;
  correct: number;
  answered: number;
}

export interface TriviaResults {
  /** Highest score first; ties keep team order. */
  standings: TeamResult[];
  /** Teams sharing the top score (empty when nobody scored). */
  winners: number[];
  correct: number;
  played: number;
}

export function triviaResults(state: TriviaState): TriviaResults {
  const standings = state.scores
    .map((score, team) => {
      const mine = state.rounds.filter((r) => r.team === team && !r.skipped);
      return {
        team,
        score,
        correct: mine.filter((r) => r.correct).length,
        answered: mine.length,
      };
    })
    .sort((x, y) => y.score - x.score || x.team - y.team);
  const top = standings[0]?.score ?? 0;
  return {
    standings,
    winners: top > 0 ? standings.filter((s) => s.score === top).map((s) => s.team) : [],
    correct: state.rounds.filter((r) => r.correct).length,
    played: state.rounds.filter((r) => !r.skipped).length,
  };
}
