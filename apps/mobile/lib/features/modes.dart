import 'package:flutter/material.dart';

import '../content/content.dart';
import '../l10n/app_localizations.dart';
import '../state/games.dart';

/// Every entry in the game library: the four modes plus custom party packs.
enum LibraryEntry {
  wouldYouRather(Icons.call_split_rounded, GameMode.wouldYouRather),
  thisOrThat(Icons.compare_arrows_rounded, GameMode.thisOrThat),
  trivia(Icons.timer_outlined, GameMode.trivia),
  guess(Icons.lightbulb_outline_rounded, GameMode.guess),
  custom(Icons.dashboard_customize_outlined, null);

  const LibraryEntry(this.icon, this.mode);

  final IconData icon;

  /// The game mode, or null for custom party packs.
  final GameMode? mode;

  String get route => mode == null ? '/party' : setupRoute(mode!);

  String name(AppLocalizations l) => switch (this) {
    wouldYouRather => l.modeWyrName,
    thisOrThat => l.modeTotName,
    trivia => l.modeTriviaName,
    guess => l.modeGuessName,
    custom => l.modeCustomName,
  };

  String blurb(AppLocalizations l) => switch (this) {
    wouldYouRather => l.modeWyrBlurb,
    thisOrThat => l.modeTotBlurb,
    trivia => l.modeTriviaBlurb,
    guess => l.modeGuessBlurb,
    custom => l.modeCustomBlurb,
  };

  String rules(AppLocalizations l) => switch (this) {
    wouldYouRather => l.modeWyrRules,
    thisOrThat => l.modeTotRules,
    trivia => l.modeTriviaRules,
    guess => l.modeGuessRules,
    custom => l.modeCustomRules,
  };

  static LibraryEntry of(GameMode mode) => values.firstWhere((e) => e.mode == mode);
}

String modeName(AppLocalizations l, GameMode mode) => LibraryEntry.of(mode).name(l);
