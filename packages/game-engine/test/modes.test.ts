import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';
import {
  createGuessSession,
  guessResults,
  pointsFor,
  reduceGuess,
  type GuessAction,
  type GuessConfig,
  type GuessState,
} from '../src/guess.ts';
import {
  createTriviaSession,
  reduceTrivia,
  speedBonus,
  triviaResults,
  type TriviaAction,
  type TriviaConfig,
  type TriviaPoolItem,
  type TriviaState,
} from '../src/trivia.ts';
import {
  bestAgreement,
  buildPool,
  EmptyPoolError,
  type PoolItem,
  type WyrRound,
} from '../src/would-you-rather.ts';

const vectorsDir = join(import.meta.dirname, '../test-vectors');
const load = (f: string): unknown => JSON.parse(readFileSync(join(vectorsDir, f), 'utf8'));
type Scenario<C, A> = { name: string; config: C; actions: A[]; expected: unknown };

const tPool = [0, 1, 2, 3, 0].map((answer, i) => ({ id: `triv-x-00${i}`, category: 'x', answer }));
const tConfig: TriviaConfig = {
  categoryIds: ['x'],
  rounds: 3,
  seed: 1,
  teams: 2,
  timeLimitMs: 20000,
};
const tPlay = (s: TriviaState, ...a: TriviaAction[]) => a.reduce(reduceTrivia, s);
/** Display position of the correct answer for the current question. */
const correctPos = (s: TriviaState) => s.current!.choiceOrder.indexOf(s.current!.answer);

describe('trivia', () => {
  it('validates input', () => {
    expect(() => createTriviaSession([], tConfig)).toThrow(EmptyPoolError);
    expect(() => createTriviaSession(tPool, { ...tConfig, teams: 0 })).toThrow(RangeError);
  });

  it('shuffles choices per question but keeps every choice', () => {
    const s = createTriviaSession(tPool, tConfig);
    expect([...s.current!.choiceOrder].sort()).toEqual([0, 1, 2, 3]);
  });

  it('scores correct answers with a speed bonus and alternates teams', () => {
    let s = createTriviaSession(tPool, tConfig);
    expect(s.current!.team).toBe(0);
    s = tPlay(s, { type: 'answer', choice: correctPos(s), elapsedMs: 0 });
    expect(s.current!.points).toBe(150);
    s = tPlay(s, { type: 'next' });
    expect(s.current!.team).toBe(1);
    s = tPlay(
      s,
      { type: 'answer', choice: (correctPos(s) + 1) % 4, elapsedMs: 0 },
      { type: 'next' },
    );
    expect(s.scores).toEqual([150, 0]);
    expect(s.rounds[1]!.correct).toBe(false);
  });

  it('needs an answer or timeout before moving on, and locks after answering', () => {
    let s = createTriviaSession(tPool, tConfig);
    expect(tPlay(s, { type: 'next' })).toBe(s);
    s = tPlay(s, { type: 'timeout' });
    expect(s.current!.timedOut).toBe(true);
    expect(tPlay(s, { type: 'answer', choice: 0, elapsedMs: 0 })).toBe(s);
    expect(tPlay(s, { type: 'skip' })).toBe(s);
  });

  it('speed bonus is bounded', () => {
    expect(speedBonus(0, 20000)).toBe(50);
    expect(speedBonus(10000, 20000)).toBe(25);
    expect(speedBonus(30000, 20000)).toBe(0);
    expect(speedBonus(-5, 20000)).toBe(50);
    expect(speedBonus(0, 0)).toBe(0);
  });

  it('results rank teams and report winners', () => {
    let s = createTriviaSession(tPool, { ...tConfig, rounds: 2 });
    s = tPlay(s, { type: 'timeout' }, { type: 'next' });
    s = tPlay(s, { type: 'answer', choice: correctPos(s), elapsedMs: 20000 }, { type: 'next' });
    const r = triviaResults(s);
    expect(s.status).toBe('finished');
    expect(r.standings.map((x) => x.team)).toEqual([1, 0]);
    expect(r.winners).toEqual([1]);
    expect(r.correct).toBe(1);
  });
});

const gPool = [1, 2, 3, 4].map((n) => ({ id: `gta-x-00${n}`, category: 'x' }));
const gConfig: GuessConfig = { categoryIds: ['x'], rounds: 3, seed: 2, teams: 2 };
const gPlay = (s: GuessState, ...a: GuessAction['type'][]) =>
  a.reduce((st, type) => reduceGuess(st, { type }), s);

describe('guess the answer', () => {
  it('awards 3/2/1 points by clues used', () => {
    expect([1, 2, 3].map(pointsFor)).toEqual([3, 2, 1]);
    const s = gPlay(createGuessSession(gPool, gConfig), 'clue', 'got', 'next');
    expect(s.scores).toEqual([2, 0]);
    expect(s.current!.team).toBe(1);
  });

  it('caps clues at three and locks after an outcome', () => {
    let s = gPlay(createGuessSession(gPool, gConfig), 'clue', 'clue', 'clue');
    expect(s.current!.cluesShown).toBe(3);
    s = gPlay(s, 'reveal');
    expect(gPlay(s, 'got')).toBe(s);
    expect(gPlay(s, 'clue')).toBe(s);
    s = gPlay(s, 'next');
    expect(s.rounds[0]).toMatchObject({ outcome: 'revealed', points: 0 });
  });

  it('cannot move on without an outcome', () => {
    const s = createGuessSession(gPool, gConfig);
    expect(gPlay(s, 'next')).toBe(s);
  });

  it('results rank teams', () => {
    const s = gPlay(
      createGuessSession(gPool, gConfig),
      'reveal',
      'next',
      'got',
      'next',
      'got',
      'next',
    );
    const r = guessResults(s);
    expect(s.status).toBe('finished');
    expect(r.ranking).toEqual([0, 1]);
    expect(r.winners).toEqual([0, 1].filter((t) => s.scores[t] === Math.max(...s.scores)));
    expect(r.solved).toBe(2);
  });
});

describe('bestAgreement', () => {
  const round = (votes: ('a' | 'b')[]): WyrRound => ({
    questionId: 'q',
    a: votes.filter((v) => v === 'a').length,
    b: votes.filter((v) => v === 'b').length,
    votes,
    skipped: false,
  });

  it('needs two players', () => {
    expect(bestAgreement([round(['a'])], 1)).toBeNull();
  });

  it('finds the most in-sync pair', () => {
    const r = bestAgreement([round(['a', 'b', 'b']), round(['b', 'a', 'a'])], 3);
    expect(r).toEqual({ players: [1, 2], matches: 2, rounds: 2 });
  });
});

describe('shared vectors', () => {
  const trivia = load('trivia.json') as {
    items: TriviaPoolItem[];
    scenarios: Scenario<TriviaConfig, TriviaAction>[];
  };
  it.each(trivia.scenarios)('trivia: $name', ({ config, actions, expected }) => {
    let s = createTriviaSession(buildPool(trivia.items, config.categoryIds), config);
    for (const a of actions) s = reduceTrivia(s, a);
    const { config: _c, ...state } = s;
    expect({ ...state, results: triviaResults(s) }).toEqual(expected);
  });

  const guess = load('guess.json') as {
    items: PoolItem[];
    scenarios: Scenario<GuessConfig, GuessAction>[];
  };
  it.each(guess.scenarios)('guess: $name', ({ config, actions, expected }) => {
    let s = createGuessSession(buildPool(guess.items, config.categoryIds), config);
    for (const a of actions) s = reduceGuess(s, a);
    const { config: _c, ...state } = s;
    expect({ ...state, results: guessResults(s) }).toEqual(expected);
  });

  const wyr = load('would-you-rather.json') as {
    agreement: { name: string; rounds: WyrRound[]; playerCount: number; expected: unknown }[];
  };
  it.each(wyr.agreement)('agreement: $name', ({ rounds, playerCount, expected }) => {
    expect(bestAgreement(rounds, playerCount)).toEqual(expected);
  });
});
