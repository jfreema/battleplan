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
  // An added account chose how to sign in next time (AUTH-6).
  signInChosen: z.literal(true).optional(),
});

/**
 * Creates the caller's profile at first sign-in; with `setup`, finishes
 * AUTH-5. It also brings a verified email change into the profile and
 * emails the security notice (AUTH-8), so it needs the email secret.
 */
export const ensureUserProfile = onCall({ secrets: [resendApiKey] }, async (request) => {
  const uid = requireAuth(request);
  const input = parse(EnsureInput, request.data ?? {});
  const result = await ensure(uid, input.setup, { signInChosen: input.signInChosen });
  return { created: result.created, needsSetup: result.needsSetup };
});

/** Signs the caller out on every device (AUTH-9). */
export const signOutEverywhere = onCall(async (request) => {
  const uid = requireAuth(request);
  await revokeAll(uid);
  return { ok: true };
});

const RecordChangeInput = z.object({
  // The app changed the password (AUTH-7's security notice).
  passwordChanged: z.boolean().optional(),
});

/** Syncs users.signInMethods after the app links or unlinks a method or changes the password (AUTH-7). */
export const recordSignInMethodChange = onCall({ secrets: [resendApiKey] }, async (request) => {
  const uid = requireAuth(request);
  const input = parse(RecordChangeInput, request.data ?? {});
  return recordChange(uid, input.passwordChanged === true);
});

/** How recent the sign-in must be to delete an account (AUTH-7). */
const RECENT_SIGN_IN_SECONDS = 5 * 60;

const DeleteAccountInput = z.object({
  // Team ID → the member the owner picked to take the team over (AUTH-10).
  newOwners: z.record(z.string().min(1).max(128), z.string().min(1).max(128)).optional(),
});

/** Deletes the caller's account and data (AUTH-10). Needs a fresh sign-in. */
export const deleteAccount = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = parse(DeleteAccountInput, request.data ?? {});
  const authTime = request.auth?.token.auth_time ?? 0;
  if (Date.now() / 1000 - authTime > RECENT_SIGN_IN_SECONDS) {
    throw new HttpsError('failed-precondition', 'requires-recent-login');
  }
  await deleteAll(uid, input.newOwners ?? {});
  return { ok: true };
});
