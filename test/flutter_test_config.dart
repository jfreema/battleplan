// Runs around every test file. Arena's font is an asset the app loads when
// Arena is used (loadArenaFont), not a declared font, so tests load it up
// front: otherwise it would arrive partway through a test, at a time that
// differs by machine, and change the layout under the checks.
import 'dart:async';

import 'package:battleplan/core/design/arena/arena_font.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadArenaFont();
  await testMain();
}
