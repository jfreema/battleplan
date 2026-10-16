import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { onCall } from '../shared/callable.js';
import { Limits } from '../shared/constants.js';
import { consumeRateLimit } from '../shared/rate_limit.js';
import { parse } from '../shared/validate.js';
import { recordClientError } from './service.js';

const ClientErrorInput = z.object({
  message: z.string().max(500),
  stack: z.string().max(4000).default(''),
  fatal: z.boolean().default(false),
  appVersion: z.string().max(40).default(''),
});

/**
 * Sampled web error reports, since Crashlytics doesn't support web. They
 * work signed out (the sign-in screen can fail too), so each IP address
 * gets 30 an hour (SAFE-5); past that they're dropped quietly, as a report
 * mustn't become an error of its own.
 */
export const logClientError = onCall(async (request) => {
  const input = parse(ClientErrorInput, request.data);
  const ip = (request.rawRequest?.ip ?? 'unknown').replace(/[^0-9a-fA-F.:]/g, '');
  try {
    await consumeRateLimit(`ip-${ip}`, 'clientError', Limits.clientErrorsPerIpPerHour, 'hour');
  } catch (e) {
    if (e instanceof HttpsError && e.code === 'resource-exhausted') return { ok: true };
    throw e;
  }
  recordClientError(input, request.auth?.uid);
  return { ok: true };
});
