import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/card_dialog.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/dues/application/providers.dart';
import 'package:battleplan/features/dues/domain/due.dart';
import 'package:battleplan/features/dues/presentation/dues_widgets.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// What an admin picked on a share's sheet.
sealed class _ShareAction {
  const new();
}

final class _Record extends _ShareAction {
  const new();
}

final class _PaidInFull extends _ShareAction {
  const new();
}

final class _SetStatus extends _ShareAction {
  const new(this.status);

  final DueStatus status;
}

final class _Undo extends _ShareAction {
  const new(this.payment);

  final DuePayment payment;
}

/// [charge] as it will be after [next], for what screen readers hear.
DueCharge _after(DueCharge charge, DueChargePayments next) => charge.copyWith(
  payments: next.payments,
  recordedCents: next.paidCents,
  status: next.status,
);

/// One person's share of a due, for its admins (DUES-2): where it stands,
/// then, with [canEdit], Record a payment, Mark paid in full (what's left,
/// in one tap), and Waive the rest, or Undo waive, or, on a share marked
/// paid before payments were recorded, Mark not paid; and its payments,
/// each with who recorded it, its note, and Undo. Screen readers hear each
/// change.
Future<void> openShareSheet(
  BuildContext context,
  WidgetRef ref,
  DueCharge charge, {
  required bool canEdit,
}) async {
  final l10n = AppLocalizations.of(context);
  final picked = await showCardSheet<_ShareAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ShareSheet(charge: charge, canEdit: canEdit),
  );
  if (picked == null || !context.mounted) return;
  final uid = ref.read(authUserProvider).value?.uid;
  if (uid == null) return;
  final by = UserId(uid);
  final repo = ref.read(duesRepositoryProvider);
  void announce(DueCharge after) {
    if (!context.mounted) return;
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        l10n.duesStatusAnnounce(
          charge.participantName,
          shareSpoken(l10n, after),
        ),
        Directionality.of(context),
      ),
    );
  }

  try {
    switch (picked) {
      case _Record():
        final after = await showCardDialog<DueCharge>(
          context: context,
          builder: (_) => _RecordPaymentDialog(charge: charge),
        );
        if (after != null) announce(after);
      case _PaidInFull():
        final payment = DuePayment(
          id: newRequestId(),
          amountCents: charge.owedCents,
          paidOn: dayKey(DateTime.now()),
          by: uid,
        );
        await repo.recordPayment(
          charge,
          id: payment.id,
          paidOn: payment.paidOn,
          by: by,
        );
        announce(_after(charge, addDuePayment(charge, payment)));
      case _SetStatus(:final status):
        await repo.setStatus(charge, status, by: by);
        announce(
          charge.copyWith(
            status: status == DueStatus.owed && charge.recordsPayments
                ? unwaivedStatus(charge)
                : status,
          ),
        );
      case _Undo(:final payment):
        final ok = await showConfirmDialog(
          context,
          title: l10n.duesUndoPaymentTitle,
          message: l10n.duesUndoPaymentBody(
            formatDues(l10n, payment.amountCents),
            charge.participantName,
          ),
          confirmLabel: l10n.duesUndoPayment,
          cancelLabel: l10n.cancel,
          destructive: true,
        );
        if (!ok || !context.mounted) return;
        await repo.undoPayment(charge, payment.id, by: by);
        announce(_after(charge, removeDuePayment(charge, payment.id)));
    }
  } on InvalidInput {
    // Changed since the sheet opened: another admin just recorded one.
    if (context.mounted) showAppSnackBar(context, l10n.duesPaymentChanged);
  } on AppFailure {
    if (context.mounted) showAppSnackBar(context, l10n.duesSaveFailed);
  }
}

class _ShareSheet extends ConsumerWidget {
  const new({required this.charge, required this.canEdit});

  final DueCharge charge;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final left = formatDues(l10n, charge.owedCents);
    final owing = charge.status == DueStatus.owed && charge.owedCents > 0;
    void pick(_ShareAction a) => Navigator.of(context).pop(a);
    Widget action(
      IconData icon,
      String title,
      _ShareAction a, {
      String? subtitle,
    }) => ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      onTap: () => pick(a),
    );
    String recorder(String uid) {
      final m = ref.watch(memberProvider(charge.groupId, UserId(uid)));
      if (!m.hasValue) return '';
      final who = m.value;
      return who == null
          ? l10n.duesPaymentByFormer
          : l10n.duesPaymentBy(who.displayName);
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Whose share, and where it stands: a heading, not a choice.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: MergeSemantics(
              child: Semantics(
                header: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      charge.participantName,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        height: 22 / 18,
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      [
                        shareLine(l10n, charge),
                        shareStateName(l10n, charge.state),
                      ].join(' · '),
                      style: duesMuted(c),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (canEdit) ...[
            if (owing) ...[
              action(
                AppIcons.payments,
                l10n.duesRecordPayment,
                const _Record(),
              ),
              action(
                AppIcons.check,
                l10n.duesPaidInFull,
                const _PaidInFull(),
                subtitle: l10n.duesPaidInFullSub(left),
              ),
              action(
                AppIcons.block,
                charge.partlyPaid ? l10n.duesWaiveRest : l10n.duesWaive,
                const _SetStatus(DueStatus.waived),
              ),
            ],
            if (charge.status == DueStatus.waived)
              action(
                AppIcons.undo,
                l10n.duesUnwaive,
                const _SetStatus(DueStatus.owed),
              ),
            // Marked paid before payments were recorded: no payment to
            // take back, so it's marked not paid.
            if (charge.paid && !charge.recordsPayments)
              action(
                AppIcons.payments,
                l10n.duesMarkOwed,
                const _SetStatus(DueStatus.owed),
              ),
          ],
          if (charge.payments.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SectionLabel(l10n.duesPayments),
            ),
            for (final p in charge.payments.reversed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PageRow(
                  title: [
                    formatDues(l10n, p.amountCents),
                    duesDay(l10n, p.paidOn),
                  ].join(' · '),
                  subtitle: [
                    if (p.by.isNotEmpty) recorder(p.by),
                    if (p.note.isNotEmpty) p.note,
                  ].where((x) => x.isNotEmpty).join('\n'),
                  subtitleMaxLines: null,
                  icon: AppIcons.payments,
                  chevron: false,
                  trailingActions: canEdit,
                  trailing: canEdit
                      ? IconButton(
                          tooltip: l10n.duesUndoPaymentTip(
                            formatDues(l10n, p.amountCents),
                          ),
                          icon: const Icon(AppIcons.undo, size: 22),
                          onPressed: () => pick(_Undo(p)),
                        )
                      : null,
                ),
              ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// Record a payment (DUES-2): how much, up to what's left, the day it was
/// paid (today unless changed), and a short note. It saves itself, trying
/// again with the same payment if a try fails, so it's never recorded
/// twice, and closes with the share as it will be.
class _RecordPaymentDialog extends ConsumerStatefulWidget {
  const new({required this.charge});

  final DueCharge charge;

  @override
  ConsumerState<_RecordPaymentDialog> createState() =>
      _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends ConsumerState<_RecordPaymentDialog> {
  final _amount = TextEditingController();
  final _note = TextEditingController();

  /// One per payment, the same on every try (DUES-2).
  final String _id = newRequestId();
  String _paidOn = dayKey(DateTime.now());
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_paidOn) ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked != null) setState(() => _paidOn = dayKey(picked));
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final charge = widget.charge;
    final left = formatDues(l10n, charge.owedCents);
    final cents = parseDollars(_amount.text);
    if (cents == null || cents > charge.owedCents) {
      setState(() => _error = l10n.duesPaymentTooMuch(left));
      return;
    }
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final payment = DuePayment(
      id: _id,
      amountCents: cents,
      paidOn: _paidOn,
      by: uid,
      note: _note.text.trim(),
    );
    try {
      await ref
          .read(duesRepositoryProvider)
          .recordPayment(
            charge,
            id: _id,
            amountCents: cents,
            paidOn: _paidOn,
            note: payment.note,
            by: UserId(uid),
          );
      if (mounted) {
        Navigator.of(context)
            .pop(_after(charge, addDuePayment(charge, payment)));
      }
    } on InvalidInput catch (e) {
      if (mounted) {
        setState(
          () => _error = e.message == DuePaymentRefusal.full.name
              ? l10n.duesPaymentsFull(Limits.duePaymentsMax)
              : l10n.duesPaymentChanged,
        );
      }
    } on AppFailure {
      if (mounted) setState(() => _error = l10n.duesSaveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final charge = widget.charge;
    final left = formatDues(l10n, charge.owedCents);
    final today = dayKey(DateTime.now());
    return AlertDialog(
      title: Text(l10n.duesRecordPayment),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              [charge.participantName, charge.title].join(' · '),
              style: duesMuted(c),
            ),
            Text(shareLine(l10n, charge), style: duesMuted(c)),
            const SizedBox(height: 12),
            LabeledField(
              label: l10n.duesFieldAmount,
              child: TextField(
                controller: _amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,$]')),
                ],
                style: gumdropFieldText(context),
                decoration: gumdropField(
                  hint: l10n.duesPaymentAmountHint(left),
                ),
                onSubmitted: (_) => unawaited(_save()),
              ),
            ),
            const SizedBox(height: 8),
            PageRows(
              children: [
                PageRow(
                  icon: AppIcons.schedule,
                  title: l10n.duesPaymentDate,
                  subtitle: _paidOn == today
                      ? l10n.duesToday
                      : duesDay(l10n, _paidOn),
                  onTap: () => unawaited(_pickDate()),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: l10n.duesPaymentNote,
              child: TextField(
                controller: _note,
                maxLength: Limits.duePaymentNoteMax,
                textCapitalization: TextCapitalization.sentences,
                style: gumdropFieldText(context),
                decoration: gumdropField(hint: l10n.duesPaymentNoteHint),
              ),
            ),
            Text(
              l10n.duesPaymentNoteWho,
              style: duesMuted(c).copyWith(fontSize: 14),
            ),
            if (_error case final e?) ...[
              const SizedBox(height: 8),
              Text(e, style: TextStyle(color: c.cherry.text)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : () => unawaited(_save()),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
