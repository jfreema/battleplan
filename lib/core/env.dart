/// Which Firebase project and app ID a build talks to (ARCH §5.7).
enum AppFlavor { dev, prod }

/// Build-time environment, chosen by the entry point (`main_dev.dart`,
/// `main_prod.dart`) and `--dart-define=USE_EMULATORS=true`.
class AppEnv {
  const new({required this.flavor, required this.useEmulators});

  final AppFlavor flavor;

  /// Talk to the local Emulator Suite instead of a cloud project.
  final bool useEmulators;

  bool get isProd => flavor == AppFlavor.prod;

  /// Sign in with Apple (AUTH-1, roadmap task 109): on in dev and on the
  /// emulators, and in prod once the prod Firebase project has Apple's
  /// Services ID and key, so prod never shows a button that can't work.
  bool get appleSignIn => !isProd || appleSignInInProd;

  /// Turned on when prod's Apple provider is set up (ARCH §6.1).
  static const appleSignInInProd = false;

  /// Shown as a small banner so dev builds are never mistaken for prod.
  String? get bannerLabel => switch ((flavor, useEmulators)) {
    (AppFlavor.prod, _) => null,
    (AppFlavor.dev, true) => 'EMU',
    (AppFlavor.dev, false) => 'DEV',
  };
}
