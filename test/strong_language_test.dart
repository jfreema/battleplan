import 'dart:convert';
import 'dart:io';

import 'package:battleplan/features/safety/domain/strong_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The team language filter (SAFE-7): the examples in
  // shared/strong_language.json, which the server's tests check too.
  final examples =
      (jsonDecode(File('shared/strong_language.json').readAsStringSync())
              as Map<String, dynamic>)['examples']
          as List<dynamic>;
  group('maskStrongLanguage', () {
    for (final e in examples.cast<List<dynamic>>()) {
      test(jsonEncode(e[0]), () {
        expect(maskStrongLanguage(e[0] as String), e[1]);
      });
    }
  });
}
