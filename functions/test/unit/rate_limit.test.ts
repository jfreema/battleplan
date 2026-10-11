import { describe, expect, it } from 'vitest';
import { rateLimitDocId } from '../../src/shared/rate_limit.js';

describe('rateLimitDocId', () => {
  const at = new Date('2026-10-11T16:45:00Z');

  it('uses a calendar-day window by default', () => {
    expect(rateLimitDocId({ key: 'u1', action: 'emailInvite', max: 50 }, at)).toBe('u1_emailInvite_2026-10-11');
  });

  it('uses an hour window when asked', () => {
    expect(rateLimitDocId({ key: 'u1', action: 'redeemInvite', max: 20, window: 'hour' }, at)).toBe(
      'u1_redeemInvite_2026-10-11T16',
    );
  });
});
