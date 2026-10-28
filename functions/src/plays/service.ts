// Shared plays (SPEC BOARD-6, ARCH §6.14): a public copy of a team's play
// that anyone with the link can see. The copy holds only the drawing: no
// team, no one's name, and no roster player behind a marker's label.
import { randomBytes } from 'node:crypto';
import { FieldValue, type DocumentData } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { db, storage } from '../shared/admin.js';
import { Collections, Limits } from '../shared/constants.js';
import { consumeRateLimit } from '../shared/rate_limit.js';
import { requireTeamAdmin } from '../shared/roles.js';

/** A share's ID: 12 URL-safe characters, unguessable. */
export function newShareId(): string {
  return randomBytes(9).toString('base64url');
}

/** Whether [id] could be a share's ID, before it's looked up. */
export function isShareId(id: string): boolean {
  return /^[A-Za-z0-9_-]{12}$/.test(id);
}

/** Where a share's picture is kept in Storage. */
export function shareImagePath(shareId: string): string {
  return `${Collections.sharedPlays}/${shareId}.png`;
}

type Raw = Record<string, unknown>;
const isMap = (v: unknown): v is Raw => typeof v === 'object' && v !== null && !Array.isArray(v);
const num = (v: unknown) => (typeof v === 'number' && Number.isFinite(v) ? v : 0);
const str = (v: unknown, max: number) => (typeof v === 'string' ? v.slice(0, max) : '');
const points = (v: unknown) => (Array.isArray(v) ? v.slice(0, 2000).map(num) : []);

/**
 * One element as the public copy keeps it: each kind's own fields only
 * (ARCH §6.14). A marker labeled with a roster player (`p`) loses the
 * label too, since it's the player's name; null for an unknown kind.
 */
export function publicElement(e: unknown): DocumentData | null {
  if (!isMap(e)) return null;
  const id = str(e.id, 40);
  switch (e.k) {
    case 'm': {
      const label = e.p == null ? str(e.l, 40) : '';
      return { k: 'm', id, x: num(e.x), y: num(e.y), s: str(e.s, 10), ...(label ? { l: label } : {}) };
    }
    case 'a':
      return { k: 'a', id, t: str(e.t, 10), pts: points(e.pts) };
    case 'l':
      return { k: 'l', id, pts: points(e.pts) };
    case 'n':
      return { k: 'n', id, x: num(e.x), y: num(e.y), text: str(e.text, 200) };
    default:
      return null;
  }
}

/** A play's steps as the public copy keeps them. */
export function publicSteps(steps: unknown): DocumentData[] {
  const list = Array.isArray(steps) ? steps.slice(0, Limits.playStepsMax) : [];
  return list.map((s) => ({
    elements: (isMap(s) && Array.isArray(s.elements) ? s.elements.slice(0, Limits.playElementsMax) : [])
      .map(publicElement)
      .filter((e): e is DocumentData => e !== null),
  }));
}

/** The shared copy of [play]: the drawing, its name, and its note. */
export function publicPlay(play: DocumentData): DocumentData {
  return {
    board: str(play.board, 20),
    variant: str(play.variant, 10),
    title: str(play.title, Limits.playTitleMax),
    note: str(play.note, Limits.playNoteMax),
    steps: publicSteps(play.steps),
  };
}

/** The picture a share sends, if it's a PNG within the limit; else `invalid-argument`. */
export function imageOf(base64: string | null | undefined): Buffer | null {
  if (!base64) return null;
  const bytes = Buffer.from(base64, 'base64');
  const png = bytes.length > 8 && bytes.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]));
  if (!png || bytes.length > Limits.sharedPlayImageBytesMax) {
    throw new HttpsError('invalid-argument', 'bad-image');
  }
  return bytes;
}

/**
 * Shares a play by its team's admin (or a super admin), on an open team:
 * the public copy is made, or brought up to date with the play under the
 * same link, with [image], a picture of its last step, for link previews.
 * Returns the share's ID, which is also kept on the play.
 */
export async function sharePlay(
  uid: string,
  superAdmin: boolean,
  playId: string,
  image: Buffer | null,
): Promise<string> {
  const playRef = db().collection(Collections.plays).doc(playId);
  const play = await playRef.get();
  if (!play.exists) throw new HttpsError('not-found', 'No such play.');
  await requireTeamAdmin(play.get('groupId') as string, uid, superAdmin);
  await consumeRateLimit(uid, 'playShare', Limits.playSharesPerUserPerHour, 'hour');

  const shareId = await db().runTransaction(async (tx) => {
    const now = await tx.get(playRef);
    if (!now.exists) throw new HttpsError('not-found', 'No such play.');
    const existing = now.get('shareId') as string | undefined;
    const id = existing ?? newShareId();
    const shareRef = db().collection(Collections.sharedPlays).doc(id);
    tx.set(
      shareRef,
      {
        ...publicPlay(now.data() ?? {}),
        hasImage: image !== null,
        updatedAt: FieldValue.serverTimestamp(),
        ...(existing ? {} : { sharedAt: FieldValue.serverTimestamp() }),
      },
      { merge: true },
    );
    if (!existing) tx.update(playRef, { shareId: id });
    return id;
  });
  const file = storage().bucket().file(shareImagePath(shareId));
  if (image) {
    await file.save(image, { contentType: 'image/png', resumable: false });
    // Stopped or deleted while the picture went up: it goes too.
    if (!(await db().collection(Collections.sharedPlays).doc(shareId).get()).exists) {
      await file.delete({ ignoreNotFound: true });
    }
  } else {
    await file.delete({ ignoreNotFound: true });
  }
  return shareId;
}

/**
 * Stops sharing a play: its link stops working. Also on an archived team,
 * so a link can always be taken down.
 */
export async function stopSharingPlay(uid: string, superAdmin: boolean, playId: string): Promise<void> {
  const playRef = db().collection(Collections.plays).doc(playId);
  const play = await playRef.get();
  if (!play.exists) throw new HttpsError('not-found', 'No such play.');
  await requireTeamAdmin(play.get('groupId') as string, uid, superAdmin, { allowArchived: true });
  const shareId = play.get('shareId') as string | undefined;
  if (!shareId) return;
  await playRef.update({ shareId: FieldValue.delete() });
  await deleteShare(shareId);
}

/** Deletes a share and its picture: when it's stopped, or its play is deleted. */
export async function deleteShare(shareId: string): Promise<void> {
  await db().collection(Collections.sharedPlays).doc(shareId).delete();
  await storage().bucket().file(shareImagePath(shareId)).delete({ ignoreNotFound: true });
}

/** A share, as its page needs it; null if there's no such share. */
export async function sharedPlayOf(shareId: string): Promise<DocumentData | null> {
  if (!isShareId(shareId)) return null;
  const snap = await db().collection(Collections.sharedPlays).doc(shareId).get();
  return snap.exists ? (snap.data() ?? null) : null;
}

/** A share's picture, or null if it has none or isn't shared anymore. */
export async function sharedPlayImage(shareId: string): Promise<Buffer | null> {
  if (!isShareId(shareId)) return null;
  const share = await db().collection(Collections.sharedPlays).doc(shareId).get();
  if (share.get('hasImage') !== true) return null;
  try {
    const [bytes] = await storage().bucket().file(shareImagePath(shareId)).download();
    return bytes;
  } catch {
    return null;
  }
}

/**
 * A play changed or was deleted: its share follows (ARCH §6.4 trigger map).
 * Deleting the play takes the link down; a change to the drawing, name, or
 * note is copied over, and the picture, now out of date, is dropped until
 * the play is shared again. It reads the play as it is now rather than the
 * event's copy, so events arriving late or retried can't undo newer ones.
 */
export async function followPlayChange(
  playId: string,
  before: DocumentData | undefined,
  after: DocumentData | undefined,
): Promise<void> {
  const shareId = (before?.shareId ?? after?.shareId) as string | undefined;
  if (!shareId) return;
  const play = await db().collection(Collections.plays).doc(playId).get();
  if (!play.exists) {
    await deleteShare(shareId);
    return;
  }
  // Sharing stopped (stopSharingPlay deletes the share itself).
  if (play.get('shareId') !== shareId) return;
  // Already the same: unchanged, or shared again since (with a new picture).
  const shareRef = db().collection(Collections.sharedPlays).doc(shareId);
  const shared = await shareRef.get();
  if (!shared.exists) return;
  const now = publicPlay(play.data() ?? {});
  if (JSON.stringify(publicPlay(shared.data() ?? {})) === JSON.stringify(now)) return;
  await shareRef.update({ ...now, hasImage: false, updatedAt: FieldValue.serverTimestamp() });
  await storage().bucket().file(shareImagePath(shareId)).delete({ ignoreNotFound: true });
}
