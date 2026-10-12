import 'package:battleplan/core/env.dart';
import 'package:battleplan/core/logging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

/// The reCAPTCHA Enterprise site key for the web app,
/// e.g. --dart-define=APP_CHECK_WEB_KEY=6Lc... (docs/DEVELOPMENT.md).
const _webSiteKey = String.fromEnvironment('APP_CHECK_WEB_KEY');

/// A debug token registered in the Firebase console, for dev builds in CI or
/// on a machine that already has one (--dart-define=APP_CHECK_DEBUG_TOKEN=...).
/// Without it, debug builds make up a token and log it for registering.
const _debugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');

/// How a build proves to Firebase that it's the real app (ARCH §6.9).
enum AppCheckMode {
  /// No App Check: requests carry no token.
  off,

  /// The debug provider, with a token registered in the console.
  debug,

  /// Play Integrity (Android), App Attest with DeviceCheck fallback (iOS),
  /// reCAPTCHA Enterprise (web).
  attested,
}

/// What [activateAppCheck] will do, worked out from the build settings so
/// it can be tested without Firebase.
class AppCheckPlan {
  const new({
    required this.mode,
    required this.reason,
    this.webSiteKey = '',
    this.debugToken = '',
  });

  final AppCheckMode mode;

  /// Why, for the startup log line.
  final String reason;

  /// The reCAPTCHA Enterprise site key, when [mode] is attested on web.
  final String webSiteKey;

  /// A registered debug token, or empty to let the SDK make one up.
  final String debugToken;
}

/// Chooses App Check's provider:
///
/// - **Emulators:** off. The `demo-` project has no App Check backend to
///   swap a debug token with, and the emulators don't check tokens.
/// - **Dev:** the debug provider, with [debugToken] when given.
/// - **Prod:** the platform's attestation provider. Never the debug provider.
/// - **Web:** reCAPTCHA Enterprise with [webSiteKey]; dev also takes a
///   [debugToken] instead. With neither, off, so a build without a key still
///   runs (monitor mode lets its requests through).
AppCheckPlan planAppCheck({
  required AppEnv env,
  required bool isWeb,
  String webSiteKey = _webSiteKey,
  String debugToken = _debugToken,
}) {
  if (env.useEmulators) {
    return const AppCheckPlan(
      mode: AppCheckMode.off,
      reason: 'the emulators have no App Check backend',
    );
  }
  final token = env.isProd ? '' : debugToken;
  if (isWeb) {
    if (token.isNotEmpty) {
      return AppCheckPlan(
        mode: AppCheckMode.debug,
        reason: 'APP_CHECK_DEBUG_TOKEN on a dev web build',
        debugToken: token,
      );
    }
    if (webSiteKey.isEmpty) {
      return const AppCheckPlan(
        mode: AppCheckMode.off,
        reason: 'APP_CHECK_WEB_KEY is not set for this web build',
      );
    }
    return AppCheckPlan(
      mode: AppCheckMode.attested,
      reason: 'reCAPTCHA Enterprise',
      webSiteKey: webSiteKey,
    );
  }
  if (env.isProd) {
    return const AppCheckPlan(
      mode: AppCheckMode.attested,
      reason: 'Play Integrity or App Attest',
    );
  }
  return AppCheckPlan(
    mode: AppCheckMode.debug,
    reason: token.isEmpty
        ? 'dev build; the native log shows the debug token to register'
        : 'dev build with APP_CHECK_DEBUG_TOKEN',
    debugToken: token,
  );
}

/// Starts App Check, before anything else uses Firebase (ARCH §6.9). Never
/// throws: a failure is logged and the app runs without tokens, which
/// monitor mode allows and enforcement would refuse.
Future<void> activateAppCheck(AppCheckPlan plan) async {
  if (plan.mode == AppCheckMode.off) {
    Log.warn('App Check off: ${plan.reason}');
    return;
  }
  final token = plan.debugToken.isEmpty ? null : plan.debugToken;
  final debug = plan.mode == AppCheckMode.debug;
  try {
    final appCheck = FirebaseAppCheck.instance;
    await appCheck.activate(
      providerWeb: debug
          ? WebDebugProvider(debugToken: token)
          : ReCaptchaEnterpriseProvider(plan.webSiteKey),
      providerAndroid: debug
          ? AndroidDebugProvider(debugToken: token)
          : const AndroidPlayIntegrityProvider(),
      providerApple: debug
          ? AppleDebugProvider(debugToken: token)
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
    await appCheck.setTokenAutoRefreshEnabled(true);
    Log.debug('App Check on: ${plan.reason}');
  } on Object catch (error, stack) {
    Log.error('App Check failed to start; continuing without it', error, stack);
  }
}
