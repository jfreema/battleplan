import { HttpsError } from 'firebase-functions/v2/https';
import { db } from './admin.js';
import { Collections } from './constants.js';
import { groupMemberId } from './ids.js';

export type Role = 'owner' | 'admin' | 'member';

/** The caller's role on a team, or null if not a member. Mirrors isMember/isAdmin in the rules. */
export async function roleOf(groupId: string, uid: string): Promise<Role | null> {
  const snap = await db().collection(Collections.groupMembers).doc(groupMemberId(groupId, uid)).get();
  return snap.exists ? (snap.get('role') as Role) : null;
}

/** Throws unless the caller is a team admin (or owner), or a super admin. */
export async function requireTeamAdmin(
  groupId: string,
  uid: string,
  superAdmin: boolean,
): Promise<'owner' | 'admin' | 'superAdmin'> {
  if (superAdmin) return 'superAdmin';
  const role = await roleOf(groupId, uid);
  if (role === 'owner' || role === 'admin') return role;
  throw new HttpsError('permission-denied', 'Team admins only.');
}
