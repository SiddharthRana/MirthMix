import 'package:flutter/foundation.dart';

import '../content/content.dart';
import 'random.dart';

/// Port of packages/game-engine/src/would-you-rather.ts. Keep the two in step: the shared
/// test vectors (packages/game-engine/test-vectors) run against both.
enum Side { a, b }

@immutable
class WyrConfig {
  const WyrConfig({required this.categoryIds, required this.rounds, required this.seed, this.playerCount});

  final List<String> categoryIds;
  final int rounds;
  final int seed;

  /// When set, a round accepts at most this many votes.
  final int? playerCount;

  WyrConfig withSeed(int seed) =>
      WyrConfig(categoryIds: categoryIds, rounds: rounds, seed: seed, playerCount: playerCount);

  Map<String, Object?> toJson() => {
    'categoryIds': categoryIds,
    'rounds': rounds,
    'seed': seed,
    if (playerCount != null) 'playerCount': playerCount,
  };

  factory WyrConfig.fromJson(Map<String, dynamic> j) => WyrConfig(
    categoryIds: (j['categoryIds'] as List<dynamic>).cast<String>(),
    rounds: j['rounds'] as int,
    seed: j['seed'] as int,
    playerCount: j['playerCount'] as int?,
  );
}

@immutable
class WyrRound {
  const WyrRound({
    required this.questionId,
    required this.a,
    required this.b,
    this.votes = const [],
    required this.skipped,
  });

  final String questionId;
  final int a;
  final int b;

  /// Votes in the order cast. In pass-the-phone play, index i is player i's pick.
  final List<Side> votes;
  final bool skipped;

  int get total => a + b;

  Map<String, Object?> toJson() => {
    'questionId': questionId,
    'a': a,
    'b': b,
    'votes': votes.map((v) => v.name).toList(),
    'skipped': skipped,
  };

  factory WyrRound.fromJson(Map<String, dynamic> j) => WyrRound(
    questionId: j['questionId'] as String,
    a: j['a'] as int,
    b: j['b'] as int,
    votes: ((j['votes'] as List<dynamic>?) ?? const []).map((v) => Side.values.byName(v as String)).toList(),
    skipped: j['skipped'] as bool,
  );
}

@immutable
class WyrCurrent {
  const WyrCurrent({required this.questionId, this.votes = const [], this.revealed = false});

  final String questionId;

  /// Votes in the order they were cast, so undo removes the latest.
  final List<Side> votes;
  final bool revealed;

  int count(Side side) => votes.where((v) => v == side).length;

  WyrCurrent copyWith({List<Side>? votes, bool? revealed}) =>
      WyrCurrent(questionId: questionId, votes: votes ?? this.votes, revealed: revealed ?? this.revealed);

  Map<String, Object?> toJson() => {
    'questionId': questionId,
    'votes': votes.map((v) => v.name).toList(),
    'revealed': revealed,
  };

  factory WyrCurrent.fromJson(Map<String, dynamic> j) => WyrCurrent(
    questionId: j['questionId'] as String,
    votes: (j['votes'] as List<dynamic>).map((v) => Side.values.byName(v as String)).toList(),
    revealed: j['revealed'] as bool,
  );
}

enum WyrStatus { playing, finished }

@immutable
class WyrState {
  const WyrState({
    required this.config,
    required this.order,
    required this.cursor,
    required this.totalRounds,
    required this.rounds,
    required this.current,
    required this.skips,
    required this.status,
  });

  final WyrConfig config;

  /// Question ids in play order: the first [totalRounds] are dealt, the rest are skip replacements.
  final List<String> order;

  /// Index in [order] of the next unused question.
  final int cursor;
  final int totalRounds;
  final List<WyrRound> rounds;
  final WyrCurrent? current;
  final int skips;
  final WyrStatus status;

  /// 1-based number of the round being played (or the last round once finished).
  int get roundNumber => status == WyrStatus.finished ? rounds.length : rounds.length + 1;
  bool get isLastRound => rounds.length + 1 >= totalRounds;

  WyrState copyWith({int? cursor, List<WyrRound>? rounds, WyrCurrent? current, int? skips}) => WyrState(
    config: config,
    order: order,
    cursor: cursor ?? this.cursor,
    totalRounds: totalRounds,
    rounds: rounds ?? this.rounds,
    current: current ?? this.current,
    skips: skips ?? this.skips,
    status: status,
  );

  WyrState _finish(List<WyrRound> rounds) => WyrState(
    config: config,
    order: order,
    cursor: cursor,
    totalRounds: totalRounds,
    rounds: rounds,
    current: null,
    skips: skips,
    status: WyrStatus.finished,
  );

  Map<String, Object?> toJson() => {
    'config': config.toJson(),
    'order': order,
    'cursor': cursor,
    'totalRounds': totalRounds,
    'rounds': rounds.map((r) => r.toJson()).toList(),
    'current': current?.toJson(),
    'skips': skips,
    'status': status.name,
  };

  factory WyrState.fromJson(Map<String, dynamic> j) => WyrState(
    config: WyrConfig.fromJson(j['config'] as Map<String, dynamic>),
    order: (j['order'] as List<dynamic>).cast<String>(),
    cursor: j['cursor'] as int,
    totalRounds: j['totalRounds'] as int,
    rounds: (j['rounds'] as List<dynamic>).map((r) => WyrRound.fromJson(r as Map<String, dynamic>)).toList(),
    current: j['current'] == null ? null : WyrCurrent.fromJson(j['current'] as Map<String, dynamic>),
    skips: j['skips'] as int,
    status: WyrStatus.values.byName(j['status'] as String),
  );
}

sealed class WyrAction {
  const WyrAction();
}

class Vote extends WyrAction {
  const Vote(this.side);
  final Side side;
}

class Undo extends WyrAction {
  const Undo();
}

class Reveal extends WyrAction {
  const Reveal();
}

class Next extends WyrAction {
  const Next();
}

class SkipQuestion extends WyrAction {
  const SkipQuestion();
}

class EmptyPoolException implements Exception {
  const EmptyPoolException();
  @override
  String toString() => 'No questions available for the selected categories.';
}

/// Items in the chosen categories, in a stable (id) order so shuffles are reproducible.
List<T> buildPool<T extends PoolItem>(List<T> items, List<String> categoryIds) {
  final wanted = categoryIds.toSet();
  return items.where((i) => wanted.contains(i.category)).toList()..sort((x, y) => x.id.compareTo(y.id));
}

WyrState createWyrSession(List<PoolItem> pool, WyrConfig config) {
  if (pool.isEmpty) throw const EmptyPoolException();
  if (config.rounds < 1) throw RangeError.value(config.rounds, 'rounds', 'must be positive');
  final order = seededShuffle(pool.map((i) => i.id).toList(), config.seed);
  return WyrState(
    config: config,
    order: order,
    cursor: 1,
    totalRounds: config.rounds < order.length ? config.rounds : order.length,
    rounds: const [],
    current: WyrCurrent(questionId: order.first),
    skips: 0,
    status: WyrStatus.playing,
  );
}

/// Pure reducer: returns the same state object when an action doesn't apply.
WyrState reduceWyr(WyrState state, WyrAction action) {
  final cur = state.current;
  if (state.status == WyrStatus.finished || cur == null) return state;

  switch (action) {
    case Vote(:final side):
      final cap = state.config.playerCount;
      if (cur.revealed || (cap != null && cur.votes.length >= cap)) return state;
      return state.copyWith(current: cur.copyWith(votes: [...cur.votes, side]));
    case Undo():
      if (cur.revealed || cur.votes.isEmpty) return state;
      return state.copyWith(current: cur.copyWith(votes: cur.votes.sublist(0, cur.votes.length - 1)));
    case Reveal():
      if (cur.revealed) return state;
      return state.copyWith(current: cur.copyWith(revealed: true));
    case Next():
      return _advance(
        state,
        WyrRound(
          questionId: cur.questionId,
          a: cur.count(Side.a),
          b: cur.count(Side.b),
          votes: cur.votes,
          skipped: false,
        ),
      );
    case SkipQuestion():
      // Swap in an unused question when one is left; otherwise the round is spent as skipped.
      if (state.cursor < state.order.length) {
        return state.copyWith(
          cursor: state.cursor + 1,
          skips: state.skips + 1,
          current: WyrCurrent(questionId: state.order[state.cursor]),
        );
      }
      return _advance(
        state.copyWith(skips: state.skips + 1),
        WyrRound(questionId: cur.questionId, a: 0, b: 0, skipped: true),
      );
  }
}

WyrState _advance(WyrState state, WyrRound round) {
  final rounds = [...state.rounds, round];
  if (rounds.length >= state.totalRounds || state.cursor >= state.order.length) return state._finish(rounds);
  return state.copyWith(
    rounds: rounds,
    cursor: state.cursor + 1,
    current: WyrCurrent(questionId: state.order[state.cursor]),
  );
}

@immutable
class WyrResults {
  const WyrResults({
    required this.roundsPlayed,
    required this.roundsSkipped,
    required this.totalVotes,
    required this.mostDivisive,
    required this.mostUnanimous,
  });

  final int roundsPlayed;
  final int roundsSkipped;
  final int totalVotes;

  /// Closest split (needs ≥ 2 votes). Ties go to the earliest round.
  final String? mostDivisive;

  /// Largest share for one side (needs ≥ 2 votes). Ties go to the earliest round.
  final String? mostUnanimous;

  Map<String, Object?> toJson() => {
    'roundsPlayed': roundsPlayed,
    'roundsSkipped': roundsSkipped,
    'totalVotes': totalVotes,
    'mostDivisive': mostDivisive,
    'mostUnanimous': mostUnanimous,
  };
}

WyrResults wyrResults(WyrState state) {
  double share(WyrRound r) => (r.a > r.b ? r.a : r.b) / r.total;
  WyrRound? divisive;
  WyrRound? unanimous;
  for (final r in state.rounds.where((r) => !r.skipped && r.total >= 2)) {
    if (divisive == null || share(r) < share(divisive)) divisive = r;
    if (unanimous == null || share(r) > share(unanimous)) unanimous = r;
  }
  return WyrResults(
    roundsPlayed: state.rounds.where((r) => !r.skipped).length,
    roundsSkipped: state.rounds.where((r) => r.skipped).length,
    totalVotes: state.rounds.fold(0, (n, r) => n + r.total),
    mostDivisive: divisive?.questionId,
    // With a single voted round both highlights would be the same question; show only one.
    mostUnanimous: unanimous != null && !identical(unanimous, divisive) ? unanimous.questionId : null,
  );
}

@immutable
class Agreement {
  const Agreement({required this.players, required this.matches, required this.rounds});

  /// Player indexes, lowest first.
  final (int, int) players;
  final int matches;
  final int rounds;

  Map<String, Object?> toJson() => {
    'players': [players.$1, players.$2],
    'matches': matches,
    'rounds': rounds,
  };
}

/// For pass-the-phone play: the pair of players who picked the same side most often, over rounds
/// where both voted. Ties go to the lowest player indexes. Null with fewer than two players.
Agreement? bestAgreement(List<WyrRound> rounds, int playerCount) {
  Agreement? best;
  for (var i = 0; i < playerCount; i++) {
    for (var j = i + 1; j < playerCount; j++) {
      var matches = 0;
      var both = 0;
      for (final r in rounds) {
        if (i >= r.votes.length || j >= r.votes.length) continue;
        both++;
        if (r.votes[i] == r.votes[j]) matches++;
      }
      if (both > 0 && (best == null || matches * best.rounds > best.matches * both)) {
        best = Agreement(players: (i, j), matches: matches, rounds: both);
      }
    }
  }
  return best;
}
