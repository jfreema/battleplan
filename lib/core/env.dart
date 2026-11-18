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
  /// emulators, and in prod while [appleSignInInProd] is on.
  bool get appleSignIn => !isProd || appleSignInInProd;

  /// On since prod's Firebase project got Apple's Services ID and key
  /// (2026-10-17, ARCH §6.1). Turning it off hides Apple in prod again, so
  /// prod never shows a button that can't work.
  static const appleSignInInProd = true;

  /// The project's web OAuth client ("Web client (auto created by Google
  /// Service)"), which Android's own Google sign-in asks for an ID token
  /// for, so Firebase accepts it (AUTH-1, ARCH §6.1). Not a secret: it's in
  /// every google-services.json. Null on the emulators, whose fake Google
  /// page needs Firebase's own flow.
  String? get googleServerClientId => useEmulators
      ? null
      : switch (flavor) {
          AppFlavor.dev =>
            '814215990622-eaimmmv1ki0luj2dbr9gucd6f8lqr84f'
                '.apps.googleusercontent.com',
          AppFlavor.prod =>
            '628123687470-5ean303f7qcev52tbg9hqjmrul2f5qi9'
                '.apps.googleusercontent.com',
        };

  /// Shown as a small banner so dev builds are never mistaken for prod.
  String? get bannerLabel => switch ((flavor, useEmulators)) {
    (AppFlavor.prod, _) => null,
    (AppFlavor.dev, true) => 'EMU',
    (AppFlavor.dev, false) => 'DEV',
  };
}
