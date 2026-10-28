// Thin entry points for shared plays (SPEC BOARD-6, ARCH §6.14).
import { logger } from 'firebase-functions/v2';
import { onRequest } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { isPreviewFetcher } from '../invites/page.js';
import { APP_PREFIX, linkHost, playShareUrl } from '../links/service.js';
import { onCall } from '../shared/callable.js';
import { requireAuth } from '../shared/guards.js';
import { parse } from '../shared/validate.js';
import { playPreviewPage, type PlayCard } from './page.js';
import { imageOf, sharedPlayImage, sharedPlayOf, sharePlay as share, stopSharingPlay } from './service.js';

const SharePlayInput = z.object({
  playId: z.string().min(1).max(128),
  action: z.enum(['share', 'stop']),
  // A PNG of the play's last step, base64, for link previews.
  image: z.string().max(1_400_000).nullish(),
});

/**
 * Shares one of the team's plays (`share`), by its admins and super
 * admins: returns `{ shareId }`, the same each time for the same play, and
 * the app builds the link (`/p/<shareId>`). `stop` takes the link down and
 * returns `{ shareId: null }`.
 */
export const sharePlay = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = parse(SharePlayInput, request.data);
  const superAdmin = request.auth?.token.superAdmin === true;
  if (input.action === 'stop') {
    await stopSharingPlay(uid, superAdmin, input.playId);
    return { shareId: null };
  }
  return { shareId: await share(uid, superAdmin, input.playId, imageOf(input.image)) };
});

/**
 * `/p/<shareId>` (Hosting rewrites it here): a shared play's link. Link
 * previews get its name and picture; people go on to the app's /p page,
 * which shows the play. `/p/<shareId>/image.png` is the picture. No
 * sign-in: the ID in the link is the key.
 */
export const playPage = onRequest({ invoker: 'public' }, async (req, res) => {
  res.set('X-Robots-Tag', 'noindex');
  const [shareId = '', extra = ''] = req.path.replace(/^\/p\/?/, '').split('/');
  if (extra === 'image.png') {
    const bytes = await sharedPlayImage(shareId).catch(() => null);
    if (!bytes) {
      res.status(404).type('text/plain').send('No picture.');
      return;
    }
    res.set('Cache-Control', 'public, max-age=300');
    res.status(200).type('image/png').send(req.method === 'HEAD' ? '' : bytes);
    return;
  }
  // The answer differs by who asks, so no cache may keep it for others.
  res.set('Cache-Control', 'no-store');
  res.set('Vary', 'User-Agent');
  const appPlayUrl = `${APP_PREFIX}/p/${encodeURIComponent(shareId)}`;
  if (!isPreviewFetcher(req.get('user-agent'))) {
    res.redirect(302, appPlayUrl);
    return;
  }
  let card: PlayCard | null = null;
  try {
    const play = await sharedPlayOf(shareId);
    if (play) {
      card = {
        title: String(play.title ?? ''),
        note: String(play.note ?? ''),
        board: String(play.board ?? ''),
        steps: Array.isArray(play.steps) ? play.steps.length : 1,
        hasImage: play.hasImage === true,
      };
    }
  } catch (e) {
    logger.warn('play_page_lookup_failed', { error: String(e) });
  }
  const html = playPreviewPage(card, {
    playUrl: playShareUrl(shareId),
    appPlayUrl: `https://${linkHost()}${appPlayUrl}`,
    imageUrl: `${playShareUrl(shareId)}/image.png`,
    siteImage: `https://${linkHost()}/images/og.png`,
  });
  res.status(200).type('text/html; charset=utf-8').send(req.method === 'HEAD' ? '' : html);
});
