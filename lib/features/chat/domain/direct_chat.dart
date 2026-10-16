import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';

/// One of my direct conversations as Messages lists it (CHAT-19): the
/// conversation, and my membership of it, which holds my read marker and
/// mute.
class DirectChat {
  const new({required this.group, required this.membership});

  final Group group;
  final Membership membership;

  /// The other person in it.
  String get otherUid =>
      membership.otherUid ?? group.otherThan(membership.uid.value) ?? '';

  /// Their name and photo, kept up to date by the server; "Deleted user"
  /// once their account is gone.
  DirectPerson? get other => group.people[otherUid];

  /// Messages newer than my read marker, from the other person. Sending
  /// marks a chat read (CHAT-9), so my own never count.
  bool get hasUnread => hasUnreadDirect(membership);

  /// When it last had a message.
  DateTime? get lastActivity => group.lastMessageAt ?? membership.lastMessageAt;

  /// Whether its newest message is mine ("You: …").
  bool get lastIsMine =>
      group.lastMessageAuthorId != null &&
      group.lastMessageAuthorId == membership.uid.value;
}

/// Whether my membership of a conversation has messages I haven't read:
/// its newest is after my read marker. Cheap: two timestamps already
/// loaded, no conversation read (ARCH §10.2 rule 6).
bool hasUnreadDirect(Membership m) {
  final last = m.lastMessageAt;
  if (last == null) return false;
  final read = m.lastReadAt;
  return read == null || last.isAfter(read);
}
