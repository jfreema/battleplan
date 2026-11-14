// Admin domain service (SPEC §6.11, ARCH §6.4): the God admin panel's reads
// across every team and user, and config/app, which it owns. Actions on
// teams, accounts, documents, and reports go through those domains'
// services; this only reads their collections. Callers check the
// superAdmin claim.
import { AggregateField, FieldValue, Timestamp, type Query } from 'firebase-admin/firestore';
import type { UserRecord } from 'firebase-admin/auth';
import { HttpsError } from 'firebase-functions/v2/https';
import { randomUUID } from 'node:crypto';
import { signInMethodsOf } from '../accounts/profile.js';
import { isUsable } from '../invites/service.js';
import { playerStatusOf, relationOf } from '../players/roster.js';
import { auth, db } from '../shared/admin.js';
import { applyDefaultQuota, defaultQuotaMbOf } from '../teams/storage.js';
import { Collections, Limits } from '../shared/constants.js';
import { teamMembershipsOf } from '../shared/roles.js';
import {
  configFields,
  iso,
  plain,
  prefixEnd,
  TEAM_SORTS_DESC_FIRST,
  teamStatus,
  USER_FILTER,
  type AppConfigInput,
  type AuditSort,
  type TeamSort,
  type TeamStatus,
  type UserFilter,
  type UserSort,
} from './inputs.js';

const DAY_MS = 86_400_000;

/** A page of rows, and where the next one starts (null at the end). */
export interface Page<T> {
  rows: T[];
  nextCursor: string | null;
}

/** The document a page cursor names, for startAfter, or `invalid-argument`. */
async function cursorDoc(collection: string, cursor: string): Promise<FirebaseFirestore.DocumentSnapshot> {
  const snap = await db().collection(collection).doc(cursor).get();
  if (!snap.exists) throw new HttpsError('invalid-argument', 'bad-cursor');
  return snap;
}

/** Fields of each document [ids] names in [collection], by ID, in one getAll; missing ones are left out. */
async function fieldsOf(
  collection: string,
  ids: string[],
  fields: string[],
): Promise<Map<string, FirebaseFirestore.DocumentData>> {
  const unique = [...new Set(ids.filter(Boolean))];
  const out = new Map<string, FirebaseFirestore.DocumentData>();
  if (!unique.length) return out;
  const refs = unique.map((id) => db().collection(collection).doc(id));
  const snaps = await db().getAll(...refs, { fieldMask: fields });
  snaps.forEach((s) => s.exists && out.set(s.id, s.data()!));
  return out;
}

// ---- Dashboard (ADMIN-1) -----------------------------------------------------

export interface DashboardTotals {
  users: number;
  teams: number;
  /** Teams created in the last 7 days. */
  newTeams: number;
  /** Teams with a message in the last 7 days. */
  activeTeams: number;
  /** Messages sent in the last 7 days. */
  messages: number;
  storageBytes: number;
  openReports: number;
}

/**
 * The platform's totals (ADMIN-1), each a count() or sum() aggregation, so
 * nothing is scanned: about one read per 1,000 entries (ARCH §6.2). "This
 * week" and "active" mean the last 7 days; an active team has had a message
 * in that time. Direct conversations (CHAT-19) are groups too, counted
 * apart and taken off the teams; their messages and storage count.
 */
export async function dashboard(now = Date.now()): Promise<DashboardTotals> {
  const weekAgo = Timestamp.fromMillis(now - 7 * DAY_MS);
  const count = async (q: Query) => (await q.count().get()).data().count;
  const groups = db().collection(Collections.groups);
  const direct = groups.where('kind', '==', 'direct');
  const [users, groupCount, newGroups, activeGroups, chats, newChats, activeChats, messages, openReports, storage] =
    await Promise.all([
      count(db().collection(Collections.users)),
      count(groups),
      count(groups.where('createdAt', '>=', weekAgo)),
      count(groups.where('lastMessageAt', '>=', weekAgo)),
      count(direct),
      count(direct.where('createdAt', '>=', weekAgo)),
      count(direct.where('lastMessageAt', '>=', weekAgo)),
      count(db().collection(Collections.messages).where('createdAt', '>=', weekAgo)),
      count(db().collection(Collections.reports).where('status', '==', 'open')),
      groups.aggregate({ bytes: AggregateField.sum('storageBytes') }).get(),
    ]);
  return {
    users,
    teams: groupCount - chats,
    newTeams: newGroups - newChats,
    activeTeams: activeGroups - activeChats,
    messages,
    storageBytes: storage.data().bytes ?? 0,
    openReports,
  };
}

// ---- Teams (ADMIN-2, ADMIN-3) ------------------------------------------------

/** One row of the teams table (ADMIN-2). Dates are ISO 8601. */
export interface TeamRow {
  id: string;
  name: string;
  sport: string;
  ownerId: string;
  ownerName: string;
  memberCount: number;
  lastMessageAt: string | null;
  storageBytes: number;
  storageQuotaBytes: number;
  status: TeamStatus;
  createdAt: string | null;
}

/**
 * The most name matches one search reads (ADMIN-2) before sorting them.
 * A prefix search ranges over nameLower, so Firestore returns matches in
 * name order; they're re-sorted by the chosen sort here. A search is one
 * page of the best matches, without a cursor, as in the users search.
 */
export const TEAM_SEARCH_MAX = 500;

/** A sortable value: text lowercased, dates as ISO 8601, null when missing. */
type SortValue = string | number | null;

/**
 * [rows] ordered by [key] in [direction], rows missing it last either
 * way, then by [tie] (always the same way), so a page never shuffles. The
 * admin lists sort this way when Firestore can't (ADMIN-2, ADMIN-4,
 * ADMIN-6): by a name it would have to look up, or by a field some
 * documents lack, which its orderBy leaves out.
 */
export function sortByKey<T>(
  rows: T[],
  key: (row: T) => SortValue,
  direction: 'asc' | 'desc',
  tie: (a: T, b: T) => number,
): T[] {
  const sign = direction === 'asc' ? 1 : -1;
  const compare = (a: SortValue, b: SortValue) => {
    if (a === b) return 0;
    if (a === null) return 1;
    if (b === null) return -1;
    return (typeof a === 'number' && typeof b === 'number' ? a - b : String(a).localeCompare(String(b))) * sign;
  };
  return [...rows].sort((a, b) => compare(key(a), key(b)) || tie(a, b));
}

/** Text as it sorts: trimmed, lowercased, and null when blank. */
const textKey = (text: string | null | undefined) => text?.trim().toLowerCase() || null;

/**
 * The most teams a list sorted by anything but created reads (ADMIN-2):
 * they're sorted here, past this many the newest.
 */
export const TEAM_SORT_MAX = 2000;

/** Where a status falls when sorting by it: Active, Archived, then Suspended, as they read. */
const TEAM_STATUS_ORDER: Record<string, number> = { active: 0, archived: 1, suspended: 2 };

/** Orders [rows] by [sort] (see sortByKey); ties by name, then id. */
export function sortTeamRows(rows: TeamRow[], sort: TeamSort, direction: 'asc' | 'desc'): TeamRow[] {
  const key = (t: TeamRow): SortValue => {
    switch (sort) {
      case 'created':
        return t.createdAt;
      case 'name':
        return textKey(t.name);
      case 'sport':
        return textKey(t.sport);
      case 'owner':
        return textKey(t.ownerName);
      case 'members':
        return t.memberCount;
      case 'activity':
        return t.lastMessageAt;
      case 'storage':
        return t.storageBytes;
      case 'status':
        return TEAM_STATUS_ORDER[t.status] ?? 3;
    }
  };
  return sortByKey(rows, key, direction, (a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase()) || a.id.localeCompare(b.id));
}

/**
 * A page of teams (ADMIN-2), optionally only Active, Archived, or
 * Suspended ones, sorted by any column either way (newest first by
 * default; owner's request 2026-11-14). Newest first pages straight from
 * Firestore (groups.status and createdAt are indexed); any other order
 * reads every team the filter matches (up to TEAM_SORT_MAX, the newest),
 * sorts them here, and pages by position, the cursor being the next row's.
 * A search matches the start of the name and returns the best [limit]
 * matches in the chosen sort and status, without paging.
 */
export async function listTeams(input: {
  query?: string;
  sort: TeamSort;
  direction?: 'asc' | 'desc';
  status?: TeamStatus;
  cursor?: string;
  limit: number;
}): Promise<Page<TeamRow>> {
  const groups = db().collection(Collections.groups);
  const direction = input.direction ?? (TEAM_SORTS_DESC_FIRST.has(input.sort) ? 'desc' : 'asc');
  // Direct conversations (CHAT-19) aren't teams.
  const teamsOf = (docs: FirebaseFirestore.QueryDocumentSnapshot[]) => docs.filter((d) => d.get('kind') !== 'direct');
  if (input.query) {
    const snap = await groups
      .where('nameLower', '>=', input.query)
      .where('nameLower', '<', prefixEnd(input.query))
      .orderBy('nameLower')
      .limit(TEAM_SEARCH_MAX)
      .get();
    // Teams made before groups.status existed are read by their dates.
    const found = teamsOf(snap.docs).filter((d) => !input.status || teamStatus(d.data()) === input.status);
    const rows = sortTeamRows(await teamRows(found), input.sort, direction);
    return { rows: rows.slice(0, input.limit), nextCursor: null };
  }
  const filtered: Query = input.status ? groups.where('status', '==', input.status) : groups;
  if (input.sort === 'created' && direction === 'desc') {
    let query = filtered.orderBy('createdAt', 'desc').limit(input.limit);
    if (input.cursor) query = query.startAfter(await cursorDoc(Collections.groups, input.cursor));
    const snap = await query.get();
    // A page may come back short of direct conversations, and the cursor
    // still goes on from the last one read.
    const nextCursor = snap.size === input.limit ? snap.docs[snap.size - 1].id : null;
    return { rows: await teamRows(teamsOf(snap.docs)), nextCursor };
  }
  const start = positionOf(input.cursor);
  const every = await filtered.orderBy('createdAt', 'desc').limit(TEAM_SORT_MAX).get();
  const rows = sortTeamRows(await teamRows(teamsOf(every.docs)), input.sort, direction);
  return pageAt(rows, start, input.limit);
}

/** A sorted list's cursor: the position of its next row; none is the start. */
function positionOf(cursor: string | undefined): number {
  const start = cursor === undefined ? 0 : Number(cursor);
  if (!Number.isSafeInteger(start) || start < 0) throw new HttpsError('invalid-argument', 'bad-cursor');
  return start;
}

/** The [limit] rows from [start], with the next page's position while there's more. */
function pageAt<T>(rows: T[], start: number, limit: number): Page<T> {
  const end = start + limit;
  return { rows: rows.slice(start, end), nextCursor: end < rows.length ? String(end) : null };
}

/** Each team's row, with its owner's name from their membership. */
async function teamRows(found: FirebaseFirestore.QueryDocumentSnapshot[]): Promise<TeamRow[]> {
  const owners = await fieldsOf(
    Collections.groupMembers,
    found.filter((d) => d.get('ownerId')).map((d) => `${d.id}_${d.get('ownerId')}`),
    ['displayName'],
  );
  return found.map((d): TeamRow => {
    const t = d.data();
    const ownerId = String(t.ownerId ?? '');
    return {
      id: d.id,
      name: String(t.name ?? ''),
      sport: String(t.sport ?? ''),
      ownerId,
      ownerName: String(owners.get(`${d.id}_${ownerId}`)?.displayName ?? ''),
      memberCount: Number(t.memberCount ?? 0),
      lastMessageAt: iso(t.lastMessageAt),
      storageBytes: Number(t.storageBytes ?? 0),
      storageQuotaBytes: Number(t.storageQuotaBytes ?? Limits.defaultStorageQuotaMb * 1024 * 1024),
      status: teamStatus(t),
      createdAt: iso(t.createdAt),
    };
  });
}

/** How many of a team's latest messages its detail page reads for review (ADMIN-3 Content). */
export const RECENT_MESSAGES_MAX = 20;

/**
 * Everything the team detail page shows (ADMIN-3): the team, its owner's
 * name, its people with roles (up to Limits.membersPerGroupMax), its
 * players (active and pending) and player links, its usable invites, its
 * recent messages, and how many events, documents, and polls it has.
 * Dates are ISO 8601.
 */
export async function getTeam(groupId: string) {
  const group = await db().collection(Collections.groups).doc(groupId).get();
  // A direct conversation (CHAT-19) is only its two people's.
  if (!group.exists || group.get('kind') === 'direct') throw new HttpsError('not-found', 'No such team.');
  const byTeam = (collection: string) => db().collection(collection).where('groupId', '==', groupId);
  const [members, players, guardians, invites, events, documents, polls, messages] = await Promise.all([
    byTeam(Collections.groupMembers).limit(Limits.membersPerGroupMax).get(),
    byTeam(Collections.players).limit(Limits.playersPerGroupMax).get(),
    // Up to 4 guardians and one 'self' link per player (PLAYER-3).
    byTeam(Collections.playerGuardians).limit(Limits.playersPerGroupMax * (Limits.guardiansPerPlayerMax + 1)).get(),
    byTeam(Collections.invites).where('revokedAt', '==', null).limit(Limits.queryLimitMax).get(),
    byTeam(Collections.events).count().get(),
    byTeam(Collections.groupDocuments).count().get(),
    byTeam(Collections.polls).count().get(),
    byTeam(Collections.messages).orderBy('createdAt', 'desc').limit(RECENT_MESSAGES_MAX).get(),
  ]);
  const ownerId = String(group.get('ownerId') ?? '');
  return {
    team: { id: group.id, ...(plain(group.data()) as object), status: teamStatus(group.data()!) },
    ownerName: String(members.docs.find((d) => d.get('uid') === ownerId)?.get('displayName') ?? ''),
    members: members.docs.map((d) => ({
      uid: d.get('uid') as string,
      role: d.get('role') as string,
      displayName: String(d.get('displayName') ?? ''),
      photoPath: (d.get('photoPath') as string | null | undefined) ?? null,
      title: (d.get('title') as string | null | undefined) ?? null,
      playerSummary: (d.get('playerSummary') as string | null | undefined) ?? null,
      pending: d.get('pending') === true,
      joinedAt: iso(d.get('joinedAt')),
    })),
    players: players.docs.map((d) => ({
      id: d.id,
      displayName: String(d.get('displayName') ?? ''),
      jerseyNumber: (d.get('jerseyNumber') as string | null | undefined) ?? null,
      position: (d.get('position') as string | null | undefined) ?? null,
      status: playerStatusOf(d.data()),
    })),
    guardians: guardians.docs.map((d) => ({
      playerId: d.get('playerId') as string,
      uid: d.get('uid') as string,
      via: (d.get('via') as string | undefined) ?? null,
      relation: relationOf(d.data()),
    })),
    invites: invites.docs
      .filter((d) => isUsable(d.data()))
      .map((d) => ({
        code: d.id,
        type: d.get('type') as string,
        email: (d.get('email') as string | null | undefined) ?? null,
        createdBy: (d.get('createdBy') as string | undefined) ?? null,
        expiresAt: iso(d.get('expiresAt')),
        maxUses: (d.get('maxUses') as number | null | undefined) ?? null,
        useCount: Number(d.get('useCount') ?? 0),
        createdAt: iso(d.get('createdAt')),
      })),
    // ADMIN-3 Content: the latest messages to review, newest first, each
    // deletable (deleteMessage, audited). Deleted and system messages are
    // left out, so a page can hold fewer than RECENT_MESSAGES_MAX.
    recentMessages: messages.docs
      .filter((d) => d.get('deletedAt') == null && d.get('type') !== 'system')
      .map((d) => ({
        id: d.id,
        authorId: String(d.get('authorId') ?? ''),
        authorName: String(d.get('authorName') ?? ''),
        text: String(d.get('text') ?? '').slice(0, 500),
        photoCount: ((d.get('attachments') as unknown[] | undefined) ?? []).length,
        createdAt: iso(d.get('createdAt')),
      })),
    counts: {
      events: events.data().count,
      documents: documents.data().count,
      polls: polls.data().count,
    },
  };
}

// ---- Users (ADMIN-4) ---------------------------------------------------------

/** One row of the users list (ADMIN-4). Dates are ISO 8601. */
export interface UserRow {
  uid: string;
  displayName: string;
  email: string | null;
  photoPath: string | null;
  status: string;
  superAdmin: boolean;
  disabled: boolean;
  createdAt: string | null;
  lastActiveAt: string | null;
}

/** Firebase Auth's record for each of [uids] (100 per call), by uid. */
async function authUsers(uids: string[]): Promise<Map<string, UserRecord>> {
  const out = new Map<string, UserRecord>();
  for (let i = 0; i < uids.length; i += 100) {
    const result = await auth().getUsers(uids.slice(i, i + 100).map((uid) => ({ uid })));
    result.users.forEach((u) => out.set(u.uid, u));
  }
  return out;
}

/** When the person last used the app: their last token refresh or sign-in, else the profile's lastActiveAt. */
function lastActive(user: UserRecord | undefined, profile: FirebaseFirestore.DocumentData) {
  const when = user?.metadata.lastRefreshTime ?? user?.metadata.lastSignInTime;
  return when ? new Date(when).toISOString() : iso(profile.lastActiveAt);
}

function userRow(
  uid: string,
  p: FirebaseFirestore.DocumentData,
  user: UserRecord | undefined,
): UserRow {
  return {
    uid,
    displayName: String(p.displayName ?? user?.displayName ?? ''),
    email: (p.email as string | null | undefined) ?? user?.email ?? null,
    photoPath: (p.photoPath as string | null | undefined) ?? null,
    status: String(p.status ?? 'active'),
    // The claim is what rules and Functions check; users.superAdmin follows it.
    superAdmin: user ? user.customClaims?.superAdmin === true : p.superAdmin === true,
    disabled: user?.disabled ?? p.status === 'disabled',
    createdAt: iso(p.createdAt) ?? (user ? new Date(user.metadata.creationTime).toISOString() : null),
    lastActiveAt: lastActive(user, p),
  };
}

/**
 * The most people a sorted users list reads (ADMIN-4). Sorting by a column
 * other than Joined happens here, over everyone the filter matches, since
 * last active comes from Auth and Firestore drops documents missing the
 * field it orders by; past this many, it sorts the newest who joined.
 */
export const USER_SORT_MAX = 2000;

/** Where a status falls when sorting by it: Active, Added, then Disabled, as they read. */
const STATUS_ORDER: Record<string, number> = { active: 0, provisioned: 1, disabled: 2 };

/** Orders [rows] by [sort] (see sortByKey); ties by name, then uid. */
export function sortUserRows(rows: UserRow[], sort: UserSort, direction: 'asc' | 'desc'): UserRow[] {
  const key = (row: UserRow): SortValue => {
    switch (sort) {
      case 'name':
        return textKey(row.displayName);
      case 'email':
        return textKey(row.email);
      case 'status':
        return STATUS_ORDER[row.status] ?? 3;
      case 'joined':
        return row.createdAt;
      case 'lastActive':
        return row.lastActiveAt;
    }
  };
  return sortByKey(
    rows,
    key,
    direction,
    (a, b) => a.displayName.toLowerCase().localeCompare(b.displayName.toLowerCase()) || a.uid.localeCompare(b.uid),
  );
}

/**
 * A page of people (ADMIN-4), optionally filtered by Added, Active,
 * Disabled, or Super admin, and sorted by any column either way (newest
 * joined first by default). A search matches the start of the name or the
 * email and returns up to [limit] matches, sorted the same way, without
 * paging (ARCH §6.2 admin search). Newest joined first pages straight from
 * Firestore; any other order sorts everyone the filter matches (up to
 * USER_SORT_MAX) and pages by position, the cursor being the next row's.
 */
export async function listUsers(input: {
  query?: string;
  filter?: UserFilter;
  sort?: UserSort;
  direction?: 'asc' | 'desc';
  cursor?: string;
  limit: number;
}): Promise<Page<UserRow>> {
  const sort = input.sort ?? 'joined';
  const direction = input.direction ?? (sort === 'joined' || sort === 'lastActive' ? 'desc' : 'asc');
  let base: Query = db().collection(Collections.users);
  if (input.filter) {
    const [field, value] = USER_FILTER[input.filter];
    base = base.where(field, '==', value);
  }
  const rowsOf = async (docs: FirebaseFirestore.QueryDocumentSnapshot[]) => {
    const users = await authUsers(docs.map((d) => d.id));
    return docs.map((d) => userRow(d.id, d.data(), users.get(d.id)));
  };
  if (input.query) {
    const prefix = (field: string) =>
      base.where(field, '>=', input.query).where(field, '<', prefixEnd(input.query!)).orderBy(field).limit(input.limit).get();
    const [byName, byEmail] = await Promise.all([prefix('displayNameLower'), prefix('emailLower')]);
    const unique = new Map([...byName.docs, ...byEmail.docs].map((d) => [d.id, d]));
    const rows = sortUserRows(await rowsOf([...unique.values()]), sort, direction);
    return { rows: rows.slice(0, input.limit), nextCursor: null };
  }
  if (sort === 'joined' && direction === 'desc') {
    let query = base.orderBy('createdAt', 'desc').limit(input.limit);
    if (input.cursor) query = query.startAfter(await cursorDoc(Collections.users, input.cursor));
    const snap = await query.get();
    const nextCursor = snap.size === input.limit ? snap.docs[snap.size - 1].id : null;
    return { rows: await rowsOf(snap.docs), nextCursor };
  }
  const start = positionOf(input.cursor);
  const everyone = await base.orderBy('createdAt', 'desc').limit(USER_SORT_MAX).get();
  return pageAt(sortUserRows(await rowsOf(everyone.docs), sort, direction), start, input.limit);
}

/**
 * One person in full (ADMIN-4): the list row plus how they sign in, whether
 * their email is verified, and their teams with roles.
 */
export async function getUser(uid: string) {
  const [profile, user] = await Promise.all([
    db().collection(Collections.users).doc(uid).get(),
    auth()
      .getUser(uid)
      .catch((e: { code?: string }) => {
        if (e.code === 'auth/user-not-found') return undefined;
        throw e;
      }),
  ]);
  if (!profile.exists && !user) throw new HttpsError('not-found', 'No such user.');
  const p = profile.data() ?? {};
  // Teams only: their direct conversations are theirs alone (CHAT-19).
  const memberships = await teamMembershipsOf(uid).limit(Limits.groupsPerUserMax).get();
  const groups = await fieldsOf(
    Collections.groups,
    memberships.docs.map((m) => m.get('groupId') as string),
    ['name', 'archivedAt', 'suspendedAt'],
  );
  return {
    ...userRow(uid, p, user),
    emailVerified: user?.emailVerified ?? false,
    signInMethods: user
      ? signInMethodsOf(user.providerData.map((d) => d.providerId))
      : ((p.signInMethods as string[] | undefined) ?? []),
    teams: memberships.docs.map((m) => {
      const groupId = m.get('groupId') as string;
      const group = groups.get(groupId);
      return {
        groupId,
        name: String(group?.name ?? ''),
        status: group ? teamStatus(group) : 'active',
        role: m.get('role') as string,
        pending: m.get('pending') === true,
        joinedAt: iso(m.get('joinedAt')),
      };
    }),
  };
}

// ---- Audit log (ADMIN-6) -----------------------------------------------------

/** One audit log entry as the sorted list sends it. Dates are ISO 8601. */
export interface AuditRow {
  id: string;
  actorId: string;
  /** Who did it, from their profile, for sorting by Who; blank once they're gone. */
  actorName: string;
  action: string;
  groupId: string | null;
  targetType: string;
  targetId: string;
  before: unknown;
  after: unknown;
  createdAt: string | null;
}

/**
 * The most entries a sorted audit log reads (ADMIN-6): the newest the
 * filters match. Newest first, the app reads auditLogs itself and pages
 * through all of them.
 */
export const AUDIT_SORT_MAX = 2000;

/**
 * Orders [rows] by [sort] (see sortByKey): Who by the person's name, else
 * their uid, as the log shows them; ties newest first, then by id.
 */
export function sortAuditRows(rows: AuditRow[], sort: AuditSort, direction: 'asc' | 'desc'): AuditRow[] {
  const key = (e: AuditRow): SortValue => {
    switch (sort) {
      case 'when':
        return e.createdAt;
      case 'who':
        return textKey(e.actorName) ?? textKey(e.actorId);
      case 'action':
        return textKey(e.action);
      case 'team':
        return textKey(e.groupId);
      case 'target':
        return textKey(`${e.targetType} ${e.targetId}`);
    }
  };
  return sortByKey(rows, key, direction, (a, b) => (b.createdAt ?? '').localeCompare(a.createdAt ?? '') || a.id.localeCompare(b.id));
}

/**
 * A page of the audit log sorted by any column either way (ADMIN-6, owner's
 * request 2026-11-14): the newest AUDIT_SORT_MAX entries matching the same
 * filters as the app's own read (each combination indexed, newest first),
 * sorted here and paged by position, the cursor being the next row's.
 */
export async function listAudit(input: {
  actorId?: string;
  action?: string;
  groupId?: string;
  from?: string;
  until?: string;
  sort: AuditSort;
  direction?: 'asc' | 'desc';
  cursor?: string;
  limit: number;
}): Promise<Page<AuditRow>> {
  const direction = input.direction ?? (input.sort === 'when' ? 'desc' : 'asc');
  const start = positionOf(input.cursor);
  let query: Query = db().collection(Collections.auditLogs);
  if (input.actorId) query = query.where('actorId', '==', input.actorId);
  if (input.action) query = query.where('action', '==', input.action);
  if (input.groupId) query = query.where('groupId', '==', input.groupId);
  if (input.from) query = query.where('createdAt', '>=', Timestamp.fromDate(new Date(input.from)));
  if (input.until) query = query.where('createdAt', '<', Timestamp.fromDate(new Date(input.until)));
  const snap = await query.orderBy('createdAt', 'desc').limit(AUDIT_SORT_MAX).get();
  const actors = [...new Set(snap.docs.map((d) => String(d.get('actorId') ?? '')).filter(Boolean))];
  const names = await fieldsOf(Collections.users, actors, ['displayName']);
  const rows = snap.docs.map((d): AuditRow => {
    const e = d.data();
    const actorId = String(e.actorId ?? '');
    return {
      id: d.id,
      actorId,
      actorName: String(names.get(actorId)?.displayName ?? ''),
      action: String(e.action ?? ''),
      groupId: typeof e.groupId === 'string' ? e.groupId : null,
      targetType: String(e.targetType ?? ''),
      targetId: String(e.targetId ?? ''),
      before: plain(e.before ?? null),
      after: plain(e.after ?? null),
      createdAt: iso(e.createdAt),
    };
  });
  return pageAt(sortAuditRows(rows, input.sort, direction), start, input.limit);
}

/** How long one super-admin change may hold the lock before it's treated as abandoned. */
export const SUPER_ADMIN_LOCK_MS = 30_000;
/** How long to keep trying for the lock before giving up with `aborted`. */
const LOCK_WAIT_MS = 10_000;

/**
 * Runs [fn] while holding config/superAdmins' lock, so changes that can
 * take away the last super admin (revoking, disabling, deleting) happen
 * one at a time (ADMIN-4): each sees the others' Auth changes before its
 * own check. A lock left by a crashed call lapses after
 * SUPER_ADMIN_LOCK_MS. Busy for longer than LOCK_WAIT_MS is `aborted`.
 */
export async function withSuperAdminLock<T>(holder: string, fn: () => Promise<T>): Promise<T> {
  const ref = db().collection(Collections.config).doc('superAdmins');
  const token = randomUUID();
  const giveUpAt = Date.now() + LOCK_WAIT_MS;
  for (;;) {
    const taken = await db().runTransaction(async (tx) => {
      const until = (await tx.get(ref)).get('lockedUntil') as Timestamp | null | undefined;
      if (until && until.toMillis() > Date.now()) return false;
      tx.set(ref, {
        lockToken: token,
        lockedBy: holder,
        lockedUntil: Timestamp.fromMillis(Date.now() + SUPER_ADMIN_LOCK_MS),
      });
      return true;
    });
    if (taken) break;
    if (Date.now() > giveUpAt) throw new HttpsError('aborted', 'busy');
    await new Promise((r) => setTimeout(r, 50 + Math.random() * 100));
  }
  try {
    return await fn();
  } finally {
    await db().runTransaction(async (tx) => {
      if ((await tx.get(ref)).get('lockToken') === token) tx.update(ref, { lockToken: null, lockedUntil: null });
    });
  }
}

/**
 * Checks the caller still holds the superAdmin claim in Auth and isn't
 * disabled, as their ID token may be up to an hour old (a revoked super
 * admin's token keeps the claim until it expires): `permission-denied`
 * otherwise. Then marks their profile as a super admin's, so super admins
 * made before users.superAdmin existed (tools/seed/set-super-admin.ts) are
 * counted and listed too.
 */
export async function requireCurrentSuperAdmin(uid: string): Promise<void> {
  const user = await auth()
    .getUser(uid)
    .catch(() => undefined);
  if (user?.customClaims?.superAdmin !== true || user.disabled) {
    throw new HttpsError('permission-denied', 'Super admins only.');
  }
  await db()
    .collection(Collections.users)
    .doc(uid)
    .update({ superAdmin: true })
    .catch((e: { code?: number }) => {
      if (e.code !== 5) throw e; // 5 = NOT_FOUND
    });
}

/**
 * Whether revoking, disabling, or deleting [uid] would leave no super
 * admin who can sign in (ADMIN-4). Only people who hold the claim in Auth
 * now and aren't disabled count; users.superAdmin only finds the
 * candidates, so a stale flag can't stand in for one. Call it inside
 * withSuperAdminLock, after requireCurrentSuperAdmin.
 */
export async function wouldLeaveNoSuperAdmin(uid: string): Promise<boolean> {
  const flagged = await db()
    .collection(Collections.users)
    .where('superAdmin', '==', true)
    .select()
    .limit(Limits.queryLimitMax)
    .get();
  const others = flagged.docs.map((d) => d.id).filter((id) => id !== uid);
  const users = await authUsers(others);
  return !others.some((id) => {
    const user = users.get(id);
    return user?.customClaims?.superAdmin === true && !user.disabled;
  });
}

// ---- Reports (ADMIN-5) -------------------------------------------------------

/** One report in the super-admin queue (ADMIN-5). Dates are ISO 8601. */
export interface ReportRow {
  id: string;
  groupId: string;
  groupName: string;
  /**
   * Reported in a direct conversation (CHAT-19), not a team: there's no
   * team to remove anyone from or suspend, and groupName is empty.
   */
  direct: boolean;
  targetType: string;
  targetId: string;
  reason: string;
  details: string | null;
  /** What was reported, copied when it was reported: the message text or the document's name. */
  excerpt: string;
  subjectId: string;
  subjectName: string;
  reporterId: string;
  reporterName: string;
  status: string;
  resolution: string | null;
  note: string | null;
  resolvedBy: string | null;
  createdAt: string | null;
  resolvedAt: string | null;
}

/** A page of reports from every team with one status, newest first (ADMIN-5). */
export async function listReports(input: {
  status: string;
  cursor?: string;
  limit: number;
}): Promise<Page<ReportRow>> {
  let query = db()
    .collection(Collections.reports)
    .where('status', '==', input.status)
    .orderBy('createdAt', 'desc')
    .limit(input.limit);
  if (input.cursor) query = query.startAfter(await cursorDoc(Collections.reports, input.cursor));
  const snap = await query.get();
  const [groups, reporters] = await Promise.all([
    fieldsOf(Collections.groups, snap.docs.map((d) => d.get('groupId') as string), ['name', 'kind']),
    fieldsOf(Collections.users, snap.docs.map((d) => d.get('reporterId') as string), ['displayName']),
  ]);
  const rows = snap.docs.map((d): ReportRow => {
    const r = d.data();
    return {
      id: d.id,
      groupId: String(r.groupId ?? ''),
      groupName: String(groups.get(r.groupId)?.name ?? ''),
      direct: groups.get(r.groupId)?.kind === 'direct',
      targetType: String(r.targetType ?? ''),
      targetId: String(r.targetId ?? ''),
      reason: String(r.reason ?? ''),
      details: (r.details as string | null | undefined) ?? null,
      excerpt: String(r.excerpt ?? ''),
      subjectId: String(r.subjectId ?? ''),
      subjectName: String(r.subjectName ?? ''),
      reporterId: String(r.reporterId ?? ''),
      reporterName: String(reporters.get(r.reporterId)?.displayName ?? ''),
      status: String(r.status ?? ''),
      resolution: (r.resolution as string | null | undefined) ?? null,
      note: (r.note as string | null | undefined) ?? null,
      resolvedBy: (r.resolvedBy as string | null | undefined) ?? null,
      createdAt: iso(r.createdAt),
      resolvedAt: iso(r.resolvedAt),
    };
  });
  return { rows, nextCursor: snap.size === input.limit ? snap.docs[snap.size - 1].id : null };
}

// ---- Platform settings (ADMIN-7) ---------------------------------------------

/** The fields of config/app the admin panel edits, for the audit log's before and after. */
const CONFIG_KEYS = [
  'allowUserGroupCreation',
  'maxGroupsCreatedPerUserPerDay',
  'defaultStorageQuotaMb',
  'maxUploadMb',
  'supportEmail',
  'emailAdminAlerts',
  'announcementBanner',
] as const;

/**
 * Saves the platform settings (ADMIN-7) to config/app, which every
 * signed-in app reads (the announcement banner) and createGroup enforces
 * (who may create teams, how many a day). The storage limit is every
 * team's that doesn't have its own, so saving puts those teams on it
 * (applyDefaultQuota). Other fields (maxImageMb) are kept. Returns the
 * edited fields before and after, as plain JSON, and how many teams' limits
 * changed.
 */
export async function updateConfig(input: AppConfigInput): Promise<{
  before: Record<string, unknown>;
  after: Record<string, unknown>;
  teamsUpdated: number;
}> {
  const ref = db().collection(Collections.config).doc('app');
  const fields = configFields(input);
  const before = await db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    tx.set(ref, { ...fields, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
    return snap.data() ?? {};
  });
  const pick = (data: Record<string, unknown>) =>
    plain(Object.fromEntries(CONFIG_KEYS.map((k) => [k, data[k] ?? null]))) as Record<string, unknown>;
  const teamsUpdated = await applyDefaultQuota(defaultQuotaMbOf(fields), defaultQuotaMbOf(before));
  return { before: pick(before), after: pick(fields), teamsUpdated };
}

/**
 * The platform settings createGroup enforces (ADMIN-7, Q3), with the
 * built-in defaults for anything config/app doesn't set.
 */
export async function groupCreationConfig(): Promise<{
  allowUserGroupCreation: boolean;
  maxGroupsCreatedPerUserPerDay: number;
  defaultStorageQuotaMb: number;
}> {
  const config = (await db().collection(Collections.config).doc('app').get()).data() ?? {};
  const positive = (v: unknown, fallback: number) => (typeof v === 'number' && v > 0 ? v : fallback);
  return {
    allowUserGroupCreation: config.allowUserGroupCreation !== false,
    maxGroupsCreatedPerUserPerDay: positive(config.maxGroupsCreatedPerUserPerDay, Limits.groupsCreatedPerUserPerDay),
    defaultStorageQuotaMb: defaultQuotaMbOf(config),
  };
}
