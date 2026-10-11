import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/group_repository.dart';
import 'package:battleplan/features/groups/domain/invite.dart';
import 'package:battleplan/features/groups/domain/invite_repository.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/domain/my_team.dart';
import 'package:battleplan/features/groups/domain/plan_repository.dart';
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

@riverpod
Stream<Group?> group(Ref ref, GroupId id) =>
    ref.watch(groupRepositoryProvider).watchGroup(id);

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

/// A URL for a team logo path, or null.
@riverpod
Future<String?> teamPhotoUrl(Ref ref, String path) =>
    ref.watch(groupRepositoryProvider).photoUrl(path);

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
PlanRepository planRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// Plus licenses I hold that haven't ended (PLAN-3).
@riverpod
Stream<List<HeldLicense>> myLicenses(Ref ref) {
  final uid = ref.watch(authUserProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(planRepositoryProvider).watchMyLicenses(UserId(uid));
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
