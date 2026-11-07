// Dues (DUES-1 to DUES-3): admins add a due for every player (or member in
// a group), record what each person paid, a part at a time or all at once,
// see who owes what by due and by person, and share how to pay; everyone
// else sees only what they or their players owe, and what they've paid.
import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/widgets/back_chevron.dart';
import 'package:battleplan/core/widgets/skeleton.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/dues/domain/due.dart';
import 'package:battleplan/features/dues/presentation/dues_screen.dart';
import 'package:battleplan/features/dues/presentation/dues_widgets.dart';
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
      expect(t, (
        paid: 1,
        partly: 0,
        count: 3,
        chargedCents: 3000,
        paidCents: 1000,
        owedCents: 2000,
      ));
      expect(venmoUser('@thunder-u14'), 'thunder-u14');
      expect(cashTag(r'$Thunder'), 'Thunder');
    });

    group('partial payments (DUES-2)', () {
      DueCharge c({
        DueStatus status = DueStatus.owed,
        List<int>? paid,
        int amount = 4500,
        String name = 'P',
        String id = 'p',
        String title = 'Fee',
      }) => DueCharge(
        id: 'd_$id',
        groupId: const GroupId('a'),
        dueId: 'd',
        title: title,
        amountCents: amount,
        participantType: ParticipantType.player,
        participantId: id,
        participantName: name,
        status: status,
        payments: [
          for (final (i, cents) in (paid ?? const <int>[]).indexed)
            DuePayment(id: 'pay-$i', amountCents: cents, paidOn: '2026-11-05'),
        ],
        recordedCents: paid?.fold<int>(0, (a, b) => a + b),
      );

      test("a share's paid, left, and state, old shares too", () {
        final owes = c();
        expect(
          (owes.paidCents, owes.owedCents, owes.state),
          (0, 4500, DueShareState.owes),
        );
        final partly = c(paid: [2000]);
        expect(
          (partly.paidCents, partly.owedCents, partly.state),
          (2000, 2500, DueShareState.partlyPaid),
        );
        expect(partly.partlyPaid, isTrue);
        final full = c(status: DueStatus.paid, paid: [2000, 2500]);
        expect(
          (full.paidCents, full.owedCents, full.state),
          (4500, 0, DueShareState.paid),
        );
        // Marked paid before payments were recorded: paid in full.
        final old = c(status: DueStatus.paid);
        expect(
          (old.paidCents, old.owedCents, old.recordsPayments),
          (4500, 0, false),
        );
        expect(old.state, DueShareState.paid);
        // Waived: only what was paid counts toward what's owed in all.
        final waived = c(status: DueStatus.waived, paid: [1000]);
        expect(
          (waived.chargedCents, waived.paidCents, waived.owedCents),
          (1000, 1000, 0),
        );
        expect(c(status: DueStatus.waived).chargedCents, 0);
        expect(c(status: DueStatus.waived).state, DueShareState.waived);
      });

      test('totals add paid in full, partly paid, and what is left', () {
        final t = dueTotals([
          c(paid: [2000]),
          c(),
          c(status: DueStatus.paid),
          c(status: DueStatus.waived, paid: [1000]),
        ]);
        expect(t, (
          paid: 1,
          partly: 1,
          count: 3,
          chargedCents: 4500 * 3 + 1000,
          paidCents: 2000 + 4500 + 1000,
          owedCents: 2500 + 4500,
        ));
      });

      test('a payment adds up, never over what is left, and a retry adds '
          'nothing', () {
        const p = DuePayment(
          id: 'new',
          amountCents: 2000,
          paidOn: '2026-11-06',
        );
        final one = addDuePayment(c(), p);
        expect((one.paidCents, one.status), (2000, DueStatus.owed));
        expect(one.payments.single, p);
        final rest = addDuePayment(
          c(paid: [2000]),
          p.copyWith(amountCents: 2500),
        );
        expect((rest.paidCents, rest.status), (4500, DueStatus.paid));
        // The same payment again (a retry): nothing changes.
        final again = addDuePayment(c(paid: [2000]), p.copyWith(id: 'pay-0'));
        expect(again.paidCents, 2000);
        expect(again.payments, hasLength(1));
        for (final (charge, amount, why) in [
          (c(paid: [2000]), 2501, DuePaymentRefusal.tooMuch),
          (c(), 0, DuePaymentRefusal.tooMuch),
          (c(), -5, DuePaymentRefusal.tooMuch),
          (c(status: DueStatus.paid), 100, DuePaymentRefusal.nothingLeft),
          (c(status: DueStatus.waived), 100, DuePaymentRefusal.nothingLeft),
          (
            c(amount: 100000, paid: List.filled(Limits.duePaymentsMax, 1)),
            1,
            DuePaymentRefusal.full,
          ),
        ]) {
          expect(
            () => addDuePayment(charge, p.copyWith(amountCents: amount)),
            throwsA(why),
          );
        }
      });

      test('a payment taken back comes off what was paid', () {
        final next = removeDuePayment(
          c(status: DueStatus.paid, paid: [1000, 2000, 1500]),
          'pay-1',
        );
        expect(next.payments.map((p) => p.id), ['pay-0', 'pay-2']);
        expect((next.paidCents, next.status), (2500, DueStatus.owed));
        // Waived stays waived; one already gone changes nothing.
        expect(
          removeDuePayment(
            c(status: DueStatus.waived, paid: [1000]),
            'pay-0',
          ).status,
          DueStatus.waived,
        );
        final same = removeDuePayment(c(paid: [1000]), 'gone');
        expect((same.paidCents, same.payments.length), (1000, 1));
        // Waived no more: paid when its payments cover it.
        expect(
          unwaivedStatus(c(status: DueStatus.waived, paid: [4500])),
          DueStatus.paid,
        );
        expect(
          unwaivedStatus(c(status: DueStatus.waived, paid: [100])),
          DueStatus.owed,
        );
        expect(unwaivedStatus(c(status: DueStatus.waived)), DueStatus.owed);
      });

      test('each person across every due, who owes most first', () {
        final people = duePeople([
          c(id: 'luke', name: 'Luke #7', title: 'Uniforms', paid: [2000]),
          c(id: 'luke', name: 'Luke #7', title: 'Photos', amount: 1500),
          c(id: 'alex', name: 'Alex #9', title: 'Uniforms'),
          c(
            id: 'emma',
            name: 'Emma #11',
            title: 'Uniforms',
            status: DueStatus.paid,
          ),
          c(id: 'zoe', name: 'Zoe', title: 'Uniforms'),
        ]);
        expect(people.map((p) => p.name), [
          'Alex #9',
          'Zoe',
          'Luke #7',
          'Emma #11',
        ]);
        final luke = people[2];
        expect(luke.totals.owedCents, 2500 + 1500);
        expect(luke.totals.chargedCents, 6000);
        expect(luke.totals.paidCents, 2000);
        // Most left first.
        expect(luke.shares.map((x) => x.title), ['Uniforms', 'Photos']);
        expect(people.last.totals.owedCents, 0);
      });

      test('shares sort by most left, then paid, then waived, by name', () {
        final list = [
          c(id: 'a', name: 'Ava', status: DueStatus.waived),
          c(id: 'b', name: 'Ben', status: DueStatus.paid),
          c(id: 'c', name: 'Cal', paid: [4000]),
          c(id: 'd', name: 'Dee'),
          c(id: 'e', name: 'Eve'),
        ]..sort(compareShares);
        expect(list.map((x) => x.participantName), [
          'Dee',
          'Eve',
          'Cal',
          'Ben',
          'Ava',
        ]);
        expect(dayKey(DateTime(2026, 3, 7)), '2026-03-07');
      });

      test('in words, for the row and for screen readers', () {
        expect(shareLine(l10n, c()), r'$45');
        expect(shareLine(l10n, c(paid: [2000])), r'$20 of $45 paid · $25 left');
        expect(shareLine(l10n, c(status: DueStatus.paid)), r'$45 paid');
        expect(
          shareLine(l10n, c(status: DueStatus.waived, paid: [2000])),
          r'$20 of $45 paid · rest waived',
        );
        expect(shareLine(l10n, c(status: DueStatus.waived)), r'$45');
        expect(shareSpoken(l10n, c()), r'owes $45');
        expect(shareSpoken(l10n, c(paid: [2000])), r'$25 left of $45');
        expect(shareSpoken(l10n, c(status: DueStatus.paid)), r'$45 paid');
        expect(
          shareSpoken(l10n, c(status: DueStatus.waived, paid: [2000])),
          r'$20 paid, rest waived',
        );
        expect(shareSpoken(l10n, c(status: DueStatus.waived)), 'Waived');
        expect(shareStateName(l10n, DueShareState.partlyPaid), 'Partly paid');
      });
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
    expect(find.text(r'0 of 2 paid · $90 left'), findsOneWidget);
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
    expect(find.text(r'0 of 1 paid · $45 left'), findsOneWidget);

    await tester.tap(find.text('Uniform fee'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Emma #7'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark paid in full'));
    await tester.pumpAndSettle();
    expect(dues.calls.last, 'pay d0_emma rest');
    expect(find.text('1 of 1 paid'), findsOneWidget);
    expect(dues.charges.single.payments.single.amountCents, 4500);
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
            // A precaution, not Apple's rule (store checklist, Store payment
            // rules): the iPhone app never links out to pay.
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
      expect(find.text('Undo waive'), findsNothing);
      tester.takeAnnouncements();
      await tester.tap(find.text('Mark paid in full'));
      await tester.pumpAndSettle();
      expect(
        tester.takeAnnouncements(),
        contains(isAccessibilityAnnouncement(r'Emma #7: $45 paid')),
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
          '1 person has paid some or all of it. What they paid stays '
          r'recorded, and anyone who paid less than $50 will owe the rest.',
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
      expect(find.text(r'0 of 2 paid · $90 left'), findsOneWidget);
      await tester.tap(find.text('Add people'));
      await tester.pumpAndSettle();
      expect(find.text("Everyone's already on this due."), findsOneWidget);
    });
  });

  group('partial payments (DUES-2)', () {
    DueCharge partly(DueCharge x, List<int> cents) => x.copyWith(
      payments: [
        for (final (i, c) in cents.indexed)
          DuePayment(
            id: 'pay-$i',
            amountCents: c,
            paidOn: '2026-11-0${i + 1}',
            by: 'coach',
            note: i == 0 ? 'Venmo' : '',
          ),
      ],
      recordedCents: cents.fold<int>(0, (a, b) => a + b),
      status: cents.fold<int>(0, (a, b) => a + b) >= x.amountCents
          ? DueStatus.paid
          : DueStatus.owed,
    );
    Finder inDialog(Finder f) =>
        find.descendant(of: find.byType(AlertDialog), matching: f);

    testWidgets('an admin records part of a share, then the rest in one tap, '
        'and takes back a mistake', (tester) async {
      final dues = FakeDuesRepository()
        ..dues.add(uniforms)
        ..charges.addAll([share('emma', 'Emma #7'), share('liam', 'Liam #9')]);
      await pumpCoach(tester, dues);
      await go(tester, '/g/a/dues/d0');
      tester.takeAnnouncements();
      await tester.tap(find.text('Emma #7'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Record a payment'));
      await tester.pumpAndSettle();
      // Today unless changed, and up to what's left.
      expect(inDialog(find.text('Today')), findsOneWidget);
      expect(inDialog(find.text(r'Up to $45')), findsOneWidget);
      expect(
        inDialog(find.text('Whoever owes it can see this too.')),
        findsOneWidget,
      );
      await tester.enterText(inDialog(find.byType(TextField)).at(0), '20');
      await tester.enterText(inDialog(find.byType(TextField)).at(1), 'Venmo');
      await tester.tap(inDialog(find.text('Save')));
      await tester.pumpAndSettle();
      expect(dues.calls, ['pay d0_emma 2000 Venmo']);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text(r'$20 of $45 paid · $25 left'), findsOneWidget);
      expect(find.text('Partly paid'), findsOneWidget);
      expect(find.text(r'0 of 2 paid · 1 partly paid · $70 left'), findsOne);
      expect(
        tester.takeAnnouncements(),
        contains(isAccessibilityAnnouncement(r'Emma #7: $25 left of $45')),
      );

      // The rest, in one tap.
      await tester.tap(find.text('Emma #7'));
      await tester.pumpAndSettle();
      expect(find.text(r'Records the $25 left'), findsOneWidget);
      expect(find.text('Waive the rest'), findsOneWidget);
      await tester.tap(find.text('Mark paid in full'));
      await tester.pumpAndSettle();
      expect(dues.calls.last, 'pay d0_emma rest');
      expect(find.text(r'$45 paid'), findsOneWidget);
      expect(dues.charges.first.payments.map((p) => p.amountCents), [
        2000,
        2500,
      ]);

      // The $20 was a mistake: newest first, each with Undo.
      await tester.tap(find.text('Emma #7'));
      await tester.pumpAndSettle();
      expect(find.text('Record a payment'), findsNothing);
      expect(find.text('PAYMENTS'), findsOneWidget);
      expect(find.text('Recorded by coach\nVenmo'), findsOneWidget);
      await tester.tap(find.byTooltip(r'Undo the $20 payment'));
      await tester.pumpAndSettle();
      expect(find.text('Undo this payment?'), findsOneWidget);
      expect(
        find.text(r'$20 comes off what Emma #7 has paid.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Undo payment'));
      await tester.pumpAndSettle();
      expect(dues.calls.last, startsWith('undo d0_emma '));
      expect(find.text(r'$25 of $45 paid · $20 left'), findsOneWidget);
    });

    testWidgets('more than what is left is refused before anything is saved', (
      tester,
    ) async {
      final dues = FakeDuesRepository()
        ..dues.add(uniforms)
        ..charges.add(partly(share('emma', 'Emma #7'), [2000]));
      await pumpCoach(tester, dues);
      await go(tester, '/g/a/dues/d0');
      await tester.tap(find.text('Emma #7'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Record a payment'));
      await tester.pumpAndSettle();
      for (final text in ['30', '0', 'abc']) {
        await tester.enterText(inDialog(find.byType(TextField)).at(0), text);
        await tester.tap(inDialog(find.text('Save')));
        await tester.pumpAndSettle();
        expect(
          find.text(r'Enter an amount up to the $25 left.'),
          findsOneWidget,
          reason: text,
        );
      }
      expect(dues.calls, isEmpty);
      // What's left exactly is fine, and pays it in full.
      await tester.enterText(inDialog(find.byType(TextField)).at(0), r'$25');
      await tester.tap(inDialog(find.text('Save')));
      await tester.pumpAndSettle();
      expect(dues.calls, ['pay d0_emma 2500']);
      expect(dues.charges.single.status, DueStatus.paid);
    });

    testWidgets('a share that changed under the dialog says so, and stays '
        'open to try again with the same payment', (tester) async {
      final dues = FakeDuesRepository()
        ..dues.add(uniforms)
        ..charges.add(share('emma', 'Emma #7'));
      await pumpCoach(tester, dues);
      await go(tester, '/g/a/dues/d0');
      await tester.tap(find.text('Emma #7'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Record a payment'));
      await tester.pumpAndSettle();
      await tester.enterText(inDialog(find.byType(TextField)).at(0), '10');
      dues.failWrites = const InvalidInput('tooMuch');
      await tester.tap(inDialog(find.text('Save')));
      await tester.pumpAndSettle();
      expect(
        find.text("This share just changed. Check what's left and try again."),
        findsOneWidget,
      );
      dues.failWrites = const InvalidInput('full');
      await tester.tap(inDialog(find.text('Save')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'This share has ${Limits.duePaymentsMax} payments, the most it '
          'can hold. Undo one and record it again with this one added, or '
          'waive the rest.',
        ),
        findsOneWidget,
      );
      dues.failWrites = const Offline();
      await tester.tap(inDialog(find.text('Save')));
      await tester.pumpAndSettle();
      expect(find.text("Couldn't save. Try again."), findsOneWidget);
      dues.failWrites = null;
      await tester.tap(inDialog(find.text('Save')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(dues.charges.single.payments.single.amountCents, 1000);
    });

    testWidgets('waiving the rest keeps what was paid; undo waive owes it '
        'again', (tester) async {
      final dues = FakeDuesRepository()
        ..dues.add(uniforms)
        ..charges.add(partly(share('emma', 'Emma #7'), [2000]));
      await pumpCoach(tester, dues);
      await go(tester, '/g/a/dues/d0');
      await tester.tap(find.text('Emma #7'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Waive the rest'));
      await tester.pumpAndSettle();
      expect(dues.calls, ['status d0_emma waived']);
      expect(find.text(r'$20 of $45 paid · rest waived'), findsOneWidget);
      expect(find.text('All waived'), findsOneWidget);
      await tester.tap(find.text('Emma #7'));
      await tester.pumpAndSettle();
      expect(find.text('Record a payment'), findsNothing);
      await tester.tap(find.text('Undo waive'));
      await tester.pumpAndSettle();
      expect(dues.calls.last, 'status d0_emma owed');
      expect(find.text(r'$20 of $45 paid · $25 left'), findsOneWidget);
    });

    testWidgets('a share marked paid before payments were recorded is paid in '
        'full, and can be marked not paid', (tester) async {
      final dues = FakeDuesRepository()
        ..dues.add(uniforms)
        ..charges.add(
          share('emma', 'Emma #7').copyWith(status: DueStatus.paid),
        );
      await pumpCoach(tester, dues);
      await go(tester, '/g/a/dues/d0');
      expect(find.text(r'$45 paid'), findsOneWidget);
      expect(find.text('1 of 1 paid'), findsOneWidget);
      await tester.tap(find.text('Emma #7'));
      await tester.pumpAndSettle();
      expect(find.text('Record a payment'), findsNothing);
      expect(find.text('PAYMENTS'), findsNothing);
      await tester.tap(find.text('Mark not paid'));
      await tester.pumpAndSettle();
      expect(dues.calls, ['status d0_emma owed']);
      expect(find.text('Owes'), findsOneWidget);
    });

    testWidgets("an archived team's payments can be seen, not changed", (
      tester,
    ) async {
      final dues = FakeDuesRepository()
        ..dues.add(uniforms)
        ..charges.add(partly(share('emma', 'Emma #7'), [2000]));
      await pumpDues(
        tester,
        dues,
        role: MemberRole.owner,
        group: testGroup('a', 'Thunder').copyWith(archivedAt: DateTime(2026)),
      );
      await go(tester, '/g/a/dues/d0');
      await tester.tap(find.text('Emma #7'));
      await tester.pumpAndSettle();
      expect(find.text('PAYMENTS'), findsOneWidget);
      expect(find.text('Record a payment'), findsNothing);
      expect(find.byTooltip(r'Undo the $20 payment'), findsNothing);
    });

    testWidgets('the amount of a due is never lowered below what someone '
        'paid; raising it asks first', (tester) async {
      final dues = FakeDuesRepository()
        ..dues.add(uniforms)
        ..charges.addAll([
          partly(share('emma', 'Emma #7'), [3000]),
          share('liam', 'Liam #9'),
        ]);
      await pumpCoach(tester, dues);
      await go(tester, '/g/a/dues/d0/edit');
      await tester.enterText(find.byType(TextField).at(1), '25');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          r'Emma #7 has already paid $30. Undo a payment on their share '
          'first, or keep the amount at least that.',
        ),
        findsOneWidget,
      );
      expect(dues.calls, isEmpty);
      await tester.enterText(find.byType(TextField).at(1), '60');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Change the amount?'), findsOneWidget);
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();
      expect(dues.calls, ['edit d0 Uniform fee 6000']);
    });

    testWidgets('a share marked paid before payments were recorded is marked '
        'not paid before the amount goes below it', (tester) async {
      final dues = FakeDuesRepository()
        ..dues.add(uniforms)
        ..charges.add(
          share('emma', 'Emma #7').copyWith(status: DueStatus.paid),
        );
      await pumpCoach(tester, dues);
      await go(tester, '/g/a/dues/d0/edit');
      await tester.enterText(find.byType(TextField).at(1), '40');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      // It has no payment to undo.
      expect(
        find.text(
          r'Emma #7 is marked paid at $45. Mark their share not paid first, '
          'or keep the amount at least that.',
        ),
        findsOneWidget,
      );
      expect(dues.calls, isEmpty);
    });

    testWidgets('at the most payments a share holds, Mark paid in full says '
        'so', (tester) async {
      final dues = FakeDuesRepository()
        ..dues.add(uniforms)
        ..charges.add(
          partly(
            share('emma', 'Emma #7'),
            List.filled(Limits.duePaymentsMax, 10),
          ),
        );
      await pumpCoach(tester, dues);
      await go(tester, '/g/a/dues/d0');
      await tester.tap(find.text('Emma #7'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark paid in full'));
      await tester.pumpAndSettle();
      // Not "This share just changed": paying the rest is one too many.
      expect(
        find.text(
          'This share has ${Limits.duePaymentsMax} payments, the most it '
          'can hold. Undo one and record it again with this one added, or '
          'waive the rest.',
        ),
        findsOneWidget,
      );
      expect(dues.charges.single.payments, hasLength(Limits.duePaymentsMax));
      expect(dues.charges.single.status, DueStatus.owed);
    });

    testWidgets('a payment recorded since the edit opened is refused by the '
        'server, and said so', (tester) async {
      final dues = FakeDuesRepository()
        ..dues.add(uniforms)
        ..charges.add(share('emma', 'Emma #7'))
        ..failWrites = const InvalidInput('due-amount-below-paid');
      await pumpCoach(tester, dues);
      await go(tester, '/g/a/dues/d0/edit');
      await tester.enterText(find.byType(TextField).at(1), '5');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Someone has already paid more than that. Undo a payment on their '
          'share first.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a guardian sees what they have paid and what is left', (
      tester,
    ) async {
      final dues = FakeDuesRepository()
        ..charges.addAll([
          partly(share('emma', 'Emma #7'), [2000]),
          share('emma', 'Emma #7', due: 'd1').copyWith(title: 'Photos'),
          share(
            'emma',
            'Emma #7',
            due: 'd2',
          ).copyWith(title: 'League fee', status: DueStatus.paid),
        ]);
      await pumpDues(tester, dues, playerRepo: linkedToEmma());
      await go(tester, '/g/a/dues');
      // $25 left on uniforms, and $45 for photos.
      expect(find.text(r'$70 owed'), findsOneWidget);
      expect(find.text(r'$20 of $45 paid · $25 left'), findsOneWidget);
      expect(find.text('Partly paid'), findsOneWidget);
      expect(find.text(r'$45 paid'), findsOneWidget);
      // No totals or Who owes what: that's the admins'.
      expect(find.text('Who owes what'), findsNothing);
      expect(find.text('Owed in all'.toUpperCase()), findsNothing);
    });
    testWidgets('a guardian opens a share to see its payments, and changes '
        'nothing', (tester) async {
      final dues = FakeDuesRepository()
        ..charges.addAll([
          partly(share('emma', 'Emma #7'), [2000]),
          share('emma', 'Emma #7', due: 'd1').copyWith(title: 'Photos'),
        ]);
      await pumpDues(tester, dues, playerRepo: linkedToEmma());
      await go(tester, '/g/a/dues');
      // With payments, a share is a button that opens them; without, it
      // isn't.
      expect(
        tester.getSemantics(find.text('Uniform fee')),
        isSemantics(isButton: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.text('Photos')),
        isNot(isSemantics(isButton: true)),
      );
      await tester.tap(find.text('Uniform fee'));
      await tester.pumpAndSettle();
      // Headed by what it's for, with each payment: its amount, day, who
      // recorded it, and its note.
      expect(find.text('Uniform fee'), findsNWidgets(2));
      expect(
        find.text(r'$20 of $45 paid · $25 left · Partly paid'),
        findsOneWidget,
      );
      expect(find.text('PAYMENTS'), findsOneWidget);
      expect(find.text(r'$20 · Nov 1'), findsOneWidget);
      expect(find.text('Recorded by Coach Lee\nVenmo'), findsOneWidget);
      expect(find.text('Record a payment'), findsNothing);
      expect(find.text('Mark paid in full'), findsNothing);
      expect(find.text('Waive the rest'), findsNothing);
      expect(find.byTooltip(r'Undo the $20 payment'), findsNothing);
      expect(dues.calls, isEmpty);
    });

    testWidgets('with shares for more than one player, the sheet says whose', (
      tester,
    ) async {
      final both = FakePlayerRepository(players.players)
        ..links.addAll([
          emmaLink,
          const GuardianLink(
            playerId: PlayerId('liam'),
            groupId: GroupId('a'),
            uid: UserId('coach'),
          ),
        ]);
      final dues = FakeDuesRepository()
        ..charges.addAll([
          partly(share('emma', 'Emma #7'), [2000]),
          share('liam', 'Liam #9'),
        ]);
      await pumpDues(tester, dues, playerRepo: both);
      await go(tester, '/g/a/dues');
      await tester.tap(find.textContaining('For Emma #7'));
      await tester.pumpAndSettle();
      expect(
        find.text(r'For Emma #7 · $20 of $45 paid · $25 left · Partly paid'),
        findsOneWidget,
      );
    });
  });

  group('who owes what (DUES-5)', () {
    // Two dues: uniforms for Emma (partly paid) and Liam, photos for both.
    FakeDuesRepository twoDues() => FakeDuesRepository()
      ..dues.addAll([
        uniforms,
        const Due(
          id: 'd1',
          groupId: GroupId('a'),
          title: 'Photos',
          amountCents: 1500,
        ),
      ])
      ..charges.addAll([
        share('emma', 'Emma #7').copyWith(
          payments: const [
            DuePayment(id: 'pay-0', amountCents: 2000, paidOn: '2026-11-05'),
          ],
          recordedCents: 2000,
        ),
        share('liam', 'Liam #9'),
        share(
          'emma',
          'Emma #7',
          due: 'd1',
        ).copyWith(title: 'Photos', amountCents: 1500, status: DueStatus.paid),
        share(
          'liam',
          'Liam #9',
          due: 'd1',
        ).copyWith(title: 'Photos', amountCents: 1500),
      ]);

    testWidgets('Dues shows owed in all, paid, and left, and Who owes what is '
        'one tap away', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCoach(tester, twoDues());
      await go(tester, '/g/a/dues');
      expect(find.text('OWED IN ALL'), findsOneWidget);
      expect(find.text(r'$120'), findsOneWidget);
      expect(find.text(r'$35'), findsOneWidget);
      expect(find.text(r'$85'), findsOneWidget);
      expect(
        find.bySemanticsLabel(r'$120 owed in all, $35 paid, $85 left'),
        findsOneWidget,
      );
      expect(find.text(r'0 of 2 paid · 1 partly paid · $70 left'), findsOne);
      expect(find.text(r'1 of 2 paid · $15 left'), findsOne);
      await tester.tap(find.text('Who owes what'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Everyone on a due, who owes the most first. Tap a due to record a '
          'payment.',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('each person, who owes most first, with every due they are on, '
        'read as one sentence', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCoach(tester, twoDues());
      await go(tester, '/g/a/dues/people');
      // Liam owes $60, Emma $25.
      expect(
        tester.getTopLeft(find.text('Liam #9')).dy,
        lessThan(tester.getTopLeft(find.text('Emma #7')).dy),
      );
      expect(find.text(r'$60 left'), findsOneWidget);
      expect(find.text(r'$0 of $60 paid'), findsOneWidget);
      expect(find.text(r'$25 left'), findsOneWidget);
      expect(find.text(r'$35 of $60 paid'), findsOneWidget);
      expect(
        find.bySemanticsLabel(r'Liam #9, $60 left of $60'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(r'Emma #7, Uniform fee, $25 left of $45'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(r'Emma #7, Photos, $15 paid'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(r'Liam #9, Photos, owes $15'),
        findsOneWidget,
      );
      // A tap opens the due, to record a payment, and comes back here.
      await tester.tap(find.text(r'$20 of $45 paid · $25 left'));
      await tester.pumpAndSettle();
      expect(find.byType(DueDetailScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BackChevron),
          matching: find.text('Who owes what'),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('with nothing left, a person says so', (tester) async {
      final dues = FakeDuesRepository()
        ..dues.add(uniforms)
        ..charges.add(
          share('emma', 'Emma #7').copyWith(status: DueStatus.paid),
        );
      await pumpCoach(tester, dues);
      await go(tester, '/g/a/dues/people');
      expect(find.text('Nothing left'), findsOneWidget);
      expect(find.text(r'$45 of $45 paid'), findsOneWidget);
    });

    testWidgets('with no dues, it says so', (tester) async {
      await pumpCoach(tester, FakeDuesRepository());
      await go(tester, '/g/a/dues/people');
      expect(find.text('No dues yet.'), findsOneWidget);
      await go(tester, '/g/a/dues');
      expect(find.text('Who owes what'), findsNothing);
    });

    testWidgets("is the admins': members are told so, and read nothing", (
      tester,
    ) async {
      final dues = twoDues();
      await pumpDues(tester, dues, playerRepo: linkedToEmma());
      await go(tester, '/g/a/dues/people');
      expect(find.text('Only admins see what everyone owes.'), findsOneWidget);
      expect(find.textContaining('Liam'), findsNothing);
    });

    testWidgets("when a due's shares can't load, it says so", (tester) async {
      final dues = twoDues()..failReads = true;
      await pumpCoach(tester, dues);
      await go(tester, '/g/a/dues/people');
      expect(
        find.text("Couldn't load this. Check your connection and try again."),
        findsOneWidget,
      );
    });

    testWidgets('at 200% text, nothing is cut off', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpDues(
        tester,
        twoDues(),
        role: MemberRole.owner,
        size: const Size(375, 3000),
      );
      await go(tester, '/g/a/dues');
      expect(tester.takeException(), isNull);
      await go(tester, '/g/a/dues/people');
      expect(tester.takeException(), isNull);
      await go(tester, '/g/a/dues/d0');
      await tester.tap(find.text('Emma #7'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Record a payment'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
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
      expect(find.text('Mark paid in full'), findsNothing);
      expect(find.text('Record a payment'), findsNothing);
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
