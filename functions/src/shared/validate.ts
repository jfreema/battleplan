import { HttpsError } from 'firebase-functions/v2/https';
import type { z } from 'zod';

/** Parses callable input, or throws `invalid-argument` (ARCH §6.4 rule 1). */
export function parse<T extends z.ZodType>(schema: T, data: unknown): z.infer<T> {
  const result = schema.safeParse(data);
  if (!result.success) {
    throw new HttpsError('invalid-argument', 'Invalid request.');
  }
  return result.data;
}
