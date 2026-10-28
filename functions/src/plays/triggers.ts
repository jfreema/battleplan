// Plays triggers (ARCH §6.4 trigger map).
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { followPlayChange } from './service.js';

/**
 * plays written → its share (BOARD-6) follows: a deleted play's link stops
 * working, and a changed play's copy is brought up to date. Exits early
 * for a play that isn't shared, and is retried on failure, so a deleted play's
 * link can't stay up.
 */
export const onPlayWritten = onDocumentWritten({ document: 'plays/{playId}', retry: true }, async (event) => {
  await followPlayChange(event.params.playId, event.data?.before.data(), event.data?.after.data());
});
