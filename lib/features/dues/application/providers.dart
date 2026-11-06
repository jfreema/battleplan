import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/dues/domain/due.dart';
import 'package:battleplan/features/dues/domain/dues_repository.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/schedule/domain/rsvp.dart' show Participant;
import 'package:battleplan/features/schedule/domain/schedule_rules.dart'
    show participantsFor;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
DuesRepository duesRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// The team's dues (admins, DUES-1).
@riverpod
Stream<List<Due>> teamDues(Ref ref, GroupId groupId) =>
    ref.watch(duesRepositoryProvider).watchDues(groupId);

/// Everyone's share of one due (admins, DUES-2).
@riverpod
Stream<List<DueCharge>> dueCharges(Ref ref, GroupId groupId, String dueId) =>
    ref.watch(duesRepositoryProvider).watchDueCharges(groupId, dueId);

/// Who I pay for on [groupId] (DUES-2): my players on a team, myself in a
/// group, the same people I answer RSVPs for ([participantsFor]). Loading
/// until my membership, the team, and on a team its players and player
/// links have loaded, and failing when any of them fails, so nobody is told
/// they owe nothing before it's known whom they pay for.
@riverpod
AsyncValue<List<DuePayer>> myPayers(Ref ref, GroupId groupId) {
  final memberships = ref.watch(myMembershipsProvider);
  if (!memberships.hasValue) return _pending(memberships);
  final me = ref.watch(myMembershipProvider(groupId));
  if (me == null) return const AsyncData([]);
  final group = ref.watch(groupProvider(groupId));
  if (!group.hasValue) return _pending(group);
  final List<Participant> people;
  if (group.value?.isGroup ?? false) {
    people = participantsFor(me: me, isTeam: false);
  } else {
    final players = ref.watch(playersProvider(groupId));
    if (!players.hasValue) return _pending(players);
    final links = ref.watch(guardianLinksProvider(groupId));
    if (!links.hasValue) return _pending(links);
    people = participantsFor(
      me: me,
      isTeam: true,
      players: players.requireValue,
      links: links.requireValue,
    );
  }
  return AsyncData([
    for (final p in people) (type: p.type, id: p.id, name: p.name),
  ]);
}

/// A read that has no value yet, as [myPayers]': its error, or loading.
AsyncValue<List<DuePayer>> _pending(AsyncValue<Object?> v) => v.hasError
    ? AsyncError(v.error!, v.stackTrace ?? StackTrace.current)
    : const AsyncLoading();

/// What I owe on [groupId] (DUES-2): my own share, or my players'. Loading
/// until [myPayers] knows whom I pay for, and failing when it fails.
@riverpod
Stream<List<DueCharge>> myCharges(Ref ref, GroupId groupId) {
  final payers = ref.watch(myPayersProvider(groupId));
  if (payers.value case final list?) {
    return ref.watch(duesRepositoryProvider).watchMine(groupId, list);
  }
  if (payers.error case final e?) return Stream.error(e, payers.stackTrace);
  // Stays loading until the payers are known.
  return const Stream.empty();
}

/// How to pay the team (DUES-3).
@riverpod
Stream<DuesPayments> duesPayments(Ref ref, GroupId groupId) =>
    ref.watch(duesRepositoryProvider).watchPayments(groupId);

/// The status a tap on a charge moves to: owed to paid, paid back to owed,
/// waived back to owed.
DueStatus nextStatus(DueStatus s) =>
    s == DueStatus.owed ? DueStatus.paid : DueStatus.owed;
