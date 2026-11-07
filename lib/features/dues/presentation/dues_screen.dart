import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/card_dialog.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/focus_ring_ink.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/dues/application/providers.dart';
import 'package:battleplan/features/dues/domain/due.dart';
import 'package:battleplan/features/dues/presentation/dues_widgets.dart';
import 'package:battleplan/features/dues/presentation/share_sheet.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// "Nov 30" for a due date stored as "2026-11-30".
String _dueDate(AppLocalizations l10n, String dueOn) => duesDay(l10n, dueOn);

/// Who a due can be for on [group] (DUES-1): every active player on a team,
/// every member who has joined a group. The list is null until it has loaded;
/// failed is true when its read failed.
({List<DuePayer>? list, bool failed}) _everyone(WidgetRef ref, Group group) {
  if (group.hasPlayers) {
    final players = ref.watch(playersProvider(group.id));
    return (
      list: players.value == null
          ? null
          : [
              for (final p in players.value!)
                if (!p.isPending)
                  (type: ParticipantType.player, id: p.id.value, name: p.label),
            ],
      failed: players.hasError,
    );
  }
  final roster = ref.watch(rosterProvider(group.id));
  return (
    list: roster.value == null
        ? null
        : [
            for (final m in roster.value!)
              if (!m.pending)
                (
                  type: ParticipantType.member,
                  id: m.uid.value,
                  name: m.displayName,
                ),
          ],
    failed: roster.hasError,
  );
}

/// Dues at `/g/:groupId/dues` (DUES-1 to DUES-3). Admins see every due with
/// how many have paid and what's still owed, and add new ones; everyone
/// else sees only what they, or their players, owe. Under it, how to pay
/// the team: Venmo, Cash App or Apple Cash handles the admins or coaches
/// share. No money goes through Battleplan.
class DuesScreen extends ConsumerWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final group = ref.watch(groupProvider(groupId)).value;
    final admin = isDuesAdmin(ref, groupId);
    final isGroup = group?.isGroup ?? false;
    final archived = group?.isArchived ?? false;
    // Coaches share how to pay too (DUES-3, TEAM-3); dues stay the admins'.
    final coach =
        (group?.hasPlayers ?? false) &&
        (ref.watch(myMembershipProvider(groupId))?.isCoach ?? false);
    final lede = TextStyle(
      fontFamily: AppFonts.body,
      fontWeight: FontWeight.w600,
      fontSize: 15,
      height: 21 / 15,
      color: c.textMutedOnPage,
    );

    return Scaffold(
      appBar: gumdropAppBar(
        context,
        title: l10n.duesTitle,
        backLabel: backLabelFrom(
          context,
          isGroup ? l10n.groupInfo : l10n.teamInfo,
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
            children: [
              Text(isGroup ? l10n.duesGroupLede : l10n.duesLede, style: lede),
              const SizedBox(height: 18),
              if (admin)
                _AdminDues(groupId: groupId, archived: archived)
              else
                _MyDues(groupId: groupId),
              const SizedBox(height: 24),
              _HowToPay(
                groupId: groupId,
                isGroup: isGroup,
                canEdit: (admin || coach) && group != null && !archived,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The admins' list (DUES-1, DUES-5): what's owed in all, paid, and left
/// across every due, with Who owes what a tap away, then each due with how
/// many have paid.
class _AdminDues extends ConsumerWidget {
  const new({required this.groupId, required this.archived});

  final GroupId groupId;

  /// Read-only (TEAM-9): no New due.
  final bool archived;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dues = ref.watch(teamDuesProvider(groupId));
    final list = dues.value;
    final all = ref.watch(teamChargesProvider(groupId)).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Once every due's shares have loaded, so it's never short.
        if (all != null && (list?.isNotEmpty ?? false)) ...[
          DuesTotalsPanel(
            totals: dueTotals(all),
            onWhoOwesWhat: () =>
                unawaited(context.push('/g/${groupId.value}/dues/people')),
          ),
          const SizedBox(height: 16),
        ],
        if (!archived)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: () =>
                  unawaited(context.push('/g/${groupId.value}/dues/new')),
              icon: const Icon(AppIcons.add),
              label: Text(l10n.duesNew),
            ),
          ),
        const SizedBox(height: 16),
        if (list == null && dues.hasError)
          const DuesLoadError()
        else if (list == null)
          const SkeletonList()
        else if (list.isEmpty)
          DuesQuiet(archived ? l10n.duesEmptyArchived : l10n.duesEmptyAdmin)
        else
          for (final due in list) ...[
            _DueCard(
              due: due,
              onTap: () =>
                  unawaited(context.push('/g/${groupId.value}/dues/${due.id}')),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

/// A due for the admins: what it's for and how much, when it's due, and
/// "4 of 12 paid · 1 partly paid · $90 left" from its own charges, with a
/// bar for how much of it is paid.
class _DueCard extends ConsumerWidget {
  const new({required this.due, required this.onTap});

  final Due due;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final charges = ref.watch(dueChargesProvider(due.groupId, due.id));
    final loaded = charges.value;
    final totals = dueTotals(loaded ?? const <DueCharge>[]);
    return SettingsPanel(
      padding: EdgeInsets.zero,
      child: Builder(
        builder: (context) {
          final c = GumdropColors.of(context);
          final summary = _summary(l10n, totals);
          final card = FocusRingInk(
            onTap: onTap,
            radius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TitleLine(
                          title: due.title,
                          amount: formatDues(l10n, due.amountCents),
                        ),
                        if (due.dueOn case final on?)
                          Text(
                            dueDateLine(l10n, on, owed: totals.owedCents > 0),
                            style: duesMuted(c),
                          ),
                        const SizedBox(height: 6),
                        if (loaded == null)
                          Text(
                            charges.hasError ? l10n.loadError : '',
                            style: duesMuted(c).copyWith(fontSize: 14),
                          )
                        else
                          Row(
                            children: [
                              DuesBar(
                                fraction: totals.chargedCents == 0
                                    ? 0
                                    : totals.paidCents / totals.chargedCents,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  summary,
                                  style: duesMuted(c).copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    AppIcons.chevronRight,
                    size: 20,
                    weight: 700,
                    color: c.textMuted,
                  ),
                ],
              ),
            ),
          );
          // One button that reads the whole card, as a row does.
          return MergeSemantics(child: Semantics(button: true, child: card));
        },
      ),
    );
  }
}

/// A due's shares in a line (DUES-2): "4 of 12 paid · 1 partly paid · $90
/// left", or "All waived".
String _summary(AppLocalizations l10n, DueTotals totals) => totals.count == 0
    ? l10n.duesAllWaived
    : [
        l10n.duesPaidOf(totals.paid, totals.count),
        if (totals.partly > 0) l10n.duesPartlyCount(totals.partly),
        if (totals.owedCents > 0)
          l10n.duesLeft(formatDues(l10n, totals.owedCents)),
      ].join(' · ');

/// The title in Nunito 800 18 with the amount on the right, or under it
/// when the two don't fit side by side without breaking a word (large
/// text, SPEC §7.6).
class _TitleLine extends StatelessWidget {
  const new({required this.title, required this.amount});

  final String title;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    final style = TextStyle(
      fontFamily: AppFonts.body,
      fontWeight: FontWeight.w800,
      fontSize: 18,
      height: 22 / 18,
      color: c.textPrimary,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        double width(String text, {bool word = false}) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          final w = word ? painter.minIntrinsicWidth : painter.width;
          painter.dispose();
          return w;
        }

        final side =
            width(title, word: true) + 10 + width(amount) <=
            constraints.maxWidth;
        if (!side) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: style),
              Text(amount, style: style),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(title, style: style)),
            const SizedBox(width: 10),
            Text(amount, style: style),
          ],
        );
      },
    );
  }
}

/// What I owe (DUES-2): my own share, or each of my players', with what's
/// still owed in all; a share with payments opens to show them. On a
/// team, someone not linked to a player yet is pointed to "Who are you
/// here for?" (PLAYER-3), or told their claim waits, rather than told they
/// owe nothing.
class _MyDues extends ConsumerWidget {
  const new({required this.groupId});

  final GroupId groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final mine = ref.watch(myChargesProvider(groupId));
    final payers = ref.watch(myPayersProvider(groupId)).value ?? const [];
    final group = ref.watch(groupProvider(groupId)).value;
    final list = mine.value;
    if (list == null) {
      return mine.hasError ? const DuesLoadError() : const SkeletonList();
    }
    final owed = list.fold(0, (sum, x) => sum + x.owedCents);
    // "For Emma" once the shares are for more than one person.
    final several =
        {for (final x in list) '${x.participantType.value}/${x.participantId}'}
            .length >
        1;
    // What's still owed first, soonest due first.
    final sorted = [...list]
      ..sort((a, b) {
        final byStatus = (a.owedCents == 0 ? 1 : 0).compareTo(
          b.owedCents == 0 ? 1 : 0,
        );
        return byStatus != 0
            ? byStatus
            : (a.dueOn ?? '~').compareTo(b.dueOn ?? '~');
      });

    // On a team with players, linked to none of them: as on an event
    // (PLAYER-3, PLAYER-6).
    final uid = ref.watch(authUserProvider).value?.uid;
    final unlinked =
        (group?.hasPlayers ?? false) &&
        !payers.any((p) => p.type == ParticipantType.player);
    final waiting =
        unlinked &&
        ((ref.watch(myPendingPlayersProvider(groupId)).value ??
                    const <Player>[])
                .any((p) => p.proposedBy == uid) ||
            (ref.watch(myGuardianRequestsProvider(groupId)).value ??
                    const <GuardianRequest>[])
                .any((r) => r.status == GuardianRequestStatus.pending));
    final pointToWho =
        unlinked &&
        !waiting &&
        (ref.watch(playersProvider(groupId)).value ?? const <Player>[]).any(
          (p) => !p.isPending,
        );
    final muted = TextStyle(
      fontFamily: AppFonts.body,
      fontWeight: FontWeight.w600,
      fontSize: 15,
      color: c.textMutedOnPage,
    );
    final pointer = waiting
        ? DuesQuiet(l10n.claimWaiting)
        : pointToWho
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(l10n.duesPlayersOnly, style: muted),
                if (!(group?.isArchived ?? false))
                  TextButton(
                    onPressed: () =>
                        unawaited(context.push('/g/${groupId.value}/who')),
                    child: Text(l10n.whoAreYouHereFor),
                  ),
              ],
            ),
          )
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeading(l10n.duesYours),
        const SizedBox(height: 4),
        if (list.isEmpty && pointer != null)
          pointer
        else
          DuesQuiet(
            owed > 0
                ? l10n.duesTotalOwed(formatDues(l10n, owed))
                // Only waived shares, or none: nothing to thank them for.
                : list.any((x) => x.paid)
                ? l10n.duesAllPaid
                : l10n.duesEmptyMember,
          ),
        if (list.isNotEmpty) ...[
          PageRows(
            children: [
              for (final x in sorted)
                _ChargeRow(
                  charge: x,
                  showName: several,
                  // Its payments, to see: each one's amount, day, who
                  // recorded it, and note (DUES-2).
                  onTap: x.payments.isEmpty
                      ? null
                      : () => unawaited(
                          openShareSheet(
                            context,
                            ref,
                            x,
                            canEdit: false,
                            mine: true,
                            showName: several,
                          ),
                        ),
                ),
            ],
          ),
          ?pointer,
        ],
      ],
    );
  }
}

/// One share, on the page (DUES-2): what it's for (and for whom), where it
/// stands ("$20 of $45 paid · $25 left"), when it's due, the due's note,
/// and a pill saying Owes, Partly paid, Paid, or Waived. Screen readers
/// hear one sentence: "Uniform fee, for Luke #7, $25 left of $45". Admins
/// tap it to record a payment; whoever owes it, to see its payments.
class _ChargeRow extends StatelessWidget {
  const new({
    required this.charge,
    this.showName = true,
    this.admin = false,
    this.onTap,
  });

  final DueCharge charge;
  final bool showName;

  /// On the due's own screen: named by whose share it is, which [onTap]
  /// changes (null on an archived team).
  final bool admin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final mine = !admin;
    final owed = charge.owedCents > 0;
    final dueLine = charge.dueOn != null && owed
        ? dueDateLine(l10n, charge.dueOn!, owed: true)
        : null;
    final sub = [
      [
        if (showName && mine) l10n.duesFor(charge.participantName),
        shareLine(l10n, charge),
        ?dueLine,
      ].join(' · '),
      // Admins read the note once, at the top of the due.
      if (mine && charge.note.isNotEmpty) charge.note,
    ].join('\n');
    final spoken = [
      if (mine) charge.title,
      if (mine && showName) l10n.duesFor(charge.participantName),
      if (!mine) charge.participantName,
      shareSpoken(l10n, charge),
      ?dueLine,
      if (mine && charge.note.isNotEmpty) charge.note,
    ].join(', ');
    return PageRow(
      title: mine ? charge.title : charge.participantName,
      subtitle: sub,
      // Never cut off: the amount and date are what it's for (SPEC §7.6).
      subtitleMaxLines: null,
      onTap: onTap,
      semanticsLabel: spoken,
      trailing: DueStatePill(state: charge.state),
      leading: Icon(
        charge.paid ? AppIcons.going : AppIcons.payments,
        size: 22,
        color: charge.paid ? c.successOnPage : c.textOnPage,
      ),
    );
  }
}

/// How to pay the team (DUES-3): each handle with Copy, and on the web and
/// Android an Open link. The iPhone app copies only: these are payments
/// between people, outside the app. Who saved it last shows under it.
class _HowToPay extends ConsumerWidget {
  const new({
    required this.groupId,
    required this.isGroup,
    required this.canEdit,
  });

  final GroupId groupId;
  final bool isGroup;

  /// Admins, or a team's coaches, on a team that isn't archived.
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final async = ref.watch(duesPaymentsProvider(groupId));
    final pay = async.value;
    // The iPhone app only copies, as a precaution (DUES-3, SPEC §4.2); the
    // store checklist's Store payment rules say why Apple would allow Open.
    final links = kIsWeb || defaultTargetPlatform != TargetPlatform.iOS;
    Widget row(String app, String shown, Uri? link) => PageRow(
      title: app,
      subtitle: shown,
      // The handle is what people pay to: never cut off (SPEC §7.6).
      subtitleMaxLines: null,
      icon: AppIcons.payments,
      // Copy and Open are buttons of their own for screen readers.
      trailingActions: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.duesCopy(app),
            icon: const Icon(AppIcons.copy, size: 22),
            onPressed: () {
              unawaited(Clipboard.setData(ClipboardData(text: shown)));
              showAppSnackBar(context, l10n.duesCopied);
            },
          ),
          if (links && link != null)
            IconButton(
              tooltip: l10n.duesOpen(app),
              icon: const Icon(AppIcons.openInNew, size: 22),
              onPressed: () =>
                  unawaited(ref.read(linkOpenerProvider).open(link)),
            ),
        ],
      ),
    );
    final venmo = venmoUser(pay?.venmo ?? '');
    final cash = cashTag(pay?.cashApp ?? '');
    final apple = pay?.appleCash.trim() ?? '';
    // Who saved it last, from the roster: "a former member" once they've
    // left (or deleted their account, which removes what they saved).
    final by = pay == null || pay.isEmpty || pay.updatedBy.isEmpty
        ? null
        : ref.watch(memberProvider(groupId, UserId(pay.updatedBy)));
    final byName = by == null || !by.hasValue
        ? null
        : by.value == null
        ? l10n.duesPaymentsUpdatedByFormer
        : l10n.duesPaymentsUpdatedBy(by.value!.displayName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The button goes under the heading when both don't fit.
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          spacing: 8,
          children: [
            PageHeading(l10n.duesHowToPay),
            // Only once it has loaded, so saving never empties what's there.
            if (canEdit && pay != null)
              TextButton.icon(
                onPressed: () => unawaited(_edit(context, ref, pay)),
                icon: const Icon(AppIcons.edit, size: 18),
                label: Text(l10n.duesEditPayments),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (pay == null && async.hasError)
          const DuesLoadError()
        else if (pay == null)
          const SkeletonList(rows: 1)
        else if (pay.isEmpty)
          DuesQuiet(
            canEdit ? l10n.duesHowToPayEmptyEditor : l10n.duesHowToPayEmpty,
          )
        else ...[
          PageRows(
            children: [
              if (venmo.isNotEmpty)
                row(
                  l10n.duesVenmo,
                  '@$venmo',
                  Uri.https('venmo.com', '/u/$venmo'),
                ),
              if (cash.isNotEmpty)
                row(
                  l10n.duesCashApp,
                  '\$$cash',
                  Uri.https('cash.app', '/\$$cash'),
                ),
              if (apple.isNotEmpty) row(l10n.duesAppleCash, apple, null),
            ],
          ),
          if (pay.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              pay.note,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: c.textOnPage,
              ),
            ),
          ],
          if (byName != null) DuesQuiet(byName),
        ],
        const SizedBox(height: 8),
        DuesQuiet(isGroup ? l10n.duesGroupHowToPayNote : l10n.duesHowToPayNote),
      ],
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    DuesPayments p,
  ) async {
    final l10n = AppLocalizations.of(context);
    final next = await showCardDialog<DuesPayments>(
      context: context,
      builder: (_) => _PaymentsDialog(initial: p, isGroup: isGroup),
    );
    if (next == null || !context.mounted) return;
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid == null) return;
    try {
      await ref
          .read(duesRepositoryProvider)
          .savePayments(groupId, next, by: UserId(uid));
    } on AppFailure {
      if (context.mounted) showAppSnackBar(context, l10n.duesSaveFailed);
    }
  }
}

class _PaymentsDialog extends StatefulWidget {
  const new({required this.initial, required this.isGroup});

  final DuesPayments initial;
  final bool isGroup;

  @override
  State<_PaymentsDialog> createState() => _PaymentsDialogState();
}

class _PaymentsDialogState extends State<_PaymentsDialog> {
  late final _venmo = TextEditingController(text: widget.initial.venmo);
  late final _cash = TextEditingController(text: widget.initial.cashApp);
  late final _apple = TextEditingController(text: widget.initial.appleCash);
  late final _note = TextEditingController(text: widget.initial.note);

  @override
  void dispose() {
    _venmo.dispose();
    _cash.dispose();
    _apple.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget field(
      String label,
      TextEditingController controller,
      String hint, {
      int max = Limits.duePayHandleMax,
      int lines = 1,
      bool handle = true,
      TextInputType? keyboard,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LabeledField(
        label: label,
        child: TextField(
          controller: controller,
          maxLength: max,
          minLines: 1,
          maxLines: lines,
          // A handle is typed exactly: no corrections or capitals.
          autocorrect: !handle,
          enableSuggestions: !handle,
          keyboardType: keyboard,
          style: gumdropFieldText(context),
          decoration: gumdropField(hint: hint),
        ),
      ),
    );
    return AlertDialog(
      title: Text(l10n.duesEditPayments),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            field(l10n.duesVenmo, _venmo, l10n.duesVenmoHint),
            field(l10n.duesCashApp, _cash, l10n.duesCashAppHint),
            field(
              l10n.duesAppleCash,
              _apple,
              l10n.duesAppleCashHint,
              keyboard: TextInputType.emailAddress,
            ),
            field(
              l10n.duesPayNote,
              _note,
              widget.isGroup ? l10n.duesGroupPayNoteHint : l10n.duesPayNoteHint,
              max: Limits.dueNoteMax,
              lines: 3,
              handle: false,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            // A pasted profile link is saved as the handle it names.
            final venmo = venmoUser(_venmo.text);
            final cash = cashTag(_cash.text);
            Navigator.of(context).pop(
              DuesPayments(
                venmo: venmo.isEmpty ? '' : '@$venmo',
                cashApp: cash.isEmpty ? '' : '\$$cash',
                appleCash: _apple.text.trim(),
                note: _note.text.trim(),
              ),
            );
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// One due at `/g/:groupId/dues/:dueId` (admins, DUES-2): what's owed in
/// all, paid, and left, then everyone's share, who owes most first, each
/// with what they've paid and what's left. A tap opens the share: record a
/// payment, or all that's left, waive it, or take back a payment. Admins add
/// people a due left out, such as a player who joined later.
class DueDetailScreen extends ConsumerWidget {
  const new({required this.groupId, required this.dueId, super.key});

  final GroupId groupId;
  final String dueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final duesAsync = ref.watch(teamDuesProvider(groupId));
    final dues = duesAsync.value;
    final due = dues?.where((d) => d.id == dueId).firstOrNull;
    final chargesAsync = ref.watch(dueChargesProvider(groupId, dueId));
    // Who owes most first, then who paid, then who's waived; by name.
    final charges = [...?chargesAsync.value]..sort(compareShares);
    final group = ref.watch(groupProvider(groupId)).value;
    final archived = group?.isArchived ?? false;
    final canEdit = isDuesAdmin(ref, groupId) && !archived;
    final totals = dueTotals(charges);
    return Scaffold(
      appBar: gumdropAppBar(
        context,
        title: due?.title ?? l10n.duesTitle,
        // Dues, or Who owes what when opened from there.
        backLabel: backLabelFrom(context, l10n.duesTitle),
        actions: [
          if (due != null && canEdit)
            PopupMenuButton<String>(
              tooltip: l10n.eventMoreActions,
              onSelected: (v) => v == 'edit'
                  ? unawaited(
                      context.push('/g/${groupId.value}/dues/$dueId/edit'),
                    )
                  : unawaited(_delete(context, ref, due)),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(l10n.duesEdit)),
                PopupMenuItem(value: 'delete', child: Text(l10n.duesDelete)),
              ],
            ),
        ],
      ),
      body: dues == null
          ? (duesAsync.hasError ? const DuesLoadError() : const SkeletonList())
          : due == null
          ? Center(child: DuesQuiet(l10n.duesNotFound))
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
                  children: [
                    // The bar's title is one line: a long one in full here.
                    if (_titleCut(context, due.title))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          due.title,
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            height: 22 / 18,
                            color: c.textOnPage,
                          ),
                        ),
                      ),
                    Text(
                      [
                        formatDues(l10n, due.amountCents),
                        if (due.dueOn case final on?)
                          dueDateLine(l10n, on, owed: totals.owedCents > 0),
                      ].join(' · '),
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: c.textOnPage,
                      ),
                    ),
                    if (due.note.isNotEmpty) DuesQuiet(due.note),
                    const SizedBox(height: 6),
                    if (chargesAsync.value == null && chargesAsync.hasError)
                      const DuesLoadError()
                    else if (chargesAsync.value == null)
                      const SkeletonList()
                    else ...[
                      const SizedBox(height: 6),
                      DuesTotalsPanel(totals: totals),
                      DuesQuiet(_summary(l10n, totals)),
                      PageRows(
                        children: [
                          for (final x in charges)
                            _ChargeRow(
                              charge: x,
                              admin: true,
                              // On an archived team, only to see payments.
                              onTap: canEdit || x.payments.isNotEmpty
                                  ? () => unawaited(
                                      openShareSheet(
                                        context,
                                        ref,
                                        x,
                                        canEdit: canEdit,
                                      ),
                                    )
                                  : null,
                            ),
                        ],
                      ),
                      if (canEdit && group != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            onPressed: () => unawaited(
                              _addPeople(context, ref, due, group, charges),
                            ),
                            icon: const Icon(AppIcons.invite, size: 20),
                            label: Text(l10n.duesAddPeople),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  /// Whether [title] is cut short in the bar's one-line title.
  static bool _titleCut(BuildContext context, String title) {
    final painter = TextPainter(
      text: TextSpan(
        text: title,
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(fontSize: 32, height: 36 / 32),
      ),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: MediaQuery.sizeOf(context).width - 40);
    final cut = painter.didExceedMaxLines;
    painter.dispose();
    return cut;
  }

  /// Adds people [due] left out (DUES-1): each starts owing it.
  Future<void> _addPeople(
    BuildContext context,
    WidgetRef ref,
    Due due,
    Group group,
    List<DueCharge> charges,
  ) async {
    final l10n = AppLocalizations.of(context);
    final onIt = {for (final x in charges) x.participantId};
    final picked = await showCardDialog<List<DuePayer>>(
      context: context,
      builder: (_) => _AddPeopleDialog(group: group, onIt: onIt),
    );
    if (picked == null || picked.isEmpty || !context.mounted) return;
    if (onIt.length + picked.length > Limits.duesChargesMax) {
      showAppSnackBar(context, l10n.duesTooManyPayers(Limits.duesChargesMax));
      return;
    }
    try {
      await ref
          .read(duesRepositoryProvider)
          .edit(
            due,
            title: due.title,
            amountCents: due.amountCents,
            dueOn: due.dueOn,
            note: due.note,
            add: picked,
          );
    } on AppFailure {
      if (context.mounted) showAppSnackBar(context, l10n.duesSaveFailed);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Due due) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.duesDeleteTitle,
      message: l10n.duesDeleteBody,
      confirmLabel: l10n.duesDelete,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(duesRepositoryProvider).remove(due);
      if (context.mounted) context.pop();
    } on AppFailure {
      if (context.mounted) showAppSnackBar(context, l10n.duesSaveFailed);
    }
  }
}

/// Who a due could still add (DUES-1): everyone who can owe one and isn't
/// on it, none checked to start. Returns who was checked.
class _AddPeopleDialog extends ConsumerStatefulWidget {
  const new({required this.group, required this.onIt});

  final Group group;

  /// The participant IDs already on the due.
  final Set<String> onIt;

  @override
  ConsumerState<_AddPeopleDialog> createState() => _AddPeopleDialogState();
}

class _AddPeopleDialogState extends ConsumerState<_AddPeopleDialog> {
  final Set<String> _picked = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final everyone = _everyone(ref, widget.group);
    final others = [
      for (final p in everyone.list ?? const <DuePayer>[])
        if (!widget.onIt.contains(p.id)) p,
    ];
    final loaded = everyone.list != null;
    return AlertDialog(
      title: Text(l10n.duesAddPeople),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: !loaded
              ? (everyone.failed
                    ? const DuesLoadError()
                    : const SizedBox(height: 48))
              : others.isEmpty
              ? Text(l10n.duesAddNone)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final p in others)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _picked.contains(p.id),
                        title: Text(p.name),
                        onChanged: (on) => setState(
                          () => on ?? false
                              ? _picked.add(p.id)
                              : _picked.remove(p.id),
                        ),
                      ),
                  ],
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loaded && others.isEmpty ? l10n.done : l10n.cancel),
        ),
        if (others.isNotEmpty)
          FilledButton(
            onPressed: _picked.isEmpty
                ? null
                : () => Navigator.of(context).pop([
                    for (final p in others)
                      if (_picked.contains(p.id)) p,
                  ]),
            child: Text(l10n.add),
          ),
      ],
    );
  }
}

/// A new due at `/g/:groupId/dues/new`, or a due's edit (admins, DUES-1):
/// what it's for, the amount, a date, a note everyone on it sees, and,
/// when new, who owes it: every active player on a team, or every member
/// of a group, with any left out by unchecking.
class NewDueScreen extends ConsumerStatefulWidget {
  const new({required this.groupId, this.dueId, super.key});

  final GroupId groupId;

  /// The due being edited, or null for a new one.
  final String? dueId;

  @override
  ConsumerState<NewDueScreen> createState() => _NewDueScreenState();
}

class _NewDueScreenState extends ConsumerState<NewDueScreen> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  /// One per new due, the same on every try, so trying again after a lost
  /// reply never adds it twice (DUES-1).
  final String _requestId = newRequestId();
  String? _dueOn;
  final Set<String> _left = {};
  bool _loaded = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  /// The amount in cents, or null when it isn't one.
  int? get _cents => parseDollars(_amount.text);

  bool get _isEdit => widget.dueId != null;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_dueOn ?? '') ?? now;
    // A due from an older season still opens on its own date.
    final first = DateTime(now.year - 1);
    final last = DateTime(now.year + 3);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: initial.isBefore(first) ? initial : first,
      lastDate: initial.isAfter(last) ? initial : last,
    );
    if (picked == null) return;
    setState(
      () => _dueOn =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}',
    );
  }

  Future<void> _save(
    Group group,
    Due? editing,
    List<DuePayer> everyone,
    List<DueCharge> charges,
  ) async {
    final l10n = AppLocalizations.of(context);
    // Editing needs the due; never fall back to adding a new one.
    if (_isEdit && editing == null) return;
    final cents = _cents;
    final payers = [
      for (final p in everyone)
        if (!_left.contains(p.id)) p,
    ];
    final error = _title.text.trim().isEmpty
        ? l10n.duesTitleRequired
        : cents == null
        ? l10n.duesAmountInvalid
        : !_isEdit && payers.isEmpty
        ? l10n.duesPickSomeone
        : !_isEdit && payers.length > Limits.duesChargesMax
        ? l10n.duesTooManyPayers(Limits.duesChargesMax)
        : null;
    setState(() => _error = error);
    if (error != null || cents == null) return;
    if (editing != null && cents != editing.amountCents) {
      // Never below what someone already paid (DUES-1, DUES-2).
      final most = charges.isEmpty
          ? null
          : charges.reduce((a, b) => b.paidCents > a.paidCents ? b : a);
      if (most != null && most.paidCents > cents) {
        final name = most.participantName;
        final paid = formatDues(l10n, most.paidCents);
        setState(
          () => _error = most.recordsPayments
              ? l10n.duesAmountBelowPaid(name, paid)
              // Marked paid before payments were recorded: no payment to
              // undo, so it's marked not paid.
              : l10n.duesAmountBelowMarkedPaid(name, paid),
        );
        return;
      }
      // What people paid stays, and they owe the rest: say so first.
      final paid = charges.where((x) => x.paidCents > 0).length;
      if (paid > 0) {
        final ok = await showConfirmDialog(
          context,
          title: l10n.duesAmountChangedTitle,
          message: l10n.duesAmountChangedBody(paid, formatDues(l10n, cents)),
          confirmLabel: l10n.save,
          cancelLabel: l10n.cancel,
        );
        if (!ok || !mounted) return;
      }
    }
    setState(() => _saving = true);
    final repo = ref.read(duesRepositoryProvider);
    try {
      if (editing != null) {
        await repo.edit(
          editing,
          title: _title.text,
          amountCents: cents,
          dueOn: _dueOn,
          note: _note.text,
        );
      } else {
        await repo.create(
          group.id,
          title: _title.text,
          amountCents: cents,
          dueOn: _dueOn,
          note: _note.text,
          payers: payers,
          requestId: _requestId,
        );
      }
      if (mounted) context.pop();
    } on InvalidInput catch (e) {
      // A payment recorded since this screen loaded.
      if (e.message == 'due-amount-below-paid' && mounted) {
        setState(() => _error = l10n.duesAmountBelowPaidAny);
      } else if (mounted) {
        showAppSnackBar(context, l10n.duesSaveFailed);
      }
    } on AppFailure {
      if (mounted) showAppSnackBar(context, l10n.duesSaveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final group = ref.watch(groupProvider(widget.groupId)).value;
    final duesAsync = _isEdit
        ? ref.watch(teamDuesProvider(widget.groupId))
        : null;
    final editing = duesAsync?.value
        ?.where((d) => d.id == widget.dueId)
        .firstOrNull;
    // Who has paid, and how much, for the warning when the amount changes.
    final charges = _isEdit
        ? ref.watch(dueChargesProvider(widget.groupId, widget.dueId!)).value ??
              const <DueCharge>[]
        : const <DueCharge>[];
    if (editing != null && !_loaded) {
      _loaded = true;
      _title.text = editing.title;
      _amount.text = (editing.amountCents / 100).toStringAsFixed(
        editing.amountCents % 100 == 0 ? 0 : 2,
      );
      _note.text = editing.note;
      _dueOn = editing.dueOn;
    }
    // Edit goes back to the due it came from; New due to Dues.
    final back = _isEdit ? editing?.title : l10n.duesTitle;
    if (group == null || (_isEdit && editing == null)) {
      // On the edit route, nothing to save until the due loads: a list
      // that failed, or a due that's gone, says so.
      final body = duesAsync == null || !duesAsync.hasValue
          ? (duesAsync?.hasError ?? false)
                ? const DuesLoadError()
                : const SkeletonList()
          : group == null
          ? const SkeletonList()
          : Center(child: DuesQuiet(l10n.duesNotFound));
      return Scaffold(
        appBar: gumdropAppBar(
          context,
          title: _isEdit ? l10n.duesEdit : l10n.duesNew,
          backLabel: back,
        ),
        body: body,
      );
    }
    // Who it can be for, on a new due: nothing to save until it's known.
    final everyoneAsync = _isEdit ? null : _everyone(ref, group);
    final everyone = everyoneAsync?.list;
    return Scaffold(
      appBar: gumdropAppBar(
        context,
        title: _isEdit ? l10n.duesEdit : l10n.duesNew,
        backLabel: back,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
            children: [
              LabeledField(
                label: l10n.duesFieldTitle,
                child: TextField(
                  controller: _title,
                  maxLength: Limits.dueTitleMax,
                  textCapitalization: TextCapitalization.sentences,
                  style: gumdropFieldText(context),
                  decoration: gumdropField(hint: l10n.duesFieldTitleHint),
                ),
              ),
              const SizedBox(height: 8),
              LabeledField(
                label: l10n.duesFieldAmount,
                child: TextField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,$]')),
                  ],
                  style: gumdropFieldText(context),
                  decoration: gumdropField(hint: l10n.duesFieldAmountHint),
                ),
              ),
              const SizedBox(height: 12),
              PageRows(
                children: [
                  PageRow(
                    icon: AppIcons.schedule,
                    title: l10n.duesFieldDueOn,
                    subtitle: _dueOn == null
                        ? l10n.duesNoDate
                        : _dueDate(l10n, _dueOn!),
                    onTap: () => unawaited(_pickDate()),
                    // Clear date is a button of its own for screen readers.
                    trailingActions: true,
                    trailing: _dueOn == null
                        ? null
                        : IconButton(
                            tooltip: l10n.duesClearDate,
                            icon: const Icon(AppIcons.close, size: 20),
                            onPressed: () => setState(() => _dueOn = null),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LabeledField(
                label: l10n.duesFieldNote,
                child: TextField(
                  controller: _note,
                  maxLength: Limits.dueNoteMax,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: gumdropFieldText(context),
                  decoration: gumdropField(hint: l10n.duesFieldNoteHint),
                ),
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 16),
                SectionLabel(l10n.duesWho),
                const SizedBox(height: 6),
                if (everyone == null && (everyoneAsync?.failed ?? false))
                  const DuesLoadError()
                else if (everyone == null)
                  const SkeletonList(rows: 3)
                else if (everyone.isEmpty)
                  DuesQuiet(
                    group.hasPlayers ? l10n.duesNoPlayers : l10n.duesNoOne,
                  )
                else ...[
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _left.isEmpty
                        ? true
                        : _left.length == everyone.length
                        ? false
                        : null,
                    tristate: true,
                    title: Text(l10n.duesWhoAll),
                    onChanged: (_) => setState(
                      () => _left.isEmpty
                          ? _left.addAll([for (final p in everyone) p.id])
                          : _left.clear(),
                    ),
                  ),
                  for (final p in everyone)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: !_left.contains(p.id),
                      title: Text(p.name),
                      onChanged: (on) => setState(
                        () =>
                            on ?? false ? _left.remove(p.id) : _left.add(p.id),
                      ),
                    ),
                ],
              ],
              if (_error case final e?) ...[
                const SizedBox(height: 8),
                Text(e, style: TextStyle(color: c.cherry.text)),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton(
                  onPressed:
                      _saving ||
                          (_isEdit && editing == null) ||
                          (!_isEdit && everyone == null)
                      ? null
                      : () => unawaited(
                          _save(
                            group,
                            editing,
                            everyone ?? const <DuePayer>[],
                            charges,
                          ),
                        ),
                  child: Text(l10n.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
