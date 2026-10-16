import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/button_spinner.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// My direct conversation with [other] (CHAT-19): at once when it's in
/// Messages already, else from the server, which makes it the first time
/// and checks we share a team. Its ID, or why it can't open, to show.
Future<({GroupId? id, String? error})> findDirectChat(
  WidgetRef ref,
  AppLocalizations l10n,
  UserId other,
) async {
  final known = ref
      .read(myDirectMembershipsProvider)
      .value
      ?.where((m) => m.otherUid == other.value)
      .firstOrNull;
  if (known != null) return (id: known.groupId, error: null);
  try {
    final id = await ref.read(groupRepositoryProvider).openDirectChat(other);
    return (id: id, error: null);
  } on AppFailure catch (e) {
    return (
      id: null,
      error: switch (e) {
        PermissionDenied() => l10n.directNoSharedTeam,
        InvalidInput(message: 'blocked') => l10n.directBlocked,
        InvalidInput() => l10n.directNotAvailable,
        RateLimited() => l10n.signInRateLimited,
        _ => l10n.directOpenFailed,
      },
    );
  }
}

/// Opens my direct conversation with [other] (CHAT-19), or says why it
/// can't. Returns whether it opened.
Future<bool> openDirectChatWith(
  BuildContext context,
  WidgetRef ref,
  UserId other,
) async {
  final found = await findDirectChat(ref, AppLocalizations.of(context), other);
  if (!context.mounted) return false;
  final id = found.id;
  if (id == null) {
    showAppSnackBar(context, found.error ?? '');
    return false;
  }
  unawaited(context.push('/messages/${id.value}'));
  return true;
}

/// "Message", which opens my conversation with [uid] (CHAT-19), with a
/// spinner while the server makes it. Not for myself, someone not joined
/// yet, or someone I blocked: the person page offers Unblock instead.
class MessageButton extends ConsumerStatefulWidget {
  const new({required this.uid, required this.name, super.key});

  final UserId uid;
  final String name;

  @override
  ConsumerState<MessageButton> createState() => _MessageButtonState();
}

class _MessageButtonState extends ConsumerState<MessageButton> {
  bool _opening = false;

  Future<void> _open() async {
    setState(() => _opening = true);
    await openDirectChatWith(context, ref, widget.uid);
    if (mounted) setState(() => _opening = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(authUserProvider).value?.uid;
    if (me == null || me == widget.uid.value) return const SizedBox.shrink();
    return Tooltip(
      message: l10n.messagePersonTooltip(widget.name),
      child: FilledButton.icon(
        onPressed: _opening ? null : () => unawaited(_open()),
        icon: _opening
            ? const ButtonSpinner()
            : const Icon(AppIcons.directMessage),
        label: Text(l10n.messagePerson),
      ),
    );
  }
}

/// A person's profile (TEAM-15), from a chat or the roster. [teamId] is the
/// team it was opened from, which the page lists even when that team keeps
/// its people to its admins: they were already seen there.
void openPersonPage(BuildContext context, UserId uid, {GroupId? teamId}) =>
    unawaited(context.push(personPageLocation(uid, teamId: teamId)));

/// Where a person's page is ([openPersonPage]).
String personPageLocation(UserId uid, {GroupId? teamId}) => Uri(
  path: '/people/${uid.value}',
  queryParameters: teamId == null ? null : {'team': teamId.value},
).toString();
