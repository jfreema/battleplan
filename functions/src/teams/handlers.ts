// Thin entry points for the teams domain (ARCH §6.4).
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { auth, db } from '../shared/admin.js';
import { Collections, Limits, sportValues, TEAM_COLORS, teamTypeValues } from '../shared/constants.js';
import { requireAuth } from '../shared/guards.js';
import { consumeRateLimit } from '../shared/rate_limit.js';
import { parse } from '../shared/validate.js';
import { createGroup as create } from './service.js';

const CreateGroupInput = z.object({
  name: z.string().trim().min(1).max(Limits.groupNameMax),
  sport: z.enum(sportValues),
  teamType: z.enum(teamTypeValues),
  color: z.enum(TEAM_COLORS).optional(),
  timeZone: z.string().min(1).max(64),
  description: z.string().max(500).optional(),
});

/** Creates a team with the caller as owner (TEAM-1). */
export const createGroup = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = parse(CreateGroupInput, request.data);

  // Verified email required (AUTH-3, SAFE-5); super admins can turn
  // team creation off for everyone else (Q3, ADMIN-7).
  const user = await auth().getUser(uid);
  if (!user.emailVerified) {
    throw new HttpsError('failed-precondition', 'email-not-verified');
  }
  const config = (await db().collection(Collections.config).doc('app').get()).data() ?? {};
  const superAdmin = request.auth?.token.superAdmin === true;
  if (config.allowUserGroupCreation === false && !superAdmin) {
    throw new HttpsError('permission-denied', 'group-creation-off');
  }
  if (!superAdmin) {
    await consumeRateLimit(
      uid,
      'createGroup',
      (config.maxGroupsCreatedPerUserPerDay as number | undefined) ?? Limits.groupsCreatedPerUserPerDay,
    );
  }

  // A person can be on up to 100 teams (TEAM-2).
  const teams = await db()
    .collection(Collections.groupMembers)
    .where('uid', '==', uid)
    .count()
    .get();
  if (teams.data().count >= Limits.groupsPerUserMax) {
    throw new HttpsError('failed-precondition', 'too-many-teams');
  }

  const profile = (await db().collection(Collections.users).doc(uid).get()).data();
  const groupId = await create(
    uid,
    {
      displayName: (profile?.displayName as string | undefined) ?? user.displayName ?? 'Team owner',
      photoPath: (profile?.photoPath as string | null | undefined) ?? null,
    },
    input,
    (config.defaultStorageQuotaGb as number | undefined) ?? Limits.defaultStorageQuotaGb,
  );
  return { groupId };
});
