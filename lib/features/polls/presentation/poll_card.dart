import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_buttons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_shape.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/team_theme.dart';
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
/// it again removes the vote. Results are always visible. On polls that
/// aren't anonymous, tapping an option's count (or long-pressing the
/// option) shows who chose it, and See votes shows everyone, including who
/// hasn't voted (POLL-3).
///
/// Drawn as Gumdrop Pop's poll card (§3.10): a POLL tag, who asked and
/// when, the question, each option a gumdrop with its bar, and the footer.
class PollCard extends ConsumerStatefulWidget {
  const new({
    required this.pollId,
    required this.groupId,
    this.asked,
    this.time,
    super.key,
  });

  final PollId pollId;
  final GroupId groupId;

  /// Who asked, "You asked" or "Coach L. asked", beside the tag.
  final String? asked;

  /// When it was asked, at the end of the tag's row.
  final String? time;

  @override
  ConsumerState<PollCard> createState() => _PollCardState();
}

class _PollCardState extends ConsumerState<PollCard> {
  /// Rebuilds the card at its close time, so it turns Closed on time even
  /// though the server's tick writes closedAt a few minutes later.
  Timer? _closeTimer;
  DateTime? _timerFor;

  /// Set when the timer for [_timerFor] fires.
  bool _reachedClose = false;

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  void _rebuildAt(DateTime? closesAt) {
    if (closesAt == _timerFor) return;
    _closeTimer?.cancel();
    _timerFor = closesAt;
    _reachedClose = false;
    final wait = closesAt?.difference(DateTime.now());
    if (wait == null || wait.isNegative) return;
    _closeTimer = Timer(wait, () {
      if (mounted) setState(() => _reachedClose = true);
    });
  }

  PollId get pollId => widget.pollId;
  GroupId get groupId => widget.groupId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final poll = ref.watch(pollProvider(pollId));
    Widget frame(Widget child) => ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: GumdropCard(
        radius: Corners.panel,
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 9),
        child: child,
      ),
    );
    final value = poll.value;
    if (value == null) {
      return frame(
        Builder(
          builder: (context) => poll.isLoading
              ? const LinearProgressIndicator()
              : Text(
                  l10n.pollRemoved,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: GumdropColors.of(context).textMuted,
                  ),
                ),
        ),
      );
    }
    final mine = ref.watch(myPollVoteProvider(pollId)).value ?? const {};
    final me = ref.watch(authUserProvider).value?.uid;
    final isAdmin =
        (ref.watch(myMembershipProvider(groupId))?.isAdmin ?? false) ||
        (ref.watch(authUserProvider).value?.isSuperAdmin ?? false);
    // Archived teams are read-only (TEAM-9): results show, nothing changes.
    final archived =
        ref.watch(groupProvider(groupId)).value?.isArchived ?? false;
    // A super admin viewing the team sees results but can't vote (ADMIN-3).
    final viewing = ref.watch(viewingAsSuperAdminProvider(groupId));
    if (value.closedAt == null) _rebuildAt(value.closesAt);
    final closed = value.isClosedAt(DateTime.now()) || _reachedClose;
    final canClose = !closed && !archived && (value.createdBy == me || isAdmin);
    final leaders = closed ? value.leaders : const <String>{};

    final tags = [
      ?widget.asked,
      if (value.anonymous) l10n.pollAnonymous,
      if (value.allowMultiple) l10n.pollChooseAny,
    ];
    final status = closed
        ? l10n.pollClosed
        : value.closesAt == null
        ? null
        : l10n.pollClosesAt(closesLabel(l10n, value.closesAt!, DateTime.now()));

    return frame(
      Builder(
        builder: (context) {
          final c = GumdropColors.of(context);
          final buttons = GumdropButtons.of(context);
          final muted = TextStyle(
            fontFamily: AppFonts.body,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: c.textMuted,
          );
          // The footer's 32 px secondary gumdrops, padded out to 48-point
          // targets (SPEC §7.6).
          final small = buttons
              .secondary(
                height: 35,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 35),
                textStyle: GumdropStyle.of(context).label(
                  const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1,
                  ),
                ),
              )
              .copyWith(tapTargetSize: MaterialTapTargetSize.padded);
          final time = widget.time ?? '';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _PollTag(label: l10n.pollLabel),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      tags.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                  ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(width: Space.sm),
                    Text(time, style: muted),
                  ],
                ],
              ),
              const SizedBox(height: Space.sm),
              Text(
                value.question,
                style: GumdropStyle.of(context).label(
                  TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    height: 1.15,
                    color: c.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: Space.sm),
              for (final (i, option) in value.options.indexed) ...[
                if (i > 0) const SizedBox(height: 6),
                _OptionRow(
                  poll: value,
                  option: option,
                  chosen: mine.contains(option.id),
                  leading: leaders.contains(option.id),
                  onTap: closed || archived || viewing
                      ? null
                      : () => unawaited(
                          _vote(context, ref, value, mine, option.id),
                        ),
                  onShowVoters: value.anonymous
                      ? null
                      : () => unawaited(
                          _showVoters(context, value, optionId: option.id),
                        ),
                ),
              ],
              // The count, and the buttons beside it while they fit; on
              // a narrow screen or with large text, the buttons go under.
              OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                overflowAlignment: OverflowBarAlignment.end,
                overflowSpacing: Space.xs,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.sm),
                    child: Text(
                      [l10n.pollVoters(value.voterCount), ?status].join(' · '),
                      style: muted,
                    ),
                  ),
                  OverflowBar(
                    spacing: Space.sm,
                    overflowAlignment: OverflowBarAlignment.end,
                    children: [
                      // Even before anyone votes: it lists who hasn't
                      // (POLL-3).
                      if (!value.anonymous)
                        TextButton(
                          style: small,
                          onPressed: () =>
                              unawaited(_showVoters(context, value)),
                          child: Text(l10n.pollSeeVotes),
                        ),
                      if (canClose)
                        TextButton(
                          style: small,
                          onPressed: () =>
                              unawaited(_close(context, ref, value)),
                          child: Text(l10n.pollClose),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
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

  Future<void> _showVoters(
    BuildContext context,
    Poll poll, {
    String? optionId,
  }) => showAdaptiveSheet<void>(
    context,
    builder: (_) => PollVotersSheet(poll: poll, optionId: optionId),
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

/// The POLL tag (§3.6): a small bubblegum chip with the poll icon.
class _PollTag extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 23),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: c.bubblegum.face,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.poll, size: 14, weight: 700, color: c.ink),
          const SizedBox(width: 5),
          Text(
            label,
            style: GumdropStyle.of(context).label(
              TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1,
                letterSpacing: 0.72,
                color: c.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One option (§3.10): a 50 px gumdrop row, bubblegum when it's my choice,
/// with a radio ring or check, the text, the count and percentage (which
/// shows who chose it), and a thin bar along the bottom filled to its share
/// of voters.
class _OptionRow extends StatelessWidget {
  const new({
    required this.poll,
    required this.option,
    required this.chosen,
    required this.leading,
    required this.onTap,
    required this.onShowVoters,
  });

  final Poll poll;
  final PollOption option;
  final bool chosen;

  /// Ahead once the poll has closed.
  final bool leading;
  final VoidCallback? onTap;

  /// Who chose this option (POLL-3); null on anonymous polls.
  final VoidCallback? onShowVoters;

  static const _height = 50.0;
  static const _radius = BorderRadius.all(Radius.circular(16));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final buttons = GumdropButtons.of(context);
    final share = poll.shareOf(option.id);
    final votes = poll.votesFor(option.id);
    final ink = chosen ? c.ink : c.textPrimary;
    // The content sits 3 px above the lip, leaving room for the bar.
    const padding = EdgeInsets.fromLTRB(10, 0, 14, 3);
    var style = chosen
        ? buttons.accent(
            c.bubblegum,
            height: _height,
            radius: _radius,
            padding: padding,
          )
        : buttons.secondary(height: _height, radius: _radius, padding: padding);
    // Closed (or read-only): the results stay in their colors, at rest,
    // rather than the flat disabled look.
    if (onTap == null && onShowVoters == null) {
      final lip = GumdropShape.lipFor(_height - 4);
      style = style.copyWith(
        backgroundColor: WidgetStatePropertyAll(
          chosen ? c.bubblegum.face : c.raisedFace,
        ),
        foregroundColor: WidgetStatePropertyAll(ink),
        shape: WidgetStatePropertyAll(
          buttons.style.styled(
            GumdropShape(
              lip: lip,
              lipColor: chosen ? c.bubblegum.lip : c.raisedLip,
              highlight: chosen ? 2 : 1.5,
              highlightColor: chosen
                  ? GumdropColors.accentHighlight
                  : c.raisedHighlight,
              radius: _radius,
            ),
          ),
        ),
        side: WidgetStatePropertyAll(
          chosen || c.raisedBorderWidth == 0
              ? BorderSide.none
              : BorderSide(color: c.raisedBorder, width: c.raisedBorderWidth),
        ),
        padding: WidgetStatePropertyAll(
          padding.add(EdgeInsets.only(bottom: lip)),
        ),
      );
    }
    final count = Text(
      '$votes · ${(share * 100).round()}%',
      style: GumdropStyle.of(context).label(
        TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          height: 1,
          color: ink,
        ),
      ),
    );
    final marker = chosen
        ? Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: GumdropColors.inkTint14,
              shape: poll.allowMultiple ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: poll.allowMultiple
                  ? BorderRadius.circular(7)
                  : null,
            ),
            child: Icon(AppIcons.check, size: 17, weight: 800, color: c.ink),
          )
        : Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(color: c.textMuted, width: 2.5),
              shape: poll.allowMultiple ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: poll.allowMultiple
                  ? BorderRadius.circular(7)
                  : null,
            ),
          );
    return Semantics(
      button: onTap != null,
      selected: chosen,
      label: '${option.text}, ${l10n.pollOptionVotes(votes)}',
      // The label replaces the row's own semantics, so it carries the
      // actions too, or screen readers couldn't vote.
      excludeSemantics: true,
      onTap: onTap,
      onLongPress: onShowVoters,
      child: TextButton(
        style: style,
        onPressed: onTap,
        onLongPress: onShowVoters,
        child: SizedBox(
          width: double.infinity,
          height: _height - 7,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Row(
                  children: [
                    marker,
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        option.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontWeight: leading
                              ? FontWeight.w900
                              : FontWeight.w800,
                          fontSize: 16,
                          height: 1.2,
                          color: ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    if (onShowVoters case final show?)
                      // Its own tap target: the count shows who chose
                      // it, the rest of the row votes.
                      Tooltip(
                        message: l10n.pollSeeWhoChose(option.text),
                        child: InkWell(
                          onTap: show,
                          borderRadius: BorderRadius.circular(Corners.chip),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: 40,
                              minWidth: 48,
                            ),
                            child: Center(widthFactor: 1, child: count),
                          ),
                        ),
                      )
                    else
                      count,
                  ],
                ),
              ),
              // The vote bar: from under the text to the end, 5 px tall.
              Positioned(
                left: 34,
                right: 0,
                bottom: 1,
                height: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: ColoredBox(
                    color: chosen ? GumdropColors.inkTint16 : c.well,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FractionallySizedBox(
                        widthFactor: share.clamp(0, 1),
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: chosen ? c.ink : c.bubblegum.face,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
