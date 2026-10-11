import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/avatar.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/application/session_service.dart';
import 'package:battleplan/features/auth/auth.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Settings (SPEC §6.10): profile, appearance, sign-in methods, about, and
/// the account actions. Notification settings join in M4.
class SettingsScreen extends ConsumerWidget {
  const new({required this.appVersion, this.showDevTools = false, super.key});

  final String appVersion;

  /// Shows developer-only tools (dev builds only).
  final bool showDevTools;

  static final Uri _terms = Uri.parse('https://getbattleplan.app/terms');
  static final Uri _privacy = Uri.parse('https://getbattleplan.app/privacy');
  static final Uri _support = Uri.parse('mailto:support@getbattleplan.app');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = ref.watch(themePreferenceControllerProvider);
    final profile = ref.watch(myProfileProvider).value;
    final photoUrl = ref.watch(myPhotoUrlProvider).value;
    final links = ref.read(linkOpenerProvider);
    final error = Theme.of(context).colorScheme.error;

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
            leading: const Icon(AppIcons.settings),
            title: Text(l10n.signInMethods),
            onTap: () => context.push('/settings/sign-in-methods'),
          ),
          ListTile(
            leading: const Icon(AppIcons.block),
            title: Text(l10n.blockedPeople),
            onTap: () => context.push('/settings/blocked'),
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
            onTap: () => links.open(_terms),
          ),
          ListTile(
            title: Text(l10n.privacyPolicy),
            onTap: () => links.open(_privacy),
          ),
          ListTile(
            title: Text(l10n.openSourceLicenses),
            onTap: () => showLicensePage(
              context: context,
              applicationName: l10n.appName,
              applicationVersion: appVersion,
            ),
          ),
          ListTile(
            title: Text(l10n.contactSupport),
            subtitle: const Text('support@getbattleplan.app'),
            onTap: () => links.open(_support),
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
              try {
                await withFreshSignIn(
                  context,
                  ref,
                  ref.read(sessionServiceProvider).deleteAccount,
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
