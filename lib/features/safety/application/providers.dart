import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/safety/domain/safety.dart';
import 'package:battleplan/features/safety/domain/safety_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// Overridden in app/providers.dart.
@Riverpod(keepAlive: true)
SafetyRepository safetyRepository(Ref ref) =>
    throw UnimplementedError('Wired in app/providers.dart');

/// The people I blocked (SET-5).
@Riverpod(keepAlive: true)
Stream<List<BlockedPerson>> blockedPeople(Ref ref) {
  final uid = ref.watch(authUserProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(safetyRepositoryProvider).watchBlocked(UserId(uid));
}

/// Just their IDs, for collapsing their messages (CHAT-12).
@Riverpod(keepAlive: true)
Set<String> blockedIds(Ref ref) => {
  for (final b
      in ref.watch(blockedPeopleProvider).value ?? const <BlockedPerson>[])
    b.uid.value,
};

/// A team's open reports (SAFE-4). Only admins can read them.
@riverpod
Stream<List<Report>> openReports(Ref ref, GroupId groupId) =>
    ref.watch(safetyRepositoryProvider).watchOpenReports(groupId);
