// Shared plays on the server (SPEC BOARD-6, ARCH §6.14): sharePlay, the
// public copy and its picture, what happens to them as the play changes or
// goes, and the link's page. Runs against the Firestore and Storage
// emulators:
//   npm --prefix functions run emulators:test
import { beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { playPage, sharePlay } from '../../src/plays/handlers.js';
import { followPlayChange, shareImagePath, sharedPlayImage } from '../../src/plays/service.js';
import { db, storage } from '../../src/shared/admin.js';
import { Collections } from '../../src/shared/constants.js';
import { groupMemberId } from '../../src/shared/ids.js';

const G = 'thunder';
const PNG = Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), Buffer.alloc(32, 7)]);

type CallRequest = Parameters<typeof sharePlay.run>[0];
const call = async (uid: string, data: object, superAdmin = false) => {
  const req = { data, auth: { uid, token: superAdmin ? { superAdmin: true } : {} }, rawRequest: {} } as unknown as CallRequest;
  return (await sharePlay.run(req)) as { shareId: string | null };
};
const share = (uid: string, image: Buffer | null = PNG) =>
  call(uid, { playId: 'p1', action: 'share', image: image?.toString('base64') ?? null });
const playDoc = () => db().collection(Collections.plays).doc('p1');
const copyOf = (id: string) => db().collection(Collections.sharedPlays).doc(id).get();
const imageExists = async (id: string) => (await storage().bucket().file(shareImagePath(id)).exists())[0];

const play = {
  groupId: G,
  board: 'baseball',
  variant: 'full',
  title: 'Bunt defense',
  note: 'Corners crash.',
  steps: [
    {
      elements: [
        { k: 'm', id: 'a', x: 0.5, y: 0.5, s: 'team', l: 'Emma R.', p: 'emma' },
        { k: 'm', id: 'b', x: 0.2, y: 0.5, s: 'team', l: 'SS' },
        { k: 'a', id: 'c', t: 'run', pts: [0.2, 0.5, 0.4, 0.4] },
      ],
    },
  ],
  createdBy: 'coach',
};

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
  await storage().bucket().deleteFiles({ prefix: `${Collections.sharedPlays}/` });
  await db().collection(Collections.groups).doc(G).set({ name: 'Thunder', kind: 'team', status: 'active' });
  for (const [uid, role] of [['coach', 'owner'], ['pat', 'member']]) {
    await db().collection(Collections.groupMembers).doc(groupMemberId(G, uid!)).set({ groupId: G, uid, role });
  }
  await playDoc().set(play);
});

describe('sharePlay', () => {
  it("copies the drawing, without the team or a roster player's name, "
    + 'with its picture, under one link', async () => {
    const { shareId } = await share('coach');
    expect(shareId).toMatch(/^[A-Za-z0-9_-]{12}$/);
    expect((await playDoc().get()).get('shareId')).toBe(shareId);
    const copy = (await copyOf(shareId!)).data()!;
    expect(copy.groupId).toBeUndefined();
    expect(copy.createdBy).toBeUndefined();
    expect(copy).toMatchObject({ board: 'baseball', variant: 'full', title: 'Bunt defense', note: 'Corners crash.', hasImage: true });
    expect(copy.steps[0].elements).toEqual([
      { k: 'm', id: 'a', x: 0.5, y: 0.5, s: 'team' },
      { k: 'm', id: 'b', x: 0.2, y: 0.5, s: 'team', l: 'SS' },
      { k: 'a', id: 'c', t: 'run', pts: [0.2, 0.5, 0.4, 0.4] },
    ]);
    expect(await imageExists(shareId!)).toBe(true);

    // Shared again: the same link, brought up to date.
    await playDoc().update({ title: 'Squeeze' });
    expect((await share('coach')).shareId).toBe(shareId);
    expect((await copyOf(shareId!)).get('title')).toBe('Squeeze');
    // Without a picture, the old one goes.
    await share('coach', null);
    expect(await imageExists(shareId!)).toBe(false);
    expect((await copyOf(shareId!)).get('hasImage')).toBe(false);
  });

  it("is for the team's admins and super admins, on an open team", async () => {
    await expect(share('pat')).rejects.toThrow('Team admins only.');
    await expect(share('stranger')).rejects.toThrow('Team admins only.');
    expect((await call('root', { playId: 'p1', action: 'share' }, true)).shareId).toBeTruthy();
    await db().collection(Collections.groups).doc(G).update({ archivedAt: new Date() });
    await expect(share('coach')).rejects.toThrow('team-archived');
    await expect(call('coach', { playId: 'nope', action: 'share' })).rejects.toThrow('No such play.');
    await expect(call('coach', { playId: 'p1', action: 'share', image: 'R0lGODlh' })).rejects.toThrow('bad-image');
  });

  it('stops sharing: the link goes, with its picture', async () => {
    const { shareId } = await share('coach');
    await expect(call('pat', { playId: 'p1', action: 'stop' })).rejects.toThrow('Team admins only.');
    expect((await call('coach', { playId: 'p1', action: 'stop' })).shareId).toBeNull();
    expect((await copyOf(shareId!)).exists).toBe(false);
    expect(await imageExists(shareId!)).toBe(false);
    expect((await playDoc().get()).get('shareId')).toBeUndefined();
    // Also on an archived team.
    const again = (await share('coach')).shareId!;
    await db().collection(Collections.groups).doc(G).update({ archivedAt: new Date() });
    await call('coach', { playId: 'p1', action: 'stop' });
    expect((await copyOf(again)).exists).toBe(false);
    await db().collection(Collections.groups).doc(G).update({ archivedAt: null });
    // Stopping again is fine; sharing again is a new link.
    await call('coach', { playId: 'p1', action: 'stop' });
    expect((await share('coach')).shareId).not.toBe(shareId);
  });

  it("serves a picture only while it's the share's", async () => {
    const { shareId } = await share('coach');
    // A picture left behind with no share (a stop that raced the upload).
    await db().collection(Collections.sharedPlays).doc(shareId!).delete();
    expect(await sharedPlayImage(shareId!)).toBeNull();
  });
});

describe('the play changing or going', () => {
  it('copies a change over and drops the picture, now out of date', async () => {
    const { shareId } = await share('coach');
    const before = (await playDoc().get()).data();
    await playDoc().update({ note: 'Wheel play.' });
    await followPlayChange('p1', before, (await playDoc().get()).data());
    const copy = await copyOf(shareId!);
    expect(copy.get('note')).toBe('Wheel play.');
    expect(copy.get('hasImage')).toBe(false);
    expect(await imageExists(shareId!)).toBe(false);
  });

  it("leaves the copy alone when nothing it holds changed, or it's already "
    + 'up to date', async () => {
    const { shareId } = await share('coach');
    const before = (await playDoc().get()).data();
    await followPlayChange('p1', before, { ...before, updatedAt: new Date() });
    expect(await imageExists(shareId!)).toBe(true);
    // Shared again right after a change: the trigger finds it done.
    await playDoc().update({ title: 'Squeeze' });
    await share('coach');
    await followPlayChange('p1', before, (await playDoc().get()).data());
    expect(await imageExists(shareId!)).toBe(true);
  });

  it('a late event for an older version leaves the newer copy', async () => {
    const { shareId } = await share('coach');
    const first = (await playDoc().get()).data();
    await playDoc().update({ title: 'Squeeze' });
    const second = (await playDoc().get()).data();
    await playDoc().update({ title: 'Wheel' });
    await followPlayChange('p1', second, (await playDoc().get()).data());
    // The Squeeze event arrives last.
    await followPlayChange('p1', first, second);
    expect((await copyOf(shareId!)).get('title')).toBe('Wheel');
  });

  it("deleting the play takes its link down; a play that isn't shared is "
    + 'left alone', async () => {
    const { shareId } = await share('coach');
    const before = (await playDoc().get()).data();
    await playDoc().delete();
    await followPlayChange('p1', before, undefined);
    expect((await copyOf(shareId!)).exists).toBe(false);
    expect(await imageExists(shareId!)).toBe(false);
    await followPlayChange('p1', play, undefined);
  });
});

describe("the link's page", () => {
  const reply = async (path: string, userAgent = 'Mozilla/5.0 (iPhone)', method = 'GET') => {
    const out: { status: number; headers: Record<string, string>; body: unknown; location?: string } = {
      status: 200,
      headers: {},
      body: '',
    };
    const res = {
      status(code: number) {
        out.status = code;
        return res;
      },
      set(name: string, value: string) {
        out.headers[name.toLowerCase()] = value;
        return res;
      },
      type(value: string) {
        out.headers['content-type'] = value;
        return res;
      },
      send(body: unknown) {
        out.body = body;
        return res;
      },
      redirect(code: number, location: string) {
        out.status = code;
        out.location = location;
      },
    };
    const req = { method, path, originalUrl: path, get: (h: string) => (h.toLowerCase() === 'user-agent' ? userAgent : undefined) };
    await (playPage as unknown as (req: object, res: object) => Promise<void>)(req, res);
    return out;
  };

  it('sends people on to the app, and gives previews the play', async () => {
    const { shareId } = await share('coach');
    const person = await reply(`/p/${shareId}`);
    expect(person.status).toBe(302);
    expect(person.location).toBe(`/app/p/${shareId}`);

    const preview = await reply(`/p/${shareId}`, 'facebookexternalhit/1.1');
    expect(preview.status).toBe(200);
    expect(preview.body).toContain('<title>Bunt defense · a play on Battleplan</title>');
    expect(preview.body).toContain(`/p/${shareId}/image.png`);
    expect(preview.body).not.toContain('Thunder');
    expect(preview.headers['x-robots-tag']).toBe('noindex');

    const image = await reply(`/p/${shareId}/image.png`, 'facebookexternalhit/1.1');
    expect(image.status).toBe(200);
    expect(image.headers['content-type']).toBe('image/png');
    expect(Buffer.compare(image.body as Buffer, PNG)).toBe(0);
  });

  it("is Battleplan's own for a link that doesn't work", async () => {
    const preview = await reply('/p/Zz3_x-9Kq2Zw', 'Slackbot-LinkExpanding 1.0');
    expect(preview.body).toContain('<title>A play on Battleplan</title>');
    expect(preview.body).toContain('images/og.png');
    expect((await reply('/p/Zz3_x-9Kq2Zw/image.png')).status).toBe(404);
    expect((await reply('/p/short/image.png')).status).toBe(404);
  });
});
