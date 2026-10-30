/** Modes a share link can start. Matches the content pack `mode` values. */
export const SHARE_MODES = ['would-you-rather', 'this-or-that', 'trivia', 'guess'] as const;
export type ShareMode = (typeof SHARE_MODES)[number];

/** A game setup plus seed: enough to recreate the same deal on any device. No personal data. */
export interface SharedGame {
  mode: ShareMode;
  categoryIds: string[];
  rounds: number;
  seed: number;
  /** Trivia only: per-question limit in ms (0 = off). */
  timeLimitMs?: number;
}

const toBase64Url = (s: string) =>
  btoa(String.fromCharCode(...new TextEncoder().encode(s)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');

const fromBase64Url = (s: string) => {
  const bin = atob(s.replace(/-/g, '+').replace(/_/g, '/'));
  return new TextDecoder().decode(Uint8Array.from(bin, (c) => c.charCodeAt(0)));
};

/** Encodes a game as a compact URL-safe string for `/play?c=…`. */
export function encodeShare(game: SharedGame): string {
  const compact: Record<string, unknown> = {
    m: SHARE_MODES.indexOf(game.mode),
    c: game.categoryIds,
    r: game.rounds,
    s: game.seed >>> 0,
  };
  if (game.mode === 'trivia' && game.timeLimitMs !== undefined) compact.t = game.timeLimitMs;
  return toBase64Url(JSON.stringify(compact));
}

/** Decodes a share string; returns null for anything malformed or out of range. */
export function decodeShare(code: string): SharedGame | null {
  try {
    if (code.length > 2000) return null;
    const v = JSON.parse(fromBase64Url(code)) as Record<string, unknown>;
    const mode = SHARE_MODES[v.m as number];
    const { c, r, s, t } = v;
    if (!mode || !Array.isArray(c) || c.length === 0 || c.length > 20) return null;
    if (!c.every((id) => typeof id === 'string' && /^[a-z0-9-]{1,40}$/.test(id))) return null;
    if (!Number.isInteger(r) || (r as number) < 1 || (r as number) > 50) return null;
    if (!Number.isInteger(s) || (s as number) < 0 || (s as number) > 0xffffffff) return null;
    const game: SharedGame = {
      mode,
      categoryIds: c as string[],
      rounds: r as number,
      seed: s as number,
    };
    if (mode === 'trivia') {
      game.timeLimitMs =
        Number.isInteger(t) && (t as number) >= 0 && (t as number) <= 60000 ? (t as number) : 20000;
    }
    return game;
  } catch {
    return null;
  }
}
