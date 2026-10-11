// Chat triggers (ARCH §6.4 trigger map): react to messages clients write.
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { touchLastMessage, writeReplyPreview } from './service.js';

/**
 * messages created → the team's last-message time and preview (switcher
 * order and unread dots, CHAT-9), and a reply's quote (CHAT-13, D25). The
 * client sends only replyToId; the server copies the quote from the
 * original so it can't be faked. (Notifications join this trigger in M4.)
 */
export const onMessageCreated = onDocumentCreated('messages/{messageId}', async (event) => {
  const data = event.data?.data();
  if (!data) return;
  await touchLastMessage(data.groupId as string, data);
  if (typeof data.replyToId === 'string') {
    await writeReplyPreview(event.params.messageId, data.groupId as string, data.replyToId);
  }
});
