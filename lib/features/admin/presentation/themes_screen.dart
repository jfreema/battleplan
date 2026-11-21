import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/core/design/schemes.dart';
import 'package:battleplan/core/design/tokens.dart';
import 'package:battleplan/core/widgets/load_error.dart';
import 'package:battleplan/core/widgets/scheme_swatch.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/admin/presentation/admin_widgets.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The theme editor's list at `/admin/themes` (#82, owner's request
/// 2026-11-20): the saved themes, with New theme while there's a free slot,
/// and the built-in ones, each saying whether its colors were changed. Each
/// opens the editor (`AdminThemeEditorScreen` at `/admin/themes/<scheme>`).
class AdminThemesScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(appConfigProvider);
    final themes = ref.watch(themeOverridesProvider);
    final saved = [
      for (final s in customSchemes)
        if (schemeAvailable(s, themes)) s,
    ];
    final full = saved.length >= customSchemes.length;

    Widget row(TeamScheme scheme, String subtitle) => ListTile(
      contentPadding: EdgeInsets.zero,
      // Drawn from the theme itself, so a save shows here at once.
      leading: SchemeSwatch.roles(SchemeRoles.themed(scheme, themes[scheme])),
      title: Text(themes[scheme]?.name ?? scheme.label(l10n)),
      subtitle: Text(subtitle),
      trailing: const Icon(AppIcons.chevronRight),
      onTap: () => unawaited(context.push('/admin/themes/${scheme.value}')),
    );

    return AdminScaffold(
      section: AdminSection.themes,
      title: l10n.adminThemes,
      body: config.value == null && config.hasError
          ? LoadError(onRetry: () => ref.invalidate(appConfigProvider))
          : config.value == null
          ? const Center(child: CircularProgressIndicator())
          : AdminBody(
              maxWidth: 640,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.lg),
                  child: Text(l10n.adminThemesIntro),
                ),
                AdminSectionCard(
                  title: l10n.adminSavedThemes,
                  children: [
                    if (saved.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.md),
                        child: Text(l10n.adminNoSavedThemes),
                      ),
                    for (final s in saved)
                      row(
                        s,
                        l10n.savedThemeShort(
                          (themes[s]?.base ?? defaultTeamScheme).label(l10n),
                        ),
                      ),
                    const SizedBox(height: Space.sm),
                    if (full)
                      Text(l10n.adminThemesFull(customSchemes.length))
                    else
                      FilledButton.icon(
                        icon: const Icon(AppIcons.add),
                        label: Text(l10n.adminNewTheme),
                        onPressed: () =>
                            unawaited(context.push('/admin/themes/new')),
                      ),
                  ],
                ),
                AdminSectionCard(
                  title: l10n.adminBuiltInThemes,
                  children: [
                    for (final s in builtInSchemes)
                      row(
                        s,
                        themes.containsKey(s)
                            ? l10n.adminThemeChanged
                            : l10n.adminThemeAsShipped,
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}
