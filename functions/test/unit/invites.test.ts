import { Timestamp } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';
import { formatCode, newInviteCode, normalizeCode } from '../../src/invites/codes.js';
import { inviteDescription, invitePreviewPage, inviteTitle, isPreviewFetcher } from '../../src/invites/page.js';
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

describe("an invite link's preview (task 140)", () => {
  const urls = {
    joinUrl: 'https://getbattleplan.app/join/K7XPM2QR',
    appJoinUrl: 'https://getbattleplan.app/app/join/K7XPM2QR',
    siteImage: 'https://getbattleplan.app/images/og.png',
  };

  it('is for link-preview fetchers, not people', () => {
    for (const agent of [
      'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
      // iMessage
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_1) AppleWebKit/601.2.4 (KHTML, like Gecko) Version/9.0.1 Safari/601.2.4 facebookexternalhit/1.1 Facebot Twitterbot/1.0',
      'WhatsApp/2.23.20.0 A',
      'Slackbot-LinkExpanding 1.0 (+https://api.slack.com/robots)',
      'Mozilla/5.0 (compatible; Discordbot/2.0; +https://discordapp.com)',
      'TelegramBot (like TwitterBot)',
      'LinkedInBot/1.0 (compatible; Mozilla/5.0; Apache-HttpClient +http://www.linkedin.com)',
    ]) {
      expect(isPreviewFetcher(agent), agent).toBe(true);
    }
    for (const agent of [
      'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1',
      'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Mobile Safari/537.36',
      'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Snapchat/13.0',
    ]) {
      expect(isPreviewFetcher(agent), agent).toBe(false);
    }
    expect(isPreviewFetcher(undefined)).toBe(false);
  });

  it("names the team and who invited you, with the team's logo", () => {
    const card = { teamName: 'Thunder U14', logoUrl: 'https://cdn.example/logo.png', invitedBy: 'Coach Lee' };
    expect(inviteTitle(card)).toBe('Join Thunder U14 on Battleplan');
    expect(inviteDescription(card)).toBe("Coach Lee invited you to the team's chat, schedule, and RSVPs.");
    const html = invitePreviewPage(card, urls);
    expect(html).toContain('<meta property="og:title" content="Join Thunder U14 on Battleplan">');
    expect(html).toContain('<meta property="og:image" content="https://cdn.example/logo.png">');
    expect(html).toContain('<meta property="og:url" content="https://getbattleplan.app/join/K7XPM2QR">');
    expect(html).toContain('<meta name="twitter:card" content="summary">');
    expect(html).toContain('href="https://getbattleplan.app/app/join/K7XPM2QR"');
    expect(html).toContain('noindex');
  });

  it("is Battleplan's own without a logo, an inviter, or a team", () => {
    const noLogo = invitePreviewPage({ teamName: 'Cyclone', logoUrl: null, invitedBy: null }, urls);
    expect(noLogo).toContain('<meta property="og:image" content="https://getbattleplan.app/images/og.png">');
    expect(noLogo).toContain('<meta property="og:image:width" content="1200">');
    expect(noLogo).toContain('<meta name="twitter:card" content="summary_large_image">');
    expect(noLogo).toContain("The team&#39;s chat, schedule, and RSVPs, in one app.");
    const none = invitePreviewPage(null, urls);
    expect(none).toContain('<title>Join your team on Battleplan</title>');
  });

  it('escapes what people typed', () => {
    const html = invitePreviewPage({ teamName: '<b>"Ducks"</b>', logoUrl: null, invitedBy: 'A & B' }, urls);
    expect(html).toContain('Join &lt;b&gt;&quot;Ducks&quot;&lt;/b&gt; on Battleplan');
    expect(html).toContain('A &amp; B invited you');
    expect(html).not.toContain('<b>');
  });
});
