import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// [child] in the team's colors (TEAM-1): the Gumdrop theme tinted with
/// the color its admins chose. Every screen inside a team is wrapped in
/// this (app/router.dart); screens outside a team aren't.
///
/// The color comes from my teams, which are already loaded, so a team I'm
/// not on isn't read early; a super admin viewing a team (ADMIN-3) reads
/// the team itself.
class TeamColors extends ConsumerWidget {
  const new({required this.groupId, required this.child, super.key});

  final GroupId groupId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref
        .watch(myTeamsProvider)
        .value
        ?.where((t) => t.group.id == groupId)
        .firstOrNull;
    final color =
        mine?.group.color ??
        (mine == null && ref.watch(viewingAsSuperAdminProvider(groupId))
            ? ref.watch(groupProvider(groupId)).value?.color
            : null);
    return TeamTheme(teamColor: color, child: child);
  }
}
