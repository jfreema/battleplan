// Starting a new season from a team (TEAM-16): a new team with the old
// one's logo, color, sport, settings, chat look, and default reminders, the
// people its owner brings along already on it (players with their links, so
// parents keep answering for their kids), and, when asked, its documents and
// saved plays. The caller then archives the old team (TEAM-9), keeping its
// chat, photos, schedule, and results. Every document the copy writes is
// named from the new team's ID, so a retry of an attempt that stopped partway
// writes the same documents again and finishes it.
import { createHash } from 'node:crypto';
import { FieldValue, type DocumentData, type DocumentReference, type WriteBatch } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { chunk } from '../notify/service.js';
import { playerStatusOf, playerSummaryOf, relationOf } from '../players/roster.js';
import { refreshPlayerCount } from '../players/service.js';
import { db, storage } from '../shared/admin.js';
import { Collections, Limits } from '../shared/constants.js';
import { compositeId, groupMemberId } from '../shared/ids.js';
import { teamCountOf } from '../shared/roles.js';
import { DEFAULT_SETTINGS, refreshMemberCount } from './service.js';
import { maxUploadBytes } from './storage.js';

/** Who and what the owner brings to the new season (TEAM-16). */
export interface SeasonChoices {
  /** The players, with their links, and so the members linked to them. */
  players: boolean;
  /** The admins and coaches. */
  staff: boolean;
  /** Everyone else. */
  members: boolean;
  documents: boolean;
  plays: boolean;
}

/** What a member is on the new team: their role, Coach, and title. */
export interface SeasonPlace {
  role: 'owner' | 'admin' | 'member';
  coach: boolean | null;
  title: string | null;
}

/**
 * Whether a member of the old team comes along, and as what (TEAM-16). The
 * owner always does, as the owner. Admins and coaches come with
 * [choices.staff], keeping their role, Coach, and title; members linked to a
 * player come with [choices.players], so a coach who's also a parent comes
 * as a parent when the staff stay behind; everyone else comes with
 * [choices.members]. Null leaves them out. The app's seasonGroupOf sorts
 * people the same way for its counts.
 */
export function seasonPlaceOf(
  member: { role?: unknown; coach?: unknown; title?: unknown },
  linked: boolean,
  choices: Pick<SeasonChoices, 'players' | 'staff' | 'members'>,
): SeasonPlace | null {
  const title = typeof member.title === 'string' ? member.title : null;
  const coach = typeof member.coach === 'boolean' ? member.coach : null;
  if (member.role === 'owner') return { role: 'owner', coach, title };
  const staff = member.role === 'admin' || coach === true;
  if (staff && choices.staff) return { role: member.role === 'admin' ? 'admin' : 'member', coach, title };
  if (linked && choices.players) return { role: 'member', coach: null, title: staff ? null : title };
  if (!staff && !linked && choices.members) return { role: 'member', coach, title };
  return null;
}

/**
 * The ID of the new season's copy of an old team's document: the same for
 * every attempt of one season, so a retry overwrites what an earlier one
 * wrote. Twenty hex characters, with no `_` for composite IDs.
 */
export function seasonCopyId(newGroupId: string, oldId: string): string {
  return createHash('sha256').update(`${newGroupId}:${oldId}`).digest('hex').slice(0, 20);
}

/**
 * Where a file in the old team's folder goes in the new team's: the same
 * name under `groups/{newGroupId}/`. A path outside the old team's folder
 * isn't the team's own file, so it's kept as it is.
 */
export function seasonFilePath(path: string, oldGroupId: string, newGroupId: string): string {
  const prefix = `groups/${oldGroupId}/`;
  return path.startsWith(prefix) ? `groups/${newGroupId}/${path.slice(prefix.length)}` : path;
}

/** Firestore writes in batches of 400 (a batch takes 500 at most). */
class Writes {
  private batch: WriteBatch = db().batch();
  private size = 0;

  async set(ref: DocumentReference, data: DocumentData): Promise<void> {
    this.batch.set(ref, data);
    if (++this.size === 400) await this.commit();
  }

  async commit(): Promise<void> {
    if (this.size === 0) return;
    await this.batch.commit();
    this.batch = db().batch();
    this.size = 0;
  }
}

/**
 * Copies a team file within the bucket. The Storage trigger counts the copy
 * toward the new team (onGroupFileAdded). False when the file is gone, or
 * larger than platform settings now allow (ADMIN-7), which that trigger
 * would delete. A file already in its place is copied over, so a retry
 * changes nothing.
 */
async function copyFile(from: string, to: string, maxBytes: number): Promise<boolean> {
  if (from === to) return true;
  const file = storage().bucket().file(from);
  try {
    const [meta] = await file.getMetadata();
    if (Number(meta.size ?? 0) > maxBytes) return false;
    await file.copy(storage().bucket().file(to));
    return true;
  } catch (e) {
    if ((e as { code?: number }).code === 404) return false;
    throw e;
  }
}

/** A new season's team, and who it brought along (TEAM-16). */
export interface SeasonCopy {
  /** Everyone on the new team, the owner included. */
  uids: string[];
  players: number;
  documents: number;
  plays: number;
  /** People who'd have come along but are on 100 teams already (TEAM-2). */
  leftOut: string[];
}

/**
 * Makes team [newGroupId] the next season of [oldGroupId] (TEAM-16), owned
 * by [uid] and named [name]: the old team's profile, settings, and chat
 * look; the members [choices] bring, with their notification levels and
 * what they share (TEAM-10); its active players with their details
 * (PLAYER-12) and the links of the members who came; and, when asked, its
 * documents and plays. Callers check the owner may and archive the old team
 * after. Writes the team only when it's new, so a retry keeps what happened
 * on it since; everything else is written again.
 */
export async function copyTeamForSeason(
  oldGroupId: string,
  newGroupId: string,
  uid: string,
  name: string,
  choices: SeasonChoices,
  defaultQuotaMb: number,
): Promise<SeasonCopy> {
  const groups = db().collection(Collections.groups);
  const old = (await groups.doc(oldGroupId).get()).data() ?? {};
  const newRef = groups.doc(newGroupId);
  const made = await newRef.get();
  const hasPlayers = (old.kind ?? 'team') === 'team';
  const byTeam = (collection: string) => db().collection(collection).where('groupId', '==', oldGroupId);

  // Who comes along: the links say who's here for a player, so a parent
  // stays behind with the players. Links come only for members who came.
  const [members, players, links] = await Promise.all([
    byTeam(Collections.groupMembers).get(),
    hasPlayers ? byTeam(Collections.players).get() : null,
    hasPlayers ? byTeam(Collections.playerGuardians).get() : null,
  ]);
  const activePlayers = (players?.docs ?? []).filter((p) => playerStatusOf(p.data()) === 'active');
  const activeIds = new Set(activePlayers.map((p) => p.id));
  const activeLinks = (links?.docs ?? []).filter((l) => activeIds.has(String(l.get('playerId'))));
  const linked = new Set(activeLinks.map((l) => String(l.get('uid'))));
  const comingPlayers = choices.players ? activePlayers : [];
  const playerById = new Map(comingPlayers.map((p) => [p.id, p]));
  const placed = members.docs
    .map((m) => ({ doc: m, place: seasonPlaceOf(m.data(), linked.has(String(m.get('uid'))), choices) }))
    .filter((m): m is { doc: FirebaseFirestore.QueryDocumentSnapshot; place: SeasonPlace } => m.place !== null);

  // A person can be on 100 teams (TEAM-2); the handler checked the owner.
  // Someone already on the new team (from an earlier attempt) has room.
  const already = made.exists
    ? new Set((await db().collection(Collections.groupMembers).where('groupId', '==', newGroupId).select().get()).docs.map((d) => d.id))
    : new Set<string>();
  const leftOut: string[] = [];
  const coming: typeof placed = [];
  for (const part of chunk(placed, 10)) {
    const full = await Promise.all(
      part.map(async ({ doc, place }) => {
        const who = String(doc.get('uid'));
        if (place.role === 'owner' || already.has(groupMemberId(newGroupId, who))) return false;
        return (await teamCountOf(who)) >= Limits.groupsPerUserMax;
      }),
    );
    part.forEach((m, i) => (full[i] ? leftOut.push(String(m.doc.get('uid'))) : coming.push(m)));
  }
  const uids = new Set(coming.map((m) => String(m.doc.get('uid'))));
  const keptLinks = activeLinks.filter((l) => playerById.has(String(l.get('playerId'))) && uids.has(String(l.get('uid'))));

  // The logo and the chat background, copied into the new team's folder.
  const maxBytes = await maxUploadBytes();
  // A logo that won't copy is left off rather than failing the season:
  // a retry finds the team made and doesn't copy it again.
  const copied = async (path: unknown): Promise<string | null> => {
    if (typeof path !== 'string' || !path) return null;
    const to = seasonFilePath(path, oldGroupId, newGroupId);
    try {
      return (await copyFile(path, to, maxBytes)) ? to : null;
    } catch (e) {
      logger.warn('season_file_copy_failed', { path, error: String(e) });
      return null;
    }
  };
  const now = FieldValue.serverTimestamp();
  if (!made.exists) {
    const custom = old.storageQuotaCustom === true && typeof old.storageQuotaBytes === 'number';
    const theme = old.chatTheme as { bubbleColor?: unknown; background?: unknown; backgroundPath?: unknown } | undefined;
    const trimmed = name.trim();
    // The team first: the Storage trigger counts copied files toward it.
    await newRef.create({
      name: trimmed,
      nameLower: trimmed.toLowerCase(),
      description: typeof old.description === 'string' ? old.description : '',
      photoPath: null,
      color: old.color ?? null,
      sport: old.sport ?? 'other',
      kind: old.kind ?? 'team',
      ownerId: uid,
      createdBy: uid,
      timeZone: old.timeZone ?? 'America/Chicago',
      // The settings the rules know (TEAM-5), the default reminders among
      // them; one the team never set takes the default.
      settings: Object.fromEntries(
        Object.entries(DEFAULT_SETTINGS).map(([key, value]) => [key, (old.settings as DocumentData | undefined)?.[key] ?? value]),
      ),
      ...(theme ? { chatTheme: { ...theme, backgroundPath: null } } : {}),
      memberCount: uids.size,
      playerCount: comingPlayers.length,
      lastMessageAt: null,
      lastMessagePreview: null,
      storageBytes: 0,
      // A limit a super admin gave the team (STORE-6) carries on.
      storageQuotaBytes: custom ? old.storageQuotaBytes : defaultQuotaMb * 1024 * 1024,
      ...(custom ? { storageQuotaCustom: true } : {}),
      storageAlert: 'none',
      archivedAt: null,
      suspendedAt: null,
      status: 'active',
      previousSeasonId: oldGroupId,
      createdAt: now,
      updatedAt: now,
      schemaVersion: 1,
    });
    const [photoPath, backgroundPath] = await Promise.all([copied(old.photoPath), copied(theme?.backgroundPath)]);
    if (photoPath || backgroundPath || theme?.background === 'photo') {
      await newRef.update({
        photoPath,
        ...(theme
          ? {
              'chatTheme.backgroundPath': backgroundPath,
              // A photo background with no photo left shows plain.
              ...(theme.background === 'photo' && !backgroundPath ? { 'chatTheme.background': 'plain' } : {}),
            }
          : {}),
      });
    }
  }

  // The people, players, details, and links.
  const writes = new Writes();
  const newPlayerId = (oldPlayerId: string) => seasonCopyId(newGroupId, oldPlayerId);
  const summaries = new Map<string, Parameters<typeof playerSummaryOf>[0]>();
  for (const link of keptLinks) {
    const player = playerById.get(String(link.get('playerId')))!;
    const who = String(link.get('uid'));
    summaries.set(who, [
      ...(summaries.get(who) ?? []),
      {
        relation: relationOf(link.data()),
        name: String(player.get('displayName') ?? ''),
        jerseyNumber: (player.get('jerseyNumber') as string | null | undefined) ?? null,
      },
    ]);
  }
  for (const { doc, place } of coming) {
    const m = doc.data();
    const who = String(m.uid);
    await writes.set(db().collection(Collections.groupMembers).doc(groupMemberId(newGroupId, who)), {
      groupId: newGroupId,
      uid: who,
      role: place.role,
      title: place.title,
      ...(place.coach === null ? {} : { coach: place.coach }),
      displayName: m.displayName ?? '',
      photoPath: m.photoPath ?? null,
      playerSummary: playerSummaryOf(summaries.get(who) ?? []),
      // Their own choices for the team carry on: notifications (NOTIF-3),
      // what they share (TEAM-10), and the color scheme they see it in
      // (SET-2).
      notificationLevel: m.notificationLevel ?? 'all',
      mutedUntil: m.mutedUntil ?? null,
      colorScheme: m.colorScheme ?? null,
      avatarColor: m.avatarColor ?? null,
      ...(m.contactPhone != null ? { contactPhone: m.contactPhone } : {}),
      ...(m.contactEmail != null ? { contactEmail: m.contactEmail } : {}),
      // Someone added by email who hasn't signed in yet (AUTH-6).
      ...(m.pending === true ? { pending: true } : {}),
      lastReadAt: now,
      lastPostedAt: null,
      joinedAt: now,
      addedBy: uid,
    });
  }
  const details = comingPlayers.length ? await byTeam(Collections.playerDetails).get() : null;
  for (const player of comingPlayers) {
    const p = player.data();
    await writes.set(db().collection(Collections.players).doc(newPlayerId(player.id)), {
      groupId: newGroupId,
      displayName: p.displayName ?? '',
      displayNameLower: p.displayNameLower ?? String(p.displayName ?? '').toLowerCase(),
      ...(p.jerseyNumber != null ? { jerseyNumber: p.jerseyNumber } : {}),
      ...(p.position != null ? { position: p.position } : {}),
      ...(p.walkUpSong != null ? { walkUpSong: p.walkUpSong } : {}),
      status: 'active',
      createdBy: uid,
      createdAt: now,
      updatedAt: now,
    });
  }
  // Details only of players that came (PLAYER-12).
  for (const d of details?.docs ?? []) {
    if (!playerById.has(d.id)) continue;
    await writes.set(db().collection(Collections.playerDetails).doc(newPlayerId(d.id)), {
      ...d.data(),
      groupId: newGroupId,
    });
  }
  for (const link of keptLinks) {
    const playerId = newPlayerId(String(link.get('playerId')));
    const who = String(link.get('uid'));
    await writes.set(db().collection(Collections.playerGuardians).doc(compositeId(playerId, who)), {
      ...link.data(),
      playerId,
      groupId: newGroupId,
    });
  }

  // Saved plays (BOARD-4), teams only.
  let plays = 0;
  if (hasPlayers && choices.plays) {
    for (const play of (await byTeam(Collections.plays).get()).docs) {
      await writes.set(db().collection(Collections.plays).doc(seasonCopyId(newGroupId, play.id)), {
        ...play.data(),
        groupId: newGroupId,
      });
      plays++;
    }
  }
  await writes.commit();

  // Documents (DOC-2): a link as it is; a file copied into its new
  // document's folder first, and left out when it's gone. notifyTeam is off,
  // so the copies don't each tell the team (DOC-6).
  let documents = 0;
  if (choices.documents) {
    const docs = (await byTeam(Collections.groupDocuments).get()).docs;
    for (const part of chunk(docs, 5)) {
      const copies = await Promise.all(
        part.map(async (d) => {
          const id = seasonCopyId(newGroupId, d.id);
          const data = d.data();
          if (data.kind !== 'file') return { id, data };
          const fileName = String(data.path ?? '').split('/').pop() ?? '';
          const to = `groups/${newGroupId}/documents/${id}/${fileName}`;
          if (!fileName || !(await copyFile(String(data.path), to, maxBytes))) return null;
          return { id, data: { ...data, path: to } };
        }),
      );
      for (const copy of copies) {
        if (!copy) continue;
        await writes.set(db().collection(Collections.groupDocuments).doc(copy.id), {
          ...copy.data,
          groupId: newGroupId,
          notifyTeam: false,
          updatedAt: now,
        });
        documents++;
      }
    }
    await writes.commit();
  }

  // An earlier attempt may have brought someone, or a player, who has
  // since left the old team.
  if (made.exists) await Promise.all([refreshMemberCount(newGroupId), refreshPlayerCount(newGroupId)]);
  return { uids: [...uids], players: comingPlayers.length, documents, plays, leftOut };
}
