import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/focus_ring_ink.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/features/admin/admin.dart';
import 'package:battleplan/features/chat/application/providers.dart';
import 'package:battleplan/features/chat/chat.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/my_team.dart';
import 'package:battleplan/features/groups/presentation/color_scheme_screen.dart';
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

    final joinOrCreate = PageRows(
      children: [
        PageRow(
          icon: AppIcons.qr,
          title: l10n.joinTeam,
          onTap: () => unawaited(context.push('/join')),
        ),
        PageRow(
          icon: AppIcons.add,
          title: l10n.createTeam,
          onTap: () => unawaited(context.push(createPath(GroupKind.team))),
        ),
        // A basic group (TEAM-14), below teams.
        PageRow(
          icon: AppIcons.group,
          title: l10n.createGroupTitle,
          onTap: () => unawaited(context.push(createPath(GroupKind.group))),
        ),
      ],
    );

    // My default color scheme (SET-2): Teams, Profile, and every team I
    // haven't picked for.
    final defaultScheme = ref.watch(defaultSchemeControllerProvider);
    final schemeSection = _SchemeSection(
      child: SchemeRow(
        scheme: defaultScheme,
        title: l10n.defaultColorScheme,
        subtitle: l10n.defaultColorSchemeSubtitle(defaultScheme.label(l10n)),
        onTap: () => unawaited(context.push('/teams/scheme')),
      ),
    );

    final Widget body;
    if (teams.isLoading && !teams.hasValue) {
      body = const SkeletonList();
    } else if (mine.isEmpty) {
      body = _Welcome(joinOrCreate: joinOrCreate, schemes: schemeSection);
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, Space.xl),
        children: [
          for (final t in active) ...[
            _TeamCard(team: t, onTap: () => open(t.group.id)),
            const SizedBox(height: 12),
          ],
          if (archived.isNotEmpty)
            _Archived(
              count: archived.length,
              children: [
                for (final t in archived) ...[
                  _TeamCard(team: t, onTap: () => open(t.group.id)),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: joinOrCreate,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: schemeSection,
          ),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // The page's name where a team's is, and the inbox and
            // notifications, which cover every team; before them, the
            // Admin panel for super admins.
            TopLevelBar(
              title: l10n.tabTeams,
              actions: const [
                AdminPanelButton(),
                MessagesButton(),
                NotificationBell(),
              ],
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

/// My archived teams, under a plain row that opens and closes them.
class _Archived extends StatefulWidget {
  const new({required this.count, required this.children});

  final int count;
  final List<Widget> children;

  @override
  State<_Archived> createState() => _ArchivedState();
}

class _ArchivedState extends State<_Archived> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // On the rows' 20 px gutter, like Join and Create below; the cards
        // reach 4 px past it.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          // On the row's own node, which PageRow merges.
          child: MergeSemantics(
            child: Semantics(
              expanded: _open,
              child: PageRow(
                icon: AppIcons.archive,
                title: l10n.archivedTeams,
                subtitle: '${widget.count}',
                onTap: () => setState(() => _open = !_open),
                trailing: Icon(
                  _open ? AppIcons.expandLess : AppIcons.expand,
                  size: 20,
                  weight: 700,
                  color: c.textMutedOnPage,
                ),
              ),
            ),
          ),
        ),
        if (_open) ...[const SizedBox(height: 8), ...widget.children],
      ],
    );
  }
}

/// One of my teams (SPEC §5.1): an Open Field card with its badge, name
/// and kind, the last message, how many I haven't read (a ring when the
/// team is muted, CHAT-9), and a chevron.
class _TeamCard extends ConsumerWidget {
  const new({required this.team, required this.onTap});

  final MyTeam team;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context).card;
    final style = GumdropStyle.of(context);
    final group = team.group;
    final muted = team.membership.isMutedAt(DateTime.now());
    final preview = group.lastMessagePreview;
    final count = team.hasUnread
        ? ref.watch(unreadCountProvider(group.id)).value
        : null;
    final kind = group.isGroup ? l10n.kindGroup : l10n.kindTeam;
    final Widget? unread = !team.hasUnread
        ? null
        : count != null && count > 0
        ? Container(
            // At least 21 tall, growing with the text size.
            constraints: const BoxConstraints(minWidth: 21, minHeight: 21),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: muted ? null : c.cherry.face,
              borderRadius: BorderRadius.circular(10.5),
              border: muted
                  ? Border.all(color: c.cardOutline, width: 1.5)
                  : null,
            ),
            child: Text(
              unreadLabel(count),
              style: style.label(
                TextStyle(
                  fontSize: 13,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: muted ? c.textMuted : c.ink,
                ),
              ),
            ),
          )
        : Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: muted ? c.textMuted : c.cherry.face,
              shape: BoxShape.circle,
            ),
          );
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: style.cardDecoration(
            c.surface,
            18,
            side: BorderSide(color: c.surfaceBorder, width: 2),
          ),
          child: FocusRingInk(
            onTap: onTap,
            radius: BorderRadius.circular(18),
            child: GumdropSurface(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Row(
                  children: [
                    // The card says the name.
                    ExcludeSemantics(child: GroupBadge(group: group, size: 48)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Flexible(
                                child: Text(
                                  group.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppFonts.body,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    height: 22 / 18,
                                    color: c.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                kind.toUpperCase(),
                                semanticsLabel: kind,
                                style: style.label(
                                  TextStyle(
                                    fontSize: 13,
                                    height: 16 / 13,
                                    letterSpacing: 13 * 0.1,
                                    fontWeight: FontWeight.w600,
                                    color: c.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (preview != null)
                            Text(
                              preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                height: 19 / 15,
                                letterSpacing: -0.2,
                                color: c.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (muted) ...[
                      Icon(
                        AppIcons.muted,
                        size: 18,
                        color: c.textMuted,
                        semanticLabel: l10n.teamMutedLabel,
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (unread != null) ...[unread, const SizedBox(width: 8)],
                    Icon(
                      AppIcons.chevronRight,
                      size: 20,
                      weight: 700,
                      color: c.textMuted,
                    ),
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

/// No team yet (SPEC §5.1): what the app is for, then Join a team and
/// Create a team.
class _Welcome extends StatelessWidget {
  const new({required this.joinOrCreate, required this.schemes});

  final Widget joinOrCreate;
  final Widget schemes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, Space.xl, 20, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(AppIcons.group, size: 64, color: c.textMutedOnPage),
          const SizedBox(height: Space.lg),
          Text(
            l10n.welcomeTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 25),
          ),
          const SizedBox(height: Space.md),
          Text(
            l10n.welcomeBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: c.textMutedOnPage,
            ),
          ),
          const SizedBox(height: Space.xl),
          joinOrCreate,
          schemes,
        ],
      ),
    );
  }
}

/// The Color scheme section under the rows: its caps label, then the
/// Default color scheme row between hairlines.
class _SchemeSection extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final label = l10n.colorSchemeSection;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        SectionLabel(label),
        const SizedBox(height: 10),
        Container(height: 1, color: c.divider),
        child,
        Container(height: 1, color: c.divider),
      ],
    );
  }
}
