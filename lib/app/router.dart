import 'dart:async';

import 'package:battleplan/app/app_services.dart';
import 'package:battleplan/app/update_required_screen.dart';
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/version.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/features/admin/presentation/admin_screen.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/presentation/activate_screen.dart';
import 'package:battleplan/features/auth/presentation/disabled_screen.dart';
import 'package:battleplan/features/auth/presentation/email_sign_in_screen.dart';
import 'package:battleplan/features/auth/presentation/profile_screen.dart';
import 'package:battleplan/features/auth/presentation/reset_password_screen.dart';
import 'package:battleplan/features/auth/presentation/setup_screen.dart';
import 'package:battleplan/features/auth/presentation/sign_in_methods_screen.dart';
import 'package:battleplan/features/auth/presentation/sign_in_screen.dart';
import 'package:battleplan/features/chat/presentation/chat_screen.dart';
import 'package:battleplan/features/documents/presentation/documents_screen.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/presentation/add_members_screen.dart';
import 'package:battleplan/features/groups/presentation/create_team_screen.dart';
import 'package:battleplan/features/groups/presentation/enter_code_screen.dart';
import 'package:battleplan/features/groups/presentation/invite_screen.dart';
import 'package:battleplan/features/groups/presentation/join_screen.dart';
import 'package:battleplan/features/groups/presentation/roster_screen.dart';
import 'package:battleplan/features/groups/presentation/team_settings_screen.dart';
import 'package:battleplan/features/groups/presentation/team_shell.dart';
import 'package:battleplan/features/groups/presentation/welcome_screen.dart';
import 'package:battleplan/features/notifications/presentation/notifications_screen.dart';
import 'package:battleplan/features/notifications/presentation/push_test_screen.dart';
import 'package:battleplan/features/players/presentation/add_players_screen.dart';
import 'package:battleplan/features/players/presentation/player_card_screen.dart';
import 'package:battleplan/features/schedule/presentation/schedule_screen.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:battleplan/features/settings/presentation/settings_screen.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

/// Paths that don't need a signed-in user.
const _publicPaths = {
  '/sign-in',
  '/sign-in/email',
  '/reset-password',
  '/update-required',
  '/activate',
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

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.uri.path;

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
        final from = state.uri.toString();
        return from == '/'
            ? '/sign-in'
            : '/sign-in?from=${Uri.encodeComponent(from)}';
      }

      if (path.startsWith('/sign-in')) {
        return state.uri.queryParameters['from'] ?? '/';
      }
      if (path == '/activate' || path == '/__/auth/links') return '/';
      // Disabled accounts see only the disabled screen (AUTH-11).
      final disabled =
          ref.read(myProfileProvider).value?.status == UserStatus.disabled;
      if (disabled) return path == '/disabled' ? null : '/disabled';
      if (path == '/disabled') return '/';

      // First-run setup (AUTH-5) comes before anything else. Until the
      // profile exists (the callable creates it), nothing is blocked.
      final profile = ref.read(myProfileProvider).value;
      final needsSetup = profile?.needsSetup ?? false;
      if (needsSetup && path != '/setup') return '/setup';
      if (!needsSetup && path == '/setup') return '/';

      if (path.startsWith('/admin') && !user.isSuperAdmin) return '/';

      if (path == '/' || path == '/welcome') {
        // Wait for this user's memberships; right after sign-in the provider
        // still holds the signed-out empty list while it reloads.
        final memberships = ref.read(myMembershipsProvider);
        if (!memberships.hasValue || memberships.isLoading) return null;
        final list = memberships.value!;
        if (path == '/welcome') return list.isEmpty ? null : '/';
        if (list.isEmpty) return '/welcome';
        final last = ref.read(localPrefsRepositoryProvider).lastTeamRoute;
        final lastGroup = last?.split('/').elementAtOrNull(2);
        if (last != null && list.any((m) => m.groupId.value == lastGroup)) {
          return last;
        }
        // Otherwise the team with the most recent activity.
        if (list.any((m) => ref.read(groupProvider(m.groupId)).isLoading)) {
          return null;
        }
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
        onAction: () => context.go('/'),
      ),
    ),
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (_, _) => const SignInScreen(),
        routes: [
          GoRoute(
            path: 'email',
            builder: (_, _) =>
                EmailSignInScreen(showEmulatorHint: env.useEmulators),
          ),
        ],
      ),
      GoRoute(path: '/setup', builder: (_, _) => const SetupScreen()),
      GoRoute(path: '/disabled', builder: (_, _) => const DisabledScreen()),
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
      GoRoute(
        path: '/welcome',
        builder: (context, _) =>
            WelcomeScreen(onOpenSettings: () => context.push('/settings')),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, _) => SettingsScreen(
          appVersion: ref.read(appVersionProvider),
          showDevTools: !env.isProd,
        ),
        routes: [
          GoRoute(path: 'profile', builder: (_, _) => const ProfileScreen()),
          GoRoute(
            path: 'sign-in-methods',
            builder: (_, _) => const SignInMethodsScreen(),
          ),
          if (!env.isProd)
            GoRoute(
              path: 'push-test',
              builder: (_, _) => const PushTestScreen(),
            ),
        ],
      ),
      GoRoute(path: '/admin', builder: (_, _) => const AdminScreen()),
      GoRoute(path: '/g/new', builder: (_, _) => const CreateTeamScreen()),
      GoRoute(
        path: '/g/:groupId',
        redirect: (_, state) => state.uri.pathSegments.length == 2
            ? '/g/${state.pathParameters['groupId']}/chat'
            : null,
        routes: [
          GoRoute(
            path: 'invite',
            builder: (_, state) => InviteScreen(
              groupId: GroupId(state.pathParameters['groupId']!),
            ),
          ),
          GoRoute(
            path: 'settings',
            builder: (_, state) => TeamSettingsScreen(
              groupId: GroupId(state.pathParameters['groupId']!),
            ),
          ),
          GoRoute(
            path: 'roster',
            builder: (_, state) => RosterScreen(
              groupId: GroupId(state.pathParameters['groupId']!),
            ),
            routes: [
              GoRoute(
                path: 'players/:playerId',
                builder: (_, state) => PlayerCardScreen(
                  groupId: GroupId(state.pathParameters['groupId']!),
                  playerId: PlayerId(state.pathParameters['playerId']!),
                ),
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
            path: 'players/add',
            builder: (_, state) => AddPlayersScreen(
              groupId: GroupId(state.pathParameters['groupId']!),
            ),
          ),
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => TeamShell(
              groupId: GroupId(state.pathParameters['groupId']!),
              navigationShell: shell,
            ),
            branches: [
              for (final tab in teamTabs)
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: tab,
                      builder: (_, state) {
                        final id = GroupId(state.pathParameters['groupId']!);
                        return switch (tab) {
                          'chat' => ChatScreen(groupId: id),
                          'schedule' => ScheduleScreen(groupId: id),
                          _ => DocumentsScreen(groupId: id),
                        };
                      },
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    ],
  );

  // Remember the last team and tab on this device (SPEC §5.2).
  router.routerDelegate.addListener(() {
    final path = router.routerDelegate.currentConfiguration.uri.path;
    final segments = path.split('/');
    if (segments.length == 4 &&
        segments[1] == 'g' &&
        teamTabs.contains(segments[3])) {
      unawaited(ref.read(localPrefsRepositoryProvider).setLastTeamRoute(path));
    }
  });
  ref.onDispose(router.dispose);
  return router;
}
