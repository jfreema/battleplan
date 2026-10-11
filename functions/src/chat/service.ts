// Chat domain service: owns messages.
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { db, storage } from '../shared/admin.js';
import { forEachPage } from '../shared/batch.js';
import { Collections } from '../shared/constants.js';

export const DELETED_USER_NAME = 'Deleted user';

/** A deleted account's past messages stay, shown from "Deleted user" (AUTH-10). */
export async function anonymizeAuthor(uid: string): Promise<void> {
  // Updates don't move documents out of an authorId query, so page by cursor
  // over authorName instead: renamed messages drop out of the query.
  const query = db()
    .collection(Collections.messages)
    .where('authorId', '==', uid)
    .where('authorName', '!=', DELETED_USER_NAME);
  for (;;) {
    const snap = await query.limit(400).get();
    if (snap.empty) break;
    const batch = db().batch();
    snap.docs.forEach((d) =>
      batch.update(d.ref, { authorName: DELETED_USER_NAME, authorPhotoPath: null, authorPlayerSummary: null }),
    );
    await batch.commit();
    if (snap.size < 400) break;
  }
}

export type SystemEventKind = 'joined' | 'left' | 'removed' | 'madeAdmin' | 'renamed';

/**
 * Posts a small centered line in a team's chat (CHAT-10): "Sam joined",
 * "Alex is now an admin". Only Functions write system messages.
 */
export async function postSystemMessage(
  groupId: string,
  kind: SystemEventKind,
  text: string,
  actorId: string,
  targetId?: string,
): Promise<void> {
  await db().collection(Collections.messages).add({
    groupId,
    authorId: 'system',
    authorName: '',
    authorPhotoPath: null,
    authorPlayerSummary: null,
    type: 'system',
    text,
    attachments: [],
    reactions: {},
    systemEvent: { kind, actorId, targetId: targetId ?? null },
    createdAt: FieldValue.serverTimestamp(),
  });
}

/** What a reply shows of the message it quotes (ARCH §6.2 replyPreview). */
export interface ReplyPreview {
  authorName: string;
  text: string;
  type: string;
  deleted: boolean;
}

/** The quote for [original]: the author and first line, up to 120 characters. */
export function replyPreviewOf(original: Record<string, unknown> | undefined): ReplyPreview {
  if (!original || original.deletedAt) return { authorName: '', text: '', type: 'text', deleted: true };
  const firstLine = String(original.text ?? '').split('\n')[0].trim();
  return {
    authorName: String(original.authorName ?? ''),
    text: firstLine.length > 120 ? `${firstLine.slice(0, 119)}…` : firstLine,
    type: String(original.type ?? 'text'),
    deleted: false,
  };
}

/**
 * Writes the quote on a reply. The original must be in the same team; a
 * missing or foreign original reads as deleted.
 */
export async function writeReplyPreview(messageId: string, groupId: string, replyToId: string): Promise<void> {
  const original = await db().collection(Collections.messages).doc(replyToId).get();
  const data = original.exists && original.get('groupId') === groupId ? original.data() : undefined;
  await db()
    .collection(Collections.messages)
    .doc(messageId)
    .update({ replyPreview: replyPreviewOf(data) });
}

/**
 * Erases a message (CHAT-8): the text, photos, reactions, and quote are
 * removed from the server, not hidden, and the message becomes a
 * placeholder ("This message was deleted" or "Removed by a team admin").
 * Replies that quoted it now show "Original message was deleted".
 */
export async function eraseMessage(
  messageId: string,
  deletedBy: string,
  reason: 'author' | 'admin',
): Promise<void> {
  const ref = db().collection(Collections.messages).doc(messageId);
  const message = await ref.get();
  if (!message.exists || message.get('deletedAt')) return;
  const groupId = message.get('groupId') as string;
  await ref.update({
    text: '',
    attachments: [],
    reactions: {},
    replyPreview: FieldValue.delete(),
    deletedAt: FieldValue.serverTimestamp(),
    deletedBy,
    deletedReason: reason,
  });
  // Photos go too; the Storage trigger takes them off the team's total.
  await storage()
    .bucket()
    .deleteFiles({ prefix: `groups/${groupId}/messages/${messageId}/` })
    .catch(() => undefined);
  await forEachPage(
    db().collection(Collections.messages).where('replyToId', '==', messageId),
    (batch, reply) =>
      batch.update(reply.ref, { replyPreview: { authorName: '', text: '', type: 'text', deleted: true } }),
  );
}

/** The switcher's one-line preview of a message: "Photo" for photos. */
export function lastMessagePreviewOf(m: Record<string, unknown>): { authorName: string; text: string; type: string } {
  const type = String(m.type ?? 'text');
  const firstLine = String(m.text ?? '').split('\n')[0].trim();
  const text = firstLine || (type === 'image' ? 'Photo' : type === 'poll' ? 'Poll' : '');
  return {
    authorName: String(m.authorName ?? ''),
    text: text.length > 80 ? `${text.slice(0, 79)}…` : text,
    type,
  };
}

/**
 * Moves the team's `lastMessageAt` and preview forward to [message]. Runs
 * in a transaction and never moves backward, since triggers can arrive out
 * of order or twice.
 */
export async function touchLastMessage(groupId: string, message: Record<string, unknown>): Promise<void> {
  const at = message.createdAt as Timestamp | undefined;
  if (!at) return;
  const ref = db().collection(Collections.groups).doc(groupId);
  await db().runTransaction(async (tx) => {
    const group = await tx.get(ref);
    if (!group.exists) return;
    const current = group.get('lastMessageAt') as Timestamp | undefined;
    if (current && current.toMillis() >= at.toMillis()) return;
    tx.update(ref, { lastMessageAt: at, lastMessagePreview: lastMessagePreviewOf(message) });
  });
}

/** Rewrites the quote on every reply to [messageId] from its new text. */
export async function refreshReplyPreviews(messageId: string, original: Record<string, unknown>): Promise<void> {
  const preview = replyPreviewOf(original);
  await forEachPage(db().collection(Collections.messages).where('replyToId', '==', messageId), (batch, reply) =>
    batch.update(reply.ref, { replyPreview: preview }),
  );
}
