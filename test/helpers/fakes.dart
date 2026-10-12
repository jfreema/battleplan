import 'dart:async';
import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/browser_info.dart';
import 'package:battleplan/core/services/calendar.dart';
import 'package:battleplan/core/services/photo_picker.dart';
import 'package:battleplan/features/auth/domain/auth_repository.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/auth/domain/user_profile.dart';
import 'package:battleplan/features/auth/domain/user_repository.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/domain/message_repository.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/group_repository.dart';
import 'package:battleplan/features/groups/domain/invite.dart';
import 'package:battleplan/features/groups/domain/invite_repository.dart';
import 'package:battleplan/features/groups/domain/media.dart';
import 'package:battleplan/features/groups/domain/media_repository.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/notifications/domain/device_repository.dart';
import 'package:battleplan/features/notifications/domain/notification_item.dart';
import 'package:battleplan/features/notifications/domain/notification_repository.dart';
import 'package:battleplan/features/notifications/domain/push_repository.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/domain/player_repository.dart';
import 'package:battleplan/features/polls/domain/poll.dart';
import 'package:battleplan/features/polls/domain/poll_repository.dart';
import 'package:battleplan/features/safety/domain/safety.dart';
import 'package:battleplan/features/safety/domain/safety_repository.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/event_draft.dart';
import 'package:battleplan/features/schedule/domain/event_repository.dart';
import 'package:battleplan/features/schedule/domain/recurrence.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart';
import 'package:battleplan/features/schedule/domain/rsvp_repository.dart';
import 'package:battleplan/features/settings/domain/local_prefs_repository.dart';

class FakeAuthRepository implements AuthRepository {
  new({AuthUser? user, List<String>? log}) : _user = user, log = log ?? [] {
    _controller.add(user);
  }

  /// Shared with other fakes to check the order of calls across them.
  final List<String> log;

  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;

  static const password = 'password';
  static const knownEmail = 'coach@example.com';

  @override
  AuthUser? get currentUser => _user;

  /// The session ends without the app signing out: a password change or
  /// Sign out everywhere on another device.
  void endSessionElsewhere() {
    _user = null;
    _controller.add(null);
  }

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
    log.add('auth signOut');
    _user = null;
    _controller.add(null);
  }
}

class FakeGroupRepository implements GroupRepository {
  new(this.groups);

  final Map<String, Group> groups;

  ChatTheme? savedTheme;

  @override
  Future<void> updateChatTheme(GroupId id, ChatTheme theme) async {
    savedTheme = theme;
    updates.add('chatTheme');
  }

  @override
  Future<String> uploadChatBackground(GroupId id, Uint8List jpegBytes) async =>
      'groups/${id.value}/theme/bg.jpg';

  final _changes = StreamController<String>.broadcast();

  /// Replaces a team and tells anyone watching it, like a server write.
  void setGroup(Group group) {
    groups[group.id.value] = group;
    _changes.add(group.id.value);
  }

  @override
  Stream<Group?> watchGroup(GroupId id) async* {
    yield groups[id.value];
    await for (final changed in _changes.stream) {
      if (changed == id.value) yield groups[id.value];
    }
  }

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

  int logosUploaded = 0;

  @override
  Future<void> uploadLogo(GroupId id, Uint8List jpegBytes) async =>
      logosUploaded++;

  @override
  Future<void> setStorageQuota(GroupId id, int quotaMb) async =>
      updates.add('quota ${id.value} $quotaMb');

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
  final _changes = StreamController<void>.broadcast();

  final List<String> calls = [];

  void _updateMine(
    GroupId groupId,
    UserId uid,
    Membership Function(Membership) f,
  ) {
    final i = memberships.indexWhere(
      (m) => m.groupId == groupId && m.uid == uid,
    );
    if (i < 0) return;
    memberships[i] = f(memberships[i]);
    _changes.add(null);
  }

  @override
  Future<void> setNotificationLevel(
    GroupId groupId,
    UserId uid,
    NotificationLevel level,
  ) async {
    calls.add('level ${groupId.value} ${level.value}');
    _updateMine(groupId, uid, (m) => m.copyWith(notificationLevel: level));
  }

  DateTime? mutedUntil;

  @override
  Future<void> setMutedUntil(
    GroupId groupId,
    UserId uid,
    DateTime? until,
  ) async {
    calls.add('mute ${groupId.value} ${until == null ? 'off' : 'on'}');
    mutedUntil = until;
    _updateMine(groupId, uid, (m) => m.copyWith(mutedUntil: until));
  }

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
  Future<AddMembersResult> addByEmail(
    GroupId groupId,
    List<({String? name, String email})> entries,
  ) async {
    calls.add('add ${entries.map((e) => e.email).join(',')}');
    return AddMembersResult(
      added: 0,
      invited: entries.length,
      alreadyMembers: 0,
    );
  }

  @override
  Future<void> resendSetupEmail(GroupId groupId, UserId uid) async =>
      calls.add('resend ${uid.value}');

  @override
  Stream<List<Membership>> watchMyMemberships(UserId uid) async* {
    List<Membership> mine() => memberships.where((m) => m.uid == uid).toList();
    yield mine();
    await for (final _ in _changes.stream) {
      yield mine();
    }
  }

  final List<String> reads = [];

  @override
  Future<void> markRead(GroupId groupId, UserId uid) async =>
      reads.add(groupId.value);
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

  @override
  String installId = 'test-install-0000000000000';

  @override
  bool pushPrePromptShown = false;

  @override
  Future<void> setPushPrePromptShown() async => pushPrePromptShown = true;

  @override
  DeviceRegistration? deviceRegistration;

  @override
  Future<void> setDeviceRegistration(DeviceRegistration? value) async =>
      deviceRegistration = value;
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

  final Map<NotificationPref, bool> notificationPrefs = {};

  UserProfile _profile(String uid) => UserProfile(
    uid: uid,
    displayName: savedName ?? 'Jordan Coach',
    status: UserStatus.active,
    adultConfirmedAt: needsSetup ? null : DateTime(2026),
    acceptedTermsAt: needsSetup ? null : DateTime(2026),
    themeMode: themeMode,
    notificationPrefs: {...notificationPrefs},
  );

  @override
  Future<void> setNotificationPref(
    String uid,
    NotificationPref pref, {
    required bool enabled,
  }) async {
    notificationPrefs[pref] = enabled;
    _changes.add(null);
  }

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

/// Push on a pretend device. Permission starts granted with a token, so
/// the pre-prompt stays away unless a test sets [permission] to
/// notDetermined. [answer] is what the system prompt returns.
class FakePushRepository implements PushRepository {
  new({
    this.permission = PushPermission.authorized,
    this.answer = PushPermission.authorized,
    this.token = 'fcm-token-1',
    this.launchMessage,
    this.tokenAfterDelete,
    List<String>? log,
  }) : log = log ?? [];

  PushPermission permission;
  PushPermission answer;
  String? token;
  PushMessage? launchMessage;
  final List<String> log;

  /// A new token FCM reports right after the old one is deleted.
  String? tokenAfterDelete;

  int permissionRequests = 0;
  int tokensDeleted = 0;

  final foreground = StreamController<PushMessage>.broadcast();
  final opened = StreamController<PushMessage>.broadcast();
  final refreshes = StreamController<String>.broadcast();

  @override
  DevicePlatform get platform => DevicePlatform.android;

  @override
  Future<PushPermission> permissionStatus() async => permission;

  @override
  Future<PushPermission> requestPermission() async {
    permissionRequests++;
    return permission = answer;
  }

  @override
  Future<String?> currentToken() async =>
      permission == PushPermission.authorized ? token : null;

  @override
  Stream<String> tokenRefreshes() => refreshes.stream;

  @override
  Stream<PushMessage> foregroundMessages() => foreground.stream;

  @override
  Stream<PushMessage> openedMessages() => opened.stream;

  @override
  Future<PushMessage?> initialMessage() async => launchMessage;

  /// When true, deleting the token fails, as it does offline.
  bool deleteFails = false;

  @override
  Future<bool> deleteToken() async {
    log.add('push deleteToken');
    if (deleteFails) return false;
    tokensDeleted++;
    if (tokenAfterDelete case final next?) {
      token = next;
      refreshes.add(next);
    }
    return true;
  }
}

/// Device docs in memory, by install ID.
class FakeDeviceRepository implements DeviceRepository {
  new({List<String>? log}) : log = log ?? [];

  final List<String> log;
  final Map<String, ({String uid, String token, DevicePlatform platform})>
  docs = {};
  int writes = 0;

  @override
  Future<void> register(
    String installId, {
    required String uid,
    required String token,
    required DevicePlatform platform,
    required String appVersion,
  }) async {
    writes++;
    log.add('device register $installId');
    docs[installId] = (uid: uid, token: token, platform: platform);
  }

  @override
  Future<void> remove(String installId) async {
    log.add('device remove $installId');
    docs.remove(installId);
  }
}

/// The notification center on an in-memory list, newest first.
class FakeNotificationRepository implements NotificationRepository {
  new([List<NotificationItem>? items]) : items = items ?? [];

  final List<NotificationItem> items;
  final List<String> markedRead = [];
  int markAllCalls = 0;
  int loadOlderCalls = 0;
  final _changes = StreamController<void>.broadcast();

  /// How long marking read takes, like a real network write.
  Duration writeDelay = Duration.zero;

  /// Loading older pages fails while this is set.
  bool failLoadOlder = false;

  /// A stale cached answer the live page sends before the server's, as
  /// Firestore does with persistence on.
  List<NotificationItem>? cachedFirst;

  @override
  Stream<NotificationPage> watchNewest(
    UserId uid, {
    int limit = Limits.notificationPageSize,
  }) async* {
    NotificationPage page() {
      final all = items;
      return NotificationPage(
        items: all.take(limit).toList(),
        next: all.length > limit ? NotificationCursor(limit) : null,
      );
    }

    if (cachedFirst case final cached?) {
      yield NotificationPage(items: cached.take(limit).toList());
    }
    yield page();
    await for (final _ in _changes.stream) {
      yield page();
    }
  }

  @override
  Future<NotificationPage> loadOlder(
    UserId uid,
    NotificationCursor after, {
    int limit = Limits.notificationPageSize,
  }) async {
    loadOlderCalls++;
    if (failLoadOlder) throw const Offline('test');
    final all = items;
    final start = after.handle as int;
    final end = (start + limit).clamp(0, all.length);
    return NotificationPage(
      items: all.sublist(start, end),
      next: end < all.length ? NotificationCursor(end) : null,
    );
  }

  @override
  Future<int> countUnread(
    UserId uid, {
    int cap = Limits.unreadCountCap,
  }) async => items.where((n) => !n.read).take(cap).length;

  @override
  Future<void> markRead(String id) async {
    markedRead.add(id);
    if (writeDelay > Duration.zero) await Future<void>.delayed(writeDelay);
    final i = items.indexWhere((n) => n.id == id);
    if (i < 0) return;
    items[i] = items[i].copyWith(read: true);
    _changes.add(null);
  }

  @override
  Future<void> markAllRead(UserId uid) async {
    markAllCalls++;
    for (var i = 0; i < items.length; i++) {
      items[i] = items[i].copyWith(read: true);
    }
    _changes.add(null);
  }
}

/// A browser that may need Add to Home Screen for push (NOTIF-9).
class FakeBrowserInfo implements BrowserInfo {
  const new({this.pushNeedsHomeScreen = false});

  @override
  final bool pushNeedsHomeScreen;
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

  final List<EmailInvite> sent = [];

  @override
  Future<int> sendEmailInvites(
    GroupId groupId,
    List<String> emails, {
    String? note,
  }) async {
    for (final (i, e) in emails.indexed) {
      sent.insert(
        0,
        EmailInvite(
          code: 'EMAIL00$i',
          email: e,
          status: EmailInviteStatus.pending,
        ),
      );
    }
    return emails.length;
  }

  @override
  Future<List<EmailInvite>> emailInvites(GroupId groupId) async => [...sent];

  final List<String> resent = [];

  @override
  Future<void> resendEmailInvite(String code) async => resent.add(code);

  @override
  Future<void> revokeInvite(String code) async {
    final i = sent.indexWhere((x) => x.code == code);
    if (i >= 0) sent[i] = sent[i].copyWith(status: EmailInviteStatus.revoked);
  }
}

class FakePlayerRepository implements PlayerRepository {
  new([List<Player>? players]) : players = players ?? [];

  final List<Player> players;
  final List<List<NewPlayer>> added = [];

  @override
  Stream<List<Player>> watchPlayers(GroupId groupId) =>
      Stream.value(players.where((p) => p.groupId == groupId).toList());

  @override
  Stream<List<GuardianLink>> watchGuardianLinks(GroupId groupId) =>
      Stream.value(links.where((l) => l.groupId == groupId).toList());

  final List<GuardianLink> links = [];

  @override
  Future<AddPlayersResult> addPlayers(
    GroupId groupId,
    List<NewPlayer> players,
  ) async {
    added.add(players);
    return AddPlayersResult(
      playersAdded: players.length,
      guardiansLinked: 0,
      guardiansInvited: players.fold(0, (n, p) => n + p.guardians.length),
    );
  }

  @override
  Future<void> updatePlayer(
    PlayerId id, {
    required String name,
    String? jerseyNumber,
    String? position,
  }) async {}

  @override
  Future<void> removePlayer(GroupId groupId, PlayerId id) async {}

  final List<GuardianRequest> requests = [];
  final List<String> calls = [];

  @override
  Stream<List<GuardianRequest>> watchPendingRequests(GroupId groupId) =>
      Stream.value(
        requests
            .where(
              (r) =>
                  r.groupId == groupId &&
                  r.status == GuardianRequestStatus.pending,
            )
            .toList(),
      );

  @override
  Stream<List<GuardianRequest>> watchMyRequests(GroupId groupId, UserId uid) =>
      Stream.value(
        requests.where((r) => r.groupId == groupId && r.uid == uid).toList(),
      );

  @override
  Future<void> requestGuardianLink(
    GroupId groupId,
    List<PlayerId> players,
  ) async => calls.add('request ${players.map((p) => p.value).join(',')}');

  @override
  Future<void> resolveGuardianRequest(
    GroupId groupId,
    PlayerId playerId,
    UserId uid, {
    required bool approve,
  }) async => calls.add(
    '${approve ? 'approve' : 'decline'} ${playerId.value} ${uid.value}',
  );

  @override
  Future<void> addMyPlayer(
    GroupId groupId, {
    required String name,
    String? jerseyNumber,
  }) async => calls.add('addMine $name #$jerseyNumber');

  @override
  Future<bool> inviteGuardian(
    GroupId groupId,
    PlayerId playerId, {
    required String email,
    String? name,
  }) async {
    calls.add('inviteGuardian ${playerId.value} $email');
    return true;
  }

  @override
  Future<void> removeGuardian(
    GroupId groupId,
    PlayerId playerId,
    UserId uid,
  ) async => calls.add('removeGuardian ${playerId.value} ${uid.value}');
}

/// Chat on an in-memory list. [sent] records what was sent; each send also
/// appears in the chat, as Firestore's local write would.
class FakeMessageRepository implements MessageRepository {
  new([List<Message>? messages]) : messages = messages ?? [];

  /// Newest first.
  final List<Message> messages;
  final List<String> sent = [];
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<MessagePage> watchNewest(GroupId groupId, {int limit = 50}) async* {
    MessagePage page() {
      final all = messages.where((m) => m.groupId == groupId).toList();
      return MessagePage(
        messages: all.take(limit).toList(),
        next: all.length > limit ? PageCursor(limit) : null,
      );
    }

    yield page();
    await for (final _ in _changes.stream) {
      yield page();
    }
  }

  @override
  Future<MessagePage> loadOlder(
    GroupId groupId,
    PageCursor before, {
    int limit = 50,
  }) async {
    final all = messages.where((m) => m.groupId == groupId).toList();
    final start = before.handle as int;
    final end = (start + limit).clamp(0, all.length);
    return MessagePage(
      messages: all.sublist(start, end),
      next: end < all.length ? PageCursor(end) : null,
    );
  }

  final List<int> photoBatches = [];

  /// Where posted polls go; pumpApp links it to the fake poll repository.
  FakePollRepository polls = FakePollRepository();

  /// Set to make posting a poll fail, as a refusal would.
  bool failPolls = false;

  @override
  Future<void> sendPoll(
    GroupId groupId,
    UserId uid,
    NewPoll poll, {
    String? id,
  }) async {
    if (failPolls) throw const PermissionDenied('poll');
    final p = poll.tidy;
    id ??= 'poll${polls.polls.length}';
    polls.put(
      Poll(
        id: PollId(id),
        groupId: groupId,
        createdBy: uid.value,
        question: p.question,
        options: [
          for (final (i, text) in p.options.indexed)
            PollOption(id: '$i', text: text),
        ],
        allowMultiple: p.allowMultiple,
        anonymous: p.anonymous,
        closesAt: p.closesAt,
      ),
    );
    messages.insert(
      0,
      Message(
        id: id,
        groupId: groupId,
        authorId: uid.value,
        authorName: uid.value,
        type: MessageType.poll,
        text: p.question,
        pollId: id,
        createdAt: DateTime.now(),
      ),
    );
    _changes.add(null);
  }

  /// How many uploads fail, as if offline, before they work again.
  int failUploads = 0;

  @override
  Future<UploadedPhotos> uploadPhotos(
    GroupId groupId,
    List<NewPhoto> photos, {
    void Function(double progress)? onProgress,
  }) async {
    if (failUploads > 0) {
      failUploads--;
      throw const Offline('upload');
    }
    onProgress?.call(1);
    final id = 'photos${photoBatches.length}';
    return (
      messageId: id,
      attachments: [
        for (var i = 0; i < photos.length; i++)
          Attachment(path: 'groups/${groupId.value}/messages/$id/$i.jpg'),
      ],
    );
  }

  @override
  Future<void> sendPhotos(
    GroupId groupId,
    UserId uid,
    UploadedPhotos photos, {
    String caption = '',
    String? replyToId,
  }) async {
    photoBatches.add(photos.attachments.length);
    messages.insert(
      0,
      Message(
        id: photos.messageId,
        groupId: groupId,
        authorId: uid.value,
        authorName: uid.value,
        type: MessageType.image,
        attachments: photos.attachments,
        createdAt: DateTime.now(),
      ),
    );
    _changes.add(null);
  }

  @override
  Future<int> countUnread(
    GroupId groupId,
    DateTime since, {
    int cap = 100,
  }) async => messages
      .where(
        (m) =>
            m.groupId == groupId &&
            (m.createdAt?.isAfter(since) ?? false) &&
            !m.isSystem,
      )
      .take(cap)
      .length;

  final List<String> deleted = [];

  @override
  Future<void> deleteMessage(String messageId) async {
    deleted.add(messageId);
    final i = messages.indexWhere((m) => m.id == messageId);
    if (i < 0) return;
    messages[i] = messages[i].copyWith(
      text: '',
      attachments: const [],
      reactions: const {},
      deletedAt: DateTime.now(),
      deletedReason: 'author',
    );
    _changes.add(null);
  }

  final List<String> edits = [];

  @override
  Future<void> editText(String messageId, String text) async {
    edits.add('$messageId $text');
    final i = messages.indexWhere((m) => m.id == messageId);
    if (i < 0) return;
    messages[i] = messages[i].copyWith(text: text, editedAt: DateTime.now());
    _changes.add(null);
  }

  @override
  Future<void> setReaction(
    String messageId,
    UserId uid,
    Reaction? reaction,
  ) async {
    final i = messages.indexWhere((m) => m.id == messageId);
    if (i < 0) return;
    final reactions = {...messages[i].reactions}..remove(uid.value);
    if (reaction != null) reactions[uid.value] = reaction;
    messages[i] = messages[i].copyWith(reactions: reactions);
    _changes.add(null);
  }

  @override
  Future<String?> attachmentUrl(String path) async => null;

  @override
  Future<Uint8List?> attachmentBytes(String path) async => null;

  int _ids = 0;

  @override
  String newMessageId() => 'new${_ids++}';

  /// When set, sends fail with this, as a server refusal would.
  AppFailure? failSends;

  @override
  Future<void> sendText(
    GroupId groupId,
    UserId uid,
    String text, {
    String? id,
    String? replyToId,
  }) async {
    if (failSends case final error?) throw error;
    sent.add(text);
    messages.insert(
      0,
      Message(
        id: id ?? 'sent${sent.length}',
        groupId: groupId,
        authorId: uid.value,
        authorName: uid.value,
        type: MessageType.text,
        text: text,
        replyToId: replyToId,
        replyPreview: replyToId == null ? null : _previewOf(replyToId),
        createdAt: DateTime.now(),
      ),
    );
    _changes.add(null);
  }

  /// What the server's trigger would write.
  ReplyPreview _previewOf(String id) {
    final o = messages.where((m) => m.id == id).firstOrNull;
    return o == null || o.deletedAt != null
        ? const ReplyPreview(authorName: '', text: '', deleted: true)
        : ReplyPreview(
            authorName: o.authorName,
            text: o.text.split('\n').first,
            type: o.type,
          );
  }
}

/// A valid 1×1 PNG, for photos the app decodes.
final tinyPng = Uint8List.fromList(const [
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0, //
  1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65,
  84, 120, 156, 99, 248, 15, 4, 0, 9, 251, 3, 253, 227, 85, 242, 156, 0,
  0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
]);

/// Returns [photos] when asked for chat photos.
class FakePhotoPicker implements PhotoPicker {
  new([this.photos = const []]);

  final List<PickedPhoto> photos;

  /// How many times a picker opened, to check full storage stops it.
  int opened = 0;

  /// Runs while the picker is open, e.g. to fill storage before the pick
  /// returns.
  void Function()? whilePicking;

  @override
  Future<Uint8List?> pickProfilePhoto() async {
    opened++;
    return null;
  }

  @override
  Future<List<PickedPhoto>> pickChatPhotos({int limit = 10}) async {
    opened++;
    whilePicking?.call();
    await Future<void>.delayed(Duration.zero);
    return photos.take(limit).toList();
  }

  @override
  Future<PickedPhoto?> takeChatPhoto() async => null;

  @override
  bool get canUseCamera => false;
}

/// Blocks and reports in memory.
class FakeSafetyRepository implements SafetyRepository {
  final List<BlockedPerson> blocks = [];
  final List<String> reports = [];
  final List<String> resolved = [];
  final List<Report> open = [];
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<List<BlockedPerson>> watchBlocked(UserId uid) async* {
    yield [...blocks];
    await for (final _ in _changes.stream) {
      yield [...blocks];
    }
  }

  @override
  Future<void> block(UserId uid, UserId blocked, {required String name}) async {
    blocks.add(BlockedPerson(uid: blocked, name: name));
    _changes.add(null);
  }

  @override
  Future<void> unblock(UserId uid, UserId blocked) async {
    blocks.removeWhere((b) => b.uid == blocked);
    _changes.add(null);
  }

  @override
  Future<void> report(
    GroupId groupId, {
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    String? details,
  }) async => reports.add('${targetType.name} $targetId ${reason.value}');

  @override
  Stream<List<Report>> watchOpenReports(GroupId groupId) async* {
    yield open.where((r) => r.groupId == groupId).toList();
    await for (final _ in _changes.stream) {
      yield open.where((r) => r.groupId == groupId).toList();
    }
  }

  @override
  Future<void> resolveReport(
    String reportId, {
    required bool actioned,
    ReportResolution resolution = ReportResolution.none,
  }) async {
    resolved.add('$reportId ${resolution.name}');
    open.removeWhere((r) => r.id == reportId);
    _changes.add(null);
  }
}

/// A team's stored files in memory. [lists] counts reads, so tests can see
/// the list refresh; [deleted] records deleted paths.
class FakeMediaRepository implements MediaRepository {
  new([List<MediaItem>? items]) : items = items ?? [];

  final List<MediaItem> items;
  final List<String> deleted = [];
  int lists = 0;
  int storageQuotaBytes = 500 * bytesPerMb;
  bool truncated = false;

  @override
  Future<TeamMedia> list(GroupId groupId) async {
    lists++;
    final sorted = [...items]..sort((a, b) => b.size.compareTo(a.size));
    return TeamMedia(
      items: sorted,
      storageBytes: items.fold(0, (n, i) => n + i.size),
      storageQuotaBytes: storageQuotaBytes,
      truncated: truncated,
    );
  }

  @override
  Future<void> delete(GroupId groupId, String path) async {
    deleted.add(path);
    items.removeWhere((i) => i.path == path);
  }
}

/// Polls and votes in memory. Votes recount the poll at once, as the
/// server's trigger does a moment later.
class FakePollRepository implements PollRepository {
  final Map<String, Poll> polls = {};

  /// Votes by poll ID, then uid.
  final Map<String, Map<String, Set<String>>> votes = {};
  final List<String> closed = [];
  final _changes = StreamController<void>.broadcast();

  /// Makes votes fail as the rules refuse them once the server closed the
  /// poll, while this device still shows it open.
  bool refuseVotes = false;

  /// Makes closing fail, as offline would.
  bool failClose = false;

  /// Adds or replaces a poll, and tells anyone watching.
  void put(Poll poll) {
    polls[poll.id.value] = poll;
    _changes.add(null);
  }

  Stream<T> _live<T>(T Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  @override
  Stream<Poll?> watchPoll(PollId pollId) => _live(() => polls[pollId.value]);

  @override
  Stream<Set<String>> watchMyVote(PollId pollId, UserId uid) =>
      _live(() => votes[pollId.value]?[uid.value] ?? const {});

  @override
  Future<void> setVote(Poll poll, UserId uid, Set<String> optionIds) async {
    final current = polls[poll.id.value]!;
    if (refuseVotes || current.isClosedAt(DateTime.now())) {
      throw const PermissionDenied('closed');
    }
    final byUid = votes.putIfAbsent(poll.id.value, () => {});
    if (optionIds.isEmpty) {
      byUid.remove(uid.value);
    } else {
      byUid[uid.value] = optionIds;
    }
    put(
      current.copyWith(
        voteCounts: {
          for (final o in current.options)
            o.id: byUid.values.where((v) => v.contains(o.id)).length,
        },
        voterCount: byUid.length,
      ),
    );
  }

  @override
  Future<List<PollVote>> loadVotes(PollId pollId) async => [
    for (final e in (votes[pollId.value] ?? const {}).entries)
      PollVote(uid: e.key, optionIds: e.value),
  ];

  @override
  Future<void> closePoll(PollId pollId) async {
    if (failClose) throw const Offline('close');
    closed.add(pollId.value);
    put(polls[pollId.value]!.copyWith(closedAt: DateTime.now()));
  }
}

/// Events and series in memory. Series calls are recorded, and do to the
/// events what the server's `saveEventSeries` does.
class FakeEventRepository implements EventRepository {
  new([List<Event>? events]) {
    for (final e in events ?? const <Event>[]) {
      this.events[e.id.value] = e;
    }
  }

  final Map<String, Event> events = {};
  final Map<String, EventSeries> series = {};

  /// What was asked of the repository, in order.
  final List<String> calls = [];

  /// The last template sent to a series call.
  EventTemplate? lastTemplate;

  /// What dry runs report (the confirmation's counts).
  SeriesResult dryRunResult = const SeriesResult();
  final _changes = StreamController<void>.broadcast();
  int _next = 0;

  /// Adds or replaces an event, and tells anyone watching.
  void put(Event e) {
    events[e.id.value] = e;
    _changes.add(null);
  }

  Stream<T> _live<T>(T Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  List<Event> _team(GroupId g) => [
    for (final e in events.values)
      if (e.groupId == g) e,
  ];

  @override
  Stream<EventPage> watchUpcoming(
    GroupId groupId,
    DateTime from, {
    int limit = 50,
  }) => _live(() {
    final list = [
      for (final e in _team(groupId))
        if (!e.startAt.isBefore(from)) e,
    ]..sort((a, b) => a.startAt.compareTo(b.startAt));
    return (events: list.take(limit).toList(), next: null);
  });

  @override
  Stream<EventPage> watchPast(
    GroupId groupId,
    DateTime before, {
    int limit = 50,
  }) => _live(() {
    final list = [
      for (final e in _team(groupId))
        if (e.startAt.isBefore(before)) e,
    ]..sort((a, b) => b.startAt.compareTo(a.startAt));
    return (events: list.take(limit).toList(), next: null);
  });

  @override
  Future<EventPage> loadMore(
    GroupId groupId,
    PageCursor cursor, {
    required bool past,
    int limit = 50,
  }) async => (events: const <Event>[], next: null);

  @override
  Stream<List<Event>> watchRange(
    GroupId groupId,
    DateTime from,
    DateTime until,
  ) => _live(
    () => [
      for (final e in _team(groupId))
        if (!e.startAt.isBefore(from) && e.startAt.isBefore(until)) e,
    ]..sort((a, b) => a.startAt.compareTo(b.startAt)),
  );

  @override
  Stream<Event?> watchEvent(EventId id) => _live(() => events[id.value]);

  @override
  Stream<EventSeries?> watchSeries(String seriesId) =>
      _live(() => series[seriesId]);

  Event _fromDraft(
    String id,
    GroupId groupId,
    EventDraft d, {
    required String createdBy,
    required bool youth,
  }) {
    final t = d.template;
    return Event(
      id: EventId(id),
      groupId: groupId,
      type: t.type,
      title: t.title,
      description: t.description,
      location: t.location,
      allDay: t.allDay,
      startAt: d.startAt!,
      endAt: d.endAt!,
      startDate: d.allDay ? dateKey(d.date!) : null,
      endDate: d.allDay ? dateKey(d.lastDay!) : null,
      timeZone: t.timeZone,
      arriveMinutesBefore: t.arriveMinutesBefore,
      opponent: t.opponent,
      homeAway: t.homeAway,
      rsvpEnabled: t.rsvpEnabled,
      rsvpFor: youth ? RsvpFor.players : RsvpFor.members,
      rsvpDeadline: d.rsvpDeadline,
      reminderOffsets: t.reminderOffsets,
      notifyTeam: t.notifyTeam,
      postToChat: t.postToChat,
      createdBy: createdBy,
    );
  }

  @override
  Future<EventId> createEvent(
    GroupId groupId,
    EventDraft draft, {
    required UserId createdBy,
    required bool youth,
  }) async {
    final id = 'new${_next++}';
    calls.add('create');
    put(
      _fromDraft(id, groupId, draft, createdBy: createdBy.value, youth: youth),
    );
    return EventId(id);
  }

  @override
  Future<void> updateEvent(Event event, EventDraft draft) async {
    calls.add('update ${event.id.value}');
    put(
      _fromDraft(
        event.id.value,
        event.groupId,
        draft,
        createdBy: event.createdBy,
        youth: event.forPlayers,
      ).copyWith(rsvpCounts: event.rsvpCounts),
    );
  }

  @override
  Future<void> cancelEvent(Event event, UserId by) async {
    calls.add('cancel ${event.id.value}');
    put(
      events[event.id.value]!.copyWith(
        canceledAt: DateTime.now(),
        canceledBy: by.value,
      ),
    );
  }

  @override
  Future<void> deleteEvent(Event event) async {
    calls.add('delete ${event.id.value}');
    events.remove(event.id.value);
    _changes.add(null);
  }

  /// Set to make series calls fail as full storage does (STORE-4).
  bool storageFull = false;

  @override
  Future<SeriesResult> createSeries(
    GroupId groupId,
    Recurrence recurrence,
    EventTemplate template, {
    bool dryRun = false,
  }) async {
    if (storageFull) throw const StorageFull();
    lastTemplate = template;
    final dates = expandRecurrence(recurrence).dates;
    calls.add('createSeries ${dates.length}${dryRun ? ' dry' : ''}');
    if (dryRun) return SeriesResult(created: dates.length);
    final seriesId = 's${_next++}';
    series[seriesId] = EventSeries(
      id: seriesId,
      groupId: groupId,
      timeZone: template.timeZone,
      recurrence: recurrence,
      createdBy: 'coach',
    );
    for (final key in dates) {
      int minutes(String? hhmm) => hhmm == null
          ? 0
          : int.parse(hhmm.split(':')[0]) * 60 + int.parse(hhmm.split(':')[1]);
      final draft = EventDraft(
        timeZone: template.timeZone,
        type: template.type,
        title: template.title,
        allDay: template.allDay,
        date: parseDateKey(key),
        startMinutes: minutes(template.startTime),
        endMinutes: minutes(template.endTime),
      );
      events['$seriesId-$key'] = Event(
        id: EventId('$seriesId-$key'),
        groupId: groupId,
        type: template.type,
        title: template.title,
        startAt: draft.startAt!,
        endAt: draft.endAt!,
        timeZone: template.timeZone,
        createdBy: 'coach',
        seriesId: seriesId,
        seriesDate: key,
      );
    }
    _changes.add(null);
    return SeriesResult(seriesId: seriesId, created: dates.length);
  }

  Iterable<Event> _scope(EventId id, SeriesScope scope) {
    final e = events[id.value]!;
    if (scope == SeriesScope.thisEvent) return [e];
    return [
      for (final x in events.values)
        if (x.seriesId == e.seriesId && !x.startAt.isBefore(e.startAt)) x,
    ];
  }

  @override
  Future<SeriesResult> updateSeries(
    EventId eventId,
    SeriesScope scope,
    EventTemplate template, {
    Recurrence? recurrence,
    String? date,
    bool dryRun = false,
  }) async {
    lastTemplate = template;
    calls.add('updateSeries ${scope.value}${dryRun ? ' dry' : ''}');
    if (dryRun) return dryRunResult;
    for (final e in _scope(eventId, scope).toList()) {
      put(e.copyWith(title: template.title));
    }
    return const SeriesResult(updated: 1);
  }

  @override
  Future<SeriesResult> cancelSeries(
    EventId eventId,
    SeriesScope scope, {
    bool dryRun = false,
  }) async {
    calls.add('cancelSeries ${scope.value}${dryRun ? ' dry' : ''}');
    if (dryRun) return dryRunResult;
    final list = _scope(eventId, scope).toList();
    for (final e in list) {
      put(e.copyWith(canceledAt: DateTime.now()));
    }
    return SeriesResult(canceled: list.length);
  }

  @override
  Future<SeriesResult> deleteSeries(
    EventId eventId,
    SeriesScope scope, {
    bool dryRun = false,
  }) async {
    calls.add('deleteSeries ${scope.value}${dryRun ? ' dry' : ''}');
    if (dryRun) return dryRunResult;
    final list = _scope(eventId, scope).toList();
    for (final e in list) {
      events.remove(e.id.value);
    }
    _changes.add(null);
    return SeriesResult(removed: list.length);
  }
}

/// RSVPs in memory. Each answer recounts its event at once, as the
/// server's trigger does a moment later.
class FakeRsvpRepository implements RsvpRepository {
  new(this.events);

  final FakeEventRepository events;
  final List<Rsvp> rsvps = [];
  final _changes = StreamController<void>.broadcast();

  /// Makes answers fail as the rules refuse them (after the deadline).
  bool refuse = false;

  Stream<T> _live<T>(T Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  @override
  Stream<List<Rsvp>> watchMine(
    GroupId groupId,
    List<String> participantIds, {
    DateTime? from,
    DateTime? until,
  }) => _live(
    () => [
      for (final r in rsvps)
        if (r.groupId == groupId && participantIds.contains(r.participantId)) r,
    ],
  );

  @override
  Stream<List<Rsvp>> watchForEvent(GroupId groupId, EventId eventId) => _live(
    () => [
      for (final r in rsvps)
        if (r.eventId == eventId) r,
    ],
  );

  /// Adds an answer as if someone gave it earlier.
  void put(Rsvp r) {
    rsvps
      ..removeWhere(
        (x) => x.eventId == r.eventId && x.participantId == r.participantId,
      )
      ..add(r);
    final e = events.events[r.eventId.value];
    if (e != null) {
      RsvpCounts count({required bool staff}) {
        final list = [
          for (final x in rsvps)
            if (x.eventId == e.id &&
                (!e.forPlayers ||
                    (x.participantType == ParticipantType.member) == staff))
              x,
        ];
        int n(RsvpStatus s) => list.where((x) => x.status == s).length;
        return RsvpCounts(
          going: n(RsvpStatus.going),
          maybe: n(RsvpStatus.maybe),
          notGoing: n(RsvpStatus.notGoing),
        );
      }

      events.put(
        e.copyWith(
          rsvpCounts: count(staff: false),
          staffCounts: e.forPlayers ? count(staff: true) : const RsvpCounts(),
        ),
      );
    }
    _changes.add(null);
  }

  @override
  Future<void> setRsvp(
    Event event,
    RsvpAnswer answer, {
    required UserId by,
  }) async {
    final current = events.events[event.id.value];
    if (refuse || current == null || current.isCanceled) {
      throw const PermissionDenied('closed');
    }
    put(
      Rsvp(
        eventId: event.id,
        groupId: event.groupId,
        participantType: answer.participant.type,
        participantId: answer.participant.id,
        participantName: answer.participant.name,
        status: answer.status,
        note: answer.note,
        respondedBy: by.value,
        eventStartAt: event.startAt,
      ),
    );
  }
}

/// Records what was added to the calendar.
class FakeCalendarAdder implements CalendarAdder {
  final List<CalendarEntry> added = [];

  @override
  Future<bool> add(CalendarEntry entry) async {
    added.add(entry);
    return true;
  }
}
