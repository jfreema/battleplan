// Thin entry points for the polls domain (ARCH §6.4).
import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { audit } from '../audit/service.js';
import { db } from '../shared/admin.js';
import { onCall } from '../shared/callable.js';
import { Collections } from '../shared/constants.js';
import { groupMemberId } from '../shared/ids.js';
import { requireAuth } from '../shared/guards.js';
import { requireOpenTeam } from '../shared/roles.js';
import { parse } from '../shared/validate.js';
import { closePollNow } from './service.js';

/**
 * Closes a poll early (POLL-4): its creator, a team admin, or a super
 * admin. Voters get "Poll closed" with the result. An admin closing someone
 * else's poll goes in the audit log.
 */
export const closePoll = onCall(async (request) => {
  const uid = requireAuth(request);
  const { pollId } = parse(z.object({ pollId: z.string().min(1).max(64) }), request.data);
  const poll = await db().collection(Collections.polls).doc(pollId).get();
  if (!poll.exists) throw new HttpsError('not-found', 'poll-not-found');
  if (poll.get('closedAt')) return { ok: true };
  const groupId = poll.get('groupId') as string;
  const member = await db().collection(Collections.groupMembers).doc(groupMemberId(groupId, uid)).get();
  const isCreator = poll.get('createdBy') === uid && member.exists;
  const superAdmin = request.auth?.token.superAdmin === true;
  const isAdmin = member.exists && ['owner', 'admin'].includes(member.get('role') as string);
  if (!isCreator && !isAdmin && !superAdmin) {
    throw new HttpsError('permission-denied', 'Only the poll creator or a team admin can close it.');
  }
  // A suspended team is closed to everyone on it but super admins, and an
  // archived one is read-only (§3, TEAM-9), as in every team callable.
  await requireOpenTeam(groupId, superAdmin);
  const name = member.exists ? String(member.get('displayName') ?? '') : '';
  await closePollNow(pollId, { uid, name });
  if (!isCreator) {
    await audit({
      actorId: uid,
      action: 'closePoll',
      groupId,
      targetType: 'poll',
      targetId: pollId,
      before: { createdBy: poll.get('createdBy') },
    });
  }
  return { ok: true };
});
