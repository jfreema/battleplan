import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/core/widgets/team_badge.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/my_team.dart';
import 'package:battleplan/features/notifications/application/providers.dart';
import 'package:battleplan/features/notifications/application/push_registration.dart';
import 'package:battleplan/features/notifications/domain/push_repository.dart';
import 'package:battleplan/features/notifications/presentation/notification_labels.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Settings → Notifications (SET-3): whether this device may notify, with
/// how to turn it on (NOTIF-1, NOTIF-9); the global switches (NOTIF-4); and
/// each team's level, which opens that team's screen (NOTIF-3).
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Coming back from the system settings may have changed the answer.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(pushPermissionProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _turnOn() async {
    await ref.read(pushRegistrationProvider.notifier).requestAndRegister();
    if (mounted) ref.invalidate(pushPermissionProvider);
  }

  Future<void> _setPref(NotificationPref pref, {required bool enabled}) async {
    final l10n = AppLocalizations.of(context);
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid == null) return;
    try {
      await ref
          .read(userRepositoryProvider)
          .setNotificationPref(uid, pref, enabled: enabled);
    } on Object {
      if (mounted) showAppSnackBar(context, l10n.notificationSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(myProfileProvider).value;
    final teams = ref.watch(myTeamsProvider).value ?? const <MyTeam>[];
    final now = DateTime.now();

    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.lg,
        Space.lg,
        Space.sm,
      ),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationSettings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Space.xl),
        children: [
          section(l10n.pushThisDevice),
          _DeviceStatus(onTurnOn: () => unawaited(_turnOn())),
          section(l10n.notifyMeAbout),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg),
            child: Text(
              l10n.notifyAllTeamsHelp,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          for (final pref in shownNotificationPrefs)
            SwitchListTile(
              title: Text(notificationPrefLabel(l10n, pref)),
              value: profile?.notifies(pref) ?? true,
              onChanged: profile == null
                  ? null
                  : (v) => unawaited(_setPref(pref, enabled: v)),
            ),
          if (teams.isNotEmpty) section(l10n.teamSwitcherTitle),
          for (final t in teams)
            ListTile(
              leading: TeamBadge(
                name: t.group.name,
                color: t.group.color == null ? null : Color(t.group.color!),
              ),
              title: Text(t.group.name),
              subtitle: Text(
                [
                  notificationLevelLabel(l10n, t.membership.notificationLevel),
                  ?muteLabel(l10n, t.membership, now),
                ].join(' · '),
              ),
              trailing: t.membership.isMutedAt(now)
                  ? const Icon(AppIcons.muted, size: 18)
                  : null,
              onTap: () => context.push('/g/${t.group.id.value}/notifications'),
            ),
        ],
      ),
    );
  }
}

/// This device's permission, and how to turn notifications on.
class _DeviceStatus extends ConsumerWidget {
  const new({required this.onTurnOn});

  final VoidCallback onTurnOn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(pushPermissionProvider).value;
    final platform = ref.watch(pushRepositoryProvider).platform;
    final needsHomeScreen = ref.watch(browserInfoProvider).pushNeedsHomeScreen;
    final (icon, title, help, canAsk) = switch (status) {
      null => (AppIcons.notifications, '', null, false),
      _ when needsHomeScreen => (
        AppIcons.homeScreen,
        l10n.pushStatusUnavailable,
        l10n.pushHomeScreenBody,
        false,
      ),
      PushPermission.authorized => (
        AppIcons.notificationsOn,
        l10n.pushStatusOn,
        null,
        false,
      ),
      PushPermission.notDetermined => (
        AppIcons.muted,
        l10n.pushStatusOff,
        l10n.pushOffHelp,
        true,
      ),
      // Android can ask again after one "Don't allow"; iOS and browsers
      // answer at once without asking, so the help says where to go.
      PushPermission.denied => (
        AppIcons.muted,
        l10n.pushStatusBlocked,
        platform == DevicePlatform.web
            ? l10n.pushBlockedHelpWeb
            : l10n.pushBlockedHelpPhone,
        platform == DevicePlatform.android,
      ),
      PushPermission.unavailable => (
        AppIcons.muted,
        l10n.pushStatusUnavailable,
        null,
        false,
      ),
    };
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: help == null ? null : Text(help),
      trailing: canAsk
          ? FilledButton(onPressed: onTurnOn, child: Text(l10n.pushTurnOn))
          : null,
    );
  }
}
