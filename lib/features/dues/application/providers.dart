import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/dues/domain/due.dart';
import 'package:battleplan/features/dues/domain/dues_repository.dart';
import 'package:battleplan/features/schedule/application/providers.dart'
    show myParticipantsProvider;
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
/// group, the same people I answer RSVPs for.
@riverpod
List<DuePayer> myPayers(Ref ref, GroupId groupId) => [
  for (final p in ref.watch(myParticipantsProvider(groupId)))
    (type: p.type, id: p.id, name: p.name),
];

/// What I owe on [groupId] (DUES-2): my own share, or my players'.
@riverpod
Stream<List<DueCharge>> myCharges(Ref ref, GroupId groupId) {
  final payers = ref.watch(myPayersProvider(groupId));
  return ref.watch(duesRepositoryProvider).watchMine(groupId, payers);
}

/// How to pay the team (DUES-3).
@riverpod
Stream<DuesPayments> duesPayments(Ref ref, GroupId groupId) =>
    ref.watch(duesRepositoryProvider).watchPayments(groupId);

/// The status a tap on a charge moves to: owed to paid, paid back to owed,
/// waived back to owed.
DueStatus nextStatus(DueStatus s) =>
    s == DueStatus.owed ? DueStatus.paid : DueStatus.owed;
