import 'package:battleplan/app/app_services.dart';
import 'package:battleplan/core/env.dart';
import 'package:battleplan/core/services/analytics.dart';
import 'package:battleplan/core/services/crash_reporter.dart';
import 'package:battleplan/core/services/remote_config.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/data/firebase_auth_repository.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/data/firestore_group_repository.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:battleplan/features/settings/data/shared_prefs_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The one place repositories and services are constructed (ARCH §5.2 rule 4).
List<Override> buildOverrides({
  required AppEnv env,
  required String version,
  required FirebaseAuth auth,
  required FirebaseFirestore firestore,
  required SharedPreferencesWithCache prefs,
  required Analytics analytics,
  required CrashReporter crashReporter,
  required RemoteConfig remoteConfig,
}) => [
  appEnvProvider.overrideWithValue(env),
  appVersionProvider.overrideWithValue(version),
  analyticsProvider.overrideWithValue(analytics),
  crashReporterProvider.overrideWithValue(crashReporter),
  remoteConfigProvider.overrideWithValue(remoteConfig),
  authRepositoryProvider.overrideWithValue(
    FirebaseAuthRepository(
      auth,
      linkHost: env.isProd
          ? 'getbattleplan.app'
          : 'battleplan-dev-ecce4.web.app',
    ),
  ),
  groupRepositoryProvider.overrideWithValue(
    FirestoreGroupRepository(firestore),
  ),
  memberRepositoryProvider.overrideWithValue(
    FirestoreMemberRepository(firestore),
  ),
  localPrefsRepositoryProvider.overrideWithValue(SharedPrefsRepository(prefs)),
];
