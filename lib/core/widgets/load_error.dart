import 'package:battleplan/core/design/app_colors.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/color_math.dart';
import 'package:battleplan/core/design/gumdrop_buttons.dart';
import 'package:battleplan/core/design/gumdrop_colors.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/empty_state.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// "Couldn't load this" with Try again (SPEC §7.5, #40, #42): what every
/// failed load says, in one of two forms.
///
/// - The full form, for a page or a tab whose content failed: the empty
///   state's look, the error icon, the sentence ([message], or "Couldn't
///   load this. Check your connection and try again."), and one coral
///   **Try again**, the one thing to do there.
/// - The [inline] form, for one section of a page that otherwise loaded
///   (Your schedule on Teams): one muted line, "Couldn't load this.", and
///   a quiet Try again link.
///
/// Screen readers hear the sentence once, as a live region, then "Try
/// again, button". [onRetry] loads again: usually `ref.invalidate` of the
/// provider that failed, whose placeholder rows show while it does.
class LoadError extends StatelessWidget {
  const new({
    required this.onRetry,
    this.message,
    this.inline = false,
    super.key,
  });

  final VoidCallback onRetry;

  /// In place of the usual sentence, for a load with its own words.
  final String? message;

  /// One line inside a page, rather than the page's whole content.
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!inline) {
      return Semantics(
        container: true,
        liveRegion: true,
        child: EmptyState(
          icon: AppIcons.error,
          message: message ?? l10n.loadError,
          actionLabel: l10n.tryAgain,
          onAction: onRetry,
        ),
      );
    }
    final c = GumdropColors.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Space.xs,
        children: [
          Text(
            message ?? l10n.loadErrorShort,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: c.onCard ? c.textMuted : c.textMutedOnPage,
            ),
          ),
          TextButton(
            style: GumdropButtons.of(context).link(),
            onPressed: onRetry,
            child: Text(l10n.tryAgain),
          ),
        ],
      ),
    );
  }
}

/// A list that stopped after showing what it has (#40): it keeps them, and
/// this slim notice at the top says "Couldn't refresh." with a quiet Try
/// again, in the warning look (the amber of Maybe, lightly, never coral or
/// the error red). It goes once a fresh answer arrives. Heard once, as a
/// live region.
class RefreshFailedNotice extends StatelessWidget {
  const new({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = GumdropColors.of(context);
    final ink = c.onCard ? c.textPrimary : c.textOnPage;
    final gutter = Space.gutter(MediaQuery.sizeOf(context).width);
    // A Maybe tint over what it's on; where that would take the words under
    // 4.5:1 (white on Tropic Blue's mid-blue page, #90), an ink tint, which
    // deepens it instead.
    final tinted = Color.alphaBlend(
      AppColors.of(context).maybe.withValues(alpha: 0.18),
      c.background,
    );
    final fill = ColorMath.contrast(ink, tinted) >= 4.5
        ? tinted
        : Color.alphaBlend(c.ink.withValues(alpha: 0.18), c.background);
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        // Across the list, whatever its words need.
        width: double.infinity,
        margin: EdgeInsets.fromLTRB(gutter, 8, gutter, 4),
        padding: const EdgeInsets.only(left: 12, right: 8),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
        ),
        // The icon rides with the words, so with large text it stays by
        // their line; Try again goes beside them, or under them when it
        // doesn't fit.
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: Space.xs,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      AppIcons.warning,
                      size: MediaQuery.textScalerOf(context)
                          .clamp(maxScaleFactor: 1.6)
                          .scale(18),
                      color: ink,
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Flexible(
                    child: Text(
                      l10n.refreshFailed,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontSize: 15, color: ink),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              style: GumdropButtons.of(context).link(),
              onPressed: onRetry,
              child: Text(l10n.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}
