import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/content.dart';
import '../../game/random.dart';
import '../../game/wyr_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../state/wyr_session.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';

const roundOptions = [5, 10, 15, 20];
const minPlayers = 2;
const maxPlayers = 12;

class WyrSetupScreen extends ConsumerStatefulWidget {
  const WyrSetupScreen({super.key});

  @override
  ConsumerState<WyrSetupScreen> createState() => _WyrSetupScreenState();
}

class _WyrSetupScreenState extends ConsumerState<WyrSetupScreen> {
  late Set<String> _selected;
  late int _rounds;
  int? _players;

  @override
  void initState() {
    super.initState();
    final pack = ref.read(contentProvider).wyr;
    final playable = pack.categories.where(_playable).map((c) => c.id).toSet();
    final last = ref.read(wyrSessionProvider.notifier).lastConfig();
    final remembered = last?.categoryIds.where(playable.contains).toSet() ?? {};
    _selected = remembered.isNotEmpty
        ? remembered
        : pack.categories.where((c) => _playable(c) && c.region == 'global').map((c) => c.id).toSet();
    _rounds = roundOptions.contains(last?.rounds) ? last!.rounds : 10;
    _players = last?.playerCount;
  }

  bool _playable(Category c) => c.tier == Tier.free || ref.read(premiumProvider);

  void _start() {
    final config = WyrConfig(
      categoryIds: _selected.toList()..sort(),
      rounds: _rounds,
      seed: newSeed(),
      playerCount: _players,
    );
    try {
      ref.read(wyrSessionProvider.notifier).start(config);
    } on EmptyPoolException {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).errorEmptyCategories)));
      return;
    }
    context.pushReplacement('/play/would-you-rather');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = MmPalette.of(context);
    final pack = ref.watch(contentProvider).wyr;
    final available = pack.countIn(_selected);

    return Scaffold(
      appBar: AppBar(title: Text(l.modeWyrName)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(MmSpace.s4, 0, MmSpace.s4, MmSpace.s6),
        children: [
          Card(
            color: palette.surfaceMuted,
            child: Padding(
              padding: const EdgeInsets.all(MmSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.setupHowToPlay, style: theme.textTheme.titleMedium),
                  const SizedBox(height: MmSpace.s1),
                  Text(l.modeWyrRules),
                ],
              ),
            ),
          ),
          const SizedBox(height: MmSpace.s6),
          _SectionTitle(l.setupCategories, hint: l.setupCategoriesHint),
          for (final c in pack.categories) ...[
            _CategoryTile(
              category: c,
              count: pack.countIn([c.id]),
              locked: !_playable(c),
              selected: _selected.contains(c.id),
              onChanged: (on) => setState(() => on ? _selected.add(c.id) : _selected.remove(c.id)),
            ),
            const SizedBox(height: MmSpace.s2),
          ],
          const SizedBox(height: MmSpace.s4),
          _SectionTitle(l.setupRounds),
          SegmentedButton<int>(
            segments: [for (final r in roundOptions) ButtonSegment(value: r, label: Text('$r'))],
            selected: {_rounds},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _rounds = s.first),
          ),
          if (_selected.isNotEmpty && available < _rounds) ...[
            const SizedBox(height: MmSpace.s2),
            Text(
              l.setupFewerQuestions(available),
              style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted),
            ),
          ],
          const SizedBox(height: MmSpace.s6),
          _SectionTitle(l.setupGroupSize, hint: l.setupGroupSizeHint),
          _GroupSize(value: _players, onChanged: (v) => setState(() => _players = v)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(MmSpace.s4, MmSpace.s2, MmSpace.s4, MmSpace.s4),
          child: FilledButton.icon(
            onPressed: _selected.isEmpty ? null : _start,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(l.setupStart),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.hint});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: MmSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(title, style: theme.textTheme.titleLarge)),
          if (hint != null)
            Text(hint!, style: theme.textTheme.bodySmall?.copyWith(color: MmPalette.of(context).textMuted)),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.count,
    required this.locked,
    required this.selected,
    required this.onChanged,
  });

  final Category category;
  final int count;
  final bool locked;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = MmPalette.of(context);
    final tags = [
      l.setupQuestionsAvailable(count),
      if (category.ageRating == AgeRating.teen) l.ageTeen,
      if (category.region == 'in') l.regionIndia,
      if (locked) l.premiumLabel,
    ];
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MmRadius.lg),
        side: BorderSide(
          color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
          width: selected ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: selected && !locked,
        onChanged: locked ? null : (v) => onChanged(v ?? false),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MmRadius.lg)),
        contentPadding: const EdgeInsets.symmetric(horizontal: MmSpace.s4, vertical: MmSpace.s1),
        secondary: locked ? Icon(Icons.lock_outline_rounded, color: palette.textMuted) : null,
        title: Text(category.name, style: theme.textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category.description),
            if (category.contentNote != null) ...[
              const SizedBox(height: MmSpace.s1),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: palette.textMuted),
                  const SizedBox(width: MmSpace.s1),
                  Expanded(child: Text(category.contentNote!, style: theme.textTheme.bodySmall)),
                ],
              ),
            ],
            const SizedBox(height: MmSpace.s1),
            Text(
              locked ? '${tags.join(' · ')} — ${l.premiumLocked}' : tags.join(' · '),
              style: theme.textTheme.labelMedium?.copyWith(color: palette.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupSize extends StatelessWidget {
  const _GroupSize({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final v = value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: MmSpace.s2, vertical: MmSpace.s1),
        child: Row(
          children: [
            IconButton(
              tooltip: l.setupPlayersDecrease,
              icon: const Icon(Icons.remove_rounded),
              onPressed: v == null ? null : () => onChanged(v <= minPlayers ? null : v - 1),
            ),
            Expanded(
              child: Text(
                v == null ? l.setupGroupSizeAny : l.setupGroupSizeValue(v),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: l.setupPlayersIncrease,
              icon: const Icon(Icons.add_rounded),
              onPressed: v != null && v >= maxPlayers ? null : () => onChanged(v == null ? minPlayers : v + 1),
            ),
          ],
        ),
      ),
    );
  }
}
