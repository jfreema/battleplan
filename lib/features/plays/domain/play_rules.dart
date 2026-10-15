import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';

/// Whether [me] may draw, change, copy, and delete the team's plays
/// (BOARD-4): its admins, and super admins (SPEC §3), on an open team.
/// Everyone on the team views them.
bool canEditPlays(Group group, Membership? me, {bool superAdmin = false}) =>
    !group.isArchived && (superAdmin || (me?.isAdmin ?? false));
