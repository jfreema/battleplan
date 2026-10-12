import { describe, expect, it } from 'vitest';
import { Limits } from '../../src/shared/constants.js';
import { classifyMediaPath, isTeamMediaPath } from '../../src/teams/media.js';
import {
  groupIdFromPath,
  quotaBytesOf,
  storageAlertBody,
  storageAlertLevel,
} from '../../src/teams/storage.js';

const MB = 1024 * 1024;

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

describe('storageAlertLevel (STORE-3, STORE-4)', () => {
  const quota = 500 * MB;

  it('is none below 90%, warn from 90%, and full at the limit', () => {
    expect(Limits.storageWarnPercent).toBe(90);
    expect(storageAlertLevel(0, quota)).toBe('none');
    expect(storageAlertLevel(quota * 0.9 - 1, quota)).toBe('none');
    expect(storageAlertLevel(quota * 0.9, quota)).toBe('warn');
    expect(storageAlertLevel(quota - 1, quota)).toBe('warn');
    expect(storageAlertLevel(quota, quota)).toBe('full');
    expect(storageAlertLevel(quota + 1, quota)).toBe('full');
  });

  it('treats a limit of zero as full, like the rules do', () => {
    expect(storageAlertLevel(0, 0)).toBe('full');
  });

  it('words the warning and the full message (SPEC STORE-3, STORE-4)', () => {
    expect(storageAlertBody('warn')).toBe('Storage is 90% full. Free up space in Media.');
    expect(storageAlertBody('full')).toBe(
      'Storage is full. Uploads, attachments, and scheduling new events are disabled until storage is freed up.',
    );
  });

  it('gives a team without a limit the 500 MB default (STORE-1)', () => {
    expect(quotaBytesOf({})).toBe(500 * MB);
    expect(quotaBytesOf(undefined)).toBe(500 * MB);
    expect(quotaBytesOf({ storageQuotaBytes: 2048 * MB })).toBe(2048 * MB);
  });
});

describe('classifyMediaPath (STORE-5)', () => {
  it('matches each team folder to what uses it', () => {
    expect(classifyMediaPath('g1', 'groups/g1/messages/m1/0.jpg')).toEqual({ kind: 'chatPhoto', messageId: 'm1' });
    expect(classifyMediaPath('g1', 'groups/g1/messages/m1/thumbs/0_400x400.jpg')).toEqual({
      kind: 'chatPhoto',
      messageId: 'm1',
    });
    expect(classifyMediaPath('g1', 'groups/g1/avatar/1700000000000.jpg')).toEqual({ kind: 'logo' });
    expect(classifyMediaPath('g1', 'groups/g1/theme/1700000000000.jpg')).toEqual({ kind: 'background' });
    expect(classifyMediaPath('g1', 'groups/g1/documents/d1/Schedule.pdf')).toEqual({ kind: 'document' });
  });

  it('calls a file in a folder no message could have an orphan', () => {
    expect(classifyMediaPath('g1', 'groups/g1/messages/./0.jpg')).toEqual({ kind: 'other' });
    expect(classifyMediaPath('g1', 'groups/g1/messages/../0.jpg')).toEqual({ kind: 'other' });
    expect(classifyMediaPath('g1', 'groups/g1/messages/__name__/0.jpg')).toEqual({ kind: 'other' });
    expect(classifyMediaPath('g1', 'groups/g1/messages/m1/a..jpg')).toEqual({ kind: 'chatPhoto', messageId: 'm1' });
  });

  it('calls anything else other', () => {
    expect(classifyMediaPath('g1', 'groups/g1/stray.jpg')).toEqual({ kind: 'other' });
    expect(classifyMediaPath('g1', 'groups/g1/messages/m1')).toEqual({ kind: 'other' });
    expect(classifyMediaPath('g1', 'groups/g1/messages//0.jpg')).toEqual({ kind: 'other' });
    expect(classifyMediaPath('g1', 'groups/g1/avatar/old/1.jpg')).toEqual({ kind: 'other' });
    expect(classifyMediaPath('g1', 'groups/g1/documents/1.pdf')).toEqual({ kind: 'other' });
    expect(classifyMediaPath('g1', 'groups/g2/avatar/1.jpg')).toEqual({ kind: 'other' });
  });

  it("accepts only paths inside the team's own folder", () => {
    expect(isTeamMediaPath('g1', 'groups/g1/avatar/1.jpg')).toBe(true);
    expect(isTeamMediaPath('g1', 'groups/g1/')).toBe(false);
    expect(isTeamMediaPath('g1', 'groups/g10/avatar/1.jpg')).toBe(false);
    expect(isTeamMediaPath('g1', 'groups/g1/../g2/avatar/1.jpg')).toBe(false);
    expect(isTeamMediaPath('g1', 'groups/g1/messages/../../g2/avatar/1.jpg')).toBe(false);
    expect(isTeamMediaPath('g1', 'groups/g1/x/..')).toBe(false);
    expect(isTeamMediaPath('g1', 'users/u1/avatar/1.jpg')).toBe(false);
    expect(isTeamMediaPath('g1/x', 'groups/g1/x/avatar/1.jpg')).toBe(false);
    expect(isTeamMediaPath('..', 'groups/../users/u1/avatar/1.jpg')).toBe(false);
  });

  it("keeps every name that stays in the team's folder deletable", () => {
    expect(isTeamMediaPath('g1', 'groups/g1/documents/d1/Roster..final.pdf')).toBe(true);
    expect(isTeamMediaPath('g1', 'groups/g1/messages/m1/a..jpg')).toBe(true);
    expect(isTeamMediaPath('g1', 'groups/g1/messages/./0.jpg')).toBe(true);
    expect(isTeamMediaPath('g1', 'groups/g1/messages/../0.jpg')).toBe(true);
  });
});
