import { HttpsError } from 'firebase-functions/v2/https';
import { db } from './admin.js';
import { Collections } from './constants.js';
import { groupMemberId } from './ids.js';

export type Role = 'owner' | 'admin' | 'member';

/**
 * The roles people have on a team. A direct conversation's two people are
 * 'participant's (CHAT-19), so asking for these leaves conversations out
 * of everything that lists or counts someone's teams.
 */
export const TEAM_ROLES: readonly string[] = ['owner', 'admin', 'member'];

/** Someone's team memberships, without their direct conversations (CHAT-19). */
export function teamMembershipsOf(uid: string): FirebaseFirestore.Query {
  return db().collection(Collections.groupMembers).where('uid', '==', uid).where('role', 'in', [...TEAM_ROLES]);
}

/**
 * The caller's role on a team, or null if not a member. Mirrors the
 * membership half of isMember/isAdmin in the rules; requireOpenTeam is the
 * other half (a suspended team) and the rules' active() (an archived one).
 */
export async function roleOf(groupId: string, uid: string): Promise<Role | null> {
  const snap = await db().collection(Collections.groupMembers).doc(groupMemberId(groupId, uid)).get();
  return snap.exists ? (snap.get('role') as Role) : null;
}

export interface OpenTeamOptions {
  /**
   * Lets the call through on an archived team: reads, leaving, restoring
   * or deleting it (TEAM-9), and super-admin moderation. Default false.
   */
  allowArchived?: boolean;
  /**
   * Lets the call through on a direct conversation (CHAT-19): deleting a
   * message and reporting. Everything else is for teams. Default false.
   */
  allowDirect?: boolean;
}

/**
 * Throws unless the team takes changes from this caller (SPEC §3: the
 * matrix is enforced on the server, the same way the rules enforce it).
 *
 * - A suspended team (ADMIN-3, SAFE-4) is closed to everyone on it, its
 *   owner and admins included (`permission-denied`, `team-suspended`), as
 *   the rules' isMember fails for them. Super admins still act on it.
 * - An archived team is read-only for everyone (TEAM-9, the rules'
 *   active()): `failed-precondition`, `team-archived`, unless
 *   [options.allowArchived].
 *
 * Returns the team's document, or throws `not-found`.
 */
export async function requireOpenTeam(
  groupId: string,
  superAdmin: boolean,
  options: OpenTeamOptions = {},
): Promise<FirebaseFirestore.DocumentSnapshot> {
  const group = await db().collection(Collections.groups).doc(groupId).get();
  if (!group.exists) throw new HttpsError('not-found', 'No such team.');
  // A direct conversation isn't a team: team actions find no such team.
  if (!options.allowDirect && group.get('kind') === 'direct') throw new HttpsError('not-found', 'No such team.');
  if (!superAdmin && group.get('suspendedAt') != null) {
    throw new HttpsError('permission-denied', 'team-suspended');
  }
  if (!options.allowArchived && group.get('archivedAt') != null) {
    throw new HttpsError('failed-precondition', 'team-archived');
  }
  return group;
}

/**
 * Throws unless the caller is a team admin (or owner), or a super admin,
 * and the team takes the change (requireOpenTeam: not suspended, and not
 * archived unless [options.allowArchived]).
 */
export async function requireTeamAdmin(
  groupId: string,
  uid: string,
  superAdmin: boolean,
  options: OpenTeamOptions = {},
): Promise<'owner' | 'admin' | 'superAdmin'> {
  const role = superAdmin ? null : await roleOf(groupId, uid);
  if (!superAdmin && role !== 'owner' && role !== 'admin') {
    throw new HttpsError('permission-denied', 'Team admins only.');
  }
  await requireOpenTeam(groupId, superAdmin, options);
  return role === 'owner' || role === 'admin' ? role : 'superAdmin';
}

/**
 * Throws unless the caller owns the team, or is a super admin, and the team
 * takes the change (requireOpenTeam).
 */
export async function requireTeamOwner(
  groupId: string,
  uid: string,
  superAdmin: boolean,
  options: OpenTeamOptions = {},
): Promise<void> {
  if (!superAdmin && (await roleOf(groupId, uid)) !== 'owner') {
    throw new HttpsError('permission-denied', 'Only the team owner can do that.');
  }
  await requireOpenTeam(groupId, superAdmin, options);
}

/**
 * Throws `too-many-teams` when adding [uid] to another team would put them
 * on more than [max] (TEAM-2: up to 100). Callers that add someone who may
 * already be on the team check that first.
 */
export async function requireRoomForAnotherTeam(uid: string, max: number): Promise<void> {
  if ((await teamCountOf(uid)) >= max) throw new HttpsError('failed-precondition', 'too-many-teams');
}

/** How many teams someone is on (TEAM-2), their direct conversations left out. */
export async function teamCountOf(uid: string): Promise<number> {
  return (await teamMembershipsOf(uid).count().get()).data().count;
}
