import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/players/domain/player.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_details.freezed.dart';

/// Someone to call about a player in an emergency (PLAYER-12): a name and a
/// phone, and how they're related ("Mom") when given.
@freezed
abstract class EmergencyContact with _$EmergencyContact {
  const factory({
    required String name,
    required String phone,
    String? relationship,
  }) = _EmergencyContact;

  const new _();

  /// The phone as a `tel:` link for tap-to-call: its digits, with the
  /// leading + of an international number kept.
  Uri get telUri => Uri(scheme: 'tel', path: dialable(phone));
}

/// [phone]'s digits, with a leading + kept ("+1 (555) 010-0199" is
/// "+15550100199").
String dialable(String phone) {
  final digits = phone.replaceAll(RegExp('[^0-9]'), '');
  return phone.trim().startsWith('+') ? '+$digits' : digits;
}

/// Whether [phone] has a digit to dial (PLAYER-12).
bool hasDialableDigits(String phone) => RegExp('[0-9]').hasMatch(phone);

/// A player's optional details for coaches (PLAYER-12, `playerDetails`,
/// same ID as the player): date of birth, up to 2 emergency contacts,
/// medical notes, and other notes. Kept apart from the roster record
/// (PLAYER-10), so only the team's admins and the members linked to the
/// player ever read them.
@freezed
abstract class PlayerDetails with _$PlayerDetails {
  const factory({
    required PlayerId playerId,
    required GroupId groupId,

    /// 'YYYY-MM-DD': a calendar day, with no time or time zone.
    String? dateOfBirth,
    @Default(<EmergencyContact>[]) List<EmergencyContact> emergencyContacts,

    /// Allergies, conditions, and medications.
    String? medicalNotes,

    /// When and by whom the medical notes were shared, with the consent
    /// line, each time they were set or changed.
    DateTime? medicalConsentAt,
    String? medicalConsentBy,

    /// "Anything else coaches should know".
    String? notes,
    String? updatedBy,
    DateTime? updatedAt,
  }) = _PlayerDetails;

  const new _();

  /// The player's age on [day], or null without a date of birth.
  int? ageAt(DateTime day) => switch (dateOfBirth) {
    final dob? => ageOn(dob, day),
    null => null,
  };

  /// Whether nothing is filled in once [cleaned], so saving removes the
  /// details rather than keeping an empty record.
  bool get isEmpty {
    final c = cleaned;
    return c.dateOfBirth == null &&
        c.emergencyContacts.isEmpty &&
        c.medicalNotes == null &&
        c.notes == null;
  }

  /// The details as they're saved: text trimmed, blanks as null, and
  /// contacts with nothing filled in dropped.
  PlayerDetails get cleaned => copyWith(
    dateOfBirth: blankToNull(dateOfBirth),
    emergencyContacts: [
      for (final c in emergencyContacts)
        if (blankToNull(c.name) != null ||
            blankToNull(c.phone) != null ||
            blankToNull(c.relationship) != null)
          EmergencyContact(
            name: c.name.trim(),
            phone: c.phone.trim(),
            relationship: blankToNull(c.relationship),
          ),
    ],
    medicalNotes: blankToNull(medicalNotes),
    notes: blankToNull(notes),
  );
}

/// Whether [uid] sees and edits [playerId]'s details (PLAYER-12): the
/// team's admins, and the members linked to the player as the player or a
/// guardian. Nobody else, not even to know whether there are any; super
/// admins read them for support outside the player card.
bool seesPlayerDetails(
  String? uid,
  PlayerId playerId, {
  required bool teamAdmin,
  required Iterable<GuardianLink> links,
}) =>
    teamAdmin ||
    (uid != null &&
        links.any((l) => l.playerId == playerId && l.uid.value == uid));

/// [value] trimmed, or null when there's nothing in it.
String? blankToNull(String? value) {
  final t = value?.trim();
  return t == null || t.isEmpty ? null : t;
}

/// A 'YYYY-MM-DD' date of birth as that day at midnight UTC, or null when
/// it isn't a real day (such as 2016-02-30).
DateTime? parseDateOfBirth(String value) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (m == null) return null;
  final (y, mo, d) = (int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  final day = DateTime.utc(y, mo, d);
  // DateTime rolls Feb 30 over into March; a real day comes back as given.
  return day.year == y && day.month == mo && day.day == d ? day : null;
}

/// [day]'s calendar date as 'YYYY-MM-DD'.
String formatDateOfBirth(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// The age in whole years on [today]'s calendar date of someone born on
/// [dateOfBirth] ('YYYY-MM-DD'), or null when it isn't a real day or is
/// after [today]. A year older on each birthday; someone born on Feb 29 is
/// a year older on Mar 1 in other years.
int? ageOn(String dateOfBirth, DateTime today) {
  final born = parseDateOfBirth(dateOfBirth);
  if (born == null) return null;
  var age = today.year - born.year;
  // Before this year's birthday. A Feb 29 birthday counts as passed from
  // Mar 1, since (3, 1) comes after (2, 29).
  if (today.month < born.month ||
      (today.month == born.month && today.day < born.day)) {
    age--;
  }
  return age < 0 ? null : age;
}

/// The dates of birth the app takes on [today] (PLAYER-12): from
/// [Limits.playerAgeMaxYears] years ago to yesterday. Not today, since the
/// rules want the day's start in UTC to have passed, which it hasn't yet
/// early in the day east of UTC.
({DateTime first, DateTime last}) dateOfBirthRange(DateTime today) => (
  first: DateTime(
    today.year - Limits.playerAgeMaxYears,
    today.month,
    today.day,
  ),
  last: DateTime(today.year, today.month, today.day - 1),
);

/// Whether [dateOfBirth] ('YYYY-MM-DD') is a real day in
/// [dateOfBirthRange] on [today].
bool dateOfBirthAllowed(String dateOfBirth, DateTime today) {
  final born = parseDateOfBirth(dateOfBirth);
  if (born == null) return false;
  final range = dateOfBirthRange(today);
  final day = DateTime(born.year, born.month, born.day);
  return !day.isBefore(range.first) && !day.isAfter(range.last);
}

/// What saving does to the medical consent (PLAYER-12).
enum MedicalConsent {
  /// New or changed medical notes: the one saving them consents now, so
  /// the save records when and who.
  record,

  /// The medical notes and their consent stay as they are.
  keep,

  /// The medical notes are cleared, and their consent with them.
  clear,
}

/// What saving [medicalNotes] does to the consent, given what's [stored]
/// (PLAYER-12). Non-empty notes need consent the first time they're set and
/// whenever they change, and only then: the rules refuse a new consent on
/// unchanged notes, and want it unchanged otherwise.
MedicalConsent medicalConsentFor({
  required PlayerDetails? stored,
  required String? medicalNotes,
}) {
  final next = blankToNull(medicalNotes);
  if (next != null) {
    return next == blankToNull(stored?.medicalNotes)
        ? MedicalConsent.keep
        : MedicalConsent.record;
  }
  final hadAny =
      stored != null &&
      (blankToNull(stored.medicalNotes) != null ||
          stored.medicalConsentAt != null ||
          stored.medicalConsentBy != null);
  return hadAny ? MedicalConsent.clear : MedicalConsent.keep;
}

/// Whether saving [medicalNotes] needs the consent line checked
/// (PLAYER-12): they're entered or changed.
bool needsMedicalConsent({
  required PlayerDetails? stored,
  required String? medicalNotes,
}) =>
    medicalConsentFor(stored: stored, medicalNotes: medicalNotes) ==
    MedicalConsent.record;
