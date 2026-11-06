import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/focus_ring_ink.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/core/widgets/viewer_zone.dart';
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
    this.mine = false,
    this.bubbleColor,
    super.key,
  });

  /// My bubble's color from the chat look, or null for coral.
  final Color? bubbleColor;

  /// My own poll: drawn inside my coral bubble, in ink (SPEC §7.3).
  final bool mine;

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

  /// The text on my bubble: ink on coral, or ink or white, whichever
  /// reads better, on the chat look's color.
  Color _inkOn(BuildContext context) {
    final c = GumdropColors.of(context);
    final fill = widget.bubbleColor;
    if (fill == null) return c.ink;
    return ColorMath.contrast(c.ink, fill) >=
            ColorMath.contrast(const Color(0xFFFFFFFF), fill)
        ? c.ink
        : const Color(0xFFFFFFFF);
  }

  GroupId get groupId => widget.groupId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final poll = ref.watch(pollProvider(pollId));
    // Others' polls are cards; mine is my coral bubble, with an ink edge on
    // a page close to its color, as my text bubbles have (CHAT-18).
    final page = GumdropColors.of(context);
    final fill = widget.bubbleColor ?? page.you.face;
    Widget frame(Widget child) => ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: widget.mine
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                border: ColorMath.contrast(fill, page.page) < 2
                    ? Border.all(color: page.ink, width: 2)
                    : null,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(Corners.bubble),
                  topRight: Radius.circular(Corners.bubble),
                  bottomLeft: Radius.circular(Corners.bubble),
                  bottomRight: Radius.circular(Corners.bubbleTail),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: child,
              ),
            )
          : GumdropCard(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: child,
            ),
    );
    final value = poll.value;
    if (value == null) {
      return frame(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Builder(
            builder: (context) => poll.isLoading
                ? const LinearProgressIndicator()
                : Text(
                    l10n.pollRemoved,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: widget.mine
                          ? _inkOn(context)
                          : GumdropColors.of(context).textMuted,
                    ),
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
        : l10n.pollClosesAt(
            closesLabel(
              l10n,
              value.closesAt!,
              DateTime.now(),
              zone: ViewerZone.of(context),
            ),
          );

    return frame(
      Builder(
        builder: (context) {
          final c = GumdropColors.of(context);
          final style = GumdropStyle.of(context);
          final ink = widget.mine ? _inkOn(context) : c.textPrimary;
          final rule = widget.mine ? ink.withValues(alpha: 0.22) : c.divider;
          final small = TextStyle(
            fontFamily: AppFonts.body,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: widget.mine ? ink : c.textMuted,
          );
          final link = style.label(
            TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: ink,
              decoration: TextDecoration.underline,
              decorationThickness: 1.5,
              decorationColor: ink,
            ),
          );
          final time = widget.time ?? '';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // The head: POLL, who asked and how, and when.
              Row(
                children: [
                  Icon(AppIcons.poll, size: 16, weight: 700, color: ink),
                  const SizedBox(width: 5),
                  Text(
                    l10n.pollLabel.toUpperCase(),
                    semanticsLabel: l10n.pollLabel,
                    style: style.label(
                      TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 16 / 13,
                        letterSpacing: 13 * 0.08,
                        color: ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      tags.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: small,
                    ),
                  ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(width: Space.sm),
                    Text(time, style: small),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value.question,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  height: 23 / 18,
                  color: ink,
                ),
              ),
              const SizedBox(height: 4),
              for (final option in value.options)
                _OptionRow(
                  poll: value,
                  option: option,
                  chosen: mine.contains(option.id),
                  leading: leaders.contains(option.id),
                  onCoral: widget.mine,
                  bubbleInk: widget.mine ? ink : null,
                  bubbleFill: widget.bubbleColor,
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
              // The footer, on a rule: how many voted, then the links.
              const SizedBox(height: 6),
              Container(height: 1.5, color: rule),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: Space.sm,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        [
                          l10n.pollVoters(value.voterCount),
                          ?status,
                        ].join(' · '),
                        style: small.copyWith(fontSize: 14),
                      ),
                    ),
                    Wrap(
                      spacing: 4,
                      children: [
                        // Even before anyone votes: it lists who hasn't
                        // (POLL-3).
                        if (!value.anonymous)
                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            onPressed: () =>
                                unawaited(_showVoters(context, value)),
                            child: Text(l10n.pollSeeVotes, style: link),
                          ),
                        if (canClose)
                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            onPressed: () =>
                                unawaited(_close(context, ref, value)),
                            child: Text(l10n.pollClose, style: link),
                          ),
                      ],
                    ),
                  ],
                ),
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
/// "Fri, Oct 23 5:00 PM" further out; in the viewer's [zone] (SET-7).
String closesLabel(
  AppLocalizations l10n,
  DateTime at,
  DateTime now, {
  String? zone,
}) {
  final local = wallClockIn(zone, at);
  final wallNow = wallClockIn(zone, now);
  // UTC dates, so a day that's 23 hours long here still counts as one.
  final today = DateTime.utc(wallNow.year, wallNow.month, wallNow.day);
  final day = DateTime.utc(local.year, local.month, local.day);
  final days = day.difference(today).inDays;
  final format = days == 0
      ? DateFormat.jm(l10n.localeName)
      : days > 0 && days < 7
      ? DateFormat.E(l10n.localeName).add_jm()
      : DateFormat.MMMEd(l10n.localeName).add_jm();
  return format.format(local);
}

/// One option (SPEC §7.3): an 18 px ring (filled, with a check, for my
/// choice), the text, the votes and share on the right (which show who
/// chose it), and a 6 px bar under it filled to its share of voters. On my
/// coral bubble ([onCoral]) it's all in ink.
class _OptionRow extends StatelessWidget {
  const new({
    required this.poll,
    required this.option,
    required this.chosen,
    required this.leading,
    required this.onTap,
    required this.onShowVoters,
    this.onCoral = false,
    this.bubbleInk,
    this.bubbleFill,
  });

  /// On my bubble: its text color, and its fill (null for coral).
  final Color? bubbleInk;
  final Color? bubbleFill;

  final Poll poll;
  final PollOption option;
  final bool chosen;

  /// Ahead once the poll has closed.
  final bool leading;
  final bool onCoral;
  final VoidCallback? onTap;

  /// Who chose this option (POLL-3); null on anonymous polls.
  final VoidCallback? onShowVoters;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final share = poll.shareOf(option.id);
    final votes = poll.votesFor(option.id);
    final ink = onCoral ? bubbleInk ?? c.ink : c.textPrimary;
    final track = onCoral ? ink.withValues(alpha: 0.18) : c.cardTrack;
    final fill = onCoral ? ink : c.mint.face;
    final shape = poll.allowMultiple ? BoxShape.rectangle : BoxShape.circle;
    final radius = poll.allowMultiple ? BorderRadius.circular(5) : null;
    final marker = Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: chosen ? ink : null,
        border: Border.all(color: ink, width: 2),
        shape: shape,
        borderRadius: radius,
      ),
      child: chosen
          ? Icon(
              AppIcons.check,
              size: 13,
              weight: 800,
              color: onCoral ? bubbleFill ?? c.you.face : c.surface,
            )
          : null,
    );
    final count = Text(
      l10n.pollOptionVotesShare(votes, (share * 100).round()),
      style: TextStyle(
        fontFamily: AppFonts.body,
        fontWeight: FontWeight.w700,
        fontSize: 14,
        height: 22 / 14,
        color: ink,
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
      child: FocusRingInk(
        onTap: onTap,
        radius: BorderRadius.circular(8),
        child: GestureDetector(
          onLongPress: onShowVoters,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The count at its own width, so the option's text has
                  // the rest of the row; never over half of it, so big text
                  // wraps the count rather than overflowing.
                  LayoutBuilder(
                    builder: (context, box) {
                      final countBox = BoxConstraints(
                        maxWidth: (box.maxWidth / 2).clamp(
                          48.0,
                          double.infinity,
                        ),
                      );
                      return Row(
                        children: [
                          marker,
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              option.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontWeight: chosen || leading
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                fontSize: 16,
                                height: 22 / 16,
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
                                borderRadius: BorderRadius.circular(
                                  Corners.chip,
                                ),
                                child: ConstrainedBox(
                                  constraints: countBox.copyWith(
                                    minHeight: 36,
                                    minWidth: 48,
                                  ),
                                  child: Center(widthFactor: 1, child: count),
                                ),
                              ),
                            )
                          else
                            ConstrainedBox(constraints: countBox, child: count),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 26),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: 6,
                        child: ColoredBox(
                          color: track,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: FractionallySizedBox(
                              widthFactor: share.clamp(0, 1),
                              heightFactor: 1,
                              child: ColoredBox(color: fill),
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
        ),
      ),
    );
  }
}
