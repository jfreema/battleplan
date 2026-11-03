import { describe, expect, it } from 'vitest';
import { seasonCopyId, seasonFilePath, seasonPlaceOf } from '../../src/teams/season.js';

const ALL = { players: true, staff: true, members: true };
const NONE = { players: false, staff: false, members: false };

describe('seasonPlaceOf (TEAM-16)', () => {
  it('always brings the owner, as the owner', () => {
    expect(seasonPlaceOf({ role: 'owner' }, false, NONE)).toEqual({ role: 'owner', coach: null, title: null });
    expect(seasonPlaceOf({ role: 'owner', coach: false, title: 'Head coach' }, true, NONE)).toEqual({
      role: 'owner', coach: false, title: 'Head coach',
    });
  });

  it('brings admins and coaches with the staff, as they were', () => {
    expect(seasonPlaceOf({ role: 'admin', title: 'Manager' }, false, { ...NONE, staff: true })).toEqual({
      role: 'admin', coach: null, title: 'Manager',
    });
    expect(seasonPlaceOf({ role: 'member', coach: true }, false, { ...NONE, staff: true })).toEqual({
      role: 'member', coach: true, title: null,
    });
    expect(seasonPlaceOf({ role: 'admin' }, false, { ...ALL, staff: false })).toBeNull();
    expect(seasonPlaceOf({ role: 'member', coach: true }, false, { ...ALL, staff: false })).toBeNull();
  });

  it('brings a coach who is a parent as a parent when the staff stay behind', () => {
    expect(seasonPlaceOf({ role: 'admin', coach: true, title: 'Coach' }, true, { ...NONE, players: true })).toEqual({
      role: 'member', coach: null, title: null,
    });
  });

  it("brings the players' members with the players, and only with them", () => {
    expect(seasonPlaceOf({ role: 'member', title: 'Team parent' }, true, { ...NONE, players: true })).toEqual({
      role: 'member', coach: null, title: 'Team parent',
    });
    expect(seasonPlaceOf({ role: 'member' }, true, { ...ALL, players: false })).toBeNull();
  });

  it('brings everyone else with the other members', () => {
    expect(seasonPlaceOf({ role: 'member', coach: false }, false, { ...NONE, members: true })).toEqual({
      role: 'member', coach: false, title: null,
    });
    expect(seasonPlaceOf({ role: 'member' }, false, { ...ALL, members: false })).toBeNull();
  });
});

describe('seasonCopyId', () => {
  it('is the same for one season and different for the next, with no "_"', () => {
    expect(seasonCopyId('spring', 'p1')).toBe(seasonCopyId('spring', 'p1'));
    expect(seasonCopyId('summer', 'p1')).not.toBe(seasonCopyId('spring', 'p1'));
    expect(seasonCopyId('spring', 'p1')).toMatch(/^[0-9a-f]{20}$/);
  });
});

describe('seasonFilePath', () => {
  it("moves the old team's files to the new team's folder, and leaves other paths", () => {
    expect(seasonFilePath('groups/fall/avatar/1.jpg', 'fall', 'spring')).toBe('groups/spring/avatar/1.jpg');
    expect(seasonFilePath('groups/fall2/avatar/1.jpg', 'fall', 'spring')).toBe('groups/fall2/avatar/1.jpg');
    expect(seasonFilePath('users/pat/avatar/1.jpg', 'fall', 'spring')).toBe('users/pat/avatar/1.jpg');
  });
});
