import { HttpsError, type CallableRequest } from 'firebase-functions/v2/https';

/** The caller's uid, or `unauthenticated` (ARCH §6.4: callables need auth). */
export function requireAuth(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in first.');
  return uid;
}
