import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/admin/presentation/admin_widgets.dart';
import 'package:battleplan/features/safety/safety.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// ADMIN-5 at `/admin/reports`: reports from every team with what was
/// reported, who reported it, and the team. Open ones can be acted on:
/// delete the content, remove the person from the team, disable them,
/// suspend the team, or dismiss. Each asks for a note, which is saved.
class AdminReportsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  ReportStatus _status = ReportStatus.open;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reports = ref.watch(adminReportsProvider(_status));
    return AdminScaffold(
      section: AdminSection.reports,
      title: l10n.reportsTitle,
      body: AdminBody(
        maxWidth: 840,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<ReportStatus>(
              segments: [
                for (final s in ReportStatus.values)
                  ButtonSegment(value: s, label: Text(_statusLabel(l10n, s))),
              ],
              selected: {_status},
              onSelectionChanged: (s) => setState(() => _status = s.first),
            ),
          ),
          const SizedBox(height: Space.lg),
          switch (reports) {
            AsyncValue(:final AdminList<AdminReport> value)
                when value.items.isEmpty =>
              EmptyState(icon: AppIcons.check, message: l10n.noReports),
            AsyncValue(:final AdminList<AdminReport> value) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final r in value.items) _ReportCard(report: r),
                if (!value.reachedEnd)
                  LoadMoreButton(
                    loading: value.loadingMore,
                    onPressed: () => ref
                        .read(adminReportsProvider(_status).notifier)
                        .loadMore(),
                  ),
              ],
            ),
            AsyncError() => Center(child: Text(l10n.loadError)),
            _ => const SkeletonList(),
          },
        ],
      ),
    );
  }
}

String _statusLabel(AppLocalizations l10n, ReportStatus s) => switch (s) {
  ReportStatus.open => l10n.adminReportsOpen,
  ReportStatus.actioned => l10n.adminReportsActioned,
  ReportStatus.dismissed => l10n.adminReportsDismissed,
};

String _actionLabel(
  AppLocalizations l10n,
  AdminReportAction a,
  AdminReport r,
) => switch (a) {
  AdminReportAction.deleteContent =>
    r.targetType == ReportTargetType.document
        ? l10n.reportDeleteDocument
        : l10n.reportDeleteMessage,
  AdminReportAction.removeMember => l10n.reportRemoveMember,
  AdminReportAction.disableUser => l10n.adminDisablePerson,
  AdminReportAction.suspendTeam => l10n.adminSuspendTeam,
  AdminReportAction.dismiss => l10n.reportDismiss,
};

/// What each action does, said before it's done (ADMIN-8).
String _actionBody(AppLocalizations l10n, AdminReportAction a, AdminReport r) =>
    switch (a) {
      AdminReportAction.deleteContent =>
        r.targetType == ReportTargetType.document
            ? l10n.documentDeleteBody
            : l10n.deleteMessageBody,
      AdminReportAction.removeMember => l10n.adminRemovePersonBody(
        r.subjectName,
        r.groupName,
      ),
      AdminReportAction.disableUser => l10n.adminDisableBody,
      AdminReportAction.suspendTeam => l10n.adminSuspendBody,
      AdminReportAction.dismiss => l10n.adminDismissBody,
    };

class _ReportCard extends ConsumerWidget {
  const new({required this.report});

  final AdminReport report;

  Future<void> _resolve(
    BuildContext context,
    WidgetRef ref,
    AdminReportAction action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final note = await askNote(
      context,
      title: _actionLabel(l10n, action, report),
      message: _actionBody(l10n, action, report),
      confirmLabel: _actionLabel(l10n, action, report),
      required: true,
      destructive: action != AdminReportAction.dismiss,
    );
    if (note == null || note.isEmpty || !context.mounted) return;
    final ok = await runAdminAction(
      context,
      () => ref
          .read(adminRepositoryProvider)
          .resolveReport(report.id, action, note),
      done: l10n.adminReportResolved,
    );
    if (ok) {
      ref
        ..invalidate(adminReportsProvider)
        ..invalidate(adminTotalsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final r = report;
    final about = switch (r.targetType) {
      ReportTargetType.message => l10n.reportAboutMessage(r.subjectName),
      ReportTargetType.user => l10n.reportAboutPerson(r.subjectName),
      ReportTargetType.document => l10n.reportAboutDocument(r.subjectName),
    };
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: Space.lg),
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${reportReasonLabel(l10n, r.reason)} · ${adminDateTime(l10n, r.createdAt)}',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                // A direct conversation (CHAT-19) has no team page.
                if (r.direct)
                  Text(
                    l10n.reportsDirectMessage,
                    style: theme.textTheme.labelLarge,
                  )
                else
                  TextButton(
                    onPressed: () => unawaited(
                      context.push('/admin/teams/${r.groupId.value}'),
                    ),
                    child: Text(
                      r.groupName.isEmpty ? r.groupId.value : r.groupName,
                    ),
                  ),
              ],
            ),
            Text(about),
            Text(
              l10n.adminReportedBy(
                r.reporterName.isEmpty ? r.reporterId : r.reporterName,
              ),
              style: theme.textTheme.bodySmall,
            ),
            if (r.excerpt.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: Space.sm),
                padding: const EdgeInsets.all(Space.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(Corners.card),
                ),
                child: Text(r.excerpt),
              ),
            if (r.details?.isNotEmpty ?? false) ...[
              const SizedBox(height: Space.sm),
              Text(
                l10n.reportDetailsShown(r.details!),
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: Space.sm),
            if (r.status == ReportStatus.open)
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  for (final a in reportActionsFor(r))
                    if (a == AdminReportAction.dismiss)
                      TextButton(
                        onPressed: () => unawaited(_resolve(context, ref, a)),
                        child: Text(_actionLabel(l10n, a, r)),
                      )
                    else
                      OutlinedButton(
                        onPressed: () => unawaited(_resolve(context, ref, a)),
                        child: Text(_actionLabel(l10n, a, r)),
                      ),
                  if (r.subjectId.isNotEmpty)
                    TextButton(
                      onPressed: () => unawaited(
                        context.push('/admin/users/${r.subjectId}'),
                      ),
                      child: Text(l10n.adminOpenUser),
                    ),
                ],
              )
            else if (r.note?.isNotEmpty ?? false)
              Text(
                l10n.adminResolutionNote(r.note!),
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
