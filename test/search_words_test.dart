import 'dart:convert';
import 'dart:io';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/features/chat/domain/search_words.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Chat search's words (CHAT-20): the examples in shared/search_words.json,
  // which the server's tests check too.
  final examples =
      (jsonDecode(File('shared/search_words.json').readAsStringSync())
              as Map<String, dynamic>)['examples']
          as List<dynamic>;
  group('searchWords', () {
    for (final e in examples.cast<List<dynamic>>()) {
      test(jsonEncode(e[0]), () {
        expect(searchWords(e[0] as String), e[1]);
      });
    }

    test('keeps the longest words of a long message, in order', () {
      // 104 four-letter words, then one of eight: the long one stays, with
      // the first 99 of the rest.
      final short = [for (var i = 0; i < 104; i++) 'w${'$i'.padLeft(3, '0')}'];
      final words = searchWords('${short.join(' ')} longword');
      expect(words, hasLength(Limits.searchWordsMax));
      expect(words.last, 'longword');
      expect(words.first, 'w000');
      expect(words, isNot(contains('w099')));
    });
  });

  test('a message has the words of a search when it has every one', () {
    expect(hasSearchWords('Tournament at Riverside Park', ['riverside']), true);
    expect(
      hasSearchWords('Tournament at Riverside Park', ['park', 'tournament']),
      true,
    );
    expect(
      hasSearchWords('Tournament at Riverside Park', ['park', 'game']),
      false,
    );
    expect(hasSearchWords('Tournament', const []), false);
  });
}
