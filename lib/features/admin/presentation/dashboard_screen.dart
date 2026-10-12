import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/admin/presentation/admin_widgets.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// ADMIN-1 at `/admin`: the platform's totals, each opening its list.
class AdminDashboardScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final totals = ref.watch(adminTotalsProvider);
    final number = NumberFormat.decimalPattern(l10n.localeName);
    return AdminScaffold(
      section: AdminSection.dashboard,
      title: l10n.adminDashboard,
      actions: [
        IconButton(
          tooltip: l10n.retry,
          icon: const Icon(AppIcons.retry),
          onPressed: () => ref.invalidate(adminTotalsProvider),
        ),
      ],
      body: switch (totals) {
        AsyncValue(:final AdminTotals value) => AdminBody(
          children: [
            Wrap(
              spacing: Space.lg,
              runSpacing: Space.lg,
              children: [
                _Stat(
                  label: l10n.adminStatUsers,
                  value: number.format(value.users),
                  icon: AppIcons.person,
                  route: AdminSection.users.path,
                ),
                _Stat(
                  label: l10n.adminStatTeams,
                  value: number.format(value.teams),
                  icon: AppIcons.group,
                  route: AdminSection.teams.path,
                ),
                _Stat(
                  label: l10n.adminStatNewTeams,
                  value: number.format(value.newTeams),
                  icon: AppIcons.add,
                ),
                _Stat(
                  label: l10n.adminStatActiveTeams,
                  value: number.format(value.activeTeams),
                  icon: AppIcons.chat,
                ),
                _Stat(
                  label: l10n.adminStatMessages,
                  value: number.format(value.messages),
                  icon: AppIcons.send,
                ),
                _Stat(
                  label: l10n.adminStatStorage,
                  value: formatBytes(value.storageBytes),
                  icon: AppIcons.storage,
                ),
                _Stat(
                  label: l10n.adminStatOpenReports,
                  value: number.format(value.openReports),
                  icon: AppIcons.report,
                  route: AdminSection.reports.path,
                  alert: value.openReports > 0,
                ),
              ],
            ),
          ],
        ),
        AsyncError() => Center(child: Text(l10n.loadError)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// One total; tapping it opens its list when there is one.
class _Stat extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.icon,
    this.route,
    this.alert = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? route;

  /// Open reports waiting (SAFE-4's 24-hour goal): drawn in the error color.
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = alert ? theme.colorScheme.error : theme.colorScheme.primary;
    final target = route;
    return SizedBox(
      width: 200,
      child: Card.outlined(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: target == null ? null : () => context.go(target),
          child: Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Semantics(
              label: '$label: $value',
              excludeSemantics: true,
              button: target != null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color),
                  const SizedBox(height: Space.sm),
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: alert ? color : null,
                    ),
                  ),
                  Text(label, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
