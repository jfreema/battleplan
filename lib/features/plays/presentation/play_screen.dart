import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/plays/application/providers.dart';
import 'package:battleplan/features/plays/domain/play.dart';
import 'package:battleplan/features/plays/domain/play_rules.dart';
import 'package:battleplan/features/plays/presentation/play_board.dart';
import 'package:battleplan/features/plays/presentation/step_player.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// One play, for everyone on the team (BOARD-3, BOARD-4): the board, step
/// by step, and its notes. Admins edit, duplicate, and delete it.
class PlayScreen extends ConsumerStatefulWidget {
  const new({required this.groupId, required this.playId, super.key});

  final GroupId groupId;
  final PlayId playId;

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  late final _player = StepPlayer(this);

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  /// Plays the steps, the players and the ball gliding between them.
  Future<void> _playSteps(Play play) async {
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

  /// Puts the play on the coach's whiteboard to show or change it there.
  Future<void> _toWhiteboard(Play play) async {
    await ref.read(whiteboardStoreProvider).save(widget.groupId, (
      board: play.board,
      variant: play.variant,
      title: '',
      note: play.note,
      steps: play.steps,
    ));
    if (mounted) context.go('/g/${widget.groupId.value}/plays');
  }

  Future<void> _duplicate(Play play) async {
    final l10n = AppLocalizations.of(context);
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid == null) return;
    try {
      final id = await ref.read(playRepositoryProvider).create(
        play.groupId,
        UserId(uid),
        (
          board: play.board,
          variant: play.variant,
          title: l10n.playCopyOf(play.title),
          note: play.note,
          steps: play.steps,
        ),
      );
      if (!mounted) return;
      unawaited(context.push('/g/${widget.groupId.value}/plays/${id.value}'));
    } on AppFailure {
      if (mounted) showAppSnackBar(context, l10n.playSaveFailed);
    }
  }

  Future<void> _delete(Play play) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.playDeleteTitle(play.title),
      confirmLabel: l10n.playDelete,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(playRepositoryProvider).delete(play.id);
      if (mounted) context.pop();
    } on AppFailure {
      if (mounted) showAppSnackBar(context, l10n.playDeleteFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(playProvider(widget.playId));
    final play = async.value;
    final group = ref.watch(groupProvider(widget.groupId)).value;
    final me = ref.watch(myMembershipProvider(widget.groupId));
    final superAdmin = ref.watch(authUserProvider).value?.isSuperAdmin ?? false;
    final canEdit =
        group != null && canEditPlays(group, me, superAdmin: superAdmin);
    if (play == null) {
      return Scaffold(
        appBar: AppBar(),
        body: async.isLoading
            ? const Center(child: CircularProgressIndicator())
            : EmptyState(icon: AppIcons.plays, message: l10n.playGone),
      );
    }
    final step = _step.clamp(0, play.steps.length - 1);
    return Scaffold(
      appBar: AppBar(
        title: Text(play.title, overflow: TextOverflow.ellipsis),
        actions: [
          if (canEdit) ...[
            IconButton(
              tooltip: l10n.playEdit,
              icon: const Icon(AppIcons.edit),
              onPressed: () => unawaited(
                context.push(
                  '/g/${widget.groupId.value}/plays/${play.id.value}/edit',
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: l10n.playMore,
              onSelected: (v) => unawaited(switch (v) {
                'board' => _toWhiteboard(play),
                'copy' => _duplicate(play),
                _ => _delete(play),
              }),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'board',
                  child: Text(l10n.playToWhiteboard),
                ),
                PopupMenuItem(value: 'copy', child: Text(l10n.playDuplicate)),
                PopupMenuItem(value: 'delete', child: Text(l10n.playDelete)),
              ],
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final board = Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Center(
                // While playing, the board repaints each frame.
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
                  ),
                ),
              ),
            );
            final steps = play.steps.length < 2
                ? null
                : Row(
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
                        tooltip: _player.playing
                            ? l10n.playStopPlaying
                            : l10n.playPlaySteps,
                        icon: Icon(
                          _player.playing ? AppIcons.stop : AppIcons.play,
                        ),
                        onPressed: () => unawaited(_playSteps(play)),
                      ),
                    ],
                  );
            final note = play.note.isEmpty
                ? null
                : Padding(
                    padding: const EdgeInsets.all(Space.lg),
                    child: Text(play.note),
                  );
            // On a wide screen the notes sit beside the board.
            if (box.maxWidth >= 900 && note != null) {
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(child: board),
                        ?steps,
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: SingleChildScrollView(child: note),
                  ),
                ],
              );
            }
            return Column(
              children: [
                Expanded(child: board),
                ?steps,
                if (note != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: box.maxHeight * 0.3),
                    child: SingleChildScrollView(child: note),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
