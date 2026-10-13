import 'dart:async';

import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/application/team_editor.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/group_repository.dart';
import 'package:battleplan/features/groups/domain/invite.dart';
import 'package:battleplan/features/groups/domain/invite_repository.dart';
import 'package:battleplan/features/groups/domain/media.dart';
import 'package:battleplan/features/groups/domain/media_repository.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/domain/my_team.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
GroupRepository groupRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
MemberRepository memberRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

@Riverpod(keepAlive: true)
Stream<List<Membership>> myMemberships(Ref ref) {
  final user = ref.watch(authUserProvider).value;
  if (user == null) return Stream.value(const []);
  return ref
      .watch(memberRepositoryProvider)
      .watchMyMemberships(UserId(user.uid));
}

/// A team, live. One you can't read (removed, deleted, or suspended)
/// reads as null, and its read ends there. A suspension can be lifted with
/// nothing to tell its members, so while it's null the read starts over:
/// after [groupRetryFirst], doubling to [groupRetryMax], and whenever the
/// app comes back to the foreground (ADMIN-3).
@riverpod
Stream<Group?> group(Ref ref, GroupId id) {
  final repo = ref.watch(groupRepositoryProvider);
  final out = StreamController<Group?>();
  StreamSubscription<Group?>? sub;
  Timer? retry;
  var wait = groupRetryFirst;
  var gone = false;
  void open() {
    retry?.cancel();
    unawaited(sub?.cancel());
    sub = repo.watchGroup(id).listen((group) {
      out.add(group);
      retry?.cancel();
      gone = group == null;
      if (!gone) {
        wait = groupRetryFirst;
        return;
      }
      retry = Timer(wait, open);
      wait = wait * 2 > groupRetryMax ? groupRetryMax : wait * 2;
    }, onError: out.addError);
  }

  open();
  final lifecycle = AppLifecycleListener(
    onResume: () {
      if (gone) open();
    },
  );
  ref.onDispose(() {
    retry?.cancel();
    lifecycle.dispose();
    unawaited(sub?.cancel());
    unawaited(out.close());
  });
  return out.stream;
}

/// The first wait before reading an unreadable team again; it doubles up
/// to [groupRetryMax].
const groupRetryFirst = Duration(seconds: 30);

/// The longest wait between reads of an unreadable team.
const groupRetryMax = Duration(minutes: 10);

/// The switcher's list: one group read per membership (ARCH §6.2 query
/// table), most recent activity first, archived teams last.
@Riverpod(keepAlive: true)
AsyncValue<List<MyTeam>> myTeams(Ref ref) {
  final memberships = ref.watch(myMembershipsProvider);
  return memberships.whenData((list) {
    final teams = <MyTeam>[];
    for (final m in list) {
      final group = ref.watch(groupProvider(m.groupId)).value;
      if (group != null) teams.add(MyTeam(group: group, membership: m));
    }
    teams.sort((a, b) {
      if (a.group.isArchived != b.group.isArchived) {
        return a.group.isArchived ? 1 : -1;
      }
      final x = a.lastActivity ?? DateTime(2000);
      final y = b.lastActivity ?? DateTime(2000);
      return y.compareTo(x);
    });
    return teams;
  });
}

/// How the roster lists its players (TEAM-10).
enum RosterOrder {
  /// By jersey number, players without one last, then by name. The default.
  number,

  /// By name.
  name,
}

/// The roster's order (TEAM-10), kept while the app runs.
@Riverpod(keepAlive: true)
class RosterView extends _$RosterView {
  @override
  RosterOrder build() => RosterOrder.number;

  RosterOrder get order => state;
  set order(RosterOrder value) => state = value;
}

/// A team's roster, sorted by name (TEAM-3).
@riverpod
Stream<List<Membership>> roster(Ref ref, GroupId groupId) => ref
    .watch(memberRepositoryProvider)
    .watchRoster(groupId)
    .map(
      (list) => [...list]
        ..sort(
          (a, b) => a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          ),
        ),
    );

/// The signed-in person's membership on [groupId], if any.
@riverpod
Membership? myMembership(Ref ref, GroupId groupId) => ref
    .watch(myMembershipsProvider)
    .value
    ?.where((m) => m.groupId == groupId)
    .firstOrNull;

/// True while a super admin looks at a team they aren't on (ADMIN-3 View
/// team): its tabs, read-only, with the "Viewing as super admin" banner and
/// moderation. False until their memberships have loaded.
@riverpod
bool viewingAsSuperAdmin(Ref ref, GroupId groupId) {
  final superAdmin = ref.watch(
    authUserProvider.select((a) => a.value?.isSuperAdmin ?? false),
  );
  if (!superAdmin) return false;
  // Right after sign-in the list still holds the previous one.
  final memberships = ref.watch(myMembershipsProvider);
  if (!memberships.hasValue || memberships.isLoading) return false;
  return !memberships.value!.any((m) => m.groupId == groupId);
}

/// Saves edits to [groupId] (TEAM-5, CHAT-18): directly for its admins,
/// through the audited admin callable for a super admin who isn't one
/// (ADMIN-3).
@riverpod
TeamEditor teamEditor(Ref ref, GroupId groupId) {
  final teamAdmin = ref.watch(myMembershipProvider(groupId))?.isAdmin ?? false;
  final superAdmin = ref.watch(
    authUserProvider.select((a) => a.value?.isSuperAdmin ?? false),
  );
  return TeamEditor(
    ref.watch(groupRepositoryProvider),
    ref.watch(adminRepositoryProvider),
    asSuperAdmin: superAdmin && !teamAdmin,
  );
}

/// A URL for a stored team file (the logo, the chat background, or a Media
/// preview), or null.
@riverpod
Future<String?> teamPhotoUrl(Ref ref, String path) =>
    ref.watch(groupRepositoryProvider).photoUrl(path);

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
MediaRepository mediaRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// The team's files, largest first, for Media (STORE-5). Read once per
/// visit (it lists the bucket); invalidate to refresh after a delete.
@riverpod
Future<TeamMedia> teamMedia(Ref ref, GroupId groupId) =>
    ref.watch(mediaRepositoryProvider).list(groupId);

/// Storage banners dismissed this session, by team and level (STORE-3,
/// STORE-4). Each level is its own, so filling up after dismissing the 90%
/// warning still shows the full banner. A new sign-in starts over.
@Riverpod(keepAlive: true)
class DismissedStorageBanners extends _$DismissedStorageBanners {
  @override
  Set<(GroupId, StorageLevel)> build() {
    ref.watch(authUserProvider.select((a) => a.value?.uid));
    return const {};
  }

  void dismiss(GroupId groupId, StorageLevel level) =>
      state = {...state, (groupId, level)};
}

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
InviteRepository inviteRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// The team's invite link (INV-1).
@riverpod
Future<TeamInvite> teamInvite(Ref ref, GroupId groupId) =>
    ref.watch(inviteRepositoryProvider).teamInvite(groupId);

/// The team's email invites with their state (INV-4).
@riverpod
Future<List<EmailInvite>> emailInvites(Ref ref, GroupId groupId) =>
    ref.watch(inviteRepositoryProvider).emailInvites(groupId);
