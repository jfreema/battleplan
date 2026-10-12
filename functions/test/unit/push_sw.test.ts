// The web push worker's tap handling (NOTIF-6, D40): web/firebase-messaging-sw.js
// runs with the browser's service-worker globals, stubbed here.
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { runInNewContext } from 'node:vm';
import { describe, expect, it } from 'vitest';

const source = readFileSync(resolve(process.cwd(), '../web/firebase-messaging-sw.js'), 'utf8');
const SCOPE = 'https://getbattleplan.app/app/';
const LINK = 'https://getbattleplan.app/app/g/g1/chat/m/m1';

/** Loads the worker and returns what a click on a notification does. */
async function click(windows: string[], data: unknown) {
  const listeners: ((e: unknown) => void)[] = [];
  const opened: string[] = [];
  const navigated: string[] = [];
  const focused: string[] = [];
  const clients = {
    matchAll: async () =>
      windows.map((url) => ({
        url,
        focus: async () => void focused.push(url),
        navigate: async (to: string) => void navigated.push(`${url} -> ${to}`),
      })),
    openWindow: async (url: string) => void opened.push(url),
  };
  const self = {
    location: { href: `${SCOPE}firebase-messaging-sw.js` },
    registration: { scope: SCOPE },
    addEventListener: (type: string, fn: (e: unknown) => void) => {
      if (type === 'notificationclick') listeners.push(fn);
    },
  };
  runInNewContext(source, {
    self,
    clients,
    URL,
    importScripts: () => {},
    firebase: { initializeApp: () => {}, messaging: () => {} },
  });
  let work: Promise<unknown> = Promise.resolve();
  let stopped = false;
  const event = {
    notification: { data, close: () => {} },
    stopImmediatePropagation: () => (stopped = true),
    waitUntil: (p: Promise<unknown>) => (work = p),
  };
  listeners[0](event);
  await work;
  return { opened, navigated, focused, stopped };
}

describe('web push taps', () => {
  const fcm = { FCM_MSG: { fcmOptions: { link: LINK } } };

  it('opens the route in an app tab, never in a website tab on the same origin', async () => {
    const r = await click(['https://getbattleplan.app/privacy', `${SCOPE}g/g2/schedule`], fcm);
    expect(r.stopped).toBe(true);
    expect(r.focused).toEqual([`${SCOPE}g/g2/schedule`]);
    expect(r.navigated).toEqual([`${SCOPE}g/g2/schedule -> ${LINK}`]);
    expect(r.opened).toEqual([]);
  });

  it('opens a new tab when only website pages are open', async () => {
    const r = await click(['https://getbattleplan.app/', 'https://getbattleplan.app/support'], fcm);
    expect(r.opened).toEqual([LINK]);
    expect(r.focused).toEqual([]);
  });

  it('leaves notifications without a link to the SDK', async () => {
    const r = await click([`${SCOPE}`], { other: true });
    expect(r.stopped).toBe(false);
    expect(r.opened).toEqual([]);
  });
});
