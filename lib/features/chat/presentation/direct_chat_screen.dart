import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/chat/presentation/chat_screen.dart';
import 'package:battleplan/features/chat/presentation/direct_actions.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/safety/application/providers.dart';
import 'package:battleplan/features/safety/safety.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// A direct conversation (CHAT-19): the team chat's screen, for two. The
/// header shows the other person's photo and name, which open their page
/// (TEAM-15), and a menu to see their profile, mute the conversation, or
/// block them.
class DirectChatScreen extends ConsumerWidget {
  const new({required this.groupId, this.initialMessageId, super.key});

  final GroupId groupId;

  /// Opens at this message (a notification tap, NOTIF-6).
  final String? initialMessageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(authUserProvider).value?.uid;
    final group = ref.watch(groupProvider(groupId));
    final membership = ref.watch(myMembershipProvider(groupId));
    final g = group.value;
    // One I'm not in, or that's gone, reads as null.
    if (group.hasValue && (g == null || !g.isDirect)) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: AppIcons.error, message: l10n.notFoundTitle),
      );
    }
    final otherUid = membership?.otherUid ?? g?.otherThan(me);
    final person = otherUid == null ? null : g?.people[otherUid];
    final name = person?.name ?? '';
    final photoPath = person?.photoPath;
    final photoUrl = photoPath == null
        ? null
        : ref.watch(teamPhotoUrlProvider(photoPath)).value;
    final muted = membership?.isMutedAt(DateTime.now()) ?? false;
    final blocked =
        otherUid != null && ref.watch(blockedIdsProvider).contains(otherUid);
    // Gone once their account is deleted (AUTH-10): no page to open.
    final closed = g?.isArchived ?? false;

    Future<void> setMuted({required bool on}) async {
      if (me == null) return;
      try {
        await ref
            .read(memberRepositoryProvider)
            .setMutedUntil(
              groupId,
              UserId(me),
              on
                  ? DateTime.fromMillisecondsSinceEpoch(Limits.mutedForeverMs)
                  : null,
            );
        if (context.mounted) {
          showAppSnackBar(
            context,
            on ? l10n.directMutedDone : l10n.directUnmutedDone,
          );
        }
      } on AppFailure {
        if (context.mounted) {
          showAppSnackBar(context, l10n.notificationSaveFailed);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Semantics(
          button: otherUid != null && !closed,
          label: otherUid != null && !closed ? l10n.openProfile(name) : name,
          excludeSemantics: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(Space.sm),
            onTap: otherUid == null || closed
                ? null
                : () => openPersonPage(context, UserId(otherUid)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xs),
              child: Row(
                children: [
                  Avatar(
                    name: name,
                    colorKey: otherUid,
                    imageUrl: photoUrl,
                    size: 36,
                  ),
                  const SizedBox(width: Space.md),
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (muted) ...[
                    const SizedBox(width: Space.sm),
                    Icon(
                      AppIcons.muted,
                      size: 18,
                      semanticLabel: l10n.directMuted,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          if (otherUid != null && !closed)
            PopupMenuButton<String>(
              tooltip: l10n.directMenuTooltip,
              icon: const Icon(AppIcons.menu),
              onSelected: (action) => switch (action) {
                'profile' => openPersonPage(context, UserId(otherUid)),
                'mute' => unawaited(setMuted(on: true)),
                'unmute' => unawaited(setMuted(on: false)),
                'block' => unawaited(
                  confirmBlock(context, ref, uid: UserId(otherUid), name: name),
                ),
                'unblock' => unawaited(unblock(context, ref, UserId(otherUid))),
                _ => null,
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'profile', child: Text(l10n.viewProfile)),
                PopupMenuItem(
                  value: muted ? 'unmute' : 'mute',
                  child: Text(muted ? l10n.directUnmute : l10n.directMute),
                ),
                PopupMenuItem(
                  value: blocked ? 'unblock' : 'block',
                  child: Text(blocked ? l10n.unblock : l10n.blockPerson(name)),
                ),
              ],
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoints.contentMax),
          child: ChatScreen(
            key: ValueKey('dm-${groupId.value}'),
            groupId: groupId,
            initialMessageId: initialMessageId,
          ),
        ),
      ),
    );
  }
}
