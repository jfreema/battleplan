// Thin entry points for the accounts domain (ARCH §6.4).
import { onCall } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { requireAuth } from '../shared/guards.js';
import { parse } from '../shared/validate.js';
import { ensureUserProfile as ensure } from './service.js';

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
  return ensure(uid, input.setup);
});
