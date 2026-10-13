// Pure helpers for adding players (PLAYER-1), kept free of Firebase.

export interface GuardianInput {
  name?: string | null;
  email?: string | null;
}

export interface PlayerInput {
  name: string;
  jerseyNumber?: string | null;
  position?: string | null;
  /** The player's own email (PLAYER-1, optional): they're linked as the player ('self'). */
  email?: string | null;
  guardians: GuardianInput[];
}

const EMAIL = /^\S+@\S+\.\S+$/;

/**
 * Parses a pasted roster (PLAYER-1), one line per guardian: "Player name,
 * Guardian name, Guardian email", or for an adult player, "Player name,
 * Player's email". Lines with the same player name become one player with
 * up to 4 guardians and at most one email of their own. Returns the players
 * and any lines that couldn't be read. Mirrors the app's parser.
 */
export function parsePastedRoster(text: string, maxGuardians = 4): { players: PlayerInput[]; problems: string[] } {
  const byName = new Map<string, PlayerInput>();
  const problems: string[] = [];
  for (const raw of text.split(/\r?\n/)) {
    const line = raw.trim();
    if (!line) continue;
    const [player, second = '', guardianEmail = ''] = line.split(/[,\t]/).map((p) => p.trim());
    if (!player) {
      problems.push(line);
      continue;
    }
    if (guardianEmail && !EMAIL.test(guardianEmail)) {
      problems.push(line);
      continue;
    }
    const key = player.toLowerCase();
    const entry = byName.get(key) ?? { name: player, guardians: [] };
    // "Jared Freeman, jared@example.com": the player's own email (an adult
    // player), at most one per player. Mirrors the app's parser.
    if (!guardianEmail && EMAIL.test(second)) {
      if (entry.email) problems.push(line);
      else entry.email = second;
      byName.set(key, entry);
      continue;
    }
    const guardianName = second;
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

/**
 * Why [uid] can't be linked to a player as [relation] (PLAYER-3), or null
 * when they can: a player has at most one 'self' link, a member is 'self'
 * for at most one player per team, and a player has up to [maxGuardians]
 * guardians ('self' doesn't count). [playerLinks] are the player's links;
 * [selfPlayers] the players [uid] is 'self' for on the team.
 */
export function linkLimitProblem(
  uid: string,
  playerId: string,
  relation: Relation,
  playerLinks: { uid: string; relation: Relation }[],
  selfPlayers: string[],
  maxGuardians: number,
): 'player-already-claimed' | 'already-a-player' | 'too-many-guardians' | null {
  const others = playerLinks.filter((l) => l.uid !== uid);
  if (relation === 'self') {
    if (others.some((l) => l.relation === 'self')) return 'player-already-claimed';
    if (selfPlayers.some((p) => p !== playerId)) return 'already-a-player';
    return null;
  }
  return others.filter((l) => l.relation === 'guardian').length >= maxGuardians ? 'too-many-guardians' : null;
}

/**
 * Whether a players update changes what members' "Who's who" labels and
 * RSVP names read (PLAYER-8): an active player's name or number. The
 * players-updated trigger exits early otherwise.
 */
export function playerLabelChanged(
  before: Record<string, unknown> | undefined,
  after: Record<string, unknown> | undefined,
): boolean {
  if (!before || !after || playerStatusOf(after) !== 'active') return false;
  return before.displayName !== after.displayName || (before.jerseyNumber ?? null) !== (after.jerseyNumber ?? null);
}
