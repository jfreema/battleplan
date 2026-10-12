import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// ADMIN-3 View team: "Viewing as super admin" across the top of a team's
/// tabs while a super admin who isn't on the team looks around, with a way
/// back to the team's admin page. Showing it records the visit in the
/// audit log, once while it's up.
class ViewingAsSuperAdminBanner extends ConsumerWidget {
  const new({required this.groupId, super.key});

  final GroupId groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The record is best effort: a failure doesn't stop the viewing.
    ref.watch(adminGroupOpenedProvider(groupId));
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    return Material(
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: EdgeInsets.only(left: Space.gutter(width), right: Space.xs),
        child: Row(
          children: [
            Icon(AppIcons.admin, size: 20, color: scheme.onTertiaryContainer),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.sm),
                child: Text(
                  l10n.viewingAsSuperAdmin,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onTertiaryContainer,
                  ),
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: scheme.onTertiaryContainer,
              ),
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go('/admin/teams/${groupId.value}'),
              child: Text(l10n.backToAdminPanel),
            ),
          ],
        ),
      ),
    );
  }
}
