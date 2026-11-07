// What saveDue accepts and stores (SPEC DUES-1): its input, a due's terms
// trimmed and clipped, a player's name as the app shows it, and what a
// share becomes when the due's amount changes (DUES-2).
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';
import { DeleteDueInput, dueIdFor, dueTerms, MARKED_PAID_ID, playerLabel, reamountShare, SaveDueInput } from '../../src/dues/service.js';
import { Limits } from '../../src/shared/constants.js';

const input = { groupId: 'teamA', title: 'Fee', amountCents: 4500, dueOn: '2026-11-30', note: '' };

describe('SaveDueInput', () => {
  it('takes a whole amount of cents up to the cap, and a calendar day or none', () => {
    expect(SaveDueInput.safeParse(input).success).toBe(true);
    expect(SaveDueInput.safeParse({ ...input, dueOn: null, participantIds: ['emma'] }).success).toBe(true);
    expect(SaveDueInput.safeParse({ ...input, requestId: 'a1B2c3D4e5_-' }).success).toBe(true);
    expect(SaveDueInput.safeParse({ ...input, amountCents: Limits.dueAmountMaxCents }).success).toBe(true);
    for (const bad of [
      { amountCents: 0 },
      { amountCents: Limits.dueAmountMaxCents + 1 },
      { amountCents: 1.5 },
      { dueOn: '2026-11-31x' },
      { dueOn: '2026-00-10' },
      { groupId: '' },
      { groupId: 'a/b' },
      { dueId: 'a_b' },
      { participantIds: ['x_y'] },
      { title: 5 },
      { requestId: 'short' },
      { requestId: 'has spaces in it' },
    ]) {
      expect(SaveDueInput.safeParse({ ...input, ...bad }).success).toBe(false);
    }
    expect(DeleteDueInput.safeParse({ dueId: '' }).success).toBe(false);
  });
});

describe('dueTerms', () => {
  it('trims and clips the title and note', () => {
    expect(dueTerms({ ...input, title: '  Fee  ', note: ' n ' })).toEqual({
      title: 'Fee', amountCents: 4500, dueOn: '2026-11-30', note: 'n',
    });
    const long = dueTerms({ ...input, title: 'x'.repeat(99), note: 'y'.repeat(999) });
    expect(long.title).toHaveLength(Limits.dueTitleMax);
    expect(long.note).toHaveLength(Limits.dueNoteMax);
  });

  it('refuses a blank title', () => {
    expect(() => dueTerms({ ...input, title: '   ' })).toThrow(HttpsError);
  });
});

describe('playerLabel', () => {
  it('is the first name and number, as the app shows a player', () => {
    expect(playerLabel('Emma Rivera', '7')).toBe('Emma #7');
    expect(playerLabel(' Liam  Park ', '')).toBe('Liam');
    expect(playerLabel(undefined, null)).toBe('');
  });
});

describe('dueIdFor', () => {
  it("is the same for a person's retries of one add, and differs otherwise", () => {
    expect(dueIdFor('carol', 'req-1234')).toBe(dueIdFor('carol', 'req-1234'));
    expect(dueIdFor('carol', 'req-1234')).toMatch(/^[0-9a-f]{20}$/);
    expect(dueIdFor('carol', 'req-1234')).not.toBe(dueIdFor('carol', 'req-5678'));
    expect(dueIdFor('carol', 'req-1234')).not.toBe(dueIdFor('alice', 'req-1234'));
  });
});

describe('reamountShare', () => {
  const pay = (amountCents: number) => ({ id: `pay-${amountCents}`, amountCents, paidOn: '2026-11-05', by: 'carol', note: '' });
  const at = Timestamp.fromDate(new Date('2026-11-02T23:30:00Z'));

  it('leaves a share with nothing paid as it is', () => {
    expect(reamountShare({ status: 'owed', amountCents: 4500 }, 5000, '2026-11-07')).toBeNull();
    expect(reamountShare({ status: 'waived', amountCents: 4500 }, 5000, '2026-11-07')).toBeNull();
  });

  it('keeps the payments, and is paid only when they cover the new amount', () => {
    const owed = { status: 'owed', amountCents: 4500, payments: [pay(2000), pay(2000)], paidCents: 4000 };
    expect(reamountShare(owed, 5000, '2026-11-07')).toEqual({ payments: owed.payments, paidCents: 4000, status: 'owed', paidAt: null });
    const full = reamountShare(owed, 4000, '2026-11-07')!;
    expect(full).toMatchObject({ paidCents: 4000, status: 'paid' });
    expect(full.paidAt).toBeInstanceOf(FieldValue);
    // Already paid, and still covered: when it was paid stays.
    expect(reamountShare({ ...owed, status: 'paid', paidAt: at, paidCents: 4000, amountCents: 4000 }, 4000, '2026-11-07')!.paidAt).toBe(at);
    // Waived stays waived, its payments kept.
    expect(reamountShare({ ...owed, status: 'waived' }, 6000, '2026-11-07')).toMatchObject({ status: 'waived', paidCents: 4000, paidAt: null });
  });

  it('counts a share marked paid before payments were recorded as paid in full at its amount', () => {
    expect(reamountShare({ status: 'paid', amountCents: 4500, paidAt: at }, 5000, '2026-11-07')).toEqual({
      payments: [{ id: MARKED_PAID_ID, amountCents: 4500, paidOn: '2026-11-02', by: '', note: '' }],
      paidCents: 4500,
      status: 'owed',
      paidAt: null,
    });
    // No time it was marked: today.
    expect(reamountShare({ status: 'paid', amountCents: 4500, paidAt: null }, 5000, '2026-11-07')!.payments[0].paidOn).toBe('2026-11-07');
  });

  it('refuses an amount below what was paid', () => {
    for (const share of [
      { status: 'owed', amountCents: 4500, payments: [pay(3000)], paidCents: 3000 },
      { status: 'waived', amountCents: 4500, payments: [pay(3000)], paidCents: 3000 },
      { status: 'paid', amountCents: 4500 },
    ]) {
      try {
        reamountShare(share, 2500, '2026-11-07');
        expect.unreachable();
      } catch (e) {
        expect((e as HttpsError).code).toBe('failed-precondition');
        expect((e as HttpsError).message).toBe('due-amount-below-paid');
      }
    }
  });
});
