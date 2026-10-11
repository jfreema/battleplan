// Thin entry points for the plans domain (ARCH §6.4, §6.11).
import { HttpsError, onCall, type CallableRequest } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { audit } from '../audit/service.js';
import { auth } from '../shared/admin.js';
import { Limits } from '../shared/constants.js';
import { requireAuth } from '../shared/guards.js';
import { parse } from '../shared/validate.js';
import { extendLicense, grantLicense, moveLicense as move, revokeLicense } from './service.js';

/** Throws unless the caller is a super admin; returns their uid. */
function requireSuperAdmin(request: CallableRequest): string {
  const uid = requireAuth(request);
  if (request.auth?.token.superAdmin !== true) throw new HttpsError('permission-denied', 'Super admins only.');
  return uid;
}

const Months = z.number().int().min(1).max(Limits.licenseMaxMonths);

/** Grants Plus to a person for a team, 12 months by default (PLAN-2). */
export const adminGrantLicense = onCall(async (request) => {
  const actor = requireSuperAdmin(request);
  const input = parse(
    z
      .object({
        groupId: z.string().min(1),
        holderId: z.string().min(1).optional(),
        holderEmail: z.string().email().optional(),
        months: Months.default(Limits.licenseDefaultMonths),
      })
      .refine((x) => x.holderId || x.holderEmail, 'holder required'),
    request.data,
  );
  const holderId = input.holderId ?? (await auth().getUserByEmail(input.holderEmail!)).uid;
  const licenseId = await grantLicense({ holderId, groupId: input.groupId, months: input.months, grantedBy: actor });
  await audit({
    actorId: actor,
    action: 'grantLicense',
    groupId: input.groupId,
    targetType: 'license',
    targetId: licenseId,
    after: { holderId, months: input.months },
  });
  return { licenseId };
});

/** Adds months to a license (PLAN-2). */
export const adminExtendLicense = onCall(async (request) => {
  const actor = requireSuperAdmin(request);
  const input = parse(z.object({ licenseId: z.string().min(1), months: Months }), request.data);
  await extendLicense(input.licenseId, input.months);
  await audit({ actorId: actor, action: 'extendLicense', targetType: 'license', targetId: input.licenseId, after: { months: input.months } });
  return { ok: true };
});

/** Ends a license now (PLAN-2). */
export const adminRevokeLicense = onCall(async (request) => {
  const actor = requireSuperAdmin(request);
  const { licenseId } = parse(z.object({ licenseId: z.string().min(1) }), request.data);
  await revokeLicense(licenseId);
  await audit({ actorId: actor, action: 'revokeLicense', targetType: 'license', targetId: licenseId });
  return { ok: true };
});

const MoveInput = z.object({ licenseId: z.string().min(1), toGroupId: z.string().min(1) });

/** The holder moves their license to another team they admin (PLAN-3). */
export const moveLicense = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = parse(MoveInput, request.data);
  const superAdmin = request.auth?.token.superAdmin === true;
  await move(input.licenseId, input.toGroupId, uid, superAdmin);
  await audit({
    actorId: uid,
    action: 'moveLicense',
    groupId: input.toGroupId,
    targetType: 'license',
    targetId: input.licenseId,
  });
  return { ok: true };
});
