// What saveDue accepts and stores (SPEC DUES-1): its input, a due's terms
// trimmed and clipped, and a player's name as the app shows it.
import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';
import { DeleteDueInput, dueIdFor, dueTerms, playerLabel, SaveDueInput } from '../../src/dues/service.js';
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
