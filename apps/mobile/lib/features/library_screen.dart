import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/tokens.g.dart';
import '../widgets/mode_tile.dart';
import 'modes.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).libraryTitle)),
      body: ListView.separated(
        padding: const EdgeInsets.all(MmSpace.s4),
        itemCount: GameMode.values.length,
        separatorBuilder: (_, _) => const SizedBox(height: MmSpace.s3),
        itemBuilder: (_, i) => ModeTile(mode: GameMode.values[i]),
      ),
    );
  }
}
