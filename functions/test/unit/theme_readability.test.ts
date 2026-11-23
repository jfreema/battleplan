// The theme editor's server check (#83, owner's requests 2026-11-21: "put a
// protection in there that prevents text and background from being the
// same color", then "I only want to block colors that are nearly
// identical"): which colors over each stored scheme sit on one that looks
// nearly the same, as the app draws it (since Boot Camp Mix, #85 and #86,
// the closest of its seven schemes). No emulators needed.
import { describe, expect, it } from 'vitest';
import {
  builtInSchemeValues,
  campSchemeValues,
  contrast,
  deltaE,
  NEARLY_SAME,
  SaveCampThemeInput,
  unreadableCampParts,
  unreadableParts,
  type ThemeColors,
} from '../../src/admin/themes.js';
import { CAMP_PALETTES, SCHEME_INK } from '../../src/shared/constants.js';

const none: ThemeColors = { accent: null, page: null, card: null, text: null, cardText: null };
const theme = (colors: Partial<ThemeColors>): ThemeColors => ({ ...none, ...colors });

describe('contrast and deltaE', () => {
  it('contrast is the WCAG ratio', () => {
    expect(contrast('#000000', '#FFFFFF')).toBeCloseTo(21, 5);
    expect(contrast('#FFFFFF', '#FFFFFF')).toBeCloseTo(1, 5);
  });

  it('deltaE is the distance in CIE Lab, as the app has it', () => {
    expect(deltaE('#000000', '#FFFFFF')).toBeCloseTo(100, 1);
    expect(deltaE('#F45B5B', '#F45B5B')).toBe(0);
    // Near: Ice on white; far: cream on gold.
    expect(deltaE('#F2F6FF', '#FFFFFF')).toBeLessThan(NEARLY_SAME);
    expect(deltaE('#F4EAD0', '#FDD023')).toBeGreaterThan(NEARLY_SAME);
  });
});

describe('unreadableParts', () => {
  it('knows every built-in scheme, and each passes as it ships', () => {
    expect(Object.keys(SCHEME_INK).sort()).toEqual([...builtInSchemeValues].sort());
    for (const scheme of builtInSchemeValues) {
      expect(unreadableParts(scheme, none), scheme).toEqual([]);
    }
  });

  it('refuses text nearly the color of its background, on the page or the cards', () => {
    expect(unreadableParts('army', theme({ page: '#F4EAD0' }))).toContain('text on page');
    expect(unreadableParts('army', theme({ text: '#474C2B' }))).toContain('text on page');
    // Ivory is nearly Army green's cream.
    expect(unreadableParts('army', theme({ page: '#FBF5E6' }))).toContain('text on page');
    expect(unreadableParts('army', theme({ card: '#F4EAD0' }))).toEqual(
      expect.arrayContaining(['text on cards', 'text on pop-ups']),
    );
    expect(unreadableParts('candypop', theme({ cardText: '#FFFFFF' }))).toContain('text on cards');
    // Navy is drawn as Black: cream text.
    expect(unreadableParts('navy', theme({ page: '#F4EAD0' }))).toContain('text on page');
    // Scoreboard too: cream text on a page nearly cream.
    expect(unreadableParts('scoreboard', theme({ page: '#EFE6CC' }))).toContain('text on page');
  });

  it('lets anything else through, however it reads: a yellow background included', () => {
    for (const page of ['#FDD023', '#F8D84A']) {
      expect(unreadableParts('army', theme({ page })), page).toEqual([]);
      expect(unreadableParts('light', theme({ page })), page).toEqual([]);
      expect(unreadableParts('navy', theme({ page })), page).toEqual([]);
    }
    // Dark text where Army green's tab bar stays olive: hard to read, not
    // the same color.
    expect(unreadableParts('army', theme({ page: '#FBF5E6', card: '#FFFFFF', text: '#1A1A18' }))).toEqual([]);
    expect(unreadableParts('purplegold', theme({ text: '#FDD023' }))).toEqual([]);
    expect(unreadableParts('light', theme({ accent: '#7F1D1D' }))).toEqual([]);
    expect(unreadableParts('light', theme({ accent: '#808080' }))).toEqual([]);
  });

  it('refuses a "you" color nearly the same as the page, cards or tab bar', () => {
    // Central Wildcats' maroon page and a shade lighter cards (#86).
    expect(unreadableParts('wildcat', theme({ accent: '#661729' }))).toEqual(
      expect.arrayContaining(['buttons on page', 'buttons on cards']),
    );
    expect(unreadableParts('army', theme({ accent: '#3D4124' }))).toContain('picked tab on tab bar');
  });

  it('refuses text the color of the tab bar or text boxes, which keep the base colors', () => {
    expect(unreadableParts('army', theme({ text: '#3D4124', page: '#FFFFFF' }))).toContain('text on tab bar');
    expect(unreadableParts('light', theme({ text: '#FAF5EA', page: '#1A1A18' }))).toContain('text in text boxes');
  });

  it('refuses an unknown base', () => {
    expect(unreadableParts('plaid', none)).toEqual(['base']);
  });
});

// Boot Camp Mix's theme editor (#88): every token of the seven schemes, the
// same pairs as the app's campPairs.
describe('unreadableCampParts', () => {
  it('knows the seven schemes, and each passes as it ships', () => {
    expect(campSchemeValues.sort()).toEqual(['army', 'candypop', 'dark', 'light', 'purplegold', 'sky', 'wildcat']);
    for (const scheme of campSchemeValues) expect(unreadableCampParts(scheme, {})).toEqual([]);
  });

  it('lets games, send and alerts be any color that stands apart: coral on Black, gold on Geaux Tigahs', () => {
    expect(unreadableCampParts('dark', { red: '#F45B5B' })).toEqual([]);
    expect(unreadableCampParts('purplegold', { red: '#FDD023' })).toEqual([]);
  });

  it('refuses games, send and alerts nearly the color of the page or the panels', () => {
    const page = CAMP_PALETTES.army.page;
    expect(unreadableCampParts('army', { red: page })).toEqual(['red on page', 'red on panel']);
    // Candy Pop's panels are white on its royal blue page.
    expect(unreadableCampParts('candypop', { red: '#FFFFFE' })).toEqual(['red on panel']);
  });

  it('refuses text nearly the color of the page, tab bar, text boxes or panels', () => {
    expect(unreadableCampParts('dark', { page: CAMP_PALETTES.dark.text })).toEqual(['text on page']);
    expect(unreadableCampParts('light', { tabBar: '#1A1A1A' })).toEqual(['text on tabBar']);
    expect(unreadableCampParts('light', { panel: '#222222' })).toContain('panelText on panel');
    // Candy Pop's text boxes are the camouflage's ground, where its page's
    // white reads.
    expect(unreadableCampParts('candypop', { camoGround: '#FFFFFF' })).toContain('text on camoGround');
  });

  it("refuses the tags' trim nearly the ink of their lettering, or the tab bar of the current tab", () => {
    expect(unreadableCampParts('dark', { mustard: '#050505' })).toEqual(['ink on mustard', 'mustard on tabBar']);
    expect(unreadableCampParts('army', { mustard: CAMP_PALETTES.army.tabBar })).toEqual(['mustard on tabBar']);
  });

  it('never refuses a pair the scheme ships with nearly the same', () => {
    // Black's ink is black on its near-black page, by design: its panels
    // stand off it on an olive shadow.
    expect(deltaE(CAMP_PALETTES.dark.ink, CAMP_PALETTES.dark.page)).toBeLessThan(NEARLY_SAME);
    expect(unreadableCampParts('dark', { shadow: '#000000' })).toEqual([]);
  });

  it('refuses an unknown scheme', () => {
    expect(unreadableCampParts('navy', {})).toEqual(['scheme']);
  });

  it('takes colors by token only, as #RRGGBB, upper-cased', () => {
    expect(SaveCampThemeInput.parse({ scheme: 'dark', colors: { red: '#f45b5b' } }).colors).toEqual({ red: '#F45B5B' });
    expect(() => SaveCampThemeInput.parse({ scheme: 'dark', colors: { accent: '#F45B5B' } })).toThrow();
    expect(() => SaveCampThemeInput.parse({ scheme: 'dark', colors: { red: 'red' } })).toThrow();
    expect(() => SaveCampThemeInput.parse({ scheme: 'navy', colors: {} })).toThrow();
  });
});

