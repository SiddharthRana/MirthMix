import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/content.dart';
import '../game/random.dart';
import '../game/wyr_engine.dart';
import 'providers.dart';

/// The Would You Rather session in progress (or just finished), persisted on every change so it
/// survives navigation, backgrounding and the process being killed.
class WyrSessionController extends Notifier<WyrState?> {
  static const _key = 'session.wyr';
  static const _lastConfigKey = 'setup.wyr';

  @override
  WyrState? build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return null;
    try {
      final restored = WyrState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      // Content can change between app versions; drop sessions that point at missing questions.
      final pack = ref.read(contentProvider).wyr;
      if (restored.order.any((id) => pack.item(id) == null)) return _discard();
      return restored;
    } on Object catch (e) {
      debugPrint('Discarding unreadable saved session: $e');
      return _discard();
    }
  }

  WyrState? _discard() {
    ref.read(sharedPreferencesProvider).remove(_key);
    return null;
  }

  /// Starts a new session. Throws [EmptyPoolException] when the categories have no questions.
  void start(WyrConfig config) {
    final pack = ref.read(contentProvider).wyr;
    final allowed = config.categoryIds.where((id) => _isPlayable(id)).toList();
    final session = createWyrSession(buildPool(pack.items, allowed), config);
    _set(session);
    ref.read(sharedPreferencesProvider).setString(_lastConfigKey, jsonEncode(config.toJson()));
  }

  /// Same settings, fresh shuffle.
  void restart() {
    final s = state;
    if (s != null) start(s.config.withSeed(newSeed()));
  }

  void dispatch(WyrAction action) {
    final s = state;
    if (s == null) return;
    final next = reduceWyr(s, action);
    if (!identical(next, s)) _set(next);
  }

  void clear() {
    state = null;
    ref.read(sharedPreferencesProvider).remove(_key);
  }

  /// The configuration used last time, to prefill setup.
  WyrConfig? lastConfig() {
    final raw = ref.read(sharedPreferencesProvider).getString(_lastConfigKey);
    if (raw == null) return null;
    try {
      return WyrConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  bool _isPlayable(String categoryId) {
    final category = ref.read(contentProvider).wyr.category(categoryId);
    if (category == null) return false;
    return category.tier == Tier.free || ref.read(premiumProvider);
  }

  void _set(WyrState next) {
    state = next;
    ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(next.toJson()));
  }
}

final wyrSessionProvider = NotifierProvider<WyrSessionController, WyrState?>(WyrSessionController.new);
