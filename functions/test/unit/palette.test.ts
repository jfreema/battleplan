// The team palette (TEAM-1) lives in shared/constants.json, and
// firestore.rules lists it by hand twice (team color, CHAT-18 bubble
// color). This keeps all three the same, in both directions, so a color
// can't be dropped from one place or added to only one.
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { TEAM_COLORS } from '../../src/shared/constants.js';

describe('team palette', () => {
  it('matches between shared constants and both lists in firestore.rules', () => {
    const rules = readFileSync(resolve(process.cwd(), '../firestore.rules'), 'utf8');
    const lists = [...rules.matchAll(/in \[((?:\s*'#[0-9A-F]{6}',?)+)\s*\]/g)].map((m) =>
      [...m[1].matchAll(/'(#[0-9A-F]{6})'/g)].map((c) => c[1]).sort(),
    );
    expect(lists).toHaveLength(2);
    for (const list of lists) expect(list).toEqual([...TEAM_COLORS].sort());
    expect(TEAM_COLORS).toHaveLength(13);
  });
});
