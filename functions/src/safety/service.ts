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
 * The copy (`excerpt`) is kept only while the report is open: closeReport
 * clears it, so a deleted message's text doesn't outlive the report.
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

/**
 * Whether the team's admins see a report about [subjectRole] (SAFE-1). A
 * report about one of the team's own admins or its owner goes to the
 * super-admin queue only: the rules let a team's admins read its reports,
 * which hold the reporter, and the reported person is never told who
 * reported them, nor gets to dismiss it.
 */
export function teamSeesReport(subjectRole: string | null): boolean {
  return subjectRole !== 'owner' && subjectRole !== 'admin';
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
  /** Whether the team's admins see it (teamSeesReport); super admins always do. */
  teamVisible: boolean;
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
      teamVisible: input.teamVisible,
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
 * done, the super admin's note, and who closed it. The copy of what was
 * reported (`excerpt`) is cleared: it was there for the decision, and the
 * content itself may be deleted now (privacy policy, "Reports"). A report already closed
 * is refused, so two admins can't act on it twice: callers close (claim)
 * it before acting, and reopenReport it if the action then fails. Returns
 * the report as it was, for the action and the audit log.
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
      excerpt: '',
    });
    return report.data()!;
  });
}

/**
 * Puts back a report [resolvedBy] closed with closeReport when the action it
 * claimed the report for then failed (ADMIN-5), so it's still in the open
 * queue, with the [excerpt] closing cleared. A report someone else has
 * since closed is left alone.
 */
export async function reopenReport(reportId: string, resolvedBy: string, excerpt: string): Promise<void> {
  const ref = db().collection(Collections.reports).doc(reportId);
  await db().runTransaction(async (tx) => {
    const report = await tx.get(ref);
    if (!report.exists || report.get('status') === 'open' || report.get('resolvedBy') !== resolvedBy) return;
    tx.update(ref, {
      status: 'open',
      resolution: null,
      resolvedBy: null,
      excerpt,
      note: FieldValue.delete(),
      resolvedAt: FieldValue.delete(),
    });
  });
}

/** An open report, or `not-found` / `already-resolved`, read before acting on it. */
export async function openReport(reportId: string): Promise<FirebaseFirestore.DocumentData> {
  const report = await db().collection(Collections.reports).doc(reportId).get();
  if (!report.exists) throw new HttpsError('not-found', 'No such report.');
  if (report.get('status') !== 'open') throw new HttpsError('failed-precondition', 'already-resolved');
  return report.data()!;
}
