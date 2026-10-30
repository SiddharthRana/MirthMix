import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../content/content.dart';
import '../game/random.dart';
import '../game/wyr_engine.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import '../state/wyr_session.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';
import '../widgets/brand.dart';
import '../widgets/mode_tile.dart';
import 'modes.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _quickPlay(BuildContext context, WidgetRef ref) {
    final pack = ref.read(contentProvider).wyr;
    final free = pack.categories.where((c) => c.tier == Tier.free && c.region == 'global').map((c) => c.id).toList();
    ref.read(wyrSessionProvider.notifier).start(WyrConfig(categoryIds: free, rounds: 10, seed: newSeed()));
    context.push('/play/would-you-rather');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = MmPalette.of(context);
    final session = ref.watch(wyrSessionProvider);
    final inProgress = session != null && session.status == WyrStatus.playing;

    return Scaffold(
      appBar: AppBar(
        title: const MirthMixWordmark(size: 22),
        actions: [
          IconButton(
            tooltip: l.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(MmSpace.s4, MmSpace.s2, MmSpace.s4, MmSpace.s8),
        children: [
          Text(l.homeGreeting, style: theme.textTheme.headlineMedium),
          const SizedBox(height: MmSpace.s4),
          if (inProgress) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(MmSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.homeResumeTitle, style: theme.textTheme.titleMedium),
                    const SizedBox(height: MmSpace.s1),
                    Text(
                      l.homeResumeBody(l.modeWyrName, session.roundNumber, session.totalRounds),
                      style: theme.textTheme.bodyMedium?.copyWith(color: palette.textMuted),
                    ),
                    const SizedBox(height: MmSpace.s3),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: () => context.push('/play/would-you-rather'),
                          child: Text(l.homeResume),
                        ),
                        const SizedBox(width: MmSpace.s2),
                        TextButton(
                          onPressed: () => ref.read(wyrSessionProvider.notifier).clear(),
                          child: Text(l.homeDiscard),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: MmSpace.s4),
          ],
          GradientPanel(
            onTap: () => _quickPlay(context, ref),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.homeQuickPlay, style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
                      const SizedBox(height: MmSpace.s2),
                      Text(l.homeQuickPlayBody, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(width: MmSpace.s4),
                const Icon(Icons.play_circle_fill_rounded, size: 56),
              ],
            ),
          ),
          const SizedBox(height: MmSpace.s8),
          Row(
            children: [
              Expanded(child: Text(l.homeAllGames, style: theme.textTheme.titleLarge)),
              TextButton(onPressed: () => context.push('/games'), child: Text(l.homeSeeAll)),
            ],
          ),
          const SizedBox(height: MmSpace.s2),
          for (final mode in GameMode.values.take(3)) ...[ModeTile(mode: mode), const SizedBox(height: MmSpace.s3)],
        ],
      ),
    );
  }
}
