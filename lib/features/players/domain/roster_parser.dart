import 'package:battleplan/features/players/domain/player.dart';

/// Parses a pasted roster, one line per guardian: "Player name, Guardian
/// name, Guardian email" (PLAYER-1). Lines with the same player name become
/// one player with up to 4 guardians. Mirrors functions/src/players/roster.ts,
/// so the app can show what it will add before sending.
({List<NewPlayer> players, List<String> problems}) parsePastedRoster(
  String text, {
  int maxGuardians = 4,
}) {
  final byName = <String, NewPlayer>{};
  final problems = <String>[];
  final email = RegExp(r'^\S+@\S+\.\S+$');
  for (final raw in text.split(RegExp(r'\r?\n'))) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final parts = line.split(RegExp('[,\t]')).map((p) => p.trim()).toList();
    final name = parts.isNotEmpty ? parts[0] : '';
    final guardianName = parts.length > 1 ? parts[1] : '';
    final guardianEmail = parts.length > 2 ? parts[2] : '';
    if (name.isEmpty ||
        (guardianEmail.isNotEmpty && !email.hasMatch(guardianEmail))) {
      problems.add(line);
      continue;
    }
    final key = name.toLowerCase();
    final current = byName[key] ?? NewPlayer(name: name);
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
  return (players: byName.values.toList(), problems: problems);
}
