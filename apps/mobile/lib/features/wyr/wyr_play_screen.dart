import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/content.dart';
import '../../game/wyr_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../state/wyr_session.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';

class WyrPlayScreen extends ConsumerStatefulWidget {
  const WyrPlayScreen({super.key});

  @override
  ConsumerState<WyrPlayScreen> createState() => _WyrPlayScreenState();
}

class _WyrPlayScreenState extends ConsumerState<WyrPlayScreen> {
  late final ScreenAwake _awake;

  @override
  void initState() {
    super.initState();
    _awake = ref.read(screenAwakeProvider);
    _awake.enable();
  }

  @override
  void dispose() {
    _awake.disable();
    super.dispose();
  }

  void _act(WyrAction action) {
    if (action is Vote && ref.read(settingsProvider).haptics) HapticFeedback.selectionClick();
    ref.read(wyrSessionProvider.notifier).dispatch(action);
    if (ref.read(wyrSessionProvider)?.status == WyrStatus.finished) {
      context.pushReplacement('/play/would-you-rather/results');
    }
  }

  Future<void> _confirmQuit() async {
    final l = AppLocalizations.of(context);
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.playQuitTitle),
        content: Text(l.playQuitBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.playKeepPlaying)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l.playQuitConfirm)),
        ],
      ),
    );
    if (quit == true && mounted) {
      ref.read(wyrSessionProvider.notifier).clear();
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(wyrSessionProvider);
    final current = session?.current;
    final pack = ref.watch(contentProvider).wyr;
    final item = current == null ? null : pack.item(current.questionId);

    if (session == null || current == null || item == null) {
      // Nothing to play (e.g. opened from a stale link): offer a way out instead of a blank screen.
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.errorNotFound),
              const SizedBox(height: MmSpace.s4),
              FilledButton(onPressed: () => context.go('/'), child: Text(l.goHome)),
            ],
          ),
        ),
      );
    }

    final reduceMotion = reduceMotionOf(context, ref);
    final cap = session.config.playerCount;
    final votes = current.votes.length;
    final full = cap != null && votes >= cap;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(tooltip: l.playQuit, icon: const Icon(Icons.close_rounded), onPressed: _confirmQuit),
          title: Text(l.playRound(session.roundNumber, session.totalRounds)),
          centerTitle: true,
          actions: [
            if (!current.revealed)
              TextButton(
                onPressed: () => _act(const SkipQuestion()),
                child: Tooltip(message: l.playSkipTooltip, child: Text(l.playSkip)),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: session.rounds.length / session.totalRounds,
              minHeight: 4,
              semanticsLabel: l.playRound(session.roundNumber, session.totalRounds),
            ),
          ),
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
            child: _Question(
              key: ValueKey(item.id),
              item: item,
              current: current,
              full: full,
              reduceMotion: reduceMotion,
              onVote: (side) => _act(Vote(side)),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(MmSpace.s4, MmSpace.s2, MmSpace.s4, MmSpace.s4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cap != null ? l.playVotesOfPlayers(votes, cap) : l.playVotes(votes),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: MmSpace.s2),
                Row(
                  children: [
                    if (!current.revealed) ...[
                      OutlinedButton.icon(
                        onPressed: votes == 0 ? null : () => _act(const Undo()),
                        icon: const Icon(Icons.undo_rounded),
                        label: Text(l.playUndo),
                      ),
                      const SizedBox(width: MmSpace.s3),
                    ],
                    Expanded(
                      child: current.revealed
                          ? FilledButton(
                              onPressed: () => _act(const Next()),
                              child: Text(session.isLastRound ? l.playFinish : l.playNext),
                            )
                          : FilledButton(onPressed: () => _act(const Reveal()), child: Text(l.playReveal)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({
    super.key,
    required this.item,
    required this.current,
    required this.full,
    required this.reduceMotion,
    required this.onVote,
  });

  final WyrItem item;
  final WyrCurrent current;
  final bool full;
  final bool reduceMotion;
  final ValueChanged<Side> onVote;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = MmPalette.of(context);
    final a = current.count(Side.a);
    final b = current.count(Side.b);
    final total = a + b;

    String? verdict;
    if (current.revealed) {
      verdict = total == 0
          ? l.playNoVotes
          : a == b
          ? l.playTie
          : (a == 0 || b == 0) && total > 1
          ? l.playUnanimous
          : null;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(MmSpace.s4, MmSpace.s4, MmSpace.s4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.playPrompt, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: MmSpace.s1),
          Text(
            current.revealed ? (verdict ?? '') : l.playHint,
            style: theme.textTheme.bodyMedium?.copyWith(color: palette.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MmSpace.s4),
          Expanded(
            child: _OptionCard(
              text: item.a,
              color: palette.optionA,
              onColor: palette.onOption,
              votes: a,
              total: total,
              revealed: current.revealed,
              enabled: !current.revealed && !full,
              reduceMotion: reduceMotion,
              onTap: () => onVote(Side.a),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: MmSpace.s2),
            child: Center(
              child: Text(l.playOr, style: theme.textTheme.titleLarge?.copyWith(color: palette.textMuted)),
            ),
          ),
          Expanded(
            child: _OptionCard(
              text: item.b,
              color: palette.optionB,
              onColor: palette.onOption,
              votes: b,
              total: total,
              revealed: current.revealed,
              enabled: !current.revealed && !full,
              reduceMotion: reduceMotion,
              onTap: () => onVote(Side.b),
            ),
          ),
          const SizedBox(height: MmSpace.s2),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.text,
    required this.color,
    required this.onColor,
    required this.votes,
    required this.total,
    required this.revealed,
    required this.enabled,
    required this.reduceMotion,
    required this.onTap,
  });

  final String text;
  final Color color;
  final Color onColor;
  final int votes;
  final int total;
  final bool revealed;
  final bool enabled;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final share = total == 0 ? 0.0 : votes / total;
    final percent = (share * 100).round();
    final style = theme.textTheme.headlineSmall?.copyWith(color: onColor, fontWeight: FontWeight.w600);

    return Semantics(
      button: enabled,
      label: revealed ? '$text. ${l.playVotes(votes)}, ${l.playSplit(percent)}' : l.playVoteFor(text),
      value: revealed ? null : l.playVotes(votes),
      excludeSemantics: true,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(MmRadius.xl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Stack(
            children: [
              if (revealed)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: share),
                      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => FractionallySizedBox(
                        widthFactor: v,
                        heightFactor: 1,
                        child: ColoredBox(color: Colors.black.withValues(alpha: 0.18)),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(MmSpace.s5),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 80),
                      child: Text(text, style: style, textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: MmSpace.s3,
                top: MmSpace.s3,
                child: _Badge(text: revealed ? l.playSplit(percent) : '$votes', color: onColor, onColor: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color, required this.onColor});

  final String text;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 40),
      padding: const EdgeInsets.symmetric(horizontal: MmSpace.s3, vertical: MmSpace.s1),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(MmRadius.pill)),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: onColor, fontWeight: FontWeight.w800, fontSize: MmFontSize.lg),
      ),
    );
  }
}
