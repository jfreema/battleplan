import 'package:battleplan/features/players/domain/player.dart';

/// Parses a pasted roster (PLAYER-1), one line per guardian: "Player name,
/// Guardian name, Guardian email", or for an adult player, "Player name,
/// Player's email": a line with an email right after the name is the
/// player's own. Lines with the same player name become one player with up
/// to 4 guardians and at most one email of their own. `lines` counts the
/// lines that aren't blank, of which there can be up to 200
/// (`Limits.pastedRosterLinesMax`).
({List<NewPlayer> players, List<String> problems, int lines}) parsePastedRoster(
  String text, {
  int maxGuardians = 4,
}) {
  var lines = 0;
  final byName = <String, NewPlayer>{};
  final problems = <String>[];
  final email = RegExp(r'^\S+@\S+\.\S+$');
  for (final raw in text.split(RegExp(r'\r?\n'))) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    lines++;
    final parts = line.split(RegExp('[,\t]')).map((p) => p.trim()).toList();
    final name = parts.isNotEmpty ? parts[0] : '';
    final second = parts.length > 1 ? parts[1] : '';
    final guardianEmail = parts.length > 2 ? parts[2] : '';
    // "Jared Freeman, jared@example.com": the player's own email.
    final playerEmail = guardianEmail.isEmpty && email.hasMatch(second)
        ? second
        : '';
    final guardianName = playerEmail.isEmpty ? second : '';
    if (name.isEmpty ||
        (guardianEmail.isNotEmpty && !email.hasMatch(guardianEmail))) {
      problems.add(line);
      continue;
    }
    final key = name.toLowerCase();
    final current = byName[key] ?? NewPlayer(name: name);
    if (playerEmail.isNotEmpty) {
      // One email of their own per player.
      if (current.email != null) {
        problems.add(line);
      } else {
        byName[key] = current.copyWith(email: playerEmail);
      }
      byName.putIfAbsent(key, () => current);
      continue;
    }
    if (guardianName.isNotEmpty || guardianEmail.isNotEmpty) {
      if (current.guardians.length >= maxGuardians) {
        problems.add(line);
        byName[key] = current;
        continue;
      }
      byName[key] = current.copyWith(
        guardians: [
          ...current.guardians,
          NewGuardian(
            name: guardianName.isEmpty ? null : guardianName,
            email: guardianEmail.isEmpty ? null : guardianEmail,
          ),
        ],
      );
    } else {
      byName[key] = current;
    }
  }
  return (players: byName.values.toList(), problems: problems, lines: lines);
}
