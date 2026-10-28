import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/plays_icon.dart';
import 'package:battleplan/features/plays/application/providers.dart';
import 'package:battleplan/features/plays/domain/play.dart';
import 'package:battleplan/features/plays/presentation/play_board.dart';
import 'package:battleplan/features/plays/presentation/step_player.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// A shared play at `/p/:shareId` (SPEC BOARD-6), for anyone with its
/// link, signed in or not: the play step by step, and its notes, with no
/// team behind it.
class SharedPlayScreen extends ConsumerStatefulWidget {
  const new({required this.shareId, super.key});

  final String shareId;

  @override
  ConsumerState<SharedPlayScreen> createState() => _SharedPlayScreenState();
}

class _SharedPlayScreenState extends ConsumerState<SharedPlayScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  late final _player = StepPlayer(this);

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playSteps(PlayDraft play) async {
    if (_player.playing) {
      setState(_player.stop);
      return;
    }
    final start = _step >= play.steps.length - 1 ? 0 : _step;
    setState(() => _step = start);
    await _player.play(
      play.steps,
      start: start,
      onStep: (i) => setState(() => _step = i),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(sharedPlayProvider(widget.shareId));
    final play = async.value;
    // Opened from a link, there's nothing underneath: close goes home.
    final leading = context.canPop()
        ? null
        : IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(AppIcons.close),
            onPressed: () => context.go('/'),
          );
    if (play == null) {
      return Scaffold(
        appBar: AppBar(leading: leading, title: Text(l10n.sharedPlayTitle)),
        body: async.isLoading
            ? const Center(child: CircularProgressIndicator())
            : EmptyState(
                art: const PlaysIcon(colorful: true, size: 64),
                message: async.hasError
                    ? l10n.sharedPlayFailed
                    : l10n.sharedPlayGone,
              ),
      );
    }
    final step = _step.clamp(0, play.steps.length - 1);
    final phone = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      appBar: AppBar(
        leading: leading,
        title: Text(
          play.title.isEmpty ? l10n.sharedPlayTitle : play.title,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              children: [
                Padding(
                  padding: phone
                      ? const EdgeInsets.symmetric(vertical: Space.sm)
                      : const EdgeInsets.all(Space.md),
                  child: AnimatedBuilder(
                    animation: _player.controller,
                    builder: (context, _) => PlayBoardView(
                      board: play.board,
                      variant: play.variant,
                      elements: _player.elements(
                        play.steps,
                        play.steps[step].elements,
                      ),
                      semanticLabel: l10n.playBoardLabel(
                        boardName(l10n, play.board),
                      ),
                      edgeToEdge: phone,
                    ),
                  ),
                ),
                if (play.steps.length > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: l10n.playStepBack,
                        icon: const Icon(AppIcons.stepBack),
                        onPressed: step > 0
                            ? () => setState(() => _step = step - 1)
                            : null,
                      ),
                      Text(l10n.playStepOf(step + 1, play.steps.length)),
                      IconButton(
                        tooltip: l10n.playStepNext,
                        icon: const Icon(AppIcons.stepNext),
                        onPressed: step < play.steps.length - 1
                            ? () => setState(() => _step = step + 1)
                            : null,
                      ),
                      const SizedBox(width: Space.sm),
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                        tooltip: _player.playing
                            ? l10n.playStopPlaying
                            : l10n.playPlaySteps,
                        icon: Icon(
                          _player.playing ? AppIcons.stop : AppIcons.play,
                        ),
                        onPressed: () => unawaited(_playSteps(play)),
                      ),
                    ],
                  ),
                if (play.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(Space.lg),
                    child: Text(play.note),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
