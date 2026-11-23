import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/polls/application/providers.dart';
import 'package:battleplan/features/polls/domain/poll.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Who chose each option, or just [optionId] when an option was tapped, and
/// who hasn't voted yet (POLL-3). Only for polls that aren't anonymous; the
/// rules refuse the read otherwise. On a one-vote-per-player poll (#96),
/// the players, each with who voted for them.
class PollVotersSheet extends ConsumerWidget {
  const new({required this.poll, this.optionId, super.key});

  final Poll poll;

  /// The option tapped, or null for every option.
  final String? optionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (poll.perPlayer) return _PlayerVoters(poll: poll, optionId: optionId);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final votes = ref.watch(pollVotesProvider(poll.id));
    final roster = ref.watch(rosterProvider(poll.groupId)).value ?? const [];
    Membership? memberOf(String uid) =>
        roster.where((m) => m.uid == UserId(uid)).firstOrNull;
    String nameOf(String uid) =>
        memberOf(uid)?.nameWithPlayers ?? l10n.formerMember;

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.lg,
        Space.lg,
        Space.xs,
      ),
      child: Text(text, style: theme.textTheme.titleSmall),
    );
    Widget person(String uid) => ListTile(
      dense: true,
      // Initials from the name alone, not "A#" from "Andy D. #12".
      leading: Avatar(
        name: memberOf(uid)?.displayName ?? nameOf(uid),
        colorKey: uid,
        color: memberOf(uid)?.avatarColor,
        size: 32,
      ),
      title: Text(nameOf(uid)),
    );

    final list = votes.value;
    if (list == null) {
      // Lists load with skeleton rows, not spinners (SPEC §7.5).
      return const SkeletonList(rows: 3);
    }
    final voted = {for (final v in list) v.uid};
    final notVoted = [
      for (final m in roster)
        if (!voted.contains(m.uid.value)) m.uid.value,
    ];
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: Space.lg),
      children: [
        heading(l10n.pollVotesTitle),
        for (final option in poll.options)
          if (optionId == null || option.id == optionId)
            if (list.where((v) => v.optionIds.contains(option.id)).toList()
                case final chose) ...[
              heading('${option.text} · ${l10n.pollOptionVotes(chose.length)}'),
              for (final v in chose) person(v.uid),
            ],
        if (notVoted.isNotEmpty) ...[
          heading('${l10n.pollNotVoted} · ${notVoted.length}'),
          for (final uid in notVoted) person(uid),
        ],
      ],
    );
  }
}

/// Who chose each option on a one-vote-per-player poll (#96): each player
/// ("Luke #7") with who voted for them ("Voted by Claire Dunphy"), then
/// the roster's players with no vote yet.
class _PlayerVoters extends ConsumerWidget {
  const new({required this.poll, this.optionId});

  final Poll poll;
  final String? optionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final votes = ref.watch(pollPlayerVotesProvider(poll.id));
    final players = ref.watch(playersProvider(poll.groupId)).value ?? const [];
    final roster = ref.watch(rosterProvider(poll.groupId)).value ?? const [];
    Player? playerOf(PlayerId id) =>
        players.where((p) => p.id == id).firstOrNull;
    String voterName(String uid) =>
        roster.where((m) => m.uid == UserId(uid)).firstOrNull?.displayName ??
        l10n.formerMember;

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.lg,
        Space.lg,
        Space.xs,
      ),
      child: Text(text, style: theme.textTheme.titleSmall),
    );
    Widget player(PlayerId id, {String? votedBy}) {
      final p = playerOf(id);
      final name = p?.label ?? l10n.pollFormerPlayer;
      return ListTile(
        dense: true,
        leading: Avatar(
          name: p?.displayName ?? name,
          colorKey: id.value,
          size: 32,
        ),
        title: Text(name),
        subtitle: votedBy == null ? null : Text(l10n.pollVotedBy(votedBy)),
      );
    }

    final list = votes.value;
    if (list == null) {
      // Lists load with skeleton rows, not spinners (SPEC §7.5).
      return const SkeletonList(rows: 3);
    }
    final voted = {
      for (final v in list)
        if (v.optionIds.isNotEmpty) v.playerId,
    };
    final notVoted = [
      for (final p in players)
        if (!voted.contains(p.id)) p.id,
    ];
    // In roster order, then any who left the roster.
    int order(PlayerPollVote v) {
      final i = players.indexWhere((p) => p.id == v.playerId);
      return i < 0 ? players.length : i;
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: Space.lg),
      children: [
        heading(l10n.pollVotesTitle),
        for (final option in poll.options)
          if (optionId == null || option.id == optionId)
            if (list.where((v) => v.optionIds.contains(option.id)).toList()
                  ..sort((a, b) => order(a) - order(b))
                case final chose) ...[
              heading('${option.text} · ${l10n.pollOptionVotes(chose.length)}'),
              for (final v in chose)
                player(v.playerId, votedBy: voterName(v.uid)),
            ],
        if (notVoted.isNotEmpty) ...[
          heading('${l10n.pollNotVoted} · ${notVoted.length}'),
          for (final id in notVoted) player(id),
        ],
      ],
    );
  }
}
