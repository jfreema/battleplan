// Documents domain service: owns groupDocuments and the files under
// `groups/{g}/documents/` (ARCH §6.2, §6.8). Members create, rename, pin,
// and delete documents directly under the rules; this is the follow-up
// work: the documentAdded notification, removing a deleted document's file
// and center items, Media's view of document files, and cleaning up uploads
// whose document was never created.
import { logger } from 'firebase-functions/v2';
import { db, storage } from '../shared/admin.js';
import { forEachPage } from '../shared/batch.js';
import { Collections } from '../shared/constants.js';
import { DELETED_USER_NAME } from '../chat/service.js';
import { trySend } from '../notify/service.js';

const DAY_MS = 86_400_000;

/** The fields of a groupDocuments record the server reads. */
export interface DocumentData {
  groupId?: unknown;
  kind?: unknown;
  name?: unknown;
  path?: unknown;
  uploadedBy?: unknown;
  uploaderName?: unknown;
  notifyTeam?: unknown;
}

/** The folder a document's file lives in (ARCH §6.8): `groups/{g}/documents/{docId}/`. */
export function documentFolder(groupId: string, docId: string): string {
  return `groups/${groupId}/documents/${docId}/`;
}

/**
 * Whether a new document tells the team (DOC-6). The uploader can switch
 * "Notify team" off; a record without the field notifies, as the switch
 * starts on.
 */
export function notifiesTeam(data: DocumentData | undefined): boolean {
  return data !== undefined && data.notifyTeam !== false;
}

/** "New document: Fall roster.pdf", or "New link: League site" (DOC-6, NOTIF-5). */
export function documentAddedBody(kind: unknown, name: string): string {
  return `${kind === 'link' ? 'New link' : 'New document'}: ${name.trim()}`;
}

/** Where tapping a document's notification goes (NOTIF-6). */
export function documentRoute(groupId: string, docId: string): string {
  return `/g/${groupId}/documents/d/${docId}`;
}

/**
 * groupDocuments created → documentAdded to the team (DOC-6, NOTIF-2),
 * unless the uploader switched "Notify team" off. The uploader is the
 * actor, so they aren't told and people who blocked them aren't either.
 * Dedupes on the document ID, so a retried trigger notifies once.
 */
export async function notifyDocumentAdded(docId: string, data: DocumentData | undefined): Promise<void> {
  if (!notifiesTeam(data)) return;
  const groupId = String(data!.groupId ?? '');
  const name = String(data!.name ?? '');
  if (!groupId || !name.trim()) return;
  await trySend({
    kind: 'documentAdded',
    groupId,
    recipients: { members: true },
    actor: { uid: String(data!.uploadedBy ?? ''), name: String(data!.uploaderName ?? '') },
    // Deleting the document takes these items too (removeDocumentLeftovers).
    target: { type: 'document', id: docId },
    route: documentRoute(groupId, docId),
    params: { name, kind: data!.kind === 'link' ? 'link' : 'file' },
    body: documentAddedBody(data!.kind, name),
    dedupeKey: `${docId}_added`,
  });
}

/**
 * groupDocuments deleted → its file in Storage (ARCH §6.4 trigger map) and
 * the notification-center items that name it. The whole folder goes, which
 * also takes an earlier upload left in it; the Storage trigger takes the
 * files off the team's total. Links have no file. Safe to retry.
 */
export async function removeDocumentLeftovers(docId: string, data: DocumentData | undefined): Promise<void> {
  const groupId = typeof data?.groupId === 'string' ? data.groupId : '';
  if (groupId && !groupId.includes('/') && !docId.includes('/')) {
    await storage()
      .bucket()
      .deleteFiles({ prefix: documentFolder(groupId, docId) })
      .catch((e) => logger.warn('document_file_cleanup_failed', { docId, error: String(e) }));
  }
  await forEachPage(
    db().collection(Collections.notifications).where('targetType', '==', 'document').where('targetId', '==', docId),
    (batch, item) => batch.delete(item.ref),
  );
}

/** What Media shows of a document file: its record's name and uploader. */
export interface DocumentOfFile {
  name: string;
  uploaderName: string;
  path: string | null;
}

/**
 * The documents behind Media's document files (STORE-5), by document ID,
 * in one getAll per 100. Records of another team are left out, so a file
 * can never show another team's document.
 */
export async function documentsOfFiles(groupId: string, docIds: string[]): Promise<Map<string, DocumentOfFile>> {
  const out = new Map<string, DocumentOfFile>();
  const ids = [...new Set(docIds)];
  for (let i = 0; i < ids.length; i += 100) {
    const refs = ids.slice(i, i + 100).map((id) => db().collection(Collections.groupDocuments).doc(id));
    const snaps = await db().getAll(...refs, { fieldMask: ['groupId', 'name', 'uploaderName', 'path'] });
    for (const s of snaps) {
      if (!s.exists || s.get('groupId') !== groupId) continue;
      out.set(s.id, {
        name: String(s.get('name') ?? ''),
        uploaderName: String(s.get('uploaderName') ?? ''),
        path: typeof s.get('path') === 'string' ? (s.get('path') as string) : null,
      });
    }
  }
  return out;
}

/**
 * Deletes the document whose file is [path] (STORE-5: Media can delete a
 * document's file, and the document goes with it). The record is found by
 * the folder's document ID and must be this team's and point at this very
 * file; an earlier upload left in the same folder leaves the record alone.
 * Returns whether a record was deleted. Its delete trigger then removes the
 * folder and the center items.
 */
export async function deleteDocumentOfFile(groupId: string, docId: string, path: string): Promise<boolean> {
  const ref = db().collection(Collections.groupDocuments).doc(docId);
  return db().runTransaction(async (tx) => {
    const doc = await tx.get(ref);
    if (!doc.exists || doc.get('groupId') !== groupId || doc.get('path') !== path) return false;
    tx.delete(ref);
    return true;
  });
}

/**
 * Which files under a team's documents folder are orphans (dailyCleanup):
 * older than [cutoffMs] (an upload in progress, or one whose document is
 * being saved, is left alone), and either their document doesn't exist (the
 * upload finished but the document was never created) or it points at
 * another file. [docs] maps each existing document ID to its path.
 */
export function orphanDocumentFiles(
  groupId: string,
  files: { name: string; timeCreated?: unknown }[],
  docs: Map<string, string | null>,
  cutoffMs: number,
): string[] {
  const prefix = `groups/${groupId}/documents/`;
  return files
    .filter((f) => {
      if (!f.name.startsWith(prefix)) return false;
      const created = typeof f.timeCreated === 'string' ? Date.parse(f.timeCreated) : NaN;
      if (Number.isNaN(created) || created > cutoffMs) return false;
      const docId = f.name.slice(prefix.length).split('/')[0];
      if (!docId) return false;
      return !docs.has(docId) || docs.get(docId) !== f.name;
    })
    .map((f) => f.name);
}

/**
 * Deletes one team's orphan document files (dailyCleanup): uploads older
 * than a day whose groupDocuments record doesn't exist or points at another
 * file. They'd otherwise hold the team's space for good, with nothing in
 * Documents to delete them from. Returns how many went.
 */
export async function removeOrphanDocumentFiles(groupId: string, now = Date.now()): Promise<number> {
  const [found] = await storage().bucket().getFiles({ prefix: `groups/${groupId}/documents/` });
  if (!found.length) return 0;
  const prefix = `groups/${groupId}/documents/`;
  const ids = found.map((f) => f.name.slice(prefix.length).split('/')[0]).filter((id) => isDocId(id));
  const records = await documentsOfFiles(groupId, ids);
  const docs = new Map([...records].map(([id, d]) => [id, d.path]));
  const orphans = orphanDocumentFiles(
    groupId,
    found.map((f) => ({ name: f.name, timeCreated: f.metadata.timeCreated })),
    docs,
    now - DAY_MS,
  );
  for (const name of orphans) {
    await storage().bucket().file(name).delete({ ignoreNotFound: true });
  }
  if (orphans.length) logger.info('orphan_document_files_removed', { groupId, count: orphans.length });
  return orphans.length;
}

/**
 * Removes orphan document files from every team, a page of teams at a time
 * (ARCH §6.4 dailyCleanup). One team's failure doesn't stop the rest.
 */
export async function removeAllOrphanDocumentFiles(now = Date.now()): Promise<number> {
  let removed = 0;
  let last: FirebaseFirestore.QueryDocumentSnapshot | undefined;
  for (;;) {
    let page = db().collection(Collections.groups).orderBy('__name__').select().limit(200);
    if (last) page = page.startAfter(last);
    const snap = await page.get();
    for (const team of snap.docs) {
      removed += await removeOrphanDocumentFiles(team.id, now).catch((e) => {
        logger.error('orphan_document_cleanup_failed', { groupId: team.id, error: String(e) });
        return 0;
      });
    }
    if (snap.size < 200) break;
    last = snap.docs[snap.docs.length - 1];
  }
  return removed;
}

/**
 * A deleted account's documents stay with the team, shown as added by
 * "Deleted user" (AUTH-10, like its messages). Pages by uploaderName so
 * renamed records drop out of the query.
 */
export async function anonymizeUploader(uid: string): Promise<void> {
  const query = db()
    .collection(Collections.groupDocuments)
    .where('uploadedBy', '==', uid)
    .where('uploaderName', '!=', DELETED_USER_NAME);
  for (;;) {
    const snap = await query.limit(400).get();
    if (snap.empty) break;
    const batch = db().batch();
    snap.docs.forEach((d) => batch.update(d.ref, { uploaderName: DELETED_USER_NAME }));
    await batch.commit();
    if (snap.size < 400) break;
  }
}

/** Whether [id] can name a Firestore document (a member may pick any folder name in Storage). */
function isDocId(id: string): boolean {
  return id !== '' && id !== '.' && id !== '..' && !/^__.*__$/.test(id) && Buffer.byteLength(id) <= 1500;
}

/**
 * Deletes one of a team's documents for a super admin acting on a report
 * (ADMIN-5, SAFE-4). Only a record of [groupId] is deleted; its delete
 * trigger then removes the file and the center items. Returns whether one
 * was deleted.
 */
export async function deleteDocumentOf(groupId: string, docId: string): Promise<boolean> {
  const ref = db().collection(Collections.groupDocuments).doc(docId);
  return db().runTransaction(async (tx) => {
    const doc = await tx.get(ref);
    if (!doc.exists || doc.get('groupId') !== groupId) return false;
    tx.delete(ref);
    return true;
  });
}
