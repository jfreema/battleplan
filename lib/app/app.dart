import 'package:battleplan/app/app_services.dart';
import 'package:battleplan/app/router.dart';
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_theme.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The root widget: theme, localization, and the router.
///
/// Dev builds are wrapped in a corner ribbon ("EMU" or "DEV") so they're
/// never mistaken for prod.
class BattleplanApp extends ConsumerWidget {
  const new({super.key});

  // Built once; rebuilding ThemeData on every frame is wasteful.
  static final ThemeData _light = AppTheme.light();
  static final ThemeData _dark = AppTheme.dark();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banner = ref.watch(appEnvProvider).bannerLabel;
    final app = MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: _light,
      darkTheme: _dark,
      themeMode: switch (ref.watch(themePreferenceControllerProvider)) {
        ThemePreference.system => ThemeMode.system,
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
    );
    if (banner == null) return app;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Banner(
        message: banner,
        location: BannerLocation.topEnd,
        child: app,
      ),
    );
  }
}
