import 'dart:async';

import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Links to the Terms of Use and the Privacy Policy on the website
/// (LEGAL-1: linked from sign-in; SAFE-3: readable before accepting them
/// at setup). The pages are at the root of the domain (D40).
class LegalLinks extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final site = ref.read(linkServiceProvider);
    void open(String path) =>
        unawaited(ref.read(linkOpenerProvider).open(site.site(path)));
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        TextButton(
          onPressed: () => open('/terms'),
          child: Text(l10n.termsOfUse),
        ),
        TextButton(
          onPressed: () => open('/privacy'),
          child: Text(l10n.privacyPolicy),
        ),
      ],
    );
  }
}
