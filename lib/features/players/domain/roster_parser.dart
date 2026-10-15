import 'package:battleplan/features/players/domain/player.dart';

/// Parses a pasted roster (PLAYER-1): one player per line, their name and,
/// after a comma or tab, their jersey number if they have one ("Emma
/// Rodriguez, 7" or "Emma Rodriguez, #7"). Lines that can't be read (no
/// name, a name over 60 characters, a number over 4, or more than a name
/// and a number, such as the old "player, guardian, email" lines) and
/// repeated names are listed as problems. `lines` counts the lines that
/// aren't blank, of which there can be up to 200
/// (`Limits.pastedRosterLinesMax`).
({List<NewPlayer> players, List<String> problems, int lines}) parsePastedRoster(
  String text,
) {
  var lines = 0;
  final players = <NewPlayer>[];
  final names = <String>{};
  final problems = <String>[];
  for (final raw in text.split(RegExp(r'\r?\n'))) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    lines++;
    final parts = line.split(RegExp('[,\t]')).map((p) => p.trim()).toList();
    final name = parts.first;
    final number = parts.length > 1
        ? parts[1].replaceFirst(RegExp(r'^#\s*'), '')
        : '';
    if (name.isEmpty ||
        name.length > 60 ||
        parts.length > 2 ||
        number.length > 4 ||
        !names.add(name.toLowerCase())) {
      problems.add(line);
      continue;
    }
    players.add(
      NewPlayer(name: name, jerseyNumber: number.isEmpty ? null : number),
    );
  }
  return (players: players, problems: problems, lines: lines);
}
