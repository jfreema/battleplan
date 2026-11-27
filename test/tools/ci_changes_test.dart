// Which of CI's jobs a push needs (tools/ci_changes.sh, ARCH §9): the path
// rules, that the App job is never skipped for a file it reads, and how it
// picks the commit to compare a push with.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// What tools/ci_changes.sh says a push that changed [paths] needs: app (the
/// App job), functions (the Functions and security rules job), web (the Web
/// build and Hosting's deploy), rules and fdeploy (the rules' and Functions'
/// deploys), and deploy (any of the three deploys).
Future<Map<String, bool>> needs(List<String> paths) async =>
    answer(await script(['--classify'], paths));

/// What each of [paths] needs on its own, as the script's words for it:
/// app, functions, web, rules, fdeploy, all, or none.
Future<Map<String, Set<String>>> needsOfEach(List<String> paths) async => {
  for (final line in const LineSplitter().convert(
    await script(['--each'], paths),
  ))
    line.split('\t').last: line.split('\t').first.split(' ').toSet(),
};

/// Runs the script with [paths] on its input, one a line, and gives what it
/// printed.
Future<String> script(List<String> arguments, List<String> paths) async {
  final process = await Process.start('bash', [
    'tools/ci_changes.sh',
    ...arguments,
  ]);
  process.stdin.write(paths.join('\n'));
  await process.stdin.close();
  final out = await utf8.decodeStream(process.stdout);
  expect(await process.exitCode, 0);
  return out;
}

/// The script's name=true and name=false lines as a map.
Map<String, bool> answer(String lines) => {
  for (final line in const LineSplitter().convert(lines))
    line.split('=').first: line.split('=').last == 'true',
};

/// The answer with only [on] true.
Map<String, bool> only(Set<String> on) => {
  for (final name in ['app', 'functions', 'web', 'rules', 'fdeploy', 'deploy'])
    name: on.contains(name),
};

final Map<String, bool> everything = only({
  'app',
  'functions',
  'web',
  'rules',
  'fdeploy',
  'deploy',
});

/// A repository of its own with the script in it, and a stand-in for
/// GitHub's command line that answers from what a test says, so the script
/// runs as in CI's "What changed" job without GitHub.
class Scratch {
  new(this.root);

  final Directory root;

  static Future<Scratch> create() async {
    final scratch = Scratch(Directory.systemTemp.createTempSync('ci_changes'));
    await scratch._git(['init', '-q', '-b', 'main']);
    Directory('${scratch.root.path}/tools').createSync();
    File('tools/ci_changes.sh')
        .copySync('${scratch.root.path}/tools/ci_changes.sh');
    // `gh run list` for CI's runs and for Release to dev's: each answers
    // with a file's lines, or fails if the test asked for that.
    final gh = File('${scratch.root.path}/bin/gh')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'''
#!/usr/bin/env bash
case "$*" in
  *release-dev.yml*) name=release ;;
  *ci.yml*) name=ci ;;
  *) exit 2 ;;
esac
[ ! -e "$FAKE_GH/$name.fails" ] || exit 1
cat "$FAKE_GH/$name"
''');
    expect((await Process.run('chmod', ['+x', gh.path])).exitCode, 0);
    return scratch;
  }

  Future<String> _git(List<String> arguments) async {
    final result = await Process.run('git', [
      '-c',
      'user.name=Test',
      '-c',
      'user.email=test@example.com',
      '-c',
      'commit.gpgsign=false',
      ...arguments,
    ], workingDirectory: root.path);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    return (result.stdout as String).trim();
  }

  /// Commits [files] (path to contents) and gives the commit's ID.
  Future<String> commit(Map<String, String> files) async {
    for (final MapEntry(key: path, value: contents) in files.entries) {
      File('${root.path}/$path')
        ..createSync(recursive: true)
        ..writeAsStringSync(contents);
    }
    await _git(['add', '--', ...files.keys]);
    await _git(['commit', '-q', '-m', 'A change']);
    return await _git(['rev-parse', 'HEAD']);
  }

  /// Moves to [commit] on a new branch, [name].
  Future<void> branchFrom(String commit, String name) =>
      _git(['checkout', '-q', '-b', name, commit]);

  /// What the script answers for a run on [head]. [ciRuns] are the lines
  /// GitHub lists for the branch's CI runs ([run]), [releasedToDev] is when
  /// Release to dev last ran, and the two `fail` flags make GitHub not
  /// answer. Gives the needs and the sentence that says why.
  Future<({Map<String, bool> needs, String why})> push(
    String head, {
    String event = 'push',
    List<String> ciRuns = const [],
    String releasedToDev = '',
    bool ciListFails = false,
    bool releaseListFails = false,
  }) async {
    final github = Directory('${root.path}/github');
    if (github.existsSync()) github.deleteSync(recursive: true);
    github.createSync();
    File('${github.path}/ci').writeAsStringSync(ciRuns.join('\n'));
    File('${github.path}/release').writeAsStringSync(releasedToDev);
    if (ciListFails) File('${github.path}/ci.fails').createSync();
    if (releaseListFails) File('${github.path}/release.fails').createSync();
    final output = File('${github.path}/output')..createSync();
    final result = await Process.run(
      'bash',
      ['tools/ci_changes.sh'],
      workingDirectory: root.path,
      // Everything the script reads from GitHub, so that this test running
      // in CI doesn't pass its own run's on.
      environment: {
        'PATH': '${root.path}/bin:${Platform.environment['PATH']}',
        'FAKE_GH': github.path,
        'GITHUB_EVENT_NAME': event,
        'GITHUB_REF_NAME': 'main',
        'GITHUB_REPOSITORY': 'someone/battleplan',
        'GITHUB_SHA': head,
        'GITHUB_RUN_ID': thisRun,
        'GITHUB_OUTPUT': output.path,
        'GITHUB_STEP_SUMMARY': '',
      },
    );
    expect(result.exitCode, 0, reason: '${result.stderr}');
    // The report's third line says what was compared, or why nothing was.
    final said = const LineSplitter().convert(result.stdout as String);
    return (needs: answer(output.readAsStringSync()), why: said[2]);
  }
}

/// The run the script is called from, as [Scratch.push] names it.
const thisRun = '999';

/// One line of GitHub's list of CI runs: the run's [id], its [commit], how
/// it ended, and the hour its latest attempt started.
String run(String id, String commit, String ended, {required int hour}) =>
    '$id $commit $ended ${at(hour)}';

/// A time on one day, as GitHub writes it.
String at(int hour) => '2026-11-01T${hour.toString().padLeft(2, '0')}:00:00Z';

void main() {
  test('docs, store pictures and top-level notes need no job', () async {
    expect(
      await needs([
        'docs/SPEC.md',
        'docs/ROADMAP.md',
        'store/app-store/iphone-6.9/01-chat.png',
        'README.md',
        'TODO.md',
        'AGENTS.md',
        '.vscode/launch.json',
        'website/README.md',
      ]),
      only({}),
    );
    expect(await needs([]), only({}));
  });

  test('the website needs only the Hosting build and its deploy', () async {
    expect(
      await needs(['website/index.html', 'website/site.css', 'docs/SPEC.md']),
      only({'web', 'deploy'}),
    );
    expect(
      await needs(['hosting/well-known/prod/assetlinks.json']),
      only({'web', 'deploy'}),
    );
  });

  test(
    'the app needs its tests and the Hosting build, not the server',
    () async {
      for (final path in [
        'lib/features/chat/presentation/chat_screen.dart',
        'lib/l10n/app_en.arb',
        'assets/fonts/battleplan_sans/BattleplanSans-Regular.ttf',
        'pubspec.yaml',
        'pubspec.lock',
      ]) {
        expect(
          await needs([path]),
          only({'app', 'web', 'deploy'}),
          reason: path,
        );
      }
    },
  );

  test(
    "the app's tests and the phone projects need only the App job",
    () async {
      expect(
        await needs([
          'test/chat_test.dart',
          'test/goldens/readable/chat_black.png',
          'integration_test/e2e_test.dart',
          'dart_test.yaml',
          'analysis_options.yaml',
          'ios/Runner/Info.plist',
          'ios/Runner.xcodeproj/project.pbxproj',
          'android/app/build.gradle.kts',
          'android/app/src/main/AndroidManifest.xml',
        ]),
        only({'app'}),
      );
    },
  );

  test('the server needs its tests and its deploy, not the app', () async {
    expect(
      await needs(['functions/src/chat/service.ts', 'functions/package.json']),
      only({'functions', 'fdeploy', 'deploy'}),
    );
    // Its tests and the demo seed aren't deployed.
    expect(
      await needs(['functions/test/unit/polls.test.ts', 'tools/seed/demo.ts']),
      only({'functions'}),
    );
  });

  test('the rules need the Functions job and the rules deploy', () async {
    for (final path in [
      'firestore.rules',
      'storage.rules',
      'firestore.indexes.json',
    ]) {
      expect(
        await needs([path]),
        only({'functions', 'rules', 'deploy'}),
        reason: path,
      );
    }
  });

  test('what the app and the server both read needs both', () async {
    // tools/gen_constants.dart, which the App job checks, writes it.
    expect(
      await needs(['functions/src/shared/constants.ts']),
      only({'app', 'functions', 'fdeploy', 'deploy'}),
    );
    // schedule_domain_test.dart reads the server's recurrence vectors.
    expect(
      await needs(['functions/test/unit/fixtures/series_vectors.json']),
      only({'app', 'functions'}),
    );
    // The server's palette.test.ts reads the app's chat colors.
    expect(
      await needs(['lib/features/groups/domain/chat_colors.dart']),
      only({'app', 'functions', 'web', 'deploy'}),
    );
    // The server's push_sw.test.ts reads the web app's push worker.
    expect(
      await needs(['web/firebase-messaging-sw.js']),
      only({'functions', 'web', 'deploy'}),
    );
  });

  test("the web app's page and icons need only the Hosting build", () async {
    expect(
      await needs([
        'web/index.html',
        'web/manifest.json',
        'web/icons/Icon-192.png',
        'web/flutter_bootstrap.js',
      ]),
      only({'web', 'deploy'}),
    );
  });

  // The releases and the Android build are started by hand, and no job of
  // CI's reads their workflows or checks them, so a fix to one doesn't wait
  // for the tests.
  test("the hand-started workflows need no job, and CI's uses none", () async {
    expect(
      await needs([
        '.github/workflows/release.yml',
        '.github/workflows/release-ios.yml',
        '.github/workflows/android.yml',
      ]),
      only({}),
    );
    // A workflow or an action of the repo's own that ci.yml ran would be a
    // part of CI, and need a rule of its own.
    final ci = File('.github/workflows/ci.yml').readAsStringSync();
    expect(ci, isNot(contains(RegExp(r'uses:\s*\./'))));
  });

  test('anything else needs everything', () async {
    for (final path in [
      'shared/constants.json',
      'shared/notes.md',
      'tools/build_hosting.sh',
      'tools/ci_changes.sh',
      'firebase.json',
      '.firebaserc',
      '.github/workflows/ci.yml',
      '.github/actionlint.yaml',
      '.gitignore',
      'a_new_folder/file.txt',
      'a_new_file',
    ]) {
      expect(await needs([path]), everything, reason: path);
    }
  });

  test('a push needs what any of its files needs', () async {
    expect(
      await needs([
        'docs/SPEC.md',
        'website/index.html',
        'functions/src/chat/service.ts',
      ]),
      only({'functions', 'web', 'fdeploy', 'deploy'}),
    );
    expect(
      await needs(['test/chat_test.dart', 'firestore.rules']),
      only({'app', 'functions', 'rules', 'deploy'}),
    );
  });

  // The App job formats and analyzes every Dart file in the repo, wherever
  // it is.
  test('every Dart file needs the App job', () async {
    final listed = await Process.run('git', ['ls-files', '*.dart']);
    expect(listed.exitCode, 0, reason: '${listed.stderr}');
    final files = const LineSplitter().convert(listed.stdout as String);
    expect(files, isNotEmpty);
    final each = await needsOfEach(files);
    expect(each.keys, containsAll(files));
    for (final MapEntry(key: file, value: its) in each.entries) {
      expect(its.contains('app') || its.contains('all'), isTrue, reason: file);
    }
  });

  // A rule may leave the App job off a path only if nothing it runs reads
  // it. This finds the files and folders the app's tests and the Dart tools
  // open by name: every quoted path with a slash in it that exists in the
  // repo, and whatever File(...) or Directory(...) is given in quotes. A
  // path put together at run time isn't found, so a test that reads a new
  // place still needs its rule checked by hand.
  test('every file the tests and tools name needs the App job', () async {
    final quotedPath = RegExp(r'''['"]([\w.\-]+(?:/[\w.\- ]+)+)['"]''');
    final opened = RegExp(r'''\b(?:File|Directory)\(\s*['"]([\w.\-/ ]+)['"]''');
    final named = <String>{};
    for (final dir in ['test', 'integration_test', 'tools']) {
      for (final file in Directory(dir).listSync(recursive: dir != 'tools')) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        // This file names paths as examples; the two it reads, the script
        // and CI's workflow, need everything.
        if (file.path.endsWith('ci_changes_test.dart')) continue;
        final source = file.readAsStringSync();
        for (final pattern in [quotedPath, opened]) {
          named.addAll(pattern.allMatches(source).map((m) => m[1]!));
        }
      }
    }
    final checked = <String>[];
    for (final path in named) {
      if (path.contains('..')) continue;
      if (File(path).existsSync()) {
        checked.add(path);
      } else if (Directory(path).existsSync()) {
        // A folder is read through the files in it.
        checked.add('${path.replaceAll(RegExp(r'/+$'), '')}/a_file');
      }
    }
    // What the tests read today, so the search itself is known to work.
    expect(
      checked,
      containsAll([
        'shared/constants.json',
        'ios/Runner/Info.plist',
        'functions/test/unit/fixtures/series_vectors.json',
        'lib/a_file',
      ]),
    );
    final each = await needsOfEach(checked);
    for (final MapEntry(key: path, value: its) in each.entries) {
      expect(its.contains('app') || its.contains('all'), isTrue, reason: path);
    }
  });

  // In CI the script asks GitHub which run passed last and compares the push
  // with that run's commit. Here it runs in a repository of its own, with
  // GitHub's answers written by each test.
  group('in CI, a push', () {
    late Scratch scratch;
    // On main, in order: `first`, then a server change, then that change
    // taken back along with a docs edit, then a website edit, then another
    // docs edit. `aside` is a commit on another branch.
    late String first;
    late String serverChange;
    late String takenBack;
    late String websiteEdit;
    late String docsEdit;
    late String aside;

    setUpAll(() async {
      scratch = await Scratch.create();
      first = await scratch.commit({
        'lib/main.dart': 'one',
        'functions/src/index.ts': 'one',
        'website/index.html': 'one',
        'docs/SPEC.md': 'one',
      });
      serverChange = await scratch.commit({'functions/src/index.ts': 'two'});
      takenBack = await scratch.commit({
        'functions/src/index.ts': 'one',
        'docs/SPEC.md': 'two',
      });
      websiteEdit = await scratch.commit({'website/index.html': 'two'});
      docsEdit = await scratch.commit({'docs/SPEC.md': 'three'});
      await scratch.branchFrom(first, 'aside');
      aside = await scratch.commit({'lib/main.dart': 'aside'});
    });

    tearDownAll(() => scratch.root.deleteSync(recursive: true));

    test('needs what changed since the last commit CI passed on', () async {
      final result = await scratch.push(
        websiteEdit,
        ciRuns: [
          run('3', takenBack, 'success', hour: 3),
          run('2', serverChange, 'failure', hour: 2),
          run('1', first, 'success', hour: 1),
        ],
      );
      expect(result.needs, only({'web', 'deploy'}));
      expect(result.why, contains('1 file(s), in website'));
      expect(result.why, contains(takenBack.substring(0, 7)));
    });

    test('needs nothing when only the docs changed, or nothing did', () async {
      final runs = [run('4', websiteEdit, 'success', hour: 4)];
      final docsOnly = await scratch.push(docsEdit, ciRuns: runs);
      expect(docsOnly.needs, only({}));
      expect(docsOnly.why, contains('1 file(s), in docs'));

      // The very commit CI last passed on.
      final same = await scratch.push(websiteEdit, ciRuns: runs);
      expect(same.needs, only({}));
      expect(same.why, startsWith('Nothing'));
    });

    test('keeps the pushes whose runs failed in the comparison', () async {
      final result = await scratch.push(
        websiteEdit,
        ciRuns: [
          run('3', takenBack, 'cancelled', hour: 3),
          run('2', serverChange, 'failure', hour: 2),
          run('1', first, 'success', hour: 1),
        ],
      );
      // The server change is back as it was at `first`, so the files don't
      // differ. But the failed run may have deployed it, so it still counts.
      expect(result.needs, only({'functions', 'web', 'fdeploy', 'deploy'}));
      expect(result.why, contains('3 file(s), in docs, functions, website'));
    });

    test(
      'is compared with the run that started last, not the newest',
      () async {
        // The first commit's run was started again after the later one's, and
        // passed: dev holds the first commit, so that's the one to compare.
        final result = await scratch.push(
          websiteEdit,
          ciRuns: [
            run('3', serverChange, 'success', hour: 2),
            run('1', first, 'success', hour: 3),
          ],
        );
        expect(result.needs, only({'functions', 'web', 'fdeploy', 'deploy'}));
        expect(result.why, contains(first.substring(0, 7)));
      },
    );

    test("doesn't count its own run's earlier attempt", () async {
      final result = await scratch.push(
        websiteEdit,
        ciRuns: [
          run(thisRun, websiteEdit, 'success', hour: 4),
          run('3', takenBack, 'success', hour: 3),
        ],
      );
      expect(result.needs, only({'web', 'deploy'}));
    });

    test('lets a run that is still going on a commit in between be', () async {
      final result = await scratch.push(
        websiteEdit,
        ciRuns: [
          run('3', takenBack, 'none', hour: 3),
          run('1', first, 'success', hour: 1),
        ],
      );
      expect(result.needs, only({'functions', 'web', 'fdeploy', 'deploy'}));
    });

    test('needs everything when it is not a push', () async {
      for (final event in ['pull_request', 'workflow_dispatch']) {
        final result = await scratch.push(
          websiteEdit,
          event: event,
          ciRuns: [run('3', takenBack, 'success', hour: 3)],
        );
        expect(result.needs, everything, reason: event);
        expect(result.why, contains("wasn't started by a push"));
      }
    });

    test(
      'needs everything when CI has not passed, or GitHub does not say',
      () async {
        final neverPassed = await scratch.push(
          websiteEdit,
          ciRuns: [run('2', serverChange, 'failure', hour: 2)],
        );
        expect(neverPassed.needs, everything);
        expect(neverPassed.why, contains("hasn't passed"));

        final noRuns = await scratch.push(websiteEdit);
        expect(noRuns.needs, everything);

        final noAnswer = await scratch.push(websiteEdit, ciListFails: true);
        expect(noAnswer.needs, everything);
        expect(noAnswer.why, contains("didn't list"));

        final notUnderstood = await scratch.push(
          websiteEdit,
          ciRuns: ['3 $takenBack success yesterday'],
        );
        expect(notUnderstood.needs, everything);
        expect(notUnderstood.why, contains("wasn't in the form expected"));
      },
    );

    test(
      'needs everything when the last passing commit is not in its history',
      () async {
        final result = await scratch.push(
          websiteEdit,
          ciRuns: [
            run('5', aside, 'success', hour: 5),
            run('1', first, 'success', hour: 1),
          ],
        );
        expect(result.needs, everything);
        expect(result.why, contains("isn't in this push's history"));

        // A commit GitHub names that the clone doesn't have at all.
        final unknown = await scratch.push(
          websiteEdit,
          ciRuns: [run('5', 'a' * 40, 'success', hour: 5)],
        );
        expect(unknown.needs, everything);
      },
    );

    test('needs everything after a run on a commit outside it', () async {
      // An older commit's run started again after the last passing run and
      // failed, perhaps after deploying some of the older commit.
      final older = await scratch.push(
        websiteEdit,
        ciRuns: [
          run('3', takenBack, 'success', hour: 3),
          run('1', first, 'failure', hour: 4),
        ],
      );
      expect(older.needs, everything);
      expect(older.why, contains('a CI run on another commit'));
      expect(older.why, contains(first.substring(0, 7)));

      // A commit that is no longer on the branch.
      final rewritten = await scratch.push(
        websiteEdit,
        ciRuns: [
          run('5', aside, 'cancelled', hour: 4),
          run('3', takenBack, 'success', hour: 3),
        ],
      );
      expect(rewritten.needs, everything);

      // The same runs before the last passing run started change nothing.
      final before = await scratch.push(
        websiteEdit,
        ciRuns: [
          run('5', aside, 'cancelled', hour: 2),
          run('3', takenBack, 'success', hour: 3),
          run('1', first, 'failure', hour: 1),
        ],
      );
      expect(before.needs, only({'web', 'deploy'}));
    });

    test('needs everything after a Release to dev', () async {
      final runs = [run('3', takenBack, 'success', hour: 3)];
      final after = await scratch.push(
        websiteEdit,
        ciRuns: runs,
        releasedToDev: at(4),
      );
      expect(after.needs, everything);
      expect(after.why, contains('Release to dev ran'));

      final before = await scratch.push(
        websiteEdit,
        ciRuns: runs,
        releasedToDev: at(2),
      );
      expect(before.needs, only({'web', 'deploy'}));

      final noAnswer = await scratch.push(
        websiteEdit,
        ciRuns: runs,
        releaseListFails: true,
      );
      expect(noAnswer.needs, everything);
    });
  });
}
