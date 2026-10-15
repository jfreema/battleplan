import 'package:battleplan/features/players/presentation/guardian_picker.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  // "Add a guardian" offers people already on the team (PLAYER-5).
  group('guardianCandidates', () {
    final roster = [
      testMembership('y', 'me', name: 'Maria'),
      testMembership('y', 'zoe', name: 'zoe Park'),
      testMembership('y', 'carlos', name: 'Carlos Rodriguez'),
      testMembership('y', 'emma', name: 'Emma Rodriguez'),
    ];

    List<String> names({required bool isAdmin, required bool seePeople}) => [
      for (final m in guardianCandidates(
        roster,
        linked: {'emma'},
        me: 'me',
        isAdmin: isAdmin,
        membersCanSeePeople: seePeople,
      ))
        m.displayName,
    ];

    test('leaves out me and the people linked to the player, by name', () {
      expect(names(isAdmin: false, seePeople: true), [
        'Carlos Rodriguez',
        'zoe Park',
      ]);
    });

    test('offers no one to a member when the team keeps its people to its '
        'admins (TEAM-3)', () {
      expect(names(isAdmin: false, seePeople: false), isEmpty);
      expect(names(isAdmin: true, seePeople: false), hasLength(2));
    });
  });
}
