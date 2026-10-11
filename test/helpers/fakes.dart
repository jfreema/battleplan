import 'dart:async';
import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
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
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/notifications/domain/push_repository.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/domain/player_repository.dart';
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

  @override
  Future<UploadedPhotos> uploadPhotos(
    GroupId groupId,
    List<NewPhoto> photos, {
    void Function(double progress)? onProgress,
  }) async {
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
        createdAt: DateTime.now(),
      ),
    );
    _changes.add(null);
  }
}

/// Returns [photos] when asked for chat photos.
class FakePhotoPicker implements PhotoPicker {
  new([this.photos = const []]);

  final List<PickedPhoto> photos;

  @override
  Future<Uint8List?> pickProfilePhoto() async => null;

  @override
  Future<List<PickedPhoto>> pickChatPhotos({int limit = 10}) async =>
      photos.take(limit).toList();

  @override
  Future<PickedPhoto?> takeChatPhoto() async => null;

  @override
  bool get canUseCamera => false;
}
