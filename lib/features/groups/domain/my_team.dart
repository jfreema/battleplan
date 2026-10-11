import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';

/// A team as the signed-in person sees it in the switcher.
class MyTeam {
  const new({required this.group, required this.membership});

  final Group group;
  final Membership membership;

  /// Cheap unread dot: two timestamps already loaded (ARCH §10.2 rule 6).
  bool get hasUnread {
    final last = group.lastMessageAt;
    if (last == null) return false;
    final read = membership.lastReadAt;
    return read == null || last.isAfter(read);
  }

  DateTime? get lastActivity => group.lastMessageAt;
}
