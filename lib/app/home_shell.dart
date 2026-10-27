import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/features/groups/presentation/shell_parts.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The top of the app (SPEC §5.1): Teams at `/teams` and Profile at
/// `/profile`, with a bottom bar on phones or a left rail at 840 px and
/// up, the way a team's tabs are. A team's back arrow comes back here.
///
/// Each tab is its own page, not a stateful shell: a shell's global key
/// would be in the tree twice when a page comes back while its last copy
/// is still leaving (signing in again from an emailed link does that).
class HomeShell extends StatelessWidget {
  const new({required this.tab, required this.child, super.key});

  /// 0 for Teams, 1 for Profile.
  final int tab;
  final Widget child;

  static const paths = ['/teams', '/profile'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destinations = [
      (AppIcons.group, l10n.tabTeams),
      (AppIcons.profile, l10n.tabProfile),
    ];
    void select(int i) => context.go(paths[i]);
    if (MediaQuery.sizeOf(context).width >= Breakpoints.wide) {
      return Scaffold(
        body: Row(
          children: [
            FloatingRail(
              child: NavigationRail(
                backgroundColor: Colors.transparent,
                selectedIndex: tab,
                onDestinationSelected: select,
                destinations: [
                  for (final (icon, label) in destinations)
                    NavigationRailDestination(
                      icon: Icon(icon),
                      label: Text(label),
                    ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      );
    }
    return Scaffold(
      body: child,
      // A floating rounded panel (design §3.12).
      bottomNavigationBar: FloatingTabBar(
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          selectedIndex: tab,
          onDestinationSelected: select,
          destinations: [
            for (final (icon, label) in destinations)
              NavigationDestination(icon: Icon(icon), label: label),
          ],
        ),
      ),
    );
  }
}
