// Thin entry points for the chat domain (ARCH §6.4).
import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { audit } from '../audit/service.js';
import { db } from '../shared/admin.js';
import { onCall } from '../shared/callable.js';
import { Collections } from '../shared/constants.js';
import { requireAuth } from '../shared/guards.js';
import { requireOpenTeam, requireTeamAdmin, roleOf } from '../shared/roles.js';
import { parse } from '../shared/validate.js';
import { eraseMessage, setPinned } from './service.js';

/**
 * Deletes a message (CHAT-8): its author, a team admin, or a super admin.
 * System messages can't be deleted. Admin deletions go in the audit log.
 * Not on a suspended team, nor an archived (read-only) one, except by a
 * super admin moderating it (§3, TEAM-9).
 */
export const deleteMessage = onCall(async (request) => {
  const uid = requireAuth(request);
  const { messageId } = parse(z.object({ messageId: z.string().min(1).max(64) }), request.data);
  const message = await db().collection(Collections.messages).doc(messageId).get();
  if (!message.exists || message.get('deletedAt')) return { ok: true };
  const groupId = message.get('groupId') as string;
  if (message.get('type') === 'system') throw new HttpsError('failed-precondition', 'system-message');
  const isAuthor = message.get('authorId') === uid;
  const superAdmin = request.auth?.token.superAdmin === true;
  await requireOpenTeam(groupId, superAdmin, { allowArchived: superAdmin });
  if (!isAuthor && !superAdmin) {
    const role = await roleOf(groupId, uid);
    if (role !== 'owner' && role !== 'admin') {
      throw new HttpsError('permission-denied', 'Only the author or a team admin can delete this.');
    }
  }
  await eraseMessage(messageId, uid, isAuthor ? 'author' : 'admin');
  if (!isAuthor) {
    await audit({
      actorId: uid,
      action: 'deleteMessage',
      groupId,
      targetType: 'message',
      targetId: messageId,
      before: { authorId: message.get('authorId'), type: message.get('type') },
    });
  }
  return { ok: true };
});

/**
 * Pins or unpins a message on the bar at the top of the chat (CHAT-15):
 * team admins, and super admins. Up to Limits.pinnedMessagesMax are pinned
 * at once; one more is refused with `too-many-pins`. Deleted messages and
 * system lines can't be pinned, but either can be unpinned. Not on a
 * suspended or archived team (requireTeamAdmin). Each change is audited.
 */
export const pinMessage = onCall(async (request) => {
  const uid = requireAuth(request);
  const { messageId, pinned } = parse(
    z.object({ messageId: z.string().min(1).max(64), pinned: z.boolean() }),
    request.data,
  );
  const message = await db().collection(Collections.messages).doc(messageId).get();
  if (!message.exists) throw new HttpsError('not-found', 'No such message.');
  const groupId = message.get('groupId') as string;
  await requireTeamAdmin(groupId, uid, request.auth?.token.superAdmin === true);
  if (pinned && (message.get('deletedAt') || message.get('type') === 'system')) {
    throw new HttpsError('failed-precondition', 'not-pinnable');
  }
  if (await setPinned(groupId, messageId, pinned)) {
    await audit({
      actorId: uid,
      action: pinned ? 'pinMessage' : 'unpinMessage',
      groupId,
      targetType: 'message',
      targetId: messageId,
      before: { authorId: message.get('authorId'), type: message.get('type') },
    });
  }
  return { ok: true };
});
