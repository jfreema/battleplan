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

  it('takes the member the owner picked while they are still on the team (AUTH-10)', () => {
    const members = [
      { uid: 'owner', role: 'owner', joinedAt: at(1) },
      { uid: 'a1', role: 'admin', joinedAt: at(2) },
      { uid: 'm1', role: 'member', joinedAt: at(3) },
    ];
    expect(nextOwner(members, 'owner', 'm1')).toBe('m1');
    expect(nextOwner(members, 'owner', 'gone')).toBe('a1');
    expect(nextOwner(members, 'owner', 'owner')).toBe('a1');
  });
});

import { canChangeRole, canRemove } from '../../src/teams/service.js';

describe('role rules (SPEC §3)', () => {
  it('lets admins promote, but only owners and super admins demote', () => {
    expect(canChangeRole('admin', 'member', 'admin')).toBe(true);
    expect(canChangeRole('admin', 'admin', 'member')).toBe(false);
    expect(canChangeRole('owner', 'admin', 'member')).toBe(true);
    expect(canChangeRole('superAdmin', 'admin', 'member')).toBe(true);
    expect(canChangeRole('owner', 'owner', 'member')).toBe(false);
  });

  it('lets admins remove members, and owners remove admins, never the owner', () => {
    expect(canRemove('admin', 'member')).toBe(true);
    expect(canRemove('admin', 'admin')).toBe(false);
    expect(canRemove('owner', 'admin')).toBe(true);
    expect(canRemove('superAdmin', 'owner')).toBe(false);
  });
});
