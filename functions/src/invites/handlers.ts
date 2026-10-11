// Thin entry points for the invites domain (ARCH §6.4).
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
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
import { resendApiKey, sendEmail } from '../email/service.js';
import { inviteEmail } from '../email/templates.js';
import { joinUrl } from '../links/service.js';
import {
  activeTeamLink,
  createEmailInvite,
  createTeamLink,
  listEmailInvites as listInvites,
  previewInvite,
  redeem,
  revokeTeamLinks,
} from './service.js';

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

/** Throws unless the caller may invite: admins, or members when the team allows it. */
async function requireInviter(groupId: string, uid: string, superAdmin: boolean): Promise<void> {
  if (superAdmin) return;
  const role = await roleOf(groupId, uid);
  if (!role) throw new HttpsError('permission-denied', 'Not a member.');
  if (role === 'member') {
    const group = await db().collection(Collections.groups).doc(groupId).get();
    if (group.get('settings.membersCanInvite') !== true) {
      throw new HttpsError('permission-denied', 'invites-admins-only');
    }
  }
}

const SendInvitesInput = z.object({
  groupId: z.string().min(1),
  emails: z.array(z.string().trim().email().max(200)).min(1).max(Limits.emailInvitesPerBatchMax),
  note: z.string().trim().max(300).optional(),
});

/**
 * Emails single-use invites that expire in 14 days (INV-4). Needs a verified
 * email; 50 a day per person and 200 a day per team.
 */
export const sendEmailInvites = onCall({ secrets: [resendApiKey] }, async (request) => {
  const uid = requireAuth(request);
  const input = parse(SendInvitesInput, request.data);
  await requireInviter(input.groupId, uid, request.auth?.token.superAdmin === true);
  if (request.auth?.token.email_verified !== true) {
    throw new HttpsError('failed-precondition', 'email-not-verified');
  }
  const emails = [...new Set(input.emails.map((e) => e.toLowerCase()))];
  for (let i = 0; i < emails.length; i++) {
    await consumeRateLimit(uid, 'emailInvite', Limits.emailInvitesPerUserPerDay);
    await consumeRateLimit(input.groupId, 'emailInvite', Limits.emailInvitesPerGroupPerDay);
  }
  const group = await db().collection(Collections.groups).doc(input.groupId).get();
  const inviter = await db().collection(Collections.users).doc(uid).get();
  const inviterName = (inviter.get('displayName') as string | undefined) ?? 'A teammate';
  let sent = 0;
  for (const email of emails) {
    const code = await createEmailInvite(input.groupId, email, uid);
    if (await sendEmail(inviteEmail(email, group.get('name') as string, inviterName, joinUrl(code), input.note))) sent++;
  }
  return { invited: emails.length, sent };
});

/** The team's email invites with their state (INV-4). */
export const listEmailInvites = onCall(async (request) => {
  const uid = requireAuth(request);
  const { groupId } = parse(z.object({ groupId: z.string().min(1) }), request.data);
  await requireInviter(groupId, uid, request.auth?.token.superAdmin === true);
  return { invites: await listInvites(groupId) };
});

/** Turns an invite off at once (INV-4 Revoke). The inviter or an admin. */
export const revokeInvite = onCall(async (request) => {
  const uid = requireAuth(request);
  const { code } = parse(z.object({ code: z.string().min(4) }), request.data);
  const ref = db().collection(Collections.invites).doc(normalizeCode(code));
  const invite = await ref.get();
  if (!invite.exists) return { ok: true };
  const groupId = invite.get('groupId') as string;
  if (invite.get('createdBy') !== uid) {
    await requireTeamAdmin(groupId, uid, request.auth?.token.superAdmin === true);
  }
  await ref.update({ revokedAt: FieldValue.serverTimestamp() });
  return { ok: true };
});

/** Sends an email invite again with a fresh 14 days (INV-4 Resend). */
export const resendEmailInvite = onCall({ secrets: [resendApiKey] }, async (request) => {
  const uid = requireAuth(request);
  const { code } = parse(z.object({ code: z.string().min(4) }), request.data);
  const ref = db().collection(Collections.invites).doc(normalizeCode(code));
  const invite = await ref.get();
  if (!invite.exists || invite.get('type') !== 'email') throw new HttpsError('not-found', 'unknown');
  const groupId = invite.get('groupId') as string;
  await requireInviter(groupId, uid, request.auth?.token.superAdmin === true);
  if ((invite.get('useCount') ?? 0) >= 1) throw new HttpsError('failed-precondition', 'already-joined');
  await consumeRateLimit(uid, 'emailInvite', Limits.emailInvitesPerUserPerDay);
  await ref.update({
    revokedAt: null,
    expiresAt: Timestamp.fromMillis(Date.now() + Limits.emailInviteExpiryDays * 86_400_000),
  });
  const group = await db().collection(Collections.groups).doc(groupId).get();
  const inviter = await db().collection(Collections.users).doc(uid).get();
  await sendEmail(
    inviteEmail(
      invite.get('email') as string,
      group.get('name') as string,
      (inviter.get('displayName') as string | undefined) ?? 'A teammate',
      joinUrl(invite.id),
    ),
  );
  return { ok: true };
});
