import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/focus_ring_ink.dart';
import 'package:battleplan/core/widgets/team_badge.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/my_team.dart';
import 'package:battleplan/features/groups/presentation/create_team_screen.dart';
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
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
  const new({
    required this.group,
    this.size = 32,
    this.candy = false,
    super.key,
  });

  final Group? group;
  final double size;

  /// The candy finish, on the Teams cards ([TeamBadge.candy], #98).
  final bool candy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = group?.color;
    return TeamBadge(
      name: group?.name ?? '',
      color: color == null ? null : Color(color),
      imageUrl: teamLogoUrl(ref, group),
      size: size,
      candy: candy,
    );
  }
}

/// The list inside the team switcher sheet or dropdown (SPEC §5.2), in
/// the app's own rows (#25): "Your teams", each team a row with its badge,
/// name, and last message, the one I'm on marked with a coral check, then
/// the archived ones under a row that opens them, then Join and Create.
class TeamSwitcherList extends ConsumerWidget {
  const new({
    required this.currentGroupId,
    required this.onSelect,
    required this.onCreate,
    required this.onJoinTeam,
    super.key,
  });

  final GroupId? currentGroupId;
  final ValueChanged<GroupId> onSelect;

  /// Opens Create a Team or Create a Group (TEAM-14), [createPath] (the
  /// caller closes the sheet first).
  final ValueChanged<GroupKind> onCreate;

  /// Opens Join a Team or Group (the caller closes the sheet first).
  final VoidCallback onJoinTeam;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final teams = ref.watch(myTeamsProvider).value ?? const <MyTeam>[];
    final active = teams.where((t) => !t.group.isArchived).toList();
    final archived = teams.where((t) => t.group.isArchived).toList();

    Widget row(MyTeam t) => _TeamRow(
      team: t,
      current: t.group.id == currentGroupId,
      onTap: () => onSelect(t.group.id),
    );

    return ListView(
      shrinkWrap: true,
      // The rows 20 px from the edge, as on every page (SPEC §7.3).
      padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.lg),
      children: [
        PageHeading(l10n.teamSwitcherTitle),
        const SizedBox(height: 10),
        PageRows(
          children: [
            ...active.map(row),
            if (archived.isNotEmpty)
              _ArchivedRows(children: archived.map(row).toList()),
          ],
        ),
        const SizedBox(height: 18),
        // Join and Create, in the text color: none is the main action.
        SettingsCard(
          children: [
            SettingsRow(
              icon: AppIcons.qr,
              title: l10n.joinTeam,
              onTap: onJoinTeam,
            ),
            SettingsRow(
              icon: AppIcons.add,
              title: l10n.createTeam,
              onTap: () => onCreate(GroupKind.team),
            ),
            SettingsRow(
              icon: AppIcons.group,
              title: l10n.createGroupTitle,
              onTap: () => onCreate(GroupKind.group),
            ),
          ],
        ),
      ],
    );
  }
}

/// One team in the switcher (#25): at least 64 tall, its badge, its name
/// in the text color (never the groups' blue) with its sport's icon (a
/// group's own), and its last message. The one I'm on has a faint tint, a
/// bold name, and a coral check; unread is the coral count Teams shows
/// (gray for a muted team, CHAT-9), or a coral dot before the count loads.
/// Screen readers hear one sentence: "Thunder, Soccer, current team, 3
/// unread messages".
class _TeamRow extends ConsumerWidget {
  const new({required this.team, required this.current, required this.onTap});

  final MyTeam team;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final style = GumdropStyle.of(context);
    final text = c.onCard ? c.textPrimary : c.textOnPage;
    final quiet = c.onCard ? c.textMuted : c.textMutedOnPage;
    final group = team.group;
    final muted = team.membership.isMutedAt(DateTime.now());
    final count = team.hasUnread
        ? ref.watch(unreadCountProvider(group.id)).value
        : null;
    final kind = group.hasPlayers
        ? sportName(l10n, group.sport)
        : l10n.kindGroup;
    final preview = group.lastMessagePreview;
    final Widget? unread = !team.hasUnread
        ? null
        : count != null && count > 0
        ? Container(
            // At least 21 tall, growing with the text size, as on Teams.
            constraints: const BoxConstraints(minWidth: 21, minHeight: 21),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // Coral, as unread is (SPEC §7.2); gray for a muted team.
              color: muted ? null : c.you.face,
              borderRadius: BorderRadius.circular(10.5),
              border: muted ? Border.all(color: c.outline, width: 1.5) : null,
            ),
            child: Text(
              unreadLabel(count),
              style: style.label(
                TextStyle(
                  fontSize: 13,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: muted ? quiet : c.inkOn(c.you),
                ),
              ),
            ),
          )
        : Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: muted ? quiet : c.you.face,
              shape: BoxShape.circle,
            ),
          );
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: current,
        label: [
          group.name,
          kind,
          if (current) l10n.switcherCurrentTeam,
          if (muted) l10n.teamMutedLabel,
          if (count != null && count > 0) l10n.unreadCount(count),
        ].join(', '),
        excludeSemantics: true,
        child: Material(
          // The one I'm on, faintly tinted.
          color: current ? text.withValues(alpha: 0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: FocusRingInk(
            onTap: onTap,
            radius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Row(
                  children: [
                    GroupBadge(group: group, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  group.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  // stencil, as names are; bold for the
                                  // one I'm on.
                                  style: style.label(
                                    TextStyle(
                                      fontSize: 17,
                                      height: 22 / 17,
                                      fontWeight: current
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: text,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // A basic group's own icon (TEAM-14).
                              Icon(
                                group.hasPlayers
                                    ? AppIcons.sport(group.sport)
                                    : AppIcons.group,
                                size: 16,
                                color: quiet,
                              ),
                            ],
                          ),
                          if (preview != null)
                            Text(
                              preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontSize: 14,
                                    height: 19 / 14,
                                    fontWeight: FontWeight.w600,
                                    color: quiet,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (muted) ...[
                      Icon(AppIcons.muted, size: 18, color: quiet),
                      const SizedBox(width: 6),
                    ],
                    ?unread,
                    // The team I'm on: a coral check, not only a bolder
                    // name.
                    if (current) ...[
                      const SizedBox(width: 8),
                      Icon(
                        AppIcons.check,
                        size: 22,
                        weight: 700,
                        color: c.you.face,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The archived teams, last and closed (SPEC §5.2): a quiet row whose
/// chevron turns as it opens them, as Teams' Archived row does.
class _ArchivedRows extends StatefulWidget {
  const new({required this.children});

  final List<Widget> children;

  @override
  State<_ArchivedRows> createState() => _ArchivedRowsState();
}

class _ArchivedRowsState extends State<_ArchivedRows> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final quiet = c.onCard ? c.textMuted : c.textMutedOnPage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          child: PageRow(
            icon: AppIcons.archive,
            title: l10n.archivedTeams,
            chevron: false,
            trailing: AnimatedRotation(
              turns: _open ? 0.5 : 0,
              duration: Motion.of(context, Motion.fast),
              child: Icon(AppIcons.expand, size: 22, color: quiet),
            ),
            onTap: () => setState(() => _open = !_open),
          ),
        ),
        if (_open) PageRows(children: widget.children),
      ],
    );
  }
}

/// Where Create a Team or Create a Group (TEAM-14) opens.
String createPath(GroupKind kind) =>
    kind == GroupKind.group ? '/g/new?kind=group' : '/g/new';
