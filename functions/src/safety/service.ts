// Safety domain service: owns userBlocks and reports.
import { FieldValue } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
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
  // The name admins see in Reports, with the uploader's snapshot name (M7).
  return {
    subjectId: String(doc.get('uploadedBy') ?? ''),
    subjectName: String(doc.get('uploaderName') ?? ''),
    text: String(doc.get('name') ?? '').slice(0, 500),
  };
}

/** The admins' notification for a report (NOTIF-2): what was reported, never by whom. */
export function reportedBody(targetType: ReportTarget): string {
  return targetType === 'user'
    ? 'A person was reported'
    : targetType === 'document'
      ? 'A document was reported'
      : 'A message was reported';
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

/** How a report was closed (ARCH §6.2 reports.resolution). */
export type ReportResolution =
  | 'deletedMessage'
  | 'deletedDocument'
  | 'removedMember'
  | 'disabledUser'
  | 'suspendedTeam'
  | 'none';

/**
 * Closes an open report from the admin panel (ADMIN-5): its status, what was
 * done, the super admin's note, and who closed it. A report already closed
 * is refused, so two admins can't act on it twice. Returns the report as it
 * was, for the action and the audit log.
 */
export async function closeReport(
  reportId: string,
  close: { status: 'actioned' | 'dismissed'; resolution: ReportResolution; note: string; resolvedBy: string },
): Promise<FirebaseFirestore.DocumentData> {
  const ref = db().collection(Collections.reports).doc(reportId);
  return db().runTransaction(async (tx) => {
    const report = await tx.get(ref);
    if (!report.exists) throw new HttpsError('not-found', 'No such report.');
    if (report.get('status') !== 'open') throw new HttpsError('failed-precondition', 'already-resolved');
    tx.update(ref, {
      status: close.status,
      resolution: close.resolution,
      note: close.note,
      resolvedBy: close.resolvedBy,
      resolvedAt: FieldValue.serverTimestamp(),
    });
    return report.data()!;
  });
}

/** An open report, or `not-found` / `already-resolved`, read before acting on it. */
export async function openReport(reportId: string): Promise<FirebaseFirestore.DocumentData> {
  const report = await db().collection(Collections.reports).doc(reportId).get();
  if (!report.exists) throw new HttpsError('not-found', 'No such report.');
  if (report.get('status') !== 'open') throw new HttpsError('failed-precondition', 'already-resolved');
  return report.data()!;
}
