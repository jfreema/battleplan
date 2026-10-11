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
}
