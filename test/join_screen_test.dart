import 'package:battleplan/features/groups/presentation/join_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('invite codes display as two groups of four', () {
    expect(JoinScreen.formatCode('k7xpm2qr'), 'K7XP-M2QR');
    expect(JoinScreen.formatCode('K7XP-M2QR'), 'K7XP-M2QR');
    expect(JoinScreen.formatCode('short'), 'SHORT');
  });
}
