import { z } from 'zod';
import { onCall } from '../shared/callable.js';
import { parse } from '../shared/validate.js';
import { recordClientError } from './service.js';

const ClientErrorInput = z.object({
  message: z.string().max(500),
  stack: z.string().max(4000).default(''),
  fatal: z.boolean().default(false),
  appVersion: z.string().max(40).default(''),
});

/** Sampled web error reports, since Crashlytics doesn't support web. */
export const logClientError = onCall(async (request) => {
  const input = parse(ClientErrorInput, request.data);
  recordClientError(input, request.auth?.uid);
  return { ok: true };
});
