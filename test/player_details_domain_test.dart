// Player details (PLAYER-12): ages from a date of birth, the dates the app
// takes, who sees them, and what's saved.
import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:battleplan/features/players/domain/player_details.dart';
import 'package:flutter_test/flutter_test.dart';

const _emma = PlayerId('emma');
const _team = GroupId('y');

PlayerDetails _details({String? notes}) =>
    PlayerDetails(playerId: _emma, groupId: _team, notes: notes);

void main() {
  group('ageOn', () {
    test('turns a year older on the birthday', () {
      expect(ageOn('2014-03-03', DateTime(2026, 3, 2)), 11);
      expect(ageOn('2014-03-03', DateTime(2026, 3, 3)), 12);
      expect(ageOn('2014-03-03', DateTime(2026, 3, 4)), 12);
      expect(ageOn('2014-03-03', DateTime(2026, 2, 28)), 11);
      expect(ageOn('2014-03-03', DateTime(2026, 4)), 12);
    });

    test('around the new year', () {
      expect(ageOn('2014-12-31', DateTime(2026, 12, 30)), 11);
      expect(ageOn('2014-12-31', DateTime(2026, 12, 31)), 12);
      expect(ageOn('2014-01-01', DateTime(2025, 12, 31)), 11);
      expect(ageOn('2014-01-01', DateTime(2026)), 12);
    });

    test('born on Feb 29: a year older on Mar 1 in other years', () {
      expect(ageOn('2012-02-29', DateTime(2013, 2, 28)), 0);
      expect(ageOn('2012-02-29', DateTime(2013, 3)), 1);
      expect(ageOn('2012-02-29', DateTime(2016, 2, 28)), 3);
      expect(ageOn('2012-02-29', DateTime(2016, 2, 29)), 4);
      expect(ageOn('2012-02-29', DateTime(2026, 2, 28)), 13);
      expect(ageOn('2012-02-29', DateTime(2026, 3)), 14);
    });

    test('uses only the calendar day, not the time', () {
      expect(ageOn('2014-03-03', DateTime(2026, 3, 2, 23, 59)), 11);
      expect(ageOn('2014-03-03', DateTime(2026, 3, 3, 0, 1)), 12);
    });

    test('a newborn is 0; no age before birth or without a real day', () {
      expect(ageOn('2026-03-03', DateTime(2026, 3, 3)), 0);
      expect(ageOn('2026-03-03', DateTime(2026, 3, 2)), isNull);
      expect(ageOn('2016-02-30', DateTime(2026)), isNull);
      expect(ageOn('2015-02-29', DateTime(2026)), isNull);
      expect(ageOn('2014-3-3', DateTime(2026)), isNull);
      expect(ageOn('03/03/2014', DateTime(2026)), isNull);
      expect(ageOn('', DateTime(2026)), isNull);
    });

    test('details give the age on a day when they have a birthday', () {
      final d = _details().copyWith(dateOfBirth: '2014-03-03');
      expect(d.ageAt(DateTime(2026, 10, 12)), 12);
      expect(_details().ageAt(DateTime(2026, 10, 12)), isNull);
    });
  });

  group('dates of birth', () {
    test('parse and format as YYYY-MM-DD', () {
      expect(parseDateOfBirth('2014-03-03'), DateTime.utc(2014, 3, 3));
      expect(parseDateOfBirth('2012-02-29'), DateTime.utc(2012, 2, 29));
      expect(parseDateOfBirth('2014-13-01'), isNull);
      expect(parseDateOfBirth('2014-00-10'), isNull);
      expect(parseDateOfBirth('2014-04-31'), isNull);
      expect(formatDateOfBirth(DateTime(2014, 3, 3)), '2014-03-03');
      expect(formatDateOfBirth(DateTime.utc(999, 12, 31)), '0999-12-31');
    });

    test('from 100 years ago to yesterday', () {
      final today = DateTime(2026, 10, 12, 9);
      final range = dateOfBirthRange(today);
      expect(range.last, DateTime(2026, 10, 11));
      expect(range.first, DateTime(2026 - Limits.playerAgeMaxYears, 10, 12));
      expect(dateOfBirthAllowed('2026-10-11', today), isTrue);
      // Today and later are refused: today hasn't started in UTC yet east
      // of it, and the rules want a day that has.
      expect(dateOfBirthAllowed('2026-10-12', today), isFalse);
      expect(dateOfBirthAllowed('2027-01-01', today), isFalse);
      expect(dateOfBirthAllowed('1926-10-12', today), isTrue);
      expect(dateOfBirthAllowed('1926-10-11', today), isFalse);
      expect(dateOfBirthAllowed('2016-02-30', today), isFalse);
    });

    test('the range on Feb 29 and on the first of a month', () {
      final leap = dateOfBirthRange(DateTime(2028, 2, 29));
      expect(leap.last, DateTime(2028, 2, 28));
      expect(leap.first, DateTime(1928, 2, 29));
      // 1900 had no Feb 29, so the range starts the day after Feb 28.
      expect(dateOfBirthRange(DateTime(2000, 2, 29)).first, DateTime(1900, 3));
      expect(dateOfBirthRange(DateTime(2026, 3)).last, DateTime(2026, 2, 28));
    });
  });

  group('who sees details', () {
    final links = [
      const GuardianLink(playerId: _emma, groupId: _team, uid: UserId('maria')),
      const GuardianLink(
        playerId: _emma,
        groupId: _team,
        uid: UserId('emma1'),
        relation: PlayerRelation.self,
      ),
      const GuardianLink(
        playerId: PlayerId('liam'),
        groupId: _team,
        uid: UserId('sam'),
      ),
    ];

    test("the team's admins, and members linked to the player", () {
      expect(
        seesPlayerDetails('coach', _emma, teamAdmin: true, links: links),
        isTrue,
      );
      expect(
        seesPlayerDetails('maria', _emma, teamAdmin: false, links: links),
        isTrue,
      );
      expect(
        seesPlayerDetails('emma1', _emma, teamAdmin: false, links: links),
        isTrue,
      );
    });

    test('nobody else, even linked to another player', () {
      expect(
        seesPlayerDetails('sam', _emma, teamAdmin: false, links: links),
        isFalse,
      );
      expect(
        seesPlayerDetails('jo', _emma, teamAdmin: false, links: links),
        isFalse,
      );
      expect(
        seesPlayerDetails(null, _emma, teamAdmin: false, links: links),
        isFalse,
      );
    });
  });

  group('what is saved', () {
    test('trimmed, blanks as null, empty contacts dropped', () {
      const d = PlayerDetails(
        playerId: _emma,
        groupId: _team,
        dateOfBirth: ' ',
        emergencyContacts: [
          EmergencyContact(
            name: ' Maria ',
            phone: ' 555-0100 ',
            relationship: ' ',
          ),
          EmergencyContact(name: ' ', phone: ''),
          EmergencyContact(
            name: 'Luis',
            phone: '555-0101',
            relationship: 'Dad',
          ),
        ],
        notes: ' Wears glasses ',
      );
      final c = d.cleaned;
      expect(c.dateOfBirth, isNull);
      expect(c.emergencyContacts, const [
        EmergencyContact(name: 'Maria', phone: '555-0100'),
        EmergencyContact(name: 'Luis', phone: '555-0101', relationship: 'Dad'),
      ]);
      expect(c.notes, 'Wears glasses');
      expect(d.isEmpty, isFalse);
    });

    test('nothing filled in is empty', () {
      expect(_details(notes: ' ').isEmpty, isTrue);
      expect(
        const PlayerDetails(
          playerId: _emma,
          groupId: _team,
          emergencyContacts: [EmergencyContact(name: '', phone: ' ')],
        ).isEmpty,
        isTrue,
      );
      expect(_details().copyWith(dateOfBirth: '2014-03-03').isEmpty, isFalse);
      expect(blankToNull(null), isNull);
    });

    test('a contact calls its digits, keeping a leading +', () {
      expect(
        const EmergencyContact(
          name: 'Maria',
          phone: '+1 (555) 010-0199',
        ).telUri,
        Uri.parse('tel:+15550100199'),
      );
      expect(dialable('(555) 010-0199'), '5550100199');
      expect(hasDialableDigits('555'), isTrue);
      expect(hasDialableDigits('call me'), isFalse);
    });
  });
}
