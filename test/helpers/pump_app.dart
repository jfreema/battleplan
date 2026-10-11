import 'package:battleplan/app/app.dart';
import 'package:battleplan/app/app_services.dart';
import 'package:battleplan/core/env.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/notifications/application/providers.dart';
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// Pumps the whole app (router, theme, shell) on fake repositories.
Future<FakeLocalPrefs> pumpApp(
  WidgetTester tester, {
  required FakeAuthRepository auth,
  Map<String, dynamic> groups = const {},
  List<dynamic> memberships = const [],
  FakeLocalPrefs? prefs,
  FakeUserRepository? users,
  FakePushRepository? push,
}) async {
  final localPrefs = prefs ?? FakeLocalPrefs();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appEnvProvider.overrideWithValue(
          const AppEnv(flavor: AppFlavor.dev, useEmulators: true),
        ),
        appVersionProvider.overrideWithValue('1.0.0'),
        authRepositoryProvider.overrideWithValue(auth),
        userRepositoryProvider.overrideWithValue(users ?? FakeUserRepository()),
        groupRepositoryProvider.overrideWithValue(
          FakeGroupRepository(groups.cast()),
        ),
        memberRepositoryProvider.overrideWithValue(
          FakeMemberRepository(memberships.cast()),
        ),
        localPrefsRepositoryProvider.overrideWithValue(localPrefs),
        pushRepositoryProvider.overrideWithValue(push ?? FakePushRepository()),
      ],
      child: const BattleplanApp(),
    ),
  );
  await tester.pumpAndSettle();
  return localPrefs;
}
