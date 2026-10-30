/**
 * Seeded 32-bit PRNG (mulberry32). The Dart app ports this exactly; shared test vectors
 * guarantee both produce the same sequence, so a seed in a share link recreates a session.
 */
export function createRng(seed: number): () => number {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return (t ^ (t >>> 14)) >>> 0;
  };
}

/** Fisher–Yates shuffle driven by integer draws (no floating point, so ports match exactly). */
export function seededShuffle<T>(items: readonly T[], seed: number): T[] {
  const next = createRng(seed);
  const out = [...items];
  for (let i = out.length - 1; i > 0; i--) {
    const j = next() % (i + 1);
    [out[i], out[j]] = [out[j]!, out[i]!];
  }
  return out;
}

/** A random seed for a new session (not used by tests). */
export function newSeed(): number {
  return crypto.getRandomValues(new Uint32Array(1))[0]!;
}
