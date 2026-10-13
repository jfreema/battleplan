// ENG-9: every library the app depends on has a decision-log entry
// (docs/ARCHITECTURE.md §14), so a new one can't slip in unrecorded.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Libraries covered by an entry that names their family, not each one.
const _covered = {
  // The Firebase SDKs: Firebase is the backend (D1, D3, D29).
  'firebase_', 'cloud_',
  // Code-generation companions of D2's Riverpod and freezed, and of
  // Flutter's own localizations tool.
  'flutter_riverpod', 'riverpod_annotation', 'freezed_annotation',
  'json_annotation', 'intl',
};

void main() {
  test('every runtime dependency has a decision-log entry (ENG-9)', () {
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final start = pubspec.indexOf('dependencies:');
    final names = <String>[];
    for (final line in pubspec.skip(start + 1)) {
      if (!line.startsWith(' ')) break;
      // `  name: ^1.0.0`; an SDK package's `sdk: flutter` line is nested.
      final m = RegExp(r'^  ([a-z0-9_]+):\s*\S').firstMatch(line);
      if (m != null) names.add(m[1]!);
    }
    expect(names, contains('gal'));

    final doc = File('docs/ARCHITECTURE.md').readAsStringSync();
    final log = doc.substring(
      doc.indexOf('## 14. Decision log'),
      doc.indexOf('## 15.'),
    );
    // Named in code style, or plainly when the name can't be a word (D2's
    // "Riverpod + go_router + freezed").
    bool named(String n) =>
        log.contains('`$n`') ||
        (n.contains('_') &&
            RegExp('(?<![a-z0-9_])$n(?![a-z0-9_])').hasMatch(log));
    final missing = [
      for (final n in names)
        if (!named(n) && !_covered.any(n.startsWith)) n,
    ];
    expect(missing, isEmpty, reason: 'Add a D row for each to §14');
  });
}
