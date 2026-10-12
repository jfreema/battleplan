// Media (STORE-5, ARCH §6.11): every file a team stores, matched to what
// uses it, and deleting one with whatever pointed at it fixed. Callers check
// that the caller is a team admin. The Storage trigger lowers storageBytes
// once a file is gone, which also clears the storage warning.
import { FieldValue } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { photosOfMessages, removeAttachment } from '../chat/service.js';
import { db, storage } from '../shared/admin.js';
import { Collections } from '../shared/constants.js';
import { quotaBytesOf } from './storage.js';

/** What a team file is (ARCH §6.8 layout); 'other' is an orphan nothing uses. */
export type MediaKind = 'chatPhoto' | 'logo' | 'background' | 'document' | 'other';

/** One file in Media, as listTeamMedia returns it. */
export interface MediaItem {
  path: string;
  size: number;
  contentType: string | null;
  /** ISO 8601, from the file's timeCreated. */
  createdAt: string | null;
  kind: MediaKind;
  /** Chat photos: the message the file was uploaded for. */
  messageId?: string;
  /** Chat photos: who sent it, while the message still exists. */
  authorName?: string;
  /** Whether it's still in use: the team's logo or background, or a photo its message still shows. */
  current?: boolean;
}

/**
 * The most files one listing returns: the largest, since those free the
 * most space. 500 MB holds roughly 500 to 1,500 chat photos (PLANS.md), so
 * this is every file of a team on the default limit.
 */
export const MEDIA_LIST_MAX = 2000;

/** Whether [path] is a file of [groupId]'s and can't climb out of its folder. */
export function isTeamMediaPath(groupId: string, path: string): boolean {
  const prefix = `groups/${groupId}/`;
  return !groupId.includes('/') && path.startsWith(prefix) && path.length > prefix.length && !path.includes('..');
}

/**
 * What a file under `groups/{groupId}/` is, from its path alone (the
 * folders in storage.rules): a chat photo (with its message ID), the team
 * logo, a chat background, a document, or anything else.
 */
export function classifyMediaPath(groupId: string, path: string): { kind: MediaKind; messageId?: string } {
  if (!isTeamMediaPath(groupId, path)) return { kind: 'other' };
  const parts = path.slice(`groups/${groupId}/`.length).split('/');
  if (parts.some((p) => p === '')) return { kind: 'other' };
  const [folder] = parts;
  if (folder === 'messages' && parts.length >= 3) return { kind: 'chatPhoto', messageId: parts[1] };
  if (folder === 'avatar' && parts.length === 2) return { kind: 'logo' };
  if (folder === 'theme' && parts.length === 2) return { kind: 'background' };
  if (folder === 'documents' && parts.length === 3) return { kind: 'document' };
  return { kind: 'other' };
}

function isoOrNull(value: unknown): string | null {
  if (typeof value !== 'string' || !value) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

/**
 * Every file the team stores, largest first, with what each belongs to,
 * plus the team's usage and limit (STORE-2, STORE-5). Lists the bucket
 * rather than Firestore, so orphans show up too. The whole folder is
 * scanned (as the daily recount does) so that, past MEDIA_LIST_MAX files,
 * the ones returned are the largest; `truncated` says some were left out.
 */
export async function listMedia(groupId: string): Promise<{
  files: MediaItem[];
  truncated: boolean;
  storageBytes: number;
  storageQuotaBytes: number;
}> {
  const group = await db().collection(Collections.groups).doc(groupId).get();
  if (!group.exists) throw new HttpsError('not-found', 'No such team.');
  const [found] = await storage().bucket().getFiles({ prefix: `groups/${groupId}/` });
  const files: MediaItem[] = found
    .map((f) => ({
      path: f.name,
      size: Number(f.metadata.size ?? 0),
      contentType: f.metadata.contentType ?? null,
      createdAt: isoOrNull(f.metadata.timeCreated),
      ...classifyMediaPath(groupId, f.name),
    }))
    .sort((a, b) => b.size - a.size || a.path.localeCompare(b.path))
    .slice(0, MEDIA_LIST_MAX);

  const photos = await photosOfMessages(
    groupId,
    files.flatMap((f) => (f.kind === 'chatPhoto' && f.messageId ? [f.messageId] : [])),
  );
  const logo = group.get('photoPath') as string | null | undefined;
  const background = group.get('chatTheme.backgroundPath') as string | null | undefined;
  for (const f of files) {
    if (f.kind === 'chatPhoto') {
      const message = photos.get(f.messageId!);
      if (message) f.authorName = message.authorName;
      f.current = message?.paths.includes(f.path) ?? false;
    } else if (f.kind === 'logo') {
      f.current = f.path === logo;
    } else if (f.kind === 'background') {
      f.current = f.path === background;
    }
  }
  return {
    files,
    truncated: found.length > files.length,
    storageBytes: Number(group.get('storageBytes') ?? 0),
    storageQuotaBytes: quotaBytesOf(group.data()),
  };
}

/**
 * Clears the team's logo or chat background when [path] is the one in use
 * (STORE-5: "deleting the logo or background resets it"). Returns whether
 * it was.
 */
async function resetGroupImage(groupId: string, kind: 'logo' | 'background', path: string): Promise<boolean> {
  const ref = db().collection(Collections.groups).doc(groupId);
  return db().runTransaction(async (tx) => {
    const group = await tx.get(ref);
    if (!group.exists) return false;
    if (kind === 'logo' && group.get('photoPath') === path) {
      tx.update(ref, { photoPath: null, updatedAt: FieldValue.serverTimestamp() });
      return true;
    }
    if (kind === 'background' && group.get('chatTheme.backgroundPath') === path) {
      tx.update(ref, {
        'chatTheme.background': 'plain',
        'chatTheme.backgroundPath': null,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return true;
    }
    return false;
  });
}

/** What deleting one file did, for the audit log. */
export interface DeletedMedia {
  kind: MediaKind;
  /** Null when the file was already gone. */
  size: number | null;
  messageId?: string;
  /** What pointed at it and was fixed: the photo's message, or the logo or background. */
  fixed: 'removed' | 'erased' | 'reset' | 'none';
}

/**
 * Deletes one team file and fixes what pointed at it (STORE-5): a chat
 * photo leaves its message (chat removes it, and erases a message left
 * empty), and the logo or background in use is reset. An orphan is just
 * deleted. Safe to retry.
 */
export async function deleteMedia(groupId: string, path: string, actorUid: string): Promise<DeletedMedia> {
  if (!isTeamMediaPath(groupId, path)) throw new HttpsError('invalid-argument', 'bad-path');
  const file = storage().bucket().file(path);
  const size = await file.getMetadata().then(
    ([meta]) => Number(meta.size ?? 0),
    (e: { code?: number }) => {
      if (e.code === 404) return null;
      throw e;
    },
  );
  const { kind, messageId } = classifyMediaPath(groupId, path);
  let fixed: DeletedMedia['fixed'] = 'none';
  // References first, so nothing shows a missing file while it's deleted.
  if (kind === 'chatPhoto') {
    fixed = await removeAttachment(groupId, messageId!, path, actorUid);
  } else if (kind === 'logo' || kind === 'background') {
    fixed = (await resetGroupImage(groupId, kind, path)) ? 'reset' : 'none';
  }
  // Documents (M7) must also remove their groupDocuments record here,
  // through the documents service.
  await file.delete({ ignoreNotFound: true });
  return { kind, size, fixed, ...(messageId ? { messageId } : {}) };
}
