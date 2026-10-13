// Players triggers (ARCH §6.4 trigger map).
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { followUpPlayerUpdate } from './service.js';

/**
 * players updated → linked members' "Who's who" labels (PLAYER-8) and
 * upcoming RSVPs' participantName. Linked members and admins edit players
 * directly, so this is where the copies follow. Exits early unless an
 * active player's name or number changed.
 */
export const onPlayerUpdated = onDocumentUpdated('players/{playerId}', async (event) => {
  await followUpPlayerUpdate(event.params.playerId, event.data?.before.data(), event.data?.after.data());
});
