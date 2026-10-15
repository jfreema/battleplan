import 'dart:async';
import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/browser_info.dart';
import 'package:battleplan/core/services/calendar.dart';
import 'package:battleplan/core/services/file_chooser.dart';
import 'package:battleplan/core/services/link_opener.dart';
import 'package:battleplan/core/services/photo_drops.dart';
import 'package:battleplan/core/services/photo_picker.dart';
import 'package:battleplan/core/services/photo_saver.dart';
import 'package:battleplan/core/services/sharer.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/admin/domain/admin_repository.dart';
import 'package:battleplan/features/auth/domain/auth_repository.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/auth/domain/user_profile.dart';
import 'package:battleplan/features/auth/domain/user_repository.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/chat/domain/message_repository.dart';
import 'package:battleplan/features/documents/domain/document.dart';
import 'package:battleplan/features/documents/domain/document_repository.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/group_repository.dart';
import 'package:battleplan/features/groups/domain/invite.dart';
import 'package:battleplan/features/groups/domain/invite_repository.dart';
import 'package:battleplan/features/groups/domain/media.dart';
import 'package:battleplan/features/groups/domain/media_repository.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/imports/domain/chat_import.dart';
import 'package:battleplan/features/imports/domain/event_import.dart';
import 'package:battleplan/features/notifications/domain/device_repository.dart';
import 'package:battleplan/features/notifications/domain/notification_item.dart';
import 'package:battleplan/features/notifications/domain/notification_repository.dart';
import 'package:battleplan/features/notifications/domain/push_repository.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/domain/player_details.dart';
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

  /// Set to make the next reload fail the way a revoked session does: the
  /// session ends, then the reload throws.
  bool reloadEndsSession = false;

  @override
  Future<void> reloadUser() async {
    if (!reloadEndsSession) return;
    endSessionElsewhere();
    throw const Unauthenticated('user-token-expired');
  }

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

  /// When true, linking Google behaves as if the person closed the sheet.
  bool linkCancels = false;

  /// The method changes made without the app's own recent sign-in check
  /// (AUTH-6).
  final List<String> uncheckedChanges = [];

  @override
  Future<bool> linkGoogle({bool checkRecent = true}) async {
    if (checkRecent) {
      _requireRecent();
    } else {
      uncheckedChanges.add('google.com');
    }
    if (linkCancels) return false;
    _setProviders([..._user!.providerIds, 'google.com']);
    return true;
  }

  @override
  Future<void> unlink(String providerId) async {
    _requireRecent();
    _setProviders([..._user!.providerIds]..remove(providerId));
  }

  @override
  Future<void> setPassword(
    String newPassword, {
    bool checkRecent = true,
  }) async {
    if (checkRecent) {
      _requireRecent();
    } else {
      uncheckedChanges.add('password');
    }
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
  Map<String, String>? deletedNewOwners;

  @override
  Future<void> deleteAccount({Map<String, String> newOwners = const {}}) async {
    _requireRecent();
    deleted = true;
    deletedNewOwners = newOwners;
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
    // Opening the link is a fresh sign-in (AUTH-7).
    needsRecentLogin = false;
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

  /// Pins or unpins a message as `pinMessage` would (CHAT-15).
  void setPinned(GroupId id, String messageId, {required bool pinned}) {
    final g = groups[id.value];
    if (g == null) return;
    final pins = [...g.pinnedMessageIds]..remove(messageId);
    setGroup(
      g.copyWith(pinnedMessageIds: pinned ? [...pins, messageId] : pins),
    );
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
      timeZone: timeZone ?? g.timeZone,
      settings: settings ?? g.settings,
    );
    if (timeZone != null) updates.add('timeZone $timeZone');
    updates.add(
      settings != null ? 'settings' : (name != null ? 'name $name' : 'other'),
    );
  }

  int logosUploaded = 0;

  @override
  Future<void> uploadLogo(GroupId id, Uint8List jpegBytes) async =>
      logosUploaded++;

  /// Logo files uploaded without being put on the team (a super admin's).
  final List<String> logoFiles = [];

  @override
  Future<String> uploadLogoFile(GroupId id, Uint8List jpegBytes) async {
    final path = 'groups/${id.value}/avatar/logo${logoFiles.length}.jpg';
    logoFiles.add(path);
    return path;
  }

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

  /// The color each created team was given, null for none (TEAM-1).
  final List<String?> createdColors = [];

  @override
  Future<GroupId> createGroup({
    required String name,
    required Sport sport,
    required String timeZone,
    String? color,
    String? description,
  }) async {
    created.add(name);
    createdColors.add(color);
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
  Stream<List<Membership>> watchRoster(GroupId groupId) async* {
    List<Membership> team() =>
        memberships.where((m) => m.groupId == groupId).toList();
    yield team();
    await for (final _ in _changes.stream) {
      yield team();
    }
  }

  /// Shares or stops sharing my contact info (TEAM-10), as the rules let
  /// me write it: blank is not shared.
  @override
  Future<void> setContact(
    GroupId groupId,
    UserId uid, {
    String? phone,
    String? email,
  }) async {
    String? shared(String? v) =>
        v == null || v.trim().isEmpty ? null : v.trim();
    calls.add('contact ${uid.value} ${shared(phone)} ${shared(email)}');
    _updateMine(
      groupId,
      uid,
      (m) =>
          m.copyWith(contactPhone: shared(phone), contactEmail: shared(email)),
    );
  }

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
      invitedPeople: [
        for (final e in entries) (name: e.name ?? e.email, email: e.email),
      ],
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

  /// The marker each partial read set (CHAT-9), in order.
  final List<DateTime> readsUpTo = [];

  @override
  Future<void> markRead(GroupId groupId, UserId uid, {DateTime? upTo}) async {
    reads.add(groupId.value);
    if (upTo != null) readsUpTo.add(upTo);
  }
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
  PendingLink? pendingLink;

  @override
  Future<void> setPendingLink(PendingLink? value) async => pendingLink = value;

  @override
  Future<void> setLastTeamRoute(String route) async => lastTeamRoute = route;

  @override
  Future<void> setThemePreference(ThemePreference value) async =>
      themePreference = value;

  final Set<String> passwordSetUids = {};

  @override
  bool passwordSet(String uid) => passwordSetUids.contains(uid);

  @override
  Future<void> setPasswordSet(String uid, {required bool value}) async =>
      value ? passwordSetUids.add(uid) : passwordSetUids.remove(uid);

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
  new({this.needsSetup = false, this.status = UserStatus.active});

  bool needsSetup;

  /// The account's status; disabled shows only the disabled screen.
  UserStatus status;
  final _changes = StreamController<void>.broadcast();
  String? savedName;
  ThemePreference themeMode = ThemePreference.system;
  int photosUploaded = 0;

  final Map<NotificationPref, bool> notificationPrefs = {};

  /// An added account that hasn't chosen how to sign in yet (AUTH-6).
  bool chooseSignIn = false;

  /// When "Sign out of all devices" last ran (AUTH-9).
  DateTime? sessionsRevokedAt;

  /// Shows a profile change made elsewhere (the server, another device).
  void changed() => _changes.add(null);

  UserProfile _profile(String uid) => UserProfile(
    uid: uid,
    displayName: savedName ?? 'Jordan Coach',
    status: status,
    chooseSignIn: chooseSignIn,
    sessionsRevokedAt: sessionsRevokedAt,
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
    bool signInChosen = false,
  }) async {
    if (signInChosen) {
      chooseSignIn = false;
      _changes.add(null);
    }
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
  const new({this.pushNeedsHomeScreen = false, this.isWeb = false});

  @override
  final bool pushNeedsHomeScreen;

  @override
  final bool isWeb;
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

  /// The link's options, as the last update or reset set them.
  InviteExpiry expiry = InviteExpiry.never;
  int? maxUses;

  /// True after revokeTeamInvite, until resetTeamInvite (§3).
  bool linkOff = false;

  @override
  Future<TeamInvite> teamInvite(GroupId groupId) async {
    if (linkOff) throw const InviteUnusable('link-off');
    return _invite().copyWith(maxUses: maxUses);
  }

  @override
  Future<TeamInvite> updateTeamInvite(
    GroupId groupId, {
    InviteExpiry expiry = InviteExpiry.never,
    int? maxUses,
  }) async {
    if (linkOff) throw const InviteUnusable('link-off');
    this.expiry = expiry;
    this.maxUses = maxUses;
    return _invite().copyWith(maxUses: maxUses);
  }

  @override
  Future<void> revokeTeamInvite(GroupId groupId) async => linkOff = true;

  /// What [preview] returns for K7XPM2QR.
  InvitePreview previewed = const InvitePreview(
    groupId: 'a',
    name: 'Thunder',
    sport: Sport.softball,
    memberCount: 12,
    invitedBy: 'Alex Kim',
  );

  final List<String> redeemed = [];

  /// What [redeem] says about already being on the team.
  bool joinedAlready = false;

  @override
  Future<InvitePreview> preview(String code) async {
    if (code != 'K7XPM2QR') throw const InviteUnusable('unknown');
    return previewed;
  }

  @override
  Future<JoinResult> redeem(String code) async {
    redeemed.add(code);
    return JoinResult(groupId: 'a', alreadyMember: joinedAlready);
  }

  @override
  Future<TeamInvite> resetTeamInvite(
    GroupId groupId, {
    InviteExpiry expiry = InviteExpiry.never,
    int? maxUses,
  }) async {
    resets++;
    linkOff = false;
    this.expiry = expiry;
    this.maxUses = maxUses;
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

  /// Every player, active and pending; the watches split them.
  final List<Player> players;
  final List<List<NewPlayer>> added = [];

  @override
  Stream<List<Player>> watchPlayers(GroupId groupId) => Stream.value(
    players.where((p) => p.groupId == groupId && !p.isPending).toList(),
  );

  @override
  Stream<List<Player>> watchPendingPlayers(GroupId groupId) => Stream.value(
    players.where((p) => p.groupId == groupId && p.isPending).toList(),
  );

  @override
  Stream<List<Player>> watchMyPendingPlayers(GroupId groupId, UserId uid) =>
      Stream.value(
        players
            .where(
              (p) =>
                  p.groupId == groupId &&
                  p.isPending &&
                  p.proposedBy == uid.value,
            )
            .toList(),
      );

  @override
  Stream<List<GuardianLink>> watchGuardianLinks(GroupId groupId) =>
      Stream.value(links.where((l) => l.groupId == groupId).toList());

  final List<GuardianLink> links = [];

  @override
  Future<int> addPlayers(GroupId groupId, List<NewPlayer> players) async {
    added.add(players);
    return players.length;
  }

  @override
  Future<void> updatePlayer(
    PlayerId id, {
    required String name,
    String? jerseyNumber,
  }) async => calls.add('update ${id.value} $name');

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

  /// What [claimPlayer] answers: linked at once, as for an admin.
  ClaimOutcome claimOutcome = ClaimOutcome.requested;

  @override
  Future<ClaimOutcome> claimPlayer(
    GroupId groupId,
    PlayerId playerId,
    PlayerRelation relation,
  ) async {
    calls.add('claim ${playerId.value} ${relation.value}');
    return claimOutcome;
  }

  @override
  Future<void> resolvePlayerClaim(
    GroupId groupId,
    PlayerId playerId,
    UserId uid, {
    required bool approve,
  }) async => calls.add(
    '${approve ? 'approve' : 'decline'} ${playerId.value} ${uid.value}',
  );

  /// What [proposePlayer] answers.
  PlayerStatus proposedStatus = PlayerStatus.pending;

  @override
  Future<PlayerStatus> proposePlayer(
    GroupId groupId, {
    required String name,
    required PlayerRelation relation,
    String? jerseyNumber,
    String? dateOfBirth,
  }) async {
    calls.add(
      'propose $name #${jerseyNumber ?? ''} '
      '${relation.value}${dateOfBirth == null ? '' : ' born $dateOfBirth'}',
    );
    return proposedStatus;
  }

  /// Whether an approved player's proposer gets linked (PLAYER-4).
  bool proposerLinked = true;

  @override
  Future<bool> resolvePendingPlayer(
    GroupId groupId,
    PlayerId playerId, {
    required bool approve,
  }) async {
    calls.add(
      '${approve ? 'approvePlayer' : 'declinePlayer'} ${playerId.value}',
    );
    return approve && proposerLinked;
  }

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

  /// Players' details by player ID (PLAYER-12). Saves and deletes change
  /// them, and the watches update, as Firestore's would.
  final Map<PlayerId, PlayerDetails> details = {};

  /// The details asked for, `player <id>` and `team <id>`, so a test can
  /// check that nobody else's app asks (PLAYER-12).
  final List<String> detailsReads = [];

  final _detailsChanges = StreamController<void>.broadcast();

  @override
  Stream<PlayerDetails?> watchPlayerDetails(PlayerId playerId) async* {
    detailsReads.add('player ${playerId.value}');
    yield details[playerId];
    await for (final _ in _detailsChanges.stream) {
      yield details[playerId];
    }
  }

  @override
  Stream<List<PlayerDetails>> watchTeamPlayerDetails(GroupId groupId) async* {
    detailsReads.add('team ${groupId.value}');
    List<PlayerDetails> team() => [
      for (final d in details.values)
        if (d.groupId == groupId) d,
    ];
    yield team();
    await for (final _ in _detailsChanges.stream) {
      yield team();
    }
  }

  /// Saves as the Firestore repository does: cleaned, with the consent
  /// recorded, kept, or cleared ([medicalConsentFor]), logged in [calls]
  /// as `saveDetails <id> <consent>`.
  @override
  Future<void> savePlayerDetails(
    PlayerDetails details, {
    required UserId by,
    PlayerDetails? stored,
  }) async {
    final d = details.cleaned;
    final consent = medicalConsentFor(
      stored: stored,
      medicalNotes: d.medicalNotes,
    );
    final before = this.details[d.playerId];
    final now = DateTime.now();
    this.details[d.playerId] = d.copyWith(
      medicalConsentAt: switch (consent) {
        MedicalConsent.record => now,
        MedicalConsent.clear => null,
        MedicalConsent.keep => before?.medicalConsentAt,
      },
      medicalConsentBy: switch (consent) {
        MedicalConsent.record => by.value,
        MedicalConsent.clear => null,
        MedicalConsent.keep => before?.medicalConsentBy,
      },
      updatedBy: by.value,
      updatedAt: now,
    );
    calls.add('saveDetails ${d.playerId.value} ${consent.name}');
    _detailsChanges.add(null);
  }

  @override
  Future<void> deletePlayerDetails(PlayerId playerId) async {
    details.remove(playerId);
    calls.add('deleteDetails ${playerId.value}');
    _detailsChanges.add(null);
  }
}

/// Chat on an in-memory list. [sent] records what was sent; each send also
/// appears in the chat, as Firestore's local write would.
class FakeMessageRepository implements MessageRepository {
  new([List<Message>? messages]) : messages = messages ?? [];

  /// Newest first.
  final List<Message> messages;
  final List<String> sent = [];
  final _changes = StreamController<void>.broadcast();

  /// Pages as if offline, from the cache (CHAT-4); [refresh] to apply.
  bool offline = false;

  /// Sends the live page again, as a change on the server would.
  void refresh() => _changes.add(null);

  /// Every older page read, by its cursor.
  final List<Object> olderReads = [];

  @override
  Stream<MessagePage> watchNewest(GroupId groupId, {int limit = 50}) async* {
    MessagePage page() {
      final all = messages.where((m) => m.groupId == groupId).toList();
      return MessagePage(
        messages: all.take(limit).toList(),
        next: all.length > limit ? PageCursor(limit) : null,
        fromCache: offline,
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
    olderReads.add(before.handle);
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
    Set<String> skipAuthors = const {},
  }) async => messages
      .where(
        (m) =>
            m.groupId == groupId &&
            (m.createdAt?.isAfter(since) ?? false) &&
            !m.isSystem &&
            !skipAuthors.contains(m.authorId),
      )
      .take(cap)
      .length;

  /// Every newer page read, by its `after` time or cursor (CHAT-1).
  final List<Object?> newerReads = [];

  /// While set, newer pages wait for it, as a slow connection would.
  Completer<void>? holdNewer;

  @override
  Future<MessagePage> loadNewer(
    GroupId groupId, {
    DateTime? after,
    PageCursor? cursor,
    int limit = 50,
  }) async {
    newerReads.add(cursor?.handle ?? after);
    if (holdNewer case final hold?) await hold.future;
    final all = messages.where((m) => m.groupId == groupId).toList();
    // Indexes into the newest-first list: [start, end) are the page.
    final end = cursor != null
        ? cursor.handle as int
        : switch (all.indexWhere(
            (m) => !(m.createdAt?.isAfter(after!) ?? true),
          )) {
            -1 => all.length,
            final i => i,
          };
    final start = (end - limit).clamp(0, end);
    return MessagePage(
      messages: all.sublist(start, end),
      next: start > 0 ? PageCursor(start) : null,
      older: end < all.length ? PageCursor(end) : null,
    );
  }

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

  /// What every message photo downloads as; null fails like a missing file.
  Uint8List? photoBytes;

  @override
  Future<Uint8List?> attachmentBytes(String path) async => photoBytes;

  int _ids = 0;

  @override
  String newMessageId() => 'new${_ids++}';

  /// When set, sends fail with this, as a server refusal would.
  AppFailure? failSends;

  /// What each sent text named with @, and whether it was an
  /// announcement (CHAT-14, CHAT-15), in the order sent.
  final List<({List<String> mentions, bool everyone, bool announcement})>
  sentDetails = [];

  @override
  Future<void> sendText(
    GroupId groupId,
    UserId uid,
    String text, {
    String? id,
    String? replyToId,
    List<String> mentions = const [],
    bool mentionsEveryone = false,
    bool announcement = false,
  }) async {
    if (failSends case final error?) throw error;
    sent.add(text);
    sentDetails.add((
      mentions: mentions,
      everyone: mentionsEveryone,
      announcement: announcement,
    ));
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
        mentions: mentions,
        mentionsEveryone: mentionsEveryone,
        announcement: announcement,
        createdAt: DateTime.now(),
      ),
    );
    _changes.add(null);
  }

  @override
  Stream<Message?> watchMessage(GroupId groupId, String messageId) async* {
    Message? find() => messages
        .where((m) => m.id == messageId && m.groupId == groupId)
        .firstOrNull;
    yield find();
    await for (final _ in _changes.stream) {
      yield find();
    }
  }

  /// Every pin and unpin asked for, as "id pinned" or "id unpinned".
  final List<String> pins = [];

  /// Where pins land, as the server's would: the group's pinned IDs.
  FakeGroupRepository? groups;

  /// When set, pinning fails with this, as a full bar would.
  AppFailure? failPins;

  @override
  Future<void> setPinned(String messageId, {required bool pinned}) async {
    if (failPins case final error?) throw error;
    pins.add('$messageId ${pinned ? 'pinned' : 'unpinned'}');
    final m = messages.where((m) => m.id == messageId).firstOrNull;
    if (m != null) groups?.setPinned(m.groupId, messageId, pinned: pinned);
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

  /// What a profile photo or logo pick returns; none by default.
  Uint8List? profilePhoto;

  @override
  Future<Uint8List?> pickProfilePhoto() async {
    opened++;
    return profilePhoto;
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

  /// Every range a player's RSVP history read (PLAYER-11).
  final List<({DateTime from, DateTime until})> ranges = [];

  @override
  Future<List<Event>> eventsBetween(
    GroupId groupId,
    DateTime from,
    DateTime until,
  ) async {
    ranges.add((from: from, until: until));
    return [
      for (final e in _team(groupId))
        if (!e.startAt.isBefore(from) && e.startAt.isBefore(until)) e,
    ]..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  @override
  Stream<Event?> watchEvent(EventId id) => _live(() => events[id.value]);

  @override
  Stream<Event?> watchNextInSeries(
    GroupId groupId,
    String seriesId,
    DateTime from,
  ) => _live(
    () => ([
      for (final e in _team(groupId))
        if (e.seriesId == seriesId && !e.startAt.isBefore(from)) e,
    ]..sort((a, b) => a.startAt.compareTo(b.startAt))).firstOrNull,
  );

  @override
  Stream<EventSeries?> watchSeries(String seriesId) =>
      _live(() => series[seriesId]);

  Event _fromDraft(
    String id,
    GroupId groupId,
    EventDraft d, {
    required String createdBy,
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
      rsvpDeadline: d.deadline,
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
  }) async {
    final id = 'new${_next++}';
    calls.add('create');
    put(_fromDraft(id, groupId, draft, createdBy: createdBy.value));
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

  /// The windows "My RSVPs" was asked for, in order.
  final List<({DateTime? from, DateTime? until})> windows = [];

  /// The event an answer is on starts in [from, until), as the real query
  /// filters on `eventStartAt`.
  bool _inWindow(Rsvp r, DateTime? from, DateTime? until) {
    final start = r.eventStartAt ?? events.events[r.eventId.value]?.startAt;
    if (start == null) return true;
    return (from == null || !start.isBefore(from)) &&
        (until == null || start.isBefore(until));
  }

  @override
  Stream<List<Rsvp>> watchMine(
    GroupId groupId,
    List<String> participantIds, {
    DateTime? from,
    DateTime? until,
  }) {
    windows.add((from: from, until: until));
    return _live(
      () => [
        for (final r in rsvps)
          if (r.groupId == groupId &&
              participantIds.contains(r.participantId) &&
              _inWindow(r, from, until))
            r,
      ],
    );
  }

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
            // Players apart from everyone answering for themselves
            // (PLAYER-6), as the server counts them.
            if (x.eventId == e.id &&
                (x.participantType == ParticipantType.member) == staff)
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
          staffCounts: count(staff: true),
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

  /// Every batch of answers written together (PLAYER-11), as
  /// "participant:status" lists.
  final List<List<String>> batches = [];

  @override
  Future<void> setRsvps(
    Event event,
    List<RsvpAnswer> answers, {
    required UserId by,
  }) async {
    final current = events.events[event.id.value];
    // All or none, as one batch is.
    if (refuse || current == null || current.isCanceled) {
      throw const PermissionDenied('closed');
    }
    batches.add([
      for (final a in answers) '${a.participant.id}:${a.status.value}',
    ]);
    for (final a in answers) {
      await setRsvp(event, a, by: by);
    }
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

/// Documents and their files in memory (DOC-1 to DOC-5). Pages are slices
/// of the team's documents in the query's order, as Firestore returns them
/// (pinned ones aren't first there; the app puts them first).
class FakeDocumentRepository implements DocumentRepository {
  new([List<Document> docs = const []]) {
    docs.forEach(put);
  }

  final Map<String, Document> docs = {};

  /// Stored files' bytes by path.
  final Map<String, Uint8List> files = {};
  final List<String> deleted = [];
  final _changes = StreamController<void>.broadcast();
  int _nextId = 0;

  /// The upload under way, for tests to move along, finish, or fail.
  FakeDocumentUpload? upload;

  /// Makes writes fail as the rules refuse them.
  bool refuseWrites = false;

  /// Adds or replaces a document, and tells anyone watching.
  void put(Document doc) {
    docs[doc.id.value] = doc;
    _changes.add(null);
  }

  Stream<T> _live<T>(T Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  List<Document> _ordered(GroupId groupId, DocumentSort sort) {
    final team = [
      for (final d in docs.values)
        if (d.groupId == groupId) d.copyWith(pinned: false),
    ];
    final order = arrangeDocuments(team, sort: sort);
    // Back to the stored pinned values, in the query's order.
    return [for (final d in order) docs[d.id.value]!];
  }

  DocumentPage _page(List<Document> all, int start, int limit) {
    final end = (start + limit).clamp(0, all.length);
    return (
      documents: all.sublist(start.clamp(0, all.length), end),
      next: end - start < limit ? null : PageCursor(end),
    );
  }

  @override
  Stream<DocumentPage> watchFirstPage(
    GroupId groupId,
    DocumentSort sort, {
    int limit = Limits.queryLimitMax,
  }) => _live(() => _page(_ordered(groupId, sort), 0, limit));

  @override
  Future<DocumentPage> loadMore(
    GroupId groupId,
    DocumentSort sort,
    PageCursor cursor, {
    int limit = Limits.queryLimitMax,
  }) async => _page(_ordered(groupId, sort), cursor.handle as int, limit);

  @override
  Stream<List<Document>> watchPinned(GroupId groupId) => _live(
    () => [
      for (final d in docs.values)
        if (d.groupId == groupId && d.pinned) d,
    ],
  );

  @override
  Stream<Document?> watchDocument(DocumentId id) => _live(() => docs[id.value]);

  @override
  DocumentId newDocumentId() => DocumentId('new${_nextId++}');

  @override
  DocumentUpload uploadFile(
    GroupId groupId,
    DocumentId id, {
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) {
    final path = 'groups/${groupId.value}/documents/${id.value}/$fileName';
    final up = FakeDocumentUpload(path, bytes);
    upload = up;
    // The file is stored once the upload finishes.
    unawaited(
      up.done.then((_) => files[path] = bytes, onError: (Object _) => null),
    );
    return up;
  }

  @override
  Future<void> createFile(
    GroupId groupId,
    DocumentId id,
    UserId uid, {
    required String name,
    required String description,
    required String path,
    required String contentType,
    required int size,
    required bool notifyTeam,
  }) async {
    if (refuseWrites) throw const PermissionDenied('create');
    put(
      Document(
        id: id,
        groupId: groupId,
        kind: DocumentKind.file,
        name: name,
        description: description,
        path: path,
        contentType: contentType,
        size: size,
        uploadedBy: uid.value,
        uploaderName: uid.value,
        createdAt: DateTime.now(),
      ),
    );
    notified[id.value] = notifyTeam;
  }

  /// Each new document's Notify team choice, by ID.
  final Map<String, bool> notified = {};

  @override
  Future<DocumentId> createLink(
    GroupId groupId,
    UserId uid, {
    required String name,
    required Uri url,
    required String description,
    required bool notifyTeam,
  }) async {
    if (refuseWrites) throw const PermissionDenied('create');
    final id = newDocumentId();
    put(
      Document(
        id: id,
        groupId: groupId,
        kind: DocumentKind.link,
        name: name,
        description: description,
        url: url.toString(),
        uploadedBy: uid.value,
        uploaderName: uid.value,
        createdAt: DateTime.now(),
      ),
    );
    notified[id.value] = notifyTeam;
    return id;
  }

  @override
  Future<void> update(
    Document doc, {
    required String name,
    required String description,
  }) async {
    if (refuseWrites) throw const PermissionDenied('update');
    put(docs[doc.id.value]!.copyWith(name: name, description: description));
  }

  @override
  Future<void> setPinned(Document doc, {required bool pinned}) async {
    if (refuseWrites) throw const PermissionDenied('pin');
    put(docs[doc.id.value]!.copyWith(pinned: pinned));
  }

  @override
  Future<void> delete(Document doc) async {
    if (refuseWrites) throw const PermissionDenied('delete');
    deleted.add(doc.id.value);
    docs.remove(doc.id.value);
    _changes.add(null);
  }

  @override
  Future<String?> fileUrl(String path) async =>
      files.containsKey(path) ? 'https://files.test/$path' : null;

  @override
  Future<Uint8List?> fileBytes(String path) async => files[path];
}

/// An upload the test moves along: [report] progress, then [finish] or
/// [fail]. Cancel fails it as Storage does.
class FakeDocumentUpload implements DocumentUpload {
  new(this.path, this.bytes);

  final String path;
  final Uint8List bytes;
  final _progress = StreamController<double>.broadcast();
  final _done = Completer<String>();
  bool canceled = false;

  void report(double p) => _progress.add(p);

  void finish() {
    if (!_done.isCompleted) _done.complete(path);
  }

  void fail(AppFailure failure) {
    if (!_done.isCompleted) _done.completeError(failure);
  }

  @override
  Stream<double> get progress => _progress.stream;

  @override
  Future<String> get done => _done.future;

  @override
  Future<void> cancel() async {
    canceled = true;
    fail(const UploadCanceled('canceled'));
  }
}

/// Hands out [next] when a file is picked, and records saved files.
class FakeFileChooser implements FileChooser {
  new({this.next, this.web = false});

  PickedFile? next;
  final bool web;
  final List<String> saved = [];

  /// The extensions the last pick allowed.
  List<String> extensions = const [];

  @override
  Future<PickedFile?> pickFile({required List<String> extensions}) async {
    this.extensions = extensions;
    return next;
  }

  @override
  Future<bool> saveFile(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  }) async {
    saved.add(name);
    return true;
  }

  /// Files handed to the default app, as "name type" (DOC-4).
  final List<String> opened = [];

  /// False: no app on the phone takes the file.
  bool appOpens = true;

  @override
  Future<bool> openFile(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  }) async {
    opened.add('$name $mimeType');
    return appOpens;
  }

  @override
  bool get downloadsInsteadOfOpening => web;
}

/// A picked file of [size] bytes (its bytes are that many zeros).
PickedFile pickedFile(String name, int size) =>
    (name: name, size: size, readBytes: () async => Uint8List(size));

/// Records what was shared.
class FakeSharer implements Sharer {
  final List<String> shared = [];

  /// False for a browser without Web Share: links aren't shared, so the
  /// caller copies them (SPEC §4.2).
  bool linksShare = true;

  @override
  Future<bool> shareLink(Uri uri, {String? subject}) async {
    if (!linksShare) return false;
    shared.add('link $uri');
    return true;
  }

  @override
  Future<bool> shareImage(Uint8List bytes, {required String name}) async {
    shared.add('image $name');
    return true;
  }

  @override
  Future<bool> shareFile(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  }) async {
    shared.add('file $name $mimeType');
    return true;
  }
}

/// Records the links opened outside the app.
class FakeLinkOpener implements LinkOpener {
  final List<Uri> opened = [];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

/// The admin callables and `config/app` in memory (ADMIN). Lists page by
/// [pageSize]; actions are logged in [calls] and change what's stored, as
/// the server would. Set [failWith] to make the next action throw.
class FakeAdminRepository implements AdminRepository {
  new({
    this.totalsValue = const AdminTotals(),
    List<AdminTeamRow>? teams,
    Map<String, AdminTeamDetail>? teamDetails,
    List<AdminUserRow>? users,
    Map<String, AdminUserDetail>? userDetails,
    List<AdminReport>? reports,
    List<AuditEntry>? audit,
    this._config = const AppConfig(),
    this.pageSize = 50,
    this.teamScan,
  }) : teams = teams ?? [],
       teamDetails = teamDetails ?? {},
       users = users ?? [],
       userDetails = userDetails ?? {},
       reports = reports ?? [],
       audit = audit ?? [];

  AdminTotals totalsValue;
  final List<AdminTeamRow> teams;
  final Map<String, AdminTeamDetail> teamDetails;
  final List<AdminUserRow> users;
  final Map<String, AdminUserDetail> userDetails;
  final List<AdminReport> reports;
  final List<AuditEntry> audit;
  final int pageSize;

  /// Set to look through only this many teams per page when filtering by
  /// status, as the server does (`TEAM_SCAN_MAX`): a page can come back
  /// short, even empty, with a cursor to keep looking.
  final int? teamScan;

  /// Every action, e.g. `suspend g1 true`, in order.
  final List<String> calls = [];

  /// The queries the lists were read with, newest last.
  final List<AdminTeamQuery> teamQueries = [];
  final List<AuditFilter> auditFilters = [];

  /// Thrown by the next action instead of doing it.
  AppFailure? failWith;

  Future<void> _act(String call) async {
    final failure = failWith;
    if (failure != null) {
      failWith = null;
      throw failure;
    }
    calls.add(call);
  }

  AdminPage<T> _page<T>(List<T> all, PageCursor? after) {
    final start = after == null ? 0 : after.handle as int;
    final end = (start + pageSize).clamp(0, all.length);
    return (
      items: all.sublist(start, end),
      next: end < all.length ? PageCursor(end) : null,
    );
  }

  @override
  Future<AdminTotals> totals() async => totalsValue;

  @override
  Future<AdminPage<AdminTeamRow>> listTeams(
    AdminTeamQuery query, {
    PageCursor? after,
    int limit = adminPageSize,
  }) async {
    teamQueries.add(query);
    final q = query.query.trim().toLowerCase();
    final scan = teamScan;
    final matching = [
      for (final t in teams)
        if (t.name.toLowerCase().startsWith(q) &&
            (scan != null || query.status == null || t.status == query.status))
          t,
    ];
    int newest(DateTime? a, DateTime? b) =>
        (b ?? DateTime(2000)).compareTo(a ?? DateTime(2000));
    matching.sort(
      (a, b) => switch (query.sort) {
        AdminTeamSort.created => newest(a.createdAt, b.createdAt),
        AdminTeamSort.activity => newest(a.lastMessageAt, b.lastMessageAt),
        AdminTeamSort.members => b.memberCount.compareTo(a.memberCount),
        AdminTeamSort.storage => b.storageBytes.compareTo(a.storageBytes),
      },
    );
    if (scan != null && query.status != null) {
      final start = after == null ? 0 : after.handle as int;
      final end = (start + scan).clamp(0, matching.length);
      return (
        items: [
          for (final t in matching.sublist(start, end))
            if (t.status == query.status) t,
        ],
        next: end < matching.length ? PageCursor(end) : null,
      );
    }
    return _page(matching, after);
  }

  @override
  Future<AdminTeamDetail> team(GroupId id) async =>
      teamDetails[id.value] ?? AdminTeamDetail(id: id);

  /// Teams whose View team was recorded, in order.
  final List<String> opened = [];

  @override
  Future<void> openGroup(GroupId id) async => opened.add(id.value);

  @override
  Future<void> setGroupSuspended(
    GroupId id, {
    required bool suspended,
    String? note,
  }) => _act('suspend ${id.value} $suspended ${note ?? ''}'.trim());

  @override
  Future<void> setGroupArchived(GroupId id, {required bool archived}) =>
      _act('archive ${id.value} $archived');

  @override
  Future<void> deleteGroup(GroupId id, String confirmName) =>
      _act('delete ${id.value} $confirmName');

  /// Team edits through `adminUpdateGroup`, as `team t1 name=Storm`.
  @override
  Future<void> updateGroup(
    GroupId id, {
    String? name,
    String? description,
    String? color,
    Sport? sport,
    String? timeZone,
    GroupSettings? settings,
    ChatTheme? chatTheme,
    String? photoPath,
  }) => _act(
    [
      'team ${id.value}',
      if (name != null) 'name=$name',
      if (description != null) 'description=$description',
      if (color != null) 'color=$color',
      if (sport != null) 'sport=${sport.value}',
      if (timeZone != null) 'timeZone=$timeZone',
      if (settings != null) 'settings',
      if (chatTheme != null) 'chatTheme=${_theme(chatTheme)}',
      if (photoPath != null) 'photoPath=$photoPath',
    ].join(' '),
  );

  static String _theme(ChatTheme t) =>
      [t.background.name, ?t.backgroundPath].join(':');

  @override
  Future<void> updatePlayer(
    PlayerId id, {
    required String name,
    String? jerseyNumber,
  }) => _act('player ${id.value} $name #${jerseyNumber ?? ''}');

  @override
  Future<AdminPage<AdminUserRow>> listUsers(
    AdminUserQuery query, {
    PageCursor? after,
    int limit = adminPageSize,
  }) async {
    final q = query.query.trim().toLowerCase();
    bool matches(AdminUserRow u) => switch (query.filter) {
      null => true,
      AdminUserFilter.added => u.status == UserStatus.provisioned,
      AdminUserFilter.active => u.status == UserStatus.active,
      AdminUserFilter.disabled => u.status == UserStatus.disabled,
      AdminUserFilter.superAdmin => u.superAdmin,
    };
    return _page([
      for (final u in users)
        if ((u.displayName.toLowerCase().startsWith(q) ||
                (u.email ?? '').toLowerCase().startsWith(q)) &&
            matches(u))
          u,
    ], after);
  }

  @override
  Future<AdminUserDetail> user(UserId uid) async {
    final known = userDetails[uid.value];
    if (known != null) return known;
    final row = users.where((u) => u.uid == uid).firstOrNull;
    if (row == null) throw const NotFound();
    return AdminUserDetail(user: row);
  }

  void _updateUser(UserId uid, AdminUserRow Function(AdminUserRow) f) {
    final i = users.indexWhere((u) => u.uid == uid);
    if (i >= 0) users[i] = f(users[i]);
    final d = userDetails[uid.value];
    if (d != null) userDetails[uid.value] = d.copyWith(user: f(d.user));
  }

  @override
  Future<UserId> createUser({
    required String email,
    required String displayName,
    GroupId? groupId,
    MemberRole? role,
  }) async {
    await _act(
      'create $email $displayName ${groupId?.value ?? ''} ${role?.value ?? ''}'
          .trim(),
    );
    final uid = UserId('new-${users.length}');
    users.add(
      AdminUserRow(
        uid: uid,
        displayName: displayName,
        email: email,
        status: UserStatus.provisioned,
      ),
    );
    return uid;
  }

  @override
  Future<void> renameUser(UserId uid, String displayName) async {
    await _act('rename ${uid.value} $displayName');
    _updateUser(uid, (u) => u.copyWith(displayName: displayName));
  }

  @override
  Future<void> addUserToGroup(UserId uid, GroupId groupId, MemberRole role) =>
      _act('addToTeam ${uid.value} ${groupId.value} ${role.value}');

  @override
  Future<void> setUserDisabled(UserId uid, {required bool disabled}) async {
    await _act('disable ${uid.value} $disabled');
    _updateUser(
      uid,
      (u) => u.copyWith(
        status: disabled ? UserStatus.disabled : UserStatus.active,
      ),
    );
  }

  @override
  Future<void> revokeSessions(UserId uid) => _act('signOut ${uid.value}');

  @override
  Future<void> sendPasswordReset(UserId uid) => _act('reset ${uid.value}');

  @override
  Future<void> deleteUser(UserId uid) => _act('deleteUser ${uid.value}');

  @override
  Future<void> setSuperAdmin(UserId uid, {required bool superAdmin}) async {
    await _act('superAdmin ${uid.value} $superAdmin');
    _updateUser(uid, (u) => u.copyWith(superAdmin: superAdmin));
  }

  @override
  Future<AdminPage<AdminReport>> listReports(
    ReportStatus status, {
    PageCursor? after,
    int limit = adminPageSize,
  }) async => _page([
    for (final r in reports)
      if (r.status == status) r,
  ], after);

  @override
  Future<void> resolveReport(
    String reportId,
    AdminReportAction action,
    String note,
  ) async {
    await _act('resolve $reportId ${action.name} $note');
    final i = reports.indexWhere((r) => r.id == reportId);
    if (i >= 0) {
      reports[i] = reports[i].copyWith(
        status: action == AdminReportAction.dismiss
            ? ReportStatus.dismissed
            : ReportStatus.actioned,
        note: note,
      );
    }
  }

  @override
  Future<AdminPage<AuditEntry>> auditLog(
    AuditFilter filter, {
    PageCursor? after,
    int limit = adminPageSize,
  }) async {
    auditFilters.add(filter);
    return _page([
      for (final e in audit)
        if ((filter.actorId == null || e.actorId == filter.actorId) &&
            (filter.action == null || e.action == filter.action) &&
            (filter.groupId == null || e.groupId == filter.groupId))
          e,
    ], after);
  }

  AppConfig _config;
  final _configChanges = StreamController<AppConfig>.broadcast();

  /// Replaces `config/app` and tells anyone watching, like a server write.
  set config(AppConfig value) {
    _config = value;
    _configChanges.add(value);
  }

  AppConfig get config => _config;

  @override
  Stream<AppConfig> watchConfig() async* {
    yield _config;
    yield* _configChanges.stream;
  }

  /// The settings saved, in order.
  final List<AppConfig> savedConfigs = [];

  @override
  Future<void> updateConfig(AppConfig config) async {
    await _act('updateConfig');
    savedConfigs.add(config);
    this.config = config;
  }
}

/// Google sign-in that fails offline the first time, then works (AUTH
/// edge cases: Retry).
class OfflineOnceAuth extends FakeAuthRepository {
  int googleAttempts = 0;

  @override
  Future<void> signInWithGoogle() async {
    if (++googleAttempts == 1) throw const Offline('network-request-failed');
    await super.signInWithGoogle();
  }
}

/// Every sign-in is refused: the account is disabled (AUTH-11).
class DisabledAuth extends FakeAuthRepository {
  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async => throw const PermissionDenied('user-disabled');
}

/// Google finds an existing account for the same email, so a sign-in
/// link goes out instead of merging (AUTH-7).
class ExistingAccountAuth extends FakeAuthRepository {
  @override
  Future<void> signInWithGoogle() async {
    await sendSignInLink(FakeAuthRepository.knownEmail);
    throw const AccountExistsWithOtherMethod(FakeAuthRepository.knownEmail);
  }
}

/// The phone's photo library (CHAT-3): what was saved, by name.
class FakePhotoSaver implements PhotoSaver {
  final List<String> saved = [];

  @override
  bool get available => true;

  @override
  Future<bool> saveImage(Uint8List bytes, {required String name}) async {
    saved.add(name);
    return true;
  }
}

/// Players whose adds by email are refused with [failure] (SAFE-5).
class RefusingPlayerRepository extends FakePlayerRepository {
  new(this.failure, [super.players]);

  final AppFailure failure;

  @override
  Future<int> addPlayers(GroupId groupId, List<NewPlayer> players) async =>
      throw failure;

  @override
  Future<bool> inviteGuardian(
    GroupId groupId,
    PlayerId playerId, {
    required String email,
    String? name,
  }) async => throw failure;

  @override
  Future<ClaimOutcome> claimPlayer(
    GroupId groupId,
    PlayerId playerId,
    PlayerRelation relation,
  ) async => throw failure;

  @override
  Future<PlayerStatus> proposePlayer(
    GroupId groupId, {
    required String name,
    required PlayerRelation relation,
    String? jerseyNumber,
    String? dateOfBirth,
  }) async => throw failure;

  @override
  Future<void> resolvePlayerClaim(
    GroupId groupId,
    PlayerId playerId,
    UserId uid, {
    required bool approve,
  }) async => throw failure;

  @override
  Future<bool> resolvePendingPlayer(
    GroupId groupId,
    PlayerId playerId, {
    required bool approve,
  }) async => throw failure;
}

/// Photos pasted or dropped onto the page (CHAT-2, SPEC §4.2), sent by the
/// test.
class FakePhotoDrops implements PhotoDrops {
  final _photos = StreamController<List<PickedPhoto>>.broadcast();
  final _dragging = StreamController<bool>.broadcast();

  @override
  Stream<List<PickedPhoto>> get photos => _photos.stream;

  @override
  Stream<bool> get dragging => _dragging.stream;

  /// Pastes or drops [list].
  void drop(List<PickedPhoto> list) => _photos.add(list);

  /// Files start or stop being dragged over the page.
  void drag({required bool on}) => _dragging.add(on);
}

/// Imports in memory (SPEC §6.15): answers previews with [preview] and
/// imports with [imported], or fails with [failure]; records each call.
class FakeImportRepository implements ImportRepository {
  new({EventImportResult? preview, EventImportResult? imported, this.failure})
    : preview = preview ?? sampleImport,
      imported = imported ?? (preview ?? sampleImport);

  EventImportResult preview;
  EventImportResult imported;
  AppFailure? failure;

  /// "preview link webcal://x past=false", "import file 120 chars
  /// past=true", "teamreach preview link …", "google preview link …",
  /// "import groupme events 3 past=false", "check messages 250", "import
  /// documents 2".
  final List<String> calls = [];

  /// What the server holds, by source ID: messages and documents imported.
  final Map<String, ChatImportMessage> messages = {};
  final Map<String, ChatImportDocument> documents = {};

  /// Files uploaded: path → size.
  final Map<String, int> uploads = {};

  /// The team's free space for uploads; null for plenty.
  int? roomBytes;

  @override
  Future<EventImportResult> importEvents(
    GroupId groupId, {
    required ImportSource source,
    required bool includePast,
    required bool dryRun,
    String? url,
    String? ics,
    List<ListedEvent>? events,
  }) async {
    final from = url != null
        ? 'link $url'
        : ics != null
        ? 'file ${ics.length} chars'
        : 'groupme events ${events!.length}';
    // Calendar apps other than GameChanger say which they are.
    final app = switch (source) {
      ImportSource.teamreach || ImportSource.google => '${source.value} ',
      _ => '',
    };
    calls.add('$app${dryRun ? 'preview' : 'import'} $from past=$includePast');
    if (failure case final f?) throw f;
    return dryRun ? preview : imported;
  }

  @override
  Future<ChatImportResult> importMessages(
    GroupId groupId, {
    required ImportSource source,
    required List<ChatImportMessage> messages,
    bool check = false,
  }) async {
    calls.add('${check ? 'check' : 'import'} messages ${messages.length}');
    if (failure case final f?) throw f;
    final existing = {
      for (final m in messages)
        if (this.messages.containsKey(m.sourceId)) m.sourceId,
    };
    if (check) {
      return ChatImportResult(
        added: messages.length - existing.length,
        alreadyImported: existing.length,
        existing: existing,
      );
    }
    var added = 0;
    var missing = 0;
    for (final m in messages) {
      if (existing.contains(m.sourceId)) continue;
      missing += m.photos.where((p) => !uploads.containsKey(p.path)).length;
      this.messages[m.sourceId] = m;
      added++;
    }
    return ChatImportResult(
      added: added,
      alreadyImported: existing.length,
      missing: missing,
    );
  }

  @override
  Future<ChatImportResult> importDocuments(
    GroupId groupId, {
    required ImportSource source,
    required List<ChatImportDocument> documents,
    bool check = false,
  }) async {
    calls.add('${check ? 'check' : 'import'} documents ${documents.length}');
    if (failure case final f?) throw f;
    final existing = {
      for (final d in documents)
        if (this.documents.containsKey(d.sourceId)) d.sourceId,
    };
    if (check) {
      return ChatImportResult(
        added: documents.length - existing.length,
        alreadyImported: existing.length,
        existing: existing,
      );
    }
    var added = 0;
    var missing = 0;
    for (final d in documents) {
      if (existing.contains(d.sourceId)) continue;
      if (!uploads.containsKey(d.path)) {
        missing++;
        continue;
      }
      this.documents[d.sourceId] = d;
      added++;
    }
    return ChatImportResult(
      added: added,
      alreadyImported: existing.length,
      missing: missing,
    );
  }

  @override
  Future<void> upload(String path, Uint8List bytes, String contentType) async {
    final used = uploads.values.fold(0, (a, b) => a + b);
    if (roomBytes case final room? when used + bytes.length > room) {
      throw const StorageFull('upload-refused');
    }
    uploads[path] = bytes.length;
  }

  @override
  Future<({int width, int height})> imageSize(Uint8List bytes) async =>
      (width: 4, height: 3);
}

/// A preview of a short GameChanger season.
final sampleImport = EventImportResult(
  added: 3,
  alreadyImported: 1,
  past: 2,
  skippedCount: 1,
  first: DateTime.utc(2030, 10, 14, 23),
  last: DateTime.utc(2030, 10, 24, 16),
  skipped: const [
    SkippedImport(title: 'vs. Hawks', reason: ImportSkipReason.canceled),
  ],
  sample: [
    ImportedEventSample(
      title: 'Practice',
      type: EventType.practice,
      allDay: false,
      start: DateTime.utc(2030, 10, 14, 23),
      timeZone: 'America/Chicago',
      place: '123 Main St',
    ),
    ImportedEventSample(
      title: 'vs. Eagles',
      type: EventType.game,
      allDay: false,
      start: DateTime.utc(2030, 10, 17, 15),
      timeZone: 'America/Chicago',
      place: 'Riverside Park, 100 River Rd',
    ),
    ImportedEventSample(
      title: 'Season kickoff BBQ',
      type: EventType.social,
      allDay: true,
      start: DateTime.utc(2030, 10, 26, 5),
      startDate: '2030-10-26',
      timeZone: 'America/Chicago',
      place: '',
    ),
  ],
);
