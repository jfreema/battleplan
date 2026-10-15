// The team language filter (SAFE-7). lib/features/safety/domain/
// strong_language.dart does the same in the app.
import { STRONG_LANGUAGE } from '../shared/constants.js';

const escape = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const LINKS = /(?:https?:\/\/|www\.)\S+/gi;

const WORDS = new RegExp(
  `(?<!\\p{L})(?:${STRONG_LANGUAGE.map((w) => (w.endsWith('*') ? `${escape(w.slice(0, -1))}\\p{L}*` : escape(w))).join('|')})(?!\\p{L})`,
  'giu',
);

const mask = (part: string) => part.replace(WORDS, (w) => w[0] + '*'.repeat(w.length - 1));

/**
 * [text] with the swear words and slurs in STRONG_LANGUAGE masked, each
 * keeping its first letter: "What the f***". Whole words only, ignoring
 * case; links are left alone.
 */
export function maskStrongLanguage(text: string): string {
  if (!text) return text;
  let out = '';
  let at = 0;
  for (const link of text.matchAll(LINKS)) {
    out += mask(text.slice(at, link.index)) + link[0];
    at = link.index + link[0].length;
  }
  return out + mask(text.slice(at));
}
