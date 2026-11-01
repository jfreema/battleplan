// Download links kept for the run (ARCH §5.6).
import 'package:battleplan/core/url_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('asks once per path, sharing a request already on its way', () async {
    final cache = UrlCache();
    var asked = 0;
    Future<String?> fetch() async {
      asked++;
      return 'https://x/$asked';
    }

    final both = await Future.wait([
      cache.get('a', fetch),
      cache.get('a', fetch),
    ]);
    expect(both, ['https://x/1', 'https://x/1']);
    expect(await cache.get('a', fetch), 'https://x/1');
    expect(await cache.get('b', fetch), 'https://x/2');
    expect(asked, 2);
  });

  test("doesn't keep a missing link or an error", () async {
    final cache = UrlCache();
    expect(await cache.get('a', () async => null), isNull);
    expect(await cache.get('a', () async => 'https://x/a'), 'https://x/a');
    await expectLater(
      cache.get('b', () async => throw StateError('offline')),
      throwsStateError,
    );
    expect(await cache.get('b', () async => 'https://x/b'), 'https://x/b');
  });
}
