import { describe, expect, it } from 'vitest';
import { snapshotChanged } from '../../src/accounts/triggers.js';
import {
  announcementPushBody,
  isAnnouncement,
  joinedLine,
  lastMessagePreviewOf,
  mentionedUids,
  mentionPushBody,
  messagePushBody,
  notifiesAsMessage,
  pinnedIdsOf,
  renamedLine,
  replyPreviewOf,
  replyPushBody,
  replyRecipientOf,
} from '../../src/chat/service.js';
import { Limits } from '../../src/shared/constants.js';
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

  it('names a posted play (BOARD-5)', () => {
    expect(lastMessagePreviewOf({ authorName: 'Sam', text: 'Relay', type: 'image', playId: 'p1' }).text).toBe(
      'Play: Relay',
    );
    expect(lastMessagePreviewOf({ authorName: 'Sam', text: '', type: 'image', playId: 'p1' }).text).toBe('Play');
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
    expect(messagePushBody({ authorName: 'Alex', type: 'image', text: 'Relay', playId: 'p1', attachments: [{}] })).toBe(
      'Alex posted a play: Relay',
    );
    expect(messagePushBody({ authorName: 'Alex', type: 'image', text: '', playId: 'p1', attachments: [{}] })).toBe(
      'Alex posted a play',
    );
  });

  it('words a reply push', () => {
    expect(replyPushBody({ authorName: 'Alex', type: 'text', text: 'Sounds good' })).toBe('Alex replied to you: Sounds good');
    expect(replyPushBody({ authorName: 'Alex', type: 'image', text: '', attachments: [{}] })).toBe(
      'Alex replied to you with a photo',
    );
  });
});

describe('mentions, announcements, and pins (CHAT-14, CHAT-15)', () => {
  it('words a mention push, for one person or everyone', () => {
    expect(mentionPushBody({ authorName: 'Alex', type: 'text', text: '@Sam can you drive?' })).toBe(
      'Alex mentioned you: @Sam can you drive?',
    );
    expect(mentionPushBody({ authorName: 'Alex', type: 'text', text: '@everyone 5pm', mentionsEveryone: true })).toBe(
      'Alex mentioned everyone: @everyone 5pm',
    );
    expect(mentionPushBody({ authorName: 'Alex', type: 'image', text: '', attachments: [{}, {}] })).toBe(
      'Alex mentioned you with 2 photos',
    );
  });

  it('words an announcement push', () => {
    expect(announcementPushBody({ authorName: 'Coach', type: 'text', text: 'No practice Friday' })).toBe(
      'Announcement from Coach: No practice Friday',
    );
  });

  it('counts only text marked as an announcement', () => {
    expect(isAnnouncement({ type: 'text', announcement: true })).toBe(true);
    expect(isAnnouncement({ type: 'text', announcement: 'yes' })).toBe(false);
    expect(isAnnouncement({ type: 'image', announcement: true })).toBe(false);
    expect(isAnnouncement({ type: 'text' })).toBe(false);
  });

  it('reads who a message names: IDs only, once each, never the author, up to the limit', () => {
    expect(mentionedUids({ authorId: 'alex', mentions: ['sam', 'sam', 'alex', 7, '', 'a/b', 'x_y', 'pat'] })).toEqual([
      'sam',
      'pat',
    ]);
    expect(mentionedUids({ authorId: 'alex', mentions: 'sam' })).toEqual([]);
    expect(mentionedUids({ authorId: 'alex' })).toEqual([]);
    const many = Array.from({ length: 30 }, (_, i) => `u${i}`);
    expect(mentionedUids({ authorId: 'alex', mentions: many })).toHaveLength(Limits.mentionsMax);
  });

  it("reads a team's pins, skipping anything that isn't an ID", () => {
    expect(pinnedIdsOf(['m1', 3, 'm2'])).toEqual(['m1', 'm2']);
    expect(pinnedIdsOf(undefined)).toEqual([]);
    expect(pinnedIdsOf('m1')).toEqual([]);
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
