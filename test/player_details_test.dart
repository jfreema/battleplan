// Player details for coaches (PLAYER-12): the player card's Details for the
// team's admins and linked members only, the edit form and its medical
// consent, ages on the roster for admins, and archived teams read-only.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/auth/domain/auth_user.dart';
import 'package:battleplan/features/groups/domain/group.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/domain/player_details.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

/// Refuses every save, as the rules do when access was lost meanwhile.
class _RefusingDetails extends FakePlayerRepository {
  new(super.players, this.failure);

  final AppFailure failure;

  @override
  Future<void> savePlayerDetails(
    PlayerDetails details, {
    required UserId by,
    PlayerDetails? stored,
  }) async => throw failure;
}

void main() {
  const team = GroupId('y');
  const emmaId = PlayerId('emma');
  const emma = Player(
    id: emmaId,
    groupId: team,
    displayName: 'Emma Rodriguez',
    jerseyNumber: '7',
  );
  final youth = {'y': testGroup('y', 'Lightning U10')};
  final people = [
    testMembership('y', 'coach', role: MemberRole.owner, name: 'Jordan'),
    testMembership('y', 'maria', name: 'Maria Rodriguez'),
    testMembership('y', 'emma1', name: 'Emma R'),
    testMembership('y', 'sam', name: 'Sam Lee'),
  ];
  const consentLine =
      "I'm this player or their parent or guardian (or a team admin with the "
      "family's permission), and I agree to share this with the team's "
      'admins.';

  final today = DateTime.now();
  // The first of last month, 12 years back: 12 whatever day it is.
  final born = DateTime.utc(today.year - 12, today.month - 1);
  final full = PlayerDetails(
    playerId: emmaId,
    groupId: team,
    dateOfBirth: formatDateOfBirth(born),
    emergencyContacts: const [
      EmergencyContact(
        name: 'Maria Rodriguez',
        phone: '+1 (555) 010-0199',
        relationship: 'Mom',
      ),
    ],
    medicalNotes: 'Peanut allergy',
    medicalConsentAt: DateTime(2026),
    medicalConsentBy: 'maria',
    notes: 'Wears glasses',
  );

  /// Emma, with Maria as her guardian and the member emma1 as Emma
  /// herself.
  FakePlayerRepository emmaTeam({PlayerDetails? details}) {
    final repo = FakePlayerRepository([emma])
      ..links.addAll(const [
        GuardianLink(playerId: emmaId, groupId: team, uid: UserId('maria')),
        GuardianLink(
          playerId: emmaId,
          groupId: team,
          uid: UserId('emma1'),
          relation: PlayerRelation.self,
        ),
      ]);
    if (details != null) repo.details[emmaId] = details;
    return repo;
  }

  AuthUser user(String uid, {bool superAdmin = false}) => AuthUser(
    uid: uid,
    email: '$uid@example.com',
    emailVerified: true,
    isSuperAdmin: superAdmin,
  );

  Future<void> go(WidgetTester tester, String path) async {
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
    await tester.pumpAndSettle();
  }

  /// Emma's card as [uid].
  Future<void> openCard(
    WidgetTester tester,
    String uid,
    FakePlayerRepository repo, {
    Map<String, Group>? groups,
    FakeLinkOpener? linkOpener,
  }) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(user: user(uid)),
      groups: groups ?? youth,
      memberships: people,
      playerRepo: repo,
      linkOpener: linkOpener,
    );
    await go(tester, '/g/y/roster/players/emma');
  }

  Future<void> edit(WidgetTester tester) async {
    await tester.tap(find.text('Edit details'));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  group('who sees Details (PLAYER-12)', () {
    testWidgets("other members don't, and their app never asks", (
      tester,
    ) async {
      final repo = emmaTeam(details: full);
      await openCard(tester, 'sam', repo);
      expect(find.text('Emma Rodriguez'), findsWidgets);
      expect(find.text('Details'), findsNothing);
      expect(find.text('Date of birth'), findsNothing);
      expect(find.text('Peanut allergy'), findsNothing);
      expect(find.text('Edit details'), findsNothing);
      // Not on the roster either, nor by going to the form.
      await go(tester, '/g/y/roster');
      expect(find.textContaining('Age 12'), findsNothing);
      await go(tester, '/g/y/roster/players/emma/details');
      expect(find.text("You can't do that on this team."), findsOneWidget);
      expect(repo.detailsReads, isEmpty);
    });

    testWidgets("a super admin who isn't on the team sees them, read-only", (
      tester,
    ) async {
      final repo = emmaTeam(details: full);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: user('boss', superAdmin: true)),
        groups: {...youth, 'a': testGroup('a', 'Home team')},
        memberships: [
          ...people,
          testMembership('a', 'boss', role: MemberRole.owner),
        ],
        playerRepo: repo,
      );
      await go(tester, '/g/y/roster/players/emma');
      expect(find.text('Remove player'), findsOneWidget);
      // For support (§3): shown, but never changed.
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Peanut allergy'), findsOneWidget);
      expect(find.text('Edit details'), findsNothing);
      await go(tester, '/g/y/roster/players/emma/details');
      expect(find.text("You can't do that on this team."), findsOneWidget);
      await go(tester, '/g/y/roster');
      expect(find.textContaining('Age 12'), findsOneWidget);
      expect(repo.detailsReads, unorderedEquals(['player emma', 'team y']));
    });

    testWidgets('admins see age, contacts that call, and notes', (
      tester,
    ) async {
      final repo = emmaTeam(details: full);
      final opener = FakeLinkOpener();
      await openCard(tester, 'coach', repo, linkOpener: opener);
      expect(find.text('Details'), findsOneWidget);
      expect(
        find.text(
          "Only the team's admins and the people linked to this player see "
          'these.',
        ),
        findsOneWidget,
      );
      final dates = MaterialLocalizations.of(
        tester.element(find.text('Details')),
      );
      expect(
        find.text('${dates.formatShortDate(born)} · Age 12'),
        findsOneWidget,
      );
      expect(find.text('Emergency contacts'), findsOneWidget);
      expect(find.text('Mom · +1 (555) 010-0199'), findsOneWidget);
      expect(find.text('Peanut allergy'), findsOneWidget);
      expect(find.text('Wears glasses'), findsOneWidget);
      expect(find.text('Edit details'), findsOneWidget);
      // Tap-to-call opens the phone app with the number's digits.
      await tester.tap(find.byTooltip('Call Maria Rodriguez'));
      await tester.pumpAndSettle();
      expect(opener.opened, [Uri.parse('tel:+15550100199')]);
      // The roster under the card asks for the team's, for ages.
      expect(repo.detailsReads, unorderedEquals(['player emma', 'team y']));
    });

    for (final (who, uid) in [
      ('a guardian', 'maria'),
      ('the player', 'emma1'),
    ]) {
      testWidgets('$who linked to the player sees and edits them', (
        tester,
      ) async {
        final repo = emmaTeam(details: full);
        await openCard(tester, uid, repo);
        expect(find.text('Details'), findsOneWidget);
        expect(find.text('Peanut allergy'), findsOneWidget);
        expect(find.text('Edit details'), findsOneWidget);
        expect(repo.detailsReads, ['player emma']);
      });
    }

    testWidgets('nothing yet says so', (tester) async {
      await openCard(tester, 'coach', emmaTeam());
      expect(find.text('No details yet.'), findsOneWidget);
      expect(find.text('Edit details'), findsOneWidget);
      // The date of birth row is there, with a dash.
      expect(find.widgetWithText(ListTile, 'Date of birth'), findsOneWidget);
    });

    testWidgets('the date of birth is with the number, not in Details', (
      tester,
    ) async {
      await openCard(
        tester,
        'coach',
        emmaTeam(
          details: const PlayerDetails(
            playerId: emmaId,
            groupId: team,
            dateOfBirth: '2014-03-03',
          ),
        ),
      );
      final dates = MaterialLocalizations.of(
        tester.element(find.text('Details')),
      );
      final born = DateTime.utc(2014, 3, 3);
      final row = find.widgetWithText(ListTile, 'Date of birth');
      expect(row, findsOneWidget);
      expect(
        find.descendant(
          of: row,
          matching: find.textContaining(dates.formatShortDate(born)),
        ),
        findsOneWidget,
      );
      // It sits right under the number, above Details.
      expect(
        tester.getTopLeft(row).dy,
        greaterThan(tester.getTopLeft(find.text('Number')).dy),
      );
      expect(
        tester.getTopLeft(row).dy,
        lessThan(tester.getTopLeft(find.text('Details')).dy),
      );
      // Nothing else is filled in yet.
      expect(find.text('No details yet.'), findsOneWidget);
    });
  });

  group('the details form (PLAYER-12)', () {
    testWidgets('a date of birth from the picker, a contact needing a name '
        'and phone, and medical notes needing consent', (tester) async {
      final repo = emmaTeam();
      await openCard(tester, 'maria', repo);
      await edit(tester);

      // The picker refuses today and later, and over 100 years ago.
      await tester.tap(find.text('Date of birth'));
      await tester.pumpAndSettle();
      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(picker.lastDate, DateTime(today.year, today.month, today.day - 1));
      expect(
        picker.firstDate,
        DateTime(today.year - 100, today.month, today.day),
      );
      // It opens on the years; pick one, then a day.
      await tester.tap(find.text('${today.year - 12}'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      final picked = formatDateOfBirth(
        DateTime(today.year - 12, today.month, 15),
      );
      expect(
        find.textContaining('Age ${ageOn(picked, today)}'),
        findsOneWidget,
      );

      // A contact needs a phone as well as a name.
      await tester.tap(find.text('Add an emergency contact'));
      await tester.pumpAndSettle();
      expect(find.text('Emergency contact 1'), findsOneWidget);
      await tester.enterText(field('Name'), 'Luis Rodriguez');
      await save(tester);
      expect(find.text('Enter a phone number.'), findsOneWidget);
      expect(repo.calls, isEmpty);
      await tester.enterText(field('Phone'), '555-0101');
      await tester.enterText(field('Relationship (optional)'), 'Dad');
      await tester.pumpAndSettle();
      expect(find.text('Enter a phone number.'), findsNothing);

      // New medical notes need the consent line checked.
      expect(find.text(consentLine), findsNothing);
      await tester.enterText(field('Medical notes'), 'Peanut allergy');
      await tester.pumpAndSettle();
      expect(find.text(consentLine), findsOneWidget);
      await save(tester);
      expect(
        find.text('Check the box to share the medical notes.'),
        findsOneWidget,
      );
      expect(repo.calls, isEmpty);
      await tester.tap(find.text(consentLine));
      await tester.enterText(field('Notes'), 'Wears glasses');
      await save(tester);

      expect(repo.calls, ['saveDetails emma record']);
      expect(find.text('Details saved'), findsOneWidget);
      final saved = repo.details[emmaId]!;
      expect(saved.dateOfBirth, picked);
      expect(saved.emergencyContacts, const [
        EmergencyContact(
          name: 'Luis Rodriguez',
          phone: '555-0101',
          relationship: 'Dad',
        ),
      ]);
      expect(saved.medicalNotes, 'Peanut allergy');
      expect(saved.medicalConsentBy, 'maria');
      expect(saved.notes, 'Wears glasses');
      // Back on the card, which shows them.
      expect(find.text('Dad · 555-0101'), findsOneWidget);
      expect(find.text('Wears glasses'), findsOneWidget);
    });

    testWidgets('a name is needed too, and only 2 contacts', (tester) async {
      final repo = emmaTeam();
      await openCard(tester, 'coach', repo);
      await edit(tester);
      await tester.tap(find.text('Add an emergency contact'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Phone'), '555-0101');
      await save(tester);
      expect(find.text('Enter a name.'), findsOneWidget);
      await tester.tap(find.text('Add an emergency contact'));
      await tester.pumpAndSettle();
      expect(find.text('Emergency contact 2'), findsOneWidget);
      expect(find.text('Add an emergency contact'), findsNothing);
      // A phone with nothing to dial isn't one.
      await tester.enterText(field('Name').first, 'Luis');
      await tester.enterText(field('Name').last, 'Ana');
      await tester.enterText(field('Phone').last, 'call me');
      await save(tester);
      expect(find.text('Enter a phone number.'), findsOneWidget);
      expect(repo.calls, isEmpty);
    });

    testWidgets('changed medical notes ask again; unchanged keep the consent; '
        'cleared clear it', (tester) async {
      final repo = emmaTeam(details: full);
      await openCard(tester, 'coach', repo);
      await edit(tester);
      expect(find.text(consentLine), findsNothing);
      await tester.enterText(field('Medical notes'), 'Peanut and egg allergy');
      await tester.pumpAndSettle();
      expect(find.text(consentLine), findsOneWidget);
      // Back as it was: nothing new to agree to.
      await tester.enterText(field('Medical notes'), 'Peanut allergy');
      await tester.pumpAndSettle();
      expect(find.text(consentLine), findsNothing);
      await tester.enterText(field('Notes'), 'Wears glasses, bats left');
      await save(tester);
      expect(repo.calls, ['saveDetails emma keep']);
      expect(repo.details[emmaId]!.medicalConsentBy, 'maria');
      expect(find.text('Wears glasses, bats left'), findsOneWidget);

      await edit(tester);
      await tester.enterText(field('Medical notes'), 'Peanut and egg allergy');
      await tester.pumpAndSettle();
      await tester.tap(find.text(consentLine));
      await save(tester);
      expect(repo.calls.last, 'saveDetails emma record');
      expect(repo.details[emmaId]!.medicalConsentBy, 'coach');

      await edit(tester);
      await tester.enterText(field('Medical notes'), '');
      await tester.pumpAndSettle();
      expect(find.text(consentLine), findsNothing);
      await save(tester);
      expect(repo.calls.last, 'saveDetails emma clear');
      expect(repo.details[emmaId]!.medicalNotes, isNull);
      expect(repo.details[emmaId]!.medicalConsentAt, isNull);
      expect(repo.details[emmaId]!.medicalConsentBy, isNull);
    });

    testWidgets('clearing everything removes the details', (tester) async {
      final repo = emmaTeam(details: full);
      await openCard(tester, 'maria', repo);
      await edit(tester);
      await tester.tap(find.byTooltip('Clear date of birth'));
      await tester.pumpAndSettle();
      expect(find.text('Not set'), findsOneWidget);
      await tester.tap(find.byTooltip('Remove contact'));
      await tester.pumpAndSettle();
      // A contact left blank is dropped rather than refused.
      await tester.tap(find.text('Add an emergency contact'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Medical notes'), '');
      await tester.enterText(field('Notes'), ' ');
      await save(tester);
      expect(repo.calls, ['deleteDetails emma']);
      expect(repo.details, isEmpty);
      expect(find.text('No details yet.'), findsOneWidget);
    });

    testWidgets('a refused save says so and stays on the form', (tester) async {
      for (final (failure, message) in [
        (const PermissionDenied(), "You can't do that on this team."),
        (const Offline(), "Couldn't save the details. Try again."),
      ]) {
        final repo = _RefusingDetails([emma], failure)
          ..links.add(
            const GuardianLink(
              playerId: emmaId,
              groupId: team,
              uid: UserId('maria'),
            ),
          );
        await openCard(tester, 'maria', repo);
        await edit(tester);
        await tester.enterText(field('Notes'), 'Lefty');
        await save(tester);
        expect(find.text(message), findsOneWidget);
        expect(find.text('Medical notes'), findsWidgets);
      }
    });

    testWidgets('Cancel leaves without saving', (tester) async {
      final repo = emmaTeam(details: full);
      await openCard(tester, 'coach', repo);
      await edit(tester);
      await tester.enterText(field('Notes'), 'Changed');
      await tester.tap(find.byTooltip('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.calls, isEmpty);
      expect(find.text('Wears glasses'), findsOneWidget);
    });
  });

  testWidgets('an archived team shows details without Edit (PLAYER-12)', (
    tester,
  ) async {
    final repo = emmaTeam(details: full);
    await openCard(
      tester,
      'coach',
      repo,
      groups: {
        'y': testGroup(
          'y',
          'Lightning U10',
        ).copyWith(archivedAt: DateTime(2026)),
      },
    );
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Peanut allergy'), findsOneWidget);
    expect(find.text('Edit details'), findsNothing);
    await go(tester, '/g/y/roster/players/emma/details');
    expect(find.text("You can't do that on this team."), findsOneWidget);
  });

  group('ages on the roster (PLAYER-12)', () {
    testWidgets("admins see each player's age, from one team list", (
      tester,
    ) async {
      final repo = emmaTeam(details: full);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: user('coach')),
        groups: youth,
        memberships: people,
        playerRepo: repo,
      );
      await go(tester, '/g/y/roster');
      expect(
        find.text('Age 12 · Maria Rodriguez, Emma R (player)'),
        findsOneWidget,
      );
      expect(repo.detailsReads, ['team y']);
    });

    testWidgets("linked members don't, and don't ask", (tester) async {
      final repo = emmaTeam(details: full);
      await pumpApp(
        tester,
        auth: FakeAuthRepository(user: user('maria')),
        groups: youth,
        memberships: people,
        playerRepo: repo,
      );
      await go(tester, '/g/y/roster');
      expect(find.text('Maria Rodriguez, Emma R (player)'), findsOneWidget);
      expect(find.textContaining('Age 12'), findsNothing);
      expect(repo.detailsReads, isEmpty);
    });
  });

  // The form waits for who may edit before it asks for anything.
  testWidgets('the form for a player who is gone says so', (tester) async {
    final repo = emmaTeam();
    await openCard(tester, 'coach', repo);
    await go(tester, '/g/y/roster/players/gone/details');
    expect(find.text("This player isn't on the team anymore."), findsOneWidget);
  });
}
