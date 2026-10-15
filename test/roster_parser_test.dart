import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/domain/roster_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('one player per line: a name, and a number if there is one', () {
    final r = parsePastedRoster(
      'Emma Rodriguez, 7\n'
      '\n'
      'Arjun Shah\t#12\n'
      'Mia Chen,\n'
      '  Noah Kim , # 4  ',
    );
    expect(r.players, const [
      NewPlayer(name: 'Emma Rodriguez', jerseyNumber: '7'),
      NewPlayer(name: 'Arjun Shah', jerseyNumber: '12'),
      NewPlayer(name: 'Mia Chen'),
      NewPlayer(name: 'Noah Kim', jerseyNumber: '4'),
    ]);
    expect(r.problems, isEmpty);
    // Blank lines don't count.
    expect(r.lines, 4);
  });

  test('lines it cannot read, and repeated names, are listed (PLAYER-1)', () {
    final r = parsePastedRoster(
      // The old "player, guardian, email" lines: who's linked comes from
      // claims now (PLAYER-3).
      'Emma Rodriguez, Maria Rodriguez, maria@example.com\n'
      'Jared Freeman, jared@example.com\n'
      ', 9\n'
      '${'x' * 61}\n'
      'Arjun Shah, 12\n'
      'arjun shah, 13',
    );
    expect(r.players, const [
      NewPlayer(name: 'Arjun Shah', jerseyNumber: '12'),
    ]);
    expect(r.problems, [
      'Emma Rodriguez, Maria Rodriguez, maria@example.com',
      'Jared Freeman, jared@example.com',
      ', 9',
      'x' * 61,
      'arjun shah, 13',
    ]);
    expect(r.lines, 6);
  });

  test('a member is one player at most, counting what waits (PLAYER-3)', () {
    const me = UserId('jared');
    const g = GroupId('g');
    expect(canStillBeAPlayer(me), isTrue);
    // A guardian link, a declined claim, or someone else's don't count.
    expect(
      canStillBeAPlayer(
        me,
        links: const [
          GuardianLink(playerId: PlayerId('a'), groupId: g, uid: me),
          GuardianLink(
            playerId: PlayerId('b'),
            groupId: g,
            uid: UserId('ann'),
            relation: PlayerRelation.self,
          ),
        ],
        requests: const [
          GuardianRequest(
            playerId: PlayerId('c'),
            groupId: g,
            uid: me,
            status: GuardianRequestStatus.declined,
            relation: PlayerRelation.self,
          ),
          GuardianRequest(
            playerId: PlayerId('d'),
            groupId: g,
            uid: me,
            status: GuardianRequestStatus.pending,
          ),
        ],
        pendingPlayers: const [
          Player(
            id: PlayerId('e'),
            groupId: g,
            displayName: 'Kid',
            status: PlayerStatus.pending,
            proposedBy: 'jared',
            proposedRelation: PlayerRelation.guardian,
          ),
        ],
      ),
      isTrue,
    );
    expect(
      canStillBeAPlayer(
        me,
        links: const [
          GuardianLink(
            playerId: PlayerId('a'),
            groupId: g,
            uid: me,
            relation: PlayerRelation.self,
          ),
        ],
      ),
      isFalse,
    );
    expect(
      canStillBeAPlayer(
        me,
        requests: const [
          GuardianRequest(
            playerId: PlayerId('c'),
            groupId: g,
            uid: me,
            status: GuardianRequestStatus.pending,
            relation: PlayerRelation.self,
          ),
        ],
      ),
      isFalse,
    );
    expect(
      canStillBeAPlayer(
        me,
        pendingPlayers: const [
          Player(
            id: PlayerId('e'),
            groupId: g,
            displayName: 'Jared',
            status: PlayerStatus.pending,
            proposedBy: 'jared',
            proposedRelation: PlayerRelation.self,
          ),
        ],
      ),
      isFalse,
    );
  });
}
