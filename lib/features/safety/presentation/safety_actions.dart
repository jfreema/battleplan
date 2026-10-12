import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/safety/application/providers.dart';
import 'package:battleplan/features/safety/domain/safety.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

String reportReasonLabel(AppLocalizations l10n, ReportReason r) => switch (r) {
  ReportReason.spam => l10n.reportSpam,
  ReportReason.harassment => l10n.reportHarassment,
  ReportReason.inappropriate => l10n.reportInappropriate,
  ReportReason.other => l10n.reportOther,
};

/// Report a message, document, or person (SAFE-1): a reason, optional
/// details, and a confirmation. The reported person is never told.
Future<void> showReportSheet(
  BuildContext context,
  WidgetRef ref, {
  required GroupId groupId,
  required ReportTargetType targetType,
  required String targetId,
}) async {
  final l10n = AppLocalizations.of(context);
  final sent = await showAdaptiveSheet<bool>(
    context,
    builder: (_) => _ReportForm(
      onSend: (reason, details) => ref
          .read(safetyRepositoryProvider)
          .report(
            groupId,
            targetType: targetType,
            targetId: targetId,
            reason: reason,
            details: details,
          ),
    ),
  );
  if ((sent ?? false) && context.mounted) {
    showAppSnackBar(context, l10n.reportSent);
  }
}

class _ReportForm extends StatefulWidget {
  const new({required this.onSend});

  final Future<void> Function(ReportReason reason, String details) onSend;

  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  ReportReason? _reason;
  final _details = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.onSend(_reason!, _details.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = e is RateLimited
              ? l10n.reportRateLimited
              : l10n.errorSendReport;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Space.xl,
          Space.xl,
          Space.xl,
          Space.xl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.reportTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Space.sm),
            Text(l10n.reportHelp),
            const SizedBox(height: Space.md),
            RadioGroup<ReportReason>(
              groupValue: _reason,
              onChanged: (r) => setState(() => _reason = r),
              child: Column(
                children: [
                  for (final r in ReportReason.values)
                    RadioListTile<ReportReason>(
                      contentPadding: EdgeInsets.zero,
                      value: r,
                      title: Text(reportReasonLabel(l10n, r)),
                    ),
                ],
              ),
            ),
            TextField(
              controller: _details,
              maxLength: 1000,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(labelText: l10n.reportDetails),
            ),
            if (_error case final error?)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton(
              onPressed: _reason == null || _sending
                  ? null
                  : () => unawaited(_send()),
              child: Text(l10n.reportSend),
            ),
          ],
        ),
      ),
    );
  }
}

/// Blocks someone after asking (SAFE-2). Returns true if blocked.
Future<bool> confirmBlock(
  BuildContext context,
  WidgetRef ref, {
  required UserId uid,
  required String name,
}) async {
  final l10n = AppLocalizations.of(context);
  final me = ref.read(authUserProvider).value?.uid;
  if (me == null) return false;
  final ok = await showConfirmDialog(
    context,
    title: l10n.blockTitle(name),
    message: l10n.blockBody,
    confirmLabel: l10n.block,
    cancelLabel: l10n.cancel,
    destructive: true,
  );
  if (!ok) return false;
  try {
    await ref.read(safetyRepositoryProvider).block(UserId(me), uid, name: name);
    if (context.mounted) showAppSnackBar(context, l10n.blocked(name));
    return true;
  } on AppFailure {
    if (context.mounted) showAppSnackBar(context, l10n.errorBlock);
    return false;
  }
}

/// Unblocks someone (SET-5).
Future<void> unblock(BuildContext context, WidgetRef ref, UserId uid) async {
  final me = ref.read(authUserProvider).value?.uid;
  if (me == null) return;
  try {
    await ref.read(safetyRepositoryProvider).unblock(UserId(me), uid);
  } on AppFailure {
    if (context.mounted) {
      showAppSnackBar(context, AppLocalizations.of(context).errorUnblock);
    }
  }
}
