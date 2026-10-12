import { afterEach, describe, expect, it } from 'vitest';
import { activateUrl, appUrl, joinUrl, linkHost, teamUrl } from '../../src/links/service.js';

// The website is at the root and the web app under /app (D40, ARCH §6.6).
describe('links', () => {
  const before = process.env.GCLOUD_PROJECT;
  afterEach(() => {
    if (before === undefined) delete process.env.GCLOUD_PROJECT;
    else process.env.GCLOUD_PROJECT = before;
  });

  it('points at the dev Hosting domain outside prod', () => {
    process.env.GCLOUD_PROJECT = 'battleplan-dev-ecce4';
    expect(linkHost()).toBe('battleplan-dev-ecce4.web.app');
    expect(teamUrl('g1')).toBe('https://battleplan-dev-ecce4.web.app/app/g/g1/chat');
  });

  it('uses getbattleplan.app in prod', () => {
    process.env.GCLOUD_PROJECT = 'battleplan-prod';
    expect(linkHost()).toBe('getbattleplan.app');
    expect(joinUrl('K7XPM2QR')).toBe('https://getbattleplan.app/join/K7XPM2QR');
    expect(activateUrl()).toBe('https://getbattleplan.app/app/activate');
    expect(teamUrl('g1')).toBe('https://getbattleplan.app/app/g/g1/chat');
  });

  it('keeps invite links short, at the root (WEB-4)', () => {
    process.env.GCLOUD_PROJECT = 'battleplan-prod';
    expect(joinUrl('K7XPM2QR')).not.toContain('/app/');
  });

  it('puts every app route under /app', () => {
    process.env.GCLOUD_PROJECT = 'battleplan-prod';
    expect(appUrl('/g/a/chat/m/m1')).toBe('https://getbattleplan.app/app/g/a/chat/m/m1');
    expect(appUrl('g/a/roster')).toBe('https://getbattleplan.app/app/g/a/roster');
    expect(appUrl('/')).toBe('https://getbattleplan.app/app/');
    expect(appUrl('/sign-in/email')).toBe('https://getbattleplan.app/app/sign-in/email');
  });
});
