import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../state/games.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';

class PlayersScreen extends ConsumerStatefulWidget {
  const PlayersScreen({super.key});

  @override
  ConsumerState<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends ConsumerState<PlayersScreen> {
  final _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _add() {
    final name = _field.text.trim();
    if (name.isEmpty) return;
    final names = ref.read(lineupProvider);
    if (names.length >= maxNames) return;
    ref.read(lineupProvider.notifier).set([...names, name]);
    _field.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final names = ref.watch(lineupProvider);
    final full = names.length >= maxNames;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.playersTitle),
        actions: [
          if (names.isNotEmpty)
            TextButton(onPressed: () => ref.read(lineupProvider.notifier).set(const []), child: Text(l.playersClear)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(MmSpace.s4),
        children: [
          Text(l.playersBody, style: TextStyle(color: MmPalette.of(context).textMuted)),
          const SizedBox(height: MmSpace.s4),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _field,
                  enabled: !full,
                  maxLength: 24,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l.playersName,
                    helperText: full ? l.playersFull(maxNames) : null,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: MmSpace.s2),
              FilledButton(onPressed: full ? null : _add, child: Text(l.playersAdd)),
            ],
          ),
          const SizedBox(height: MmSpace.s4),
          for (final (i, name) in names.indexed)
            Card(
              margin: const EdgeInsets.only(bottom: MmSpace.s2),
              child: ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(name),
                trailing: IconButton(
                  tooltip: l.playersRemove(name),
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => ref.read(lineupProvider.notifier).set([...names]..removeAt(i)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
