// Thin entry points for the safety domain (ARCH §6.4).
import { FieldValue } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { audit } from '../audit/service.js';
import { db } from '../shared/admin.js';
import { Collections, Limits, reportReasonValues } from '../shared/constants.js';
import { requireAuth } from '../shared/guards.js';
import { consumeRateLimit } from '../shared/rate_limit.js';
import { requireTeamAdmin, roleOf } from '../shared/roles.js';
import { parse } from '../shared/validate.js';
import { trySend } from '../notify/service.js';
import { fileReport, reportedBody, reportSnapshot } from './service.js';

const ReportInput = z.object({
  groupId: z.string().min(1),
  targetType: z.enum(['message', 'user', 'document']),
  targetId: z.string().min(1).max(128),
  reason: z.enum(reportReasonValues),
  details: z.string().trim().max(1000).optional(),
});

/**
 * Reports a message, document, or person to the team's admins and the
 * super-admin queue (SAFE-1). Members only; 20 a day. The reported person
 * is never told, and admins aren't shown who reported.
 */
export const reportContent = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = parse(ReportInput, request.data);
  if (!(await roleOf(input.groupId, uid))) throw new HttpsError('permission-denied', 'Not a member.');
  if (input.targetType === 'user' && input.targetId === uid) {
    throw new HttpsError('invalid-argument', 'You cannot report yourself.');
  }
  await consumeRateLimit(uid, 'report', Limits.reportsPerUserPerDay);
  const snapshot = await reportSnapshot(input.groupId, input.targetType, input.targetId);
  if (!snapshot) throw new HttpsError('not-found', 'Nothing to report.');
  const reportId = await fileReport({ reporterId: uid, ...input, snapshot });
  // NOTIF-2: the team's admins are told, without who reported (no actor);
  // the reporter and the person reported are left out.
  await trySend({
    kind: 'contentReported',
    groupId: input.groupId,
    recipients: { admins: true },
    exclude: [uid, snapshot.subjectId],
    actor: null,
    target: { type: 'report', id: reportId },
    route: `/g/${input.groupId}/reports`,
    params: { targetType: input.targetType },
    body: reportedBody(input.targetType),
    dedupeKey: reportId,
  });
  return { reportId };
});

/**
 * Closes a report (SAFE-4): team admins in their team, super admins
 * anywhere. The app takes the action itself first (deleting the message,
 * removing the member) and records it here; dismissing records no action.
 */
export const resolveReport = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = parse(
    z.object({
      reportId: z.string().min(1),
      outcome: z.enum(['actioned', 'dismissed']),
      resolution: z.enum(['deletedMessage', 'removedMember', 'deletedDocument', 'none']).default('none'),
    }),
    request.data,
  );
  const ref = db().collection(Collections.reports).doc(input.reportId);
  const report = await ref.get();
  if (!report.exists) throw new HttpsError('not-found', 'No such report.');
  const groupId = report.get('groupId') as string;
  await requireTeamAdmin(groupId, uid, request.auth?.token.superAdmin === true);
  await ref.update({
    status: input.outcome,
    resolution: input.resolution,
    resolvedBy: uid,
    resolvedAt: FieldValue.serverTimestamp(),
  });
  await audit({
    actorId: uid,
    action: input.outcome === 'dismissed' ? 'dismissReport' : 'actionReport',
    groupId,
    targetType: 'report',
    targetId: input.reportId,
    after: { resolution: input.resolution },
  });
  return { ok: true };
});
