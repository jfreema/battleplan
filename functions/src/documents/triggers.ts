// Documents triggers (ARCH §6.4 trigger map).
import { onDocumentCreated as onCreated, onDocumentDeleted as onDeleted } from 'firebase-functions/v2/firestore';
import { notifyDocumentAdded, removeDocumentLeftovers, type DocumentData } from './service.js';

/**
 * groupDocuments created → documentAdded to the team (DOC-6), unless the
 * uploader switched "Notify team" off.
 */
export const onDocumentCreated = onCreated('groupDocuments/{docId}', async (event) => {
  await notifyDocumentAdded(event.params.docId, event.data?.data() as DocumentData | undefined);
});

/**
 * groupDocuments deleted → the file in Storage (which fires the Storage
 * trigger, lowering storageBytes) and the center items about it.
 */
export const onDocumentDeleted = onDeleted('groupDocuments/{docId}', async (event) => {
  await removeDocumentLeftovers(event.params.docId, event.data?.data() as DocumentData | undefined);
});
