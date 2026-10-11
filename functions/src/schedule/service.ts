// Schedule domain service: owns eventSeries, events, rsvps.
import { Timestamp } from 'firebase-admin/firestore';
import { db } from '../shared/admin.js';
import { Collections } from '../shared/constants.js';
import { forEachPage } from '../shared/batch.js';

/** A deleted account's RSVPs for upcoming events go; past ones stay (AUTH-10). */
export async function removeUpcomingRsvps(uid: string): Promise<void> {
  await forEachPage(
    db()
      .collection(Collections.rsvps)
      .where('participantId', '==', uid)
      .where('eventStartAt', '>=', Timestamp.now()),
    (b, d) => b.delete(d.ref),
  );
}
