// Runs around every test file. Arena's font is an asset the app loads when
// Arena is used (loadArenaFont); tests skip that and draw Arena in the test
// font, as they did when it was bundled, since the font arriving partway
// through a test moves the layout under its checks, differently by machine.
// Goldens load it themselves (loadAppFonts).
import 'dart:async';

import 'package:battleplan/core/design/arena/arena_font.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  debugSkipArenaFont = true;
  await testMain();
}
