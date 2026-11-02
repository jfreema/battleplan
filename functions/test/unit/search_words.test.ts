// Chat search's words (CHAT-20): the examples in shared/search_words.json,
// which the app's tests check too.
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { searchWords, searchWordsOf } from '../../src/chat/search_words.js';
import { Limits } from '../../src/shared/constants.js';

const { examples } = JSON.parse(readFileSync(resolve(process.cwd(), '../shared/search_words.json'), 'utf8')) as {
  examples: [string, string[]][];
};

describe('searchWords', () => {
  it.each(examples)('%j', (text, words) => {
    expect(searchWords(text)).toEqual(words);
  });

  it('keeps the longest words of a long message, in order', () => {
    // 104 four-letter words, then one of eight: the long one stays, with
    // the first 99 of the rest.
    const short = Array.from({ length: 104 }, (_, i) => `w${String(i).padStart(3, '0')}`);
    const words = searchWords(`${short.join(' ')} longword`);
    expect(words).toHaveLength(Limits.searchWordsMax);
    expect(words.at(-1)).toBe('longword');
    expect(words[0]).toBe('w000');
    expect(words).not.toContain('w099');
  });
});

describe('searchWordsOf', () => {
  it("finds people's messages, captions, polls, and event cards, not system lines", () => {
    expect(searchWordsOf('text', 'Bring cleats')).toEqual(['bring', 'cleat']);
    expect(searchWordsOf('image', 'Team photo')).toEqual(['team', 'photo']);
    expect(searchWordsOf('poll', 'Pizza or tacos?')).toEqual(['pizza', 'taco']);
    expect(searchWordsOf('event', 'vs. Eagles · Riverside Park')).toEqual(['vs', 'eagle', 'riverside', 'park']);
    expect(searchWordsOf('system', 'Sam joined')).toEqual([]);
    expect(searchWordsOf('text', undefined)).toEqual([]);
  });
});
