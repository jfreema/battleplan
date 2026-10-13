import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Links to the Terms of Use and Privacy Policy on the website (D40), for
/// the sign-in footer (AUTH-1) and the Terms checkbox at setup (AUTH-5).
class LegalLinks extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final site = ref.read(linkServiceProvider);
    final links = ref.read(linkOpenerProvider);
    final style = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm),
      textStyle: Theme.of(context).textTheme.bodySmall,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: Space.sm,
      children: [
        TextButton(
          style: style,
          onPressed: () => links.open(site.site('/terms')),
          child: Text(l10n.termsOfUse),
        ),
        TextButton(
          style: style,
          onPressed: () => links.open(site.site('/privacy')),
          child: Text(l10n.privacyPolicy),
        ),
      ],
    );
  }
}
