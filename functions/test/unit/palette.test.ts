// The team palette (TEAM-1) lives in shared/constants.json, and
// firestore.rules lists it by hand twice: the team color, and the CHAT-18
// bubble color, which also takes the Gumdrop candies (CHAT_CANDY_COLORS,
// the ChatCandy enum in the app). This keeps them all the same, in both
// directions, so a color can't be dropped from one place or added to only one.
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { CHAT_CANDY_COLORS } from '../../src/admin/inputs.js';
import { TEAM_COLORS } from '../../src/shared/constants.js';

const colorList = /in \[((?:\s*'#[0-9A-F]{6}',?)+)\s*\]/g;

describe('team palette', () => {
  it('matches between shared constants and both lists in firestore.rules', () => {
    const rules = readFileSync(resolve(process.cwd(), '../firestore.rules'), 'utf8');
    const lists = new Map(
      [...rules.matchAll(colorList)].map((m) => [
        m[0],
        [...m[1].matchAll(/'(#[0-9A-F]{6})'/g)].map((c) => c[1]).sort(),
      ]),
    );
    expect(lists.size).toBe(2);
    const sorted = [...lists.values()].sort((a, b) => a.length - b.length);
    expect(sorted[0]).toEqual([...TEAM_COLORS].sort());
    expect(sorted[1]).toEqual([...TEAM_COLORS, ...CHAT_CANDY_COLORS].sort());
    expect(TEAM_COLORS).toHaveLength(15);
  });

  it("the bubble list in the rules is the chat look's", () => {
    const rules = readFileSync(resolve(process.cwd(), '../firestore.rules'), 'utf8');
    const chat = rules.slice(rules.indexOf('function validChatTheme'));
    const list = [...chat.matchAll(colorList)][0];
    expect([...list[1].matchAll(/'(#[0-9A-F]{6})'/g)].map((c) => c[1]).sort()).toEqual(
      [...TEAM_COLORS, ...CHAT_CANDY_COLORS].sort(),
    );
  });

  it("the candies match the app's ChatCandy enum", () => {
    const dart = readFileSync(
      resolve(process.cwd(), '../lib/features/groups/domain/chat_colors.dart'),
      'utf8',
    );
    const candies = [...dart.matchAll(/\w+\(0xFF([0-9A-F]{6})\)/g)].map((m) => `#${m[1]}`);
    expect(candies).toEqual([...CHAT_CANDY_COLORS]);
  });
});
