import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/notifications/application/providers.dart';
import 'package:battleplan/features/notifications/application/push_registration.dart';
import 'package:battleplan/features/notifications/domain/push_repository.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Asks for notification permission at the right moment (NOTIF-1): the
/// first time the person is in a team, never on first launch, and with a
/// short explainer before the system prompt, which iOS shows only once.
/// Wraps the team shell, which every path to a first team leads to
/// (creating, joining, or being added by email).
class NotificationPrePrompt extends ConsumerStatefulWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<NotificationPrePrompt> createState() =>
      _NotificationPrePromptState();
}

class _NotificationPrePromptState extends ConsumerState<NotificationPrePrompt> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // Memberships may still be loading on a cold start from a link.
    ref.listenManual<AsyncValue<List<Membership>>>(myMembershipsProvider, (
      _,
      next,
    ) {
      if (_started || (next.value?.isEmpty ?? true)) return;
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_maybeAsk());
      });
    }, fireImmediately: true);
  }

  Future<void> _maybeAsk() async {
    final prefs = ref.read(localPrefsRepositoryProvider);
    if (prefs.pushPrePromptShown) return;
    final l10n = AppLocalizations.of(context);
    if (ref.read(browserInfoProvider).pushNeedsHomeScreen) {
      await prefs.setPushPrePromptShown();
      if (!mounted) return;
      final links = ref.read(linkServiceProvider);
      final opener = ref.read(linkOpenerProvider);
      await showHomeScreenTip(
        context,
        l10n,
        onGetApp: () => unawaited(opener.open(links.iosApp)),
      );
      return;
    }
    final status = await ref.read(pushRepositoryProvider).permissionStatus();
    if (status != PushPermission.notDetermined || !mounted) return;
    await prefs.setPushPrePromptShown();
    if (!mounted) return;
    final allow = await showConfirmDialog(
      context,
      title: l10n.pushPrePromptTitle,
      message: l10n.pushPrePromptBody,
      confirmLabel: l10n.pushAllow,
      cancelLabel: l10n.notNow,
    );
    if (!allow || !mounted) return;
    await ref.read(pushRegistrationProvider.notifier).requestAndRegister();
    if (mounted) ref.invalidate(pushPermissionProvider);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// On iPhone and iPad, browser notifications need Add to Home Screen first
/// (NOTIF-9). The tip links to the App Store app with [onGetApp].
Future<void> showHomeScreenTip(
  BuildContext context,
  AppLocalizations l10n, {
  VoidCallback? onGetApp,
}) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    icon: const Icon(AppIcons.homeScreen),
    title: Text(l10n.pushHomeScreenTitle),
    content: Text(l10n.pushHomeScreenBody),
    actions: [
      if (onGetApp != null)
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onGetApp();
          },
          child: Text(l10n.pushHomeScreenGetApp),
        ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(l10n.gotIt),
      ),
    ],
  ),
);
