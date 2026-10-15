// The team language filter (SAFE-7): the examples in
// shared/strong_language.json, which the app's tests check too.
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { maskStrongLanguage } from '../../src/safety/strong_language.js';

const { examples } = JSON.parse(readFileSync(resolve(process.cwd(), '../shared/strong_language.json'), 'utf8')) as {
  examples: [string, string][];
};

describe('maskStrongLanguage', () => {
  it.each(examples)('%j', (text, masked) => {
    expect(maskStrongLanguage(text)).toBe(masked);
  });
});
