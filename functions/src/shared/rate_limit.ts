import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { db } from './admin.js';
import { Collections, Limits } from './constants.js';

/** One limit to check: [count] uses of [action] by [key], at most [max]. */
export interface RateLimit {
  key: string;
  action: string;
  max: number;
  window?: 'day' | 'hour';
  count?: number;
}

/** The counter document for a limit in the current window. */
export function rateLimitDocId(limit: RateLimit, now = new Date()): string {
  const stamp = (limit.window ?? 'day') === 'day' ? now.toISOString().slice(0, 10) : now.toISOString().slice(0, 13);
  return `${limit.key}_${limit.action}_${stamp}`;
}

/**
 * Counts uses against every limit in one transaction and throws
 * `resource-exhausted` if any would go past its max (ARCH §6.9). It's all
 * or nothing: a refused request uses up none of its allowance, so adding 30
 * people when only 10 are left adds nobody and counts nothing. Windows are
 * calendar days (UTC) or hours; counters expire through the rateLimits TTL.
 */
export async function consumeRateLimits(limits: RateLimit[]): Promise<void> {
  const now = new Date();
  const refs = limits.map((l) => db().collection(Collections.rateLimits).doc(rateLimitDocId(l, now)));
  await db().runTransaction(async (tx) => {
    const snaps = await Promise.all(refs.map((r) => tx.get(r)));
    limits.forEach((limit, i) => {
      const used = (snaps[i].get('count') as number | undefined) ?? 0;
      if (used + (limit.count ?? 1) > limit.max) {
        throw new HttpsError('resource-exhausted', 'Slow down, try again later.');
      }
    });
    limits.forEach((limit, i) =>
      tx.set(
        refs[i],
        {
          count: FieldValue.increment(limit.count ?? 1),
          expiresAt: Timestamp.fromMillis(Date.now() + Limits.rateLimitTtlDays * 86_400_000),
        },
        { merge: true },
      ),
    );
  });
}

/** Counts [count] uses of [action] by [key]; see [consumeRateLimits]. */
export async function consumeRateLimit(
  key: string,
  action: string,
  max: number,
  window: 'day' | 'hour' = 'day',
  count = 1,
): Promise<void> {
  await consumeRateLimits([{ key, action, max, window, count }]);
}
