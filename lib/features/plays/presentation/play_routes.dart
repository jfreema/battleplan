import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/plays/application/providers.dart';
import 'package:battleplan/features/plays/domain/play_rules.dart';
import 'package:battleplan/features/plays/presentation/play_editor_screen.dart';
import 'package:battleplan/features/plays/presentation/plays_screen.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// `/g/:groupId/plays` (SPEC §6.16): the whiteboard for the team's coaches,
/// with what was last drawn on this device, or the team's sport's board;
/// the saved plays for everyone else.
class PlaysRoute extends ConsumerWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupProvider(groupId)).value;
    final me = ref.watch(myMembershipProvider(groupId));
    final superAdmin = ref.watch(authUserProvider).value?.isSuperAdmin ?? false;
    if (group == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (!canEditPlays(group, me, superAdmin: superAdmin)) {
      return SavedPlaysScreen(groupId: groupId);
    }
    // A play put on the whiteboard makes a new editor, with it.
    final revision = ref.watch(whiteboardRevisionProvider);
    final kept = ref.read(whiteboardStoreProvider).load(groupId);
    return PlayEditorScreen(
      key: ValueKey(revision),
      groupId: groupId,
      whiteboard: true,
      freshBoard: kept == null,
      initial: kept ?? draftFor(defaultChoice(group.sport)),
    );
  }
}

/// `/g/:groupId/plays/:playId/edit`: the editor on a saved play.
class EditPlayRoute extends ConsumerWidget {
  const new({required this.groupId, required this.playId, super.key});

  final GroupId groupId;
  final PlayId playId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(playProvider(playId));
    final play = async.value;
    if (play == null) {
      return Scaffold(
        appBar: AppBar(),
        body: async.isLoading
            ? const Center(child: CircularProgressIndicator())
            : EmptyState(
                icon: AppIcons.plays,
                message: AppLocalizations.of(context).playGone,
              ),
      );
    }
    return PlayEditorScreen(
      // A new editor if the play is swapped out from under it.
      key: ValueKey(play.id),
      groupId: groupId,
      playId: play.id,
      initial: (
        board: play.board,
        variant: play.variant,
        title: play.title,
        note: play.note,
        steps: play.steps,
      ),
    );
  }
}
