import { Timestamp } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';
import {
  buildPayload,
  canReceive,
  centerItemId,
  chunk,
  levelAllowsPush,
  memberSettingsOf,
  prefAllowsPush,
  pushAllowed,
  shouldDeleteToken,
  tokensToDelete,
  truncate,
} from '../../src/notify/service.js';
import { Limits, NOTIFY_KINDS, notificationPrefValues, notifyKindValues } from '../../src/shared/constants.js';

const now = Date.parse('2026-10-11T12:00:00Z');
const unmuted = { level: 'all', mutedUntilMs: null };

describe('the kind table (NOTIF-2)', () => {
  it('lists every kind, with a known switch and only plain messages left out of the center', () => {
    expect(Object.keys(NOTIFY_KINDS).sort()).toEqual([...notifyKindValues].sort());
    for (const info of Object.values(NOTIFY_KINDS)) {
      if (info.pref) expect(notificationPrefValues).toContain(info.pref);
    }
    expect(notifyKindValues.filter((k) => !NOTIFY_KINDS[k].center)).toEqual(['message']);
  });
});

describe('levelAllowsPush (NOTIF-3)', () => {
  it('All activity pushes every kind', () => {
    expect(levelAllowsPush('message', unmuted, now)).toBe(true);
    expect(levelAllowsPush('reply', unmuted, now)).toBe(true);
    expect(levelAllowsPush('documentAdded', unmuted, now)).toBe(true);
  });

  it('Important only pushes only the important kinds', () => {
    const important = { level: 'important', mutedUntilMs: null };
    expect(levelAllowsPush('message', important, now)).toBe(false);
    expect(levelAllowsPush('pollCreated', important, now)).toBe(false);
    expect(levelAllowsPush('eventCreated', important, now)).toBe(false);
    expect(levelAllowsPush('reply', important, now)).toBe(true);
    expect(levelAllowsPush('addedToTeam', important, now)).toBe(true);
    expect(levelAllowsPush('contentReported', important, now)).toBe(true);
    expect(levelAllowsPush('eventChanged', important, now)).toBe(true);
    expect(levelAllowsPush('eventReminder', important, now)).toBe(true);
  });

  it('Off pushes nothing, not even important kinds', () => {
    const off = { level: 'none', mutedUntilMs: null };
    expect(levelAllowsPush('message', off, now)).toBe(false);
    expect(levelAllowsPush('reply', off, now)).toBe(false);
    expect(levelAllowsPush('madeAdmin', off, now)).toBe(false);
  });

  it('a mute still ahead pushes nothing; one that has passed is ignored', () => {
    expect(levelAllowsPush('reply', { level: 'all', mutedUntilMs: now + 60_000 }, now)).toBe(false);
    expect(levelAllowsPush('reply', { level: 'important', mutedUntilMs: now + 60_000 }, now)).toBe(false);
    expect(levelAllowsPush('message', { level: 'all', mutedUntilMs: now - 60_000 }, now)).toBe(true);
    expect(levelAllowsPush('message', { level: 'all', mutedUntilMs: now }, now)).toBe(true);
  });

  it('"until unmuted" is a mute that never passes', () => {
    expect(levelAllowsPush('reply', { level: 'all', mutedUntilMs: Limits.mutedForeverMs }, now)).toBe(false);
  });
});

describe('prefAllowsPush (NOTIF-4)', () => {
  it('turns a kind off only when its switch is false; a missing key or profile is on', () => {
    expect(prefAllowsPush('message', { messages: false })).toBe(false);
    expect(prefAllowsPush('message', { messages: true })).toBe(true);
    expect(prefAllowsPush('message', {})).toBe(true);
    expect(prefAllowsPush('message', undefined)).toBe(true);
    expect(prefAllowsPush('reply', { messages: false })).toBe(true);
    expect(prefAllowsPush('reply', { replies: false })).toBe(false);
    expect(prefAllowsPush('pollClosed', { polls: false })).toBe(false);
    expect(prefAllowsPush('documentAdded', { documents: false })).toBe(false);
    expect(prefAllowsPush('eventReminder', { reminders: false })).toBe(false);
  });

  it('kinds with no switch always pass', () => {
    const allOff = Object.fromEntries(notificationPrefValues.map((k) => [k, false]));
    for (const kind of ['addedToTeam', 'madeAdmin', 'guardianRequest', 'guardianApproved', 'playerAdded',
      'contentReported', 'storageWarning'] as const) {
      expect(prefAllowsPush(kind, { ...allOff, events: false })).toBe(true);
    }
  });

  it('the old single events switch still turns off New events and Event changes', () => {
    expect(prefAllowsPush('eventCreated', { events: false })).toBe(false);
    expect(prefAllowsPush('eventChanged', { events: false })).toBe(false);
    expect(prefAllowsPush('eventCreated', { events: true })).toBe(true);
    // Reminders always had their own switch.
    expect(prefAllowsPush('eventReminder', { events: false })).toBe(true);
  });

  it('a new events switch, once set, wins over the old one', () => {
    expect(prefAllowsPush('eventCreated', { events: false, eventsNew: true })).toBe(true);
    expect(prefAllowsPush('eventChanged', { events: true, eventsChanged: false })).toBe(false);
    expect(prefAllowsPush('eventChanged', { events: false, eventsNew: true })).toBe(false);
  });
});

describe('pushAllowed', () => {
  it('needs both the team settings and the global switch', () => {
    expect(pushAllowed('message', unmuted, { messages: true }, now)).toBe(true);
    expect(pushAllowed('message', unmuted, { messages: false }, now)).toBe(false);
    expect(pushAllowed('message', { level: 'important', mutedUntilMs: null }, { messages: true }, now)).toBe(false);
    expect(pushAllowed('reply', { level: 'important', mutedUntilMs: null }, { replies: true }, now)).toBe(true);
    expect(pushAllowed('reply', { level: 'important', mutedUntilMs: null }, { replies: false }, now)).toBe(false);
    expect(pushAllowed('reply', { level: 'all', mutedUntilMs: now + 1 }, {}, now)).toBe(false);
  });
});

describe('canReceive', () => {
  it('skips missing and disabled accounts', () => {
    expect(canReceive(undefined)).toBe(false);
    expect(canReceive({ status: 'disabled' })).toBe(false);
    expect(canReceive({ status: 'active' })).toBe(true);
    expect(canReceive({ status: 'provisioned' })).toBe(true);
  });
});

describe('memberSettingsOf', () => {
  it('reads the level and mute, defaulting to All activity and unmuted', () => {
    expect(memberSettingsOf('u1', { notificationLevel: 'important', mutedUntil: Timestamp.fromMillis(now) })).toEqual({
      uid: 'u1',
      level: 'important',
      mutedUntilMs: now,
    });
    expect(memberSettingsOf('u2', { mutedUntil: null })).toEqual({ uid: 'u2', level: 'all', mutedUntilMs: null });
    expect(memberSettingsOf('u3', undefined)).toEqual({ uid: 'u3', level: 'all', mutedUntilMs: null });
  });
});

describe('truncate', () => {
  it('keeps short text and flattens it to one line', () => {
    expect(truncate('Alex: See you at 6')).toBe('Alex: See you at 6');
    expect(truncate('  Alex: Bring\ncleats\n\nand  water ')).toBe('Alex: Bring cleats and water');
  });

  it('cuts long text to the limit with an ellipsis', () => {
    const out = truncate(`Alex: ${'word '.repeat(60)}`);
    expect([...out].length).toBeLessThanOrEqual(Limits.notificationBodyMax);
    expect(out.endsWith('…')).toBe(true);
    expect(truncate('x'.repeat(Limits.notificationBodyMax))).toBe('x'.repeat(Limits.notificationBodyMax));
    expect(truncate('x'.repeat(Limits.notificationBodyMax + 1))).toBe(`${'x'.repeat(Limits.notificationBodyMax - 1)}…`);
  });

  it('never splits an emoji', () => {
    const out = truncate('😀'.repeat(200), 10);
    expect([...out]).toEqual([...'😀'.repeat(9), '…']);
    expect(out).not.toMatch(/[\uD800-\uDBFF](?![\uDC00-\uDFFF])/);
  });
});

describe('chunk', () => {
  it('splits into runs of at most the size', () => {
    expect(chunk([1, 2, 3, 4, 5], 2)).toEqual([[1, 2], [3, 4], [5]]);
    expect(chunk([], 30)).toEqual([]);
    expect(chunk(Array.from({ length: 61 }, (_, i) => i), 30).map((c) => c.length)).toEqual([30, 30, 1]);
  });
});

describe('centerItemId', () => {
  it('is the dedupe key and the person, so the app can find it from a push', () => {
    expect(centerItemId('m123_reply', 'u9')).toBe('m123_reply_u9');
  });
});

describe('buildPayload (ARCH §6.5)', () => {
  const content = {
    teamName: 'Thunder',
    body: 'Alex replied to you: Sounds good',
    route: '/g/g1/chat/m/m1',
    groupId: 'g1',
    kind: 'reply' as const,
    nkey: 'm1_reply',
  };

  it('titles with the team, carries the route and center key, and stacks by team on iOS', () => {
    expect(buildPayload(content)).toEqual({
      notification: { title: 'Thunder', body: 'Alex replied to you: Sounds good' },
      data: { route: '/g/g1/chat/m/m1', groupId: 'g1', kind: 'reply', nkey: 'm1_reply' },
      apns: { payload: { aps: { 'thread-id': 'g1', sound: 'default' } } },
      android: { priority: 'high', notification: { channelId: 'replies' } },
      webpush: {
        // The web app is under /app (D40), so the click opens /app<route>.
        notification: { icon: 'https://demo-battleplan.web.app/app/icons/Icon-192.png' },
        fcmOptions: { link: 'https://demo-battleplan.web.app/app/g/g1/chat/m/m1' },
      },
    });
  });

  it('sends only strings in data', () => {
    for (const v of Object.values(buildPayload(content).data ?? {})) expect(typeof v).toBe('string');
  });

  it('uses no tag, which would replace earlier notifications instead of stacking (NOTIF-8)', () => {
    const p = buildPayload(content);
    expect(p.android?.notification).not.toHaveProperty('tag');
    expect(p.webpush?.notification).not.toHaveProperty('tag');
    expect(p.webpush?.notification).not.toHaveProperty('renotify');
  });

  it('picks the Android channel by kind', () => {
    const channel = (kind: (typeof notifyKindValues)[number]) => buildPayload({ ...content, kind }).android?.notification?.channelId;
    expect(channel('message')).toBe('messages');
    expect(channel('reply')).toBe('replies');
    expect(channel('addedToTeam')).toBe('team');
    expect(channel('contentReported')).toBe('team');
    expect(channel('storageWarning')).toBe('team');
    expect(channel('pollCreated')).toBe('polls');
    expect(channel('eventReminder')).toBe('events');
    expect(channel('documentAdded')).toBe('documents');
  });

  it('shortens the body to the limit', () => {
    const p = buildPayload({ ...content, body: `Alex: ${'x'.repeat(500)}` });
    expect([...(p.notification?.body ?? '')].length).toBe(Limits.notificationBodyMax);
  });
});

describe('token cleanup (ARCH §6.5 step 4)', () => {
  const ok = { success: true };
  const fail = (code: string) => ({ success: false, error: { code } });

  it('always forgets unregistered and malformed tokens', () => {
    expect(shouldDeleteToken('messaging/registration-token-not-registered', false)).toBe(true);
    expect(shouldDeleteToken('messaging/invalid-registration-token', false)).toBe(true);
  });

  it('forgets on invalid-argument only when other tokens in the batch went through', () => {
    expect(shouldDeleteToken('messaging/invalid-argument', true)).toBe(true);
    expect(shouldDeleteToken('messaging/invalid-argument', false)).toBe(false);
  });

  it('keeps tokens on passing trouble', () => {
    for (const code of ['messaging/internal-error', 'messaging/server-unavailable', 'messaging/message-rate-exceeded',
      'messaging/third-party-auth-error', 'messaging/mismatched-credential']) {
      expect(shouldDeleteToken(code, true)).toBe(false);
    }
    expect(shouldDeleteToken(undefined, true)).toBe(false);
  });

  it('picks the positions to forget in a batch', () => {
    expect(tokensToDelete([ok, fail('messaging/registration-token-not-registered'), fail('messaging/invalid-argument'),
      fail('messaging/internal-error')])).toEqual([1, 2]);
  });

  it('keeps every device when a bad payload fails the whole batch', () => {
    expect(tokensToDelete([fail('messaging/invalid-argument'), fail('messaging/invalid-argument')])).toEqual([]);
    expect(tokensToDelete([fail('messaging/invalid-argument'), fail('messaging/invalid-registration-token')])).toEqual([1]);
  });
});
