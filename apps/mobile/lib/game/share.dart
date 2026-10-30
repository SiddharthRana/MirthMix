import 'dart:convert';

import '../content/content.dart';

/// Port of packages/game-engine/src/share.ts `decodeShare`: a setup plus seed from `/play?c=…`.
typedef SharedGame = ({GameMode mode, List<String> categoryIds, int rounds, int seed, int timeLimitMs});

const _modes = ['would-you-rather', 'this-or-that', 'trivia', 'guess'];
final _idPattern = RegExp(r'^[a-z0-9-]{1,40}$');

SharedGame? decodeShare(String code) {
  try {
    if (code.isEmpty || code.length > 2000) return null;
    final v = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(code)))) as Map<String, dynamic>;
    final m = v['m'];
    final c = v['c'];
    final r = v['r'];
    final s = v['s'];
    if (m is! int || m < 0 || m >= _modes.length) return null;
    if (c is! List || c.isEmpty || c.length > 20 || !c.every((id) => id is String && _idPattern.hasMatch(id))) {
      return null;
    }
    if (r is! int || r < 1 || r > 50) return null;
    if (s is! int || s < 0 || s > 0xFFFFFFFF) return null;
    final t = v['t'];
    return (
      mode: GameMode.fromId(_modes[m])!,
      categoryIds: c.cast<String>(),
      rounds: r,
      seed: s,
      timeLimitMs: t is int && t >= 0 && t <= 60000 ? t : 20000,
    );
  } on Object {
    return null;
  }
}
