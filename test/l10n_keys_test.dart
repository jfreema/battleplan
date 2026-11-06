// Every string in the app's ARB is used by the app (Open Field spec 8.2):
// a screen that stops using one takes it out of lib/l10n/app_en.arb.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Older strings nothing uses yet, left for their own clean-up. Remove a
/// key from here when it's deleted or used again.
const _knownUnused = {
  'backToTeams',
  'membersAddedCount',
  'membersInvitedCount',
  'tooManyPhotos',
  'directPhoto',
  'personNotJoined',
};

void main() {
  test('every string in the ARB is used in lib/', () {
    final arb = jsonDecode(
      File('lib/l10n/app_en.arb').readAsStringSync(),
    ) as Map<String, Object?>;
    final keys = arb.keys.where((k) => !k.startsWith('@'));
    final words = <String>{};
    final word = RegExp(r'\w+');
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.contains('/l10n/gen/')) continue;
      words.addAll(word.allMatches(file.readAsStringSync()).map((m) => m[0]!));
    }
    final unused = [
      for (final k in keys)
        if (!words.contains(k) && !_knownUnused.contains(k)) k,
    ];
    expect(unused, isEmpty, reason: 'Unused strings in app_en.arb');
  });
}
