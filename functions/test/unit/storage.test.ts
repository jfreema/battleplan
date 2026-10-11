import { describe, expect, it } from 'vitest';
import { groupIdFromPath } from '../../src/teams/storage.js';

describe('groupIdFromPath', () => {
  it('finds the team in a team file path', () => {
    expect(groupIdFromPath('groups/abc/messages/m1/photo.jpg')).toBe('abc');
    expect(groupIdFromPath('groups/abc/avatar/logo.png')).toBe('abc');
  });

  it('ignores files outside team folders', () => {
    expect(groupIdFromPath('users/u1/avatar/a.jpg')).toBeNull();
    expect(groupIdFromPath('groups/abc')).toBeNull();
    expect(groupIdFromPath(undefined)).toBeNull();
  });
});
