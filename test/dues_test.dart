// Dues (DUES-1 to DUES-3): admins add a due for every player (or member in
// a group), mark who paid, and share how to pay; everyone else sees only
// what they or their players owe.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/dues/domain/due.dart';
import 'package:battleplan/features/dues/presentation/dues_screen.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/l10n/gen/app_localizations_en.dart';
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
    expect(find.text(r'Enter an amount up to $10,000.'), findsOneWidget);
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
      expect(find.text(error), findsOneWidget);
      await go(tester, '/g/a/dues/d0');
      expect(find.text(error), findsOneWidget);
    });

    testWidgets('for a member', (tester) async {
      final dues = FakeDuesRepository()..failReads = true;
      await pumpCoach(tester, dues, role: MemberRole.member);
      await go(tester, '/g/a/dues');
      expect(find.text(error), findsOneWidget);
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
}
