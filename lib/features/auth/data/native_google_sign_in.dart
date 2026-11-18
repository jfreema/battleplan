import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

/// Google sign-in in the phone's own account sheet, which hands back a
/// Google ID token for Firebase (AUTH-1, ARCH §6.1).
///
/// Android uses it in place of Firebase's provider flow, which signs in
/// through a browser tab: that tab keeps its place in the browser's
/// sessionStorage, and some browsers lose it on the way back from Google,
/// so sign-in failed with "Unable to process request due to missing
/// initial state" (a Google Play tester, 2026-11-18). The sheet has no
/// browser in it.
abstract interface class NativeGoogleSignIn {
  /// A Google ID token for the account the person picks, or null if they
  /// closed the sheet.
  Future<String?> idToken();
}

/// [NativeGoogleSignIn] on Android: Credential Manager, through the
/// `google_sign_in_android` plugin. Only that plugin is in the app, not
/// `google_sign_in`, so iOS and the web keep their own flows and nothing
/// else.
class AndroidGoogleSignIn implements NativeGoogleSignIn {
  /// [serverClientId] is the Firebase project's web OAuth client, the
  /// audience of the ID token Firebase accepts (AppEnv.googleServerClientId).
  /// A platform passed in stands in for the plugin, in tests.
  new(this.serverClientId, {this._platform});

  final String serverClientId;
  final GoogleSignInPlatform? _platform;

  /// The plugin is set up once, on the first sign-in.
  Future<void>? _ready;

  GoogleSignInPlatform get _plugin =>
      _platform ?? GoogleSignInPlatform.instance;

  @override
  Future<String?> idToken() async {
    final plugin = _plugin;
    try {
      await (_ready ??= plugin.init(
        InitParameters(serverClientId: serverClientId),
      ));
    } on Object {
      // Set up again next time.
      _ready = null;
      rethrow;
    }
    try {
      // The full account sheet each time, with Add account, never a quiet
      // pick of the last one.
      final result = await plugin.authenticate(const AuthenticateParameters());
      return result.authenticationTokens.idToken ??
          (throw const GoogleSignInException(
            code: GoogleSignInExceptionCode.unknownError,
            description: 'No ID token for the account picked',
          ));
    } on GoogleSignInException catch (e) {
      // Closed, or the sheet went away (the app left the screen): the
      // sign-in screen stays, to try again.
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      rethrow;
    }
  }
}
