import 'package:battleplan/core/ids.dart';

/// What [CalendarLinkRepository.set] does to a calendar link (SCHED-11).
enum CalendarLinkAction { make, reset, off }

/// A calendar link (SCHED-11, ARCH §6.15): a private address that Google,
/// Apple, or Outlook Calendar reads to keep a schedule in sync. The
/// [token] is the secret in it.
final class CalendarLink {
  const new({required this.token, this.groupId, this.fetchedAt});

  final String token;

  /// The team it's for, or null for all the person's teams.
  final GroupId? groupId;

  /// When a calendar last read it; null until one has.
  final DateTime? fetchedAt;
}

/// The signed-in person's calendar links (SCHED-11).
abstract interface class CalendarLinkRepository {
  /// Their links, live: one per team they made one for, and the one for
  /// all their teams.
  Stream<List<CalendarLink>> watchMine(UserId uid);

  /// Makes (or returns), resets, or turns off their link for [groupId], or
  /// for all their teams when null. Returns its token, null once it's off.
  Future<String?> set(GroupId? groupId, CalendarLinkAction action);
}
