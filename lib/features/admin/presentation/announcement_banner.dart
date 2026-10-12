import 'package:battleplan/core/design/app_colors.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// ADMIN-7: the super admins' announcement, above every screen for
/// everyone signed in until it ends. Its color follows its severity, and
/// Dismiss hides it for the rest of the session. It sits above the
/// navigator, so it has no tooltips (they need an Overlay).
class AnnouncementBanner extends ConsumerWidget {
  const new({super.key});

  /// Puts the banner above [child] while there is one. The banner takes
  /// the top safe-area inset, so [child] doesn't pad for it twice. The
  /// tree stays the same shape either way: a banner arriving mid-session
  /// mustn't rebuild the screens under it.
  static Widget wrap(Widget child) => Consumer(
    builder: (context, ref, _) {
      final shown = ref.watch(liveAnnouncementProvider) != null;
      return Column(
        children: [
          const AnnouncementBanner(),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final banner = ref.watch(liveAnnouncementProvider);
    if (banner == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (background, foreground, icon) = switch (banner.severity) {
      BannerSeverity.info => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        AppIcons.info,
      ),
      // The amber semantic color, as the storage warning uses it.
      BannerSeverity.warning => (
        Color.alphaBlend(
          AppColors.of(context).maybe.withValues(alpha: 0.18),
          scheme.surface,
        ),
        scheme.onSurface,
        AppIcons.warning,
      ),
      BannerSeverity.critical => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        AppIcons.error,
      ),
    };
    final width = MediaQuery.sizeOf(context).width;
    // The app's root has no Material yet: this sits above the router.
    return Material(
      color: background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(left: Space.gutter(width), right: Space.xs),
          child: Semantics(
            container: true,
            liveRegion: true,
            label: l10n.announcementLabel(severityLabel(l10n, banner.severity)),
            child: Row(
              children: [
                Icon(icon, size: 20, color: foreground),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.sm),
                    child: Text(
                      banner.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ),
                ),
                // A text button: tooltips need an Overlay, and this sits
                // above the navigator's.
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: foreground),
                  onPressed: () => ref
                      .read(dismissedAnnouncementsProvider.notifier)
                      .dismiss(banner),
                  child: Text(l10n.dismiss),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Info", "Warning", or "Critical" (ADMIN-7).
String severityLabel(AppLocalizations l10n, BannerSeverity s) => switch (s) {
  BannerSeverity.info => l10n.severityInfo,
  BannerSeverity.warning => l10n.severityWarning,
  BannerSeverity.critical => l10n.severityCritical,
};
