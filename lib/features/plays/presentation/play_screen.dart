import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/plays_icon.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/plays/application/providers.dart';
import 'package:battleplan/features/plays/domain/play.dart';
import 'package:battleplan/features/plays/domain/play_gif.dart';
import 'package:battleplan/features/plays/domain/play_rules.dart';
import 'package:battleplan/features/plays/presentation/play_board.dart';
import 'package:battleplan/features/plays/presentation/play_image.dart';
import 'package:battleplan/features/plays/presentation/step_player.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// One play, for everyone on the team (BOARD-3, BOARD-4): the board, step
/// by step, and its notes, with Post to chat and Save as GIF under it
/// (BOARD-5). Admins edit, duplicate, and delete it.
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

  /// While posting: the picture is being drawn.
  bool _posting = false;

  /// While the GIF is being made: how far along, 0 to 1.
  double? _gifProgress;

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

  /// Puts the play on the coach's whiteboard to show or change it there:
  /// back to the whiteboard if it's underneath, else onto it.
  Future<void> _toWhiteboard(Play play) async {
    await ref.read(whiteboardStoreProvider).save(widget.groupId, (
      board: play.board,
      variant: play.variant,
      title: '',
      note: play.note,
      steps: play.steps,
    ));
    ref.read(whiteboardRevisionProvider.notifier).bump();
    if (!mounted) return;
    final router = GoRouter.of(context);
    final whiteboard = '/g/${widget.groupId.value}/plays';
    while (router.state.uri.path != whiteboard && router.canPop()) {
      router.pop();
    }
    if (router.state.uri.path != whiteboard) router.go(whiteboard);
  }

  /// Posts the play to the team's chat, and goes to the chat to see it
  /// (BOARD-5): a picture of its last step, with its name, that opens the
  /// play.
  Future<void> _postToChat(Play play) async {
    if (_posting) return;
    final l10n = AppLocalizations.of(context);
    // The team's chat stays alive from here until it's on screen, even if
    // it wasn't open yet, so the post goes out from the chat that shows it.
    final chat = chatMessagesProvider(widget.groupId);
    final keep = ref.listenManual(chat, (_, _) {});
    setState(() => _posting = true);
    try {
      final photo = await playImage(play);
      if (!mounted) return;
      final messages = ref.read(chat.notifier);
      context.go('/g/${widget.groupId.value}/chat');
      await messages.sendPhotos(
        [photo],
        caption: play.title,
        playId: play.id.value,
      );
    } on Object {
      if (mounted) showAppSnackBar(context, l10n.playPostFailed);
    } finally {
      keep.close();
      if (mounted) setState(() => _posting = false);
    }
  }

  /// Makes the play's GIF and saves it to the phone's photos, or, in a
  /// browser, shares or downloads it (BOARD-5).
  Future<void> _saveGif(Play play) async {
    if (_gifProgress != null) return;
    final l10n = AppLocalizations.of(context);
    final saver = ref.read(photoSaverProvider);
    final sharer = ref.read(sharerProvider);
    setState(() => _gifProgress = 0);
    try {
      final gif = await playGif(
        play,
        onProgress: (p) {
          if (mounted) setState(() => _gifProgress = p);
        },
      );
      final name = playGifName(play.title);
      if (saver.available) {
        final saved = await saver.saveImage(gif, name: name);
        if (mounted) {
          showAppSnackBar(
            context,
            saved ? l10n.playGifSaved : l10n.playGifSaveFailed,
          );
        }
      } else if (!await sharer.shareFile(
        gif,
        name: '$name.gif',
        mimeType: 'image/gif',
      )) {
        if (mounted) showAppSnackBar(context, l10n.playGifFailed);
      }
    } on Object {
      if (mounted) showAppSnackBar(context, l10n.playGifFailed);
    } finally {
      if (mounted) setState(() => _gifProgress = null);
    }
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
    final canPost = group != null && me != null && !group.isArchived;
    if (play == null) {
      return Scaffold(
        appBar: AppBar(),
        body: async.isLoading
            ? const Center(child: CircularProgressIndicator())
            : EmptyState(
                art: const PlaysIcon(colorful: true, size: 64),
                message: l10n.playGone,
              ),
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
            // On a phone the board runs the screen's width, as big as the
            // team can see it.
            final phone = MediaQuery.sizeOf(context).width < 600;
            final board = Padding(
              padding: phone
                  ? const EdgeInsets.symmetric(vertical: Space.sm)
                  : const EdgeInsets.all(Space.md),
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
                    edgeToEdge: phone,
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
                        // Ink on the cream (or navy) face: the theme's icon color is the
                        // page's, which is the face's own on a colored page (Olive, Candy).
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
                  );
            // Post to chat for the team's members, and Save as GIF for
            // everyone (BOARD-5).
            final making = _gifProgress != null;
            final actions = Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.xs,
                Space.md,
                Space.sm,
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  if (canPost)
                    FilledButton.icon(
                      onPressed: _posting
                          ? null
                          : () => unawaited(_postToChat(play)),
                      icon: const Icon(AppIcons.send),
                      label: Text(l10n.playPostToChat),
                    ),
                  OutlinedButton.icon(
                    onPressed: making ? null : () => unawaited(_saveGif(play)),
                    icon: making
                        ? SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: _gifProgress,
                            ),
                          )
                        : const Icon(AppIcons.download),
                    label: Text(making ? l10n.playMakingGif : l10n.playSaveGif),
                  ),
                ],
              ),
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
                        actions,
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
            // On a phone the notes follow the board, which keeps the
            // screen's width: the page scrolls to them.
            if (phone && note != null) {
              return ListView(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          box.maxHeight -
                          (steps == null ? 0 : kMinInteractiveDimension) -
                          (kMinInteractiveDimension + Space.xs + Space.sm),
                    ),
                    child: board,
                  ),
                  ?steps,
                  actions,
                  note,
                ],
              );
            }
            return Column(
              children: [
                Expanded(child: board),
                ?steps,
                actions,
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
