import { describe, expect, it } from 'vitest';
import { snapshotChanged } from '../../src/accounts/triggers.js';
import { lastMessagePreviewOf, replyPreviewOf } from '../../src/chat/service.js';

describe('users trigger early exit', () => {
  it('runs only when the name or photo changed', () => {
    const base = { displayName: 'Sam', photoPath: null, themeMode: 'system' };
    expect(snapshotChanged(base, { ...base, themeMode: 'dark' })).toBe(false);
    expect(snapshotChanged(base, { ...base, displayName: 'Sam R' })).toBe(true);
    expect(snapshotChanged(base, { ...base, photoPath: 'users/u/avatar/1.jpg' })).toBe(true);
    expect(snapshotChanged(undefined, base)).toBe(false);
  });
});

describe('replyPreviewOf', () => {
  it('quotes the author and first line', () => {
    expect(replyPreviewOf({ authorName: 'Sam', text: 'Bring cleats\nand water', type: 'text' })).toEqual({
      authorName: 'Sam',
      text: 'Bring cleats',
      type: 'text',
      deleted: false,
    });
  });

  it('shortens long lines and keeps the type for photos', () => {
    const p = replyPreviewOf({ authorName: 'Sam', text: 'x'.repeat(200), type: 'image' });
    expect(p.text.length).toBe(120);
    expect(p.type).toBe('image');
  });

  it('reads a missing or deleted original as deleted', () => {
    expect(replyPreviewOf(undefined).deleted).toBe(true);
    expect(replyPreviewOf({ authorName: 'Sam', text: 'hi', deletedAt: new Date() }).deleted).toBe(true);
  });
});

describe('lastMessagePreviewOf', () => {
  it('uses the first line, or Photo for a photo without text', () => {
    expect(lastMessagePreviewOf({ authorName: 'Sam', text: 'Game moved\nto 6', type: 'text' }).text).toBe('Game moved');
    expect(lastMessagePreviewOf({ authorName: 'Sam', text: '', type: 'image' }).text).toBe('Photo');
  });
});
