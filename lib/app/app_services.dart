import 'package:battleplan/core/env.dart';
import 'package:battleplan/core/services/analytics.dart';
import 'package:battleplan/core/services/crash_reporter.dart';
import 'package:battleplan/core/services/remote_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_services.g.dart';

/// Platform services and build info, overridden in app/providers.dart.
@Riverpod(keepAlive: true)
AppEnv appEnv(Ref ref) => throw UnimplementedError();

@Riverpod(keepAlive: true)
String appVersion(Ref ref) => throw UnimplementedError();

@Riverpod(keepAlive: true)
Analytics analytics(Ref ref) => const NoopAnalytics();

@Riverpod(keepAlive: true)
CrashReporter crashReporter(Ref ref) => const NoopCrashReporter();

@Riverpod(keepAlive: true)
RemoteConfig remoteConfig(Ref ref) => const DefaultRemoteConfig();
