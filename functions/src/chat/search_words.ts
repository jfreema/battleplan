// The words chat search finds a message by (CHAT-20).
// lib/features/chat/domain/search_words.dart takes the same steps in the
// app, so a search finds what either one wrote; the rules and their
// examples are in shared/search_words.json.
import { Limits, SEARCH_FOLDS, SEARCH_STOP_WORDS } from '../shared/constants.js';

const APOSTROPHES = /['\u2019\u02BC]/g;
const MARKS = /[\u0300-\u036F]/g;
const WORD = /[\p{L}\p{N}]+/gu;

/** What search finds: people's messages, photos' captions, polls, and event cards, but not system lines. */
export const SEARCHED_TYPES: ReadonlySet<string> = new Set(['text', 'image', 'poll', 'event']);

/**
 * The words chat search finds [text] by: lowercase, without apostrophes or
 * accents (SEARCH_FOLDS), each run of letters and digits from 2 to
 * searchWordLengthMax long that isn't one of SEARCH_STOP_WORDS, a plural
 * read as its singular, each once, in order. A message keeps at most
 * [max], its longest.
 */
export function searchWords(text: string, max: number = Limits.searchWordsMax): string[] {
  if (!text) return [];
  let plain = '';
  for (const c of text.toLowerCase().replace(APOSTROPHES, '')) plain += SEARCH_FOLDS[c] ?? c;
  const words: string[] = [];
  const seen = new Set<string>();
  for (const [match] of plain.replace(MARKS, '').matchAll(WORD)) {
    let w = match;
    const length = [...w].length;
    if (length < 2 || length > Limits.searchWordLengthMax || SEARCH_STOP_WORDS.has(w)) continue;
    if (length >= 5 && w.endsWith('ies')) w = `${w.slice(0, -3)}y`;
    else if (length >= 4 && w.endsWith('s') && !w.endsWith('ss')) w = w.slice(0, -1);
    if (!seen.has(w)) {
      seen.add(w);
      words.push(w);
    }
  }
  if (words.length <= max) return words;
  // The longest, in their order.
  const keep = new Set(
    words
      .map((_, i) => i)
      .sort((a, b) => [...words[b]].length - [...words[a]].length || a - b)
      .slice(0, max),
  );
  return words.filter((_, i) => keep.has(i));
}

/** The words a message of [type] should have: none for system lines. */
export function searchWordsOf(type: unknown, text: unknown): string[] {
  return typeof type === 'string' && SEARCHED_TYPES.has(type) && typeof text === 'string' ? searchWords(text) : [];
}
