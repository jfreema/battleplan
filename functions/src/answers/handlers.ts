// Thin entry points for answering from an email (SPEC SCHED-14, ARCH §6.15).
import { logger } from 'firebase-functions/v2';
import { onRequest } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { resendApiKey } from '../email/service.js';
import { onCall } from '../shared/callable.js';
import { requireAuth } from '../shared/guards.js';
import { parse } from '../shared/validate.js';
import { answerPage as pageFor, emailRsvpReminder as emailReminder } from './service.js';

const EmailRsvpReminderInput = z.object({
  eventId: z.string().min(1).max(128),
  dryRun: z.boolean().default(false),
});

/**
 * "Email people who haven't RSVP'd" (SCHED-14): emails everyone linked to
 * a player with no answer on the event, with a link for each answer. Team
 * admins and the event's creator; once an hour per event. With dryRun it
 * only counts, for the app's question. Returns { people, players,
 * unreachable, failed }.
 */
export const emailRsvpReminder = onCall({ secrets: [resendApiKey] }, async (request) => {
  const uid = requireAuth(request);
  const input = parse(EmailRsvpReminderInput, request.data);
  return emailReminder(input.eventId, { uid, superAdmin: request.auth?.token.superAdmin === true }, input.dryRun);
});

/**
 * `/a/<token>` (Hosting rewrites it here): the page an RSVP email's answer
 * links open. GET shows the answer picked and Send; only the POST answers,
 * since email services open links to check them (D67). No sign-in: the
 * token in the link is the key.
 */
export const answerPage = onRequest({ invoker: 'public' }, async (req, res) => {
  res.set('Cache-Control', 'no-store');
  res.set('X-Robots-Tag', 'noindex');
  // The token is in the address: links on the page don't pass it along.
  res.set('Referrer-Policy', 'no-referrer');
  res.set(
    'Content-Security-Policy',
    "default-src 'none'; style-src 'unsafe-inline'; form-action 'self'; base-uri 'none'; frame-ancestors 'none'",
  );
  if (req.method !== 'GET' && req.method !== 'HEAD' && req.method !== 'POST') {
    res.set('Allow', 'GET, POST').status(405).type('text/plain').send('Only GET or POST.');
    return;
  }
  try {
    const form = req.body && typeof req.body === 'object' ? (req.body as Record<string, unknown>) : {};
    const out = await pageFor(req.path, req.method, req.query as Record<string, unknown>, form);
    res.status(out.status).type('text/html; charset=utf-8').send(req.method === 'HEAD' ? '' : out.html);
  } catch (e) {
    logger.error('answer_page_failed', { error: String(e) });
    res.status(500).type('text/plain').send('Something went wrong. Try again in a minute.');
  }
});
