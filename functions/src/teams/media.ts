// Media (STORE-5, ARCH §6.11): every file a team stores, matched to what
// uses it, and deleting one with whatever pointed at it fixed. Callers check
// that the caller is a team admin. The Storage trigger lowers storageBytes
// once a file is gone, which also clears the storage warning.
import { posix } from 'node:path';
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

/**
 * Whether [path] is a file of [groupId]'s and can't climb out of its folder.
 * Object names are literal (the Storage client encodes the whole name), so
 * `..` can't reach another team; still, a name is refused if resolving its
 * `.` and `..` would leave the team's folder. Anything else stays
 * deletable: storage.rules let members name chat files freely (`a..jpg`,
 * `messages/./x.jpg`), and an undeletable file would hold space for good.
 */
export function isTeamMediaPath(groupId: string, path: string): boolean {
  const prefix = `groups/${groupId}/`;
  const inside = (p: string) => p.startsWith(prefix) && p.length > prefix.length;
  return !groupId.includes('/') && inside(path) && inside(posix.normalize(path));
}

/**
 * Whether [id] can name a Firestore document. Storage rules let members
 * pick any message folder name, and one file under `messages/__x__/` must
 * not break Media for the whole team.
 */
function isDocId(id: string): boolean {
  return id !== '.' && id !== '..' && !/^__.*__$/.test(id) && Buffer.byteLength(id) <= 1500;
}

/**
 * What a file under `groups/{groupId}/` is, from its path alone (the
 * folders in storage.rules): a chat photo (with its message ID), the team
 * logo, a chat background, a document, or anything else. A file in a
 * message folder no message could have is an orphan ('other').
 */
export function classifyMediaPath(groupId: string, path: string): { kind: MediaKind; messageId?: string } {
  if (!isTeamMediaPath(groupId, path)) return { kind: 'other' };
  const parts = path.slice(`groups/${groupId}/`.length).split('/');
  if (parts.some((p) => p === '')) return { kind: 'other' };
  const [folder] = parts;
  if (folder === 'messages' && parts.length >= 3 && isDocId(parts[1])) return { kind: 'chatPhoto', messageId: parts[1] };
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
 * The app reads `items` (FunctionsMediaRepository).
 */
export async function listMedia(groupId: string): Promise<{
  items: MediaItem[];
  truncated: boolean;
  storageBytes: number;
  storageQuotaBytes: number;
}> {
  const group = await db().collection(Collections.groups).doc(groupId).get();
  if (!group.exists) throw new HttpsError('not-found', 'No such team.');
  const [found] = await storage().bucket().getFiles({ prefix: `groups/${groupId}/` });
  const items: MediaItem[] = found
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
    items.flatMap((f) => (f.kind === 'chatPhoto' && f.messageId ? [f.messageId] : [])),
  );
  const logo = group.get('photoPath') as string | null | undefined;
  // A photo is the background in use only while Photo is picked: Chat look
  // keeps the path after switching to Pattern or Plain, so switching back
  // needs no new upload.
  const background =
    group.get('chatTheme.background') === 'photo'
      ? (group.get('chatTheme.backgroundPath') as string | null | undefined)
      : null;
  for (const f of items) {
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
    items,
    truncated: found.length > items.length,
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
      // Only a background showing this photo goes back to Plain; a kept
      // path behind Pattern or Plain is just cleared.
      const inUse = group.get('chatTheme.background') === 'photo';
      tx.update(ref, {
        ...(inUse ? { 'chatTheme.background': 'plain' } : {}),
        'chatTheme.backgroundPath': null,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return inUse;
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
