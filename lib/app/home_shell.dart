import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/features/admin/admin.dart';
import 'package:battleplan/features/groups/presentation/shell_parts.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The top of the app (SPEC §5.1): Teams at `/teams` and Profile at
/// `/profile`, with a bottom bar on phones or a left rail at 840 px and
/// up, the way a team's tabs are. A team's back arrow comes back here. A
/// super admin's rail has the Admin panel at its foot (SPEC §5.5).
///
/// Each tab is its own page, not a stateful shell: a shell's global key
/// would be in the tree twice when a page comes back while its last copy
/// is still leaving (signing in again from an emailed link does that).
class HomeShell extends ConsumerWidget {
  const new({required this.tab, required this.child, super.key});

  /// 0 for Teams, 1 for Profile.
  final int tab;
  final Widget child;

  static const paths = ['/teams', '/profile'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final superAdmin = watchSuperAdmin(ref);
    final tabs = <OpenFieldTab>[
      for (final (icon, label) in [
        (AppIcons.group, l10n.tabTeams),
        (AppIcons.person, l10n.tabProfile),
      ])
        (
          icon: Icon(icon),
          selectedIcon: Icon(icon, fill: 1),
          label: label,
          badge: null,
        ),
    ];
    void select(int i) => context.go(paths[i]);
    // No app bar here, so the status bar's icons are set for the scheme
    // here.
    if (MediaQuery.sizeOf(context).width >= Breakpoints.wide) {
      return SchemeStatusBar(
        child: Scaffold(
          body: Row(
            children: [
              OpenFieldRail(
                tabs: tabs,
                selectedIndex: tab,
                onSelect: select,
                links: [
                  if (superAdmin)
                    (
                      icon: AppIcons.admin,
                      label: l10n.adminPanel,
                      onTap: () => openAdminPanel(context),
                    ),
                ],
              ),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }
    return SchemeStatusBar(
      child: Scaffold(
        body: child,
        bottomNavigationBar: OpenFieldTabBar(
          tabs: tabs,
          selectedIndex: tab,
          onSelect: select,
        ),
      ),
    );
  }
}
