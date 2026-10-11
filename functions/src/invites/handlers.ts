// Thin entry points for the invites domain (ARCH §6.4).
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { audit } from '../audit/service.js';
import { db } from '../shared/admin.js';
import { Collections, Limits } from '../shared/constants.js';
import { groupMemberId } from '../shared/ids.js';
import { consumeRateLimit } from '../shared/rate_limit.js';
import { postSystemMessage } from '../chat/service.js';
import { refreshMemberCount } from '../teams/service.js';
import { normalizeCode } from './codes.js';
import { requireAuth } from '../shared/guards.js';
import { requireTeamAdmin, roleOf } from '../shared/roles.js';
import { parse } from '../shared/validate.js';
import { activeTeamLink, createTeamLink, previewInvite, redeem, revokeTeamLinks } from './service.js';

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

const CodeInput = z.object({ code: z.string().min(4).max(20) });

/**
 * The team behind an invite code, shown before sign-in (INV-5, INV-7).
 * Works signed out; limited to 60 lookups an hour per IP address.
 */
export const getInvitePreview = onCall(async (request) => {
  const { code } = parse(CodeInput, request.data);
  const ip = request.rawRequest.ip ?? 'unknown';
  await consumeRateLimit(`ip-${ip.replace(/[^0-9a-fA-F.:]/g, '')}`, 'invitePreview', Limits.invitePreviewsPerIpPerHour, 'hour');
  const result = await previewInvite(normalizeCode(code));
  if (typeof result === 'string') throw new HttpsError('not-found', result);
  return result;
});

/** Joins the team behind an invite code (INV-5). 20 tries an hour per person. */
export const redeemInvite = onCall(async (request) => {
  const uid = requireAuth(request);
  const { code } = parse(CodeInput, request.data);
  await consumeRateLimit(uid, 'redeemInvite', Limits.inviteRedeemsPerUserPerHour, 'hour');
  const teams = await db().collection(Collections.groupMembers).where('uid', '==', uid).count().get();
  const profile = (await db().collection(Collections.users).doc(uid).get()).data();
  const result = await redeem(normalizeCode(code), uid, request.auth?.token.email ?? null, {
    displayName: (profile?.displayName as string | undefined) ?? 'New member',
    photoPath: (profile?.photoPath as string | null | undefined) ?? null,
  });
  if (typeof result === 'string') throw new HttpsError('not-found', result);
  if (!result.alreadyMember) {
    if (teams.data().count >= Limits.groupsPerUserMax) {
      // Undo: over the 100-team limit (TEAM-2).
      await db().collection(Collections.groupMembers).doc(groupMemberId(result.groupId, uid)).delete();
      await refreshMemberCount(result.groupId);
      throw new HttpsError('failed-precondition', 'too-many-teams');
    }
    await refreshMemberCount(result.groupId);
    const name = (profile?.displayName as string | undefined) ?? 'Someone';
    await postSystemMessage(result.groupId, 'joined', `${name} joined`, uid);
  }
  return result;
});
