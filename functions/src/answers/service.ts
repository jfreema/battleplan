// Answering from an email (SPEC SCHED-14, ARCH §6.15, D67): an admin's
// "Email people who haven't RSVP'd" emails everyone linked to a player
// with no answer, with a link for each answer; the link opens a page where
// Send records it. A link is a secret for one person, one event, and the
// players it names, kept hashed in `answerLinks`.
import { createHash, randomBytes } from 'node:crypto';
import { FieldValue, Timestamp, type DocumentData } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { HttpsError } from 'firebase-functions/v2/https';
import { sendEmail } from '../email/service.js';
import { rsvpReminderEmail } from '../email/templates.js';
import { appUrl, linkHost } from '../links/service.js';
import { eventRoute, eventView, locationLabel, whenLabel } from '../schedule/service.js';
import { db } from '../shared/admin.js';
import { Collections, Limits } from '../shared/constants.js';
import { groupMemberId, rsvpId } from '../shared/ids.js';
import { consumeRateLimit } from '../shared/rate_limit.js';
import { requireOpenTeam } from '../shared/roles.js';
import {
  answeredPage,
  answerFormPage,
  answerProblemPage,
  questionOf,
  type AnswerFor,
  type AnswerStatus,
  type EventLines,
} from './page.js';

const STATUSES: readonly AnswerStatus[] = ['going', 'maybe', 'not_going'];

/** A link's secret: 32 random bytes in base64url (43 characters). */
export function newAnswerToken(): string {
  return randomBytes(32).toString('base64url');
}

/** Where a token's link is kept: its SHA-256, so the database alone can't answer for anyone. */
export function answerLinkId(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

/** The token in an answer page's path: /a/<token>, or /<token> when called directly. */
export function answerToken(path: string): string | null {
  const match = /^\/(?:a\/)?([A-Za-z0-9_-]{43})\/?$/.exec(path);
  return match ? match[1] : null;
}

/** The answer page for [token], picking [status]. */
export function answerUrl(token: string, status: AnswerStatus): string {
  return `https://${linkHost()}/a/${token}?s=${status}`;
}

function msOf(v: unknown): number {
  return v instanceof Timestamp ? v.toMillis() : 0;
}

/** The first word of a name, as the roster labels players (PLAYER-8). */
function firstName(name: string): string {
  return name.trim().split(/\s+/)[0] || name;
}

/** A player an email asks about. */
export interface AskedPlayer extends AnswerFor {
  id: string;
}

/**
 * Who to email for [eventId]: everyone linked to an active player with no
 * answer yet (the player, when they're a member, and their guardians),
 * each with those players, the self player first. [excludeUid], the person
 * sending, answers in the app.
 */
export async function rsvpEmailAudience(
  groupId: string,
  eventId: string,
  excludeUid: string,
): Promise<{ people: Map<string, AskedPlayer[]>; open: number }> {
  const [players, links, rsvps] = await Promise.all([
    db().collection(Collections.players).where('groupId', '==', groupId).select('displayName', 'status').get(),
    db().collection(Collections.playerGuardians).where('groupId', '==', groupId).select('uid', 'playerId', 'relation').get(),
    db().collection(Collections.rsvps).where('eventId', '==', eventId).select('participantId').get(),
  ]);
  const answered = new Set(rsvps.docs.map((d) => String(d.get('participantId'))));
  const open = new Map(
    players.docs
      .filter((d) => d.get('status') !== 'pending' && !answered.has(d.id))
      .map((d) => [d.id, firstName(String(d.get('displayName') ?? ''))]),
  );
  const people = new Map<string, AskedPlayer[]>();
  for (const l of links.docs) {
    const playerId = String(l.get('playerId'));
    const uid = String(l.get('uid'));
    const name = open.get(playerId);
    if (name === undefined || uid === excludeUid) continue;
    people.set(uid, [...(people.get(uid) ?? []), { id: playerId, name, self: l.get('relation') === 'self' }]);
  }
  for (const list of people.values()) {
    list.sort((a, b) => Number(b.self) - Number(a.self) || a.name.localeCompare(b.name));
  }
  return { people, open: open.size };
}

export interface RsvpEmailResult {
  /** People emailed (or who would be, for a dry run). */
  people: number;
  /** Players with no answer that someone was emailed about. */
  players: number;
  /** Players with no answer and nobody linked to email. */
  unreachable: number;
  /** Emails the provider refused. */
  failed: number;
}

/**
 * "Email people who haven't RSVP'd" (SCHED-14): team admins and the
 * event's creator, on an event that takes RSVPs, isn't canceled, hasn't
 * started, and is before its deadline; once an hour per event. Each person
 * gets one email, naming their players, with a link for each answer that
 * works until the event starts or its deadline passes. [dryRun] counts
 * without sending, for the app's question.
 */
export async function emailRsvpReminder(
  eventId: string,
  caller: { uid: string; superAdmin: boolean },
  dryRun: boolean,
  nowMs = Date.now(),
): Promise<RsvpEmailResult> {
  const snap = await db().collection(Collections.events).doc(eventId).get();
  if (!snap.exists) throw new HttpsError('not-found', 'event-not-found');
  const data = snap.data()!;
  const groupId = String(data.groupId);
  const team = await requireOpenTeam(groupId, caller.superAdmin);
  const member = await db().collection(Collections.groupMembers).doc(groupMemberId(groupId, caller.uid)).get();
  const role = member.exists ? String(member.get('role')) : '';
  const isAdmin = caller.superAdmin || role === 'owner' || role === 'admin';
  if (!isAdmin && !(member.exists && data.createdBy === caller.uid)) {
    throw new HttpsError('permission-denied', 'Only team admins can email people.');
  }
  const view = eventView(data);
  const deadlineMs = msOf(data.rsvpDeadline);
  if (data.rsvpEnabled === false) throw new HttpsError('failed-precondition', 'no-rsvps');
  if (view.canceled) throw new HttpsError('failed-precondition', 'event-canceled');
  if (view.startMs <= nowMs) throw new HttpsError('failed-precondition', 'event-started');
  if (deadlineMs && deadlineMs <= nowMs) throw new HttpsError('failed-precondition', 'deadline-passed');

  const { people, open } = await rsvpEmailAudience(groupId, eventId, caller.uid);
  const users = people.size
    ? await db().getAll(...[...people.keys()].map((uid) => db().collection(Collections.users).doc(uid)))
    : [];
  const reachable = users
    .filter((u) => u.exists && u.get('status') !== 'disabled' && typeof u.get('email') === 'string' && u.get('email'))
    .slice(0, Limits.rsvpEmailPeopleMax);
  const asked = new Set(reachable.flatMap((u) => people.get(u.id)!.map((p) => p.id)));
  const result: RsvpEmailResult = { people: reachable.length, players: asked.size, unreachable: open - asked.size, failed: 0 };
  if (dryRun || !reachable.length) return result;

  await consumeRateLimit(eventId, 'eventRsvpEmail', 1, 'hour');
  const expiresAt = Timestamp.fromMillis(deadlineMs ? Math.min(deadlineMs, view.startMs) : view.startMs);
  const allowMaybe = team.get('settings.allowMaybe') !== false;
  const eventUrl = appUrl(eventRoute(groupId, eventId));
  const place = locationLabel(view.location);
  const when = whenLabel(view);
  const sentBy = String(member.get('displayName') ?? '').trim();
  const teamName = String(team.get('name') ?? '').trim();

  const batch = db().batch();
  const emails = reachable.map((u) => {
    const token = newAnswerToken();
    const asking = people.get(u.id)!;
    batch.set(db().collection(Collections.answerLinks).doc(answerLinkId(token)), {
      uid: u.id,
      groupId,
      eventId,
      participants: asking.map((p) => ({ id: p.id, name: p.name, self: p.self })),
      expiresAt,
      createdBy: caller.uid,
      createdAt: FieldValue.serverTimestamp(),
    });
    return rsvpReminderEmail({
      to: String(u.get('email')),
      team: teamName,
      title: view.title,
      when,
      place,
      question: questionOf(asking),
      going: answerUrl(token, 'going'),
      maybe: allowMaybe ? answerUrl(token, 'maybe') : null,
      notGoing: answerUrl(token, 'not_going'),
      sentBy,
      eventUrl,
    });
  });
  await batch.commit();
  for (const email of emails) {
    // The emulators log emails instead of sending them; that counts as sent.
    const sent = (await sendEmail(email)) || process.env.FUNCTIONS_EMULATOR === 'true';
    if (!sent) result.failed++;
  }
  logger.info('rsvp_email_sent', { eventId, people: result.people, failed: result.failed });
  return result;
}

// ---- The answer page ----------------------------------------------------------------

export interface PageResponse {
  status: number;
  html: string;
}

function problem(status: number, heading: string, body: string, url = appUrl('/'), label = 'Open Battleplan'): PageResponse {
  return { status, html: answerProblemPage({ heading, body, url, label }) };
}

/**
 * The answer page at [path] (GET shows the form, POST records the answer
 * from [form]): the link must still exist and be in time, the event must
 * take answers, and the person must still be linked to each player. The
 * answer is written as theirs, like an answer in the app (SCHED-5).
 */
export async function answerPage(
  path: string,
  method: string,
  query: Record<string, unknown>,
  form: Record<string, unknown>,
  nowMs = Date.now(),
): Promise<PageResponse> {
  const token = answerToken(path);
  const linkId = token ? answerLinkId(token) : null;
  const link = linkId ? await db().collection(Collections.answerLinks).doc(linkId).get() : null;
  if (!link?.exists) return problem(404, "This link doesn't work anymore", 'Open Battleplan to RSVP.');

  const groupId = String(link.get('groupId'));
  const eventId = String(link.get('eventId'));
  const uid = String(link.get('uid'));
  const eventUrl = appUrl(eventRoute(groupId, eventId));
  const tooLate = () =>
    problem(410, "It's too late to answer here", 'The event has started or RSVPs are closed.', eventUrl, 'Open in Battleplan');

  const [event, team, user] = await db().getAll(
    db().collection(Collections.events).doc(eventId),
    db().collection(Collections.groups).doc(groupId),
    db().collection(Collections.users).doc(uid),
  );
  if (!event.exists || !team.exists || team.get('archivedAt') != null || team.get('suspendedAt') != null) {
    return problem(410, "This event isn't taking answers", 'Open Battleplan to see your schedule.');
  }
  if (!user.exists || user.get('status') === 'disabled') {
    return problem(404, "This link doesn't work anymore", 'Open Battleplan to RSVP.');
  }
  const data = event.data() as DocumentData;
  const view = eventView(data);
  if (view.canceled) return problem(410, 'This event was canceled', "There's nothing to answer.", eventUrl, 'Open in Battleplan');
  const deadlineMs = msOf(data.rsvpDeadline);
  if (data.rsvpEnabled === false || nowMs >= msOf(link.get('expiresAt')) || nowMs >= view.startMs || (deadlineMs && nowMs >= deadlineMs)) {
    return tooLate();
  }

  // Only the players the person is still linked to.
  const asked = (link.get('participants') as AskedPlayer[] | undefined) ?? [];
  const checks = asked.length
    ? await db().getAll(
        ...asked.flatMap((p) => [
          db().collection(Collections.players).doc(p.id),
          db().collection(Collections.playerGuardians).doc(groupMemberId(p.id, uid)),
        ]),
      )
    : [];
  const people = asked.filter((p, i) => {
    const player = checks[2 * i];
    const linked = checks[2 * i + 1];
    return player.exists && player.get('groupId') === groupId && player.get('status') !== 'pending' && linked.exists;
  });
  if (!people.length) {
    return problem(403, "You can't answer for them anymore", 'Open Battleplan to see who you answer for.', eventUrl, 'Open in Battleplan');
  }

  const allowMaybe = team.get('settings.allowMaybe') !== false;
  const allowed = STATUSES.filter((s) => allowMaybe || s !== 'maybe');
  const lines: EventLines = {
    team: String(team.get('name') ?? ''),
    title: view.title,
    when: [whenLabel(view), locationLabel(view.location)].filter(Boolean).join(' · '),
  };
  const showForm = (picked: AnswerStatus | null, status = 200): PageResponse => ({
    status,
    html: answerFormPage({
      event: lines,
      people,
      picked,
      allowMaybe,
      answeringAs: String(user.get('displayName') ?? '').trim() || 'you',
      eventUrl,
    }),
  });

  const askedFor = (value: unknown): AnswerStatus | null =>
    typeof value === 'string' && (allowed as string[]).includes(value) ? (value as AnswerStatus) : null;
  if (method !== 'POST') return showForm(askedFor(query.s));

  const status = askedFor(form.status);
  if (!status) return showForm(null, 400);
  try {
    await consumeRateLimit(linkId!.slice(0, 32), 'answerLink', Limits.answerLinkTriesPerHour, 'hour');
  } catch {
    return problem(429, 'Too many tries', 'Wait a bit and try again.', eventUrl, 'Open in Battleplan');
  }
  const note = typeof form.note === 'string' ? form.note.trim().slice(0, Limits.rsvpNoteMax) : '';
  const batch = db().batch();
  for (const p of people) {
    const player = checks[2 * asked.indexOf(p)];
    batch.set(db().collection(Collections.rsvps).doc(rsvpId(eventId, p.id)), {
      eventId,
      groupId,
      participantType: 'player',
      participantId: p.id,
      participantName: String(player.get('displayName') ?? p.name).slice(0, 60),
      eventStartAt: data.startAt,
      status,
      note,
      guests: 0,
      respondedBy: uid,
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  return {
    status: 200,
    html: answeredPage({
      event: lines,
      people,
      status,
      changeUrl: `/a/${token}?s=${status}`,
      eventUrl,
    }),
  };
}
