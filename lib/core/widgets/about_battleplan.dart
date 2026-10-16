import 'dart:async';

import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/version.dart';
import 'package:battleplan/core/widgets/adaptive_sheet.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Who made Battleplan, for About.
const developerName = 'Jared Freeman';
const _developerFirstName = 'Jared';

/// Jared's Venmo: the card he shares, and its link for phones, where a QR
/// code on the screen can't be scanned.
const venmoHandle = '@Jared-D-Freeman';
final venmoUrl = Uri.https('venmo.com', '/u/Jared-D-Freeman');
const venmoCardAsset = 'assets/about/venmo.png';

/// About Battleplan, at the end of Team settings (TEAM-5): the version and
/// build, who made it, that it's free and he volunteers, and Buy Jared a
/// coffee, which shows his Venmo.
class AboutBattleplan extends ConsumerWidget {
  const new({required this.appBuild, super.key});

  final AppBuild appBuild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            appBuild.number.isEmpty
                ? l10n.versionLabel(appBuild.version)
                : l10n.versionBuildLabel(appBuild.version, appBuild.number),
          ),
          subtitle: Text(l10n.developedBy(developerName)),
        ),
        Text(
          l10n.aboutVolunteer(_developerFirstName),
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: Space.md),
        OutlinedButton.icon(
          onPressed: () => unawaited(showBuyCoffee(context)),
          icon: const Icon(AppIcons.coffee),
          label: Text(l10n.buyCoffee(_developerFirstName)),
        ),
      ],
    );
  }
}

/// Buy Jared a coffee: his Venmo card to scan, and Open Venmo to pay from
/// this phone.
Future<void> showBuyCoffee(BuildContext context) =>
    showAdaptiveSheet<void>(context, builder: (_) => const _BuyCoffee());

class _BuyCoffee extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.buyCoffee(_developerFirstName),
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.sm),
          Text(
            l10n.buyCoffeeBody(_developerFirstName),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Space.lg),
          // The card on white in either theme, as a QR code needs.
          ClipRRect(
            borderRadius: BorderRadius.circular(Space.md),
            child: ColoredBox(
              color: const Color(0xFFFFFFFF),
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Image.asset(
                  venmoCardAsset,
                  width: 220,
                  semanticLabel: l10n.venmoCardLabel(
                    developerName,
                    venmoHandle,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.lg),
          FilledButton.icon(
            onPressed: () {
              unawaited(ref.read(linkOpenerProvider).open(venmoUrl));
              Navigator.of(context).pop();
            },
            icon: const Icon(AppIcons.openExternal),
            label: Text(l10n.openVenmo),
          ),
        ],
      ),
    );
  }
}
