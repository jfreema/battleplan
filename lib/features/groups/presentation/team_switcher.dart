import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/core/widgets/team_badge.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/my_team.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The list inside the team switcher sheet or dropdown (SPEC §5.2).
class TeamSwitcherList extends ConsumerWidget {
  const new({required this.currentGroupId, required this.onSelect, super.key});

  final GroupId? currentGroupId;
  final ValueChanged<GroupId> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final teams = ref.watch(myTeamsProvider).value ?? const <MyTeam>[];
    final active = teams.where((t) => !t.group.isArchived).toList();
    final archived = teams.where((t) => t.group.isArchived).toList();
    final now = DateTime.now();

    Widget tile(MyTeam t) {
      final selected = t.group.id == currentGroupId;
      final color = t.group.color;
      return ListTile(
        selected: selected,
        leading: TeamBadge(
          name: t.group.name,
          color: color == null ? null : Color(color),
          size: 40,
        ),
        title: Text(t.group.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: t.group.lastMessagePreview == null
            ? null
            : Text(
                t.group.lastMessagePreview!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (t.membership.isMutedAt(now))
              const Icon(AppIcons.muted, size: 18, semanticLabel: 'Muted'),
            if (t.hasUnread)
              Padding(
                padding: const EdgeInsets.only(left: Space.sm),
                child: Badge(
                  smallSize: 10,
                  backgroundColor: t.membership.isMutedAt(now)
                      ? Theme.of(context).colorScheme.outline
                      : null,
                ),
              ),
          ],
        ),
        onTap: () => onSelect(t.group.id),
      );
    }

    return ListView(
      shrinkWrap: true,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.sm),
          child: Text(
            l10n.teamSwitcherTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...active.map(tile),
        if (archived.isNotEmpty)
          ExpansionTile(
            title: Text(l10n.archivedTeams),
            children: archived.map(tile).toList(),
          ),
        const Divider(),
        ListTile(
          leading: const Icon(AppIcons.qr),
          title: Text(l10n.joinTeam),
          onTap: () => showAppSnackBar(context, l10n.comingSoon),
        ),
        ListTile(
          leading: const Icon(AppIcons.add),
          title: Text(l10n.createTeam),
          onTap: () => showAppSnackBar(context, l10n.comingSoon),
        ),
        const SizedBox(height: Space.lg),
      ],
    );
  }
}
