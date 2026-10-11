import { Timestamp } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';
import { formatCode, newInviteCode, normalizeCode } from '../../src/invites/codes.js';
import { isUsable } from '../../src/invites/service.js';

describe('invite codes', () => {
  it('are 8 characters without look-alikes', () => {
    for (let i = 0; i < 200; i++) {
      const code = newInviteCode();
      expect(code).toMatch(/^[2-9A-HJKMNP-Z]{8}$/);
    }
  });

  it('normalize typed input and format for display', () => {
    expect(normalizeCode(' k7xp-m2qr ')).toBe('K7XPM2QR');
    expect(formatCode('K7XPM2QR')).toBe('K7XP-M2QR');
  });
});

describe('isUsable', () => {
  const now = Date.now();
  it('rejects revoked, expired, and used-up links', () => {
    expect(isUsable({ useCount: 0 }, now)).toBe(true);
    expect(isUsable({ revokedAt: Timestamp.now() }, now)).toBe(false);
    expect(isUsable({ expiresAt: Timestamp.fromMillis(now - 1) }, now)).toBe(false);
    expect(isUsable({ maxUses: 3, useCount: 3 }, now)).toBe(false);
    expect(isUsable({ maxUses: 3, useCount: 2 }, now)).toBe(true);
  });
});

import { problemWith } from '../../src/invites/service.js';

describe('problemWith (INV-8)', () => {
  it('explains why an invite cannot be used', () => {
    expect(problemWith(undefined, null)).toBe('unknown');
    expect(problemWith({ revokedAt: Timestamp.now() }, null)).toBe('revoked');
    expect(problemWith({ expiresAt: Timestamp.fromMillis(1) }, null)).toBe('expired');
    expect(problemWith({ maxUses: 1, useCount: 1 }, null)).toBe('used-up');
    expect(problemWith({ type: 'email', email: 'a@x.com' }, 'b@x.com')).toBe('wrong-email');
    expect(problemWith({ type: 'email', email: 'A@x.com' }, 'a@x.com')).toBeNull();
    expect(problemWith({ type: 'link', useCount: 4 }, null)).toBeNull();
  });
});
