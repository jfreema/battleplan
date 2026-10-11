import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/session_service.dart';
import 'package:battleplan/features/auth/auth.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// SET-2 appearance and sign-out. The rest of Settings arrives with M1.
class SettingsScreen extends ConsumerWidget {
  const new({required this.appVersion, this.showDevTools = false, super.key});

  final String appVersion;

  /// Shows developer-only tools (dev builds only).
  final bool showDevTools;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = ref.watch(themePreferenceControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        children: [
          ListTile(title: Text(l10n.appearance)),
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
          const SizedBox(height: Space.lg),
          const Divider(),
          ListTile(
            title: Text(l10n.about),
            subtitle: Text(l10n.versionLabel(appVersion)),
          ),
          ListTile(
            leading: const Icon(AppIcons.settings),
            title: Text(l10n.signInMethods),
            onTap: () => context.push('/settings/sign-in-methods'),
          ),
          if (showDevTools)
            ListTile(
              leading: const Icon(AppIcons.notifications),
              // Dev-only, never shipped, so not translated.
              title: const Text('Push test (dev only)'),
              onTap: () => context.push('/settings/push-test'),
            ),
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
            leading: Icon(
              AppIcons.error,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              l10n.deleteAccount,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
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
