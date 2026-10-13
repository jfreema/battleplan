import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/application/session_service.dart';
import 'package:battleplan/features/auth/presentation/sign_in_controller.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// AUTH-11: a disabled account sees only this, with the support address
/// from platform settings (ADMIN-7). Signed in (a profile disabled while
/// signed in), it offers Sign out; after a refused sign-in (the usual
/// case, since disabling also disables the sign-in), Back to sign in.
class DisabledScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final signedIn = ref.watch(authUserProvider).value != null;
    return Scaffold(
      body: EmptyState(
        icon: AppIcons.error,
        message: l10n.accountDisabledContact(ref.watch(supportEmailProvider)),
        actionLabel: signedIn ? l10n.signOut : l10n.backToSignIn,
        onAction: signedIn
            ? () => ref.read(sessionServiceProvider).signOut()
            : () {
                // Start the sign-in screen without the refused attempt.
                ref.invalidate(signInControllerProvider);
                context.go('/sign-in');
              },
      ),
    );
  }
}
