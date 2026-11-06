import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/focus_ring_ink.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Apple's "Download on the App Store" badge, which opens the listing with
/// [onPressed], over Apple's credit line (INV-7, ROADMAP task 353). For the
/// web app: the iPhone app never shows it.
///
/// Apple's marketing guidelines ask for its artwork unchanged (the black
/// badge, `website/images/app-store-badge.svg` rendered at 3×), at least
/// 40 points tall, with a quarter of its height clear around it, and for
/// the credit line wherever the badge shows.
class AppStoreBadge extends StatelessWidget {
  const new({required this.onPressed, super.key});

  /// The badge, 431 × 144 pixels.
  static const asset = 'assets/store/app-store-badge.png';

  /// Its height on screen, over Apple's 40-point minimum.
  static const height = 44.0;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          link: true,
          label: l10n.appStoreBadgeLabel,
          excludeSemantics: true,
          child: FocusRingInk(
            onTap: onPressed,
            radius: BorderRadius.circular(12),
            // Room for the focus ring, off the artwork.
            child: Padding(
              padding: const EdgeInsets.all(Space.xs),
              child: Image.asset(
                asset,
                height: height,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
        // With the padding above, a quarter of the badge's height clear.
        const SizedBox(height: Space.sm),
        Text(
          l10n.appleCredit,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
