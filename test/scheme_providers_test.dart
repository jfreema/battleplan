// Which color scheme each screen uses (SPEC SET-2, ARCH §5.5): my pick for
// a team, my default, and this device's copies of both for a cold start.

import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/groups/application/providers.dart'
    hide group;
import 'package:battleplan/features/groups/domain/group.dart';
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

/// Teams read the way the rules let them be: only while someone is signed
/// in. A read open when they sign out gets "unreadable" and nothing after,
/// as Firestore's does, and a read begun signed out gets it at once.
class _SignedInGroups extends FakeGroupRepository {
  new(super.groups);

  bool signedIn = true;
  final _signedOut = StreamController<void>.broadcast();

  void signOut() {
    signedIn = false;
    _signedOut.add(null);
  }

  @override
  Stream<Group?> watchGroup(GroupId id) {
    if (!signedIn) return Stream.value(null);
    final out = StreamController<Group?>()..add(groups[id.value]);
    final refused = _signedOut.stream.listen((_) => out.add(null));
    out.onCancel = refused.cancel;
    return out.stream;
  }
}

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  // The team read listens for the app coming back (groupProvider).
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<ProviderContainer> container({
    AuthUser? user = _coach,
    FakeUserRepository? users,
    FakeLocalPrefs? prefs,
    List<dynamic> memberships = const [],
    FakeAuthRepository? auth,
    FakeGroupRepository? groups,
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
          groups ??
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
      ..listen(myMembershipsProvider, (_, _) {})
      // My teams' reads, as the app keeps them.
      ..listen(myTeamsProvider, (_, _) {});
    await _settle();
    return c;
  }

  group("resolveTeamScheme (owner's request 2026-11-08)", () {
    test('my explicit pick, else the team default, else my default', () {
      expect(
        resolveTeamScheme(
          pick: TeamScheme.dark,
          teamDefault: TeamScheme.army,
          mine: TeamScheme.light,
        ),
        TeamScheme.dark,
      );
      expect(
        resolveTeamScheme(
          pick: null,
          teamDefault: TeamScheme.army,
          mine: TeamScheme.light,
        ),
        TeamScheme.army,
      );
      expect(
        resolveTeamScheme(pick: null, teamDefault: null, mine: TeamScheme.army),
        TeamScheme.army,
      );
    });
  });

  group('teamScheme', () {
    FakeGroupRepository armyThunder() => FakeGroupRepository({
      'a': testGroup('a', 'Thunder').copyWith(colorScheme: TeamScheme.army),
      'b': testGroup('b', 'Comets'),
    });

    test("is the team's default when I haven't picked, live", () async {
      final groups = armyThunder();
      final c = await container(
        users: FakeUserRepository()..colorScheme = TeamScheme.light,
        groups: groups,
        memberships: [
          testMembership('a', 'coach'),
          testMembership('b', 'coach'),
        ],
      );
      c.listen(teamSchemeProvider(_a), (_, _) {});
      await _settle();
      expect(c.read(teamSchemeProvider(_a)), TeamScheme.army);
      // No team default: my own.
      expect(c.read(teamSchemeProvider(_b)), TeamScheme.light);
      // An admin changes it: it reaches me.
      groups.setGroup(
        groups.groups['a']!.copyWith(colorScheme: TeamScheme.dark),
      );
      await _settle();
      expect(c.read(teamSchemeProvider(_a)), TeamScheme.dark);
    });

    test("my explicit pick wins over the team's default", () async {
      final groups = armyThunder();
      final c = await container(
        groups: groups,
        memberships: [
          testMembership('a', 'coach').copyWith(colorScheme: TeamScheme.dark),
        ],
      );
      c.listen(teamSchemeProvider(_a), (_, _) {});
      expect(c.read(teamSchemeProvider(_a)), TeamScheme.dark);
      groups.setGroup(
        groups.groups['a']!.copyWith(colorScheme: TeamScheme.light),
      );
      await _settle();
      expect(c.read(teamSchemeProvider(_a)), TeamScheme.dark);
    });

    test("a super admin viewing a team isn't given its default", () async {
      final c = await container(
        user: _boss,
        groups: armyThunder(),
        users: FakeUserRepository()..colorScheme = TeamScheme.light,
        memberships: [testMembership('b', 'boss')],
      );
      expect(c.read(teamSchemeProvider(_a)), TeamScheme.light);
    });

    test("the device keeps the team's default for a cold start", () async {
      final prefs = FakeLocalPrefs();
      final c = await container(
        prefs: prefs,
        groups: armyThunder(),
        memberships: [
          testMembership('a', 'coach'),
          testMembership('b', 'coach').copyWith(colorScheme: TeamScheme.dark),
        ],
      );
      c.listen(teamSchemeCacheProvider, (_, _) {});
      await _settle();
      expect(prefs.teamSchemes, {'a': TeamScheme.army, 'b': TeamScheme.dark});
    });

    test(
      "keeps the device's copy for a team whose read hasn't come back",
      () async {
        // Team c is in my memberships but its own read has nothing yet.
        final prefs = FakeLocalPrefs()
          ..teamSchemes = {'c': TeamScheme.army, 'gone': TeamScheme.dark}
          ..teamSchemesUid = 'coach';
        final c = await container(
          prefs: prefs,
          groups: armyThunder(),
          memberships: [
            testMembership('a', 'coach'),
            testMembership('c', 'coach'),
          ],
        );
        c.listen(teamSchemeCacheProvider, (_, _) {});
        await _settle();
        expect(prefs.teamSchemes, {'a': TeamScheme.army, 'c': TeamScheme.army});
      },
    );

    test('is my pick for the team, else my default', () async {
      final c = await container(
        users: FakeUserRepository()..colorScheme = TeamScheme.light,
        memberships: [
          testMembership('a', 'coach').copyWith(colorScheme: TeamScheme.army),
          testMembership('b', 'coach'),
        ],
      );
      expect(c.read(teamSchemeProvider(_a)), TeamScheme.army);
      expect(c.read(teamSchemeProvider(_b)), TeamScheme.light);
    });

    test("with no membership yet, this device's copy, else my default", () {
      // Memberships still loading: the auth stream never says who's in.
      final prefs = FakeLocalPrefs()
        ..teamSchemes = {'a': TeamScheme.army}
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
      expect(c.read(teamSchemeProvider(_a)), TeamScheme.army);
      expect(c.read(teamSchemeProvider(_b)), TeamScheme.dark);
    });

    test('a super admin viewing a team gets their default', () async {
      final c = await container(
        user: _boss,
        users: FakeUserRepository()..colorScheme = TeamScheme.army,
        memberships: [testMembership('b', 'boss')],
      );
      expect(c.read(viewingAsSuperAdminProvider(_a)), isTrue);
      expect(c.read(teamSchemeProvider(_a)), TeamScheme.army);
    });

    test(
      'a pick the app no longer offers reads as the closest of the '
      'twelve, and is never rewritten (#85, #86, #89, #90, #98, #105, #106)',
      () async {
        final users = FakeUserRepository()..colorScheme = TeamScheme.dark;
        final c = await container(
          users: users,
          groups: FakeGroupRepository({
            'a': testGroup('a', 'Thunder'),
            'b': testGroup(
              'b',
              'Comets',
            ).copyWith(colorScheme: TeamScheme.candypop),
          }),
          memberships: [
            // Scoreboard left in #85.
            testMembership(
              'a',
              'coach',
            ).copyWith(colorScheme: TeamScheme.scoreboard),
            testMembership('b', 'coach'),
          ],
        );
        c
          ..listen(teamSchemeProvider(_a), (_, _) {})
          ..listen(teamSchemeProvider(_b), (_, _) {});
        await _settle();
        expect(c.read(teamSchemeProvider(_a)), TeamScheme.dark);
        // Candy Pop is a Boot Camp Mix scheme again (#86).
        expect(c.read(teamSchemeProvider(_b)), TeamScheme.candypop);
        // Nothing is written back.
        expect(users.colorScheme, TeamScheme.dark);
      },
    );

    test("keeps no read of a team I'm not on once nothing shows it", () async {
      final c = await container(
        user: _boss,
        memberships: [testMembership('b', 'boss')],
      );
      final sub = c.listen(teamSchemeProvider(_a), (_, _) {});
      await _settle();
      sub.close();
      await _settle();
      // Kept for the session, but not the team's own read.
      expect(c.exists(teamSchemeProvider(_a)), isTrue);
      expect(c.exists(groupProvider(_a)), isFalse);
    });

    // Found by the end-to-end test, 2026-11-16: this provider, kept for
    // the session and read by nothing once its team's screens close, still
    // held the team's read when the coach signed out. The rules ended that
    // read as unreadable, and a parent who then joined the team on the
    // same phone waited for the 30-second retry to see it.
    test('the next person to sign in reads our team at once', () async {
      final auth = FakeAuthRepository(user: _coach);
      final groups = _SignedInGroups({'a': testGroup('a', 'Thunder')});
      final c = await container(
        auth: auth,
        groups: groups,
        memberships: [
          testMembership('a', 'coach'),
          testMembership('a', 'new-user'),
        ],
      );
      // The coach has the team open, then leaves it and signs out.
      final shown = c.listen(teamSchemeProvider(_a), (_, _) {});
      await _settle();
      expect(c.read(myTeamsProvider).value!.single.group.name, 'Thunder');
      shown.close();
      groups.signOut();
      await auth.signOut();
      await _settle();
      expect(c.read(myTeamsProvider).value, isEmpty);

      // A parent on the same team signs in.
      groups.signedIn = true;
      await auth.createAccount(
        name: 'Pat Parent',
        email: 'pat@example.com',
        password: 'longenough',
      );
      await _settle();
      expect(c.read(groupProvider(_a)).value?.name, 'Thunder');
      expect(c.read(myTeamsProvider).value!.single.group.name, 'Thunder');
    });

    test('the device keeps a copy of my picks, and only mine', () async {
      final prefs = FakeLocalPrefs();
      final c = await container(
        prefs: prefs,
        memberships: [
          testMembership('a', 'coach').copyWith(colorScheme: TeamScheme.army),
          testMembership('b', 'coach'),
        ],
      );
      c.listen(teamSchemeCacheProvider, (_, _) {});
      await _settle();
      expect(prefs.teamSchemesUid, 'coach');
      expect(prefs.teamSchemes, {'a': TeamScheme.army});
    });
  });

  group('appScheme', () {
    test('is the default, Black, once auth has loaded with nobody signed in '
        "(owner's request 2026-11-10)", () async {
      final c = await container(
        user: null,
        prefs: FakeLocalPrefs()..defaultSchemeValue = TeamScheme.army,
      );
      expect(c.read(appSchemeProvider), TeamScheme.dark);
    });

    test("is this device's default while auth loads", () {
      final c = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          userRepositoryProvider.overrideWithValue(FakeUserRepository()),
          localPrefsRepositoryProvider.overrideWithValue(
            FakeLocalPrefs()..defaultSchemeValue = TeamScheme.light,
          ),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(appSchemeProvider), TeamScheme.light);
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
        users: FakeUserRepository()..colorScheme = TeamScheme.army,
      );
      // myProfile is already loaded (container listens to it).
      expect(c.read(defaultSchemeControllerProvider), TeamScheme.army);
    });

    test('set applies at once, saves on the device and the account', () async {
      final users = FakeUserRepository();
      final prefs = FakeLocalPrefs();
      final c = await container(users: users, prefs: prefs);
      c.listen(defaultSchemeControllerProvider, (_, _) {});
      // An account that never picked one starts on the default, Black.
      expect(c.read(defaultSchemeControllerProvider), TeamScheme.dark);
      final saving = c
          .read(defaultSchemeControllerProvider.notifier)
          .set(TeamScheme.army);
      expect(c.read(defaultSchemeControllerProvider), TeamScheme.army);
      await saving;
      await _settle();
      expect(users.colorScheme, TeamScheme.army);
      expect(prefs.defaultSchemeValue, TeamScheme.army);
      expect(c.read(defaultSchemeControllerProvider), TeamScheme.army);
    });
  });
}
