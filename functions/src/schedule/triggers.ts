// Schedule triggers (ARCH §6.4 trigger map).
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { followUpEventWrite, recountEventRsvps, rsvpCountChanged } from './service.js';

/**
 * events written → for one-off events: the chat card and eventCreated on
 * create, eventChanged on a time or place change or a cancel, and
 * nextReminderAt on any change; the RSVPs on delete. Exits early for
 * changes only Functions make and for series events (saveEventSeries
 * follows those up itself).
 */
export const onEventWritten = onDocumentWritten('events/{eventId}', async (event) => {
  await followUpEventWrite(event.params.eventId, event.data?.before.data(), event.data?.after.data());
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
