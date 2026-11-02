// Preloads Firebase's own scripts in the built web app's index.html (ARCH
// §5.6). firebase_core_web loads them from www.gstatic.com only once the
// app is running, firebase-app.js first and then one for each plugin, and
// the first frame waits for them (bootstrap awaits Firebase.initializeApp),
// so on a first visit about 320 KB came only after the app itself. A
// modulepreload link for each lets the browser fetch and parse them
// alongside the app, and the app's own imports find them ready: on a phone
// (Fast 4G, a CPU four times slower) the first frame came 0.5 s sooner. The
// version and file names are firebase_core_web's own and the plugins are
// the ones the app resolves, so it follows an upgrade.
// tools/build_hosting.sh runs this:
//
//   dart run tools/preload_firebase.dart build/hosting/app/index.html
import 'dart:convert';
import 'dart:io';

/// The Firebase JS SDK version firebase_core_web loads, from its
/// `firebase_sdk_version.dart` [source].
String? sdkVersionIn(String source) =>
    RegExp(r"supportedFirebaseJsSdkVersion\s*=\s*'([0-9.]+)'")
        .firstMatch(source)
        ?.group(1);

/// The services web plugins register with firebase_core_web in [sources]
/// (`FirebaseCoreWeb.registerService('auth', ...)`), each a script it loads.
Set<String> servicesIn(Iterable<String> sources) => {
  for (final s in sources)
    for (final m in RegExp(
      r"FirebaseCoreWeb\.registerService\(\s*'([a-z-]+)'",
    ).allMatches(s))
      m.group(1)!,
};

/// The scripts firebase_core_web's [loader] (`firebase_core_web.dart`)
/// loads for [services]: `firebase-app.js`, then `firebase-<service>.js`
/// each, except Firestore's own Pipelines build where it names that. Null
/// when it no longer names them that way, so a preload never fetches a file
/// the app doesn't use.
List<String>? scriptUrls(String loader, String version, Set<String> services) {
  if (!loader.contains(r'firebasejs/$version/firebase-${service.name}.js')) {
    return null;
  }
  const pipelines = 'firestore-pipelines';
  final pipelined = loader.contains('firebase-$pipelines.js');
  return [
    for (final name in [
      'app',
      for (final s in services.toList()..sort())
        if (s == 'firestore' && pipelined) pipelines else s,
    ])
      'https://www.gstatic.com/firebasejs/$version/firebase-$name.js',
  ];
}

/// [html] with a modulepreload link for each of [urls] at the end of its
/// head.
String withPreloads(String html, List<String> urls) {
  final at = html.indexOf('</head>');
  if (at < 0) throw const FormatException('index.html has no </head>');
  final links = StringBuffer(
    "  <!-- Firebase's scripts, which the app loads once it runs and its\n"
    '       first frame waits for, fetched alongside the app\n'
    '       (tools/preload_firebase.dart). -->\n',
  );
  for (final url in urls) {
    links.writeln('  <link rel="modulepreload" href="$url">');
  }
  return '${html.substring(0, at)}$links${html.substring(at)}';
}

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('Usage: dart run tools/preload_firebase.dart <index.html>');
    exit(64);
  }
  // The web plugins the app resolves, from the package config `flutter
  // build` leaves.
  final config = File('.dart_tool/package_config.json').absolute;
  final packages =
      (jsonDecode(config.readAsStringSync())
              as Map<String, dynamic>)['packages']
          as List<dynamic>;
  final web = {
    for (final p in packages.cast<Map<String, dynamic>>())
      if ((p['name'] as String).endsWith('_web'))
        p['name'] as String: Directory.fromUri(
          config.uri
              .resolve('${p['rootUri']}/')
              .resolve(p['packageUri'] as String),
        ),
  };
  final core = web['firebase_core_web'];
  final version = core == null
      ? null
      : sdkVersionIn(
          File('${core.path}/src/firebase_sdk_version.dart').readAsStringSync(),
        );
  final services = servicesIn([
    for (final dir in web.values)
      for (final f in dir.listSync(recursive: true))
        if (f is File && f.path.endsWith('.dart')) f.readAsStringSync(),
  ]);
  final urls = version == null || services.isEmpty
      ? null
      : scriptUrls(
          File('${core!.path}/src/firebase_core_web.dart').readAsStringSync(),
          version,
          services,
        );
  if (urls == null) {
    stderr.writeln(
      "Couldn't tell which scripts firebase_core_web loads (${core?.path}): "
      'check firebase_sdk_version.dart and firebase_core_web.dart.',
    );
    exit(1);
  }
  final index = File(args.single);
  index.writeAsStringSync(withPreloads(index.readAsStringSync(), urls));
  stdout.writeln(
    'Preloading ${urls.length} Firebase $version scripts in ${index.path}.',
  );
}
