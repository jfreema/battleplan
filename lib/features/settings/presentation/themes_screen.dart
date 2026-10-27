import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:battleplan/features/settings/presentation/theme_picker.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Themes at `/themes`, from Profile (SET-2): the Gumdrop themes to pick
/// from, each a small preview; a tap switches at once.
class ThemesScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: gumdropAppBar(context, title: l10n.themes),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, Space.xl),
            children: [
              ThemePicker(
                selected: ref.watch(themePreferenceControllerProvider),
                onSelect: (t) =>
                    ref.read(themePreferenceControllerProvider.notifier).set(t),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
