import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/domain/auth_repository.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/group_repository.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/settings/domain/local_prefs_repository.dart';

class FakeAuthRepository implements AuthRepository {
  new({AuthUser? user}) : _user = user {
    _controller.add(user);
  }

  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;

  static const password = 'password';
  static const knownEmail = 'coach@example.com';

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> watchUser() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (email != knownEmail || password != FakeAuthRepository.password) {
      throw const InvalidInput();
    }
    _user = const AuthUser(
      uid: 'coach',
      email: knownEmail,
      emailVerified: true,
    );
    _controller.add(_user);
  }

  @override
  Future<void> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    if (email == knownEmail) throw const EmailAlreadyInUse();
    _user = AuthUser(
      uid: 'new-user',
      email: email,
      displayName: name,
      emailVerified: false,
    );
    _controller.add(_user);
  }

  @override
  Future<void> signInWithApple() async {}

  /// When true, Google sign-in behaves as if the person closed the sheet.
  bool googleCancels = false;

  @override
  Future<void> signInWithGoogle() async {
    if (googleCancels) return;
    _user = const AuthUser(
      uid: 'coach',
      email: knownEmail,
      emailVerified: true,
    );
    _controller.add(_user);
  }

  final List<String> sentLinks = [];

  @override
  Future<void> sendSignInLink(String email) async => sentLinks.add(email);

  @override
  bool isSignInLink(Uri link) => link.queryParameters['mode'] == 'signIn';

  @override
  Future<void> signInWithLink({
    required String email,
    required Uri link,
  }) async {
    _user = AuthUser(uid: 'coach', email: email, emailVerified: true);
    _controller.add(_user);
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}

class FakeGroupRepository implements GroupRepository {
  new(this.groups);

  final Map<String, Group> groups;

  @override
  Stream<Group?> watchGroup(GroupId id) => Stream.value(groups[id.value]);
}

class FakeMemberRepository implements MemberRepository {
  new(this.memberships);

  final List<Membership> memberships;

  @override
  Stream<List<Membership>> watchMyMemberships(UserId uid) =>
      Stream.value(memberships.where((m) => m.uid == uid).toList());
}

class FakeLocalPrefs implements LocalPrefsRepository {
  @override
  ThemePreference themePreference = ThemePreference.system;

  @override
  String? lastTeamRoute;

  @override
  String? pendingSignInEmail;

  @override
  Future<void> setPendingSignInEmail(String? email) async =>
      pendingSignInEmail = email;

  @override
  Future<void> setLastTeamRoute(String route) async => lastTeamRoute = route;

  @override
  Future<void> setThemePreference(ThemePreference value) async =>
      themePreference = value;
}

Group testGroup(String id, String name, {DateTime? lastMessageAt}) => Group(
  id: GroupId(id),
  name: name,
  sport: Sport.soccer,
  teamType: TeamType.adult,
  memberCount: 3,
  lastMessageAt: lastMessageAt,
);

Membership testMembership(
  String groupId,
  String uid, {
  MemberRole role = MemberRole.member,
}) => Membership(
  groupId: GroupId(groupId),
  uid: UserId(uid),
  role: role,
  displayName: uid,
);
