// Firebase's scripts, preloaded in the web app's index.html (ARCH §5.6):
// which files, read from firebase_core_web and the web plugins.
import 'package:flutter_test/flutter_test.dart';

import '../../tools/preload_firebase.dart' as preload;

void main() {
  const loader = r"""
      if (service.name == firestoreServiceName) {
        return injectSrcScript(
          'https://www.gstatic.com/firebasejs/$version/firebase-firestore-pipelines.js',
          'firebase_$firestoreServiceName',
        );
      }
      return injectSrcScript(
        'https://www.gstatic.com/firebasejs/$version/firebase-${service.name}.js',
        'firebase_${service.override ?? service.name}',
      );""";

  test("reads the SDK version and each plugin's service", () {
    expect(
      preload.sdkVersionIn(
        "const String supportedFirebaseJsSdkVersion = '12.19.0';",
      ),
      '12.19.0',
    );
    expect(preload.sdkVersionIn('const x = 1;'), isNull);
    expect(
      preload.servicesIn([
        "FirebaseCoreWeb.registerService('auth', ensurePluginInitialized: f);",
        "FirebaseCoreWeb.registerService(\n  'app-check',\n  productNameOverride: 'app_check',\n);",
        "FirebaseCoreWeb.registerService('firestore');",
        "FirebaseCoreWeb.registerService('auth');",
      ]),
      {'auth', 'app-check', 'firestore'},
    );
  });

  test(
    'preloads firebase-app.js first, and Firestore as the loader names it',
    () {
      expect(
        preload.scriptUrls(loader, '12.19.0', {'storage', 'firestore', 'auth'}),
        [
          'https://www.gstatic.com/firebasejs/12.19.0/firebase-app.js',
          'https://www.gstatic.com/firebasejs/12.19.0/firebase-auth.js',
          'https://www.gstatic.com/firebasejs/12.19.0/firebase-firestore-pipelines.js',
          'https://www.gstatic.com/firebasejs/12.19.0/firebase-storage.js',
        ],
      );
      final plain = loader.replaceAll('-pipelines', '');
      expect(
        preload.scriptUrls(plain, '12.19.0', {'firestore'})!.last,
        'https://www.gstatic.com/firebasejs/12.19.0/firebase-firestore.js',
      );
      // A loader that names its scripts another way gets no preloads.
      expect(preload.scriptUrls('import(src);', '12.19.0', {'auth'}), isNull);
    },
  );

  test('adds the links at the end of the head', () {
    final html = preload.withPreloads(
      '<html>\n<head>\n  <title>Battleplan</title>\n</head>\n<body></body>\n</html>',
      ['https://www.gstatic.com/firebasejs/12.19.0/firebase-app.js'],
    );
    expect(
      html,
      contains(
        '  <link rel="modulepreload" '
        'href="https://www.gstatic.com/firebasejs/12.19.0/firebase-app.js">\n'
        '</head>',
      ),
    );
    expect(html.indexOf('<title>'), lessThan(html.indexOf('modulepreload')));
    expect(
      () => preload.withPreloads('<html></html>', const []),
      throwsFormatException,
    );
  });
}
