import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:flutter_test/flutter_test.dart';

Membership _m(String name, [String? players]) => Membership(
  groupId: const GroupId('y'),
  uid: const UserId('u'),
  role: MemberRole.member,
  displayName: name,
  playerSummary: players,
);

void main() {
  test('parents show their players (PLAYER-8)', () {
    expect(
      _m('Maria Rodriguez', 'Emma #7').nameWithPlayers,
      'Maria R. · Emma #7',
    );
    expect(
      _m('Ana Maria de la Cruz', 'Emma #7, Liam #23').nameWithPlayers,
      'Ana C. · Emma #7, Liam #23',
    );
  });

  test('a member who is a player shows their number (PLAYER-8)', () {
    expect(_m('Jared Freeman', '#12').nameWithPlayers, 'Jared F. #12');
    expect(
      _m('Jared Freeman', '#12, Emma #7').nameWithPlayers,
      'Jared F. #12 · Emma #7',
    );
    // A player without a number has no summary, so just the name.
    expect(_m('Jared Freeman', ' ').nameWithPlayers, 'Jared Freeman');
  });

  test('everyone else shows just their name', () {
    expect(_m('Coach Kim').nameWithPlayers, 'Coach Kim');
    expect(_m('Madonna', 'Lola').nameWithPlayers, 'Madonna · Lola');
  });
}
