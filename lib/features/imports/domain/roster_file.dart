import 'dart:convert';

/// A player read from another app's roster export (SPEC IMPORT-11): the
/// name, number, and date of birth the add-players form takes, nothing
/// more. Contacts stay behind; parents link themselves by claiming the
/// player (PLAYER-3).
final class RosterRow {
  const new({required this.name, this.jerseyNumber, this.dateOfBirth});

  final String name;
  final String? jerseyNumber;

  /// 'YYYY-MM-DD'.
  final String? dateOfBirth;
}

/// What a roster file holds.
final class RosterFile {
  const new({
    required this.players,
    this.nonPlayers = 0,
    this.unreadable = 0,
    this.datesUnreadable = 0,
  });

  final List<RosterRow> players;

  /// Coaches, managers, and other non-players, left out.
  final int nonPlayers;

  /// Rows with no name.
  final int unreadable;

  /// Birthdates that weren't a real date before today; the player comes
  /// without one.
  final int datesUnreadable;
}

/// The file isn't a roster: no row of headers with a name column.
final class NotRosterFile implements Exception {
  const new();
}

/// The longest name and number the roster takes (functions players
/// handlers: name ≤ 60, number ≤ 4).
const int _nameMax = 60;
const int _numberMax = 4;

/// Reads a roster exported as CSV (TeamSnap's, or a spreadsheet saved as
/// CSV): a header row, then a row per member. Columns are found by their
/// headers, in any order: the name ("Name", or "First Name" and "Last
/// Name"), the number ("Jersey Number", "Number", "#"), and the date of
/// birth ("Birthdate", "Date of Birth", "DOB"). Members marked as
/// non-players, or whose role is coach, manager, or staff, are left out.
/// Throws [NotRosterFile].
RosterFile readRosterCsv(String text, {DateTime? today}) {
  final rows = _csv(text.replaceFirst('﻿', ''));
  final at = rows.indexWhere((r) => _Columns.of(r) != null);
  if (at < 0) throw const NotRosterFile();
  final columns = _Columns.of(rows[at])!;
  final now = today ?? DateTime.now();
  final players = <RosterRow>[];
  final seen = <String>{};
  var nonPlayers = 0;
  var unreadable = 0;
  var badDates = 0;
  for (final row in rows.skip(at + 1)) {
    if (row.every((c) => c.trim().isEmpty)) continue;
    String cell(int? i) => i == null || i >= row.length ? '' : row[i].trim();
    if (!columns.isPlayer(cell)) {
      nonPlayers++;
      continue;
    }
    var name = columns.full != null
        ? cell(columns.full)
        : '${cell(columns.first)} ${cell(columns.last)}';
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (name.isEmpty) {
      unreadable++;
      continue;
    }
    if (name.length > _nameMax) name = name.substring(0, _nameMax).trim();
    var number = cell(columns.number).replaceFirst(RegExp('^#'), '').trim();
    if (number.isEmpty || number.length > _numberMax) number = '';
    final rawDate = cell(columns.birth);
    final date = rawDate.isEmpty ? null : _dateOfBirth(rawDate, now);
    if (rawDate.isNotEmpty && date == null) badDates++;
    // The same player twice in one file comes once.
    if (!seen.add('${name.toLowerCase()}|$number')) continue;
    players.add(
      RosterRow(
        name: name,
        jerseyNumber: number.isEmpty ? null : number,
        dateOfBirth: date,
      ),
    );
  }
  return RosterFile(
    players: players,
    nonPlayers: nonPlayers,
    unreadable: unreadable,
    datesUnreadable: badDates,
  );
}

/// Where a roster's columns are.
final class _Columns {
  const new({
    required this.full,
    required this.first,
    required this.last,
    required this.number,
    required this.birth,
    required this.nonPlayer,
    required this.role,
  });

  final int? full;
  final int? first;
  final int? last;
  final int? number;
  final int? birth;

  /// A yes or no column: is this member a non-player?
  final int? nonPlayer;

  /// A column naming the member's role or type.
  final int? role;

  /// The columns in a header row, or null if it has no name column.
  static _Columns? of(List<String> header) {
    final keys = [for (final h in header) _key(h)];
    int? find(Set<String> names) {
      for (final (i, k) in keys.indexed) {
        if (names.contains(k)) return i;
      }
      return null;
    }

    final full = find({
      'name',
      'full name',
      'player name',
      'player',
      'member name',
    });
    final first = find({
      'first name',
      'first',
      'firstname',
      'player first name',
      'given name',
    });
    final last = find({
      'last name',
      'last',
      'lastname',
      'player last name',
      'surname',
      'family name',
    });
    if (full == null && (first == null || last == null)) return null;
    return _Columns(
      full: full,
      first: first,
      last: last,
      number: find({
        'jersey number',
        'jersey',
        'number',
        'jersey no',
        'uniform number',
        'uniform',
        'no',
      }),
      birth: find({
        'birthdate',
        'birthday',
        'date of birth',
        'dob',
        'birth date',
        'birth',
      }),
      nonPlayer: find({
        'non player',
        'nonplayer',
        'is non player',
        'non player yes no',
        // TeamSnap's own: "Non-Player (Y/N)".
        'non player y n',
      }),
      role: find({
        'role',
        'member type',
        'type',
        'position type',
        'player or non player',
      }),
    );
  }

  bool isPlayer(String Function(int?) cell) {
    final flag = cell(nonPlayer).toLowerCase();
    if (const {
      'yes',
      'y',
      'true',
      '1',
      'x',
      'non-player',
      'nonplayer',
    }.contains(flag)) {
      return false;
    }
    final kind = cell(role).toLowerCase();
    if (kind.isEmpty) return true;
    // TeamSnap's Member Type: Player, Coach, Manager, or Volunteer.
    if (const {'c', 'm', 'v'}.contains(kind)) return false;
    if (RegExp(r'non[\s-]?player').hasMatch(kind)) return false;
    return !RegExp(r'\b(coach|manager|staff|parent|admin|owner|volunteer)\b')
            .hasMatch(kind) ||
        RegExp(r'\bplayer\b').hasMatch(kind);
  }
}

/// A header, compared without case or punctuation ("Jersey #" is
/// "jersey").
String _key(String header) => header
    .toLowerCase()
    .replaceAll('#', ' number ')
    .replaceAll(RegExp('[^a-z0-9]+'), ' ')
    .trim();

const _months = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, //
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
};

/// [raw] as 'YYYY-MM-DD' when it's a real date of birth before [today],
/// at most 100 years back: 2014-03-09, 3/9/2014 (US order), 03-09-2014,
/// 3/9/14, March 9, 2014, or 9 Mar 2014.
String? _dateOfBirth(String raw, DateTime today) {
  final s = raw.trim().split(RegExp(r'[T ]\d{1,2}:')).first.trim();
  int? y;
  int? m;
  int? d;
  RegExpMatch? x;
  if ((x = RegExp(r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})$').firstMatch(s)) !=
      null) {
    (y, m, d) = (int.parse(x![1]!), int.parse(x[2]!), int.parse(x[3]!));
  } else if ((x = RegExp(r'^(\d{1,2})[-/.](\d{1,2})[-/.](\d{2}|\d{4})$')
          .firstMatch(s)) !=
      null) {
    (m, d, y) = (int.parse(x![1]!), int.parse(x[2]!), int.parse(x[3]!));
    if (y < 100) y += y > today.year % 100 ? 1900 : 2000;
  } else if ((x = RegExp(r'^([A-Za-z]{3,})\.? (\d{1,2}),? (\d{4})$')
          .firstMatch(s)) !=
      null) {
    (m, d, y) = (
      _months[x![1]!.substring(0, 3).toLowerCase()],
      int.parse(x[2]!),
      int.parse(x[3]!),
    );
  } else if ((x = RegExp(r'^(\d{1,2})[ -]([A-Za-z]{3,})\.?[ -](\d{4})$')
          .firstMatch(s)) !=
      null) {
    (d, m, y) = (
      int.parse(x![1]!),
      _months[x[2]!.substring(0, 3).toLowerCase()],
      int.parse(x[3]!),
    );
  }
  if (y == null || m == null || d == null) return null;
  final date = DateTime.utc(y, m, d);
  // Not a real date (Feb 30), today or later, or over 100 years ago.
  if (date.year != y || date.month != m || date.day != d) return null;
  final now = DateTime.utc(today.year, today.month, today.day);
  if (!date.isBefore(now) ||
      date.isBefore(DateTime.utc(now.year - 100, now.month, now.day))) {
    return null;
  }
  String two(int n) => n.toString().padLeft(2, '0');
  return '${y.toString().padLeft(4, '0')}-${two(m)}-${two(d)}';
}

/// [text] as CSV rows (RFC 4180): quoted fields may hold commas, quotes
/// ("" for one), and line breaks. Semicolons or tabs separate fields when
/// the first line has more of them than commas.
List<List<String>> _csv(String text) {
  final firstLine = text
      .split(RegExp(r'\r?\n'))
      .firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
  int count(String c) => c.allMatches(firstLine).length;
  final sep = count(';') > count(',') && count(';') >= count('\t')
      ? ';'
      : count('\t') > count(',')
      ? '\t'
      : ',';
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        field.write(c);
      }
    } else if (c == '"' && field.isEmpty) {
      quoted = true;
    } else if (c == sep) {
      row.add(field.toString());
      field.clear();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(field.toString());
      field.clear();
      rows.add(row);
      row = <String>[];
    } else {
      field.write(c);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}

/// A roster file's bytes as text: UTF-8, or Latin-1 from older Excel.
String rosterText(List<int> bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return latin1.decode(bytes);
  }
}
