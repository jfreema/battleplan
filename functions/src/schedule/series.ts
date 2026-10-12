// Repeating events (SCHED-3, SCHED-6, SCHED-7): what saveEventSeries does.
// Every action is planned first and written after, so a dry run returns the
// same counts without writing (the form's "Removes 4 practices; 9 people
// had answered").
import { FieldValue, Timestamp, type DocumentData, type DocumentSnapshot, type WriteBatch } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { audit } from '../audit/service.js';
import { chunk, trySend } from '../notify/service.js';
import { db } from '../shared/admin.js';
import {
  Collections,
  eventTypeValues,
  homeAwayValues,
  Limits,
  REMINDER_OFFSETS_MINUTES,
} from '../shared/constants.js';
import { groupMemberId } from '../shared/ids.js';
import { quotaBytesOf } from '../teams/storage.js';
import {
  addDays,
  dateInZone,
  expandDates,
  isDate,
  isTimeZone,
  occurrenceOn,
  type Occurrence,
  type Recurrence,
} from './recurrence.js';
import {
  changedFields,
  countEventRsvps,
  deleteEventRsvps,
  eventCanceledBody,
  eventChangedBody,
  eventRoute,
  eventView,
  nextReminderAtMs,
  notifyEventAudience,
  postEventCard,
  refreshRsvpStartTimes,
  seriesCanceledBody,
  seriesChangedBody,
  seriesCreatedBody,
  seriesSummary,
  timeOrPlaceChanged,
  withPlayers,
  ZERO_COUNTS,
} from './service.js';

// ---- Input (ARCH §6.4 rule 1) ---------------------------------------------

const DateString = z.string().refine(isDate);
const TimeString = z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/);
const TimeZone = z.string().min(1).max(64).refine(isTimeZone);

const Location = z
  .object({
    name: z.string().max(Limits.locationNameMax).default(''),
    address: z.string().max(Limits.locationAddressMax).default(''),
  })
  .refine((l) => l.name.trim() !== '' || l.address.trim() !== '');

/** A series' event fields minus dates (ARCH §6.2 eventSeries.template). */
const TemplateShape = z.object({
  type: z.enum(eventTypeValues),
  title: z.string().max(Limits.eventTitleMax).refine((t) => t.trim().length > 0),
  description: z.string().max(Limits.eventNotesMax).default(''),
  location: Location.nullable().default(null),
  allDay: z.boolean(),
  startTime: TimeString.nullable().default(null),
  endTime: TimeString.nullable().default(null),
  timeZone: TimeZone,
  arriveMinutesBefore: z.number().int().min(0).max(Limits.arriveMinutesMax).nullable().default(null),
  opponent: z.string().max(Limits.opponentMax).nullable().default(null),
  homeAway: z.enum(homeAwayValues).nullable().default(null),
  rsvpEnabled: z.boolean().default(true),
  reminderOffsets: z
    .array(z.number().int().refine((o) => (REMINDER_OFFSETS_MINUTES as readonly number[]).includes(o)))
    .max(Limits.eventRemindersMax)
    .refine((a) => new Set(a).size === a.length)
    .default([]),
  notifyTeam: z.boolean().default(true),
  postToChat: z.boolean().default(true),
});

const timedOk = (t: { allDay: boolean; startTime: string | null; endTime: string | null }) =>
  t.allDay || (t.startTime !== null && t.endTime !== null);

const Template = TemplateShape.refine(timedOk);
/** "This event" may also move the event to another date. */
const TemplateWithDate = TemplateShape.extend({ date: DateString.optional() }).refine(timedOk);

const RecurrenceSchema = z
  .object({
    freq: z.enum(['daily', 'weekly']),
    interval: z.number().int().min(1).max(Limits.seriesIntervalMax),
    byWeekday: z.array(z.number().int().min(1).max(7)).max(7).default([]),
    startDate: DateString,
    untilDate: DateString.nullable().default(null),
    count: z.number().int().min(1).max(Limits.seriesEventsMax).nullable().default(null),
    skipDates: z.array(DateString).max(Limits.seriesSkipDatesMax).default([]),
  })
  .refine((r) => (r.untilDate === null) !== (r.count === null))
  .refine((r) => r.freq === 'daily' || r.byWeekday.length > 0)
  .refine((r) => r.untilDate === null || r.untilDate >= r.startDate);

const Id = z.string().min(1).max(64);
const Scope = z.enum(['this', 'following']);

export const SaveSeriesInput = z.discriminatedUnion('action', [
  z.object({ action: z.literal('create'), groupId: Id, recurrence: RecurrenceSchema, template: Template, dryRun: z.boolean().default(false) }),
  z.object({
    action: z.literal('update'),
    eventId: Id,
    scope: Scope,
    template: TemplateWithDate,
    recurrence: RecurrenceSchema.optional(),
    dryRun: z.boolean().default(false),
  }),
  z.object({ action: z.literal('cancel'), eventId: Id, scope: Scope, dryRun: z.boolean().default(false) }),
  z.object({ action: z.literal('delete'), eventId: Id, scope: Scope, dryRun: z.boolean().default(false) }),
]);
export type SaveSeriesInput = z.infer<typeof SaveSeriesInput>;
type TemplateInput = z.infer<typeof Template>;

/** What saveEventSeries returns (and a dry run would do). */
export interface SeriesResult {
  /** '' for a dry-run create, which makes no series. */
  seriesId: string;
  created: number;
  updated: number;
  removed: number;
  removedRsvps: number;
  canceled: number;
}

export interface Caller {
  uid: string;
  superAdmin: boolean;
}

// ---- Event fields from a template -----------------------------------------

/** Template fields copied onto each event as they are. */
const DIRECT_FIELDS = [
  'type',
  'title',
  'description',
  'location',
  'arriveMinutesBefore',
  'opponent',
  'homeAway',
  'rsvpEnabled',
  'reminderOffsets',
] as const;

/** The time fields; "This event" time edits mark them all with 'startAt'. */
const TIME_FIELDS = ['allDay', 'startAt', 'endAt', 'startDate', 'endDate', 'timeZone'] as const;
const TIME_OVERRIDE = 'startAt';

/** Game fields only on games, and no times on all-day events (SCHED-3). */
export function normalizeTemplate<T extends TemplateInput>(t: T): T {
  const game = t.type === 'game';
  return {
    ...t,
    title: t.title.trim(),
    location: t.location ? { name: t.location.name.trim(), address: t.location.address.trim() } : null,
    startTime: t.allDay ? null : t.startTime,
    endTime: t.allDay ? null : t.endTime,
    arriveMinutesBefore: game ? t.arriveMinutesBefore : null,
    opponent: game ? (t.opponent?.trim() ?? null) : null,
    homeAway: game ? t.homeAway : null,
    reminderOffsets: [...t.reminderOffsets].sort((a, b) => a - b),
  };
}

/** The series doc's template: the input minus any date. */
function storedTemplate(t: TemplateInput): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const k of Object.keys(TemplateShape.shape)) out[k] = (t as Record<string, unknown>)[k];
  return out;
}

/** An event's own fields for [occ] (ARCH §6.2 events). */
function eventFields(t: TemplateInput, occ: Occurrence): Record<string, unknown> {
  return {
    type: t.type,
    title: t.title,
    description: t.description,
    location: t.location,
    arriveMinutesBefore: t.arriveMinutesBefore,
    opponent: t.opponent,
    homeAway: t.homeAway,
    rsvpEnabled: t.rsvpEnabled,
    reminderOffsets: t.reminderOffsets,
    allDay: t.allDay,
    startAt: Timestamp.fromMillis(occ.startMs),
    endAt: Timestamp.fromMillis(occ.endMs),
    startDate: occ.startDate,
    endDate: occ.endDate,
    timeZone: t.timeZone,
  };
}

/** [fields] minus the ones the event changed with "This event" (SCHED-6). */
function withoutOverrides(fields: Record<string, unknown>, overrides: string[]): Record<string, unknown> {
  const out = { ...fields };
  for (const k of overrides) {
    if (k === TIME_OVERRIDE) TIME_FIELDS.forEach((f) => delete out[f]);
    else delete out[k];
  }
  return out;
}

/** With reminders computed, as the events trigger would (it skips series events). */
function withReminder(data: Record<string, unknown>, nowMs: number): Record<string, unknown> {
  const next = nextReminderAtMs(eventView(data), nowMs);
  return { ...data, nextReminderAt: next === null ? null : Timestamp.fromMillis(next) };
}

/** The occurrence's date: seriesDate, or the date it starts in its zone. */
function seriesDateOf(d: DocumentData): string {
  if (typeof d.seriesDate === 'string') return d.seriesDate;
  if (d.allDay && typeof d.startDate === 'string') return d.startDate;
  return dateInZone((d.startAt as Timestamp).toMillis(), String(d.timeZone ?? 'UTC'));
}

/** The date an event is on now (it may have moved off its series date). */
function currentDateOf(d: DocumentData): string {
  if (d.allDay && typeof d.startDate === 'string') return d.startDate;
  return dateInZone((d.startAt as Timestamp).toMillis(), String(d.timeZone ?? 'UTC'));
}

function startMsOf(d: DocumentData): number {
  return d.startAt instanceof Timestamp ? d.startAt.toMillis() : 0;
}

// ---- Team checks (mirror the rules: isMember, active, Q12, STORE-4) -------

interface TeamContext {
  group: DocumentSnapshot;
  memberName: string;
  isMember: boolean;
  isAdmin: boolean;
  membersCanCreate: boolean;
  rsvpFor: 'members' | 'players';
}

async function teamContext(groupId: string, caller: Caller): Promise<TeamContext> {
  const [group, member] = await Promise.all([
    db().collection(Collections.groups).doc(groupId).get(),
    db().collection(Collections.groupMembers).doc(groupMemberId(groupId, caller.uid)).get(),
  ]);
  if (!group.exists) throw new HttpsError('not-found', 'team-not-found');
  // Archived teams are read-only (TEAM-9); suspended ones are closed.
  if (group.get('archivedAt')) throw new HttpsError('failed-precondition', 'team-archived');
  if (group.get('suspendedAt')) throw new HttpsError('failed-precondition', 'team-suspended');
  if (!member.exists && !caller.superAdmin) throw new HttpsError('permission-denied', 'Members only.');
  const role = member.exists ? String(member.get('role')) : null;
  return {
    group,
    memberName: member.exists ? String(member.get('displayName') ?? '') : '',
    isMember: member.exists,
    isAdmin: caller.superAdmin || role === 'owner' || role === 'admin',
    membersCanCreate: group.get('settings.membersCanCreateEvents') === true,
    rsvpFor: group.get('teamType') === 'youth' ? 'players' : 'members',
  };
}

/** STORE-4: a full team can't schedule new events (the rules' hasRoom). */
function requireRoom(group: DocumentSnapshot): void {
  const bytes = Number(group.get('storageBytes') ?? 0);
  if (!(bytes < quotaBytesOf(group.data()))) throw new HttpsError('failed-precondition', 'storage-full');
}

/** Writes in batches of at most 400. */
async function commitAll(writes: ((b: WriteBatch) => void)[]): Promise<void> {
  for (const part of chunk(writes, 400)) {
    const batch = db().batch();
    part.forEach((w) => w(batch));
    await batch.commit();
  }
}

function autoId(): string {
  return db().collection(Collections.events).doc().id;
}

const events = () => db().collection(Collections.events);

// ---- The actions ----------------------------------------------------------

/** Runs one saveEventSeries call (ARCH §6.4). */
export async function saveSeries(input: SaveSeriesInput, caller: Caller, nowMs = Date.now()): Promise<SeriesResult> {
  if (input.action === 'create') return createSeries(input, caller, nowMs);
  const target = await events().doc(input.eventId).get();
  if (!target.exists) throw new HttpsError('not-found', 'event-not-found');
  const seriesId = target.get('seriesId') as string | null | undefined;
  if (!seriesId) throw new HttpsError('failed-precondition', 'not-in-series');
  const series = await db().collection(Collections.eventSeries).doc(seriesId).get();
  if (!series.exists) throw new HttpsError('not-found', 'series-not-found');
  const ctx = await teamContext(String(target.get('groupId')), caller);
  const isCreator = series.get('createdBy') === caller.uid && ctx.isMember;
  // SCHED-6: admins, or the series' creator while members may create events.
  if (!ctx.isAdmin && !(isCreator && ctx.membersCanCreate)) {
    throw new HttpsError('permission-denied', 'Only team admins can change this series.');
  }
  const run = { target, series, ctx, caller, nowMs };
  const result =
    input.action === 'update'
      ? input.scope === 'this'
        ? await updateThis(run, normalizeTemplate(input.template), input.dryRun)
        : await updateFollowing(run, normalizeTemplate(input.template), input.recurrence, input.dryRun)
      : input.action === 'cancel'
        ? await cancelEvents(run, input.scope, input.dryRun)
        : await deleteEvents(run, input.scope, input.dryRun);
  // Admins canceling or deleting someone else's events go in the audit log (ADMIN-6).
  if (!input.dryRun && !isCreator && (input.action === 'cancel' || input.action === 'delete')) {
    await audit({
      actorId: caller.uid,
      action: input.action === 'cancel' ? 'cancelEventSeries' : 'deleteEventSeries',
      groupId: String(target.get('groupId')),
      targetType: 'event',
      targetId: target.id,
      before: { seriesId, scope: input.scope, createdBy: series.get('createdBy') ?? null },
      after: { canceled: result.canceled, removed: result.removed },
    });
  }
  return result;
}

interface Run {
  target: DocumentSnapshot;
  series: DocumentSnapshot;
  ctx: TeamContext;
  caller: Caller;
  nowMs: number;
}

const emptyResult = (seriesId: string): SeriesResult => ({
  seriesId,
  created: 0,
  updated: 0,
  removed: 0,
  removedRsvps: 0,
  canceled: 0,
});

/** A new event doc of [seriesId] on [date]. */
function newSeriesEvent(
  groupId: string,
  t: TemplateInput,
  occ: Occurrence,
  extra: { seriesId: string; rsvpFor: string; createdBy: string; messageId: string | null },
  nowMs: number,
): Record<string, unknown> {
  const now = Timestamp.fromMillis(nowMs);
  return withReminder(
    {
      groupId,
      ...eventFields(t, occ),
      notifyTeam: t.notifyTeam,
      postToChat: t.postToChat,
      rsvpFor: extra.rsvpFor,
      rsvpDeadline: null,
      seriesId: extra.seriesId,
      seriesDate: occ.date,
      seriesOverrides: [],
      rsvpCounts: ZERO_COUNTS,
      staffCounts: ZERO_COUNTS,
      messageId: extra.messageId,
      canceledAt: null,
      canceledBy: null,
      createdBy: extra.createdBy,
      createdAt: now,
      updatedAt: now,
    },
    nowMs,
  );
}

/**
 * Creates a series and its events (SCHED-3), with one chat card and one
 * eventCreated for the whole series.
 */
async function createSeries(
  input: Extract<SaveSeriesInput, { action: 'create' }>,
  caller: Caller,
  nowMs: number,
): Promise<SeriesResult> {
  const ctx = await teamContext(input.groupId, caller);
  if (!ctx.isAdmin && !(ctx.isMember && ctx.membersCanCreate)) {
    throw new HttpsError('permission-denied', 'Only team admins can create events.');
  }
  requireRoom(ctx.group);
  const template = normalizeTemplate(input.template);
  const recurrence = input.recurrence as Recurrence;
  const dates = expandDates(recurrence);
  if (!dates.length) throw new HttpsError('invalid-argument', 'no-dates');
  if (input.dryRun) return { ...emptyResult(''), created: dates.length };

  const seriesRef = db().collection(Collections.eventSeries).doc();
  const seriesId = seriesRef.id;
  const now = Timestamp.fromMillis(nowMs);
  const messageId = template.postToChat ? seriesId : null;
  const created = dates.map((date) => ({
    ref: events().doc(),
    data: newSeriesEvent(
      input.groupId,
      template,
      occurrenceOn(date, template),
      { seriesId, rsvpFor: ctx.rsvpFor, createdBy: caller.uid, messageId },
      nowMs,
    ),
  }));
  await seriesRef.set({
    groupId: input.groupId,
    timeZone: template.timeZone,
    recurrence,
    template: storedTemplate(template),
    createdBy: caller.uid,
    createdAt: now,
    updatedAt: now,
  });
  await commitAll(created.map((e) => (b) => b.set(e.ref, e.data)));

  // The card and notification open the first event still ahead.
  const first = created.find((e) => startMsOf(e.data) >= nowMs) ?? created[0];
  const summary = seriesSummary(recurrence, template, dates);
  if (messageId) {
    await postEventCard({
      messageId,
      groupId: input.groupId,
      authorId: caller.uid,
      text: `${template.title} · ${summary}`,
      eventId: first.ref.id,
      seriesId,
    });
  }
  if (template.notifyTeam) {
    await trySend({
      kind: 'eventCreated',
      groupId: input.groupId,
      recipients: { members: true },
      actor: { uid: caller.uid, name: ctx.memberName },
      target: { type: 'event', id: first.ref.id },
      route: eventRoute(input.groupId, first.ref.id),
      params: { title: template.title },
      body: seriesCreatedBody(template.title, summary),
      dedupeKey: `${seriesId}_created`,
    });
  }
  return { ...emptyResult(seriesId), created: created.length };
}

/**
 * "This event" (SCHED-6): changes only that event, which stays in the
 * series; the fields it changed go in seriesOverrides so later series
 * edits leave them alone.
 */
async function updateThis(
  run: Run,
  template: z.infer<typeof TemplateWithDate>,
  dryRun: boolean,
): Promise<SeriesResult> {
  const { target, nowMs } = run;
  const cur = target.data()!;
  const seriesId = String(cur.seriesId);
  const date = template.date ?? currentDateOf(cur);
  const fields = eventFields(template, occurrenceOn(date, template));
  const overrides = new Set<string>((cur.seriesOverrides as string[] | undefined) ?? []);
  for (const k of DIRECT_FIELDS) if (changedFields({ v: cur[k] ?? null }, { v: fields[k] }).length) overrides.add(k);
  const timeChanged = TIME_FIELDS.some((k) => changedFields({ v: cur[k] ?? null }, { v: fields[k] }).length > 0);
  if (timeChanged) overrides.add(TIME_OVERRIDE);
  const result = { ...emptyResult(seriesId), updated: 1 };
  if (dryRun) return result;

  const updates = withReminder(
    { ...cur, ...fields, seriesOverrides: [...overrides].sort(), updatedAt: Timestamp.fromMillis(nowMs) },
    nowMs,
  );
  const changes: Record<string, unknown> = { ...fields, seriesOverrides: updates.seriesOverrides, updatedAt: updates.updatedAt, nextReminderAt: updates.nextReminderAt };
  await target.ref.update(changes);
  if (timeChanged) await refreshRsvpStartTimes(new Map([[target.id, fields.startAt as Timestamp]]));
  const before = eventView(cur);
  const after = eventView(updates);
  const line = eventChangedBody(before, after);
  if (line) {
    await notifyEventAudience({
      kind: 'eventChanged',
      groupId: String(cur.groupId),
      eventId: target.id,
      event: after,
      mode: 'change',
      line: (names) => withPlayers(names, line),
      actor: { uid: run.caller.uid, name: run.ctx.memberName },
      dedupeKey: `${target.id}_changed_${autoId()}`,
    });
  }
  return result;
}

/** All of a series' events, in order (index seriesId + startAt). */
async function seriesEvents(seriesId: string): Promise<FirebaseFirestore.QueryDocumentSnapshot[]> {
  const snap = await events().where('seriesId', '==', seriesId).orderBy('startAt').get();
  return snap.docs;
}

/**
 * "This and following" (SCHED-6): the old series ends the day before this
 * event, and a new one starts on its date with the new rule and template.
 * Upcoming events on dates the new rule still produces keep their docs and
 * RSVPs (fields updated, except their own overrides); the others go with
 * their RSVPs; new dates get new events. Past events are never touched.
 * When nothing of the series comes before this event, the series itself
 * is updated instead of split.
 */
async function updateFollowing(
  run: Run,
  template: TemplateInput,
  input: Recurrence | undefined,
  dryRun: boolean,
): Promise<SeriesResult> {
  const { target, series, ctx, caller, nowMs } = run;
  const groupId = String(target.get('groupId'));
  const oldId = series.id;
  const from = seriesDateOf(target.data()!);
  const old = series.get('recurrence') as Recurrence;
  const all = await seriesEvents(oldId);
  const affected = all.filter((e) => seriesDateOf(e.data()) >= from && startMsOf(e.data()) >= nowMs);
  const recurrence: Recurrence = input
    ? { ...input, startDate: from }
    : {
        ...old,
        startDate: from,
        // A series that ends after N events keeps the rest of them.
        count: old.count === null ? null : Math.max(1, old.count - expandDates(old).filter((d) => d < from).length),
      };
  const dates = expandDates(recurrence);
  if (!dates.length) throw new HttpsError('invalid-argument', 'no-dates');
  const split = all.some((e) => seriesDateOf(e.data()) < from);
  const newId = split ? db().collection(Collections.eventSeries).doc().id : oldId;

  const byDate = new Map(affected.map((e) => [seriesDateOf(e.data()), e]));
  const keep = new Set(dates);
  const updates: { doc: FirebaseFirestore.QueryDocumentSnapshot; data: Record<string, unknown> }[] = [];
  const creates: Record<string, unknown>[] = [];
  const messageId = (target.get('messageId') as string | null | undefined) ?? null;
  let changed = false;
  const now = Timestamp.fromMillis(nowMs);
  for (const date of dates) {
    const occ = occurrenceOn(date, template);
    const existing = byDate.get(date);
    if (existing) {
      const cur = existing.data();
      const fields = withoutOverrides(eventFields(template, occ), (cur.seriesOverrides as string[] | undefined) ?? []);
      const next = withReminder({ ...cur, ...fields, notifyTeam: template.notifyTeam, postToChat: template.postToChat, seriesId: newId, updatedAt: now }, nowMs);
      if (timeOrPlaceChanged(eventView(cur), eventView(next))) changed = true;
      updates.push({ doc: existing, data: next });
    } else if (occ.startMs >= nowMs) {
      creates.push(
        newSeriesEvent(
          groupId,
          template,
          occ,
          { seriesId: newId, rsvpFor: String(target.get('rsvpFor') ?? ctx.rsvpFor), createdBy: String(series.get('createdBy') ?? caller.uid), messageId },
          nowMs,
        ),
      );
    }
  }
  const removed = affected.filter((e) => !keep.has(seriesDateOf(e.data())));
  if (creates.length) requireRoom(ctx.group);
  const removedRsvps = await countEventRsvps(removed.map((e) => e.id));
  const result: SeriesResult = {
    seriesId: newId,
    created: creates.length,
    updated: updates.length,
    removed: removed.length,
    removedRsvps,
    canceled: 0,
  };
  if (dryRun) return result;

  const seriesFields = { groupId, timeZone: template.timeZone, recurrence, template: storedTemplate(template), updatedAt: now };
  const writes: ((b: WriteBatch) => void)[] = [];
  if (split) {
    writes.push((b) =>
      b.update(series.ref, { 'recurrence.untilDate': addDays(from, -1), 'recurrence.count': null, updatedAt: now }),
    );
    writes.push((b) =>
      b.set(db().collection(Collections.eventSeries).doc(newId), {
        ...seriesFields,
        createdBy: series.get('createdBy') ?? caller.uid,
        createdAt: now,
      }),
    );
  } else {
    writes.push((b) => b.update(series.ref, seriesFields));
  }
  for (const u of updates) {
    // The counts belong to the RSVP trigger.
    const data = { ...u.data };
    delete data.rsvpCounts;
    delete data.staffCounts;
    writes.push((b) => b.update(u.doc.ref, data));
  }
  const createdRefs = creates.map((data) => ({ ref: events().doc(), data }));
  createdRefs.forEach((c) => writes.push((b) => b.set(c.ref, c.data)));
  removed.forEach((e) => writes.push((b) => b.delete(e.ref)));
  await commitAll(writes);
  await deleteEventRsvps(removed.map((e) => e.id));
  const moved = new Map(
    updates
      .filter((u) => changedFields({ v: u.doc.get('startAt') }, { v: u.data.startAt }).length > 0)
      .map((u) => [u.doc.id, u.data.startAt as Timestamp]),
  );
  if (moved.size) await refreshRsvpStartTimes(moved);

  // One notification for the whole change (SCHED-6), when the dates,
  // times, or places changed.
  const upcoming = [...updates.map((u) => ({ id: u.doc.id, data: u.data })), ...createdRefs.map((c) => ({ id: c.ref.id, data: c.data }))].sort(
    (a, b) => startMsOf(a.data) - startMsOf(b.data),
  );
  if ((changed || creates.length || removed.length) && upcoming.length) {
    const summary = seriesSummary(
      recurrence,
      template,
      upcoming.map((u) => String(u.data.seriesDate)).sort(),
    );
    await trySend({
      kind: 'eventChanged',
      groupId,
      recipients: { members: true },
      actor: { uid: caller.uid, name: ctx.memberName },
      target: { type: 'event', id: upcoming[0].id },
      route: eventRoute(groupId, upcoming[0].id),
      params: { title: template.title },
      body: seriesChangedBody(template.title, summary),
      dedupeKey: `${newId}_changed_${autoId()}`,
    });
  }
  return result;
}

/**
 * Cancels this event, or this and every later upcoming one (SCHED-7): they
 * stay on the schedule as Canceled, RSVPs close, and the team hears once.
 */
async function cancelEvents(run: Run, scope: 'this' | 'following', dryRun: boolean): Promise<SeriesResult> {
  const { target, series, ctx, caller, nowMs } = run;
  const groupId = String(target.get('groupId'));
  const from = seriesDateOf(target.data()!);
  const targets =
    scope === 'this'
      ? target.get('canceledAt')
        ? []
        : [target]
      : (await seriesEvents(series.id)).filter(
          (e) => seriesDateOf(e.data()) >= from && startMsOf(e.data()) >= nowMs && !e.get('canceledAt'),
        );
  const result = { ...emptyResult(series.id), canceled: targets.length };
  if (dryRun || !targets.length) return result;

  const now = Timestamp.fromMillis(nowMs);
  await commitAll(
    targets.map((e) => (b) => b.update(e.ref, { canceledAt: now, canceledBy: caller.uid, nextReminderAt: null, updatedAt: now })),
  );
  const first = eventView({ ...targets[0].data()!, canceledAt: now });
  const actor = { uid: caller.uid, name: ctx.memberName };
  if (targets.length === 1) {
    // One event: everyone but Not going, guardians named per player.
    const line = eventCanceledBody(first);
    await notifyEventAudience({
      kind: 'eventChanged',
      groupId,
      eventId: targets[0].id,
      event: first,
      mode: 'change',
      line: (names) => withPlayers(names, line),
      actor,
      dedupeKey: `${targets[0].id}_canceled`,
    });
  } else {
    await trySend({
      kind: 'eventChanged',
      groupId,
      recipients: { members: true },
      actor,
      target: { type: 'event', id: targets[0].id },
      route: eventRoute(groupId, targets[0].id),
      params: { title: first.title },
      body: seriesCanceledBody(first, targets.length),
      dedupeKey: `${targets[0].id}_canceled_${targets.length}`,
    });
  }
  return result;
}

/**
 * Deletes this event, or this and every later upcoming one, with their
 * RSVPs and no notification (SCHED-7). Deleting one event skips its date
 * in the series, so a later "this and following" edit doesn't bring it
 * back; deleting the rest ends the series the day before.
 */
async function deleteEvents(run: Run, scope: 'this' | 'following', dryRun: boolean): Promise<SeriesResult> {
  const { target, series, nowMs } = run;
  const from = seriesDateOf(target.data()!);
  const all = scope === 'this' ? [] : await seriesEvents(series.id);
  const targets =
    scope === 'this' ? [target] : all.filter((e) => seriesDateOf(e.data()) >= from && startMsOf(e.data()) >= nowMs);
  const removedRsvps = await countEventRsvps(targets.map((e) => e.id));
  const result = { ...emptyResult(series.id), removed: targets.length, removedRsvps };
  if (dryRun || !targets.length) return result;

  const now = Timestamp.fromMillis(nowMs);
  await commitAll(targets.map((e) => (b) => b.delete(e.ref)));
  await deleteEventRsvps(targets.map((e) => e.id));
  if (scope === 'this') {
    const skips = (series.get('recurrence.skipDates') as string[] | undefined) ?? [];
    if (skips.length < Limits.seriesSkipDatesMax) {
      await series.ref.update({ 'recurrence.skipDates': FieldValue.arrayUnion(from), updatedAt: now });
    }
  } else if (all.length === targets.length) {
    await series.ref.delete();
  } else {
    await series.ref.update({ 'recurrence.untilDate': addDays(from, -1), 'recurrence.count': null, updatedAt: now });
  }
  return result;
}
