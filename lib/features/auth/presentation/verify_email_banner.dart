import 'dart:async';

import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// AUTH-3: stays above every screen until the signed-in person's email is
/// verified. Google and Apple sign-ins arrive verified, so only email
/// accounts see it. "I've verified" re-checks without signing out.
class VerifyEmailBanner extends ConsumerWidget {
  const new({super.key});

  /// Puts the banner above [child] when it's needed. The banner takes the
  /// top safe-area inset, so [child] doesn't pad for it twice.
  static Widget wrap(Widget child) => Consumer(
    builder: (context, ref, _) {
      if (!_needed(ref)) return child;
      return Column(
        children: [
          const VerifyEmailBanner(),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: child,
            ),
          ),
        ],
      );
    },
  );

  static bool _needed(WidgetRef ref) {
    final user = ref.watch(authUserProvider).value;
    return user != null && !user.emailVerified && user.email != null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).value;
    if (!_needed(ref) || user == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final auth = ref.read(authRepositoryProvider);
    return Material(
      color: scheme.secondaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.lg,
            Space.sm,
            Space.sm,
            Space.sm,
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Space.sm,
            children: [
              Text(
                l10n.verifyEmailBanner(user.email!),
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
              TextButton(
                onPressed: () async {
                  await auth.sendEmailVerification();
                  if (context.mounted) {
                    showAppSnackBar(context, l10n.verifyEmailResent);
                  }
                },
                child: Text(l10n.verifyEmailResend),
              ),
              TextButton(
                onPressed: () => unawaited(auth.reloadUser()),
                child: Text(l10n.verifyEmailDone),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
