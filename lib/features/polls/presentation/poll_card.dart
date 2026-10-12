import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/polls/application/providers.dart';
import 'package:battleplan/features/polls/domain/poll.dart';
import 'package:battleplan/features/polls/presentation/poll_voters_sheet.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// A poll in the chat (POLL-2, CHAT-11): the question, each option with a
/// live result bar, count, and percentage, checkmarks on my choices, how
/// many people voted, and when it closes. Tapping an option votes; tapping
/// it again removes the vote. Results are always visible.
class PollCard extends ConsumerWidget {
  const new({required this.pollId, required this.groupId, super.key});

  final PollId pollId;
  final GroupId groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final poll = ref.watch(pollProvider(pollId));
    final frame = BoxDecoration(
      color: scheme.surfaceContainerLow,
      border: Border.all(color: scheme.outlineVariant),
      borderRadius: BorderRadius.circular(Corners.bubble),
    );
    final value = poll.value;
    if (value == null) {
      return Container(
        width: 320,
        padding: const EdgeInsets.all(Space.md),
        decoration: frame,
        child: poll.isLoading
            ? const LinearProgressIndicator()
            : Text(
                l10n.pollRemoved,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: scheme.onSurfaceVariant,
                ),
              ),
      );
    }
    final mine = ref.watch(myPollVoteProvider(pollId)).value ?? const {};
    final me = ref.watch(authUserProvider).value?.uid;
    final isAdmin = ref.watch(myMembershipProvider(groupId))?.isAdmin ?? false;
    final closed = value.isClosedAt(DateTime.now());
    final canClose = !closed && (value.createdBy == me || isAdmin);
    final leaders = closed ? value.leaders : const <String>{};

    final tags = [
      if (value.anonymous) l10n.pollAnonymous,
      if (value.allowMultiple) l10n.pollChooseAny,
    ];
    final status = closed
        ? l10n.pollClosed
        : value.closesAt == null
        ? null
        : l10n.pollClosesAt(closesLabel(l10n, value.closesAt!, DateTime.now()));

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.fromLTRB(
        Space.md,
        Space.sm,
        Space.md,
        Space.xs,
      ),
      decoration: frame,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(AppIcons.poll, size: 16, color: scheme.primary),
              const SizedBox(width: Space.xs),
              Flexible(
                child: Text(
                  [l10n.pollLabel, ...tags].join(' · '),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(value.question, style: theme.textTheme.titleMedium),
          const SizedBox(height: Space.sm),
          for (final option in value.options)
            _OptionRow(
              poll: value,
              option: option,
              chosen: mine.contains(option.id),
              leading: leaders.contains(option.id),
              onTap: closed
                  ? null
                  : () =>
                        unawaited(_vote(context, ref, value, mine, option.id)),
              onLongPress: value.anonymous || value.voterCount == 0
                  ? null
                  : () => unawaited(_showVoters(context, value)),
            ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Space.xs,
            children: [
              Text(
                [l10n.pollVoters(value.voterCount), ?status].join(' · '),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (!value.anonymous && value.voterCount > 0)
                TextButton(
                  onPressed: () => unawaited(_showVoters(context, value)),
                  child: Text(l10n.pollSeeVotes),
                ),
              if (canClose)
                TextButton(
                  onPressed: () => unawaited(_close(context, ref, value)),
                  child: Text(l10n.pollClose),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _vote(
    BuildContext context,
    WidgetRef ref,
    Poll poll,
    Set<String> mine,
    String optionId,
  ) async {
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid == null) return;
    final l10n = AppLocalizations.of(context);
    final next = toggledVote(mine, optionId, allowMultiple: poll.allowMultiple);
    try {
      await ref.read(pollRepositoryProvider).setVote(poll, UserId(uid), next);
    } on AppFailure catch (e) {
      if (!context.mounted) return;
      // Refused by the rules: it closed while this screen showed it open.
      showAppSnackBar(
        context,
        e is PermissionDenied ? l10n.pollVoteClosed : l10n.pollVoteFailed,
      );
    }
  }

  Future<void> _showVoters(BuildContext context, Poll poll) =>
      showAdaptiveSheet<void>(
        context,
        builder: (_) => PollVotersSheet(poll: poll),
      );

  Future<void> _close(BuildContext context, WidgetRef ref, Poll poll) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.pollCloseTitle,
      message: l10n.pollCloseBody,
      confirmLabel: l10n.pollClose,
      cancelLabel: l10n.cancel,
    );
    if (!ok) return;
    try {
      await ref.read(pollRepositoryProvider).closePoll(poll.id);
    } on AppFailure {
      if (context.mounted) showAppSnackBar(context, l10n.pollCloseFailed);
    }
  }
}

/// When a poll closes, short: "5:00 PM" today, "Fri 5:00 PM" this week,
/// "Fri, Oct 23 5:00 PM" further out.
String closesLabel(AppLocalizations l10n, DateTime at, DateTime now) {
  final local = at.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final days = day.difference(today).inDays;
  final format = days == 0
      ? DateFormat.jm(l10n.localeName)
      : days > 0 && days < 7
      ? DateFormat.E(l10n.localeName).add_jm()
      : DateFormat.MMMEd(l10n.localeName).add_jm();
  return format.format(local);
}

/// One option: a bar filled to its share of voters behind the text, my
/// checkmark, and the count and percentage.
class _OptionRow extends StatelessWidget {
  const new({
    required this.poll,
    required this.option,
    required this.chosen,
    required this.leading,
    required this.onTap,
    required this.onLongPress,
  });

  final Poll poll;
  final PollOption option;
  final bool chosen;

  /// Ahead once the poll has closed.
  final bool leading;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final share = poll.shareOf(option.id);
    final votes = poll.votesFor(option.id);
    final radius = BorderRadius.circular(Corners.chip);
    final check = poll.allowMultiple
        ? (chosen ? Icons.check_box : Icons.check_box_outline_blank)
        : (chosen ? Icons.check_circle : Icons.radio_button_unchecked);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Semantics(
        button: onTap != null,
        selected: chosen,
        label: '${option.text}, ${l10n.pollOptionVotes(votes)}',
        // The label replaces the row's own semantics, so it carries the
        // actions too, or screen readers couldn't vote.
        excludeSemantics: true,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Material(
          color: scheme.surface,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Stack(
              children: [
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: share,
                    child: ColoredBox(
                      color: chosen || leading
                          ? scheme.primaryContainer
                          : scheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.sm,
                    vertical: Space.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        check,
                        size: 20,
                        color: chosen ? scheme.primary : scheme.outline,
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: Text(
                          option.text,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: leading ? FontWeight.w600 : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      Text(
                        '$votes · ${(share * 100).round()}%',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
