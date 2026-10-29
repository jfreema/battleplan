import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/chat/domain/direct_chat.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/groups/domain/my_team.dart';
import 'package:battleplan/features/safety/application/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'direct_chats.g.dart';

/// Messages (CHAT-19): my conversations with messages, newest first, each
/// with its conversation, which names the other person and holds the
/// newest message. Conversations with people I blocked are left out: what
/// they send never reaches me (SAFE-2).
@riverpod
AsyncValue<List<DirectChat>> myDirectChats(Ref ref) {
  final blocked = ref.watch(blockedIdsProvider);
  return ref.watch(myDirectMembershipsProvider).whenData((list) {
    final chats = <DirectChat>[];
    for (final m in list) {
      final group = ref.watch(groupProvider(m.groupId)).value;
      if (group == null) continue;
      final chat = DirectChat(group: group, membership: m);
      if (!blocked.contains(chat.otherUid)) chats.add(chat);
    }
    chats.sort((a, b) {
      final x = a.lastActivity ?? DateTime(2000);
      final y = b.lastActivity ?? DateTime(2000);
      return y.compareTo(x);
    });
    return chats;
  });
}

/// How many conversations have unread messages, for the Messages button
/// (CHAT-19): muted ones and people I blocked don't count. From my
/// memberships alone, so the header reads no conversations.
@Riverpod(keepAlive: true)
int directUnreadCount(Ref ref) {
  final blocked = ref.watch(blockedIdsProvider);
  final now = DateTime.now();
  return [
    for (final m
        in ref.watch(myDirectMembershipsProvider).value ?? const <Membership>[])
      if (hasUnreadDirect(m) &&
          !m.isMutedAt(now) &&
          !blocked.contains(m.otherUid))
        m,
  ].length;
}

/// Someone New message offers (CHAT-19): a person on my teams, with their
/// name, photo, and the names of the teams we share.
typedef MessageablePerson = ({
  UserId uid,
  String name,
  String? photoPath,
  List<String> teams,
});

/// Everyone New message offers (CHAT-19), by name: the people on my teams
/// that the roster shows me (TEAM-3: on a team that keeps its people to its
/// admins, only its coaches, unless I'm one of the admins), who have
/// joined, other than me and people I blocked. Read from the rosters, which
/// the session keeps.
@riverpod
List<MessageablePerson> messageablePeople(Ref ref) {
  final me = ref.watch(authUserProvider).value?.uid;
  final blocked = ref.watch(blockedIdsProvider);
  final people = <String, MessageablePerson>{};
  for (final t in ref.watch(myTeamsProvider).value ?? const <MyTeam>[]) {
    final seeAll = t.group.settings.membersCanSeePeople || t.membership.isAdmin;
    for (final m
        in ref.watch(rosterProvider(t.group.id)).value ??
            const <Membership>[]) {
      final uid = m.uid.value;
      if (uid == me || m.pending || blocked.contains(uid)) continue;
      // A basic group has no coaches (TEAM-14).
      if (!seeAll && !(t.group.hasPlayers && m.isCoach)) continue;
      final known = people[uid];
      people[uid] = (
        uid: m.uid,
        name: known?.name ?? m.displayName,
        photoPath: known?.photoPath ?? m.photoPath,
        teams: [...?known?.teams, t.group.name],
      );
    }
  }
  return people.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}
