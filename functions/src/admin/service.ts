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
import { Collections, Limits } from '../shared/constants.js';
import {
  configFields,
  iso,
  plain,
  prefixEnd,
  TEAM_SORT_FIELD,
  teamStatus,
  USER_FILTER,
  type AppConfigInput,
  type TeamSort,
  type TeamStatus,
  type UserFilter,
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
 * in that time.
 */
export async function dashboard(now = Date.now()): Promise<DashboardTotals> {
  const weekAgo = Timestamp.fromMillis(now - 7 * DAY_MS);
  const count = async (q: Query) => (await q.count().get()).data().count;
  const groups = db().collection(Collections.groups);
  const [users, teams, newTeams, activeTeams, messages, openReports, storage] = await Promise.all([
    count(db().collection(Collections.users)),
    count(groups),
    count(groups.where('createdAt', '>=', weekAgo)),
    count(groups.where('lastMessageAt', '>=', weekAgo)),
    count(db().collection(Collections.messages).where('createdAt', '>=', weekAgo)),
    count(db().collection(Collections.reports).where('status', '==', 'open')),
    groups.aggregate({ bytes: AggregateField.sum('storageBytes') }).get(),
  ]);
  return {
    users,
    teams,
    newTeams,
    activeTeams,
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

/** [a] before [b] when its sort field is larger (newest, most active, largest); missing values last. */
function bySortField(field: string) {
  const value = (d: FirebaseFirestore.QueryDocumentSnapshot) => {
    const v = d.get(field) as unknown;
    if (v instanceof Timestamp) return v.toMillis();
    return typeof v === 'number' ? v : -Infinity;
  };
  return (a: FirebaseFirestore.QueryDocumentSnapshot, b: FirebaseFirestore.QueryDocumentSnapshot) =>
    value(b) - value(a) || a.id.localeCompare(b.id);
}

/**
 * A page of teams (ADMIN-2), newest, most active, largest, or using the
 * most storage first, optionally only Active, Archived, or Suspended ones
 * (groups.status, one indexed query per sort and status). A search matches
 * the start of the name and returns the best [limit] matches in the chosen
 * sort and status, without paging.
 */
export async function listTeams(input: {
  query?: string;
  sort: TeamSort;
  status?: TeamStatus;
  cursor?: string;
  limit: number;
}): Promise<Page<TeamRow>> {
  const groups = db().collection(Collections.groups);
  const sortField = TEAM_SORT_FIELD[input.sort];
  let found: FirebaseFirestore.QueryDocumentSnapshot[];
  let nextCursor: string | null = null;
  if (input.query) {
    const snap = await groups
      .where('nameLower', '>=', input.query)
      .where('nameLower', '<', prefixEnd(input.query))
      .orderBy('nameLower')
      .limit(TEAM_SEARCH_MAX)
      .get();
    // Teams made before groups.status existed are read by their dates.
    found = snap.docs
      .filter((d) => !input.status || teamStatus(d.data()) === input.status)
      .sort(bySortField(sortField))
      .slice(0, input.limit);
  } else {
    let query: Query = input.status ? groups.where('status', '==', input.status) : groups;
    query = query.orderBy(sortField, 'desc').limit(input.limit);
    if (input.cursor) query = query.startAfter(await cursorDoc(Collections.groups, input.cursor));
    const snap = await query.get();
    found = snap.docs;
    if (snap.size === input.limit) nextCursor = snap.docs[snap.size - 1].id;
  }

  const owners = await fieldsOf(
    Collections.groupMembers,
    found.filter((d) => d.get('ownerId')).map((d) => `${d.id}_${d.get('ownerId')}`),
    ['displayName'],
  );
  const rows = found.map((d): TeamRow => {
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
  return { rows, nextCursor };
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
  if (!group.exists) throw new HttpsError('not-found', 'No such team.');
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
 * A page of people (ADMIN-4), newest first, optionally filtered by Added,
 * Active, Disabled, or Super admin. A search matches the start of the name
 * or the email and returns up to [limit] matches in name order, without
 * paging (ARCH §6.2 admin search).
 */
export async function listUsers(input: {
  query?: string;
  filter?: UserFilter;
  cursor?: string;
  limit: number;
}): Promise<Page<UserRow>> {
  let base: Query = db().collection(Collections.users);
  if (input.filter) {
    const [field, value] = USER_FILTER[input.filter];
    base = base.where(field, '==', value);
  }
  let docs: FirebaseFirestore.QueryDocumentSnapshot[];
  let nextCursor: string | null = null;
  if (input.query) {
    const prefix = (field: string) =>
      base.where(field, '>=', input.query).where(field, '<', prefixEnd(input.query!)).orderBy(field).limit(input.limit).get();
    const [byName, byEmail] = await Promise.all([prefix('displayNameLower'), prefix('emailLower')]);
    const unique = new Map([...byName.docs, ...byEmail.docs].map((d) => [d.id, d]));
    docs = [...unique.values()]
      .sort((a, b) => String(a.get('displayNameLower') ?? '').localeCompare(String(b.get('displayNameLower') ?? '')))
      .slice(0, input.limit);
  } else {
    let query = base.orderBy('createdAt', 'desc').limit(input.limit);
    if (input.cursor) query = query.startAfter(await cursorDoc(Collections.users, input.cursor));
    const snap = await query.get();
    docs = snap.docs;
    if (snap.size === input.limit) nextCursor = snap.docs[snap.size - 1].id;
  }
  const users = await authUsers(docs.map((d) => d.id));
  return { rows: docs.map((d) => userRow(d.id, d.data(), users.get(d.id))), nextCursor };
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
  const memberships = await db()
    .collection(Collections.groupMembers)
    .where('uid', '==', uid)
    .limit(Limits.groupsPerUserMax)
    .get();
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

/**
 * The super admins who hold the claim in Auth now and aren't disabled, with
 * their sign-in email (SAFE-4's alerts). users.superAdmin only finds the
 * candidates, as in wouldLeaveNoSuperAdmin.
 */
export async function currentSuperAdminEmails(): Promise<string[]> {
  const flagged = await db()
    .collection(Collections.users)
    .where('superAdmin', '==', true)
    .select()
    .limit(Limits.queryLimitMax)
    .get();
  const users = await authUsers(flagged.docs.map((d) => d.id));
  return [...users.values()]
    .filter((u) => u.customClaims?.superAdmin === true && !u.disabled && u.email)
    .map((u) => u.email!);
}

// ---- Reports (ADMIN-5) -------------------------------------------------------

/** One report in the super-admin queue (ADMIN-5). Dates are ISO 8601. */
export interface ReportRow {
  id: string;
  groupId: string;
  groupName: string;
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
    fieldsOf(Collections.groups, snap.docs.map((d) => d.get('groupId') as string), ['name']),
    fieldsOf(Collections.users, snap.docs.map((d) => d.get('reporterId') as string), ['displayName']),
  ]);
  const rows = snap.docs.map((d): ReportRow => {
    const r = d.data();
    return {
      id: d.id,
      groupId: String(r.groupId ?? ''),
      groupName: String(groups.get(r.groupId)?.name ?? ''),
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
  'announcementBanner',
] as const;

/**
 * Saves the platform settings (ADMIN-7) to config/app, which every
 * signed-in app reads (the announcement banner) and createGroup enforces
 * (who may create teams, how many a day, the new team's storage limit).
 * Other fields (maxImageMb) are kept. Returns the edited fields before and
 * after, as plain JSON.
 */
export async function updateConfig(input: AppConfigInput): Promise<{
  before: Record<string, unknown>;
  after: Record<string, unknown>;
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
  return { before: pick(before), after: pick(fields) };
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
    defaultStorageQuotaMb: Math.min(
      positive(config.defaultStorageQuotaMb, Limits.defaultStorageQuotaMb),
      Limits.storageQuotaMaxMb,
    ),
  };
}
