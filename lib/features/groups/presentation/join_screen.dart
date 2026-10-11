import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Landing page for invite links, `/join/<CODE>` (INV-5, INV-7). For now it
/// shows the code so App Links can be tested (M0 spike 2); the team preview
/// and Join button arrive in M2.
class JoinScreen extends StatelessWidget {
  const new({required this.code, super.key});

  final String code;

  /// Shows a raw 8-character code as `K7XP-M2QR`.
  static String formatCode(String code) {
    final c = code.replaceAll('-', '').toUpperCase();
    return c.length == 8 ? '${c.substring(0, 4)}-${c.substring(4)}' : c;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.invite, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: Space.lg),
              Text(l10n.inviteCodeLabel, style: theme.textTheme.titleMedium),
              const SizedBox(height: Space.sm),
              SelectableText(
                formatCode(code),
                style: theme.textTheme.headlineMedium?.copyWith(
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: Space.lg),
              Text(l10n.joinComingSoon, textAlign: TextAlign.center),
              const SizedBox(height: Space.xl),
              FilledButton(
                onPressed: () => context.go('/'),
                child: Text(l10n.goToMyTeams),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
