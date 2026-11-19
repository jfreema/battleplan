import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/load_error.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/core/widgets/viewer_zone.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/documents/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/features/safety/application/providers.dart';
import 'package:battleplan/features/safety/domain/safety.dart';
import 'package:battleplan/features/safety/presentation/safety_actions.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Team menu → Reports (SAFE-4), for team admins: each open report with
/// what was reported, and Delete message (or document), Remove from team,
/// or Dismiss.
class ReportsScreen extends ConsumerWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reports = ref.watch(openReportsProvider(groupId));
    final isGroup = ref.watch(
      groupProvider(groupId).select((g) => g.value?.isGroup ?? false),
    );
    // The app's frame (#14, 2026-11-16; it had a plain bar, and no way
    // back from a "reported" notification). Opened from Team settings.
    return GumdropScaffold(
      title: l10n.reportsTitle,
      backLabel: backLabelFrom(
        context,
        isGroup ? l10n.groupSettings : l10n.teamSettings,
      ),
      body: switch (reports) {
        AsyncData(:final value) when value.isEmpty => EmptyState(
          icon: AppIcons.check,
          message: l10n.noReports,
        ),
        AsyncData(:final value) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            Space.page,
            14,
            Space.page,
            Space.xl,
          ),
          itemCount: value.length,
          separatorBuilder: (_, _) => const Divider(height: Space.xl),
          itemBuilder: (_, i) => _ReportCard(report: value[i]),
        ),
        AsyncError() => LoadError(
          onRetry: () => ref.invalidate(openReportsProvider(groupId)),
        ),
        _ => const SkeletonList(),
      },
    );
  }
}

class _ReportCard extends ConsumerWidget {
  const new({required this.report});

  final Report report;

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action, {
    required ReportResolution resolution,
  }) async {
    final l10n = AppLocalizations.of(context);
    try {
      await action();
      await ref
          .read(safetyRepositoryProvider)
          .resolveReport(
            report.id,
            actioned: resolution != ReportResolution.none,
            resolution: resolution,
          );
    } on AppFailure {
      if (context.mounted) showAppSnackBar(context, l10n.errorResolveReport);
    }
  }

  /// Deletes the reported document, if it's still there; Functions
  /// delete its file (SAFE-4, DOC-5).
  Future<void> _deleteDocument(WidgetRef ref, String id) async {
    final doc = await ref
        .read(documentRepositoryProvider)
        .watchDocument(DocumentId(id))
        .first;
    if (doc != null) await ref.read(documentRepositoryProvider).delete(doc);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final when = report.createdAt == null
        ? ''
        : MaterialLocalizations.of(
            context,
          ).formatShortDate(ViewerZone.wallClock(context, report.createdAt!));
    final isMember =
        ref
            .watch(rosterProvider(report.groupId))
            .value
            ?.any((m) => m.uid.value == report.subjectId) ??
        false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${reportReasonLabel(l10n, report.reason)} · $when',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: Space.xs),
        Text(switch (report.targetType) {
          ReportTargetType.message => l10n.reportAboutMessage(
            report.subjectName,
          ),
          ReportTargetType.user => l10n.reportAboutPerson(report.subjectName),
          ReportTargetType.document => l10n.reportAboutDocument(
            report.subjectName,
          ),
        }),
        if (report.excerpt.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: Space.sm),
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(Corners.card),
            ),
            child: Text(report.excerpt),
          ),
        if (report.details?.isNotEmpty ?? false) ...[
          const SizedBox(height: Space.sm),
          Text(
            l10n.reportDetailsShown(report.details!),
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: Space.sm),
        Wrap(
          spacing: Space.sm,
          children: [
            if (report.targetType == ReportTargetType.message)
              OutlinedButton(
                onPressed: () => unawaited(
                  _act(
                    context,
                    ref,
                    () => ref
                        .read(messageRepositoryProvider)
                        .deleteMessage(report.targetId),
                    resolution: ReportResolution.deletedMessage,
                  ),
                ),
                child: Text(l10n.reportDeleteMessage),
              ),
            if (report.targetType == ReportTargetType.document)
              OutlinedButton(
                onPressed: () => unawaited(
                  _act(
                    context,
                    ref,
                    () => _deleteDocument(ref, report.targetId),
                    resolution: ReportResolution.deletedDocument,
                  ),
                ),
                child: Text(l10n.reportDeleteDocument),
              ),
            if (isMember)
              OutlinedButton(
                onPressed: () async {
                  final ok = await showConfirmDialog(
                    context,
                    title: l10n.removeMemberTitle(report.subjectName),
                    confirmLabel: l10n.removeMember,
                    cancelLabel: l10n.cancel,
                    destructive: true,
                  );
                  if (!ok || !context.mounted) return;
                  await _act(
                    context,
                    ref,
                    () => ref
                        .read(memberRepositoryProvider)
                        .removeMember(report.groupId, UserId(report.subjectId)),
                    resolution: ReportResolution.removedMember,
                  );
                },
                child: Text(l10n.reportRemoveMember),
              ),
            TextButton(
              onPressed: () => unawaited(
                _act(
                  context,
                  ref,
                  () async {},
                  resolution: ReportResolution.none,
                ),
              ),
              child: Text(l10n.reportDismiss),
            ),
          ],
        ),
      ],
    );
  }
}
