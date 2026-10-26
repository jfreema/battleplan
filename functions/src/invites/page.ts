// The page messaging apps read for an invite link's preview (ARCH §6.6,
// ROADMAP task 140): "Join Thunder U14 on Battleplan" with the team's logo,
// in Open Graph and Twitter card tags. People's browsers never get it: they
// go straight on to the app's /join page. Pure functions, so the wording can
// be tested without Firestore.
import { escapeHtml } from '../email/service.js';

/** The team an invite link joins, as its preview shows it. */
export interface InviteCard {
  teamName: string;
  /** The team's logo, public to anyone with the address; null for none. */
  logoUrl: string | null;
  invitedBy: string | null;
}

/**
 * What link previews are fetched with: Facebook and Messenger, iMessage
 * (which sends Facebook's and X's names), WhatsApp, Slack, Discord,
 * Telegram, LinkedIn, X, Teams, Google Chat, Bluesky, Mastodon, and the
 * unfurling services. In-app browsers (Snapchat's, KakaoTalk's) are people.
 */
const PREVIEW_FETCHERS =
  /facebookexternalhit|facebot|twitterbot|slackbot|slack-imgproxy|discordbot|telegrambot|whatsapp|linkedinbot|skypeuripreview|microsoftpreview|pinterest|redditbot|embedly|iframely|vkshare|kakaotalk-scrap|mastodon|cardyb|google-pagerenderer|applebot/i;

/** Whether [userAgent] is fetching a link's preview rather than a person opening it. */
export function isPreviewFetcher(userAgent: string | undefined): boolean {
  return userAgent !== undefined && PREVIEW_FETCHERS.test(userAgent);
}

/** The preview's title: the team, or any team for a code that doesn't work. */
export function inviteTitle(card: InviteCard | null): string {
  return card ? `Join ${card.teamName} on Battleplan` : 'Join your team on Battleplan';
}

/** The preview's line under the title. */
export function inviteDescription(card: InviteCard | null): string {
  return card?.invitedBy
    ? `${card.invitedBy} invited you to the team's chat, schedule, and RSVPs.`
    : "The team's chat, schedule, and RSVPs, in one app.";
}

/**
 * The page for [card] (null for a code that doesn't work now): its tags
 * for the preview, and a link on to the invite at [appJoinUrl] for anyone
 * who sees it. [joinUrl] is the link itself; [siteImage] the website's
 * 1200 × 630 card, for teams without a logo.
 */
export function invitePreviewPage(
  card: InviteCard | null,
  urls: { joinUrl: string; appJoinUrl: string; siteImage: string },
): string {
  const title = inviteTitle(card);
  const description = inviteDescription(card);
  const logo = card?.logoUrl ?? null;
  const property = (name: string, content: string) =>
    `<meta property="${name}" content="${escapeHtml(content)}">`;
  const named = (name: string, content: string) => `<meta name="${name}" content="${escapeHtml(content)}">`;
  const tags = [
    property('og:type', 'website'),
    property('og:site_name', 'Battleplan'),
    property('og:title', title),
    property('og:description', description),
    property('og:url', urls.joinUrl),
    property('og:image', logo ?? urls.siteImage),
    ...(logo
      ? [property('og:image:alt', `${card?.teamName ?? 'The team'}'s logo`)]
      : [property('og:image:width', '1200'), property('og:image:height', '630')]),
    // A logo is square: the small card. The site's image is wide.
    named('twitter:card', logo ? 'summary' : 'summary_large_image'),
    named('description', description),
  ];
  return (
    '<!doctype html><html lang="en"><head><meta charset="utf-8">' +
    '<meta name="viewport" content="width=device-width,initial-scale=1">' +
    '<meta name="robots" content="noindex">' +
    `<title>${escapeHtml(title)}</title>${tags.join('')}</head>` +
    `<body><h1>${escapeHtml(title)}</h1><p>${escapeHtml(description)}</p>` +
    `<p><a href="${escapeHtml(urls.appJoinUrl)}">Open the invite</a></p></body></html>`
  );
}
