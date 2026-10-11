import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/features/auth/application/session_service.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// AUTH-11: a disabled account sees only this, with a way to sign out.
class DisabledScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: EmptyState(
        icon: AppIcons.error,
        message: l10n.signInDisabled,
        actionLabel: l10n.signOut,
        onAction: () => ref.read(sessionServiceProvider).signOut(),
      ),
    );
  }
}
