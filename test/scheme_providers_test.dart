// Which color scheme each screen uses (SPEC SET-2, ARCH §5.5): my pick for
// a team, my default, and this device's copies of both for a cold start.

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/groups/application/providers.dart'
    hide group;
import 'package:battleplan/features/settings/application/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

const _coach = AuthUser(
  uid: 'coach',
  email: 'coach@example.com',
  emailVerified: true,
);
const _boss = AuthUser(
  uid: 'boss',
  email: 'boss@example.com',
  emailVerified: true,
  isSuperAdmin: true,
);
const _a = GroupId('a');
const _b = GroupId('b');

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  Future<ProviderContainer> container({
    AuthUser? user = _coach,
    FakeUserRepository? users,
    FakeLocalPrefs? prefs,
    List<dynamic> memberships = const [],
    FakeAuthRepository? auth,
  }) async {
    final c = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          auth ?? FakeAuthRepository(user: user),
        ),
        userRepositoryProvider.overrideWithValue(users ?? FakeUserRepository()),
        localPrefsRepositoryProvider.overrideWithValue(
          prefs ?? FakeLocalPrefs(),
        ),
        memberRepositoryProvider.overrideWithValue(
          FakeMemberRepository(memberships.cast()),
        ),
        groupRepositoryProvider.overrideWithValue(
          FakeGroupRepository({
            'a': testGroup('a', 'Thunder'),
            'b': testGroup('b', 'Comets'),
          }),
        ),
      ],
    );
    addTearDown(c.dispose);
    c
      ..listen(myProfileProvider, (_, _) {})
      ..listen(myMembershipsProvider, (_, _) {});
    await _settle();
    return c;
  }

  group('teamScheme', () {
    test('is my pick for the team, else my default', () async {
      final c = await container(
        users: FakeUserRepository()..colorScheme = TeamScheme.light,
        memberships: [
          testMembership('a', 'coach').copyWith(colorScheme: TeamScheme.navy),
          testMembership('b', 'coach'),
        ],
      );
      expect(c.read(teamSchemeProvider(_a)), TeamScheme.navy);
      expect(c.read(teamSchemeProvider(_b)), TeamScheme.light);
    });

    test("with no membership yet, this device's copy, else my default", () {
      // Memberships still loading: the auth stream never says who's in.
      final prefs = FakeLocalPrefs()
        ..teamSchemes = {'a': TeamScheme.skyblue}
        ..teamSchemesUid = 'coach'
        ..defaultSchemeValue = TeamScheme.dark;
      final c = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          userRepositoryProvider.overrideWithValue(FakeUserRepository()),
          localPrefsRepositoryProvider.overrideWithValue(prefs),
          memberRepositoryProvider.overrideWithValue(FakeMemberRepository([])),
          groupRepositoryProvider.overrideWithValue(FakeGroupRepository({})),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(teamSchemeProvider(_a)), TeamScheme.skyblue);
      expect(c.read(teamSchemeProvider(_b)), TeamScheme.dark);
    });

    test('a super admin viewing a team gets their default', () async {
      final c = await container(
        user: _boss,
        users: FakeUserRepository()..colorScheme = TeamScheme.navy,
        memberships: [testMembership('b', 'boss')],
      );
      expect(c.read(viewingAsSuperAdminProvider(_a)), isTrue);
      expect(c.read(teamSchemeProvider(_a)), TeamScheme.navy);
    });

    test('the device keeps a copy of my picks, and only mine', () async {
      final prefs = FakeLocalPrefs();
      final c = await container(
        prefs: prefs,
        memberships: [
          testMembership('a', 'coach').copyWith(colorScheme: TeamScheme.navy),
          testMembership('b', 'coach'),
        ],
      );
      c.listen(teamSchemeCacheProvider, (_, _) {});
      await _settle();
      expect(prefs.teamSchemesUid, 'coach');
      expect(prefs.teamSchemes, {'a': TeamScheme.navy});
    });
  });

  group('appScheme', () {
    test('is Army green once auth has loaded with nobody signed in', () async {
      final c = await container(
        user: null,
        prefs: FakeLocalPrefs()..defaultSchemeValue = TeamScheme.navy,
      );
      expect(c.read(appSchemeProvider), TeamScheme.army);
    });

    test("is this device's default while auth loads", () {
      final c = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          userRepositoryProvider.overrideWithValue(FakeUserRepository()),
          localPrefsRepositoryProvider.overrideWithValue(
            FakeLocalPrefs()..defaultSchemeValue = TeamScheme.skyblue,
          ),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(appSchemeProvider), TeamScheme.skyblue);
    });
  });

  group('DefaultSchemeController', () {
    test("the account's default wins over the device's", () async {
      final prefs = FakeLocalPrefs()..defaultSchemeValue = TeamScheme.light;
      final c = await container(
        prefs: prefs,
        users: FakeUserRepository()..colorScheme = TeamScheme.dark,
      );
      expect(c.read(defaultSchemeControllerProvider), TeamScheme.dark);
      // And the device remembers it for next time.
      expect(prefs.defaultSchemeValue, TeamScheme.dark);
      expect(prefs.defaultSchemeUid, 'coach');
    });

    test('counts a profile that loaded before it was first read', () async {
      final c = await container(
        users: FakeUserRepository()..colorScheme = TeamScheme.navy,
      );
      // myProfile is already loaded (container listens to it).
      expect(c.read(defaultSchemeControllerProvider), TeamScheme.navy);
    });

    test('set applies at once, saves on the device and the account', () async {
      final users = FakeUserRepository();
      final prefs = FakeLocalPrefs();
      final c = await container(users: users, prefs: prefs);
      c.listen(defaultSchemeControllerProvider, (_, _) {});
      expect(c.read(defaultSchemeControllerProvider), TeamScheme.army);
      final saving = c
          .read(defaultSchemeControllerProvider.notifier)
          .set(TeamScheme.skyblue);
      expect(c.read(defaultSchemeControllerProvider), TeamScheme.skyblue);
      await saving;
      await _settle();
      expect(users.colorScheme, TeamScheme.skyblue);
      expect(prefs.defaultSchemeValue, TeamScheme.skyblue);
      expect(c.read(defaultSchemeControllerProvider), TeamScheme.skyblue);
    });
  });
}
