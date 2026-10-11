import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Shown to people with no teams yet (SPEC §5.1). Join and create arrive in
/// M2.
class WelcomeScreen extends StatelessWidget {
  const new({required this.onOpenSettings, super.key});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(AppIcons.settings),
            onPressed: onOpenSettings,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  AppIcons.group,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: Space.xl),
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
                const SizedBox(height: Space.xxl),
                FilledButton(
                  onPressed: () => showAppSnackBar(context, l10n.comingSoon),
                  child: Text(l10n.joinTeam),
                ),
                const SizedBox(height: Space.md),
                OutlinedButton(
                  onPressed: () => context.push('/g/new'),
                  child: Text(l10n.createTeam),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
