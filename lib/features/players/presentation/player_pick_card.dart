import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_buttons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/logging.dart';
import 'package:battleplan/core/text_lists.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// "Waiting for the coach to approve Max" (or "Max and Sofia"), while a
/// claim of mine or a player I added waits for a team admin (PLAYER-3).
/// The chat's card, the Team tab, the schedule's cards, the event page, and
/// Dues all say it this way. Without a name to give, the plain line.
String playerPickWaitingText(AppLocalizations l10n, PlayerPick pick) =>
    pick.waitingFor.isEmpty
    ? l10n.claimWaiting
    : l10n.playerPickWaiting(joinAnd(l10n, pick.waitingFor));

/// Where "Pick my player" goes: "Who are you here for?" (PLAYER-3), pushed,
/// so asking there comes back to where the person was.
void openPlayerPick(BuildContext context, GroupId groupId) =>
    unawaited(context.push('/g/${groupId.value}/who'));

/// The card at the top of a team's chat for a member who isn't linked to a
/// player yet (PLAYER-3; owner's go 2026-11-16, "Do #11"). Joining goes
/// straight into the chat, so this is where a new parent learns how to
/// answer RSVPs: "Here for a player? Pick who's yours so you can answer
/// RSVPs.", with **Pick my player** and **Not now**. Once they've asked, it
/// says who they're waiting on, with a close button.
///
/// It never has to be answered: one tap closes it, and closing saves
/// [HereFor.later] on their membership, so it stays closed on every
/// device. It shows nothing for admins, coaches, people already linked,
/// and groups ([myPlayerPickProvider]).
class PlayerPickCard extends ConsumerWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  /// Saves "Not now": the card and the schedule's hints stop for this team.
  Future<void> _close(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid == null) return;
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(memberRepositoryProvider)
          .setMyHereFor(groupId, UserId(uid), HereFor.later);
    } on Object catch (e) {
      Log.warn('Saving Not now on the pick-your-player card failed', e);
      if (context.mounted) showAppSnackBar(context, l10n.playerPickSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The chat is the first screen a team shows, so for most people this
    // card reads nothing more than their membership, which the chat has
    // already: someone who manages the team, has answered, or whose
    // membership names their players (its `playerSummary`, kept by the
    // server) can't get the card. Only those fields are watched, because
    // the membership changes with every message read.
    final never = ref.watch(
      myMembershipProvider(groupId).select(
        (m) =>
            m == null ||
            m.isAdmin ||
            m.hereFor != null ||
            (m.playerSummary?.trim().isNotEmpty ?? false),
      ),
    );
    if (never) return const SizedBox.shrink();
    final pick = ref.watch(myPlayerPickProvider(groupId));
    if (!pick.card) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final waiting = pick.stage == PlayerPickStage.waiting;
    final page = GumdropColors.of(context);
    final outline = page.surfaceBorderWidth == 0
        ? BorderSide.none
        : BorderSide(color: page.surfaceBorder, width: page.surfaceBorderWidth);
    final gutter = Space.gutter(MediaQuery.sizeOf(context).width);
    return Padding(
      // The lip sits in the 4 px under the card.
      padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 10),
      child: Container(
        decoration: GumdropStyle.of(context)
            .cardDecoration(page.surface, 18, side: outline),
        padding: EdgeInsets.fromLTRB(14, 10, waiting ? 4 : 14, 10),
        child: GumdropSurface(
          child: Builder(
            builder: (context) {
              final card = GumdropColors.of(context);
              final buttons = GumdropButtons.of(context);
              final text = Text(
                waiting
                    ? playerPickWaitingText(l10n, pick)
                    : l10n.playerPickCard,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  height: 20 / 15,
                  color: card.textPrimary,
                ),
              );
              final icon = Icon(
                waiting ? AppIcons.time : AppIcons.family,
                size: 22,
                color: card.textMuted,
              );
              if (waiting) {
                return Row(
                  children: [
                    icon,
                    const SizedBox(width: 10),
                    Expanded(child: text),
                    IconButton(
                      tooltip: l10n.dismiss,
                      icon: Icon(AppIcons.close, color: card.textMuted),
                      onPressed: () => unawaited(_close(context, ref)),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      icon,
                      const SizedBox(width: 10),
                      Expanded(child: text),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Wraps onto two lines at large text sizes.
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton(
                        style: buttons.accent(
                          card.you,
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        onPressed: () => openPlayerPick(context, groupId),
                        child: Text(l10n.pickMyPlayer),
                      ),
                      OutlinedButton(
                        style: buttons.secondary(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        onPressed: () => unawaited(_close(context, ref)),
                        child: Text(l10n.notNow),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
