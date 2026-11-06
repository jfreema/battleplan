// Dues (DUES-1 to DUES-3): admins add a due for every player (or member in
// a group), mark who paid, and share how to pay; everyone else sees only
// what they or their players owe.
import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/back_chevron.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/dues/domain/due.dart';
import 'package:battleplan/features/dues/presentation/dues_screen.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/presentation/who_are_you_screen.dart';
import 'package:battleplan/l10n/gen/app_localizations_en.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  const coach = AuthUser(
    uid: 'coach',
    email: 'coach@example.com',
    emailVerified: true,
  );
  final players = FakePlayerRepository(const [
    Player(
      id: PlayerId('emma'),
      groupId: GroupId('a'),
      displayName: 'Emma Rivera',
      jerseyNumber: '7',
    ),
    Player(
      id: PlayerId('liam'),
      groupId: GroupId('a'),
      displayName: 'Liam Park',
      jerseyNumber: '9',
    ),
  ]);

  Future<void> go(WidgetTester tester, String path) async {
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
    await tester.pumpAndSettle();
  }

  group('helpers', () {
    final l10n = AppLocalizationsEn();
    test('amounts read as dollars', () {
      expect(formatDues(l10n, 4500), r'$45');
      expect(formatDues(l10n, 4550), r'$45.50');
    });

    test('totals leave out waived shares', () {
      DueCharge c(DueStatus s) => DueCharge(
        id: 'x',
        groupId: const GroupId('a'),
        dueId: 'd',
        title: 'Fee',
        amountCents: 1000,
        participantType: ParticipantType.player,
        participantId: 'p',
        participantName: 'P',
        status: s,
      );
      final t = dueTotals([
        c(DueStatus.paid),
        c(DueStatus.owed),
        c(DueStatus.owed),
        c(DueStatus.waived),
      ]);
      expect(t, (paid: 1, count: 3, owedCents: 2000));
      expect(venmoUser('@thunder-u14'), 'thunder-u14');
      expect(cashTag(r'$Thunder'), 'Thunder');
    });

    test('a pasted profile link reads as the handle it names', () {
      for (final v in [
        'https://venmo.com/u/Thunder-Softball',
        'venmo.com/Thunder-Softball',
        'https://account.venmo.com/u/Thunder-Softball?txn=pay',
        'www.venmo.com/u/Thunder-Softball/',
        ' @Thunder-Softball ',
        'Thunder-Softball',
      ]) {
        expect(venmoUser(v), 'Thunder-Softball', reason: v);
      }
      for (final v in [
        r'https://cash.app/$Thunder',
        r'cash.app/$Thunder/',
        r' $Thunder',
        'Thunder',
      ]) {
        expect(cashTag(v), 'Thunder', reason: v);
      }
      expect(venmoUser('https://venmo.com/'), '');
    });

    test('a due date has passed once its day is over', () {
      final today = DateTime(2026, 11, 6, 9);
      expect(duePassed('2026-11-05', today), isTrue);
      expect(duePassed('2026-11-06', today), isFalse);
      expect(duePassed('2026-12-01', today), isFalse);
      expect(duePassed('soon', today), isFalse);
    });

    test('amounts parse with either decimal mark, and nothing else', () {
      for (final (text, cents) in [
        ('45', 4500),
        (r'$45', 4500),
        (r' $ 45.5 ', 4550),
        ('12.50', 1250),
        ('12,50', 1250),
        ('12,5', 1250),
        ('1,234', 123400),
        ('1,234.56', 123456),
        ('1.234,56', 123456),
        ('10,000', 1000000),
        ('.5', 50),
        ('45.', 4500),
        ('0.01', 1),
      ]) {
        expect(parseDollars(text), cents, reason: text);
      }
      for (final text in [
        '',
        r'$',
        '0',
        '0.00',
        '12.345',
        '12,345,6',
        '1,23,456',
        '1.2.3',
        '12,',
        '1,234,',
        '10,000.01',
        '99999999999',
        'abc',
        '-5',
        '1.234.56,7',
      ]) {
        expect(parseDollars(text), isNull, reason: text);
      }
    });
  });

  DueCharge share(String id, String name, {String due = 'd0'}) => DueCharge(
    id: '${due}_$id',
    groupId: const GroupId('a'),
    dueId: due,
    title: 'Uniform fee',
    amountCents: 4500,
    participantType: ParticipantType.player,
    participantId: id,
    participantName: name,
  );

  const uniforms = Due(
    id: 'd0',
    groupId: GroupId('a'),
    title: 'Uniform fee',
    amountCents: 4500,
  );

  Future<void> pumpCoach(
    WidgetTester tester,
    FakeDuesRepository dues, {
    MemberRole role = MemberRole.owner,
  }) => pumpApp(
    tester,
    auth: FakeAuthRepository(user: coach),
    groups: {'a': testGroup('a', 'Thunder')},
    memberships: [testMembership('a', 'coach', role: role)],
    playerRepo: players,
    duesRepo: dues,
  );

  testWidgets('editing changes the due and never adds one', (tester) async {
    final dues = FakeDuesRepository()
      ..dues.add(uniforms)
      ..charges.addAll([share('emma', 'Emma #7'), share('liam', 'Liam #9')]);
    await pumpCoach(tester, dues);
    await go(tester, '/g/a/dues/d0/edit');
    await tester.enterText(find.byType(TextField).at(1), '50,00');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(dues.calls, ['edit d0 Uniform fee 5000']);
    expect(dues.dues, hasLength(1));
    expect(dues.charges.every((c) => c.amountCents == 5000), isTrue);
  });

  testWidgets("editing a due that's gone says so, with nothing to save", (
    tester,
  ) async {
    final dues = FakeDuesRepository();
    await pumpCoach(tester, dues);
    await go(tester, '/g/a/dues/gone/edit');
    expect(find.text('This due was deleted.'), findsOneWidget);
    expect(find.text('Save'), findsNothing);
    expect(dues.calls, isEmpty);
  });

  testWidgets('a bad amount is refused before anything is saved', (
    tester,
  ) async {
    final dues = FakeDuesRepository();
    await pumpCoach(tester, dues);
    await go(tester, '/g/a/dues/new');
    await tester.enterText(find.byType(TextField).at(0), 'Fee');
    await tester.enterText(find.byType(TextField).at(1), '12.345');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      find.text(r'Enter an amount, like $45, up to $10,000.'),
      findsOneWidget,
    );
    expect(dues.calls, isEmpty);
  });

  testWidgets('the admin deletes a due with all its charges', (tester) async {
    final dues = FakeDuesRepository()
      ..dues.add(uniforms)
      ..charges.addAll([share('emma', 'Emma #7'), share('liam', 'Liam #9')]);
    await pumpCoach(tester, dues);
    await go(tester, '/g/a/dues');
    expect(find.text(r'0 of 2 paid · $90 owed'), findsOneWidget);
    await go(tester, '/g/a/dues/d0');
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete due'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete due').last);
    await tester.pumpAndSettle();
    expect(dues.calls, ['remove d0']);
    expect(dues.charges, isEmpty);
  });

  group("lists that can't load say so", () {
    const error = "Couldn't load this. Check your connection and try again.";

    testWidgets('for an admin, on the list and on a due', (tester) async {
      final dues = FakeDuesRepository()..failReads = true;
      await pumpCoach(tester, dues);
      await go(tester, '/g/a/dues');
      // The dues, and how to pay.
      expect(find.text(error), findsNWidgets(2));
      expect(find.text('Edit how to pay'), findsNothing);
      await go(tester, '/g/a/dues/d0');
      expect(find.text(error), findsOneWidget);
    });

    testWidgets('for a member', (tester) async {
      final dues = FakeDuesRepository()..failReads = true;
      await pumpCoach(tester, dues, role: MemberRole.member);
      await go(tester, '/g/a/dues');
      expect(find.text(error), findsNWidgets(2));
      expect(
        find.text("The admins haven't added a way to pay yet."),
        findsNothing,
      );
    });
  });

  testWidgets('an admin adds a due for every player, and marks who paid', (
    tester,
  ) async {
    final dues = FakeDuesRepository();
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'a': testGroup('a', 'Thunder')},
      memberships: [testMembership('a', 'coach', role: MemberRole.owner)],
      playerRepo: players,
      duesRepo: dues,
    );
    await go(tester, '/g/a/info');
    await tester.tap(find.text('Dues'));
    await tester.pumpAndSettle();
    expect(
      find.text("No dues yet. Add one to track who's paid."),
      findsOneWidget,
    );
    await tester.tap(find.text('New due'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Uniform fee');
    await tester.enterText(find.byType(TextField).at(1), '45');
    // Liam's family already paid for his.
    await tester.tap(find.text('Liam #9'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(dues.calls, ['create Uniform fee 4500 1']);
    expect(find.text('Uniform fee'), findsOneWidget);
    expect(find.text(r'0 of 1 paid · $45 owed'), findsOneWidget);

    await tester.tap(find.text('Uniform fee'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Emma #7'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark paid'));
    await tester.pumpAndSettle();
    expect(dues.calls.last, 'status d0_emma paid');
    expect(find.text('1 of 1 paid'), findsOneWidget);
  });

  testWidgets('a parent sees only their player, and how to pay', (
    tester,
  ) async {
    final dues = FakeDuesRepository()
      ..payments = const DuesPayments(venmo: '@thunder')
      ..charges.addAll([
        for (final (id, name) in [('emma', 'Emma #7'), ('liam', 'Liam #9')])
          DueCharge(
            id: 'd0_$id',
            groupId: const GroupId('a'),
            dueId: 'd0',
            title: 'Uniform fee',
            amountCents: 4500,
            participantType: ParticipantType.player,
            participantId: id,
            participantName: name,
          ),
      ]);
    players.links.add(
      const GuardianLink(
        playerId: PlayerId('emma'),
        groupId: GroupId('a'),
        uid: UserId('coach'),
      ),
    );
    addTearDown(players.links.clear);
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {'a': testGroup('a', 'Thunder')},
      memberships: [testMembership('a', 'coach')],
      playerRepo: players,
      duesRepo: dues,
    );
    await go(tester, '/g/a/dues');
    expect(find.text('What you owe'), findsOneWidget);
    expect(find.text(r'$45 owed'), findsOneWidget);
    expect(find.text('Uniform fee'), findsOneWidget);
    // Not Liam's: he's not theirs.
    expect(find.textContaining('Liam'), findsNothing);
    expect(find.text('New due'), findsNothing);
    expect(find.text('@thunder'), findsOneWidget);
    expect(find.byTooltip('Copy Venmo'), findsOneWidget);
  });

  testWidgets('in a group, everyone owes for themselves', (tester) async {
    final dues = FakeDuesRepository();
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {
        'a': testGroup('a', 'Book club').copyWith(kind: GroupKind.group),
      },
      memberships: [
        testMembership('a', 'coach', role: MemberRole.owner, name: 'Coach Lee'),
        testMembership('a', 'sam', name: 'Sam Rivera'),
      ],
      duesRepo: dues,
    );
    await go(tester, '/g/a/dues/new');
    expect(find.text('Coach Lee'), findsOneWidget);
    expect(find.text('Sam Rivera'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Snacks');
    await tester.enterText(find.byType(TextField).at(1), '12.50');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(dues.calls, ['create Snacks 1250 2']);
    expect(dues.charges.map((c) => c.participantType).toSet(), {
      ParticipantType.member,
    });
  });

  testWidgets('a due for more people than it can charge is refused', (
    tester,
  ) async {
    final dues = FakeDuesRepository();
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: coach),
      groups: {
        'a': testGroup('a', 'Book club').copyWith(kind: GroupKind.group),
      },
      memberships: [
        testMembership('a', 'coach', role: MemberRole.owner),
        for (var i = 0; i < Limits.duesChargesMax; i++)
          testMembership('a', 'm$i'),
      ],
      duesRepo: dues,
    );
    await go(tester, '/g/a/dues/new');
    await tester.enterText(find.byType(TextField).at(0), 'Snacks');
    await tester.enterText(find.byType(TextField).at(1), '5');
    await tester.scrollUntilVisible(
      find.text('Save'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'A due can have at most ${Limits.duesChargesMax} people on it. '
        'Uncheck some to continue.',
      ),
      findsOneWidget,
    );
    expect(dues.calls, isEmpty);
  });

  group("a parent isn't told they owe nothing until it's known", () {
    DueCharge emmaShare() => share('emma', 'Emma #7');
    const emmaLink = GuardianLink(
      playerId: PlayerId('emma'),
      groupId: GroupId('a'),
      uid: UserId('coach'),
    );

    Future<void> pumpParent(WidgetTester tester, FakeDuesRepository dues) =>
        pumpApp(
          tester,
          auth: FakeAuthRepository(user: coach),
          groups: {'a': testGroup('a', 'Thunder')},
          memberships: [testMembership('a', 'coach')],
          playerRepo: players,
          duesRepo: dues,
        );

    testWidgets('while their player links load', (tester) async {
      final links = StreamController<List<GuardianLink>>();
      players.linksStream = links.stream;
      addTearDown(() => players.linksStream = null);
      final dues = FakeDuesRepository()..charges.add(emmaShare());
      await pumpParent(tester, dues);
      await go(tester, '/g/a/dues');
      expect(find.byType(SkeletonList), findsOneWidget);
      expect(find.text('Nothing owed.'), findsNothing);
      expect(find.text('All paid. Thanks!'), findsNothing);

      links.add([emmaLink]);
      await tester.pumpAndSettle();
      expect(find.byType(SkeletonList), findsNothing);
      expect(find.text(r'$45 owed'), findsOneWidget);
      expect(find.text('Uniform fee'), findsOneWidget);
      await links.close();
    });

    testWidgets("or when their links can't load", (tester) async {
      players.linksStream = Stream.error(const PermissionDenied('links'));
      addTearDown(() => players.linksStream = null);
      final dues = FakeDuesRepository()..charges.add(emmaShare());
      await pumpParent(tester, dues);
      await go(tester, '/g/a/dues');
      expect(
        find.text("Couldn't load this. Check your connection and try again."),
        findsOneWidget,
      );
      expect(find.text('Nothing owed.'), findsNothing);
    });
  });

  /// Dues for [members] of team (or group) 'a', signed in as the coach.
  Future<void> pumpDues(
    WidgetTester tester,
    FakeDuesRepository dues, {
    MemberRole role = MemberRole.member,
    List<Membership> others = const [],
    Membership? me,
    Group? group,
    FakePlayerRepository? playerRepo,
    FakeLinkOpener? linkOpener,
    Size size = const Size(400, 1600),
  }) => pumpApp(
    tester,
    auth: FakeAuthRepository(user: coach),
    groups: {'a': group ?? testGroup('a', 'Thunder')},
    memberships: [
      me ?? testMembership('a', 'coach', role: role, name: 'Coach Lee'),
      ...others,
    ],
    playerRepo: playerRepo ?? FakePlayerRepository(players.players),
    duesRepo: dues,
    linkOpener: linkOpener,
    size: size,
  );

  DueCharge memberShare(String uid, String name, {String due = 'dO'}) =>
      DueCharge(
        id: '${due}_$uid',
        groupId: const GroupId('a'),
        dueId: due,
        title: 'Snacks',
        amountCents: 500,
        participantType: ParticipantType.member,
        participantId: uid,
        participantName: name,
      );

  const emmaLink = GuardianLink(
    playerId: PlayerId('emma'),
    groupId: GroupId('a'),
    uid: UserId('coach'),
  );

  FakePlayerRepository linkedToEmma() =>
      FakePlayerRepository(players.players)..links.add(emmaLink);

  group('how to pay (DUES-3)', () {
    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      testWidgets('the ${platform.name} app '
          '${platform == TargetPlatform.iOS ? 'only copies' : 'copies and opens'}'
          ' the handles', (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        try {
          final opener = FakeLinkOpener();
          final dues = FakeDuesRepository()
            ..payments = const DuesPayments(
              venmo: '@thunder',
              cashApp: r'$thunder',
            );
          await pumpDues(tester, dues, linkOpener: opener);
          await go(tester, '/g/a/dues');
          expect(find.byTooltip('Copy Venmo'), findsOneWidget);
          expect(find.byTooltip('Copy Cash App'), findsOneWidget);
          if (platform == TargetPlatform.iOS) {
            // Apple's rules: the iPhone app never links out to pay.
            expect(find.byTooltip('Open Venmo'), findsNothing);
            expect(find.byTooltip('Open Cash App'), findsNothing);
          } else {
            await tester.tap(find.byTooltip('Open Venmo'));
            await tester.tap(find.byTooltip('Open Cash App'));
            await tester.pumpAndSettle();
            expect(opener.opened, [
              Uri.https('venmo.com', '/u/thunder'),
              Uri.https('cash.app', r'/$thunder'),
            ]);
          }
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }

    testWidgets('a pasted profile link shows, copies and opens as the handle', (
      tester,
    ) async {
      final opener = FakeLinkOpener();
      final dues = FakeDuesRepository()
        ..payments = const DuesPayments(
          venmo: 'https://venmo.com/u/Thunder-U14',
          cashApp: r'https://cash.app/$ThunderU14',
        );
      await pumpDues(tester, dues, linkOpener: opener);
      await go(tester, '/g/a/dues');
      expect(find.text('@Thunder-U14'), findsOneWidget);
      expect(find.text(r'$ThunderU14'), findsOneWidget);
      await tester.tap(find.byTooltip('Open Venmo'));
      await tester.pumpAndSettle();
      expect(opener.opened, [Uri.https('venmo.com', '/u/Thunder-U14')]);
    });

    testWidgets('an admin edits it: what was saved fills the form, handles '
        'are typed as is, and a pasted link saves as the handle', (
      tester,
    ) async {
      final dues = FakeDuesRepository()
        ..payments = const DuesPayments(
          venmo: '@thunder',
          cashApp: r'$thunder',
          note: 'Thanks!',
        );
      await pumpCoach(tester, dues);
      await go(tester, '/g/a/dues');
      await tester.tap(find.text('Edit how to pay'));
      await tester.pumpAndSettle();
      final fields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      expect(
        tester.widget<TextField>(fields.at(1)).controller?.text,
        r'$thunder',
      );
      for (var i = 0; i < 3; i++) {
        final field = tester.widget<TextField>(fields.at(i));
        expect(field.autocorrect, isFalse);
        expect(field.enableSuggestions, isFalse);
      }
      expect(tester.widget<TextField>(fields.at(3)).autocorrect, isTrue);
      await tester.enterText(
        fields.at(0),
        '  https://venmo.com/u/Thunder-U14  ',
      );
      await tester.enterText(fields.at(2), ' 555-0100 ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(dues.calls, ['payments']);
      expect(dues.payments.venmo, '@Thunder-U14');
      expect(dues.payments.cashApp, r'$thunder');
      expect(dues.payments.appleCash, '555-0100');
      expect(dues.payments.note, 'Thanks!');
      // Saved in their name, which everyone sees.
      expect(find.text('Updated by coach'), findsOneWidget);
    });

    testWidgets('a save that fails says so', (tester) async {
      final dues = FakeDuesRepository()..failWrites = const Offline();
      await pumpCoach(tester, dues);
      await go(tester, '/g/a/dues');
      await tester.tap(find.text('Edit how to pay'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '@thunder');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text("Couldn't save. Try again."), findsOneWidget);
    });

    testWidgets("while it loads, nobody is told there's no way to pay, and "
        "admins can't edit it yet", (tester) async {
      final payments = StreamController<DuesPayments>.broadcast();
      addTearDown(payments.close);
      final dues = FakeDuesRepository()..paymentsStream = payments.stream;
      await pumpCoach(tester, dues);
      await go(tester, '/g/a/dues');
      expect(find.textContaining('a way to pay'), findsNothing);
      expect(find.textContaining('Add how people can pay'), findsNothing);
      expect(find.text('Edit how to pay'), findsNothing);
    });

    testWidgets("when it can't load, it says so, and admins can't edit it", (
      tester,
    ) async {
      final dues = FakeDuesRepository()
        ..paymentsStream = Stream.error(const Offline());
      await pumpCoach(tester, dues);
      await go(tester, '/g/a/dues');
      expect(
        find.text("Couldn't load this. Check your connection and try again."),
        findsOneWidget,
      );
      expect(find.text('Edit how to pay'), findsNothing);
    });

    testWidgets('with none yet, admins are asked to add one; others are told '
        "the admins haven't", (tester) async {
      await pumpCoach(tester, FakeDuesRepository());
      await go(tester, '/g/a/dues');
      expect(
        find.text('Add how people can pay: Venmo, Cash App, or Apple Cash.'),
        findsOneWidget,
      );
      expect(find.text('Edit how to pay'), findsOneWidget);
    });

    testWidgets('shows who saved it last, or that they have left', (
      tester,
    ) async {
      final dues = FakeDuesRepository()
        ..payments = const DuesPayments(venmo: '@thunder', updatedBy: 'carter');
      await pumpDues(
        tester,
        dues,
        others: [
          testMembership(
            'a',
            'carter',
            role: MemberRole.admin,
            name: 'Coach Carter',
          ),
        ],
      );
      await go(tester, '/g/a/dues');
      expect(find.text('Updated by Coach Carter'), findsOneWidget);
    });

    testWidgets("someone who's left reads as a former member", (tester) async {
      final dues = FakeDuesRepository()
        ..payments = const DuesPayments(venmo: '@thunder', updatedBy: 'gone');
      await pumpDues(tester, dues);
      await go(tester, '/g/a/dues');
      expect(find.text('Updated by a former member'), findsOneWidget);
    });

    testWidgets("a team's coaches edit it too, and nothing else of the dues", (
      tester,
    ) async {
      final dues = FakeDuesRepository();
      await pumpDues(
        tester,
        dues,
        me: testMembership(
          'a',
          'coach',
          name: 'Coach Lee',
        ).copyWith(coach: true),
      );
      await go(tester, '/g/a/dues');
      expect(find.text('What you owe'), findsOneWidget);
      expect(find.text('New due'), findsNothing);
      await tester.tap(find.text('Edit how to pay'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '@coach-lee');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(dues.payments.venmo, '@coach-lee');
      expect(dues.payments.updatedBy, 'coach');
    });

    testWidgets('a group has no coaches: a coach flag there edits nothing', (
      tester,
    ) async {
      await pumpDues(
        tester,
        FakeDuesRepository(),
        group: testGroup('a', 'Book club').copyWith(kind: GroupKind.group),
        me: testMembership('a', 'coach').copyWith(coach: true),
      );
      await go(tester, '/g/a/dues');
      expect(find.text('Edit how to pay'), findsNothing);
      // A group's own words.
      expect(
        find.text("Pay directly. Battleplan doesn't handle payments."),
        findsOneWidget,
      );
    });

    testWidgets("a group's note hint is about you, not your player", (
      tester,
    ) async {
      await pumpDues(
        tester,
        FakeDuesRepository(),
        role: MemberRole.owner,
        group: testGroup('a', 'Book club').copyWith(kind: GroupKind.group),
      );
      await go(tester, '/g/a/dues');
      await tester.tap(find.text('Edit how to pay'));
      await tester.pumpAndSettle();
      expect(find.text('Like "Put your name in the note"'), findsOneWidget);
    });
  });

  group('screen readers reach every button (SPEC §7.6)', () {
    SemanticsNode node(WidgetTester tester, Finder f) => tester.getSemantics(f);
    FinderBase<SemanticsNode> byTooltip(String tip) =>
        find.semantics.byPredicate((n) => n.tooltip == tip);

    testWidgets('Copy and Open on How to pay are buttons of their own', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final copied = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map<Object?, Object?>)['text']);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final opener = FakeLinkOpener();
      final dues = FakeDuesRepository()
        ..payments = const DuesPayments(venmo: '@thunder');
      await pumpDues(tester, dues, linkOpener: opener);
      await go(tester, '/g/a/dues');
      final row = node(tester, find.text('@thunder')).id;
      expect(node(tester, find.byTooltip('Copy Venmo')).id, isNot(row));
      expect(node(tester, find.byTooltip('Open Venmo')).id, isNot(row));
      tester.semantics.tap(byTooltip('Open Venmo'));
      await tester.pumpAndSettle();
      expect(opener.opened, [Uri.https('venmo.com', '/u/thunder')]);
      tester.semantics.tap(byTooltip('Copy Venmo'));
      await tester.pumpAndSettle();
      expect(copied, ['@thunder']);
      handle.dispose();
    });

    testWidgets('Clear date is a button of its own, apart from the date', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final dues = FakeDuesRepository()
        ..dues.add(uniforms.copyWith(dueOn: '2030-10-31'));
      await pumpCoach(tester, dues);
      await go(tester, '/g/a/dues/d0/edit');
      expect(find.text('Oct 31'), findsOneWidget);
      expect(
        node(tester, find.byTooltip('Clear date')).id,
        isNot(node(tester, find.text('Oct 31')).id),
      );
      tester.semantics.tap(byTooltip('Clear date'));
      await tester.pumpAndSettle();
      expect(find.text('No date'), findsOneWidget);
      expect(find.byType(DatePickerDialog), findsNothing);
      handle.dispose();
    });

    testWidgets('a share says where it stands, and a change is announced', (
      tester,
    ) async {
      final dues = FakeDuesRepository()
        ..dues.add(uniforms)
        ..charges.add(share('emma', 'Emma #7'));
      await pumpCoach(tester, dues);
      await go(tester, '/g/a/dues/d0');
      await tester.tap(find.text('Emma #7'));
      await tester.pumpAndSettle();
      expect(find.text(r'$45 · Owes'), findsOneWidget);
      // Only what it can change to.
      expect(find.text('Mark not paid'), findsNothing);
      tester.takeAnnouncements();
      await tester.tap(find.text('Mark paid'));
      await tester.pumpAndSettle();
      expect(
        tester.takeAnnouncements(),
        contains(isAccessibilityAnnouncement('Emma #7: Paid')),
      );
    });
  });

  group('new and edited dues', () {
    testWidgets('while the players load, nobody is said to be missing, and '
        "there's nothing to save yet", (tester) async {
      final roster = StreamController<List<Player>>.broadcast();
      addTearDown(roster.close);
      final repo = FakePlayerRepository(players.players)
        ..playersStream = roster.stream;
      await pumpDues(
        tester,
        FakeDuesRepository(),
        role: MemberRole.owner,
        playerRepo: repo,
      );
      await go(tester, '/g/a/dues/new');
      expect(find.byType(SkeletonList), findsOneWidget);
      expect(find.text('Add players to the roster first.'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
            .onPressed,
        isNull,
      );
    });

    testWidgets("when the players can't load, it says so", (tester) async {
      final repo = FakePlayerRepository(players.players)
        ..playersStream = Stream.error(const Offline());
      await pumpDues(
        tester,
        FakeDuesRepository(),
        role: MemberRole.owner,
        playerRepo: repo,
      );
      await go(tester, '/g/a/dues/new');
      expect(
        find.text("Couldn't load this. Check your connection and try again."),
        findsOneWidget,
      );
    });

    testWidgets('hints read as examples, and the note says who sees it', (
      tester,
    ) async {
      await pumpCoach(tester, FakeDuesRepository());
      await go(tester, '/g/a/dues/new');
      expect(find.text('Like "Uniform fee"'), findsOneWidget);
      expect(find.text(r'Like $45'), findsOneWidget);
      expect(find.text('Everyone who owes it sees this.'), findsOneWidget);
    });

    testWidgets('trying again after a lost reply sends the same request', (
      tester,
    ) async {
      final dues = FakeDuesRepository()..failWrites = const Offline();
      await pumpCoach(tester, dues);
      await go(tester, '/g/a/dues/new');
      await tester.enterText(find.byType(TextField).at(0), 'Fee');
      await tester.enterText(find.byType(TextField).at(1), '10');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text("Couldn't save. Try again."), findsOneWidget);
      dues.failWrites = null;
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(dues.dues, hasLength(1));
      expect(dues.requestIds, hasLength(2));
      expect(dues.requestIds.first, isNotNull);
      expect(dues.requestIds.toSet(), hasLength(1));
    });

    testWidgets("an old season's due, or a far one, opens the date picker on "
        'its own date', (tester) async {
      for (final on in ['2020-03-01', '2040-06-15']) {
        final dues = FakeDuesRepository()
          ..dues.add(uniforms.copyWith(dueOn: on));
        await pumpCoach(tester, dues);
        await go(tester, '/g/a/dues/d0/edit');
        await tester.tap(find.text('Due date'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: on);
        expect(find.byType(DatePickerDialog), findsOneWidget, reason: on);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('changing the amount of a due someone paid asks first', (
      tester,
    ) async {
      final dues = FakeDuesRepository()
        ..dues.add(uniforms)
        ..charges.addAll([
          share('emma', 'Emma #7').copyWith(status: DueStatus.paid),
          share('liam', 'Liam #9'),
        ]);
      await pumpCoach(tester, dues);
      await go(tester, '/g/a/dues/d0/edit');
      // Back to the due it came from.
      expect(
        find.descendant(
          of: find.byType(BackChevron),
          matching: find.text('Uniform fee'),
        ),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField).at(1), '50');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Change the amount?'), findsOneWidget);
      expect(
        find.text(
          r'1 person has already paid. Their shares will show $50 too, so '
          'mark them not paid if they owe the difference.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(dues.calls, isEmpty);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();
      expect(dues.calls, ['edit d0 Uniform fee 5000']);
    });

    testWidgets("the due's note reaches everyone who owes it", (tester) async {
      final dues = FakeDuesRepository()
        ..charges.add(
          share('emma', 'Emma #7').copyWith(note: 'Jersey and hat.'),
        );
      await pumpDues(tester, dues, playerRepo: linkedToEmma());
      await go(tester, '/g/a/dues');
      expect(find.textContaining('Jersey and hat.'), findsOneWidget);
    });
  });

  group("a due's screen", () {
    testWidgets('lists who still owes first, then who paid, then waived', (
      tester,
    ) async {
      final dues = FakeDuesRepository()
        ..dues.add(uniforms)
        ..charges.addAll([
          share('ava', 'Ava'),
          share('ben', 'Ben').copyWith(status: DueStatus.paid),
          share('cal', 'Cal').copyWith(status: DueStatus.waived),
          share('abe', 'Abe').copyWith(status: DueStatus.paid),
          share('zed', 'Zed'),
        ]);
      await pumpCoach(tester, dues);
      await go(tester, '/g/a/dues/d0');
      final order = [
        for (final n in ['Ava', 'Zed', 'Abe', 'Ben', 'Cal'])
          tester.getTopLeft(find.text(n)).dy,
      ];
      expect(order, [...order]..sort());
    });

    testWidgets('a date that has passed reads as overdue while owed', (
      tester,
    ) async {
      final dues = FakeDuesRepository()
        ..dues.add(uniforms.copyWith(dueOn: '2020-01-15'))
        ..charges.addAll([
          share('emma', 'Emma #7').copyWith(dueOn: '2020-01-15'),
          share(
            'liam',
            'Liam #9',
          ).copyWith(dueOn: '2020-01-15', status: DueStatus.paid),
        ]);
      await pumpCoach(tester, dues);
      await go(tester, '/g/a/dues');
      expect(find.text('Overdue since Jan 15'), findsOneWidget);
      await go(tester, '/g/a/dues/d0');
      expect(find.textContaining('Overdue since Jan 15'), findsNWidgets(2));
    });

    testWidgets('a long title shows in full', (tester) async {
      const long = 'Tournament entry and team hotel deposit';
      final dues = FakeDuesRepository()
        ..dues.add(uniforms.copyWith(title: long));
      await pumpCoach(tester, dues);
      await go(tester, '/g/a/dues/d0');
      // Cut short in the bar, so whole under it.
      expect(find.text(long), findsNWidgets(2));
      final short = FakeDuesRepository()
        ..dues.add(uniforms.copyWith(title: 'Fee'));
      await pumpCoach(tester, short);
      await go(tester, '/g/a/dues/d0');
      expect(find.text('Fee'), findsOneWidget);
    });

    testWidgets('a due whose shares are all waived says so', (tester) async {
      final dues = FakeDuesRepository()
        ..dues.add(uniforms)
        ..charges.add(
          share('emma', 'Emma #7').copyWith(status: DueStatus.waived),
        );
      await pumpCoach(tester, dues);
      await go(tester, '/g/a/dues');
      expect(find.text('All waived'), findsOneWidget);
      expect(find.textContaining('0 of 0'), findsNothing);
    });

    testWidgets('admins add a player who joined later; each starts owing it', (
      tester,
    ) async {
      final repo = FakePlayerRepository([
        ...players.players,
        const Player(
          id: PlayerId('newbie'),
          groupId: GroupId('a'),
          displayName: 'Nia New',
          status: PlayerStatus.pending,
        ),
      ]);
      final dues = FakeDuesRepository()
        ..dues.add(uniforms)
        ..charges.add(share('emma', 'Emma #7'));
      await pumpDues(tester, dues, role: MemberRole.owner, playerRepo: repo);
      await go(tester, '/g/a/dues/d0');
      await tester.tap(find.text('Add people'));
      await tester.pumpAndSettle();
      final dialog = find.byType(AlertDialog);
      // Only who isn't on it yet, and no one pending.
      expect(
        find.descendant(of: dialog, matching: find.text('Liam #9')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('Emma #7')),
        findsNothing,
      );
      expect(
        find.descendant(of: dialog, matching: find.textContaining('Nia')),
        findsNothing,
      );
      await tester.tap(find.text('Liam #9'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(dues.calls, ['edit d0 Uniform fee 4500 +liam']);
      expect(find.text(r'0 of 2 paid · $90 owed'), findsOneWidget);
      await tester.tap(find.text('Add people'));
      await tester.pumpAndSettle();
      expect(find.text("Everyone's already on this due."), findsOneWidget);
    });
  });

  group('an archived team (TEAM-9)', () {
    testWidgets('its admins read its dues, and change nothing', (tester) async {
      final dues = FakeDuesRepository()
        ..payments = const DuesPayments(venmo: '@thunder')
        ..dues.add(uniforms)
        ..charges.add(share('emma', 'Emma #7'));
      await pumpDues(
        tester,
        dues,
        role: MemberRole.owner,
        group: testGroup('a', 'Thunder').copyWith(archivedAt: DateTime(2026)),
      );
      await go(tester, '/g/a/dues');
      expect(find.text('New due'), findsNothing);
      expect(find.text('Edit how to pay'), findsNothing);
      await go(tester, '/g/a/dues/d0');
      expect(find.text('Add people'), findsNothing);
      expect(find.byTooltip('More actions'), findsNothing);
      await tester.tap(find.text('Emma #7'));
      await tester.pumpAndSettle();
      expect(find.text('Mark paid'), findsNothing);
    });

    testWidgets('with no dues, it says so without asking for one', (
      tester,
    ) async {
      await pumpDues(
        tester,
        FakeDuesRepository(),
        role: MemberRole.owner,
        group: testGroup('a', 'Thunder').copyWith(archivedAt: DateTime(2026)),
      );
      await go(tester, '/g/a/dues');
      expect(find.text('No dues.'), findsOneWidget);
    });
  });

  group('what you owe (DUES-2)', () {
    testWidgets("after a group became a team, a member's own shares from "
        'before still show, with whose each is', (tester) async {
      final dues = FakeDuesRepository()
        ..charges.addAll([
          memberShare('coach', 'Coach Lee'),
          share('emma', 'Emma #7'),
        ]);
      await pumpDues(tester, dues, playerRepo: linkedToEmma());
      await go(tester, '/g/a/dues');
      expect(find.text('Snacks'), findsOneWidget);
      expect(find.text('Uniform fee'), findsOneWidget);
      expect(find.text(r'$50 owed'), findsOneWidget);
      expect(find.textContaining('For Coach Lee'), findsOneWidget);
      expect(find.textContaining('For Emma #7'), findsOneWidget);
    });

    testWidgets('one player, one name: no "For"', (tester) async {
      final dues = FakeDuesRepository()..charges.add(share('emma', 'Emma #7'));
      await pumpDues(tester, dues, playerRepo: linkedToEmma());
      await go(tester, '/g/a/dues');
      expect(find.text('Uniform fee'), findsOneWidget);
      expect(find.textContaining('For '), findsNothing);
    });

    testWidgets('only waived shares: nothing owed, and no thanks', (
      tester,
    ) async {
      final dues = FakeDuesRepository()
        ..charges.add(
          share('emma', 'Emma #7').copyWith(status: DueStatus.waived),
        );
      await pumpDues(tester, dues, playerRepo: linkedToEmma());
      await go(tester, '/g/a/dues');
      expect(find.text('Nothing owed.'), findsOneWidget);
      expect(find.text('All paid. Thanks!'), findsNothing);
    });

    testWidgets('someone not linked to a player yet is pointed to '
        '"Who are you here for?", not told they owe nothing', (tester) async {
      final dues = FakeDuesRepository()..charges.add(share('emma', 'Emma #7'));
      await pumpDues(tester, dues);
      await go(tester, '/g/a/dues');
      expect(find.text('Nothing owed.'), findsNothing);
      expect(find.text('On a team, dues are for players.'), findsOneWidget);
      await tester.tap(find.text('Who are you here for?'));
      await tester.pumpAndSettle();
      expect(find.byType(WhoAreYouScreen), findsOneWidget);
    });

    testWidgets('with a claim waiting, they are told so', (tester) async {
      final repo = FakePlayerRepository([
        ...players.players,
        const Player(
          id: PlayerId('mine'),
          groupId: GroupId('a'),
          displayName: 'Max Lee',
          status: PlayerStatus.pending,
          proposedBy: 'coach',
        ),
      ]);
      await pumpDues(tester, FakeDuesRepository(), playerRepo: repo);
      await go(tester, '/g/a/dues');
      expect(
        find.text('Your claim is waiting for a team admin.'),
        findsOneWidget,
      );
      expect(find.text('Nothing owed.'), findsNothing);
    });

    testWidgets('in a group, nothing owed is just that', (tester) async {
      await pumpDues(
        tester,
        FakeDuesRepository(),
        group: testGroup('a', 'Book club').copyWith(kind: GroupKind.group),
      );
      await go(tester, '/g/a/dues');
      expect(find.text('Nothing owed.'), findsOneWidget);
      expect(find.text('Who are you here for?'), findsNothing);
    });
  });

  group('text at 200% (SPEC §7.6)', () {
    testWidgets('How to pay, titles, handles and shares stay whole', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      const handle = '@thunder-softball-u14';
      final dues = FakeDuesRepository()
        ..payments = const DuesPayments(venmo: handle)
        ..dues.add(uniforms.copyWith(title: 'Spring fee', amountCents: 12500))
        ..charges.add(
          share('emma', 'Emma #7').copyWith(
            title: 'Spring fee',
            amountCents: 12500,
            dueOn: '2030-11-30',
          ),
        );
      await pumpDues(
        tester,
        dues,
        role: MemberRole.owner,
        size: const Size(375, 3000),
      );
      await go(tester, '/g/a/dues');
      expect(tester.takeException(), isNull);
      // At most two lines (30 × 2 each): "How to" and "pay", never a
      // letter or two at a time beside the button.
      expect(
        tester.getSize(find.text('How to pay')).height,
        lessThanOrEqualTo(120),
      );
      // The title breaks between words, its amount under it.
      expect(
        tester.getSize(find.text('Spring fee')).height,
        lessThanOrEqualTo(88),
      );
      expect(
        tester
            .renderObject<RenderParagraph>(find.text(handle))
            .didExceedMaxLines,
        isFalse,
      );
      await go(tester, '/g/a/dues/d0');
      expect(
        tester
            .renderObject<RenderParagraph>(find.textContaining('Due Nov 30'))
            .didExceedMaxLines,
        isFalse,
      );
    });
  });
}
