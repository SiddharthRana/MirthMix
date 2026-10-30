import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home_screen.dart';
import '../features/library_screen.dart';
import '../features/onboarding_screen.dart';
import '../features/settings_screen.dart';
import '../features/wyr/wyr_play_screen.dart';
import '../features/wyr/wyr_results_screen.dart';
import '../features/wyr/wyr_setup_screen.dart';
import '../l10n/app_localizations.dart';
import '../state/settings.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // First launch goes through the short introduction; it never blocks later visits.
      final onboarded = ref.read(settingsProvider).onboarded;
      if (!onboarded && state.matchedLocation != '/onboarding') return '/onboarding';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/games', builder: (_, _) => const LibraryScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/play/would-you-rather/setup', builder: (_, _) => const WyrSetupScreen()),
      GoRoute(path: '/play/would-you-rather', builder: (_, _) => const WyrPlayScreen()),
      GoRoute(path: '/play/would-you-rather/results', builder: (_, _) => const WyrResultsScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context).errorNotFound),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => context.go('/'), child: Text(AppLocalizations.of(context).goHome)),
          ],
        ),
      ),
    ),
  );
});
