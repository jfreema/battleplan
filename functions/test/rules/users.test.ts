// Rules tests for users/{uid} (roadmap task 37) and profile photos in
// Storage. Run with: npm --prefix functions run emulators:test
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import firebase from 'firebase/compat/app';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { defaultNotificationPrefs } from '../../src/accounts/service.js';
import { notificationPrefValues } from '../../src/shared/constants.js';

let env: RulesTestEnvironment;
const now = () => firebase.firestore.FieldValue.serverTimestamp();

const profile = (name: string) => ({
  displayName: name,
  displayNameLower: name.toLowerCase(),
  email: `${name.toLowerCase()}@example.com`,
  emailLower: `${name.toLowerCase()}@example.com`,
  photoPath: null,
  status: 'active',
  signInMethods: ['password'],
  themeMode: 'system',
  // As the server makes a new account's (ensureUserProfile), every switch.
  notificationPrefs: defaultNotificationPrefs(),
  acceptedTermsAt: firebase.firestore.Timestamp.now(),
  adultConfirmedAt: firebase.firestore.Timestamp.now(),
});

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-battleplan',
    firestore: { rules: readFileSync(resolve(process.cwd(), '../firestore.rules'), 'utf8') },
    storage: { rules: readFileSync(resolve(process.cwd(), '../storage.rules'), 'utf8') },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc('users/alice').set(profile('Alice'));
    await ctx.firestore().doc('users/bob').set(profile('Bob'));
  });
});

afterAll(async () => {
  await env?.cleanup();
});

const as = (uid: string, claims: Record<string, unknown> = {}) =>
  env.authenticatedContext(uid, claims).firestore();

describe('users: reading', () => {
  it('lets people read only their own profile', async () => {
    await assertSucceeds(as('alice').doc('users/alice').get());
    await assertFails(as('alice').doc('users/bob').get());
    await assertFails(env.unauthenticatedContext().firestore().doc('users/alice').get());
  });

  it('lets super admins read any profile', async () => {
    await assertSucceeds(as('admin', { superAdmin: true }).doc('users/bob').get());
  });

  it('never allows listing profiles', async () => {
    await assertFails(as('alice').collection('users').limit(10).get());
  });
});

describe('users: writing', () => {
  it('allows editing your own name, theme, photo, and notification prefs', async () => {
    const db = as('alice');
    await assertSucceeds(db.doc('users/alice').update({
      displayName: 'Alice K',
      displayNameLower: 'alice k',
      updatedAt: now(),
    }));
    await assertSucceeds(db.doc('users/alice').update({ themeMode: 'dark' }));
    await assertSucceeds(db.doc('users/alice').update({ themeMode: 'candy' }));
    await assertSucceeds(db.doc('users/alice').update({ themeMode: 'arena' }));
    await assertSucceeds(db.doc('users/alice').update({ themeMode: 'olive' }));
    await assertSucceeds(db.doc('users/alice').update({ themeMode: 'system' }));
    await assertSucceeds(db.doc('users/alice').update({ themeMode: 'light' }));
    await assertSucceeds(db.doc('users/alice').update({ photoPath: 'users/alice/avatar/123.jpg' }));
    await assertSucceeds(db.doc('users/alice').update({ 'notificationPrefs.messages': false }));
    await assertSucceeds(db.doc('users/alice').update({ 'notificationPrefs.eventsChanged': false }));
  });

  it('takes a time zone (SET-7): an IANA ID, or null for Automatic', async () => {
    const db = as('alice');
    for (const zone of ['America/Chicago', 'America/Argentina/Buenos_Aires', 'America/Port-au-Prince', 'Etc/GMT+5', 'UTC']) {
      await assertSucceeds(db.doc('users/alice').update({ timeZone: zone, updatedAt: now() }));
    }
    await assertSucceeds(db.doc('users/alice').update({ timeZone: null, updatedAt: now() }));
    for (const bad of ['', '../x', 'America/Chicago; drop', 'x'.repeat(65), 42, ['UTC']]) {
      await assertFails(db.doc('users/alice').update({ timeZone: bad }));
    }
    await assertFails(as('bob').doc('users/alice').update({ timeZone: 'UTC' }));
  });

  it('rejects server-only fields', async () => {
    const db = as('alice');
    await assertFails(db.doc('users/alice').update({ status: 'disabled' }));
    await assertFails(db.doc('users/alice').update({ email: 'other@example.com' }));
    await assertFails(db.doc('users/alice').update({ signInMethods: ['google.com'] }));
    await assertFails(db.doc('users/alice').update({ adultConfirmedAt: now() }));
    await assertFails(db.doc('users/alice').update({ acceptedTermsAt: null }));
    // AUTH-6 and AUTH-9: set by Functions only.
    await assertFails(db.doc('users/alice').update({ chooseSignIn: false }));
    await assertFails(db.doc('users/alice').update({ sessionsRevokedAt: null }));
  });

  it('rejects invalid values', async () => {
    const db = as('alice');
    await assertFails(db.doc('users/alice').update({ displayName: '', displayNameLower: '' }));
    await assertFails(db.doc('users/alice').update({ displayName: 'x'.repeat(51), displayNameLower: 'x'.repeat(51) }));
    await assertFails(db.doc('users/alice').update({ displayName: 'Alice', displayNameLower: 'someone else' }));
    await assertFails(db.doc('users/alice').update({ themeMode: 'neon' }));
    await assertFails(db.doc('users/alice').update({ photoPath: 'users/bob/avatar/1.jpg' }));
    await assertFails(db.doc('users/alice').update({ updatedAt: firebase.firestore.Timestamp.fromMillis(0) }));
  });

  it('blocks editing someone else, creating, and deleting', async () => {
    await assertFails(as('alice').doc('users/bob').update({ themeMode: 'dark' }));
    await assertFails(as('carol').doc('users/carol').set(profile('Carol')));
    await assertFails(as('alice').doc('users/alice').delete());
  });
});

describe('profile photos in Storage', () => {
  const jpeg = new Uint8Array([0xff, 0xd8, 0xff, 0xe0]);

  it('lets people upload only to their own avatar folder, images only', async () => {
    const storage = env.authenticatedContext('alice').storage();
    await assertSucceeds(storage.ref('users/alice/avatar/1.jpg').put(jpeg, { contentType: 'image/jpeg' }).then(() => undefined));
    await assertFails(storage.ref('users/bob/avatar/1.jpg').put(jpeg, { contentType: 'image/jpeg' }).then(() => undefined));
    await assertFails(storage.ref('users/alice/avatar/1.txt').put(jpeg, { contentType: 'text/plain' }).then(() => undefined));
    // The crop step (SET-1) uploads a PNG.
    const png = new Uint8Array([0x89, 0x50, 0x4e, 0x47]);
    await assertSucceeds(storage.ref('users/alice/avatar/2.png').put(png, { contentType: 'image/png' }).then(() => undefined));
  });

  it('lets signed-in people see avatars, but not visitors', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      ctx.storage().ref('users/alice/avatar/2.jpg').put(jpeg, { contentType: 'image/jpeg' }).then(() => undefined),
    );
    await assertSucceeds(env.authenticatedContext('bob').storage().ref('users/alice/avatar/2.jpg').getDownloadURL());
    await assertFails(env.unauthenticatedContext().storage().ref('users/alice/avatar/2.jpg').getDownloadURL());
  });
});

describe('users: the rules keep up with constants.json', () => {
  it('lets a new account change its name, photo, theme, and every notification switch', async () => {
    await assertSucceeds(
      as('alice').doc('users/alice').update({ displayName: 'Ally', displayNameLower: 'ally', updatedAt: now() }),
    );
    await assertSucceeds(as('alice').doc('users/alice').update({ themeMode: 'dark', updatedAt: now() }));
    for (const key of notificationPrefValues) {
      await assertSucceeds(as('alice').doc('users/alice').update({ [`notificationPrefs.${key}`]: false, updatedAt: now() }));
    }
  });

  it("lists every notification switch and theme the app knows, as the rules can't read constants.json", () => {
    const rules = readFileSync(resolve(process.cwd(), '../firestore.rules'), 'utf8');
    const prefs = rules.slice(rules.indexOf('function validPrefs'), rules.indexOf('}', rules.indexOf('function validPrefs')));
    for (const key of notificationPrefValues) expect(prefs, key).toContain(`'${key}'`);
    const constants = JSON.parse(readFileSync(resolve(process.cwd(), '../shared/constants.json'), 'utf8'));
    const themes = rules.match(/p\.themeMode in \[([^\]]*)\]/)?.[1] ?? '';
    for (const theme of constants.enums.themePreference as string[]) expect(themes, theme).toContain(`'${theme}'`);
  });
});
