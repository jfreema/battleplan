// Every "Couldn't load" has Try again (SPEC §7.5, #42): each screen whose
// load fails shows LoadError, the full form on a page and the inline form
// in a section, and Try again really loads again (the read is made again
// and the content shows). No bare "Couldn't load this" text is left in
// lib/, and the Retry of a failed message and of sign-in stay as they are.
import 'dart:io';
import 'dart:typed_data';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/load_error.dart';
import 'package:battleplan/features/admin/application/providers.dart';
import 'package:battleplan/features/admin/domain/admin.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/chat/domain/message.dart';
import 'package:battleplan/features/documents/application/providers.dart';
import 'package:battleplan/features/documents/domain/document.dart';
import 'package:battleplan/features/dues/application/providers.dart';
import 'package:battleplan/features/groups/application/providers.dart'
    hide group;
import 'package:battleplan/features/groups/domain/invite.dart';
import 'package:battleplan/features/groups/domain/media.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/players/application/providers.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/domain/player_details.dart';
import 'package:battleplan/features/safety/application/providers.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

const _a = GroupId('a');

/// Something whose reads fail while [failing], as offline; the test turns
/// it off just before Try again. How many reads were made is in [reads].
abstract class _Fails {
  bool failing = true;
  int reads = 0;
}

/// A read that fails while [failing] and answers [value] after.
class _Flaky<T> extends _Fails {
  new(this.value);

  final T value;

  Stream<T> stream() {
    reads++;
    return failing ? Stream.error(const _Offline()) : Stream.value(value);
  }

  Future<T> future() async {
    reads++;
    if (failing) throw const _Offline();
    return value;
  }
}

/// The fake admin repository, as a [_Fails].
class _AdminFails extends _Fails {
  new(this.admin) {
    admin.readFailures = 1 << 30;
  }

  final FakeAdminRepository admin;

  @override
  int get reads => admin.reads;

  @override
  set failing(bool value) {
    super.failing = value;
    if (!value) admin.readFailures = 0;
  }
}

class _Offline implements Exception {
  const new();
}

/// Team photos whose first page fails while [flaky] is failing.
class _FlakyMessages extends FakeMessageRepository {
  final flaky = _Flaky<void>(null);

  @override
  Future<MessagePage> photoMessages(
    GroupId groupId, {
    PageCursor? before,
    int limit = 30,
  }) async {
    await flaky.future();
    return await super.photoMessages(groupId, before: before, limit: limit);
  }
}

/// A player's RSVP history whose events fail while [flaky] is failing.
class _FlakyRange extends FakeEventRepository {
  new() : super();

  final flaky = _Flaky<void>(null);

  @override
  Future<List<Event>> eventsBetween(
    GroupId groupId,
    DateTime from,
    DateTime until,
  ) async {
    await flaky.future();
    return await super.eventsBetween(groupId, from, until);
  }
}

void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );
  const boss = AuthUser(
    uid: 'boss',
    email: 'boss@example.com',
    displayName: 'Bea Boss',
    emailVerified: true,
    isSuperAdmin: true,
  );
  const noah = Player(
    id: PlayerId('p1'),
    groupId: _a,
    displayName: 'Noah Diaz',
  );

  /// Riverpod tries a failed read again on its own, ten times over about
  /// 40 seconds, with the placeholder rows up meanwhile; LoadError shows
  /// once it stops.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(seconds: 7));
    }
    await tester.pumpAndSettle();
  }

  Future<void> open(
    WidgetTester tester,
    String path, {
    AuthUser user = coach,
    List<Override> overrides = const [],
    FakeMessageRepository? messageRepo,
    FakeEventRepository? eventRepo,
    FakeAdminRepository? admin,
    FakePlayerRepository? playerRepo,
    Size size = const Size(400, 1200),
  }) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: user),
      prefs: FakeLocalPrefs()..pushPrePromptShown = true,
      groups: {'a': testGroup('a', 'Thunder')},
      memberships: [testMembership('a', user.uid, role: MemberRole.owner)],
      messageRepo: messageRepo,
      eventRepo: eventRepo,
      admin: admin,
      playerRepo: playerRepo,
      overrides: overrides,
      size: size,
    );
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
    await settle(tester);
  }

  /// The page shows LoadError ([inline] or full); with the signal back,
  /// Try again reads [read] again and the error goes.
  Future<void> failsThenLoads(
    WidgetTester tester,
    _Fails read, {
    bool inline = false,
  }) async {
    final error = find.byType(LoadError);
    expect(error, findsOneWidget);
    expect(tester.widget<LoadError>(error).inline, inline);
    final button = find.descendant(
      of: error,
      matching: find.byType(inline ? TextButton : FilledButton),
    );
    expect(
      find.descendant(of: button, matching: find.text('Try again')),
      findsOneWidget,
    );
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    final before = read.reads;
    read.failing = false;
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byType(LoadError), findsNothing);
    expect(read.reads, greaterThan(before));
  }

  group('team pages', () {
    testWidgets('the roster', (tester) async {
      final roster = _Flaky([
        testMembership('a', 'coach', role: MemberRole.owner),
        testMembership('a', 'sam'),
      ]);
      await open(
        tester,
        '/g/a/team',
        overrides: [rosterProvider(_a).overrideWith((ref) => roster.stream())],
      );
      await failsThenLoads(tester, roster);
    });

    testWidgets('team photos', (tester) async {
      final messages = _FlakyMessages();
      await open(tester, '/g/a/documents/photos', messageRepo: messages);
      await failsThenLoads(tester, messages.flaky);
    });

    testWidgets('reports', (tester) async {
      final reports = _Flaky(const <Never>[]);
      await open(
        tester,
        '/g/a/reports',
        overrides: [
          openReportsProvider(_a).overrideWith((ref) => reports.stream()),
        ],
      );
      await failsThenLoads(tester, reports);
    });

    testWidgets('media', (tester) async {
      final media = _Flaky(
        const TeamMedia(items: [], storageBytes: 0, storageQuotaBytes: 100),
      );
      await open(
        tester,
        '/g/a/media',
        overrides: [
          teamMediaProvider(_a).overrideWith((ref) => media.future()),
        ],
      );
      await failsThenLoads(tester, media);
    });

    testWidgets('invite, and its link settings in a section', (tester) async {
      final invite = _Flaky(
        TeamInvite(
          code: 'K7XPM2QR',
          display: 'K7XP-M2QR',
          url: Uri.parse('https://getbattleplan.app/j/K7XPM2QR'),
          useCount: 0,
        ),
      );
      await open(
        tester,
        '/g/a/invite',
        overrides: [
          teamInviteProvider(_a).overrideWith((ref) => invite.future()),
        ],
      );
      await failsThenLoads(tester, invite);
      expect(find.textContaining('K7XP-M2QR'), findsWidgets);
    });

    testWidgets('email invites, in a section', (tester) async {
      final invites = _Flaky(const <Never>[]);
      await open(
        tester,
        '/g/a/invite/email',
        overrides: [
          emailInvitesProvider(_a).overrideWith((ref) => invites.future()),
        ],
      );
      await failsThenLoads(tester, invites, inline: true);
    });

    testWidgets("a player's details: the page, and the card's section", (
      tester,
    ) async {
      final details = _Flaky<PlayerDetails?>(null);
      final overrides = [
        playerDetailsProvider(const PlayerId('p1'))
            .overrideWith((ref) => details.stream()),
      ];
      await open(
        tester,
        '/g/a/team/players/p1',
        overrides: overrides,
        playerRepo: FakePlayerRepository([noah]),
      );
      await failsThenLoads(tester, details, inline: true);
      final page = _Flaky<PlayerDetails?>(null);
      await open(
        tester,
        '/g/a/team/players/p1/details',
        overrides: [
          playerDetailsProvider(const PlayerId('p1'))
              .overrideWith((ref) => page.stream()),
        ],
        playerRepo: FakePlayerRepository([noah]),
      );
      await failsThenLoads(tester, page);
    });

    testWidgets("a player's RSVP history, in a section", (tester) async {
      final events = _FlakyRange();
      await open(
        tester,
        '/g/a/team/players/p1/history',
        eventRepo: events,
        playerRepo: FakePlayerRepository([noah]),
      );
      await failsThenLoads(tester, events.flaky, inline: true);
    });

    testWidgets('dues: the list in a section, and Who owes what as a page', (
      tester,
    ) async {
      final dues = _Flaky(const <Never>[]);
      await open(
        tester,
        '/g/a/dues',
        overrides: [teamDuesProvider(_a).overrideWith((ref) => dues.stream())],
      );
      await failsThenLoads(tester, dues, inline: true);
      final again = _Flaky(const <Never>[]);
      await open(
        tester,
        '/g/a/dues/people',
        overrides: [teamDuesProvider(_a).overrideWith((ref) => again.stream())],
      );
      await failsThenLoads(tester, again);
    });

    testWidgets("a document whose file couldn't download", (tester) async {
      final documents = FakeDocumentRepository([
        Document(
          id: const DocumentId('d1'),
          groupId: _a,
          kind: DocumentKind.file,
          name: 'Roster.pdf',
          path: 'groups/a/documents/d1/Roster.pdf',
          contentType: 'application/pdf',
          size: 100,
          uploadedBy: 'coach',
          uploaderName: 'Coach',
          createdAt: DateTime(2030),
        ),
      ]);
      final bytes = _Flaky<Uint8List?>(Uint8List(4));
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: coach),
        prefs: FakeLocalPrefs()..pushPrePromptShown = true,
        groups: {'a': testGroup('a', 'Thunder')},
        memberships: [testMembership('a', 'coach', role: MemberRole.owner)],
        documentRepo: documents,
        overrides: [
          documentFileBytesProvider('groups/a/documents/d1/Roster.pdf')
              .overrideWith((ref) => bytes.future()),
        ],
      );
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go('/g/a/documents/d/d1');
      await tester.pumpAndSettle();
      await failsThenLoads(tester, bytes);
    });

    testWidgets('Messages', (tester) async {
      final chats = _Flaky(const <Membership>[]);
      await open(
        tester,
        '/messages',
        overrides: [
          myDirectMembershipsProvider.overrideWith((ref) => chats.stream()),
        ],
      );
      await failsThenLoads(tester, chats);
      expect(
        find.text(
          "Couldn't load your messages. Check your connection "
          'and try again.',
        ),
        findsNothing,
      );
    });
  });

  group('the Super Admin Panel', () {
    const wide = Size(1280, 1000);

    for (final (path, name) in [
      ('/admin', 'the Dashboard'),
      ('/admin/teams', 'Teams'),
      ('/admin/users', 'Users'),
      ('/admin/reports', 'Reports'),
      ('/admin/audit', 'Audit log'),
    ]) {
      testWidgets(name, (tester) async {
        final admin = FakeAdminRepository();
        final fails = _AdminFails(admin);
        await open(tester, path, user: boss, admin: admin, size: wide);
        await failsThenLoads(tester, fails);
      });
    }

    testWidgets("a team's people and content, in a section", (tester) async {
      final admin = FakeAdminRepository();
      final fails = _AdminFails(admin);
      await open(
        tester,
        '/admin/teams/a',
        user: boss,
        admin: admin,
        size: wide,
      );
      await failsThenLoads(tester, fails, inline: true);
    });

    testWidgets('Platform settings', (tester) async {
      final config = _Flaky(const AppConfig());
      await open(
        tester,
        '/admin/settings',
        user: boss,
        size: wide,
        overrides: [appConfigProvider.overrideWith((ref) => config.stream())],
      );
      await failsThenLoads(tester, config);
    });
  });

  test('no "Couldn\'t load" text is left without Try again', () {
    final bare = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.contains('/gen/') ||
          file.path.endsWith('core/widgets/load_error.dart')) {
        continue;
      }
      final source = file.readAsStringSync();
      if (RegExp(r'\.loadError\b').hasMatch(source)) bare.add(file.path);
    }
    expect(bare, isEmpty);
  });

  test("a failed message's Retry and sign-in's Retry keep their word", () {
    String read(String path) => File(path).readAsStringSync();
    expect(
      read('lib/features/chat/presentation/message_tile.dart'),
      contains('l10n.retry'),
    );
    expect(
      read('lib/features/auth/presentation/sign_in_error_text.dart'),
      contains('l10n.retry'),
    );
  });
}
