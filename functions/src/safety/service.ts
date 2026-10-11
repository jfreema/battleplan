// Safety domain service: owns userBlocks and reports.
import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../shared/admin.js';
import { Collections } from '../shared/constants.js';
import { forEachPage } from '../shared/batch.js';
import { groupMemberId } from '../shared/ids.js';

/** Deletes the blocks a deleted account made, and blocks of it. */
export async function removeAccountBlocks(uid: string): Promise<void> {
  for (const field of ['uid', 'blockedUid']) {
    await forEachPage(db().collection(Collections.userBlocks).where(field, '==', uid), (b, d) => b.delete(d.ref));
  }
}

export type ReportTarget = 'message' | 'user' | 'document';

/**
 * What the team's admins see of the reported thing, copied when it's
 * reported so the report still makes sense if the content is later deleted.
 */
export async function reportSnapshot(
  groupId: string,
  targetType: ReportTarget,
  targetId: string,
): Promise<{ subjectId: string; subjectName: string; text: string } | null> {
  if (targetType === 'message') {
    const m = await db().collection(Collections.messages).doc(targetId).get();
    if (!m.exists || m.get('groupId') !== groupId) return null;
    const photos = ((m.get('attachments') as unknown[] | undefined) ?? []).length;
    const text = String(m.get('text') ?? '').slice(0, 500);
    return {
      subjectId: String(m.get('authorId') ?? ''),
      subjectName: String(m.get('authorName') ?? ''),
      text: text || (photos ? `${photos} photo${photos === 1 ? '' : 's'}` : ''),
    };
  }
  if (targetType === 'user') {
    const member = await db().collection(Collections.groupMembers).doc(groupMemberId(groupId, targetId)).get();
    if (!member.exists) return null;
    return { subjectId: targetId, subjectName: String(member.get('displayName') ?? ''), text: '' };
  }
  const doc = await db().collection(Collections.groupDocuments).doc(targetId).get();
  if (!doc.exists || doc.get('groupId') !== groupId) return null;
  return {
    subjectId: String(doc.get('uploadedBy') ?? ''),
    subjectName: String(doc.get('uploadedByName') ?? ''),
    text: String(doc.get('title') ?? doc.get('fileName') ?? ''),
  };
}

/** Files a report (SAFE-1). Returns its ID. */
export async function fileReport(input: {
  reporterId: string;
  groupId: string;
  targetType: ReportTarget;
  targetId: string;
  reason: string;
  details?: string;
  snapshot: { subjectId: string; subjectName: string; text: string };
}): Promise<string> {
  const ref = await db()
    .collection(Collections.reports)
    .add({
      reporterId: input.reporterId,
      groupId: input.groupId,
      targetType: input.targetType,
      targetId: input.targetId,
      reason: input.reason,
      details: input.details ?? null,
      subjectId: input.snapshot.subjectId,
      subjectName: input.snapshot.subjectName,
      excerpt: input.snapshot.text,
      status: 'open',
      resolvedBy: null,
      resolution: null,
      createdAt: FieldValue.serverTimestamp(),
    });
  return ref.id;
}
