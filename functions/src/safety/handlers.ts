// Thin entry points for the safety domain (ARCH §6.4).
import { FieldValue } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { audit } from '../audit/service.js';
import { db } from '../shared/admin.js';
import { onCall } from '../shared/callable.js';
import { Collections, Limits, reportReasonValues } from '../shared/constants.js';
import { requireAuth } from '../shared/guards.js';
import { consumeRateLimit } from '../shared/rate_limit.js';
import { requireOpenTeam, requireTeamAdmin, roleOf } from '../shared/roles.js';
import { parse } from '../shared/validate.js';
import { trySend } from '../notify/service.js';
import { fileReport, reportedBody, reportSnapshot, teamSeesReport } from './service.js';

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
  // Not on a suspended team (§3); an archived one can still be reported (SAFE-1).
  await requireOpenTeam(input.groupId, false, { allowArchived: true });
  if (input.targetType === 'user' && input.targetId === uid) {
    throw new HttpsError('invalid-argument', 'You cannot report yourself.');
  }
  await consumeRateLimit(uid, 'report', Limits.reportsPerUserPerDay);
  const snapshot = await reportSnapshot(input.groupId, input.targetType, input.targetId);
  if (!snapshot) throw new HttpsError('not-found', 'Nothing to report.');
  // A report about one of the team's admins goes to super admins only.
  const teamVisible = teamSeesReport(snapshot.subjectId ? await roleOf(input.groupId, snapshot.subjectId) : null);
  const reportId = await fileReport({ reporterId: uid, ...input, snapshot, teamVisible });
  // NOTIF-2: the team's admins are told, without who reported (no actor);
  // the reporter and the person reported are left out.
  if (teamVisible) await trySend({
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
  // Team admins can't act on a suspended or archived team; super admins
  // still close its reports (§3, TEAM-9).
  const superAdmin = request.auth?.token.superAdmin === true;
  await requireTeamAdmin(groupId, uid, superAdmin, { allowArchived: superAdmin });
  // SAFE-1: a report the team's admins don't see (one about an admin) is
  // the super admins' to close, and nobody closes a report about themselves.
  if (!superAdmin && (report.get('teamVisible') === false || report.get('subjectId') === uid)) {
    throw new HttpsError('permission-denied', 'Only a super admin can close this report.');
  }
  await ref.update({
    status: input.outcome,
    resolution: input.resolution,
    resolvedBy: uid,
    resolvedAt: FieldValue.serverTimestamp(),
    // The copy of what was reported goes with the decision (as closeReport).
    excerpt: '',
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
