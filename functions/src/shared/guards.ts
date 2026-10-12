import { HttpsError, type CallableRequest } from 'firebase-functions/v2/https';

/** The caller's uid, or `unauthenticated` (ARCH §6.4: callables need auth). */
export function requireAuth(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in first.');
  return uid;
}

/** The caller's uid, unless they lack the `superAdmin` claim (ARCH §6.4 admin callables). */
export function requireSuperAdmin(request: CallableRequest): string {
  const uid = requireAuth(request);
  if (request.auth?.token.superAdmin !== true) throw new HttpsError('permission-denied', 'Super admins only.');
  return uid;
}
