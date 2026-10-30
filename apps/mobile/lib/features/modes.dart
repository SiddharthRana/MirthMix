import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Every mode in the library. Only Would You Rather is playable in Phase 1; the rest are
/// listed honestly as "coming soon".
enum GameMode {
  wouldYouRather(Icons.call_split_rounded, '/play/would-you-rather/setup'),
  thisOrThat(Icons.compare_arrows_rounded, null),
  trivia(Icons.timer_outlined, null),
  guess(Icons.lightbulb_outline_rounded, null),
  custom(Icons.dashboard_customize_outlined, null);

  const GameMode(this.icon, this.route);

  final IconData icon;

  /// Setup route, or null while the mode isn't built yet.
  final String? route;

  bool get available => route != null;

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
}
