// Importing a team's chat and files from GroupMe (SPEC IMPORT-9, ARCH
// §6.13). The app reads GroupMe's data export on the admin's device and
// sends its messages here in batches, oldest first, with each message's
// photos already uploaded to that message's own folder (as the composer
// does), and each file to its document's folder. This checks the batch and
// writes it as GroupMe had it: the author's GroupMe name, the original
// time, and replies' quotes. Nothing notifies: a team's history arriving
// at once would flood everyone (IMPORT-5).
import { createHash } from 'node:crypto';
import { Timestamp, type DocumentData } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { audit } from '../audit/service.js';
import { filtersLanguage, replyPreviewOf, touchLastMessage } from '../chat/service.js';
import { maskStrongLanguage } from '../safety/strong_language.js';
import { db, storage } from '../shared/admin.js';
import { Collections, Limits } from '../shared/constants.js';
import { consumeRateLimits } from '../shared/rate_limit.js';
import { requireTeamAdmin } from '../shared/roles.js';
import { quotaBytesOf } from '../teams/storage.js';
import type { Caller } from './service.js';

/**
 * Apps a team's chat and files can come from: GroupMe's chat and files
 * (IMPORT-9), and files downloaded from TeamSnap (IMPORT-11, documents
 * only).
 */
export const chatSources = ['groupme', 'teamsnap'] as const;
export type ChatSource = (typeof chatSources)[number];
/** Apps whose chat history comes along: only GroupMe exports it. */
export const messageSources = ['groupme'] as const;

/** Messages, or documents, in one call. */
export const MESSAGES_PER_CALL = 500;
export const DOCUMENTS_PER_CALL = 50;
/**
 * Calls per team per day, checks included: a batch is checked, then
 * written, so this is about 250,000 messages a day.
 */
export const CHAT_IMPORT_CALLS_PER_TEAM_PER_DAY = 1000;

/** Who wrote an imported message: never a Battleplan account (IMPORT-4). */
export function importedAuthorId(source: ChatSource, authorSourceId: string): string {
  return `${source}:${authorSourceId}`;
}

/**
 * A message's or document's ID in Battleplan: the same for the same team,
 * source, and item, so importing again adds only what's new (IMPORT-5).
 * The app works out the same ID, to upload photos and files to its folder
 * first (lib/features/imports/domain/groupme_export.dart).
 */
export function importedItemId(groupId: string, source: ChatSource, kind: 'message' | 'document', sourceId: string): string {
  return 'imp-' + createHash('sha256').update(`${groupId}\n${source}\n${kind}\n${sourceId}`).digest('hex').slice(0, 28);
}

export interface ImportedPhoto {
  path: string;
  width: number;
  height: number;
}

export interface ImportedMessage {
  /** The message's ID in the source. */
  sourceId: string;
  authorSourceId: string;
  authorName: string;
  text: string;
  createdAtMs: number;
  /** The message it replies to, in the source. */
  replyToSourceId?: string;
  photos: ImportedPhoto[];
}

export interface MessageImportInput {
  groupId: string;
  source: ChatSource;
  messages: ImportedMessage[];
  /**
   * Only says which are already here ([MessageImportResult.existing]), so
   * the app uploads photos only for new ones. Writes nothing.
   */
  dryRun?: boolean;
}

export interface MessageImportResult {
  /** New messages: to add on a dry run, added otherwise. */
  added: number;
  alreadyImported: number;
  /** Photos that weren't in their message's folder, left off. */
  photosMissing: number;
  /** On a dry run: the source IDs already imported. */
  existing?: string[];
}

export interface ImportedDocument {
  sourceId: string;
  name: string;
  /** Where the app uploaded it: the document's own folder. */
  path: string;
  sharedByName: string;
  sharedAtMs: number;
}

export interface DocumentImportInput {
  groupId: string;
  source: ChatSource;
  documents: ImportedDocument[];
  /** As for messages: which are already here, writing nothing. */
  dryRun?: boolean;
}

export interface DocumentImportResult {
  added: number;
  alreadyImported: number;
  /** Files that weren't uploaded, left out. */
  missing: number;
  /** On a dry run: the source IDs already imported. */
  existing?: string[];
}

/** A Storage file's type and size, or null when it isn't there. */
async function fileInfo(path: string): Promise<{ contentType: string; size: number } | null> {
  try {
    const [meta] = await storage().bucket().file(path).getMetadata();
    return { contentType: String(meta.contentType ?? ''), size: Number(meta.size ?? 0) };
  } catch (e) {
    if ((e as { code?: number }).code === 404) return null;
    throw e;
  }
}

/** Runs [work] on [items], [limit] at a time. */
async function inParallel<T, R>(items: T[], limit: number, work: (item: T) => Promise<R>): Promise<R[]> {
  const out: R[] = new Array(items.length);
  let next = 0;
  await Promise.all(
    Array.from({ length: Math.min(limit, items.length) }, async () => {
      while (next < items.length) {
        const i = next++;
        out[i] = await work(items[i]);
      }
    }),
  );
  return out;
}

const clampSide = (n: number) => (Number.isFinite(n) && n > 0 ? Math.min(Math.round(n), 20_000) : 0);

/**
 * Writes a batch of a team's history (IMPORT-9). Team admins (and super
 * admins) only, on an open team. Messages already imported are left as
 * they are; photos must be in their message's folder, and any that aren't
 * are left off. A reply quotes the message it answers when that was
 * imported, in this batch or before.
 */
export async function importMessages(input: MessageImportInput, caller: Caller, nowMs = Date.now()): Promise<MessageImportResult> {
  await requireTeamAdmin(input.groupId, caller.uid, caller.superAdmin);
  await consumeRateLimits([{ key: input.groupId, action: 'importChat', max: CHAT_IMPORT_CALLS_PER_TEAM_PER_DAY }]);
  const g = input.groupId;
  const col = db().collection(Collections.messages);
  // One of each, in the order sent.
  const byId = new Map<string, ImportedMessage>();
  for (const m of input.messages) byId.set(importedItemId(g, input.source, 'message', m.sourceId), m);
  const ids = [...byId.keys()];
  const existing = new Set((await db().getAll(...ids.map((id) => col.doc(id)))).filter((d) => d.exists).map((d) => d.id));
  const fresh = ids.filter((id) => !existing.has(id));
  if (input.dryRun) {
    return { added: fresh.length, alreadyImported: existing.size, photosMissing: 0, existing: [...existing].map((id) => byId.get(id)!.sourceId) };
  }

  // Photos: only files in the message's own folder that are really there.
  let photosMissing = 0;
  const attachments = new Map<string, DocumentData[]>();
  await inParallel(fresh, 8, async (id) => {
    const list: DocumentData[] = [];
    for (const p of byId.get(id)!.photos.slice(0, Limits.messageAttachmentsMax)) {
      const info = p.path.startsWith(`groups/${g}/messages/${id}/`) && !p.path.includes('..') ? await fileInfo(p.path) : null;
      if (!info || !info.contentType.startsWith('image/')) {
        photosMissing++;
        continue;
      }
      list.push({ path: p.path, contentType: info.contentType, width: clampSide(p.width), height: clampSide(p.height), size: info.size });
    }
    attachments.set(id, list);
  });

  // The messages replies quote: in this batch, or imported before.
  const quoted = new Map<string, DocumentData | undefined>();
  const wanted = new Set<string>();
  for (const id of fresh) {
    const to = byId.get(id)!.replyToSourceId;
    if (to) wanted.add(importedItemId(g, input.source, 'message', to));
  }
  const elsewhere = [...wanted].filter((id) => !byId.has(id) || existing.has(id));
  if (elsewhere.length) {
    for (const d of await db().getAll(...elsewhere.map((id) => col.doc(id)))) {
      quoted.set(d.id, d.exists && d.get('groupId') === g ? d.data() : undefined);
    }
  }

  // The team's language filter covers imported history too (SAFE-7).
  const filter = await filtersLanguage(g);
  const docs = new Map<string, DocumentData>();
  for (const id of fresh) {
    const m = byId.get(id)!;
    const photos = attachments.get(id) ?? [];
    const raw = m.text.slice(0, Limits.messageTextMax);
    const text = filter ? maskStrongLanguage(raw) : raw;
    if (!text.trim() && photos.length === 0) continue;
    docs.set(id, {
      groupId: g,
      authorId: importedAuthorId(input.source, m.authorSourceId),
      authorName: m.authorName.trim().slice(0, 60) || 'Imported member',
      authorPhotoPath: null,
      type: photos.length ? 'image' : 'text',
      text,
      attachments: photos,
      mentions: [],
      reactions: {},
      createdAt: Timestamp.fromMillis(m.createdAtMs),
      imported: { source: input.source, sourceId: m.sourceId, importedBy: caller.uid, importedAt: Timestamp.fromMillis(nowMs) },
    });
  }
  // Replies, once every message in the batch is known.
  for (const [id, data] of docs) {
    const to = byId.get(id)!.replyToSourceId;
    if (!to) continue;
    const originalId = importedItemId(g, input.source, 'message', to);
    const original = docs.get(originalId) ?? quoted.get(originalId);
    data.replyToId = originalId;
    data.replyPreview = replyPreviewOf(original);
  }

  const written = [...docs.entries()];
  for (let i = 0; i < written.length; i += 400) {
    const batch = db().batch();
    for (const [id, data] of written.slice(i, i + 400)) batch.create(col.doc(id), data);
    await batch.commit();
  }
  // The team list shows the newest message, if these are newer (CHAT-9).
  const newest = written.reduce<DocumentData | null>(
    (a, [, d]) => (!a || (d.createdAt as Timestamp).toMillis() > (a.createdAt as Timestamp).toMillis() ? d : a),
    null,
  );
  if (newest) await touchLastMessage(g, newest);
  if (written.length) {
    await audit({
      actorId: caller.uid,
      action: 'importMessages',
      groupId: g,
      targetType: 'group',
      targetId: g,
      after: { source: input.source, added: written.length, alreadyImported: existing.size, photosMissing },
    });
  }
  return { added: written.length, alreadyImported: existing.size, photosMissing };
}

/**
 * Adds files shared in the source as the team's documents (IMPORT-9), each
 * already uploaded to its document's folder. "Added by" names who shared
 * it there; the admin who imported it can edit or delete it like their
 * own. No "new document" notification (DOC-6).
 */
export async function importDocuments(input: DocumentImportInput, caller: Caller, nowMs = Date.now()): Promise<DocumentImportResult> {
  await requireTeamAdmin(input.groupId, caller.uid, caller.superAdmin);
  await consumeRateLimits([{ key: input.groupId, action: 'importChat', max: CHAT_IMPORT_CALLS_PER_TEAM_PER_DAY }]);
  const g = input.groupId;
  const col = db().collection(Collections.groupDocuments);
  const byId = new Map<string, ImportedDocument>();
  for (const d of input.documents) byId.set(importedItemId(g, input.source, 'document', d.sourceId), d);
  const ids = [...byId.keys()];
  const existing = new Set((await db().getAll(...ids.map((id) => col.doc(id)))).filter((d) => d.exists).map((d) => d.id));
  const fresh = ids.filter((id) => !existing.has(id));
  if (input.dryRun) {
    return { added: fresh.length, alreadyImported: existing.size, missing: 0, existing: [...existing].map((id) => byId.get(id)!.sourceId) };
  }
  if (fresh.length) {
    const team = (await db().collection(Collections.groups).doc(g).get()).data();
    // STORE-4: a full team takes no new files (the uploads were refused too).
    if (!(Number(team?.storageBytes ?? 0) < quotaBytesOf(team))) throw new HttpsError('failed-precondition', 'storage-full');
  }
  let missing = 0;
  const infos = await inParallel(fresh, 8, async (id) => {
    const d = byId.get(id)!;
    const ok = d.path.startsWith(`groups/${g}/documents/${id}/`) && d.path.split('/').length === 5 && !d.path.includes('..');
    return ok ? fileInfo(d.path) : null;
  });
  const batch = db().batch();
  let added = 0;
  fresh.forEach((id, i) => {
    const d = byId.get(id)!;
    const info = infos[i];
    if (!info) {
      missing++;
      return;
    }
    const name = d.name.trim().slice(0, 100) || 'File';
    const at = Timestamp.fromMillis(d.sharedAtMs);
    batch.create(col.doc(id), {
      groupId: g,
      kind: 'file',
      name,
      nameLower: name.toLowerCase(),
      description: '',
      pinned: false,
      path: d.path,
      contentType: info.contentType,
      size: info.size,
      uploadedBy: caller.uid,
      uploaderName: d.sharedByName.trim().slice(0, 60) || 'Team admin',
      notifyTeam: false,
      createdAt: at,
      updatedAt: at,
      imported: { source: input.source, sourceId: d.sourceId, importedBy: caller.uid, importedAt: Timestamp.fromMillis(nowMs) },
    });
    added++;
  });
  if (added) {
    await batch.commit();
    await audit({
      actorId: caller.uid,
      action: 'importDocuments',
      groupId: g,
      targetType: 'group',
      targetId: g,
      after: { source: input.source, added, alreadyImported: existing.size, missing },
    });
  }
  return { added, alreadyImported: existing.size, missing };
}
