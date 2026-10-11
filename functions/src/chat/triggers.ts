// Chat triggers (ARCH §6.4 trigger map): react to messages clients write.
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { writeReplyPreview } from './service.js';

/**
 * messages created → the reply's quote (CHAT-13, D25). The client sends only
 * replyToId; the server copies the quote from the original so it can't be
 * faked. Exits early for messages that aren't replies. (Updating the team's
 * last-message preview and notifying join this trigger in M4.)
 */
export const onMessageCreated = onDocumentCreated('messages/{messageId}', async (event) => {
  const data = event.data?.data();
  if (!data || typeof data.replyToId !== 'string') return;
  await writeReplyPreview(event.params.messageId, data.groupId as string, data.replyToId);
});
