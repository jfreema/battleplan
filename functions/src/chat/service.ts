// Chat domain service: owns messages.
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { db, storage } from '../shared/admin.js';
import { forEachPage } from '../shared/batch.js';
import { Collections } from '../shared/constants.js';
import { trySend } from '../notify/service.js';
import { deletePoll, pollCreatedBody } from '../polls/service.js';

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

/** Who wrote the message a reply quotes, for the reply notification. */
export interface QuotedMessage {
  authorId: string;
  deleted: boolean;
}

/**
 * Writes the quote on a reply. The original must be in the same team; a
 * missing or foreign original reads as deleted. Returns who wrote the
 * original (null when it's missing or foreign).
 */
export async function writeReplyPreview(
  messageId: string,
  groupId: string,
  replyToId: string,
): Promise<QuotedMessage | null> {
  const original = await db().collection(Collections.messages).doc(replyToId).get();
  const data = original.exists && original.get('groupId') === groupId ? original.data() : undefined;
  await db()
    .collection(Collections.messages)
    .doc(messageId)
    .update({ replyPreview: replyPreviewOf(data) });
  return data ? { authorId: String(data.authorId ?? ''), deleted: Boolean(data.deletedAt) } : null;
}

/** The fields that turn a message into a deleted placeholder (CHAT-8). */
function erasedFields(deletedBy: string, reason: 'author' | 'admin' | 'media'): Record<string, unknown> {
  return {
    text: '',
    attachments: [],
    reactions: {},
    replyPreview: FieldValue.delete(),
    deletedAt: FieldValue.serverTimestamp(),
    deletedBy,
    deletedReason: reason,
  };
}

/**
 * What follows erasing a message: the notification-center items that quote
 * it, its photos, and the quotes on replies to it.
 */
async function afterErase(messageId: string, groupId: string): Promise<void> {
  // Notification-center items about it go too: their bodies quote the text
  // (CHAT-8 erases it from the server, not just the chat).
  await forEachPage(
    db()
      .collection(Collections.notifications)
      .where('targetType', '==', 'message')
      .where('targetId', '==', messageId),
    (batch, item) => batch.delete(item.ref),
  );
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
  await ref.update(erasedFields(deletedBy, reason));
  // Deleting a poll's message deletes the poll and its votes (POLL-5).
  if (message.get('type') === 'poll') await deletePoll(String(message.get('pollId') ?? messageId));
  await afterErase(messageId, message.get('groupId') as string);
}

/** The parts of a message photo this service reads (ARCH §6.2 attachments). */
interface AttachmentRef {
  path?: unknown;
  thumbPath?: unknown;
}

/** Who sent a message's photos, and which files it still shows (Media, STORE-5). */
export interface MessagePhotos {
  authorName: string;
  paths: string[];
}

/**
 * The photos of [messageIds] that are still in [groupId]'s chat, keyed by
 * message ID. Missing, deleted, and other teams' messages are left out.
 * One masked getAll per 100 messages, not a read per file (ENG-5).
 */
export async function photosOfMessages(groupId: string, messageIds: string[]): Promise<Map<string, MessagePhotos>> {
  const out = new Map<string, MessagePhotos>();
  const ids = [...new Set(messageIds)];
  for (let i = 0; i < ids.length; i += 100) {
    const refs = ids.slice(i, i + 100).map((id) => db().collection(Collections.messages).doc(id));
    const snaps = await db().getAll(...refs, { fieldMask: ['groupId', 'authorName', 'attachments', 'deletedAt'] });
    for (const s of snaps) {
      if (!s.exists || s.get('groupId') !== groupId || s.get('deletedAt')) continue;
      const attachments = (s.get('attachments') as AttachmentRef[] | undefined) ?? [];
      out.set(s.id, {
        authorName: String(s.get('authorName') ?? ''),
        paths: attachments
          .flatMap((a) => [a.path, a.thumbPath])
          .filter((p): p is string => typeof p === 'string'),
      });
    }
  }
  return out;
}

/**
 * Takes one photo off a message after a team admin deleted it in Media
 * (STORE-5). A message left with no text and no photos is erased the way an
 * admin deletion is (CHAT-8: "Removed by a team admin"); one left with only
 * its caption becomes a text message, so `image` keeps meaning at least one
 * photo, as the create rule requires (attachmentsOk). The photo and its
 * thumbnail go too, and the Storage trigger takes them off the team's
 * total. Returns 'none' when the message isn't [groupId]'s or doesn't have
 * that photo.
 */
export async function removeAttachment(
  groupId: string,
  messageId: string,
  path: string,
  deletedBy: string,
): Promise<'removed' | 'erased' | 'none'> {
  const ref = db().collection(Collections.messages).doc(messageId);
  const result = await db().runTransaction(async (tx) => {
    const message = await tx.get(ref);
    if (!message.exists || message.get('groupId') !== groupId || message.get('deletedAt')) return null;
    const attachments = (message.get('attachments') as AttachmentRef[] | undefined) ?? [];
    const removed = attachments.filter((a) => a.path === path);
    if (!removed.length) return null;
    const left = attachments.filter((a) => !removed.includes(a));
    const erase = left.length === 0 && String(message.get('text') ?? '').trim() === '';
    tx.update(
      ref,
      // 'media': its last photo was deleted in Media, so the chat says
      // "Photo removed by a team admin" (STORE-5).
      erase ? erasedFields(deletedBy, 'media') : { attachments: left, ...(left.length ? {} : { type: 'text' }) },
    );
    return { erase, removed };
  });
  if (!result) return 'none';
  if (result.erase) {
    await afterErase(messageId, groupId);
    return 'erased';
  }
  // Only files in this message's own folder: the rules don't check
  // thumbPath, so it must never lead to another team's files.
  const folder = `groups/${groupId}/messages/${messageId}/`;
  const files = result.removed
    .flatMap((a) => [a.path, a.thumbPath])
    .filter((p): p is string => typeof p === 'string' && p.startsWith(folder) && !p.includes('..'));
  await Promise.all(files.map((p) => storage().bucket().file(p).delete({ ignoreNotFound: true })));
  return 'removed';
}

/** The switcher's one-line preview of a message: "Photo" for photos. */
export function lastMessagePreviewOf(m: Record<string, unknown>): { authorName: string; text: string; type: string } {
  const type = String(m.type ?? 'text');
  const firstLine = String(m.text ?? '').split('\n')[0].trim();
  // A poll's text is its question (POLL-1): "Poll: Saturday or Sunday?".
  // An event card's is its summary (CHAT-11): "Event: Practice · Tue, Oct 13 at 6:00 PM".
  const label = type === 'poll' ? 'Poll' : type === 'event' ? 'Event' : null;
  const text = label
    ? firstLine
      ? `${label}: ${firstLine}`
      : label
    : firstLine || (type === 'image' ? 'Photo' : '');
  return {
    authorName: String(m.authorName ?? ''),
    text: text.length > 80 ? `${text.slice(0, 79)}…` : text,
    type,
  };
}

/**
 * Moves the team's `lastMessageAt` and preview forward to [message]. Runs
 * in a transaction and never moves backward, since triggers can arrive out
 * of order or twice. Returns the team's name (null if the team is gone),
 * so the message's notification needn't read the team again.
 */
export async function touchLastMessage(groupId: string, message: Record<string, unknown>): Promise<string | null> {
  const at = message.createdAt as Timestamp | undefined;
  if (!at) return null;
  const ref = db().collection(Collections.groups).doc(groupId);
  return db().runTransaction(async (tx) => {
    const group = await tx.get(ref);
    if (!group.exists) return null;
    const name = (group.get('name') as string | undefined) ?? '';
    const current = group.get('lastMessageAt') as Timestamp | undefined;
    if (current && current.toMillis() >= at.toMillis()) return name;
    tx.update(ref, { lastMessageAt: at, lastMessagePreview: lastMessagePreviewOf(message) });
    return name;
  });
}

/**
 * Whether a new message notifies as a message (ARCH §6.4 trigger map): text
 * and photos. Polls notify as pollCreated; system lines and event cards
 * notify through their own domain.
 */
export function notifiesAsMessage(m: Record<string, unknown>): boolean {
  return m.type === 'text' || m.type === 'image';
}

/**
 * Who gets the "replied to you" notification (NOTIF-2): the original's
 * author, unless it was a system line, they're replying to themselves, or
 * the original is deleted.
 */
export function replyRecipientOf(original: QuotedMessage | null, replierId: string): string | null {
  if (!original || original.deleted) return null;
  const { authorId } = original;
  if (!authorId || authorId === 'system' || authorId === replierId) return null;
  return authorId;
}

function pushWording(m: Record<string, unknown>): { name: string; text: string; photos: number } {
  return {
    name: String(m.authorName ?? '').trim() || 'Someone',
    text: String(m.text ?? '').trim(),
    photos: ((m.attachments as unknown[] | undefined) ?? []).length,
  };
}

function photosPhrase(photos: number): string {
  return photos > 1 ? `${photos} photos` : 'a photo';
}

/** A message's push (NOTIF-5): "Alex: Field 3 is open", or "Alex sent a photo". */
export function messagePushBody(m: Record<string, unknown>): string {
  const { name, text, photos } = pushWording(m);
  if (text) return `${name}: ${text}`;
  return m.type === 'image' || photos ? `${name} sent ${photosPhrase(photos)}` : `${name} sent a message`;
}

/** A reply's push to the person quoted (NOTIF-5): "Alex replied to you: Sounds good". */
export function replyPushBody(m: Record<string, unknown>): string {
  const { name, text, photos } = pushWording(m);
  if (text) return `${name} replied to you: ${text}`;
  return `${name} replied to you with ${photosPhrase(Math.max(photos, 1))}`;
}

/**
 * Notifies a new message (NOTIF-2): the person replied to gets "replied to
 * you" (it pushes even at Important only and lands in their notification
 * center), and everyone else but the author gets the plain message push.
 * They're left out of the plain push only when the reply push was for
 * them: with Replies switched off (NOTIF-4) but Messages on, a reply still
 * reaches them like any other message. Both dedupe on the message ID,
 * since the trigger can run twice.
 */
export async function notifyNewMessage(
  messageId: string,
  message: Record<string, unknown>,
  teamName: string | null,
  repliedTo: string | null,
): Promise<void> {
  const isPoll = message.type === 'poll';
  if (!isPoll && !notifiesAsMessage(message)) return;
  const groupId = message.groupId as string;
  const actor = { uid: String(message.authorId ?? ''), name: String(message.authorName ?? '') };
  const common = {
    groupId,
    actor,
    target: { type: 'message', id: messageId },
    route: `/g/${groupId}/chat/m/${messageId}`,
    params: { authorName: actor.name },
    ...(teamName !== null ? { teamName } : {}),
  };
  if (isPoll) {
    // A new poll (POLL-1, NOTIF-2): the poll's message text is its question.
    await trySend({
      ...common,
      kind: 'pollCreated',
      recipients: { members: true },
      body: pollCreatedBody(actor.name, String(message.text ?? '')),
      dedupeKey: messageId,
    });
    return;
  }
  const repliedPushed = repliedTo
    ? await trySend({
        ...common,
        kind: 'reply',
        recipients: { uids: [repliedTo] },
        body: replyPushBody(message),
        dedupeKey: `${messageId}_reply`,
      })
    : [];
  await trySend({
    ...common,
    kind: 'message',
    recipients: { members: true },
    exclude: repliedPushed,
    body: messagePushBody(message),
    dedupeKey: messageId,
  });
}

/** Rewrites the quote on every reply to [messageId] from its new text. */
export async function refreshReplyPreviews(messageId: string, original: Record<string, unknown>): Promise<void> {
  const preview = replyPreviewOf(original);
  await forEachPage(db().collection(Collections.messages).where('replyToId', '==', messageId), (batch, reply) =>
    batch.update(reply.ref, { replyPreview: preview }),
  );
}
