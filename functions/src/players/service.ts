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
  user: { uid: string; displayName: string; photoPath: string | null },
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
