// Audit triggers (ADMIN-6, ADMIN-8, ARCH §6.4 trigger map). Documents and
// one-off events are deleted by the app straight in Firestore, under the
// rules (the uploader or creator, a team admin, or a super admin), so no
// callable sees those deletes. These triggers carry who made the write
// (Firestore's auth context) and record an admin's delete of someone
// else's document or event, as deleteMessage does for messages.
import {
  onDocumentDeletedWithAuthContext,
  type FirestoreAuthEvent,
  type QueryDocumentSnapshot,
} from 'firebase-functions/v2/firestore';
import { auditClientDelete } from './service.js';

type DeleteEvent = FirestoreAuthEvent<QueryDocumentSnapshot | undefined, Record<string, string>>;

const actorOf = (event: DeleteEvent) => ({ authType: event.authType, authId: event.authId });

/** groupDocuments deleted by a person in the app → an audit entry when it wasn't their own (DOC-5, ADMIN-6). */
export const auditDocumentDeleted = onDocumentDeletedWithAuthContext('groupDocuments/{docId}', async (event) => {
  await auditClientDelete('document', event.params.docId, event.data?.data(), actorOf(event));
});

/** events deleted by a person in the app → an audit entry when it wasn't their own (SCHED-6, ADMIN-6). */
export const auditEventDeleted = onDocumentDeletedWithAuthContext('events/{eventId}', async (event) => {
  await auditClientDelete('event', event.params.eventId, event.data?.data(), actorOf(event));
});
