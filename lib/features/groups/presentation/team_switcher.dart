import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/team_badge.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/my_team.dart';
import 'package:battleplan/features/groups/presentation/create_team_screen.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// [group]'s logo URL once it has loaded, or null to show its initials on
/// its color (SPEC §5.2).
String? teamLogoUrl(WidgetRef ref, Group? group) {
  final path = group?.photoPath;
  return path == null ? null : ref.watch(teamPhotoUrlProvider(path)).value;
}

/// [group]'s logo, or its initials on its color (SPEC §5.2, §7.1).
class GroupBadge extends ConsumerWidget {
  const new({required this.group, this.size = 32, super.key});

  final Group? group;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = group?.color;
    return TeamBadge(
      name: group?.name ?? '',
      color: color == null ? null : Color(color),
      imageUrl: teamLogoUrl(ref, group),
      size: size,
    );
  }
}

/// The list inside the team switcher sheet or dropdown (SPEC §5.2).
class TeamSwitcherList extends ConsumerWidget {
  const new({
    required this.currentGroupId,
    required this.onSelect,
    required this.onCreateTeam,
    required this.onJoinTeam,
    super.key,
  });

  final GroupId? currentGroupId;
  final ValueChanged<GroupId> onSelect;

  /// Opens Create a team (the caller closes the sheet first).
  final VoidCallback onCreateTeam;

  /// Opens Join a team (the caller closes the sheet first).
  final VoidCallback onJoinTeam;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final teams = ref.watch(myTeamsProvider).value ?? const <MyTeam>[];
    final active = teams.where((t) => !t.group.isArchived).toList();
    final archived = teams.where((t) => t.group.isArchived).toList();
    final now = DateTime.now();

    Widget tile(MyTeam t) {
      final selected = t.group.id == currentGroupId;
      return ListTile(
        selected: selected,
        leading: GroupBadge(group: t.group, size: 40),
        // Team names in Fredoka, as names are (Gumdrop Pop design §2).
        titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: selected ? Theme.of(context).colorScheme.primary : null,
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                t.group.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: Space.xs),
            Icon(
              AppIcons.sport(t.group.sport),
              size: 16,
              semanticLabel: sportName(l10n, t.group.sport),
            ),
          ],
        ),

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
              Icon(
                AppIcons.muted,
                size: 18,
                semanticLabel: l10n.teamMutedLabel,
              ),
            // The unread count, 1 to 99+, gray for muted teams (CHAT-9).
            if (t.hasUnread)
              Padding(
                padding: const EdgeInsets.only(left: Space.sm),
                child: switch (ref.watch(unreadCountProvider(t.group.id))) {
                  AsyncData(:final value) when value > 0 => Badge(
                    label: Text(unreadLabel(value)),
                    backgroundColor: t.membership.isMutedAt(now)
                        ? Theme.of(context).colorScheme.outline
                        : null,
                  ),
                  _ => Badge(
                    smallSize: 10,
                    backgroundColor: t.membership.isMutedAt(now)
                        ? Theme.of(context).colorScheme.outline
                        : null,
                  ),
                },
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
            style: Theme.of(context).textTheme.titleLarge,
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
          onTap: onJoinTeam,
        ),
        ListTile(
          leading: const Icon(AppIcons.add),
          title: Text(l10n.createTeam),
          onTap: onCreateTeam,
        ),
        const SizedBox(height: Space.lg),
      ],
    );
  }
}
