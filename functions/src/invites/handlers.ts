// Thin entry points for the invites domain (ARCH §6.4).
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { HttpsError, onRequest } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { audit } from '../audit/service.js';
import { db } from '../shared/admin.js';
import { onCall } from '../shared/callable.js';
import { Collections, Limits } from '../shared/constants.js';
import { groupMemberId } from '../shared/ids.js';
import { consumeRateLimit, consumeRateLimits } from '../shared/rate_limit.js';
import { postSystemMessage } from '../chat/service.js';
import { refreshMemberCount } from '../teams/service.js';
import { normalizeCode } from './codes.js';
import { requireAuth } from '../shared/guards.js';
import { requireOpenTeam, requireTeamAdmin, roleOf, teamCountOf } from '../shared/roles.js';
import { parse } from '../shared/validate.js';
import { resendApiKey, sendEmail } from '../email/service.js';
import { inviteEmail } from '../email/templates.js';
import { APP_PREFIX, joinUrl, linkHost } from '../links/service.js';
import { type InviteCard, invitePreviewPage, isPreviewFetcher } from './page.js';
import {
  activeTeamLink,
  createEmailInvite,
  createTeamLink,
  listEmailInvites as listInvites,
  previewInvite,
  redeem,
  revokeTeamLinks,
  teamLinkIsOff,
  updateTeamLink,
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
  await requireInviter(groupId, uid, superAdmin);
  // Nobody can join a suspended or archived team (redeem), so it gets no new link.
  await requireOpenTeam(groupId, superAdmin);
  const link = await activeTeamLink(groupId);
  if (link) return link;
  // An admin turned the link off (§3): no new one until they turn it on.
  if (await teamLinkIsOff(groupId)) throw new HttpsError('failed-precondition', 'link-off');
  return createTeamLink(groupId, uid);
});

/**
 * Sets an expiry and use limit on the team's current link, keeping its code
 * so the link and QR already shared still work (INV-2). Admins only.
 */
export const updateGroupInvite = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = parse(LinkOptions.extend({ groupId: z.string().min(1) }), request.data);
  await requireTeamAdmin(input.groupId, uid, request.auth?.token.superAdmin === true);
  const link = await updateTeamLink(input.groupId, {
    expiresInDays: input.expiresInDays ?? null,
    maxUses: input.maxUses ?? null,
  });
  if (!link) throw new HttpsError('failed-precondition', 'link-off');
  await audit({
    actorId: uid,
    action: 'updateGroupInvite',
    groupId: input.groupId,
    targetType: 'invite',
    targetId: link.code,
    after: { expiresInDays: input.expiresInDays ?? null, maxUses: input.maxUses ?? null },
  });
  return link;
});

/**
 * Turns the team's link off without a new one (§3 "Reset or revoke invite
 * links"). Admins turn it back on with resetGroupInvite. Email invites
 * aren't affected. Admins only.
 */
export const revokeGroupInvite = onCall(async (request) => {
  const uid = requireAuth(request);
  const { groupId } = parse(z.object({ groupId: z.string().min(1) }), request.data);
  await requireTeamAdmin(groupId, uid, request.auth?.token.superAdmin === true, { allowArchived: true });
  await revokeTeamLinks(groupId, true);
  await audit({
    actorId: uid,
    action: 'revokeGroupInvite',
    groupId,
    targetType: 'group',
    targetId: groupId,
  });
  return { ok: true };
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

/**
 * `/join/<CODE>` (Hosting rewrites it here; ARCH §6.6). Link-preview
 * fetchers get a page whose tags show the team's name and logo (task 140);
 * everyone else goes straight on to the app's /join page with a 302, as the
 * Hosting redirect this replaces did. The team lookup shares
 * getInvitePreview's limit per IP address; past it, or for a code that
 * doesn't work, the preview is Battleplan's own.
 */
export const joinPage = onRequest({ invoker: 'public' }, async (req, res) => {
  // The answer differs by who asks, so no cache may keep it for others.
  res.set('Cache-Control', 'no-store');
  res.set('Vary', 'User-Agent');
  res.set('X-Robots-Tag', 'noindex');
  const raw = req.path.replace(/^\/join\/?/, '').split('/')[0] ?? '';
  const query = req.originalUrl?.includes('?') ? req.originalUrl.slice(req.originalUrl.indexOf('?')) : '';
  const appJoinUrl = `${APP_PREFIX}/join${raw ? `/${encodeURIComponent(raw)}` : ''}${query}`;
  if (!isPreviewFetcher(req.get('user-agent'))) {
    res.redirect(302, appJoinUrl);
    return;
  }
  let card: InviteCard | null = null;
  if (CodeInput.safeParse({ code: raw }).success) {
    try {
      const ip = req.ip ?? 'unknown';
      await consumeRateLimit(`ip-${ip.replace(/[^0-9a-fA-F.:]/g, '')}`, 'invitePreview', Limits.invitePreviewsPerIpPerHour, 'hour');
      const preview = await previewInvite(normalizeCode(raw));
      if (typeof preview !== 'string') {
        card = { teamName: preview.name, logoUrl: preview.logoUrl, invitedBy: preview.invitedBy };
      }
    } catch (e) {
      if (!(e instanceof HttpsError)) logger.warn('join_page_lookup_failed', { error: String(e) });
    }
  }
  const html = invitePreviewPage(card, {
    joinUrl: joinUrl(raw),
    appJoinUrl: `https://${linkHost()}${appJoinUrl}`,
    siteImage: `https://${linkHost()}/images/og.png`,
  });
  res.status(200).type('text/html; charset=utf-8').send(req.method === 'HEAD' ? '' : html);
});

/** Joins the team behind an invite code (INV-5). 20 tries an hour per person. */
export const redeemInvite = onCall(async (request) => {
  const uid = requireAuth(request);
  const { code } = parse(CodeInput, request.data);
  await consumeRateLimit(uid, 'redeemInvite', Limits.inviteRedeemsPerUserPerHour, 'hour');
  const teams = await teamCountOf(uid);
  const profile = (await db().collection(Collections.users).doc(uid).get()).data();
  const result = await redeem(normalizeCode(code), uid, request.auth?.token.email ?? null, {
    displayName: (profile?.displayName as string | undefined) ?? 'New member',
    photoPath: (profile?.photoPath as string | null | undefined) ?? null,
  });
  if (typeof result === 'string') throw new HttpsError('not-found', result);
  if (!result.alreadyMember) {
    if (teams >= Limits.groupsPerUserMax) {
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

/**
 * Throws unless the caller may invite: admins, or members when the team
 * allows it. Callers that send invites also check requireOpenTeam.
 */
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
  await requireOpenTeam(input.groupId, request.auth?.token.superAdmin === true);
  if (request.auth?.token.email_verified !== true) {
    throw new HttpsError('failed-precondition', 'email-not-verified');
  }
  const emails = [...new Set(input.emails.map((e) => e.toLowerCase()))];
  await consumeRateLimits([
    { key: uid, action: 'emailInvite', max: Limits.emailInvitesPerUserPerDay, count: emails.length },
    { key: input.groupId, action: 'emailInvite', max: Limits.emailInvitesPerGroupPerDay, count: emails.length },
  ]);
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
  await requireOpenTeam(groupId, request.auth?.token.superAdmin === true, { allowArchived: true });
  return { invites: await listInvites(groupId) };
});

/**
 * Turns an invite off at once (INV-4 Revoke, ADMIN-3 Content). An email
 * invite: its inviter, a team admin, or a super admin. The team's link: a
 * team admin or a super admin, and it stays off the way revokeGroupInvite
 * leaves it (§3 "revoke"), so getTeamInvite makes no new one until an admin
 * turns one on with resetGroupInvite. Each revoke goes in the audit log
 * (ADMIN-6), as resetting the team link does.
 */
export const revokeInvite = onCall(async (request) => {
  const uid = requireAuth(request);
  const { code } = parse(z.object({ code: z.string().min(4) }), request.data);
  const ref = db().collection(Collections.invites).doc(normalizeCode(code));
  const invite = await ref.get();
  if (!invite.exists) return { ok: true };
  const groupId = invite.get('groupId') as string;
  const isLink = invite.get('type') === 'link';
  // Turning an invite off is fine on an archived team, not a suspended one.
  // The link belongs to the team, not the member who first opened it.
  if (isLink || invite.get('createdBy') !== uid) {
    await requireTeamAdmin(groupId, uid, request.auth?.token.superAdmin === true, { allowArchived: true });
  } else {
    await requireOpenTeam(groupId, request.auth?.token.superAdmin === true, { allowArchived: true });
  }
  if (invite.get('revokedAt') != null) return { ok: true };
  if (isLink) {
    await revokeTeamLinks(groupId, true);
  } else {
    await ref.update({ revokedAt: FieldValue.serverTimestamp() });
  }
  await audit({
    actorId: uid,
    action: 'revokeInvite',
    groupId,
    targetType: 'invite',
    targetId: invite.id,
    before: {
      type: (invite.get('type') as string | undefined) ?? null,
      email: (invite.get('email') as string | null | undefined) ?? null,
      createdBy: (invite.get('createdBy') as string | undefined) ?? null,
    },
    after: { revoked: true },
  });
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
  await requireOpenTeam(groupId, request.auth?.token.superAdmin === true);
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
