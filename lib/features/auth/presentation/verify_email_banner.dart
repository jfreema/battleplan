import 'dart:async';

import 'package:battleplan/core/design/app_colors.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/gumdrop_buttons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/gumdrop_style.dart';
import 'package:battleplan/core/design/team_theme.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/admin/application/providers.dart'
    show liveAnnouncementProvider;
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// AUTH-3: stays above every screen until the signed-in person's email is
/// verified. Google and Apple sign-ins arrive verified, so only email
/// accounts see it.
///
/// It checks again by itself whenever the app comes back to the front (on
/// the web, when the tab is shown again), the usual way back from the
/// email, and says "Email verified…" the moment it is (#33). "I've
/// verified" checks by hand, and says so when it isn't yet.
class VerifyEmailBanner extends ConsumerStatefulWidget {
  const new({super.key});

  /// Puts the banner above [child] while it's needed. The banner takes the
  /// top safe-area inset, so [child] doesn't pad for it twice. The tree is
  /// the same shape either way, as `AnnouncementBanner`'s is: verifying
  /// mustn't rebuild the screens under it and lose a half-filled form
  /// (#33).
  static Widget wrap(Widget child) => Consumer(
    builder: (context, ref, _) {
      final shown = needsVerifiedEmail(ref.watch(authUserProvider).value);
      return Column(
        children: [
          const VerifyEmailBanner(),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: shown,
              child: child,
            ),
          ),
        ],
      );
    },
  );

  @override
  ConsumerState<VerifyEmailBanner> createState() => _VerifyEmailBannerState();
}

class _VerifyEmailBannerState extends ConsumerState<VerifyEmailBanner> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back from the mail app, or back to this tab: the link was most
    // likely opened meanwhile.
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(_recheck()));
  }

  Future<void> _recheck() async {
    if (!needsVerifiedEmail(ref.read(authUserProvider).value)) return;
    await recheckEmailVerified(ref);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The moment this account turns verified, from any check: said once.
    ref.listen(authUserProvider, (previous, next) {
      final before = previous?.value;
      final now = next.value;
      if (before != null &&
          now != null &&
          before.uid == now.uid &&
          needsVerifiedEmail(before) &&
          now.emailVerified) {
        showAppSnackBar(context, AppLocalizations.of(context).emailVerifiedNow);
      }
    });
    final user = ref.watch(authUserProvider).value;
    if (!needsVerifiedEmail(user)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = GumdropColors.of(context);
    // The info color, as the super admins' routine announcements use it,
    // with the candy ink on it (4.5:1 in every scheme).
    final face = c.blueRaspberry.face;
    final ink = c.inkOn(c.blueRaspberry);
    final button = TextButton.styleFrom(
      foregroundColor: ink,
      textStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
        decoration: TextDecoration.underline,
        decorationColor: ink,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      minimumSize: const Size(48, 48),
    );
    final width = MediaQuery.sizeOf(context).width;
    // Under an announcement of the same color, a hairline keeps them two.
    final below = ref.watch(liveAnnouncementProvider) != null;
    // The app's root has no Material yet: this sits above the router.
    return Material(
      color: face,
      shape: below
          ? Border(top: BorderSide(color: ink.withValues(alpha: 0.3)))
          : null,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(left: Space.gutter(width), right: Space.xs),
          // Its own node, read before the page, and announced once when it
          // appears (§7.6). It sits above the navigator, so it has no
          // tooltips (they need an Overlay).
          child: Semantics(
            container: true,
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Level with the first line of the words.
                ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 9),
                    child: Icon(AppIcons.email, size: 20, color: ink),
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  // The words, then the two buttons beside them, or under
                  // them on a narrow phone or with large text.
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          l10n.verifyEmailBanner(user!.email!),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        style: button,
                        onPressed: () =>
                            unawaited(resendVerificationEmail(context, ref)),
                        child: Text(l10n.verifyEmailResend),
                      ),
                      TextButton(
                        style: button,
                        onPressed: () =>
                            unawaited(checkEmailVerified(context, ref)),
                        child: Text(l10n.verifyEmailDone),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks the server again whether the email is verified, quietly: on
/// resume, and every few seconds on Create a Team (#33). A failure (no
/// connection) waits for the next check; a session that ended signs out
/// on its own.
Future<bool> recheckEmailVerified(WidgetRef ref) async {
  try {
    return await ref.read(authRepositoryProvider).reloadUser();
  } on AppFailure {
    return false;
  }
}

/// Resend: a new verification link, saying it went, or when to try again
/// (AUTH-3).
Future<void> resendVerificationEmail(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppLocalizations.of(context);
  try {
    await ref.read(authRepositoryProvider).sendEmailVerification();
    if (context.mounted) showAppSnackBar(context, l10n.verifyEmailResent);
  } on AppFailure catch (e) {
    if (!context.mounted) return;
    showAppSnackBar(context, switch (e) {
      RateLimited() => l10n.verifyEmailResendLimited,
      Offline() => l10n.signInOffline,
      _ => l10n.signInUnknownError,
    });
  }
}

/// I've verified: checks with the server now. Verified, the banner says
/// "Email verified…" itself; not yet, this says so (#33).
Future<void> checkEmailVerified(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final email = ref.read(authUserProvider).value?.email;
  try {
    final verified = await ref.read(authRepositoryProvider).reloadUser();
    if (!verified && context.mounted && email != null) {
      showAppSnackBar(context, l10n.verifyEmailNotYet(email));
    }
  } on AppFailure catch (e) {
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      e is Offline ? l10n.signInOffline : l10n.signInUnknownError,
    );
  }
}

/// The notice at the top of Create a Team and Create a Group while the
/// email isn't verified (#33): what's needed and how, before anything is
/// typed, with Resend email and I've verified. Calm until Create is tapped
/// too soon ([waiting]), then the warning look: "Your email isn't verified
/// yet…". The form under it stays usable.
class VerifyEmailNotice extends ConsumerWidget {
  const new({required this.group, required this.waiting, super.key});

  /// For a group, not a team.
  final bool group;

  /// Create was tapped and is waiting for the email to be verified.
  final bool waiting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).value;
    if (!needsVerifiedEmail(user)) return const SizedBox.shrink();
    final email = user!.email!;
    final l10n = AppLocalizations.of(context);
    final page = GumdropColors.of(context);
    final outline = page.surfaceBorderWidth == 0
        ? BorderSide.none
        : BorderSide(color: page.surfaceBorder, width: page.surfaceBorderWidth);
    // Warning: the amber of Maybe and the storage warning, lightly, over
    // the card, as a warning announcement looks.
    final face = waiting
        ? Color.alphaBlend(
            AppColors.of(context).maybe.withValues(alpha: 0.18),
            page.surface,
          )
        : page.surface;
    return Semantics(
      container: true,
      liveRegion: waiting,
      child: Container(
        decoration: GumdropStyle.of(context)
            .cardDecoration(face, 18, side: outline),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: GumdropSurface(
          child: Builder(
            builder: (context) {
              final card = GumdropColors.of(context);
              final theme = Theme.of(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(
                            waiting ? AppIcons.warning : AppIcons.email,
                            size: 22,
                            color: waiting ? card.textPrimary : card.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group
                                  ? l10n.verifyEmailGroupTitle
                                  : l10n.verifyEmailTeamTitle,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: card.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              waiting
                                  ? l10n.verifyEmailStillNot(email)
                                  : l10n.verifyEmailNoticeBody(email),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: waiting
                                    ? card.textPrimary
                                    : card.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Side by side, or one under the other with large text.
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // The theme's outlined pill, 48 px.
                      OutlinedButton(
                        onPressed: () =>
                            unawaited(resendVerificationEmail(context, ref)),
                        child: Text(l10n.verifyEmailResendButton),
                      ),
                      TextButton(
                        style: GumdropButtons.of(context).link(),
                        onPressed: () =>
                            unawaited(checkEmailVerified(context, ref)),
                        child: Text(l10n.verifyEmailDone),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
