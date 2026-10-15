import 'package:battleplan/core/env.dart';
import 'package:battleplan/core/services/analytics.dart';
import 'package:battleplan/core/services/crash_reporter.dart';
import 'package:battleplan/core/services/remote_config.dart';
import 'package:battleplan/core/version.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_services.g.dart';

/// Platform services and build info, overridden in app/providers.dart.
/// Which flavor this build is and whether it talks to the emulators.
@Riverpod(keepAlive: true)
AppEnv appEnv(Ref ref) => throw UnimplementedError();

/// The app's version from the platform (pubspec `version`), for the
/// forced-update check.
@Riverpod(keepAlive: true)
String appVersion(Ref ref) => throw UnimplementedError();

/// The version, build number, and commit, for Settings → About.
@Riverpod(keepAlive: true)
AppBuild appBuild(Ref ref) => throw UnimplementedError();

/// No-op until bootstrap supplies Firebase Analytics (never in emulator runs).
@Riverpod(keepAlive: true)
Analytics analytics(Ref ref) => const NoopAnalytics();

/// Crashlytics on mobile, the logClientError callable on web.
@Riverpod(keepAlive: true)
CrashReporter crashReporter(Ref ref) => const NoopCrashReporter();

/// Feature flags and `min_supported_version`; defaults until fetched.
@Riverpod(keepAlive: true)
RemoteConfig remoteConfig(Ref ref) => const DefaultRemoteConfig();
