import 'dart:async';

import 'package:battleplan/app/app_services.dart';
import 'package:battleplan/app/home_shell.dart';
import 'package:battleplan/app/update_required_screen.dart';
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/links.dart';
import 'package:battleplan/core/version.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/core/widgets/panel_page.dart';
import 'package:battleplan/features/admin/presentation/admin_panel.dart'
    deferred as admin_panel;
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/presentation/activate_screen.dart';
import 'package:battleplan/features/auth/presentation/disabled_screen.dart';
import 'package:battleplan/features/auth/presentation/email_sign_in_screen.dart';
import 'package:battleplan/features/auth/presentation/link_method_screens.dart';
import 'package:battleplan/features/auth/presentation/profile_screen.dart';
import 'package:battleplan/features/auth/presentation/reset_password_screen.dart';
import 'package:battleplan/features/auth/presentation/setup_screen.dart';
import 'package:battleplan/features/auth/presentation/sign_in_methods_screen.dart';
import 'package:battleplan/features/auth/presentation/sign_in_screen.dart';
import 'package:battleplan/features/chat/presentation/chat_screen.dart';
import 'package:battleplan/features/chat/presentation/direct_chat_screen.dart';
import 'package:battleplan/features/chat/presentation/messages_screen.dart';
import 'package:battleplan/features/chat/presentation/team_photos_screen.dart';
import 'package:battleplan/features/documents/presentation/document_screen.dart';
import 'package:battleplan/features/documents/presentation/documents_screen.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/presentation/add_members_screen.dart';
import 'package:battleplan/features/groups/presentation/create_team_screen.dart';
import 'package:battleplan/features/groups/presentation/email_invites_screen.dart';
import 'package:battleplan/features/groups/presentation/enter_code_screen.dart';
import 'package:battleplan/features/groups/presentation/invite_screen.dart';
import 'package:battleplan/features/groups/presentation/join_screen.dart';
import 'package:battleplan/features/groups/presentation/media_screen.dart';
import 'package:battleplan/features/groups/presentation/person_screen.dart';
import 'package:battleplan/features/groups/presentation/roster_screen.dart';
import 'package:battleplan/features/groups/presentation/team_colors.dart';
import 'package:battleplan/features/groups/presentation/team_info_screen.dart';
import 'package:battleplan/features/groups/presentation/team_settings_screen.dart';
import 'package:battleplan/features/groups/presentation/team_shell.dart';
import 'package:battleplan/features/groups/presentation/teams_screen.dart';
import 'package:battleplan/features/imports/presentation/import_screen.dart';
import 'package:battleplan/features/notifications/presentation/notification_settings_screen.dart';
import 'package:battleplan/features/notifications/presentation/notifications_screen.dart';
import 'package:battleplan/features/notifications/presentation/push_test_screen.dart';
import 'package:battleplan/features/notifications/presentation/team_notifications_screen.dart';
import 'package:battleplan/features/players/presentation/add_players_screen.dart';
import 'package:battleplan/features/players/presentation/player_card_screen.dart';
import 'package:battleplan/features/players/presentation/player_details_screen.dart';
import 'package:battleplan/features/players/presentation/player_rsvp_history_screen.dart';
import 'package:battleplan/features/players/presentation/who_are_you_screen.dart';
import 'package:battleplan/features/plays/presentation/play_routes.dart';
import 'package:battleplan/features/plays/presentation/play_screen.dart';
import 'package:battleplan/features/plays/presentation/plays_screen.dart';
import 'package:battleplan/features/safety/presentation/blocked_people_screen.dart';
import 'package:battleplan/features/safety/presentation/reports_screen.dart';
import 'package:battleplan/features/schedule/domain/recurrence.dart';
import 'package:battleplan/features/schedule/presentation/calendar_link_screen.dart';
import 'package:battleplan/features/schedule/presentation/event_assignments.dart';
import 'package:battleplan/features/schedule/presentation/event_details_screen.dart';
import 'package:battleplan/features/schedule/presentation/event_form_screen.dart';
import 'package:battleplan/features/schedule/presentation/schedule_screen.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:battleplan/features/settings/presentation/settings_screen.dart';
import 'package:battleplan/features/settings/presentation/themes_screen.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

/// `/emaillogin`, keeping [uri]'s query (where to go back to, `mode`).
String _emailLogin(Uri uri) => Uri(
  path: '/emaillogin',
  queryParameters: uri.queryParameters.isEmpty ? null : uri.queryParameters,
).toString();

/// Paths that don't need a signed-in user.
const _publicPaths = {
  '/sign-in',
  // Email and password, and emailed sign-in links (AUTH-2): not linked
  // from the sign-in screen, for the people who need it.
  '/emaillogin',
  // The website's "Sign up, it's free!" (WEB-1).
  '/sign-up',
  '/reset-password',
  '/update-required',
  '/activate',
  // A refused sign-in for a disabled account (AUTH-11).
  '/disabled',
  // Firebase's email-link path; App Links deliver it to the app.
  '/__/auth/links',
};

/// go_router with its guards (ARCH §5.4). The same paths serve web URLs,
/// Universal/App Links, and notification taps.
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  // Re-run redirects when sign-in or memberships change.
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(authUserProvider, (_, _) => refresh.value++)
    ..listen(myMembershipsProvider, (_, _) => refresh.value++)
    ..listen(myProfileProvider, (_, _) => refresh.value++)
    ..listen(myTeamsProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  final env = ref.read(appEnvProvider);

  // The top navigator: event pages cover the tabs. One per router, so a
  // new router (a new sign-in in tests) never shares it.
  final rootKey = GlobalKey<NavigatorState>();

  // Whether anyone has signed in since the app started, to tell signing
  // out from arriving signed out.
  var signedInBefore = false;

  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      // Universal Links and App Links for /app/... arrive with the prefix the
      // web app's base href removes in browsers (D40).
      final unprefixed = stripAppPrefix(state.uri);
      if (unprefixed != null) return unprefixed.toString();
      final path = state.uri.path;
      // Email sign-in's old address, from links already sent (AUTH-2).
      if (path == '/sign-in/email') return _emailLogin(state.uri);

      final remote = ref.read(remoteConfigProvider);
      final tooOld =
          compareVersions(
            ref.read(appVersionProvider),
            remote.minSupportedVersion,
          ) <
          0;
      if (tooOld) return path == '/update-required' ? null : '/update-required';

      final auth = ref.read(authUserProvider);
      if (auth.isLoading && !auth.hasValue) return null;
      final user = auth.value;

      if (user == null) {
        // Invite links work signed out (ARCH §5.4).
        if (_publicPaths.contains(path) || path.startsWith('/join')) {
          return null;
        }
        // Signing out starts over at sign-in, not back where they were
        // (Settings, say): whoever signs in next may be someone else. A
        // link opened on arriving signed out goes on there after signing
        // in.
        if (signedInBefore) return '/sign-in';
        final from = state.uri.toString();
        return from == '/'
            ? '/sign-in'
            : '/sign-in?from=${Uri.encodeComponent(from)}';
      }

      signedInBefore = true;
      if (path.startsWith('/sign-in') ||
          path == '/sign-up' ||
          path == '/emaillogin') {
        return state.uri.queryParameters['from'] ?? '/';
      }
      if (path == '/activate' || path == '/__/auth/links') {
        // A fresh sign-in by emailed link (AUTH-7) finishes there while
        // signed in: the app sent it to this account's address.
        final pending = ref.read(localPrefsRepositoryProvider);
        final reauth =
            pending.pendingSignInEmail?.toLowerCase() ==
            user.email?.toLowerCase();
        return reauth ? null : '/';
      }
      // Disabled accounts see only the disabled screen (AUTH-11).
      final disabled =
          ref.read(myProfileProvider).value?.status == UserStatus.disabled;
      if (disabled) return path == '/disabled' ? null : '/disabled';
      if (path == '/disabled') return '/';

      // AUTH-7: the emailed link proved the email after Google (or Apple,
      // where it's on) found an existing account; offer to finish linking
      // the method they tried.
      final pendingLink = ref.read(localPrefsRepositoryProvider).pendingLink;
      final linkable = switch (pendingLink?.providerId) {
        'google.com' => true,
        'apple.com' => env.appleSignIn,
        _ => false,
      };
      final finishLink =
          linkable &&
          pendingLink?.email.toLowerCase() == user.email?.toLowerCase();
      if (finishLink) return path == '/finish-link' ? null : '/finish-link';
      if (path == '/finish-link') return '/';

      // AUTH-6: an added account chooses how to sign in from now on, right
      // after its setup link signed it in.
      final chooseSignIn =
          ref.read(myProfileProvider).value?.chooseSignIn ?? false;
      if (chooseSignIn) {
        return path == '/choose-sign-in' ? null : '/choose-sign-in';
      }
      if (path == '/choose-sign-in') return '/';

      // First-run setup (AUTH-5) comes before anything else, also for an
      // account the server hasn't made a profile for yet: Continue makes it
      // with the answers (ensureUserProfile), so a first request that sits
      // on a phone for minutes can't let anyone into the app, or make a
      // team, before the Terms and the 18+ confirmation. While the profile
      // is still loading (it can hold the last account's for a moment),
      // nothing is decided.
      final profileState = ref.read(myProfileProvider);
      final profile = profileState.value;
      final needsSetup =
          !profileState.isLoading &&
          profileState.hasValue &&
          (profile?.needsSetup ?? true);
      // A new account on its way somewhere (an invite link, INV-5 step 2)
      // goes there after setup.
      if (needsSetup && path != '/setup') {
        return path == '/'
            ? '/setup'
            : '/setup?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (!needsSetup && path == '/setup') {
        return state.uri.queryParameters['from'] ?? '/';
      }

      if (path.startsWith('/admin') && !user.isSuperAdmin) return '/';

      if (path == '/' || path == '/welcome') {
        // Wait for this user's memberships; right after sign-in the provider
        // still holds the signed-out empty list while it reloads.
        final memberships = ref.read(myMembershipsProvider);
        if (!memberships.hasValue || memberships.isLoading) return null;
        final list = memberships.value!;
        // Teams welcomes someone with no team yet (SPEC §5.1) at
        // `/welcome`, which goes on to a team once there is one: one just
        // joined, or mine arriving a moment late.
        if (path == '/welcome') return list.isEmpty ? null : '/';
        if (list.isEmpty) return '/welcome';
        // Back where I was: Teams, or a team's tab.
        final last = ref.read(localPrefsRepositoryProvider).lastTeamRoute;
        if (last == '/teams') return last;
        final lastGroup = last?.split('/').elementAtOrNull(2);
        if (last != null && list.any((m) => m.groupId.value == lastGroup)) {
          // Only a team its members can read: a suspended one (ADMIN-3)
          // would hold them on its notice, so pick another below.
          final g = ref.read(groupProvider(GroupId(lastGroup!)));
          if (g.isLoading && !g.hasValue) return null;
          if (g.value != null) return last;
        }
        // Otherwise the team with the most recent activity.
        if (list.any((m) => ref.read(groupProvider(m.groupId)).isLoading)) {
          return null;
        }
        // When every team is suspended, the first one's notice offers
        // Settings, Sign out, and joining or creating a team.
        final teams = ref.read(myTeamsProvider).value ?? const [];
        final id = teams.isNotEmpty ? teams.first.group.id : list.first.groupId;
        return '/g/${id.value}/chat';
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: EmptyState(
        icon: AppIcons.error,
        message: AppLocalizations.of(context).notFoundTitle,
        actionLabel: AppLocalizations.of(context).goToMyTeams,
        onAction: () => context.go('/teams'),
      ),
    ),
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
      ),
      GoRoute(
        path: '/sign-in',
        // Email only against the emulators, for the seeded accounts.
        builder: (_, _) => SignInScreen(
          emailButton: env.useEmulators,
          appleEnabled: env.appleSignIn,
        ),
        routes: [
          GoRoute(
            path: 'email',
            redirect: (_, state) => _emailLogin(state.uri),
          ),
        ],
      ),
      GoRoute(
        path: '/emaillogin',
        builder: (_, state) => EmailSignInScreen(
          showEmulatorHint: env.useEmulators,
          createAccount: state.uri.queryParameters['mode'] == 'create',
        ),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (_, _) => SignInScreen(
          signUp: true,
          emailButton: env.useEmulators,
          appleEnabled: env.appleSignIn,
        ),
      ),
      GoRoute(path: '/setup', builder: (_, _) => const SetupScreen()),
      GoRoute(path: '/disabled', builder: (_, _) => const DisabledScreen()),
      GoRoute(
        path: '/choose-sign-in',
        builder: (_, _) => ChooseSignInScreen(appleEnabled: env.appleSignIn),
      ),
      GoRoute(
        path: '/finish-link',
        builder: (_, _) => FinishLinkScreen(appleEnabled: env.appleSignIn),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) => ResetPasswordScreen(
          initialEmail: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: '/update-required',
        builder: (_, _) => const UpdateRequiredScreen(),
      ),
      for (final path in ['/activate', '/__/auth/links'])
        GoRoute(
          path: path,
          builder: (_, state) => ActivateScreen(link: state.uri),
        ),
      GoRoute(path: '/join', builder: (_, _) => const EnterCodeScreen()),
      GoRoute(
        path: '/join/:code',
        builder: (_, state) => JoinScreen(
          code: state.pathParameters['code']!,
          autoJoin: state.uri.queryParameters['join'] == '1',
        ),
      ),
      // The top of the app (SPEC §5.1): Teams, which a team's back arrow
      // comes to, and Profile, switching in place as tabs do. Teams is also
      // the welcome for someone with no team yet.
      GoRoute(
        path: '/welcome',
        pageBuilder: (_, state) => NoTransitionPage(
          key: state.pageKey,
          child: const HomeShell(tab: 0, child: TeamsScreen()),
        ),
      ),
      GoRoute(
        path: '/teams',
        pageBuilder: (_, state) => NoTransitionPage(
          key: state.pageKey,
          child: const HomeShell(tab: 0, child: TeamsScreen()),
        ),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (_, state) => NoTransitionPage(
          key: state.pageKey,
          child: const HomeShell(tab: 1, child: ProfileScreen()),
        ),
      ),
      // The themes, from Profile (SET-2).
      GoRoute(
        path: '/themes',
        pageBuilder: (_, state) =>
            PanelPage(key: state.pageKey, child: const ThemesScreen()),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      // Messages: direct conversations (CHAT-19), one of them, and one
      // opened at a message from a notification (NOTIF-6). Siblings rather
      // than children, so opening a conversation from a profile goes back
      // to the profile, and a jump doesn't stack a second copy of it.
      GoRoute(path: '/messages', builder: (_, _) => const MessagesScreen()),
      GoRoute(
        path: '/messages/:groupId',
        builder: (_, state) => DirectChatScreen(
          key: ValueKey('dm-${state.pathParameters['groupId']}'),
          groupId: GroupId(state.pathParameters['groupId']!),
        ),
      ),
      GoRoute(
        path: '/messages/:groupId/m/:messageId',
        builder: (_, state) => DirectChatScreen(
          key: ValueKey('dm-${state.pathParameters['groupId']}'),
          groupId: GroupId(state.pathParameters['groupId']!),
          initialMessageId: state.pathParameters['messageId'],
        ),
      ),
      // A person's page (TEAM-15); `?team=` is the team it was opened from.
      GoRoute(
        path: '/people/:uid',
        pageBuilder: (_, state) => PanelPage(
          key: state.pageKey,
          child: PersonScreen(
            uid: UserId(state.pathParameters['uid']!),
            fromTeam: switch (state.uri.queryParameters['team']) {
              final id? when id.isNotEmpty => GroupId(id),
              _ => null,
            },
          ),
        ),
      ),
      GoRoute(
        path: '/settings',
        // Settings, event details, and member cards open as dialogs on
        // wide screens (SPEC §5.5).
        pageBuilder: (_, state) => PanelPage(
          key: state.pageKey,
          child: SettingsScreen(
            appBuild: ref.read(appBuildProvider),
            showDevTools: !env.isProd,
          ),
        ),
        routes: [
          // The photo and name moved to Profile (SET-1).
          GoRoute(path: 'profile', redirect: (_, _) => '/profile'),
          GoRoute(
            path: 'sign-in-methods',
            pageBuilder: (_, state) => PanelPage(
              key: state.pageKey,
              child: SignInMethodsScreen(appleEnabled: env.appleSignIn),
            ),
          ),
          GoRoute(
            path: 'blocked',
            pageBuilder: (_, state) => PanelPage(
              key: state.pageKey,
              child: const BlockedPeopleScreen(),
            ),
          ),
          GoRoute(
            path: 'notifications',
            pageBuilder: (_, state) => PanelPage(
              key: state.pageKey,
              child: const NotificationSettingsScreen(),
            ),
          ),
          if (!env.isProd)
            GoRoute(
              path: 'push-test',
              builder: (_, _) => const PushTestScreen(),
            ),
        ],
      ),
      // The God admin panel (ADMIN), for super admins (the redirect above).
      GoRoute(
        path: '/admin',
        builder: (_, _) =>
            _AdminPanel(() => admin_panel.AdminDashboardScreen()),
        routes: [
          GoRoute(
            path: 'teams',
            builder: (_, _) =>
                _AdminPanel(() => admin_panel.AdminTeamsScreen()),
            routes: [
              GoRoute(
                path: ':groupId',
                builder: (_, state) => _AdminPanel(
                  () => admin_panel.AdminTeamScreen(
                    groupId: GroupId(state.pathParameters['groupId']!),
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'users',
            builder: (_, _) =>
                _AdminPanel(() => admin_panel.AdminUsersScreen()),
            routes: [
              GoRoute(
                path: ':uid',
                builder: (_, state) => _AdminPanel(
                  () => admin_panel.AdminUserScreen(
                    uid: UserId(state.pathParameters['uid']!),
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'reports',
            builder: (_, _) =>
                _AdminPanel(() => admin_panel.AdminReportsScreen()),
          ),
          GoRoute(
            path: 'audit',
            builder: (_, state) => _AdminPanel(
              () => admin_panel.AdminAuditScreen(
                actorId: state.uri.queryParameters['actor'],
                groupId: state.uri.queryParameters['group'],
              ),
            ),
          ),
          GoRoute(
            path: 'settings',
            builder: (_, _) =>
                _AdminPanel(() => admin_panel.PlatformSettingsScreen()),
          ),
        ],
      ),
      GoRoute(path: '/g/new', builder: (_, _) => const CreateTeamScreen()),
      GoRoute(
        path: '/g/:groupId',
        redirect: (_, state) => state.uri.pathSegments.length == 2
            ? '/g/${state.pathParameters['groupId']}/chat'
            : null,
        routes: _inTeamColors([
          // The Documents tab was `docs` before M7; a device may still
          // remember that as its last tab.
          GoRoute(
            path: 'docs',
            redirect: (_, state) =>
                '/g/${state.pathParameters['groupId']}/documents',
          ),
          GoRoute(
            path: 'invite',
            builder: (_, state) => InviteScreen(
              groupId: GroupId(state.pathParameters['groupId']!),
            ),
            routes: [
              GoRoute(
                path: 'email',
                builder: (_, state) => EmailInvitesScreen(
                  groupId: GroupId(state.pathParameters['groupId']!),
                ),
              ),
            ],
          ),
          // Team info, from the ⓘ in the team's header (SPEC §5.2).
          GoRoute(
            path: 'info',
            pageBuilder: (_, state) => PanelPage(
              key: state.pageKey,
              child: TeamInfoScreen(
                groupId: GroupId(state.pathParameters['groupId']!),
              ),
            ),
          ),
          // Team admin (TEAM-5); its path is still `settings`.
          GoRoute(
            path: 'settings',
            pageBuilder: (_, state) => PanelPage(
              key: state.pageKey,
              child: TeamSettingsScreen(
                groupId: GroupId(state.pathParameters['groupId']!),
                appBuild: ref.read(appBuildProvider),
              ),
            ),
          ),
          GoRoute(
            path: 'media',
            builder: (_, state) =>
                MediaScreen(groupId: GroupId(state.pathParameters['groupId']!)),
          ),
          GoRoute(
            path: 'roster',
            builder: (_, state) => RosterScreen(
              groupId: GroupId(state.pathParameters['groupId']!),
            ),
            routes: [
              GoRoute(
                path: 'players/:playerId',
                pageBuilder: (_, state) => PanelPage(
                  key: state.pageKey,
                  child: PlayerCardScreen(
                    groupId: GroupId(state.pathParameters['groupId']!),
                    playerId: PlayerId(state.pathParameters['playerId']!),
                  ),
                ),
                routes: [
                  // The player's RSVP history (PLAYER-11).
                  GoRoute(
                    path: 'history',
                    pageBuilder: (_, state) => PanelPage(
                      key: state.pageKey,
                      child: PlayerRsvpHistoryScreen(
                        groupId: GroupId(state.pathParameters['groupId']!),
                        playerId: PlayerId(state.pathParameters['playerId']!),
                      ),
                    ),
                  ),
                  // The player's details form (PLAYER-12).
                  GoRoute(
                    path: 'details',
                    pageBuilder: (_, state) => PanelPage(
                      key: state.pageKey,
                      child: PlayerDetailsRoute(
                        groupId: GroupId(state.pathParameters['groupId']!),
                        playerId: PlayerId(state.pathParameters['playerId']!),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'members/add',
            builder: (_, state) => AddMembersScreen(
              groupId: GroupId(state.pathParameters['groupId']!),
            ),
          ),
          GoRoute(
            path: 'reports',
            builder: (_, state) => ReportsScreen(
              groupId: GroupId(state.pathParameters['groupId']!),
            ),
          ),
          // Bringing events over from another app (SPEC §6.15).
          GoRoute(
            path: 'import',
            builder: (_, state) => ImportScreen(
              groupId: GroupId(state.pathParameters['groupId']!),
            ),
          ),
          GoRoute(
            path: 'notifications',
            pageBuilder: (_, state) => PanelPage(
              key: state.pageKey,
              child: TeamNotificationsScreen(
                groupId: GroupId(state.pathParameters['groupId']!),
              ),
            ),
          ),
          // A calendar link that keeps the schedule in sync (SCHED-11).
          GoRoute(
            path: 'calendar',
            pageBuilder: (_, state) => PanelPage(
              key: state.pageKey,
              child: CalendarLinkScreen(
                groupId: GroupId(state.pathParameters['groupId']!),
              ),
            ),
          ),
          GoRoute(
            path: 'who',
            builder: (_, state) => WhoAreYouScreen(
              groupId: GroupId(state.pathParameters['groupId']!),
            ),
          ),
          GoRoute(
            path: 'players/add',
            builder: (_, state) => AddPlayersScreen(
              groupId: GroupId(state.pathParameters['groupId']!),
            ),
          ),
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => TeamShell(
              groupId: GroupId(state.pathParameters['groupId']!),
              navigationShell: shell,
              // Deeper than the tab, as Saved plays and a play are; a
              // message opened from a notification is the chat itself.
              inTab: switch (state.uri.pathSegments) {
                [_, _, 'chat', 'm', ...] => false,
                final s => s.length > 3,
              },
            ),
            branches: [
              for (final tab in teamTabs)
                StatefulShellBranch(
                  routes: _inTeamColors([
                    GoRoute(
                      path: tab,
                      builder: (_, state) {
                        final id = GroupId(state.pathParameters['groupId']!);
                        return switch (tab) {
                          // Keyed by team: the tab's page is the same for
                          // every team, and a new team needs a fresh chat
                          // state, opened at its own first unread message.
                          'chat' => ChatScreen(
                            key: ValueKey('chat-${id.value}'),
                            groupId: id,
                          ),
                          'schedule' => ScheduleScreen(groupId: id),
                          'documents' => DocumentsScreen(groupId: id),
                          _ => PlaysRoute(groupId: id),
                        };
                      },
                      // New event (`?from=<id>` duplicates, SCHED-3), an
                      // event (SCHED-4; notification taps land here), and
                      // its edit form (`?scope=this|following`, SCHED-6).
                      // They cover the tabs.
                      routes: [
                        if (tab == 'schedule') ...[
                          GoRoute(
                            path: 'new',
                            parentNavigatorKey: rootKey,
                            pageBuilder: (_, state) {
                              final from = state.uri.queryParameters['from'];
                              return PanelPage(
                                key: state.pageKey,
                                child: EventFormRoute(
                                  groupId: GroupId(
                                    state.pathParameters['groupId']!,
                                  ),
                                  fromEventId: from == null
                                      ? null
                                      : EventId(from),
                                ),
                              );
                            },
                          ),
                          GoRoute(
                            path: 'e/:eventId',
                            parentNavigatorKey: rootKey,
                            pageBuilder: (_, state) => PanelPage(
                              key: state.pageKey,
                              child: EventDetailsScreen(
                                groupId: GroupId(
                                  state.pathParameters['groupId']!,
                                ),
                                eventId: EventId(
                                  state.pathParameters['eventId']!,
                                ),
                              ),
                            ),
                            routes: [
                              // The event's assignments (SCHED-15).
                              GoRoute(
                                path: 'assignments',
                                parentNavigatorKey: rootKey,
                                pageBuilder: (_, state) => PanelPage(
                                  key: state.pageKey,
                                  child: EventAssignmentsScreen(
                                    groupId: GroupId(
                                      state.pathParameters['groupId']!,
                                    ),
                                    eventId: EventId(
                                      state.pathParameters['eventId']!,
                                    ),
                                  ),
                                ),
                              ),
                              GoRoute(
                                path: 'edit',
                                parentNavigatorKey: rootKey,
                                pageBuilder: (_, state) => PanelPage(
                                  key: state.pageKey,
                                  child: EventFormRoute(
                                    groupId: GroupId(
                                      state.pathParameters['groupId']!,
                                    ),
                                    eventId: EventId(
                                      state.pathParameters['eventId']!,
                                    ),
                                    scope: switch (state
                                        .uri
                                        .queryParameters['scope']) {
                                      'following' => SeriesScope.following,
                                      'this' => SeriesScope.thisEvent,
                                      _ => null,
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (tab == 'plays') ...[
                          GoRoute(
                            path: 'saved',
                            builder: (_, state) => SavedPlaysScreen(
                              groupId: GroupId(
                                state.pathParameters['groupId']!,
                              ),
                            ),
                          ),
                          GoRoute(
                            path: ':playId',
                            builder: (_, state) => PlayScreen(
                              groupId: GroupId(
                                state.pathParameters['groupId']!,
                              ),
                              playId: PlayId(state.pathParameters['playId']!),
                            ),
                            routes: [
                              GoRoute(
                                path: 'edit',
                                builder: (_, state) => EditPlayRoute(
                                  groupId: GroupId(
                                    state.pathParameters['groupId']!,
                                  ),
                                  playId: PlayId(
                                    state.pathParameters['playId']!,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        // A document (DOC-4; notification taps land
                        // here), and Photos, every photo from the chat
                        // (DOC-7), covering the tabs.
                        if (tab == 'documents') ...[
                          GoRoute(
                            path: 'd/:docId',
                            parentNavigatorKey: rootKey,
                            builder: (_, state) => DocumentScreen(
                              groupId: GroupId(
                                state.pathParameters['groupId']!,
                              ),
                              docId: DocumentId(state.pathParameters['docId']!),
                            ),
                          ),
                          GoRoute(
                            path: 'photos',
                            parentNavigatorKey: rootKey,
                            pageBuilder: (_, state) => PanelPage(
                              key: state.pageKey,
                              child: TeamPhotosScreen(
                                groupId: GroupId(
                                  state.pathParameters['groupId']!,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // A message from a notification tap (NOTIF-6): the
                    // chat, scrolled to it. A sibling rather than a child,
                    // so it doesn't stack a second chat on the first.
                    if (tab == 'chat')
                      GoRoute(
                        path: 'chat/m/:messageId',
                        // Keyed by team: two teams' jump routes share one
                        // page, and a new team needs a fresh chat state.
                        builder: (_, state) => ChatScreen(
                          key: ValueKey(
                            'chat-${state.pathParameters['groupId']}',
                          ),
                          groupId: GroupId(state.pathParameters['groupId']!),
                          initialMessageId: state.pathParameters['messageId'],
                        ),
                      ),
                  ]),
                ),
            ],
          ),
        ]),
      ),
    ],
  );

  // Remember the last team and tab on this device (SPEC §5.2), or Teams
  // when that's where I am (Profile counts as Teams).
  router.routerDelegate.addListener(() {
    final path = router.routerDelegate.currentConfiguration.uri.path;
    if (path == '/teams' || path == '/profile') {
      unawaited(
        ref.read(localPrefsRepositoryProvider).setLastTeamRoute('/teams'),
      );
      return;
    }
    final segments = path.split('/');
    // A tab, or a message opened from a notification (/g/<id>/chat/m/<m>),
    // which remembers its team's chat tab.
    if (segments.length >= 4 &&
        segments[1] == 'g' &&
        teamTabs.contains(segments[3]) &&
        (segments.length == 4 || segments[4] == 'm')) {
      final route = segments.take(4).join('/');
      ref
          .read(lastTeamTabsProvider.notifier)
          .remember(GroupId(segments[2]), route);
      unawaited(ref.read(localPrefsRepositoryProvider).setLastTeamRoute(route));
    }
  });
  ref.onDispose(router.dispose);
  return router;
}

/// Loads the admin panel's code the first time it's opened, then shows
/// [page] (ARCH §5.6: deferred-loaded, so regular users never download
/// it). Native builds have it already; loading is instant there.
class _AdminPanel extends StatefulWidget {
  const new(this.page);

  final Widget Function() page;

  /// One download per app run, shared by every admin page.
  static Future<void>? _loading;
  static bool _loaded = false;

  @override
  State<_AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<_AdminPanel> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (_AdminPanel._loaded) return;
    unawaited(
      (_AdminPanel._loading ??= admin_panel.loadLibrary())
          .then((_) {
            _AdminPanel._loaded = true;
            if (mounted) setState(() {});
          })
          .catchError((Object e) {
            // A failed download can be tried again.
            _AdminPanel._loading = null;
            if (mounted) setState(() => _error = e);
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_AdminPanel._loaded) return widget.page();
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminPanel)),
      body: _error == null
          ? const Center(child: CircularProgressIndicator())
          : EmptyState(
              icon: AppIcons.error,
              message: l10n.loadError,
              actionLabel: l10n.retry,
              onAction: () {
                setState(() => _error = null);
                _load();
              },
            ),
    );
  }
}

/// [routes] and every route under them with their screens in the team's
/// colors (TEAM-1, TeamColors): the team's own pages, like its settings and
/// roster, and its event and document pages over the tabs. The tabs
/// themselves are inside the team shell, which tints itself.
List<RouteBase> _inTeamColors(List<RouteBase> routes) => [
  for (final route in routes)
    if (route is GoRoute) _inTeamColor(route) else route,
];

GoRoute _inTeamColor(GoRoute route) {
  Widget tinted(GoRouterState state, Widget child) => TeamColors(
    groupId: GroupId(state.pathParameters['groupId']!),
    child: child,
  );
  final builder = route.builder;
  final pageBuilder = route.pageBuilder;
  return GoRoute(
    path: route.path,
    name: route.name,
    parentNavigatorKey: route.parentNavigatorKey,
    redirect: route.redirect,
    metadata: route.metadata,
    onExit: route.onExit,
    caseSensitive: route.caseSensitive,
    builder: builder == null
        ? null
        : (context, state) => tinted(state, builder(context, state)),
    pageBuilder: pageBuilder == null
        ? null
        : (context, state) {
            final page = pageBuilder(context, state);
            return page is PanelPage
                ? PanelPage<Object?>(
                    key: page.key,
                    name: page.name,
                    arguments: page.arguments,
                    child: tinted(state, page.child),
                  )
                : page;
          },
    routes: _inTeamColors(route.routes),
  );
}
