// Thin entry points for the invites domain (ARCH §6.4).
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { audit } from '../audit/service.js';
import { db } from '../shared/admin.js';
import { Collections } from '../shared/constants.js';
import { requireAuth } from '../shared/guards.js';
import { requireTeamAdmin, roleOf } from '../shared/roles.js';
import { parse } from '../shared/validate.js';
import { activeTeamLink, createTeamLink, revokeTeamLinks } from './service.js';

const LinkOptions = z.object({
  expiresInDays: z.union([z.literal(1), z.literal(7), z.literal(30)]).nullable().optional(),
  maxUses: z.number().int().min(1).max(1000).nullable().optional(),
});

/**
 * The team's invite link, creating one if needed (INV-1, INV-2). Members
 * see it only when the team lets members invite.
 */
export const getTeamInvite = onCall(async (request) => {
  const uid = requireAuth(request);
  const { groupId } = parse(z.object({ groupId: z.string().min(1) }), request.data);
  const superAdmin = request.auth?.token.superAdmin === true;
  const role = await roleOf(groupId, uid);
  if (!superAdmin && !role) throw new HttpsError('permission-denied', 'Not a member.');
  if (!superAdmin && role === 'member') {
    const group = await db().collection(Collections.groups).doc(groupId).get();
    if (group.get('settings.membersCanInvite') !== true) {
      throw new HttpsError('permission-denied', 'invites-admins-only');
    }
  }
  return (await activeTeamLink(groupId)) ?? (await createTeamLink(groupId, uid));
});

/**
 * Replaces the team's link, turning the old one off at once, with an
 * optional expiry and use limit (INV-2). Admins only.
 */
export const resetGroupInvite = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = parse(LinkOptions.extend({ groupId: z.string().min(1) }), request.data);
  await requireTeamAdmin(input.groupId, uid, request.auth?.token.superAdmin === true);
  await revokeTeamLinks(input.groupId);
  const link = await createTeamLink(input.groupId, uid, input);
  await audit({
    actorId: uid,
    action: 'resetGroupInvite',
    groupId: input.groupId,
    targetType: 'invite',
    targetId: link.code,
    after: { expiresInDays: input.expiresInDays ?? null, maxUses: input.maxUses ?? null },
  });
  return link;
});
