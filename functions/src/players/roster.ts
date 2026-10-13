// Pure helpers for adding players (PLAYER-1), kept free of Firebase.

export interface GuardianInput {
  name?: string | null;
  email?: string | null;
}

export interface PlayerInput {
  name: string;
  jerseyNumber?: string | null;
  position?: string | null;
  guardians: GuardianInput[];
}

/**
 * Parses a pasted roster, one line per guardian: "Player name, Guardian
 * name, Guardian email". Lines with the same player name become one player
 * with several guardians (up to 4). Returns the players and any lines that
 * couldn't be read.
 */
export function parsePastedRoster(text: string, maxGuardians = 4): { players: PlayerInput[]; problems: string[] } {
  const byName = new Map<string, PlayerInput>();
  const problems: string[] = [];
  for (const raw of text.split(/\r?\n/)) {
    const line = raw.trim();
    if (!line) continue;
    const [player, guardianName, guardianEmail] = line.split(/[,\t]/).map((p) => p.trim());
    if (!player) {
      problems.push(line);
      continue;
    }
    if (guardianEmail && !/^\S+@\S+\.\S+$/.test(guardianEmail)) {
      problems.push(line);
      continue;
    }
    const key = player.toLowerCase();
    const entry = byName.get(key) ?? { name: player, guardians: [] };
    if (guardianName || guardianEmail) {
      if (entry.guardians.length >= maxGuardians) {
        problems.push(line);
      } else {
        entry.guardians.push({ name: guardianName || null, email: guardianEmail || null });
      }
    }
    byName.set(key, entry);
  }
  return { players: [...byName.values()], problems };
}

/** "Emma #7", or "Emma" without a number (PLAYER-8). */
export function playerLabel(name: string, jerseyNumber?: string | null): string {
  const first = name.trim().split(/\s+/)[0] ?? name;
  return jerseyNumber ? `${first} #${jerseyNumber}` : first;
}

/** "Emma", "Emma and Liam", "Emma, Liam, and Ava": players named in notifications (NOTIF-5). */
export function joinNames(names: string[]): string {
  if (names.length <= 1) return names[0] ?? '';
  if (names.length === 2) return `${names[0]} and ${names[1]}`;
  return `${names.slice(0, -1).join(', ')}, and ${names[names.length - 1]}`;
}

/** How a member is linked to a player (PLAYER-3): they are the player, or a parent or guardian. */
export type Relation = 'self' | 'guardian';

/** A player link's relation; links made before 'self' existed are guardians. */
export function relationOf(link: { relation?: unknown } | undefined): Relation {
  return link?.relation === 'self' ? 'self' : 'guardian';
}

/** A player's status; players made before approvals existed are active. */
export function playerStatusOf(player: { status?: unknown } | undefined): 'active' | 'pending' {
  return player?.status === 'pending' ? 'pending' : 'active';
}

/**
 * A member's "Who's who" label from their links (PLAYER-8): a guardian's
 * players, "Emma #7, Liam #23"; a member who is a player, their number,
 * "#12", or nothing without one. Both when they're both, the number first.
 */
export function playerSummaryOf(links: { relation: Relation; name: string; jerseyNumber?: string | null }[]): string | null {
  const self = links.find((l) => l.relation === 'self');
  const guarded = links
    .filter((l) => l.relation !== 'self')
    .map((l) => playerLabel(l.name, l.jerseyNumber))
    .sort();
  const parts = [...(self?.jerseyNumber ? [`#${self.jerseyNumber}`] : []), ...guarded];
  return parts.length ? parts.join(', ') : null;
}
