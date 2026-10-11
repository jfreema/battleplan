import 'package:battleplan/features/groups/presentation/email_invites_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads commas, spaces, lines, and angle brackets; drops repeats', () {
    expect(
      emailsFrom('Sam <Sam@Example.com>, alex@example.com\nsam@example.com; x'),
      ['sam@example.com', 'alex@example.com'],
    );
  });

  test('ignores text that is not an address', () {
    expect(emailsFrom('not an email, @x.com, a@b'), isEmpty);
  });
}
