import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/features/notifications/application/providers.dart';
import 'package:battleplan/features/notifications/domain/push_repository.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Shows the in-app banner for a push that arrives while the app is open
/// (NOTIF-7) above every screen. It sits above the navigator, so it has no
/// tooltips (they need an Overlay).
class PushBannerHost extends ConsumerWidget {
  const new({required this.child, required this.onOpen, super.key});

  final Widget child;

  /// Opens the push's route (the app layer owns the router).
  final ValueChanged<PushMessage> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(pushBannerProvider);
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: Motion.of(context, Motion.normal),
              child: message == null
                  ? const SizedBox.shrink()
                  : _Banner(
                      key: ObjectKey(message),
                      message: message,
                      onOpen: () {
                        ref.read(pushBannerProvider.notifier).dismiss();
                        onOpen(message);
                      },
                      onDismiss: () =>
                          ref.read(pushBannerProvider.notifier).dismiss(),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const new({
    required this.message,
    required this.onOpen,
    required this.onDismiss,
    super.key,
  });

  final PushMessage message;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(Space.sm),
          child: Dismissible(
            key: const ValueKey('pushBanner'),
            direction: DismissDirection.up,
            onDismissed: (_) => onDismiss(),
            child: Material(
              elevation: 6,
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(Corners.card),
              child: InkWell(
                borderRadius: BorderRadius.circular(Corners.card),
                onTap: onOpen,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.lg,
                    Space.md,
                    Space.sm,
                    Space.md,
                  ),
                  child: Row(
                    children: [
                      Icon(AppIcons.notifications, color: scheme.primary),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.title ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              message.body ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: onOpen,
                        child: Text(l10n.openNotification),
                      ),
                      Semantics(
                        button: true,
                        label: l10n.dismissNotification,
                        excludeSemantics: true,
                        child: IconButton(
                          onPressed: onDismiss,
                          icon: const Icon(AppIcons.close),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
