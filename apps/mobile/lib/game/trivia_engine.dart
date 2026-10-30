import 'package:flutter/foundation.dart';

import '../content/content.dart';
import 'random.dart';
import 'wyr_engine.dart' show EmptyPoolException;

/// Port of packages/game-engine/src/trivia.ts. Keep the two in step: the shared test vectors run
/// against both.
const correctPoints = 100;
const maxSpeedBonus = 50;

@immutable
class TriviaConfig {
  const TriviaConfig({
    required this.categoryIds,
    required this.rounds,
    required this.seed,
    required this.teams,
    required this.timeLimitMs,
  });

  final List<String> categoryIds;
  final int rounds;
  final int seed;

  /// Players or teams taking turns; 1 means the whole group plays together.
  final int teams;

  /// Per-question time limit; 0 turns the timer (and the speed bonus) off.
  final int timeLimitMs;

  TriviaConfig withSeed(int seed) =>
      TriviaConfig(categoryIds: categoryIds, rounds: rounds, seed: seed, teams: teams, timeLimitMs: timeLimitMs);

  Map<String, Object?> toJson() => {
    'categoryIds': categoryIds,
    'rounds': rounds,
    'seed': seed,
    'teams': teams,
    'timeLimitMs': timeLimitMs,
  };

  factory TriviaConfig.fromJson(Map<String, dynamic> j) => TriviaConfig(
    categoryIds: (j['categoryIds'] as List<dynamic>).cast<String>(),
    rounds: j['rounds'] as int,
    seed: j['seed'] as int,
    teams: j['teams'] as int,
    timeLimitMs: j['timeLimitMs'] as int,
  );
}

@immutable
class TriviaCurrent {
  const TriviaCurrent({
    required this.questionId,
    required this.team,
    required this.choiceOrder,
    required this.answer,
    this.picked,
    this.timedOut = false,
    this.points = 0,
  });

  final String questionId;
  final int team;

  /// Display order: `choiceOrder[i]` is the pack index of the choice shown in position i.
  final List<int> choiceOrder;

  /// Pack index of the correct choice.
  final int answer;

  /// Pack index of the picked choice; null until answered (and after a timeout).
  final int? picked;
  final bool timedOut;
  final int points;

  bool get answered => picked != null || timedOut;

  TriviaCurrent copyWith({int? picked, bool? timedOut, int? points}) => TriviaCurrent(
    questionId: questionId,
    team: team,
    choiceOrder: choiceOrder,
    answer: answer,
    picked: picked ?? this.picked,
    timedOut: timedOut ?? this.timedOut,
    points: points ?? this.points,
  );

  Map<String, Object?> toJson() => {
    'questionId': questionId,
    'team': team,
    'choiceOrder': choiceOrder,
    'answer': answer,
    'picked': picked,
    'timedOut': timedOut,
    'points': points,
  };

  factory TriviaCurrent.fromJson(Map<String, dynamic> j) => TriviaCurrent(
    questionId: j['questionId'] as String,
    team: j['team'] as int,
    choiceOrder: (j['choiceOrder'] as List<dynamic>).cast<int>(),
    answer: j['answer'] as int,
    picked: j['picked'] as int?,
    timedOut: j['timedOut'] as bool,
    points: j['points'] as int,
  );
}

@immutable
class TriviaRound {
  const TriviaRound({
    required this.questionId,
    required this.team,
    required this.picked,
    required this.correct,
    required this.timedOut,
    required this.skipped,
    required this.points,
  });

  final String questionId;
  final int team;
  final int? picked;
  final bool correct;
  final bool timedOut;
  final bool skipped;
  final int points;

  Map<String, Object?> toJson() => {
    'questionId': questionId,
    'team': team,
    'picked': picked,
    'correct': correct,
    'timedOut': timedOut,
    'skipped': skipped,
    'points': points,
  };

  factory TriviaRound.fromJson(Map<String, dynamic> j) => TriviaRound(
    questionId: j['questionId'] as String,
    team: j['team'] as int,
    picked: j['picked'] as int?,
    correct: j['correct'] as bool,
    timedOut: j['timedOut'] as bool,
    skipped: j['skipped'] as bool,
    points: j['points'] as int,
  );
}

enum SessionStatus { playing, finished }

@immutable
class TriviaState {
  const TriviaState({
    required this.config,
    required this.order,
    required this.answers,
    required this.cursor,
    required this.totalRounds,
    required this.rounds,
    required this.current,
    required this.scores,
    required this.status,
  });

  final TriviaConfig config;
  final List<String> order;

  /// Pack answer index per entry in [order].
  final List<int> answers;
  final int cursor;
  final int totalRounds;
  final List<TriviaRound> rounds;
  final TriviaCurrent? current;
  final List<int> scores;
  final SessionStatus status;

  int get roundNumber => status == SessionStatus.finished ? rounds.length : rounds.length + 1;
  bool get isLastRound => rounds.length + 1 >= totalRounds;

  TriviaState _with({
    int? cursor,
    List<TriviaRound>? rounds,
    TriviaCurrent? current,
    bool clearCurrent = false,
    List<int>? scores,
    SessionStatus? status,
  }) => TriviaState(
    config: config,
    order: order,
    answers: answers,
    cursor: cursor ?? this.cursor,
    totalRounds: totalRounds,
    rounds: rounds ?? this.rounds,
    current: clearCurrent ? null : current ?? this.current,
    scores: scores ?? this.scores,
    status: status ?? this.status,
  );

  /// Everything but the config, matching the shape of the shared test vectors.
  Map<String, Object?> stateJson() => {
    'order': order,
    'answers': answers,
    'cursor': cursor,
    'totalRounds': totalRounds,
    'rounds': rounds.map((r) => r.toJson()).toList(),
    'current': current?.toJson(),
    'scores': scores,
    'status': status.name,
  };

  Map<String, Object?> toJson() => {'config': config.toJson(), ...stateJson()};

  factory TriviaState.fromJson(Map<String, dynamic> j) => TriviaState(
    config: TriviaConfig.fromJson(j['config'] as Map<String, dynamic>),
    order: (j['order'] as List<dynamic>).cast<String>(),
    answers: (j['answers'] as List<dynamic>).cast<int>(),
    cursor: j['cursor'] as int,
    totalRounds: j['totalRounds'] as int,
    rounds: (j['rounds'] as List<dynamic>).map((r) => TriviaRound.fromJson(r as Map<String, dynamic>)).toList(),
    current: j['current'] == null ? null : TriviaCurrent.fromJson(j['current'] as Map<String, dynamic>),
    scores: (j['scores'] as List<dynamic>).cast<int>(),
    status: SessionStatus.values.byName(j['status'] as String),
  );
}

sealed class TriviaAction {
  const TriviaAction();
}

class Answer extends TriviaAction {
  const Answer(this.choice, this.elapsedMs);

  /// Display position (0–3).
  final int choice;
  final int elapsedMs;
}

class TimeUp extends TriviaAction {
  const TimeUp();
}

class NextQuestion extends TriviaAction {
  const NextQuestion();
}

class SkipTrivia extends TriviaAction {
  const SkipTrivia();
}

TriviaState createTriviaSession(List<TriviaItem> pool, TriviaConfig config) {
  if (pool.isEmpty) throw const EmptyPoolException();
  if (config.rounds < 1) throw RangeError.value(config.rounds, 'rounds', 'must be positive');
  if (config.teams < 1) throw RangeError.value(config.teams, 'teams', 'must be positive');
  final shuffled = seededShuffle(pool, config.seed);
  return _deal(
    TriviaState(
      config: config,
      order: shuffled.map((i) => i.id).toList(),
      answers: shuffled.map((i) => i.answer).toList(),
      cursor: 0,
      totalRounds: config.rounds < shuffled.length ? config.rounds : shuffled.length,
      rounds: const [],
      current: null,
      scores: List.filled(config.teams, 0),
      status: SessionStatus.playing,
    ),
    0,
  );
}

TriviaState _deal(TriviaState state, int team) {
  final i = state.cursor;
  return state._with(
    cursor: i + 1,
    current: TriviaCurrent(
      questionId: state.order[i],
      team: team,
      choiceOrder: seededShuffle([0, 1, 2, 3], (state.config.seed + i + 1) & 0xFFFFFFFF),
      answer: state.answers[i],
    ),
  );
}

int speedBonus(int elapsedMs, int timeLimitMs) {
  if (timeLimitMs <= 0) return 0;
  final elapsed = elapsedMs < 0 ? 0 : elapsedMs;
  final left = (timeLimitMs - elapsed).clamp(0, timeLimitMs);
  return (maxSpeedBonus * left) ~/ timeLimitMs;
}

TriviaState reduceTrivia(TriviaState state, TriviaAction action) {
  final cur = state.current;
  if (state.status == SessionStatus.finished || cur == null) return state;

  switch (action) {
    case Answer(:final choice, :final elapsedMs):
      if (cur.answered || choice < 0 || choice >= cur.choiceOrder.length) return state;
      final picked = cur.choiceOrder[choice];
      final points = picked == cur.answer ? correctPoints + speedBonus(elapsedMs, state.config.timeLimitMs) : 0;
      return state._with(
        current: cur.copyWith(picked: picked, points: points),
      );
    case TimeUp():
      if (cur.answered || state.config.timeLimitMs <= 0) return state;
      return state._with(current: cur.copyWith(timedOut: true));
    case NextQuestion():
      if (!cur.answered) return state;
      return _advance(
        state,
        TriviaRound(
          questionId: cur.questionId,
          team: cur.team,
          picked: cur.picked,
          correct: cur.picked == cur.answer,
          timedOut: cur.timedOut,
          skipped: false,
          points: cur.points,
        ),
      );
    case SkipTrivia():
      if (cur.answered) return state;
      if (state.cursor < state.order.length) return _deal(state, cur.team);
      return _advance(
        state,
        TriviaRound(
          questionId: cur.questionId,
          team: cur.team,
          picked: null,
          correct: false,
          timedOut: false,
          skipped: true,
          points: 0,
        ),
      );
  }
}

TriviaState _advance(TriviaState state, TriviaRound round) {
  final rounds = [...state.rounds, round];
  final scores = [for (var t = 0; t < state.scores.length; t++) state.scores[t] + (t == round.team ? round.points : 0)];
  if (rounds.length >= state.totalRounds || state.cursor >= state.order.length) {
    return state._with(rounds: rounds, scores: scores, clearCurrent: true, status: SessionStatus.finished);
  }
  return _deal(state._with(rounds: rounds, scores: scores), rounds.length % state.config.teams);
}

@immutable
class TeamResult {
  const TeamResult({required this.team, required this.score, required this.correct, required this.answered});

  final int team;
  final int score;
  final int correct;
  final int answered;

  Map<String, Object?> toJson() => {'team': team, 'score': score, 'correct': correct, 'answered': answered};
}

@immutable
class TriviaResults {
  const TriviaResults({required this.standings, required this.winners, required this.correct, required this.played});

  /// Highest score first; ties keep team order.
  final List<TeamResult> standings;

  /// Teams sharing the top score (empty when nobody scored).
  final List<int> winners;
  final int correct;
  final int played;

  Map<String, Object?> toJson() => {
    'standings': standings.map((s) => s.toJson()).toList(),
    'winners': winners,
    'correct': correct,
    'played': played,
  };
}

TriviaResults triviaResults(TriviaState state) {
  final standings = [
    for (var t = 0; t < state.scores.length; t++)
      () {
        final mine = state.rounds.where((r) => r.team == t && !r.skipped);
        return TeamResult(
          team: t,
          score: state.scores[t],
          correct: mine.where((r) => r.correct).length,
          answered: mine.length,
        );
      }(),
  ]..sort((x, y) => x.score != y.score ? y.score - x.score : x.team - y.team);
  final top = standings.isEmpty ? 0 : standings.first.score;
  return TriviaResults(
    standings: standings,
    winners: top > 0 ? standings.where((s) => s.score == top).map((s) => s.team).toList() : const [],
    correct: state.rounds.where((r) => r.correct).length,
    played: state.rounds.where((r) => !r.skipped).length,
  );
}
