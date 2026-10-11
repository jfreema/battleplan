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

  test('everyone else shows just their name', () {
    expect(_m('Coach Kim').nameWithPlayers, 'Coach Kim');
    expect(_m('Madonna', 'Lola').nameWithPlayers, 'Madonna · Lola');
  });
}
