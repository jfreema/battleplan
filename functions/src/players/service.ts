// Players domain service: owns players, playerGuardians, guardianRequests.
import { db } from '../shared/admin.js';
import { Collections } from '../shared/constants.js';
import { forEachPage } from '../shared/batch.js';

/** A deleted account stops being a guardian; its players stay (AUTH-10). */
export async function removeAccountFromPlayers(uid: string): Promise<void> {
  for (const collection of [Collections.playerGuardians, Collections.guardianRequests]) {
    await forEachPage(db().collection(collection).where('uid', '==', uid), (b, d) => b.delete(d.ref));
  }
}
