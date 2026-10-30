import 'dart:math';

const _mask32 = 0xFFFFFFFF;

int _imul(int a, int b) => (a * b) & _mask32;

/// Port of packages/game-engine/src/random.ts (mulberry32). Values are unsigned 32-bit and
/// must match the TypeScript engine exactly; the shared test vectors check this.
int Function() createRng(int seed) {
  var a = seed & _mask32;
  return () {
    a = (a + 0x6D2B79F5) & _mask32;
    var t = a;
    t = _imul(t ^ (t >> 15), t | 1);
    t = t ^ ((t + _imul(t ^ (t >> 7), t | 61)) & _mask32);
    return (t ^ (t >> 14)) & _mask32;
  };
}

/// Fisher–Yates shuffle driven by integer draws, identical to the TypeScript `seededShuffle`.
List<T> seededShuffle<T>(List<T> items, int seed) {
  final next = createRng(seed);
  final out = [...items];
  for (var i = out.length - 1; i > 0; i--) {
    final j = next() % (i + 1);
    final tmp = out[i];
    out[i] = out[j];
    out[j] = tmp;
  }
  return out;
}

final _seedSource = Random.secure();

/// A random seed for a new session.
int newSeed() => _seedSource.nextInt(1 << 32);
