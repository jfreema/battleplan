import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { db } from './admin.js';
import { Collections, Limits } from './constants.js';

/**
 * Counts one use of [action] by [key] in the current window and throws
 * `resource-exhausted` past [max] (ARCH §6.9). Windows are calendar days
 * (UTC) or hours; counters expire through the rateLimits TTL policy.
 */
export async function consumeRateLimit(
  key: string,
  action: string,
  max: number,
  window: 'day' | 'hour' = 'day',
): Promise<void> {
  const now = new Date();
  const stamp =
    window === 'day'
      ? now.toISOString().slice(0, 10)
      : now.toISOString().slice(0, 13);
  const ref = db().collection(Collections.rateLimits).doc(`${key}_${action}_${stamp}`);
  await db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const count = (snap.get('count') as number | undefined) ?? 0;
    if (count >= max) {
      throw new HttpsError('resource-exhausted', 'Slow down, try again later.');
    }
    tx.set(
      ref,
      {
        count: FieldValue.increment(1),
        expiresAt: Timestamp.fromMillis(Date.now() + Limits.rateLimitTtlDays * 86_400_000),
      },
      { merge: true },
    );
  });
}
