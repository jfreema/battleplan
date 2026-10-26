// Puts the web engine's fallback fonts in the web app, so browsers get them
// from our site instead of fonts.gstatic.com (ARCH §5.5): Roboto, which the
// engine loads at startup, Noto Color Emoji, and the Noto fonts for other
// scripts and symbols, which it loads only when text needs them. The list
// is the Flutter SDK's own (its engine's font_fallback_data.dart), so it
// follows a Flutter upgrade. web/flutter_bootstrap.js points the engine's
// fontFallbackBaseUrl at the folder. tools/build_hosting.sh runs this:
//
//   dart run tools/fetch_fallback_fonts.dart build/hosting/app/fonts/fallback
//
// Files already there are kept, so a second run downloads nothing.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Where the engine downloads fallback fonts from by default.
const _gstatic = 'https://fonts.gstatic.com/s/';

/// A font path under [_gstatic], as the engine names it:
/// `notocoloremoji/v32/<id>.0.woff2`.
final _fontPath = RegExp(r'[a-z0-9]+/v\d+/[A-Za-z0-9_.-]+\.woff2');

/// The font paths named in the engine's Dart [sources].
List<String> fontPathsIn(Iterable<String> sources) => {
  for (final s in sources)
    for (final m in _fontPath.allMatches(s)) m.group(0)!,
}.toList()..sort();

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln('Usage: dart run tools/fetch_fallback_fonts.dart <dir>');
    exit(64);
  }
  final out = Directory(args.single);
  final engine = Directory(
    '${await _flutterRoot()}/bin/cache/flutter_web_sdk/lib/_engine/engine',
  );
  final sources = [
    for (final name in [
      'font_fallback_data.dart',
      'canvaskit/fonts.dart',
      'skwasm/skwasm_impl/font_collection.dart',
    ])
      if (File('${engine.path}/$name').existsSync())
        File('${engine.path}/$name').readAsStringSync(),
  ];
  final paths = fontPathsIn(sources);
  // Roboto and the emoji are what the app needs most; without them the list
  // has moved and the engine would go back to Google.
  if (!paths.any((p) => p.startsWith('roboto/')) ||
      !paths.any((p) => p.startsWith('notocoloremoji/'))) {
    stderr.writeln(
      "Couldn't find the fallback fonts in ${engine.path}: check where this "
      'Flutter version keeps font_fallback_data.dart.',
    );
    exit(1);
  }
  final client = HttpClient();
  var fetched = 0;
  var bytes = 0;
  final failed = <String>[];
  final queue = [...paths];
  // A few at a time: about 725 small files, 22 MB in all.
  Future<void> worker() async {
    while (queue.isNotEmpty) {
      final path = queue.removeLast();
      final file = File('${out.path}/$path');
      if (file.existsSync() && file.lengthSync() > 0) continue;
      try {
        final data = await _download(client, '$_gstatic$path');
        file.parent.createSync(recursive: true);
        File('${file.path}.part')
          ..writeAsBytesSync(data)
          ..renameSync(file.path);
        fetched++;
        bytes += data.length;
      } on Object catch (e) {
        failed.add('$path: $e');
      }
    }
  }

  await Future.wait([for (var i = 0; i < 16; i++) worker()]);
  client.close();
  if (failed.isNotEmpty) {
    stderr.writeln('${failed.length} fallback fonts failed to download:');
    failed.take(10).forEach(stderr.writeln);
    exit(1);
  }
  stdout.writeln(
    '${paths.length} fallback fonts in ${out.path} '
    '($fetched downloaded, ${(bytes / 1e6).toStringAsFixed(1)} MB).',
  );
}

/// The bytes at [url], trying three times.
Future<List<int>> _download(HttpClient client, String url) async {
  for (var attempt = 1; ; attempt++) {
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}', uri: request.uri);
      }
      final data = <int>[];
      await response.forEach(data.addAll);
      return data;
    } on Object {
      if (attempt == 3) rethrow;
      await Future<void>.delayed(Duration(seconds: attempt));
    }
  }
}

/// The Flutter SDK running this build: FLUTTER_ROOT when set, or what
/// `flutter --version --machine` says.
Future<String> _flutterRoot() async {
  final env = Platform.environment['FLUTTER_ROOT'];
  if (env != null && env.isNotEmpty) return env;
  final result = await Process.run('flutter', [
    '--version',
    '--machine',
  ], runInShell: true);
  final info = jsonDecode(result.stdout as String) as Map<String, dynamic>;
  return info['flutterRoot'] as String;
}
