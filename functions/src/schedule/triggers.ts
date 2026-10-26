// Schedule triggers (ARCH §6.4 trigger map).
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { calendarChanged, markTeamCalendarChanged } from '../calendar/service.js';
import { followUpEventWrite, recountEventRsvps, rsvpCountChanged } from './service.js';

/**
 * events written → for one-off events: the chat card and eventCreated on
 * create, eventChanged on a time or place change or a cancel, and
 * nextReminderAt on any change; the RSVPs and assignments on delete.
 * Exits early for changes only Functions make and for series events
 * (saveEventSeries follows those up itself). A change calendar links print
 * marks the team's cached calendar (SCHED-11).
 */
export const onEventWritten = onDocumentWritten('events/{eventId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  const groupId = (after?.groupId ?? before?.groupId) as string | undefined;
  await Promise.all([
    followUpEventWrite(event.params.eventId, before, after),
    groupId && calendarChanged(event.params.eventId, before, after) ? markTeamCalendarChanged(groupId) : null,
  ]);
});

/**
 * rsvps written → the event's rsvpCounts and staffCounts (SCHED-1,
 * PLAYER-6). Exits early when the answer didn't change (a moved event's
 * eventStartAt, a renamed player).
 */
export const onRsvpWritten = onDocumentWritten('rsvps/{rsvpId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!rsvpCountChanged(before, after)) return;
  const eventId = (after?.eventId ?? before?.eventId) as string | undefined;
  if (typeof eventId === 'string' && eventId) await recountEventRsvps(eventId);
});
