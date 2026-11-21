// The theme editor's server check (#83, owner's request 2026-11-21: "put a
// protection in there that prevents text and background from being the
// same color"): which colors leave text hard to read over each built-in
// scheme. No emulators needed.
import { describe, expect, it } from 'vitest';
import { builtInSchemeValues, contrast, unreadableParts, type ThemeColors } from '../../src/admin/themes.js';
import { SCHEME_INK } from '../../src/shared/constants.js';

const none: ThemeColors = { accent: null, page: null, card: null, text: null, cardText: null };
const theme = (colors: Partial<ThemeColors>): ThemeColors => ({ ...none, ...colors });

describe('contrast', () => {
  it('is the WCAG ratio', () => {
    expect(contrast('#000000', '#FFFFFF')).toBeCloseTo(21, 5);
    expect(contrast('#FFFFFF', '#FFFFFF')).toBeCloseTo(1, 5);
    // Coral on ink, as the design's tables have it.
    expect(contrast('#F45B5B', '#1A1A18')).toBeCloseTo(contrast('#1A1A18', '#F45B5B'), 9);
  });
});

describe('unreadableParts', () => {
  it('knows every built-in scheme, and each reads as it ships', () => {
    expect(Object.keys(SCHEME_INK).sort()).toEqual([...builtInSchemeValues].sort());
    for (const scheme of builtInSchemeValues) {
      expect(unreadableParts(scheme, none), scheme).toEqual([]);
    }
  });

  it('refuses text the color of its background, on the page or the cards', () => {
    expect(unreadableParts('army', theme({ page: '#F4EAD0' }))).toContain('text on page');
    expect(unreadableParts('army', theme({ text: '#474C2B' }))).toContain('text on page');
    expect(unreadableParts('army', theme({ card: '#F4EAD0' }))).toEqual(
      expect.arrayContaining(['text on cards', 'text on pop-ups']),
    );
    expect(unreadableParts('candypop', theme({ cardText: '#FFFFFF' }))).toContain('text on cards');
  });

  it('refuses dark text where the tab bar and text boxes stay dark', () => {
    // A light page with dark text, starting from a dark scheme.
    expect(unreadableParts('army', theme({ page: '#FBF5E6', card: '#FFFFFF', text: '#1A1A18' }))).toEqual(
      expect.arrayContaining(['text on tab bar', 'text in text boxes']),
    );
    // From Light, whose bars are light, it reads.
    expect(unreadableParts('light', theme({ page: '#FFFFFF', text: '#0B1531' }))).toEqual([]);
  });

  it('the card text follows the text but in Candy Pop, and pop-ups follow the card', () => {
    // Army green: dark cards take the new light text too.
    expect(unreadableParts('army', theme({ text: '#FFFFFF' }))).toEqual([]);
    // Candy Pop keeps navy on its white cards when only the page text changes.
    expect(unreadableParts('candypop', theme({ text: '#FDD023' }))).toEqual([]);
  });

  it('takes white writing on a dark "you" color like maroon, where it stands out', () => {
    expect(unreadableParts('light', theme({ accent: '#7F1D1D' }))).toEqual([]);
    expect(unreadableParts('sky', theme({ accent: '#5E1224' }))).toEqual([]);
    // Mid gray: neither ink nor white reads.
    expect(unreadableParts('light', theme({ accent: '#808080' }))).toContain('writing on buttons');
  });

  it('refuses a "you" color that vanishes into the page, cards or tab bar', () => {
    expect(unreadableParts('wildcat', theme({ accent: '#701C30' }))).toEqual(
      expect.arrayContaining(['buttons on page', 'buttons on cards']),
    );
    expect(unreadableParts('army', theme({ accent: '#3D4124' }))).toContain('picked tab on tab bar');
  });

  it('accepts the owner-style picks: gold text on purple, gold buttons on navy', () => {
    expect(unreadableParts('purplegold', theme({ text: '#FDD023' }))).toEqual([]);
    expect(unreadableParts('navy', theme({ accent: '#FDD023' }))).toEqual([]);
    expect(unreadableParts('darkarmy', theme({ page: '#1D200F' }))).toEqual([]);
  });

  it('refuses an unknown base', () => {
    expect(unreadableParts('plaid', none)).toEqual(['base']);
  });
});
