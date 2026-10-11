import { Timestamp } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';
import { nextOwner } from '../../src/teams/service.js';

const at = (ms: number) => Timestamp.fromMillis(ms);

describe('nextOwner', () => {
  it('prefers the longest-serving admin', () => {
    expect(nextOwner([
      { uid: 'owner', role: 'owner', joinedAt: at(1) },
      { uid: 'm1', role: 'member', joinedAt: at(2) },
      { uid: 'a2', role: 'admin', joinedAt: at(9) },
      { uid: 'a1', role: 'admin', joinedAt: at(5) },
    ], 'owner')).toBe('a1');
  });

  it('falls back to the longest-serving member, then nobody', () => {
    expect(nextOwner([
      { uid: 'owner', role: 'owner', joinedAt: at(1) },
      { uid: 'm2', role: 'member', joinedAt: at(8) },
      { uid: 'm1', role: 'member', joinedAt: at(3) },
    ], 'owner')).toBe('m1');
    expect(nextOwner([{ uid: 'owner', role: 'owner' }], 'owner')).toBeNull();
  });
});
