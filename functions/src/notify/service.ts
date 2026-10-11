// Notification pipeline (ARCH §6.5). The only code that writes
// notifications and devices from the server.
import { db } from '../shared/admin.js';
import { Collections } from '../shared/constants.js';
import { forEachPage } from '../shared/batch.js';

/** Deletes a deleted account's devices and notification-center items. */
export async function removeAccountNotifications(uid: string): Promise<void> {
  for (const collection of [Collections.devices, Collections.notifications]) {
    await forEachPage(db().collection(collection).where('uid', '==', uid), (b, d) => b.delete(d.ref));
  }
}
