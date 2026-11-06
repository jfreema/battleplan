import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/card_dialog.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/focus_ring_ink.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/dues/application/providers.dart';
import 'package:battleplan/features/dues/domain/due.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// [cents] as dollars: "$45" or "$45.50" (US only, DUES-1).
String formatDues(AppLocalizations l10n, int cents) {
  final whole = cents % 100 == 0;
  return NumberFormat.simpleCurrency(
    locale: 'en_US',
    name: 'USD',
    decimalDigits: whole ? 0 : 2,
  ).format(cents / 100);
}

/// "Nov 30" for a due date stored as "2026-11-30".
String _dueDate(AppLocalizations l10n, String dueOn) {
  final d = DateTime.tryParse(dueOn);
  return d == null ? dueOn : DateFormat.MMMd(l10n.localeName).format(d);
}

String statusName(AppLocalizations l10n, DueStatus s) => switch (s) {
  DueStatus.owed => l10n.duesStatusOwed,
  DueStatus.paid => l10n.duesStatusPaid,
  DueStatus.waived => l10n.duesStatusWaived,
};

/// Shown where a list couldn't load, rather than a skeleton forever.
class _LoadError extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: AppIcons.error,
    message: AppLocalizations.of(context).loadError,
  );
}

bool _isAdmin(WidgetRef ref, GroupId groupId) =>
    (ref.watch(myMembershipProvider(groupId))?.isAdmin ?? false) ||
    (ref.watch(authUserProvider).value?.isSuperAdmin ?? false);

/// Dues at `/g/:groupId/dues` (DUES-1 to DUES-3). Admins see every due with
/// how many have paid and what's still owed, and add new ones; everyone
/// else sees only what they, or their players, owe. Under it, how to pay
/// the team: Venmo, Cash App or Apple Cash handles the admins share. No
/// money goes through Battleplan.
class DuesScreen extends ConsumerWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final group = ref.watch(groupProvider(groupId)).value;
    final admin = _isAdmin(ref, groupId);
    final isGroup = group?.isGroup ?? false;
    final archived = group?.isArchived ?? false;
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
                _AdminDues(groupId: groupId, canAdd: !archived)
              else
                _MyDues(groupId: groupId),
              const SizedBox(height: 24),
              _HowToPay(groupId: groupId, canEdit: admin && !archived),
            ],
          ),
        ),
      ),
    );
  }
}

/// The admins' list: each due with how many have paid.
class _AdminDues extends ConsumerWidget {
  const new({required this.groupId, required this.canAdd});

  final GroupId groupId;
  final bool canAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dues = ref.watch(teamDuesProvider(groupId));
    final list = dues.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canAdd)
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
          const _LoadError()
        else if (list == null)
          const SkeletonList()
        else if (list.isEmpty)
          _Quiet(l10n.duesEmptyAdmin)
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
/// "4 of 12 paid · $90 owed" from its own charges.
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
          final summary = [
            l10n.duesPaidOf(totals.paid, totals.count),
            if (totals.owedCents > 0)
              l10n.duesTotalOwed(formatDues(l10n, totals.owedCents)),
          ].join(' · ');
          return FocusRingInk(
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
                            l10n.duesDueOn(_dueDate(l10n, on)),
                            style: _muted(c),
                          ),
                        const SizedBox(height: 6),
                        if (loaded == null)
                          Text(
                            charges.hasError ? l10n.loadError : '',
                            style: _muted(c).copyWith(fontSize: 14),
                          )
                        else
                          Row(
                            children: [
                              _Bar(
                                fraction: totals.count == 0
                                    ? 0
                                    : totals.paid / totals.count,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  summary,
                                  style: _muted(c).copyWith(
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
        },
      ),
    );
  }
}

TextStyle _muted(GumdropColors c) => TextStyle(
  fontFamily: AppFonts.body,
  fontWeight: FontWeight.w600,
  fontSize: 15,
  height: 19 / 15,
  color: c.textMuted,
);

/// The title in Nunito 800 18 with the amount on the right.
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
    return Row(
      children: [
        Expanded(child: Text(title, style: style)),
        const SizedBox(width: 10),
        Text(amount, style: style),
      ],
    );
  }
}

/// A 40 × 5 bar, mint for what's paid.
class _Bar extends StatelessWidget {
  const new({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final c = GumdropColors.of(context);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: SizedBox(
          width: 40,
          height: 5,
          child: ColoredBox(
            color: c.cardTrack,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: fraction.clamp(0, 1),
                heightFactor: 1,
                child: ColoredBox(color: c.mint.face),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Quiet extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      text,
      style: TextStyle(
        fontFamily: AppFonts.body,
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: GumdropColors.of(context).textMutedOnPage,
      ),
    ),
  );
}

/// What I owe (DUES-2): my own share, or each of my players', with what's
/// still owed in all.
class _MyDues extends ConsumerWidget {
  const new({required this.groupId});

  final GroupId groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mine = ref.watch(myChargesProvider(groupId));
    final payers = ref.watch(myPayersProvider(groupId)).value ?? const [];
    final list = mine.value;
    if (list == null) {
      return mine.hasError ? const _LoadError() : const SkeletonList();
    }
    final owed = list.fold(0, (sum, x) => sum + x.owedCents);
    final several = payers.length > 1;
    final sorted = [...list]
      ..sort((a, b) {
        final byStatus = (a.owedCents == 0 ? 1 : 0).compareTo(
          b.owedCents == 0 ? 1 : 0,
        );
        return byStatus != 0
            ? byStatus
            : (a.dueOn ?? '~').compareTo(b.dueOn ?? '~');
      });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeading(l10n.duesYours),
        const SizedBox(height: 4),
        _Quiet(
          list.isEmpty
              ? l10n.duesEmptyMember
              : owed == 0
              ? l10n.duesAllPaid
              : l10n.duesTotalOwed(formatDues(l10n, owed)),
        ),
        if (list.isNotEmpty)
          PageRows(
            children: [
              for (final x in sorted) _ChargeRow(charge: x, showName: several),
            ],
          ),
      ],
    );
  }
}

/// One share, on the page: what it's for (and for whom), the amount, and
/// whether it's paid. Admins tap it to change that.
class _ChargeRow extends StatelessWidget {
  const new({required this.charge, this.showName = true, this.onTap});

  final DueCharge charge;
  final bool showName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final sub = [
      if (showName && onTap == null) l10n.duesFor(charge.participantName),
      formatDues(l10n, charge.amountCents),
      if (charge.dueOn case final on? when charge.status == DueStatus.owed)
        l10n.duesDueOn(_dueDate(l10n, on)),
    ].join(' · ');
    return PageRow(
      title: onTap == null ? charge.title : charge.participantName,
      subtitle: sub,
      onTap: onTap,
      trailing: _StatusPill(status: charge.status),
      leading: Icon(
        charge.paid ? AppIcons.going : AppIcons.payments,
        size: 22,
        color: charge.paid ? c.successOnPage : c.textOnPage,
      ),
    );
  }
}

/// Paid in mint, owed in coral, waived quiet.
class _StatusPill extends StatelessWidget {
  const new({required this.status});

  final DueStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final (face, text) = switch (status) {
      DueStatus.paid => (c.mint.face, c.ink),
      DueStatus.owed => (c.cherry.face, c.ink),
      DueStatus.waived => (null, c.textMutedOnPage),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: face,
        borderRadius: BorderRadius.circular(12),
        border: face == null ? Border.all(color: c.outline, width: 1.5) : null,
      ),
      child: Text(
        statusName(l10n, status),
        style: GumdropStyle.of(context).label(
          TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            height: 16 / 13,
            color: text,
          ),
        ),
      ),
    );
  }
}

/// How to pay the team (DUES-3): each handle with Copy, and on the web and
/// Android an Open link. The iPhone app copies only: these are payments
/// between people, outside the app.
class _HowToPay extends ConsumerWidget {
  const new({required this.groupId, required this.canEdit});

  final GroupId groupId;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final pay = ref.watch(duesPaymentsProvider(groupId)).value;
    final links = kIsWeb || defaultTargetPlatform != TargetPlatform.iOS;
    Widget row(String app, String shown, Uri? link) => PageRow(
      title: app,
      subtitle: shown,
      icon: AppIcons.payments,
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
    final p = pay ?? const DuesPayments();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: PageHeading(l10n.duesHowToPay)),
            if (canEdit)
              TextButton.icon(
                onPressed: () => unawaited(_edit(context, ref, p)),
                icon: const Icon(AppIcons.edit, size: 18),
                label: Text(l10n.duesEditPayments),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (p.isEmpty)
          _Quiet(l10n.duesHowToPayEmpty)
        else ...[
          PageRows(
            children: [
              if (p.venmo.isNotEmpty)
                row(
                  l10n.duesVenmo,
                  '@${venmoUser(p.venmo)}',
                  Uri.https('venmo.com', '/u/${venmoUser(p.venmo)}'),
                ),
              if (p.cashApp.isNotEmpty)
                row(
                  l10n.duesCashApp,
                  '\$${cashTag(p.cashApp)}',
                  Uri.https('cash.app', '/\$${cashTag(p.cashApp)}'),
                ),
              if (p.appleCash.isNotEmpty)
                row(l10n.duesAppleCash, p.appleCash.trim(), null),
            ],
          ),
          if (p.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              p.note,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: c.textOnPage,
              ),
            ),
          ],
        ],
        const SizedBox(height: 8),
        _Quiet(l10n.duesHowToPayNote),
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
      builder: (_) => _PaymentsDialog(initial: p),
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
  const new({required this.initial});

  final DuesPayments initial;

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
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LabeledField(
        label: label,
        child: TextField(
          controller: controller,
          maxLength: max,
          minLines: 1,
          maxLines: lines,
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
            field(l10n.duesAppleCash, _apple, l10n.duesAppleCashHint),
            field(
              l10n.duesPayNote,
              _note,
              l10n.duesPayNoteHint,
              max: Limits.dueNoteMax,
              lines: 3,
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
          onPressed: () => Navigator.of(context).pop(
            DuesPayments(
              venmo: _venmo.text.trim(),
              cashApp: _cash.text.trim(),
              appleCash: _apple.text.trim(),
              note: _note.text.trim(),
            ),
          ),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// One due at `/g/:groupId/dues/:dueId` (admins, DUES-2): everyone's share,
/// and a tap marks it paid or not, or waives it.
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
    final charges = [...?chargesAsync.value]
      ..sort((a, b) => a.participantName.compareTo(b.participantName));
    final archived =
        ref.watch(groupProvider(groupId)).value?.isArchived ?? false;
    final canEdit = _isAdmin(ref, groupId) && !archived;
    final totals = dueTotals(charges);
    return Scaffold(
      appBar: gumdropAppBar(
        context,
        title: due?.title ?? l10n.duesTitle,
        backLabel: l10n.duesTitle,
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
          ? (duesAsync.hasError ? const _LoadError() : const SkeletonList())
          : due == null
          ? Center(child: _Quiet(l10n.duesNotFound))
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
                  children: [
                    Text(
                      [
                        formatDues(l10n, due.amountCents),
                        if (due.dueOn case final on?)
                          l10n.duesDueOn(_dueDate(l10n, on)),
                      ].join(' · '),
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: c.textOnPage,
                      ),
                    ),
                    if (due.note.isNotEmpty) _Quiet(due.note),
                    const SizedBox(height: 6),
                    if (chargesAsync.value == null && chargesAsync.hasError)
                      const _LoadError()
                    else if (chargesAsync.value == null)
                      const SkeletonList()
                    else ...[
                      _Quiet(
                        [
                          l10n.duesPaidOf(totals.paid, totals.count),
                          if (totals.owedCents > 0)
                            l10n.duesTotalOwed(
                              formatDues(l10n, totals.owedCents),
                            ),
                        ].join(' · '),
                      ),
                      const SizedBox(height: 8),
                      PageRows(
                        children: [
                          for (final x in charges)
                            _ChargeRow(
                              charge: x,
                              onTap: canEdit
                                  ? () => unawaited(_setStatus(context, ref, x))
                                  : null,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    DueCharge charge,
  ) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showCardSheet<DueStatus>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(charge.participantName),
              subtitle: Text(formatDues(l10n, charge.amountCents)),
            ),
            for (final (s, label) in [
              (DueStatus.paid, l10n.duesMarkPaid),
              (DueStatus.owed, l10n.duesMarkOwed),
              (DueStatus.waived, l10n.duesWaive),
            ])
              if (s != charge.status)
                ListTile(
                  title: Text(label),
                  onTap: () => Navigator.of(sheet).pop(s),
                ),
          ],
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid == null) return;
    try {
      await ref
          .read(duesRepositoryProvider)
          .setStatus(charge, picked, by: UserId(uid));
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

/// A new due at `/g/:groupId/dues/new`, or a due's edit (admins, DUES-1):
/// what it's for, the amount, a date, a note, and, when new, who owes it:
/// every active player on a team, or every member of a group, with any
/// left out by unchecking.
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

  List<DuePayer> _everyone(Group group) {
    if (group.hasPlayers) {
      return [
        for (final p
            in ref.watch(playersProvider(group.id)).value ?? const <Player>[])
          if (!p.isPending)
            (type: ParticipantType.player, id: p.id.value, name: p.label),
      ];
    }
    return [
      for (final m
          in ref.watch(rosterProvider(group.id)).value ?? const <Membership>[])
        if (!m.pending)
          (type: ParticipantType.member, id: m.uid.value, name: m.displayName),
    ];
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dueOn ?? '') ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    setState(
      () => _dueOn =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}',
    );
  }

  Future<void> _save(Group group, Due? editing) async {
    final l10n = AppLocalizations.of(context);
    // Editing needs the due; never fall back to adding a new one.
    if (_isEdit && editing == null) return;
    final cents = _cents;
    final payers = [
      for (final p in _everyone(group))
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
        );
      }
      if (mounted) context.pop();
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
    if (editing != null && !_loaded) {
      _loaded = true;
      _title.text = editing.title;
      _amount.text = (editing.amountCents / 100).toStringAsFixed(
        editing.amountCents % 100 == 0 ? 0 : 2,
      );
      _note.text = editing.note;
      _dueOn = editing.dueOn;
    }
    if (group == null || (_isEdit && editing == null)) {
      // On the edit route, nothing to save until the due loads: a list
      // that failed, or a due that's gone, says so.
      final body = duesAsync == null || !duesAsync.hasValue
          ? (duesAsync?.hasError ?? false)
                ? const _LoadError()
                : const SkeletonList()
          : group == null
          ? const SkeletonList()
          : Center(child: _Quiet(l10n.duesNotFound));
      return Scaffold(
        appBar: gumdropAppBar(
          context,
          title: _isEdit ? l10n.duesEdit : l10n.duesNew,
          backLabel: l10n.duesTitle,
        ),
        body: body,
      );
    }
    final everyone = widget.dueId == null
        ? _everyone(group)
        : const <DuePayer>[];
    return Scaffold(
      appBar: gumdropAppBar(
        context,
        title: widget.dueId == null ? l10n.duesNew : l10n.duesEdit,
        backLabel: l10n.duesTitle,
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
                  decoration: gumdropField(hint: r'$45'),
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
                    trailing: _dueOn == null
                        ? null
                        : IconButton(
                            tooltip: l10n.duesNoDate,
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
                  style: gumdropFieldText(context),
                  decoration: gumdropField(),
                ),
              ),
              if (widget.dueId == null) ...[
                const SizedBox(height: 16),
                SectionLabel(l10n.duesWho),
                const SizedBox(height: 6),
                if (everyone.isEmpty)
                  _Quiet(l10n.duesNoPlayers)
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
                  onPressed: _saving || (_isEdit && editing == null)
                      ? null
                      : () => unawaited(_save(group, editing)),
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
