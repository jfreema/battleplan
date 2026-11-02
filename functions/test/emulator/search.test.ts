// Chat search's words on the server (CHAT-20): a message whose words don't
// match its text gets the right ones, the language filter's masking and
// erasing a message take them along, and messages from before search get
// theirs a page at a time. Runs against the Firestore emulator:
//   npm --prefix functions run emulators:test
import { Timestamp } from 'firebase-admin/firestore';
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { backfillSearchWords, syncSearchWords } from '../../src/chat/search.js';
import { eraseMessage, filterMessageLanguage } from '../../src/chat/service.js';
import { db } from '../../src/shared/admin.js';
import { Collections } from '../../src/shared/constants.js';

vi.mock('../../src/shared/admin.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('../../src/shared/admin.js')>()),
  messaging: () => ({ sendEach: async () => ({ responses: [], successCount: 0, failureCount: 0 }) }),
}));

const G = 'teamA';
const messages = () => db().collection(Collections.messages);
const at = (minute: number) => Timestamp.fromDate(new Date(Date.UTC(2030, 5, 1, 12, minute)));

/** A message in team A, [minute] minutes after noon. */
async function message(id: string, minute: number, fields: Record<string, unknown> = {}): Promise<void> {
  await messages().doc(id).set({
    groupId: G, authorId: 'sam', authorName: 'Sam Rivera', authorPhotoPath: null, authorPlayerSummary: null,
    type: 'text', text: `Message ${id}`, attachments: [], reactions: {}, createdAt: at(minute), ...fields,
  });
}

const words = async (id: string) => (await messages().doc(id).get()).get('words') as unknown;

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Run with npm run emulators:test');
});

beforeEach(async () => {
  const project = process.env.GCLOUD_PROJECT ?? 'demo-battleplan';
  const res = await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${project}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
  expect(res.ok).toBe(true);
  await db().collection(Collections.groups).doc(G).set({ name: 'Thunder', ownerId: 'pat', memberCount: 2, settings: {} });
});

describe('a new or edited message gets the words its text has', () => {
  it('fills in missing ones and puts right wrong ones', async () => {
    await message('m1', 1, { text: 'Tournament at Riverside' });
    await message('m2', 2, { text: 'Free pizza', words: ['tournament'] });
    for (const id of ['m1', 'm2']) {
      await syncSearchWords(id, (await messages().doc(id).get()).data()!);
    }
    expect(await words('m1')).toEqual(['tournament', 'riverside']);
    expect(await words('m2')).toEqual(['free', 'pizza']);
  });

  it('writes nothing when they already match, and leaves deleted messages and system lines without', async () => {
    await message('m1', 1, { text: 'Tournament at Riverside', words: ['tournament', 'riverside'] });
    const before = (await messages().doc('m1').get()).updateTime;
    await syncSearchWords('m1', (await messages().doc('m1').get()).data()!);
    expect((await messages().doc('m1').get()).updateTime).toEqual(before);

    await message('m2', 2, { type: 'system', text: 'Sam joined', words: ['sam'] });
    await syncSearchWords('m2', (await messages().doc('m2').get()).data()!);
    expect(await words('m2')).toBeUndefined();

    await message('m3', 3, { text: '', deletedAt: at(4) });
    await syncSearchWords('m3', (await messages().doc('m3').get()).data()!);
    expect(await words('m3')).toBeUndefined();
  });

  it('gives event cards and poll questions theirs too', async () => {
    await message('e1', 1, { type: 'event', text: 'vs. Eagles · Sat, Jun 1 at 9:00 AM · Riverside Park' });
    await message('p1', 2, { type: 'poll', text: 'Pizza or tacos?' });
    for (const id of ['e1', 'p1']) {
      await syncSearchWords(id, (await messages().doc(id).get()).data()!);
    }
    expect(await words('e1')).toEqual(['vs', 'eagle', 'sat', 'jun', '00', 'am', 'riverside', 'park']);
    expect(await words('p1')).toEqual(['pizza', 'taco']);
  });
});

describe('the language filter and erasing take the words along', () => {
  it('masks the text and gives it the masked words in the same update (SAFE-7)', async () => {
    await message('m1', 1, { text: 'Great fucking game', words: ['great', 'fucking', 'game'] });
    const filtered = await filterMessageLanguage('m1', (await messages().doc('m1').get()).data()!);
    expect(filtered.text).toBe('Great f****** game');
    expect(filtered.words).toEqual(['great', 'game']);
    expect(await words('m1')).toEqual(['great', 'game']);
  });

  it('erasing a message takes its words, so search no longer finds it (CHAT-8)', async () => {
    await message('m1', 1, { text: 'Tournament at Riverside', words: ['tournament', 'riverside'] });
    await eraseMessage('m1', 'sam', 'author');
    expect(await words('m1')).toBeUndefined();
  });
});

describe('messages from before search get their words, a page at a time', () => {
  it('walks every message once, from where the last run stopped, then stops', async () => {
    await message('a1', 1, { text: 'Bring cleats' });
    await message('a2', 2, { text: 'Snacks are covered', words: ['snack', 'covered'] });
    await message('a3', 3, { type: 'system', text: 'Sam joined' });
    await message('a4', 4, { text: '', deletedAt: at(5) });
    await message('a5', 5, { type: 'image', text: 'Team photo' });

    // Two at a time, in ID order: a1 and a2, then a3 and a4, then a5.
    expect(await backfillSearchWords(2)).toBe(1);
    expect(await words('a1')).toEqual(['bring', 'cleat']);
    expect(await words('a5')).toBeUndefined();
    expect(await backfillSearchWords(2)).toBe(0);
    expect(await backfillSearchWords(2)).toBe(1);
    expect(await words('a5')).toEqual(['team', 'photo']);
    expect(await words('a3')).toBeUndefined();
    expect(await words('a4')).toBeUndefined();
    const state = await db().collection(Collections.config).doc('searchWords').get();
    expect(state.get('done')).toBe(true);

    // Done: a later run reads only where it got to.
    await message('a0', 6, { text: 'Added since' });
    expect(await backfillSearchWords(2)).toBe(0);
    expect(await words('a0')).toBeUndefined();
  });
});
