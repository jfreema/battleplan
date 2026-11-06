import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// [child] in the color scheme I see [groupId] in (SET-2): my pick on my
/// membership, else my default. Every screen inside a team is wrapped in
/// this (app/router.dart); screens outside a team use my default.
class TeamSchemeTheme extends ConsumerWidget {
  const new({required this.groupId, required this.child, super.key});

  final GroupId groupId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      SchemeTheme(scheme: ref.watch(teamSchemeProvider(groupId)), child: child);
}
