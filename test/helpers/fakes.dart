import 'dart:async';
import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/domain/auth_repository.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/auth/domain/user_profile.dart';
import 'package:battleplan/features/auth/domain/user_repository.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/group_repository.dart';
import 'package:battleplan/features/groups/domain/invite.dart';
import 'package:battleplan/features/groups/domain/invite_repository.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/notifications/domain/push_repository.dart';
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
    verificationEmailsSent++;
    _controller.add(_user);
  }

  @override
  Future<void> signInWithApple() async {}

  final List<String> resetEmails = [];
  int verificationEmailsSent = 0;

  @override
  Future<void> sendEmailVerification() async => verificationEmailsSent++;

  @override
  Future<void> reloadUser() async {}

  @override
  Future<void> sendPasswordReset(String email) async => resetEmails.add(email);

  bool signedOutEverywhere = false;

  @override
  Future<void> signOutEverywhere() async {
    signedOutEverywhere = true;
    await signOut();
  }

  /// When true, method changes need a fresh sign-in first.
  bool needsRecentLogin = false;
  String? reauthedWith;
  String? emailChangeTo;

  void _requireRecent() {
    if (needsRecentLogin) throw const RequiresRecentLogin();
  }

  void _setProviders(List<String> ids) {
    _user = _user!.copyWith(providerIds: ids);
    _controller.add(_user);
  }

  @override
  Future<void> linkGoogle() async {
    _requireRecent();
    _setProviders([..._user!.providerIds, 'google.com']);
  }

  @override
  Future<void> unlink(String providerId) async {
    _requireRecent();
    _setProviders([..._user!.providerIds]..remove(providerId));
  }

  @override
  Future<void> setPassword(String newPassword) async {
    _requireRecent();
    if (!_user!.providerIds.contains('password')) {
      _setProviders([..._user!.providerIds, 'password']);
    }
  }

  @override
  Future<void> changeEmail(String newEmail) async {
    _requireRecent();
    emailChangeTo = newEmail;
  }

  @override
  Future<void> reauthenticateWithPassword(String password) async {
    if (password != FakeAuthRepository.password) throw const InvalidInput();
    reauthedWith = 'password';
    needsRecentLogin = false;
  }

  @override
  Future<void> reauthenticateWithProvider(String providerId) async {
    reauthedWith = providerId;
    needsRecentLogin = false;
  }

  bool deleted = false;

  @override
  Future<void> deleteAccount() async {
    _requireRecent();
    deleted = true;
    await signOut();
  }

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

  final List<String> updates = [];

  @override
  Future<void> updateGroup(
    GroupId id, {
    String? name,
    Sport? sport,
    String? color,
    String? description,
    String? timeZone,
    GroupSettings? settings,
  }) async {
    final g = groups[id.value]!;
    groups[id.value] = g.copyWith(
      name: name ?? g.name,
      settings: settings ?? g.settings,
    );
    updates.add(
      settings != null ? 'settings' : (name != null ? 'name $name' : 'other'),
    );
  }

  @override
  Future<void> uploadLogo(GroupId id, Uint8List jpegBytes) async {}

  @override
  Future<String?> photoUrl(String path) async => null;

  @override
  Future<void> transferOwnership(GroupId id, UserId newOwner) async =>
      updates.add('transfer ${newOwner.value}');

  /// Set to make leave() behave as if the caller owns the team.
  bool callerIsOwner = false;

  @override
  Future<void> leave(GroupId id) async {
    if (callerIsOwner) throw const OwnerMustTransfer();
    updates.add('leave ${id.value}');
  }

  @override
  Future<void> setArchived(GroupId id, {required bool archived}) async =>
      updates.add(archived ? 'archive' : 'restore');

  @override
  Future<void> deleteGroup(GroupId id, String confirmName) async =>
      updates.add('delete $confirmName');

  final List<String> created = [];

  @override
  Future<GroupId> createGroup({
    required String name,
    required Sport sport,
    required TeamType teamType,
    required String timeZone,
    String? color,
    String? description,
  }) async {
    created.add(name);
    final id = 'new${created.length}';
    groups[id] = testGroup(id, name);
    return GroupId(id);
  }
}

class FakeMemberRepository implements MemberRepository {
  new(this.memberships);

  final List<Membership> memberships;

  final List<String> calls = [];

  @override
  Stream<List<Membership>> watchRoster(GroupId groupId) =>
      Stream.value(memberships.where((m) => m.groupId == groupId).toList());

  @override
  Future<void> updateMember(
    GroupId groupId,
    UserId uid, {
    MemberRole? role,
    String? title,
    bool clearTitle = false,
  }) async => calls.add('update ${uid.value} ${role?.value ?? ''}'.trim());

  @override
  Future<void> removeMember(GroupId groupId, UserId uid) async =>
      calls.add('remove ${uid.value}');

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
  String? name,
}) => Membership(
  groupId: GroupId(groupId),
  uid: UserId(uid),
  role: role,
  displayName: name ?? uid,
);

/// Profiles start set up unless [needsSetup] is true, like a returning user.
class FakeUserRepository implements UserRepository {
  new({this.needsSetup = false});

  bool needsSetup;
  final _changes = StreamController<void>.broadcast();
  String? savedName;
  ThemePreference themeMode = ThemePreference.system;
  int photosUploaded = 0;

  UserProfile _profile(String uid) => UserProfile(
    uid: uid,
    displayName: savedName ?? 'Jordan Coach',
    status: UserStatus.active,
    adultConfirmedAt: needsSetup ? null : DateTime(2026),
    acceptedTermsAt: needsSetup ? null : DateTime(2026),
    themeMode: themeMode,
  );

  @override
  Stream<UserProfile?> watchProfile(String uid) async* {
    yield _profile(uid);
    await for (final _ in _changes.stream) {
      yield _profile(uid);
    }
  }

  @override
  Future<void> updateDisplayName(String uid, String name) async {
    savedName = name;
    _changes.add(null);
  }

  @override
  Future<void> setThemeMode(String uid, ThemePreference mode) async {
    themeMode = mode;
    _changes.add(null);
  }

  @override
  Future<void> uploadPhoto(String uid, Uint8List jpegBytes) async =>
      photosUploaded++;

  @override
  Future<String?> photoUrl(String path) async => null;

  @override
  Future<void> ensureProfile({
    String? displayName,
    bool finishSetup = false,
  }) async {
    if (!finishSetup) return;
    savedName = displayName;
    needsSetup = false;
    _changes.add(null);
  }
}

class FakePushRepository implements PushRepository {
  int unregistered = 0;

  @override
  Future<String?> requestPermissionAndGetToken() async => null;

  @override
  Future<void> unregister() async => unregistered++;

  @override
  Stream<PushMessage> foregroundMessages() => const Stream.empty();
}

class FakeInviteRepository implements InviteRepository {
  int resets = 0;
  String code = 'K7XPM2QR';

  TeamInvite _invite() => TeamInvite(
    code: code,
    display: '${code.substring(0, 4)}-${code.substring(4)}',
    url: Uri.parse('https://battleplan-dev-ecce4.web.app/join/$code'),
    useCount: 0,
  );

  @override
  Future<TeamInvite> teamInvite(GroupId groupId) async => _invite();

  final List<String> redeemed = [];

  @override
  Future<InvitePreview> preview(String code) async {
    if (code != 'K7XPM2QR') throw const InviteUnusable('unknown');
    return const InvitePreview(
      groupId: 'a',
      name: 'Thunder',
      sport: Sport.softball,
      teamType: TeamType.adult,
      memberCount: 12,
      invitedBy: 'Alex Kim',
    );
  }

  @override
  Future<JoinResult> redeem(String code) async {
    redeemed.add(code);
    return const JoinResult(
      groupId: 'a',
      teamType: TeamType.adult,
      alreadyMember: false,
    );
  }

  @override
  Future<TeamInvite> resetTeamInvite(
    GroupId groupId, {
    InviteExpiry expiry = InviteExpiry.never,
    int? maxUses,
  }) async {
    resets++;
    code = 'NEWC0DE2'.replaceAll('0', 'Q');
    return _invite();
  }
}
