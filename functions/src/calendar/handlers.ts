// Thin entry points for calendar links (SPEC SCHED-11, ARCH §6.15).
import { logger } from 'firebase-functions/v2';
import { onRequest } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { onCall } from '../shared/callable.js';
import { requireAuth } from '../shared/guards.js';
import { parse } from '../shared/validate.js';
import { calendarFeed as feedFor, setCalendarLink as setLink } from './service.js';

const SetCalendarLinkInput = z.object({
  groupId: z.string().min(1).max(128).nullable(),
  action: z.enum(['make', 'reset', 'off']),
});

/**
 * The caller's calendar link for one team (they must be on it) or for all
 * their teams (`groupId` null): `make` returns it, making it the first
 * time; `reset` replaces it, so calendars on the old one stop updating;
 * `off` removes it. Returns `{ token }`, null once it's off; the app builds
 * the URLs from the token.
 */
export const setCalendarLink = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = parse(SetCalendarLinkInput, request.data);
  return setLink(uid, input.groupId, input.action);
});

/**
 * `/cal/<token>.ics` (Hosting rewrites it here): the link's calendar,
 * read by Google, Apple, and Outlook Calendar on their own schedules. No
 * sign-in, and no App Check: the token in the link is the key (D66).
 */
export const calendarFeed = onRequest({ invoker: 'public' }, async (req, res) => {
  res.set('X-Robots-Tag', 'noindex');
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    res.set('Allow', 'GET, HEAD').status(405).type('text/plain').send('Only GET.');
    return;
  }
  try {
    const out = await feedFor(req.path);
    res.set('Cache-Control', 'private, max-age=300');
    if (out.status !== 200) {
      res.status(out.status).type('text/plain').send(out.body);
      return;
    }
    res
      .status(200)
      .set('Content-Type', 'text/calendar; charset=utf-8')
      .set('Content-Disposition', `inline; filename="${out.filename}"`)
      .send(req.method === 'HEAD' ? '' : out.body);
  } catch (e) {
    logger.error('calendar_feed_failed', { error: String(e) });
    res.status(500).type('text/plain').send('Something went wrong. Your calendar will try again.');
  }
});
