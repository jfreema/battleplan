// A shared play's page (SPEC BOARD-6, ARCH §6.14): what messaging apps read
// for the link's preview, the play's name and a picture of it in Open Graph
// tags. People's browsers never get it: they go straight on to the app's
// /p page, which draws the play step by step. Pure functions, so the
// wording can be tested without Firestore.
import { escapeHtml } from '../email/service.js';

/** A shared play, as its preview shows it. */
export interface PlayCard {
  title: string;
  note: string;
  board: string;
  steps: number;
  /** A picture of its last step is kept for the preview. */
  hasImage: boolean;
}

const BOARD_NAMES: Record<string, string> = {
  baseball: 'baseball diamond',
  basketball: 'basketball court',
  soccer: 'soccer field',
  football: 'football field',
  blank: 'whiteboard',
};

/** The preview's title: the play, or any play for a link that doesn't work. */
export function playTitle(card: PlayCard | null): string {
  return card ? `${card.title} · a play on Battleplan` : 'A play on Battleplan';
}

/** The preview's line under the title: the coach's note, or what the play is. */
export function playDescription(card: PlayCard | null): string {
  if (!card) return 'Plays drawn step by step on Battleplan, the team app.';
  const note = card.note.trim().replace(/\s+/g, ' ');
  if (note) return note.length > 200 ? `${note.slice(0, 199)}…` : note;
  const board = BOARD_NAMES[card.board] ?? 'whiteboard';
  return card.steps > 1
    ? `${card.steps} steps on a ${board}. Open it to watch it play out.`
    : `Drawn on a ${board}. Open it to see the play.`;
}

/**
 * The page for [card] (null for a link that doesn't work now): its tags for
 * the preview, and a link on to the play at [appPlayUrl] for anyone who
 * sees it. [playUrl] is the link itself, [imageUrl] its picture, and
 * [siteImage] the website's 1200 × 630 card, for a play without one.
 */
export function playPreviewPage(
  card: PlayCard | null,
  urls: { playUrl: string; appPlayUrl: string; imageUrl: string; siteImage: string },
): string {
  const title = playTitle(card);
  const description = playDescription(card);
  const image = card?.hasImage ? urls.imageUrl : null;
  const property = (name: string, content: string) =>
    `<meta property="${name}" content="${escapeHtml(content)}">`;
  const named = (name: string, content: string) => `<meta name="${name}" content="${escapeHtml(content)}">`;
  const tags = [
    property('og:type', 'website'),
    property('og:site_name', 'Battleplan'),
    property('og:title', title),
    property('og:description', description),
    property('og:url', urls.playUrl),
    property('og:image', image ?? urls.siteImage),
    ...(image
      ? [property('og:image:alt', `The play ${card?.title ?? ''}`.trim())]
      : [property('og:image:width', '1200'), property('og:image:height', '630')]),
    named('twitter:card', 'summary_large_image'),
    named('description', description),
  ];
  return (
    '<!doctype html><html lang="en"><head><meta charset="utf-8">' +
    '<meta name="viewport" content="width=device-width,initial-scale=1">' +
    '<meta name="robots" content="noindex">' +
    `<title>${escapeHtml(title)}</title>${tags.join('')}</head>` +
    `<body><h1>${escapeHtml(title)}</h1><p>${escapeHtml(description)}</p>` +
    `<p><a href="${escapeHtml(urls.appPlayUrl)}">Open the play</a></p></body></html>`
  );
}
