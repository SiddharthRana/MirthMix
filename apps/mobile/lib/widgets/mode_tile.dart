import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/modes.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';

class ModeTile extends StatelessWidget {
  const ModeTile({super.key, required this.mode});

  final GameMode mode;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = MmPalette.of(context);
    final route = mode.route;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: route == null ? null : () => context.push(route),
        child: Padding(
          padding: const EdgeInsets.all(MmSpace.s4),
          child: Row(
            children: [
              Container(
                width: MmTouch.game,
                height: MmTouch.game,
                decoration: BoxDecoration(
                  color: mode.available ? theme.colorScheme.primary : palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(MmRadius.md),
                ),
                child: Icon(
                  mode.icon,
                  color: mode.available ? theme.colorScheme.onPrimary : palette.textMuted,
                  size: 28,
                ),
              ),
              const SizedBox(width: MmSpace.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mode.name(l), style: theme.textTheme.titleMedium),
                    const SizedBox(height: MmSpace.s1),
                    Text(mode.blurb(l), style: theme.textTheme.bodyMedium?.copyWith(color: palette.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: MmSpace.s2),
              if (mode.available)
                Icon(Icons.chevron_right_rounded, color: palette.textMuted)
              else
                Chip(label: Text(l.comingSoon), visualDensity: VisualDensity.compact),
            ],
          ),
        ),
      ),
    );
  }
}
