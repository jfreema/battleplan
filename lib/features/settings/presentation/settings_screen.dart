import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/application/session_service.dart';
import 'package:battleplan/features/auth/auth.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:battleplan/features/settings/presentation/new_owners_dialog.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Settings (SPEC §6.10): profile, appearance, notifications, sign-in
/// methods, about, and the account actions.
class SettingsScreen extends ConsumerWidget {
  const new({required this.appVersion, this.showDevTools = false, super.key});

  final String appVersion;

  /// Shows developer-only tools (dev builds only).
  final bool showDevTools;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = ref.watch(themePreferenceControllerProvider);
    final profile = ref.watch(myProfileProvider).value;
    final photoUrl = ref.watch(myPhotoUrlProvider).value;
    final links = ref.read(linkOpenerProvider);
    // The legal pages are on the website, at the root of the domain (D40).
    final site = ref.read(linkServiceProvider);
    final error = Theme.of(context).colorScheme.error;
    final superAdmin = ref.watch(authUserProvider).value?.isSuperAdmin ?? false;
    final support = ref.watch(supportEmailProvider);

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
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Space.xl),
        children: [
          if (profile != null)
            ListTile(
              leading: Avatar(
                name: profile.displayName,
                colorKey: profile.uid,
                imageUrl: photoUrl,
              ),
              title: Text(profile.displayName),
              subtitle: Text(profile.email ?? ''),
              trailing: const Icon(AppIcons.expand),
              onTap: () => context.push('/settings/profile'),
            ),
          section(l10n.appearance),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg),
            child: SegmentedButton<ThemePreference>(
              segments: [
                ButtonSegment(
                  value: ThemePreference.system,
                  icon: const Icon(AppIcons.systemMode),
                  label: Text(l10n.themeSystem),
                ),
                ButtonSegment(
                  value: ThemePreference.light,
                  icon: const Icon(AppIcons.lightMode),
                  label: Text(l10n.themeLight),
                ),
                ButtonSegment(
                  value: ThemePreference.dark,
                  icon: const Icon(AppIcons.darkMode),
                  label: Text(l10n.themeDark),
                ),
              ],
              selected: {theme},
              onSelectionChanged: (s) => ref
                  .read(themePreferenceControllerProvider.notifier)
                  .set(s.first),
            ),
          ),
          section(l10n.account),
          ListTile(
            leading: const Icon(AppIcons.notifications),
            title: Text(l10n.notificationSettings),
            onTap: () => context.push('/settings/notifications'),
          ),
          ListTile(
            leading: const Icon(AppIcons.settings),
            title: Text(l10n.signInMethods),
            onTap: () => context.push('/settings/sign-in-methods'),
          ),
          ListTile(
            leading: const Icon(AppIcons.block),
            title: Text(l10n.blockedPeople),
            onTap: () => context.push('/settings/blocked'),
          ),
          // Also here for super admins on no team, who never see a team's
          // account menu (ADMIN).
          if (superAdmin)
            ListTile(
              leading: const Icon(AppIcons.admin),
              title: Text(l10n.adminPanel),
              onTap: () => context.push('/admin'),
            ),
          if (showDevTools)
            ListTile(
              leading: const Icon(AppIcons.notifications),
              // Dev-only, never shipped, so not translated.
              title: const Text('Push test (dev only)'),
              onTap: () => context.push('/settings/push-test'),
            ),
          section(l10n.about),
          ListTile(title: Text(l10n.versionLabel(appVersion))),
          ListTile(
            title: Text(l10n.termsOfUse),
            onTap: () => links.open(site.site('/terms')),
          ),
          ListTile(
            title: Text(l10n.privacyPolicy),
            onTap: () => links.open(site.site('/privacy')),
          ),
          ListTile(
            title: Text(l10n.openSourceLicenses),
            onTap: () => showLicensePage(
              context: context,
              applicationName: l10n.appName,
              applicationVersion: appVersion,
            ),
          ),
          // The address from platform settings (ADMIN-7).
          ListTile(
            title: Text(l10n.contactSupport),
            subtitle: Text(support),
            onTap: () => links.open(Uri(scheme: 'mailto', path: support)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(AppIcons.signOut),
            title: Text(l10n.signOut),
            onTap: () => ref.read(sessionServiceProvider).signOut(),
          ),
          ListTile(
            leading: const Icon(AppIcons.signOut),
            title: Text(l10n.signOutEverywhere),
            subtitle: Text(l10n.signOutEverywhereHelp),
            onTap: () async {
              final ok = await showConfirmDialog(
                context,
                title: l10n.signOutEverywhereConfirmTitle,
                message: l10n.signOutEverywhereHelp,
                confirmLabel: l10n.signOutEverywhere,
                cancelLabel: l10n.cancel,
              );
              if (ok) {
                await ref.read(sessionServiceProvider).signOutEverywhere();
              }
            },
          ),
          ListTile(
            leading: Icon(AppIcons.error, color: error),
            title: Text(l10n.deleteAccount, style: TextStyle(color: error)),
            onTap: () async {
              final ok = await showConfirmDialog(
                context,
                title: l10n.deleteAccountTitle,
                message: l10n.deleteAccountBody,
                confirmLabel: l10n.deleteAccount,
                cancelLabel: l10n.cancel,
                destructive: true,
              );
              if (!ok || !context.mounted) return;
              // AUTH-10: owners pick who takes over each team they own.
              final owned = ownedTeams(ref.read(myTeamsProvider).value ?? []);
              var newOwners = const <String, String>{};
              if (owned.isNotEmpty) {
                final picks = await pickNewOwners(context, owned);
                if (picks == null || !context.mounted) return;
                newOwners = picks;
              }
              try {
                await withFreshSignIn(
                  context,
                  ref,
                  () => ref
                      .read(sessionServiceProvider)
                      .deleteAccount(newOwners: newOwners),
                );
              } on AppFailure {
                if (context.mounted) {
                  showAppSnackBar(context, l10n.deleteAccountFailed);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
