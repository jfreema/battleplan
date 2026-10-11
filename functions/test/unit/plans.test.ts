import { Timestamp } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';
import { addMonths, dueReminder, isActive } from '../../src/plans/service.js';

describe('addMonths', () => {
  it('adds calendar months, clamping to the month end', () => {
    expect(addMonths(new Date('2026-10-11T12:00:00Z'), 12).toISOString()).toBe('2027-10-11T12:00:00.000Z');
    expect(addMonths(new Date('2026-01-31T00:00:00Z'), 1).toISOString()).toBe('2026-02-28T00:00:00.000Z');
    expect(addMonths(new Date('2027-12-15T00:00:00Z'), 3).toISOString()).toBe('2028-03-15T00:00:00.000Z');
  });
});

describe('isActive', () => {
  const now = Date.parse('2026-10-11T00:00:00Z');
  it('is active until its end, unless revoked', () => {
    expect(isActive({ endsAt: Timestamp.fromMillis(now + 1000) }, now)).toBe(true);
    expect(isActive({ endsAt: Timestamp.fromMillis(now - 1000) }, now)).toBe(false);
    expect(isActive({ endsAt: Timestamp.fromMillis(now + 1000), revokedAt: Timestamp.fromMillis(now) }, now)).toBe(false);
  });
});

describe('dueReminder', () => {
  const now = Date.parse('2026-10-11T00:00:00Z');
  const inDays = (d: number) => now + d * 86_400_000;
  it('reminds once at 30 days and once at 7', () => {
    expect(dueReminder(inDays(40), {}, now)).toBeNull();
    expect(dueReminder(inDays(29), {}, now)).toBe('d30');
    expect(dueReminder(inDays(29), { d30: true }, now)).toBeNull();
    expect(dueReminder(inDays(6), { d30: true }, now)).toBe('d7');
    expect(dueReminder(inDays(6), { d30: true, d7: true }, now)).toBeNull();
    expect(dueReminder(inDays(-1), {}, now)).toBeNull();
  });
});
