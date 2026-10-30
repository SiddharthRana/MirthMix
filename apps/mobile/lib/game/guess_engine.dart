import 'package:flutter/foundation.dart';

import '../content/content.dart';
import 'random.dart';
import 'trivia_engine.dart' show SessionStatus;
import 'wyr_engine.dart' show EmptyPoolException;

/// Port of packages/game-engine/src/guess.ts. Keep the two in step: the shared test vectors run
/// against both.
const cluesPerCard = 3;

/// 3 points on the first clue, 2 on the second, 1 on the third.
int pointsFor(int cluesShown) => cluesPerCard + 1 - cluesShown;

@immutable
class GuessConfig {
  const GuessConfig({required this.categoryIds, required this.rounds, required this.seed, required this.teams});

  final List<String> categoryIds;
  final int rounds;
  final int seed;
  final int teams;

  GuessConfig withSeed(int seed) => GuessConfig(categoryIds: categoryIds, rounds: rounds, seed: seed, teams: teams);

  Map<String, Object?> toJson() => {'categoryIds': categoryIds, 'rounds': rounds, 'seed': seed, 'teams': teams};

  factory GuessConfig.fromJson(Map<String, dynamic> j) => GuessConfig(
    categoryIds: (j['categoryIds'] as List<dynamic>).cast<String>(),
    rounds: j['rounds'] as int,
    seed: j['seed'] as int,
    teams: j['teams'] as int,
  );
}

enum GuessOutcome { got, revealed, skipped }

@immutable
class GuessCurrent {
  const GuessCurrent({required this.questionId, required this.team, this.cluesShown = 1, this.outcome});

  final String questionId;
  final int team;
  final int cluesShown;

  /// [GuessOutcome.got] or [GuessOutcome.revealed] once decided; never skipped.
  final GuessOutcome? outcome;

  GuessCurrent copyWith({int? cluesShown, GuessOutcome? outcome}) => GuessCurrent(
    questionId: questionId,
    team: team,
    cluesShown: cluesShown ?? this.cluesShown,
    outcome: outcome ?? this.outcome,
  );

  Map<String, Object?> toJson() => {
    'questionId': questionId,
    'team': team,
    'cluesShown': cluesShown,
    'outcome': outcome?.name,
  };

  factory GuessCurrent.fromJson(Map<String, dynamic> j) => GuessCurrent(
    questionId: j['questionId'] as String,
    team: j['team'] as int,
    cluesShown: j['cluesShown'] as int,
    outcome: j['outcome'] == null ? null : GuessOutcome.values.byName(j['outcome'] as String),
  );
}

@immutable
class GuessRound {
  const GuessRound({
    required this.questionId,
    required this.team,
    required this.cluesShown,
    required this.outcome,
    required this.points,
  });

  final String questionId;
  final int team;
  final int cluesShown;
  final GuessOutcome outcome;
  final int points;

  Map<String, Object?> toJson() => {
    'questionId': questionId,
    'team': team,
    'cluesShown': cluesShown,
    'outcome': outcome.name,
    'points': points,
  };

  factory GuessRound.fromJson(Map<String, dynamic> j) => GuessRound(
    questionId: j['questionId'] as String,
    team: j['team'] as int,
    cluesShown: j['cluesShown'] as int,
    outcome: GuessOutcome.values.byName(j['outcome'] as String),
    points: j['points'] as int,
  );
}

@immutable
class GuessState {
  const GuessState({
    required this.config,
    required this.order,
    required this.cursor,
    required this.totalRounds,
    required this.rounds,
    required this.current,
    required this.scores,
    required this.status,
  });

  final GuessConfig config;
  final List<String> order;
  final int cursor;
  final int totalRounds;
  final List<GuessRound> rounds;
  final GuessCurrent? current;
  final List<int> scores;
  final SessionStatus status;

  int get roundNumber => status == SessionStatus.finished ? rounds.length : rounds.length + 1;
  bool get isLastRound => rounds.length + 1 >= totalRounds;

  GuessState _with({
    int? cursor,
    List<GuessRound>? rounds,
    GuessCurrent? current,
    bool clearCurrent = false,
    List<int>? scores,
    SessionStatus? status,
  }) => GuessState(
    config: config,
    order: order,
    cursor: cursor ?? this.cursor,
    totalRounds: totalRounds,
    rounds: rounds ?? this.rounds,
    current: clearCurrent ? null : current ?? this.current,
    scores: scores ?? this.scores,
    status: status ?? this.status,
  );

  Map<String, Object?> stateJson() => {
    'order': order,
    'cursor': cursor,
    'totalRounds': totalRounds,
    'rounds': rounds.map((r) => r.toJson()).toList(),
    'current': current?.toJson(),
    'scores': scores,
    'status': status.name,
  };

  Map<String, Object?> toJson() => {'config': config.toJson(), ...stateJson()};

  factory GuessState.fromJson(Map<String, dynamic> j) => GuessState(
    config: GuessConfig.fromJson(j['config'] as Map<String, dynamic>),
    order: (j['order'] as List<dynamic>).cast<String>(),
    cursor: j['cursor'] as int,
    totalRounds: j['totalRounds'] as int,
    rounds: (j['rounds'] as List<dynamic>).map((r) => GuessRound.fromJson(r as Map<String, dynamic>)).toList(),
    current: j['current'] == null ? null : GuessCurrent.fromJson(j['current'] as Map<String, dynamic>),
    scores: (j['scores'] as List<dynamic>).cast<int>(),
    status: SessionStatus.values.byName(j['status'] as String),
  );
}

enum GuessAction { clue, got, reveal, next, skip }

GuessState createGuessSession(List<PoolItem> pool, GuessConfig config) {
  if (pool.isEmpty) throw const EmptyPoolException();
  if (config.rounds < 1) throw RangeError.value(config.rounds, 'rounds', 'must be positive');
  if (config.teams < 1) throw RangeError.value(config.teams, 'teams', 'must be positive');
  final order = seededShuffle(pool.map((i) => i.id).toList(), config.seed);
  return GuessState(
    config: config,
    order: order,
    cursor: 1,
    totalRounds: config.rounds < order.length ? config.rounds : order.length,
    rounds: const [],
    current: GuessCurrent(questionId: order.first, team: 0),
    scores: List.filled(config.teams, 0),
    status: SessionStatus.playing,
  );
}

GuessState reduceGuess(GuessState state, GuessAction action) {
  final cur = state.current;
  if (state.status == SessionStatus.finished || cur == null) return state;

  switch (action) {
    case GuessAction.clue:
      if (cur.outcome != null || cur.cluesShown >= cluesPerCard) return state;
      return state._with(current: cur.copyWith(cluesShown: cur.cluesShown + 1));
    case GuessAction.got:
    case GuessAction.reveal:
      if (cur.outcome != null) return state;
      return state._with(
        current: cur.copyWith(outcome: action == GuessAction.got ? GuessOutcome.got : GuessOutcome.revealed),
      );
    case GuessAction.next:
      final outcome = cur.outcome;
      if (outcome == null) return state;
      return _advance(
        state,
        GuessRound(
          questionId: cur.questionId,
          team: cur.team,
          cluesShown: cur.cluesShown,
          outcome: outcome,
          points: outcome == GuessOutcome.got ? pointsFor(cur.cluesShown) : 0,
        ),
      );
    case GuessAction.skip:
      if (cur.outcome != null) return state;
      if (state.cursor < state.order.length) {
        return state._with(
          cursor: state.cursor + 1,
          current: GuessCurrent(questionId: state.order[state.cursor], team: cur.team),
        );
      }
      return _advance(
        state,
        GuessRound(
          questionId: cur.questionId,
          team: cur.team,
          cluesShown: cur.cluesShown,
          outcome: GuessOutcome.skipped,
          points: 0,
        ),
      );
  }
}

GuessState _advance(GuessState state, GuessRound round) {
  final rounds = [...state.rounds, round];
  final scores = [for (var t = 0; t < state.scores.length; t++) state.scores[t] + (t == round.team ? round.points : 0)];
  if (rounds.length >= state.totalRounds || state.cursor >= state.order.length) {
    return state._with(rounds: rounds, scores: scores, clearCurrent: true, status: SessionStatus.finished);
  }
  return state._with(
    rounds: rounds,
    scores: scores,
    cursor: state.cursor + 1,
    current: GuessCurrent(questionId: state.order[state.cursor], team: rounds.length % state.config.teams),
  );
}

@immutable
class GuessResults {
  const GuessResults({required this.ranking, required this.winners, required this.solved, required this.played});

  /// Team indexes, highest score first; ties keep team order.
  final List<int> ranking;
  final List<int> winners;
  final int solved;
  final int played;

  Map<String, Object?> toJson() => {'ranking': ranking, 'winners': winners, 'solved': solved, 'played': played};
}

GuessResults guessResults(GuessState state) {
  final ranking = [for (var t = 0; t < state.scores.length; t++) t]
    ..sort((x, y) => state.scores[x] != state.scores[y] ? state.scores[y] - state.scores[x] : x - y);
  final top = state.scores.fold(0, (m, s) => s > m ? s : m);
  return GuessResults(
    ranking: ranking,
    winners: top > 0 ? ranking.where((t) => state.scores[t] == top).toList() : const [],
    solved: state.rounds.where((r) => r.outcome == GuessOutcome.got).length,
    played: state.rounds.where((r) => r.outcome != GuessOutcome.skipped).length,
  );
}
