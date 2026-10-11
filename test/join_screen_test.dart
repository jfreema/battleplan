import 'package:battleplan/features/groups/presentation/enter_code_screen.dart';
import 'package:battleplan/features/groups/presentation/join_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('invite codes display as two groups of four', () {
    expect(JoinScreen.formatCode('k7xpm2qr'), 'K7XP-M2QR');
    expect(JoinScreen.formatCode('K7XP-M2QR'), 'K7XP-M2QR');
    expect(JoinScreen.formatCode('short'), 'SHORT');
  });

  test('invite codes come out of typed text and scanned links', () {
    expect(inviteCodeFrom(' k7xp-m2qr '), 'K7XPM2QR');
    expect(
      inviteCodeFrom('https://getbattleplan.app/join/K7XPM2QR'),
      'K7XPM2QR',
    );
    expect(inviteCodeFrom('hello'), isNull);
  });
}
