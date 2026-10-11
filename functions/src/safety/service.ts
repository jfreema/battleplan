// Safety domain service: owns userBlocks and reports.
import { db } from '../shared/admin.js';
import { Collections } from '../shared/constants.js';
import { forEachPage } from '../shared/batch.js';

/** Deletes the blocks a deleted account made, and blocks of it. */
export async function removeAccountBlocks(uid: string): Promise<void> {
  for (const field of ['uid', 'blockedUid']) {
    await forEachPage(db().collection(Collections.userBlocks).where(field, '==', uid), (b, d) => b.delete(d.ref));
  }
}
