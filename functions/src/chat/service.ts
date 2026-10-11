// Chat domain service: owns messages.
import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../shared/admin.js';
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
