import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/domain/roster_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pasted roster lines merge by player name, up to 4 guardians', () {
    final r = parsePastedRoster(
      'Emma R, Maria R, maria@example.com\n'
      'emma r, Luis R, luis@example.com\n'
      'Bad, Name, nope\n'
      'Solo',
    );
    expect(r.players.map((p) => p.name), ['Emma R', 'Solo']);
    expect(r.players.first.guardians.map((g) => g.email), [
      'maria@example.com',
      'luis@example.com',
    ]);
    expect(r.problems, ['Bad, Name, nope']);
  });

  test("a name and an email is an adult player's own email (PLAYER-1)", () {
    final r = parsePastedRoster(
      'Jared Freeman, jared@example.com\n'
      'Jared Freeman, Ann Freeman, ann@example.com\n'
      'jared freeman, other@example.com\n'
      'Emma R, Maria R',
    );
    expect(r.players.map((p) => p.name), ['Jared Freeman', 'Emma R']);
    final jared = r.players.first;
    expect(jared.email, 'jared@example.com');
    // Not taken as a guardian of themselves.
    expect(jared.guardians.map((g) => g.email), ['ann@example.com']);
    // One email of their own per player.
    expect(r.problems, ['jared freeman, other@example.com']);
    // A guardian's name alone stays a guardian.
    expect(r.players.last.email, isNull);
    expect(r.players.last.guardians.single.name, 'Maria R');
    expect(r.lines, 4);
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
