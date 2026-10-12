// Thin entry points for the accounts domain (ARCH §6.4).
import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { resendApiKey } from '../email/service.js';
import { onCall } from '../shared/callable.js';
import { requireAuth } from '../shared/guards.js';
import { parse } from '../shared/validate.js';
import {
  deleteAccount as deleteAll,
  ensureUserProfile as ensure,
  recordSignInMethodChange as recordChange,
  signOutEverywhere as revokeAll,
} from './service.js';

const EnsureInput = z.object({
  setup: z
    .object({
      displayName: z.string().trim().min(1).max(50),
      confirmAdult: z.literal(true),
      acceptTerms: z.literal(true),
    })
    .optional(),
});

/** Creates the caller's profile at first sign-in; with `setup`, finishes AUTH-5. */
export const ensureUserProfile = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = parse(EnsureInput, request.data ?? {});
  const result = await ensure(uid, input.setup);
  return { created: result.created, needsSetup: result.needsSetup };
});

/** Signs the caller out on every device (AUTH-9). */
export const signOutEverywhere = onCall(async (request) => {
  const uid = requireAuth(request);
  await revokeAll(uid);
  return { ok: true };
});

/** Syncs users.signInMethods after the app links or unlinks a method (AUTH-7). */
export const recordSignInMethodChange = onCall({ secrets: [resendApiKey] }, async (request) => {
  const uid = requireAuth(request);
  return recordChange(uid);
});

/** How recent the sign-in must be to delete an account (AUTH-7). */
const RECENT_SIGN_IN_SECONDS = 5 * 60;

/** Deletes the caller's account and data (AUTH-10). Needs a fresh sign-in. */
export const deleteAccount = onCall(async (request) => {
  const uid = requireAuth(request);
  const authTime = request.auth?.token.auth_time ?? 0;
  if (Date.now() / 1000 - authTime > RECENT_SIGN_IN_SECONDS) {
    throw new HttpsError('failed-precondition', 'requires-recent-login');
  }
  await deleteAll(uid);
  return { ok: true };
});
