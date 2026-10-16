import 'dart:async';

import 'package:battleplan/app/app.dart';
import 'package:battleplan/app/app_check.dart';
import 'package:battleplan/app/firebase_options_emulator.dart';
import 'package:battleplan/app/providers.dart';
import 'package:battleplan/app/services/crashlytics_reporter.dart';
import 'package:battleplan/app/services/firebase_analytics_service.dart';
import 'package:battleplan/app/services/firebase_remote_config_service.dart';
import 'package:battleplan/app/services/image_picker_photo_picker.dart';
import 'package:battleplan/app/services/web_error_reporter.dart';
import 'package:battleplan/core/design/fonts.dart';
import 'package:battleplan/core/env.dart';
import 'package:battleplan/core/logging.dart';
import 'package:battleplan/core/services/analytics.dart';
import 'package:battleplan/core/services/crash_reporter.dart';
import 'package:battleplan/core/services/photo_picker.dart';
import 'package:battleplan/core/services/remote_config.dart';
import 'package:battleplan/core/services/time_zones.dart';
import 'package:battleplan/core/version.dart';
import 'package:battleplan/features/chat/data/prefs_chat_queue_store.dart';
import 'package:battleplan/features/plays/data/prefs_whiteboard_store.dart';
import 'package:battleplan/features/settings/data/shared_prefs_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
///
/// [photoPicker] is the system photo picker. Only the end-to-end test
/// passes another (`integration_test/`), as it can't tap through the
/// system's own picker.
Future<void> bootstrap({
  required AppFlavor flavor,
  required FirebaseOptions Function() cloudOptions,
  PhotoPicker? photoPicker,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  // Event times convert between zones (SCHED-9); load the zones once.
  ZonedTime.ensureInitialized();
  // The bundled Inter font's license, under Licenses (SPEC §7.3).
  registerFontLicenses();

  final env = AppEnv(flavor: flavor, useEmulators: _useEmulators);
  if (env.isProd && env.useEmulators) {
    throw StateError('Prod builds never use the emulators.');
  }

  await Firebase.initializeApp(
    options: env.useEmulators ? emulatorFirebaseOptions() : cloudOptions(),
  );
  // Before anything else talks to Firebase, so every request carries a token.
  await activateAppCheck(planAppCheck(env: env, isWeb: kIsWeb));
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  final storage = FirebaseStorage.instance;

  if (env.useEmulators) {
    final host = _emulatorHostOverride.isNotEmpty
        ? _emulatorHostOverride
        : (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        ? '10.0.2.2'
        : 'localhost';
    await auth.useAuthEmulator(host, 9099);
    firestore.useFirestoreEmulator(host, 8080);
    functions.useFunctionsEmulator(host, 5001);
    await storage.useStorageEmulator(host, 9199);
  }
  // Offline cache: default on mobile, explicit on web (ARCH §5.6).
  firestore.settings = const Settings(persistenceEnabled: true);

  final info = await PackageInfo.fromPlatform();
  final version = info.version;
  // The build number and commit tools/build_hosting.sh stamps in (ARCH §9).
  final build = AppBuild(
    version: version,
    number: info.buildNumber,
    commit: const String.fromEnvironment('APP_COMMIT'),
  );
  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: {
        ...SharedPrefsRepository.keys,
        PrefsChatQueueStore.key,
        PrefsWhiteboardStore.key,
      },
    ),
  );

  final Analytics analytics;
  final CrashReporter crashReporter;
  final RemoteConfig remoteConfig;
  if (env.useEmulators) {
    analytics = const NoopAnalytics();
    crashReporter = kIsWeb
        ? WebErrorReporter(functions, appVersion: build.full, sampleRate: 1)
        : const NoopCrashReporter();
    remoteConfig = const DefaultRemoteConfig();
  } else {
    analytics = FirebaseAnalyticsService(FirebaseAnalytics.instance);
    crashReporter = kIsWeb
        ? WebErrorReporter(functions, appVersion: build.full)
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
        build: build,
        auth: auth,
        firestore: firestore,
        functions: functions,
        storage: storage,
        // The emulators have no push service.
        messaging: env.useEmulators ? null : FirebaseMessaging.instance,
        prefs: prefs,
        analytics: analytics,
        crashReporter: crashReporter,
        remoteConfig: remoteConfig,
        photoPicker: photoPicker ?? const ImagePickerPhotoPicker(),
      ),
      child: const BattleplanApp(),
    ),
  );
}
