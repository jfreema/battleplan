import 'package:battleplan/app/app_services.dart';
import 'package:battleplan/app/push_handler.dart';
import 'package:battleplan/app/router.dart';
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_theme.dart';
import 'package:battleplan/features/admin/admin.dart';
import 'package:battleplan/features/auth/application/session_service.dart';
import 'package:battleplan/features/auth/presentation/verify_email_banner.dart';
import 'package:battleplan/features/notifications/application/push_registration.dart';
import 'package:battleplan/features/notifications/presentation/push_banner.dart';
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
    // App-wide push work (ARCH §6.5): keeping this device registered, and
    // handling taps and foreground pushes.
    ref
      ..watch(pushRegistrationProvider)
      ..watch(pushHandlerProvider)
      // Signs out when this account's sessions were ended elsewhere (AUTH-9).
      ..watch(sessionRevocationWatcherProvider);
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
      // The email verification banner sits above every screen (AUTH-3),
      // the super admins' announcement above it (ADMIN-7), and in-app push
      // banners above that (NOTIF-7).
      builder: (context, child) => PushBannerHost(
        onOpen: (m) => ref.read(pushHandlerProvider.notifier).open(m),
        child: AnnouncementBanner.wrap(
          VerifyEmailBanner.wrap(child ?? const SizedBox.shrink()),
        ),
      ),
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
