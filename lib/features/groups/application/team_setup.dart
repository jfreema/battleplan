import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/features/groups/application/providers.dart';
import 'package:battleplan/features/groups/domain/team_setup.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'team_setup.g.dart';

/// The setup card at the top of a new team's chat (TEAM-1, #3), with what's
/// done of its steps, or null where it doesn't show. Only the team's admins
/// see it (the owner and admins, not members, and not a super admin
/// viewing the team), only on a team made since the card shipped and in
/// its first 30 days (`Group.inSetupWindow`), and only until they put it
/// away (`Membership.setupClosed`).
///
/// Its own file, so groups' providers don't import the schedule's, which
/// import them.
@riverpod
TeamSetup? teamSetup(Ref ref, GroupId groupId) {
  // Only these of my membership, which changes with every message read.
  final admin = ref.watch(
    myMembershipProvider(groupId)
        .select((m) => m != null && m.isAdmin && !m.setupClosed),
  );
  if (!admin) return null;
  final now = ref.watch(clockProvider)();
  final counts = ref.watch(
    groupProvider(groupId).select((g) {
      final team = g.value;
      if (team == null || !team.inSetupWindow(now)) return null;
      return (
        group: team.isGroup,
        players: team.playerCount > 0,
        invited: team.memberCount > 1,
      );
    }),
  );
  if (counts == null) return null;
  // Not known yet reads as not done: a new team has no events, so the
  // card doesn't wait for the read.
  final event = ref.watch(teamHasEventsProvider(groupId)).value ?? false;
  return (
    group: counts.group,
    players: counts.players,
    invited: counts.invited,
    event: event,
  );
}
