// Chat triggers (ARCH §6.4 trigger map): react to messages clients write.
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import {
  notifyNewMessage,
  refreshReplyPreviews,
  replyRecipientOf,
  touchLastMessage,
  writeReplyPreview,
} from './service.js';

/**
 * messages created → the team's last-message time and preview (switcher
 * order and unread dots, CHAT-9), a reply's quote (CHAT-13, D25), and the
 * notifications (NOTIF-2): "replied to you" for the person quoted and the
 * message push for everyone else. The client sends only replyToId; the
 * server copies the quote from the original so it can't be faked.
 */
export const onMessageCreated = onDocumentCreated('messages/{messageId}', async (event) => {
  const data = event.data?.data();
  // Imported history (IMPORT-9) carries its own quotes and notifies no one;
  // importMessages moves the team's last message itself.
  if (!data || data.imported) return;
  const messageId = event.params.messageId;
  const teamName = await touchLastMessage(data.groupId as string, data);
  let repliedTo: string | null = null;
  if (typeof data.replyToId === 'string') {
    const original = await writeReplyPreview(messageId, data.groupId as string, data.replyToId);
    repliedTo = replyRecipientOf(original, String(data.authorId ?? ''));
  }
  await notifyNewMessage(messageId, data, teamName, repliedTo);
});

/**
 * messages updated → replies' quotes follow an edit (CHAT-15). Exits early
 * unless the text changed on a message that isn't deleted (reactions and
 * deletions don't count; deleteMessage updates quotes itself).
 */
export const onMessageUpdated = onDocumentUpdated('messages/{messageId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after || after.deletedAt || before.text === after.text) return;
  await refreshReplyPreviews(event.params.messageId, after);
});
