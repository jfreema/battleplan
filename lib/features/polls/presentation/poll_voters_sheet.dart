import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/polls/application/providers.dart';
import 'package:battleplan/features/polls/domain/poll.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Who chose each option, and who hasn't voted yet (POLL-3). Only for
/// polls that aren't anonymous; the rules refuse the read otherwise.
class PollVotersSheet extends ConsumerWidget {
  const new({required this.poll, super.key});

  final Poll poll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final votes = ref.watch(pollVotesProvider(poll.id));
    final roster = ref.watch(rosterProvider(poll.groupId)).value ?? const [];
    String nameOf(String uid) =>
        roster
            .where((m) => m.uid == UserId(uid))
            .firstOrNull
            ?.nameWithPlayers ??
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
    Widget person(String uid) => ListTile(
      dense: true,
      leading: Avatar(name: nameOf(uid), colorKey: uid, size: 32),
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
