// Players domain service: owns players, playerGuardians, guardianRequests.
import { FieldValue } from 'firebase-admin/firestore';
import { findOrProvisionUser } from '../accounts/service.js';
import { db } from '../shared/admin.js';
import { Collections } from '../shared/constants.js';
import { forEachPage } from '../shared/batch.js';
import { compositeId, groupMemberId } from '../shared/ids.js';
import { playerLabel, type PlayerInput } from './roster.js';

/** A deleted account stops being a guardian; its players stay (AUTH-10). */
export async function removeAccountFromPlayers(uid: string): Promise<void> {
  for (const collection of [Collections.playerGuardians, Collections.guardianRequests]) {
    await forEachPage(db().collection(collection).where('uid', '==', uid), (b, d) => b.delete(d.ref));
  }
}

export interface AddPlayersResult {
  playersAdded: number;
  guardiansLinked: number;
  guardiansInvited: number;
  /** Emails of guardians who got a new added account (for setup emails). */
  invitedEmails: string[];
  problems: string[];
}

/**
 * Adds players to a youth team with up to 4 guardians each (PLAYER-1).
 * Guardians with accounts are linked now; new emails get an added account
 * (AUTH-6). Every guardian becomes a team member.
 */
export async function addPlayers(groupId: string, actorUid: string, players: PlayerInput[]): Promise<AddPlayersResult> {
  const result: AddPlayersResult = { playersAdded: 0, guardiansLinked: 0, guardiansInvited: 0, invitedEmails: [], problems: [] };
  const touchedGuardians = new Set<string>();
  for (const input of players) {
    const playerRef = db().collection(Collections.players).doc();
    const name = input.name.trim().slice(0, 60);
    await playerRef.set({
      groupId,
      displayName: name,
      displayNameLower: name.toLowerCase(),
      jerseyNumber: input.jerseyNumber?.trim() || null,
      position: input.position?.trim() || null,
      createdBy: actorUid,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    result.playersAdded++;
    for (const g of input.guardians) {
      if (!g.email) continue; // a name alone can't be linked
      try {
        const user = await findOrProvisionUser(g.email, g.name ?? null);
        await linkGuardian(groupId, playerRef.id, user, actorUid, 'admin');
        touchedGuardians.add(user.uid);
        if (user.provisioned) {
          result.guardiansInvited++;
          result.invitedEmails.push(g.email.trim().toLowerCase());
        } else {
          result.guardiansLinked++;
        }
      } catch {
        result.problems.push(`${name}: ${g.email}`);
      }
    }
  }
  for (const uid of touchedGuardians) await refreshPlayerSummary(groupId, uid);
  await refreshPlayerCount(groupId);
  return result;
}

/** Links a guardian to a player and makes them a team member if needed. */
export async function linkGuardian(
  groupId: string,
  playerId: string,
  user: { uid: string; displayName: string; photoPath: string | null; provisioned?: boolean },
  addedBy: string,
  via: 'admin' | 'request' | 'guardian' | 'self',
): Promise<void> {
  const now = FieldValue.serverTimestamp();
  const memberRef = db().collection(Collections.groupMembers).doc(groupMemberId(groupId, user.uid));
  await db().runTransaction(async (tx) => {
    const member = await tx.get(memberRef);
    tx.set(db().collection(Collections.playerGuardians).doc(compositeId(playerId, user.uid)), {
      playerId,
      groupId,
      uid: user.uid,
      addedBy,
      via,
      createdAt: now,
    });
    if (!member.exists) {
      tx.set(memberRef, {
        groupId,
        uid: user.uid,
        role: 'member',
        title: null,
        displayName: user.displayName,
        photoPath: user.photoPath,
        playerSummary: null,
        notificationLevel: 'all',
        mutedUntil: null,
        lastReadAt: now,
        lastPostedAt: null,
        joinedAt: now,
        addedBy,
        pending: user.provisioned === true,
      });
    }
  });
  const count = await db().collection(Collections.groupMembers).where('groupId', '==', groupId).count().get();
  await db().collection(Collections.groups).doc(groupId).update({ memberCount: count.data().count });
}

/** Rewrites a guardian's "Emma #7, Liam #23" label on their membership (PLAYER-8). */
export async function refreshPlayerSummary(groupId: string, uid: string): Promise<void> {
  const links = await db()
    .collection(Collections.playerGuardians)
    .where('groupId', '==', groupId)
    .where('uid', '==', uid)
    .limit(20)
    .get();
  const labels: string[] = [];
  for (const link of links.docs) {
    const player = await db().collection(Collections.players).doc(link.get('playerId') as string).get();
    if (player.exists) labels.push(playerLabel(player.get('displayName') as string, player.get('jerseyNumber') as string | null));
  }
  await db()
    .collection(Collections.groupMembers)
    .doc(groupMemberId(groupId, uid))
    .update({ playerSummary: labels.length ? labels.sort().join(', ') : null })
    .catch(() => undefined);
}

/** Recomputes groups.playerCount (D12). */
export async function refreshPlayerCount(groupId: string): Promise<void> {
  const count = await db().collection(Collections.players).where('groupId', '==', groupId).count().get();
  await db().collection(Collections.groups).doc(groupId).update({ playerCount: count.data().count });
}

/** Removes a player, their guardian links and requests (PLAYER-2). */
export async function removePlayer(groupId: string, playerId: string): Promise<void> {
  const links = await db().collection(Collections.playerGuardians).where('playerId', '==', playerId).limit(20).get();
  const guardians = links.docs.map((d) => d.get('uid') as string);
  for (const collection of [Collections.playerGuardians, Collections.guardianRequests]) {
    await forEachPage(db().collection(collection).where('playerId', '==', playerId), (b, d) => b.delete(d.ref));
  }
  await db().collection(Collections.players).doc(playerId).delete();
  for (const uid of guardians) await refreshPlayerSummary(groupId, uid);
  await refreshPlayerCount(groupId);
}

/** Whether [uid] is already a guardian of [playerId]. */
export async function isGuardian(playerId: string, uid: string): Promise<boolean> {
  const link = await db().collection(Collections.playerGuardians).doc(compositeId(playerId, uid)).get();
  return link.exists;
}

/**
 * Asks the team's admins to link [uid] to each player (PLAYER-3, Q15).
 * Players they already guard are skipped; a declined request can be sent
 * again. Returns how many requests are now pending.
 */
export async function requestGuardianLinks(groupId: string, uid: string, playerIds: string[]): Promise<number> {
  let requested = 0;
  for (const playerId of new Set(playerIds)) {
    const player = await db().collection(Collections.players).doc(playerId).get();
    if (!player.exists || player.get('groupId') !== groupId) continue;
    if (await isGuardian(playerId, uid)) continue;
    await db()
      .collection(Collections.guardianRequests)
      .doc(compositeId(playerId, uid))
      .set({
        playerId,
        groupId,
        uid,
        status: 'pending',
        decidedBy: null,
        decidedAt: null,
        createdAt: FieldValue.serverTimestamp(),
      });
    requested++;
  }
  return requested;
}

/**
 * An admin approves or declines a guardian request (PLAYER-4). Approving
 * links the guardian; either way the request records who decided.
 */
export async function resolveGuardianRequest(
  groupId: string,
  playerId: string,
  uid: string,
  approve: boolean,
  actorUid: string,
): Promise<boolean> {
  const ref = db().collection(Collections.guardianRequests).doc(compositeId(playerId, uid));
  const request = await ref.get();
  if (!request.exists || request.get('groupId') !== groupId || request.get('status') !== 'pending') return false;
  if (approve) {
    const profile = await db().collection(Collections.users).doc(uid).get();
    await linkGuardian(
      groupId,
      playerId,
      {
        uid,
        displayName: (profile.get('displayName') as string | undefined) ?? 'Guardian',
        photoPath: (profile.get('photoPath') as string | null | undefined) ?? null,
      },
      actorUid,
      'request',
    );
    await refreshPlayerSummary(groupId, uid);
  }
  await ref.update({
    status: approve ? 'approved' : 'declined',
    decidedBy: actorUid,
    decidedAt: FieldValue.serverTimestamp(),
  });
  return true;
}

/**
 * A parent adds their own player who isn't on the roster (PLAYER-3). The
 * parent becomes the guardian; admins can edit or remove it.
 */
export async function addMyPlayer(
  groupId: string,
  uid: string,
  input: { name: string; jerseyNumber?: string | null },
): Promise<string> {
  const profile = await db().collection(Collections.users).doc(uid).get();
  const ref = db().collection(Collections.players).doc();
  const name = input.name.trim().slice(0, 60);
  await ref.set({
    groupId,
    displayName: name,
    displayNameLower: name.toLowerCase(),
    jerseyNumber: input.jerseyNumber?.trim() || null,
    position: null,
    createdBy: uid,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await linkGuardian(
    groupId,
    ref.id,
    {
      uid,
      displayName: (profile.get('displayName') as string | undefined) ?? 'Guardian',
      photoPath: (profile.get('photoPath') as string | null | undefined) ?? null,
    },
    uid,
    'self',
  );
  await refreshPlayerSummary(groupId, uid);
  await refreshPlayerCount(groupId);
  return ref.id;
}

/** How many guardians a player has. */
export async function guardianCount(playerId: string): Promise<number> {
  const count = await db().collection(Collections.playerGuardians).where('playerId', '==', playerId).count().get();
  return count.data().count;
}

/**
 * Removes one guardian from a player (PLAYER-2). They stay on the team; only
 * the link and its label go.
 */
export async function removeGuardianLink(groupId: string, playerId: string, uid: string): Promise<void> {
  await db().collection(Collections.playerGuardians).doc(compositeId(playerId, uid)).delete();
  await db().collection(Collections.guardianRequests).doc(compositeId(playerId, uid)).delete();
  await refreshPlayerSummary(groupId, uid);
}
