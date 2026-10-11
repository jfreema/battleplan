import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The small "Plus" tag on features a Free team doesn't have (PLAN-4).
class PlusBadge extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(Corners.pill),
      ),
      child: Text(
        AppLocalizations.of(context).plus,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onTertiaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// "What Plus adds" (PLAN-4): the Plus features and how to get it. Members
/// are told to ask a team admin; admins get the contact address until
/// checkout exists (Q19).
Future<void> showWhatPlusAdds(BuildContext context, {required bool isAdmin}) {
  final l10n = AppLocalizations.of(context);
  return showAdaptiveSheet<void>(
    context,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  l10n.whatPlusAdds,
                  style: Theme.of(sheet).textTheme.titleLarge,
                ),
                const SizedBox(width: Space.sm),
                const PlusBadge(),
              ],
            ),
            const SizedBox(height: Space.md),
            for (final line in [
              l10n.plusEditMessages,
              l10n.plusReactions,
              l10n.plusChatLook,
              l10n.plusStorage,
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: Text('•  $line'),
              ),
            const SizedBox(height: Space.sm),
            Text(l10n.plusPrice),
            const SizedBox(height: Space.md),
            Text(isAdmin ? l10n.plusHowToGetAdmin : l10n.plusHowToGetMember),
            const SizedBox(height: Space.lg),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.of(sheet).pop(),
                child: Text(l10n.done),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
