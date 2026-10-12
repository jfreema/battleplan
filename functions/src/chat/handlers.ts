// Thin entry points for the chat domain (ARCH §6.4).
import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { audit } from '../audit/service.js';
import { db } from '../shared/admin.js';
import { onCall } from '../shared/callable.js';
import { Collections } from '../shared/constants.js';
import { requireAuth } from '../shared/guards.js';
import { roleOf } from '../shared/roles.js';
import { parse } from '../shared/validate.js';
import { eraseMessage } from './service.js';

/**
 * Deletes a message (CHAT-8): its author, a team admin, or a super admin.
 * System messages can't be deleted. Admin deletions go in the audit log.
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
