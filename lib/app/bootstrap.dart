import 'dart:async';

import 'package:battleplan/app/app.dart';
import 'package:battleplan/app/firebase_options_emulator.dart';
import 'package:battleplan/app/providers.dart';
import 'package:battleplan/app/services/crashlytics_reporter.dart';
import 'package:battleplan/app/services/firebase_analytics_service.dart';
import 'package:battleplan/app/services/firebase_remote_config_service.dart';
import 'package:battleplan/app/services/web_error_reporter.dart';
import 'package:battleplan/core/env.dart';
import 'package:battleplan/core/logging.dart';
import 'package:battleplan/core/services/analytics.dart';
import 'package:battleplan/core/services/crash_reporter.dart';
import 'package:battleplan/core/services/remote_config.dart';
import 'package:battleplan/features/settings/data/shared_prefs_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _useEmulators = bool.fromEnvironment('USE_EMULATORS');

/// Override for phones on the LAN, e.g. --dart-define=EMULATOR_HOST=192.168.1.20.
const _emulatorHostOverride = String.fromEnvironment('EMULATOR_HOST');

/// App startup, shared by both entry points (ARCH §5.1).
Future<void> bootstrap({
  required AppFlavor flavor,
  required FirebaseOptions Function() cloudOptions,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final env = AppEnv(flavor: flavor, useEmulators: _useEmulators);
  if (env.isProd && env.useEmulators) {
    throw StateError('Prod builds never use the emulators.');
  }

  await Firebase.initializeApp(
    options: env.useEmulators ? emulatorFirebaseOptions() : cloudOptions(),
  );
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  if (env.useEmulators) {
    final host = _emulatorHostOverride.isNotEmpty
        ? _emulatorHostOverride
        : (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        ? '10.0.2.2'
        : 'localhost';
    await auth.useAuthEmulator(host, 9099);
    firestore.useFirestoreEmulator(host, 8080);
    functions.useFunctionsEmulator(host, 5001);
  }
  // Offline cache: default on mobile, explicit on web (ARCH §5.6).
  firestore.settings = const Settings(persistenceEnabled: true);

  final info = await PackageInfo.fromPlatform();
  final version = info.version;
  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: SharedPrefsRepository.keys,
    ),
  );

  final Analytics analytics;
  final CrashReporter crashReporter;
  final RemoteConfig remoteConfig;
  if (env.useEmulators) {
    analytics = const NoopAnalytics();
    crashReporter = kIsWeb
        ? WebErrorReporter(functions, appVersion: version, sampleRate: 1)
        : const NoopCrashReporter();
    remoteConfig = const DefaultRemoteConfig();
  } else {
    analytics = FirebaseAnalyticsService(FirebaseAnalytics.instance);
    crashReporter = kIsWeb
        ? WebErrorReporter(functions, appVersion: version)
        : CrashlyticsReporter(FirebaseCrashlytics.instance);
    remoteConfig = FirebaseRemoteConfigService(FirebaseRemoteConfig.instance);
  }
  // Don't block first paint on Remote Config; the router re-checks.
  unawaited(remoteConfig.refresh());

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(crashReporter.recordError(details.exception, details.stack));
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    Log.error('Uncaught error', error, stack);
    unawaited(crashReporter.recordError(error, stack, fatal: true));
    return true;
  };

  runApp(
    ProviderScope(
      overrides: buildOverrides(
        env: env,
        version: version,
        auth: auth,
        firestore: firestore,
        functions: functions,
        // The emulators have no push service.
        messaging: env.useEmulators ? null : FirebaseMessaging.instance,
        prefs: prefs,
        analytics: analytics,
        crashReporter: crashReporter,
        remoteConfig: remoteConfig,
      ),
      child: const BattleplanApp(),
    ),
  );
}
