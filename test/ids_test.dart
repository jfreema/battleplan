import 'package:battleplan/core/ids.dart';
import 'package:flutter_test/flutter_test.dart';

// IDs the app makes itself (ARCH §5.3).
void main() {
  test('request IDs are 20 letters and digits, different every time '
      '(TEAM-1)', () {
    final ids = {for (var i = 0; i < 200; i++) newRequestId()};
    expect(ids, hasLength(200));
    for (final id in ids) {
      expect(id, matches(RegExp(r'^[A-Za-z0-9]{20}$')));
    }
  });
}
