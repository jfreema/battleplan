import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/chat/chat.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/my_team.dart';
import 'package:battleplan/features/groups/presentation/create_team_screen.dart';
import 'package:battleplan/features/groups/presentation/gumdrop_rows.dart';
import 'package:battleplan/features/groups/presentation/team_switcher.dart';
import 'package:battleplan/features/notifications/notifications.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Teams at `/teams`, the top of the app (SPEC §5.1): every team I'm on as
/// a card, with its last message and unread count, then Join a team and
/// Create a team. With no team yet, it welcomes me and offers those two.
/// A team's back arrow comes here.
class TeamsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final teams = ref.watch(myTeamsProvider);
    final mine = teams.value ?? const <MyTeam>[];
    final active = mine.where((t) => !t.group.isArchived).toList();
    final archived = mine.where((t) => t.group.isArchived).toList();
    final width = MediaQuery.sizeOf(context).width;

    // Back where I was in that team, else its chat.
    void open(GroupId id) {
      final saved = ref.read(localPrefsRepositoryProvider).lastTeamRoute;
      context.go(
        ref.read(lastTeamTabsProvider)[id] ??
            (saved != null && saved.startsWith('/g/${id.value}/')
                ? saved
                : '/g/${id.value}/chat'),
      );
    }

    final joinOrCreate = SettingsCard(
      children: [
        SettingsRow(
          icon: AppIcons.qr,
          title: l10n.joinTeam,
          onTap: () => unawaited(context.push('/join')),
        ),
        SettingsRow(
          icon: AppIcons.add,
          title: l10n.createTeam,
          onTap: () => unawaited(context.push('/g/new')),
        ),
      ],
    );

    final Widget body;
    if (teams.isLoading && !teams.hasValue) {
      body = const SkeletonList();
    } else if (mine.isEmpty) {
      body = _Welcome(joinOrCreate: joinOrCreate);
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, Space.xl),
        children: [
          for (final t in active) ...[
            _TeamCard(team: t, onTap: () => open(t.group.id)),
            const SizedBox(height: 10),
          ],
          if (archived.isNotEmpty)
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              title: PageHeading(l10n.archivedTeams),
              children: [
                for (final t in archived) ...[
                  _TeamCard(team: t, onTap: () => open(t.group.id)),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          const SizedBox(height: Space.sm),
          joinOrCreate,
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // The page's name where a team's is, and the inbox and
            // notifications, which cover every team.
            Padding(
              padding: EdgeInsets.fromLTRB(
                Space.gutter(width),
                Space.xs,
                Space.gutter(width) - 5,
                Space.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Padding(
                        // Room for the heading's 4 px shadow.
                        padding: const EdgeInsets.only(right: 4, bottom: 4),
                        child: Text(
                          l10n.tabTeams,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                    ),
                  ),
                  const MessagesButton(),
                  const NotificationBell(),
                ],
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: body,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One of my teams (SPEC §5.2): its badge, name, and sport, the last
/// message, and how many I haven't read, gray when the team is muted
/// (CHAT-9).
class _TeamCard extends ConsumerWidget {
  const new({required this.team, required this.onTap});

  final MyTeam team;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context).card;
    final text = Theme.of(context).textTheme;
    final group = team.group;
    final muted = team.membership.isMutedAt(DateTime.now());
    final preview = group.lastMessagePreview;
    final count = team.hasUnread
        ? ref.watch(unreadCountProvider(group.id)).value
        : null;
    final badgeColor = muted ? Theme.of(context).colorScheme.outline : null;
    return SettingsPanel(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
        minTileHeight: 72,
        horizontalTitleGap: 12,
        leading: GroupBadge(group: group, size: 48),
        // Team names in Fredoka, as names are (Gumdrop Pop design §2).
        title: Row(
          children: [
            Flexible(
              child: Text(
                group.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleMedium?.copyWith(color: c.textPrimary),
              ),
            ),
            const SizedBox(width: Space.xs),
            Icon(
              // A basic group's own icon (TEAM-14).
              group.hasPlayers ? AppIcons.sport(group.sport) : AppIcons.group,
              size: 16,
              color: c.textMuted,
              semanticLabel: group.hasPlayers
                  ? sportName(l10n, group.sport)
                  : l10n.kindGroup,
            ),
          ],
        ),
        subtitle: preview == null
            ? null
            : Text(
                preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(color: c.textMuted),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (muted)
              Icon(
                AppIcons.muted,
                size: 18,
                color: c.textMuted,
                semanticLabel: l10n.teamMutedLabel,
              ),
            if (team.hasUnread)
              Padding(
                padding: const EdgeInsets.only(left: Space.sm),
                child: count != null && count > 0
                    ? Badge(
                        label: Text(unreadLabel(count)),
                        backgroundColor: badgeColor,
                      )
                    : Badge(smallSize: 10, backgroundColor: badgeColor),
              ),
            const SizedBox(width: Space.xs),
            Icon(
              AppIcons.chevronRight,
              size: 22,
              weight: 700,
              color: c.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// No team yet (SPEC §5.1): what the app is for, then Join a team and
/// Create a team.
class _Welcome extends StatelessWidget {
  const new({required this.joinOrCreate});

  final Widget joinOrCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, Space.xl, 16, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(AppIcons.group, size: 64),
          const SizedBox(height: Space.lg),
          Text(
            l10n.welcomeTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: Space.md),
          Text(
            l10n.welcomeBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: Space.xl),
          joinOrCreate,
        ],
      ),
    );
  }
}
