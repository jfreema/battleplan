import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// SET-2 appearance and sign-out. The rest of Settings arrives with M1.
class SettingsScreen extends ConsumerWidget {
  const new({required this.appVersion, super.key});

  final String appVersion;

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
            leading: const Icon(AppIcons.signOut),
            title: Text(l10n.signOut),
            onTap: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
    );
  }
}
