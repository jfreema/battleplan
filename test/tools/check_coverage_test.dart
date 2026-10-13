// The CI coverage gate (SPEC §8.1): which files count, and how lcov reads.
import 'package:flutter_test/flutter_test.dart';

import '../../tools/check_coverage.dart' as cov;

void main() {
  test('counts hand-written domain and data files only', () {
    expect(
      cov.counted('lib/features/chat/data/firestore_message_repository.dart'),
      isTrue,
    );
    expect(cov.counted('lib/features/chat/domain/message.dart'), isTrue);
    expect(
      cov.counted('lib/features/chat/domain/message.freezed.dart'),
      isFalse,
    );
    expect(cov.counted('lib/features/chat/domain/message.g.dart'), isFalse);
    expect(
      cov.counted('lib/features/chat/presentation/chat_screen.dart'),
      isFalse,
    );
    expect(cov.counted('lib/core/ids.dart'), isFalse);
  });

  test('reads lines found and hit per file', () {
    const lcov = '''
SF:/repo/lib/features/a/domain/x.dart
DA:1,1
DA:2,0
DA:3,4
end_of_record
SF:lib/features/a/presentation/y.dart
DA:1,0
end_of_record
''';
    expect(cov.parseLcov(lcov, root: '/repo/'), {
      'lib/features/a/domain/x.dart': (found: 3, hit: 2),
    });
  });

  test('knows when a file has lines to cover', () {
    expect(
      cov.hasCode('abstract interface class A { Future<void> f(); }'),
      isFalse,
    );
    expect(cov.hasCode('int f() => 1;'), isTrue);
    expect(cov.hasCode('void f() {\n}'), isTrue);
    expect(cov.hasCode('bool get ok {\n return true; }'), isTrue);
  });
}
