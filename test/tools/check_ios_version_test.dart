// Release iOS's check that Apple still takes builds of the app's version
// (tools/check_ios_version.py, DEVELOPMENT.md "iPhone and iPad builds"),
// against a stand-in for App Store Connect on this machine, with a key made
// for the test. It needs python3 and openssl, which CI's machines and a Mac
// have.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const appId = '6823884728';

/// A stand-in for App Store Connect's app versions endpoint.
class StandIn {
  late final HttpServer _server;

  /// The pages it answers with, in order; the last one's links name none.
  List<List<Map<String, String>>> pages = [];

  /// When set, every request gets this status and a short error body.
  int? failWith;

  final List<HttpRequest> requests = [];

  String get base => 'http://127.0.0.1:${_server.port}';

  /// Listens on a free port on this machine.
  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_answer);
  }

  Future<void> _answer(HttpRequest request) async {
    requests.add(request);
    final response = request.response..headers.contentType = ContentType.json;
    final fail = failWith;
    if (fail != null) {
      response
        ..statusCode = fail
        ..write('{"errors":[{"status":"$fail","code":"FORBIDDEN_ERROR"}]}');
    } else if (request.uri.path != '/v1/apps/$appId/appStoreVersions' ||
        request.uri.queryParameters['filter[platform]'] != 'IOS') {
      response
        ..statusCode = 404
        ..write('{"errors":[]}');
    } else {
      final page = int.parse(request.uri.queryParameters['page'] ?? '0');
      final more = page + 1 < pages.length;
      response.write(
        jsonEncode({
          'data': [
            for (final v in pages[page])
              {
                'type': 'appStoreVersions',
                'id': 'v-${v['versionString']}',
                'attributes': v,
              },
          ],
          'links': {
            'self': request.uri.toString(),
            if (more)
              'next':
                  '$base/v1/apps/$appId/appStoreVersions'
                  '?filter%5Bplatform%5D=IOS&page=${page + 1}',
          },
        }),
      );
    }
    await response.close();
  }

  Future<void> stop() => _server.close(force: true);
}

Map<String, String> version(String v, String state) => {
  'versionString': v,
  'appVersionState': state,
  'platform': 'IOS',
};

void main() {
  final tools = ['python3', 'openssl'].every((tool) {
    try {
      return Process.runSync(tool, ['--version']).exitCode == 0 ||
          Process.runSync(tool, ['version']).exitCode == 0;
    } on ProcessException {
      return false;
    }
  });

  group('the version check before the iPhone build', () {
    late Directory dir;
    final apple = StandIn();
    late String keyPath;

    setUpAll(() async {
      dir = await Directory.systemTemp.createTemp('check_ios_version');
      // A P-256 key in the .p8 form App Store Connect hands out (PKCS#8).
      final pem = '${dir.path}/key.pem';
      keyPath = '${dir.path}/AuthKey_TEST.p8';
      for (final args in [
        ['ecparam', '-name', 'prime256v1', '-genkey', '-noout', '-out', pem],
        ['pkcs8', '-topk8', '-nocrypt', '-in', pem, '-out', keyPath],
      ]) {
        final made = await Process.run('openssl', args);
        expect(made.exitCode, 0, reason: '${made.stderr}');
      }
      await apple.start();
    });

    tearDownAll(() async {
      await apple.stop();
      await dir.delete(recursive: true);
    });

    setUp(() {
      apple
        ..pages = []
        ..failWith = null
        ..requests.clear();
    });

    /// Runs the check with the app at [appVersion], against the stand-in.
    Future<ProcessResult> check(String appVersion, {bool key = true}) {
      final pubspec = File('${dir.path}/pubspec.yaml')
        ..writeAsStringSync(
          'name: battleplan\n# version: 0.0.1\nversion: $appVersion\n',
        );
      return Process.run(
        'python3',
        ['tools/check_ios_version.py'],
        environment: {
          'ASC_API_BASE': apple.base,
          'PUBSPEC': pubspec.path,
          'ASC_KEY_PATH': key ? keyPath : '',
          'ASC_KEY_ID': 'TESTKEY123',
          'ASC_ISSUER_ID': 'test-issuer',
        },
      );
    }

    test('passes a version higher than every approved one', () async {
      apple.pages = [
        [
          version('1.4.5', 'READY_FOR_DISTRIBUTION'),
          version('1.4.6', 'PREPARE_FOR_SUBMISSION'),
        ],
      ];
      final run = await check('1.4.6+1');
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      expect(run.stdout, contains('Apple still takes builds of 1.4.6.'));
      expect(run.stdout, isNot(contains('::')));
    });

    test('passes while the version waits for review or is in it', () async {
      for (final state in [
        'WAITING_FOR_REVIEW',
        'IN_REVIEW',
        'REJECTED',
        'DEVELOPER_REJECTED',
        'SOME_STATE_APPLE_ADDS_LATER',
      ]) {
        apple.pages = [
          [version('1.4.6', state)],
        ];
        final run = await check('1.4.6+1');
        expect(run.exitCode, 0, reason: state);
      }
    });

    test('stops at a version Apple has approved, and names the next', () async {
      for (final state in [
        'ACCEPTED',
        'PENDING_DEVELOPER_RELEASE',
        'READY_FOR_DISTRIBUTION',
        'REPLACED_WITH_NEW_VERSION',
      ]) {
        apple.pages = [
          [
            version('1.4.5', 'REPLACED_WITH_NEW_VERSION'),
            version('1.4.6', state),
          ],
        ];
        final run = await check('1.4.6+1');
        expect(run.exitCode, 1, reason: state);
        expect(
          run.stdout,
          contains(
            '::error::Apple has already approved 1.4.6, so App Store Connect '
            'takes no more 1.4.6 builds. Set version in pubspec.yaml to 1.4.7',
          ),
        );
      }
    });

    test('reads the older state field too', () async {
      apple.pages = [
        [
          {'versionString': '1.4.6', 'appStoreState': 'READY_FOR_SALE'},
        ],
      ];
      expect((await check('1.4.6+1')).exitCode, 1);
    });

    test('stops at a version lower than an approved one', () async {
      apple.pages = [
        [version('1.4.10', 'READY_FOR_DISTRIBUTION')],
      ];
      // Compared as numbers: 1.4.9 is lower than 1.4.10.
      final run = await check('1.4.9+1');
      expect(run.exitCode, 1);
      expect(
        run.stdout,
        contains('The app is 1.4.9, and Apple has already approved 1.4.10'),
      );
      expect(run.stdout, contains('to 1.4.11'));
    });

    test('reads every page', () async {
      apple.pages = [
        [version('1.4.4', 'REPLACED_WITH_NEW_VERSION')],
        [version('1.4.6', 'READY_FOR_DISTRIBUTION')],
      ];
      expect((await check('1.4.6+1')).exitCode, 1);
      expect(apple.requests, hasLength(2));
    });

    test('signs in with an App Store Connect token from the key', () async {
      apple.pages = [<Map<String, String>>[]];
      expect((await check('1.4.6+1')).exitCode, 0);
      final auth = apple.requests.single.headers.value('authorization')!;
      expect(auth, startsWith('Bearer '));
      final parts = auth.substring(7).split('.');
      expect(parts, hasLength(3));
      Map<String, dynamic> part(String s) =>
          jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(s))))
              as Map<String, dynamic>;
      expect(part(parts[0]), {
        'alg': 'ES256',
        'kid': 'TESTKEY123',
        'typ': 'JWT',
      });
      expect(part(parts[1]), containsPair('aud', 'appstoreconnect-v1'));
      expect(part(parts[1]), containsPair('iss', 'test-issuer'));
      // r and s, 32 bytes each.
      expect(base64Url.decode(base64Url.normalize(parts[2])), hasLength(64));
    });

    test("warns and passes when Apple can't be asked", () async {
      apple.failWith = 403;
      final run = await check('1.4.6+1');
      expect(run.exitCode, 0);
      expect(
        run.stdout,
        contains('::warning::App Store Connect answered 403 when asked'),
      );
    });

    test('warns and passes without a key', () async {
      final run = await check('1.4.6+1', key: false);
      expect(run.exitCode, 0);
      expect(run.stdout, contains('::warning::No App Store Connect key here'));
      expect(apple.requests, isEmpty);
    });
  }, skip: tools ? false : 'needs python3 and openssl');
}
