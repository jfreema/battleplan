import 'package:battleplan/features/groups/presentation/add_members_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('people lines: name and email in either order, or email alone', () {
    final r = parsePeople(
      'Sam Rivera, sam@example.com\nalex@example.com\nkim@x.com, Kim Lee\nnobody',
    );
    expect(r.entries.map((e) => e.email), [
      'sam@example.com',
      'alex@example.com',
      'kim@x.com',
    ]);
    expect(r.entries.map((e) => e.name), ['Sam Rivera', null, 'Kim Lee']);
    expect(r.problems, ['nobody']);
  });
}
