import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/tap_target.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The 16 reactions in picker order (CHAT-6): the main four, then the
/// rest.
const List<Reaction> reactionOrder = [
  Reaction.like,
  Reaction.love,
  Reaction.dislike,
  Reaction.laugh,
  Reaction.fire,
  Reaction.clap,
  Reaction.party,
  Reaction.hundred,
  Reaction.pray,
  Reaction.wow,
  Reaction.sad,
  Reaction.angry,
  Reaction.baseball,
  Reaction.basketball,
  Reaction.soccer,
  Reaction.trophy,
];

String reactionEmoji(Reaction r) => switch (r) {
  Reaction.like => '👍',
  Reaction.love => '❤️',
  Reaction.dislike => '👎',
  Reaction.laugh => '😂',
  Reaction.fire => '🔥',
  Reaction.clap => '👏',
  Reaction.party => '🎉',
  Reaction.hundred => '💯',
  Reaction.pray => '🙏',
  Reaction.wow => '😮',
  Reaction.sad => '😢',
  Reaction.angry => '😡',
  Reaction.baseball => '⚾',
  Reaction.basketball => '🏀',
  Reaction.soccer => '⚽',
  Reaction.trophy => '🏆',
};

String reactionName(AppLocalizations l10n, Reaction r) => switch (r) {
  Reaction.like => l10n.reactionLike,
  Reaction.love => l10n.reactionLove,
  Reaction.dislike => l10n.reactionDislike,
  Reaction.laugh => l10n.reactionLaugh,
  Reaction.fire => l10n.reactionFire,
  Reaction.clap => l10n.reactionClap,
  Reaction.party => l10n.reactionParty,
  Reaction.hundred => l10n.reactionHundred,
  Reaction.pray => l10n.reactionPray,
  Reaction.wow => l10n.reactionWow,
  Reaction.sad => l10n.reactionSad,
  Reaction.angry => l10n.reactionAngry,
  Reaction.baseball => l10n.reactionBaseball,
  Reaction.basketball => l10n.reactionBasketball,
  Reaction.soccer => l10n.reactionSoccer,
  Reaction.trophy => l10n.reactionTrophy,
};

/// How many of [reactionOrder] lead the picker on their own row.
const _mainReactions = 4;

/// The reactions at the top of the message menu (CHAT-6): the main four on
/// one row, then the other 12.
class ReactionPicker extends StatelessWidget {
  const new({required this.mine, required this.onPick, super.key});

  final Reaction? mine;
  final void Function(Reaction) onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    Widget button(Reaction r) => Tooltip(
      message: reactionName(l10n, r),
      // The emoji's own label already names it for screen readers.
      excludeFromSemantics: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => onPick(r),
        child: Container(
          padding: const EdgeInsets.all(Space.xs),
          // At least 48 × 48 to tap (SPEC §7.6), and no wider than that
          // (no alignment, which would stretch it), so the rest of the
          // reactions wrap in rows.
          constraints: const BoxConstraints(
            minWidth: kMinInteractiveDimension,
            minHeight: kMinInteractiveDimension,
          ),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: r == mine ? scheme.primaryContainer : null,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              reactionEmoji(r),
              style: const TextStyle(fontSize: 28),
              semanticsLabel: reactionName(l10n, r),
            ),
          ),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final r in reactionOrder.take(_mainReactions)) button(r),
          ],
        ),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (final r in reactionOrder.skip(_mainReactions)) button(r),
          ],
        ),
      ],
    );
  }
}

/// Chips under a bubble: each reaction with its count, mine highlighted.
/// Tapping shows who reacted (CHAT-6).
class ReactionChips extends StatelessWidget {
  const new({
    required this.message,
    required this.me,
    required this.onShowWho,
    super.key,
  });

  final Message message;
  final String? me;
  final VoidCallback onShowWho;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final counts = <Reaction, int>{};
    for (final r in message.reactions.values) {
      counts[r] = (counts[r] ?? 0) + 1;
    }
    final mine = me == null ? null : message.reactions[me];
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: Space.xs,
      children: [
        for (final r in reactionOrder)
          if (counts[r] case final n?)
            // Read as "Like, 2" rather than the emoji, and a 48-point
            // target around the small chip (SPEC §7.6).
            Semantics(
              container: true,
              button: true,
              selected: r == mine,
              label: l10n.reactionChipLabel(reactionName(l10n, r), n),
              excludeSemantics: true,
              onTap: onShowWho,
              child: TapTargetPadding(
                child: Material(
                  color: r == mine
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHigh,
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: r == mine ? scheme.primary : scheme.outlineVariant,
                    ),
                  ),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: onShowWho,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.sm,
                        vertical: 2,
                      ),
                      child: Text('${reactionEmoji(r)} $n'),
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

/// Who reacted, grouped by reaction.
class ReactionsSheet extends ConsumerWidget {
  const new({required this.message, super.key});

  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final roster = ref.watch(rosterProvider(message.groupId)).value ?? const [];
    String nameOf(String uid) =>
        roster.where((m) => m.uid == UserId(uid)).firstOrNull?.displayName ??
        l10n.formerMember;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: Space.lg),
      children: [
        for (final r in reactionOrder)
          for (final e in message.reactions.entries)
            if (e.value == r)
              ListTile(
                leading: Avatar(name: nameOf(e.key), colorKey: e.key, size: 32),
                title: Text(nameOf(e.key)),
                trailing: Text(
                  reactionEmoji(r),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
      ],
    );
  }
}

/// Runs [f] without waiting; its failure is shown elsewhere or not at all.
void fireAndForget(Future<void> f) => unawaited(f.catchError((Object _) {}));
