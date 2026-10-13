import { describe, expect, it } from 'vitest';
import { snapshotChanged } from '../../src/accounts/triggers.js';
import {
  joinedLine,
  lastMessagePreviewOf,
  messagePushBody,
  notifiesAsMessage,
  renamedLine,
  replyPreviewOf,
  replyPushBody,
  replyRecipientOf,
} from '../../src/chat/service.js';
import { reportedBody, teamSeesReport } from '../../src/safety/service.js';

describe('groups trigger early exit and system lines (CHAT-10)', () => {
  it('posts a rename line only when the name changed', () => {
    expect(renamedLine('Thunder', 'Thunder', 'Alex')).toBeNull();
    expect(renamedLine('Thunder', ' Thunder ', 'Alex')).toBeNull();
    expect(renamedLine('Thunder', undefined, 'Alex')).toBeNull();
    expect(renamedLine('Thunder', 'Thunder 12U', 'Alex')).toBe('Alex renamed the team to "Thunder 12U"');
    expect(renamedLine('Thunder', 'Thunder 12U', null)).toBe('The team was renamed to "Thunder 12U"');
  });

  it('words a joined line', () => {
    expect(joinedLine('Maria R.')).toBe('Maria R. joined');
    expect(joinedLine('')).toBe('Someone joined');
  });
});

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

describe('message notifications (NOTIF-2, NOTIF-5)', () => {
  it('notifies text and photos; system lines, event cards, and polls notify elsewhere', () => {
    expect(notifiesAsMessage({ type: 'text' })).toBe(true);
    expect(notifiesAsMessage({ type: 'image' })).toBe(true);
    expect(notifiesAsMessage({ type: 'system' })).toBe(false);
    expect(notifiesAsMessage({ type: 'event' })).toBe(false);
    expect(notifiesAsMessage({ type: 'poll' })).toBe(false);
  });

  it('tells the quoted author about a reply, unless it is their own, a system line, or deleted', () => {
    expect(replyRecipientOf({ authorId: 'sam', deleted: false }, 'alex')).toBe('sam');
    expect(replyRecipientOf({ authorId: 'alex', deleted: false }, 'alex')).toBeNull();
    expect(replyRecipientOf({ authorId: 'system', deleted: false }, 'alex')).toBeNull();
    expect(replyRecipientOf({ authorId: 'sam', deleted: true }, 'alex')).toBeNull();
    expect(replyRecipientOf({ authorId: '', deleted: false }, 'alex')).toBeNull();
    expect(replyRecipientOf(null, 'alex')).toBeNull();
  });

  it('words a message push', () => {
    expect(messagePushBody({ authorName: 'Alex', type: 'text', text: 'Field 3 is open' })).toBe('Alex: Field 3 is open');
    expect(messagePushBody({ authorName: 'Alex', type: 'image', text: '', attachments: [{}] })).toBe('Alex sent a photo');
    expect(messagePushBody({ authorName: 'Alex', type: 'image', text: '', attachments: [{}, {}, {}] })).toBe(
      'Alex sent 3 photos',
    );
    expect(messagePushBody({ authorName: 'Alex', type: 'image', text: 'Team pic', attachments: [{}] })).toBe(
      'Alex: Team pic',
    );
    expect(messagePushBody({ authorName: '', type: 'text', text: 'hi' })).toBe('Someone: hi');
  });

  it('words a reply push', () => {
    expect(replyPushBody({ authorName: 'Alex', type: 'text', text: 'Sounds good' })).toBe('Alex replied to you: Sounds good');
    expect(replyPushBody({ authorName: 'Alex', type: 'image', text: '', attachments: [{}] })).toBe(
      'Alex replied to you with a photo',
    );
  });
});

describe('report notifications (NOTIF-2)', () => {
  it('says what was reported, never by whom', () => {
    expect(reportedBody('message')).toBe('A message was reported');
    expect(reportedBody('user')).toBe('A person was reported');
    expect(reportedBody('document')).toBe('A document was reported');
  });

  it("keeps a report about one of the team's admins from the team (SAFE-1)", () => {
    expect(teamSeesReport('owner')).toBe(false);
    expect(teamSeesReport('admin')).toBe(false);
    expect(teamSeesReport('member')).toBe(true);
    expect(teamSeesReport(null)).toBe(true);
  });
});
