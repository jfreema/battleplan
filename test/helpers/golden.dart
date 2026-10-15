import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads real fonts into the test, so golden images are readable instead of
/// the test font's boxes: every font the app bundles (Inter, Material
/// Symbols and MaterialIcons, from the asset manifest the test build makes)
/// and Roboto from the Flutter SDK for anything that asks for it (ARCH §5.5).
///
/// Text rasterizes a little differently on each operating system, so
/// goldens made with real fonts only compare on the system that made them
/// (see [readableGoldensOs]). Fonts stay loaded for the rest of the test
/// file, which is why the readable goldens have a file of their own.
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manifest = jsonDecode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<Object?>;
  for (final entry in manifest.cast<Map<String, Object?>>()) {
    final loader = FontLoader(entry['family']! as String);
    for (final font in (entry['fonts']! as List).cast<Map<String, Object?>>()) {
      loader.addFont(rootBundle.load(font['asset']! as String));
    }
    await loader.load();
  }

  final fonts = Directory(
    '${_flutterRoot()}/bin/cache/artifacts/material_fonts',
  );
  const files = [
    'Roboto-Regular.ttf',
    'Roboto-Italic.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Light.ttf',
    'Roboto-Black.ttf',
  ];
  final roboto = FontLoader('Roboto');
  for (final f in files) {
    final bytes = File('${fonts.path}/$f').readAsBytesSync();
    roboto.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await roboto.load();
}

/// The SDK's root: `flutter test` sets FLUTTER_ROOT; otherwise it's found
/// from the test runner, `<root>/bin/cache/artifacts/engine/<os>/...`.
String _flutterRoot() {
  final env = Platform.environment['FLUTTER_ROOT'];
  if (env != null && env.isNotEmpty) return env;
  var dir = File(Platform.resolvedExecutable).parent;
  while (dir.path != dir.parent.path) {
    if (Directory('${dir.path}/bin/cache/artifacts/material_fonts')
        .existsSync()) {
      return dir.path;
    }
    dir = dir.parent;
  }
  throw StateError('Flutter SDK not found for the golden fonts');
}

/// The operating system the readable (real-font) goldens were made on.
/// They're skipped elsewhere.
const readableGoldensOs = 'macos';

/// Compares goldens allowing [tolerance] (0.01 is 1%) of pixels to differ,
/// so antialiasing that differs slightly between machines doesn't fail a
/// test while a moved or missing widget still does.
void useTolerantGoldens({double tolerance = 0.005}) {
  final current = goldenFileComparator;
  if (current is! LocalFileComparator) return;
  goldenFileComparator = _TolerantComparator(
    current.basedir.resolve('golden_test.dart'),
    tolerance,
  );
}

class _TolerantComparator extends LocalFileComparator {
  new(super.testFile, this.tolerance);

  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= tolerance) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
