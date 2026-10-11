// Email sending (ARCH §6.7): the only code that calls the email provider.
// Firebase Auth sends verification and password-reset emails itself.
import { defineSecret } from 'firebase-functions/params';
import { logger } from 'firebase-functions/v2';

/** The Resend API key, in Secret Manager. Callables that send declare it. */
export const resendApiKey = defineSecret('RESEND_API_KEY');

const FROM = 'Battleplan <noreply@getbattleplan.app>';
const REPLY_TO = 'support@getbattleplan.app';

export interface Email {
  to: string;
  subject: string;
  text: string;
  html: string;
}

/**
 * Sends one email. On the emulators (no key), it logs the email instead,
 * so flows can be tested locally without sending anything.
 */
export async function sendEmail(email: Email): Promise<boolean> {
  let key = '';
  try {
    key = resendApiKey.value();
  } catch {
    key = '';
  }
  if (!key || process.env.FUNCTIONS_EMULATOR === 'true') {
    logger.info('email_not_sent_emulator', { to: email.to, subject: email.subject, text: email.text });
    return false;
  }
  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ from: FROM, reply_to: REPLY_TO, ...email }),
  });
  if (!res.ok) {
    logger.error('email_send_failed', { status: res.status, body: (await res.text()).slice(0, 300) });
    return false;
  }
  return true;
}

/** Escapes text for the HTML part. */
export function escapeHtml(s: string): string {
  return s.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]!);
}

/** A plain, readable email body: a paragraph or two and one button. */
export function layout(paragraphs: string[], button?: { label: string; url: string }): { text: string; html: string } {
  const text = [...paragraphs, ...(button ? [`${button.label}: ${button.url}`] : []), '', '— Battleplan'].join('\n\n');
  const html =
    '<div style="font-family:-apple-system,Segoe UI,Roboto,sans-serif;font-size:16px;line-height:1.5;color:#1a1c22;max-width:520px">' +
    paragraphs.map((p) => `<p>${escapeHtml(p)}</p>`).join('') +
    (button
      ? `<p><a href="${escapeHtml(button.url)}" style="display:inline-block;background:#2F5BEA;color:#fff;padding:12px 20px;border-radius:999px;text-decoration:none;font-weight:600">${escapeHtml(button.label)}</a></p>`
      : '') +
    '<p style="color:#5b5f6b;font-size:14px">— Battleplan</p></div>';
  return { text, html };
}
