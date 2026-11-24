// The theme editor's saves (#82, owner's request 2026-11-20): each theme's
// own colors in config/app.themes, under the scheme's value, which every
// signed-in app reads with the rest of config/app. A built-in scheme's
// entry changes only the colors it sets. A saved theme takes one of the
// reserved slots (custom1 to custom12 in teamScheme), with a name and the
// built-in scheme it starts from, so picks of it are stored and checked
// like any other scheme's. The text colors came with #83 (2026-11-21), and
// with them the check that refuses a theme with a color nearly the same as
// what it's drawn on ("a protection in there that prevents text and
// background from being the same color", then "I only want to block colors
// that are nearly identical"), as the editor does before it sends one.
import { FieldValue } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { db } from '../shared/admin.js';
import { forEachPage } from '../shared/batch.js';
import {
  CAMP_PALETTES,
  type CampColor,
  Collections,
  SCHEME_INK,
  campColorValues,
  headerStyleValues,
  teamSchemeValues,
} from '../shared/constants.js';

/** The slots saved themes take, in order: a new one takes the first free. */
export const customSchemeValues = teamSchemeValues.filter((s) => s.startsWith('custom'));

/** The schemes the app ships with, which a saved theme can start from. */
export const builtInSchemeValues = teamSchemeValues.filter((s) => !s.startsWith('custom'));

/** How long a saved theme's name can be. */
export const THEME_NAME_MAX = 30;

/** `#RRGGBB`, or null to keep the base's color. */
const Hex = z
  .string()
  .regex(/^#[0-9A-Fa-f]{6}$/)
  .transform((s) => s.toUpperCase())
  .nullable()
  .optional();

export const SaveThemeInput = z.object({
  // Absent for a new theme.
  scheme: z.enum(teamSchemeValues).optional(),
  name: z.string().trim().min(1).max(THEME_NAME_MAX).optional(),
  base: z.enum(builtInSchemeValues as [string, ...string[]]).optional(),
  // The "you" color (buttons, your messages, unread counts), the page, the
  // cards and bubbles, and the text on each (#83).
  accent: Hex,
  page: Hex,
  card: Hex,
  text: Hex,
  cardText: Hex,
});
export type SaveThemeInput = z.infer<typeof SaveThemeInput>;

export const DeleteThemeInput = z.object({ scheme: z.enum(teamSchemeValues) });

/** A theme's colors, as config/app.themes keeps them: '#RRGGBB' or null. */
export type ThemeColors = {
  accent: string | null;
  page: string | null;
  card: string | null;
  text: string | null;
  cardText: string | null;
};

/** A theme as config/app.themes keeps it. */
type StoredTheme = { name?: string; base?: string } & ThemeColors;

/**
 * Saves a theme's colors. A new theme (no scheme) takes the first free
 * slot, or is refused with `no-room`; a saved theme needs a name and a
 * base (`theme-needs-name`), which an edit can leave out to keep them.
 * Returns the scheme it saved under and the entry before and after, for
 * the audit.
 */
export async function saveTheme(input: SaveThemeInput): Promise<{
  scheme: string;
  before: StoredTheme | null;
  after: StoredTheme;
}> {
  const ref = db().collection(Collections.config).doc('app');
  return db().runTransaction(async (tx) => {
    const themes = ((await tx.get(ref)).get('themes') ?? {}) as Record<string, StoredTheme | undefined>;
    const scheme = input.scheme ?? customSchemeValues.find((s) => themes[s] == null);
    if (scheme === undefined) {
      throw new HttpsError('failed-precondition', 'All the saved theme slots are taken.', { reason: 'no-room' });
    }
    const before = themes[scheme] ?? null;
    const colors: ThemeColors = {
      accent: input.accent ?? null,
      page: input.page ?? null,
      card: input.card ?? null,
      text: input.text ?? null,
      cardText: input.cardText ?? null,
    };
    let after: StoredTheme = colors;
    let base: string = scheme;
    if (scheme.startsWith('custom')) {
      const name = input.name ?? before?.name;
      base = input.base ?? before?.base ?? '';
      if (!name || !base) {
        throw new HttpsError('failed-precondition', 'A saved theme needs a name and a scheme to start from.', {
          reason: 'theme-needs-name',
        });
      }
      after = { name, base, ...colors };
    }
    const unreadable = unreadableParts(base, colors);
    if (unreadable.length > 0) {
      throw new HttpsError('failed-precondition', 'Some of those colors are nearly the same as what they sit on.', {
        reason: 'unreadable-theme',
        parts: unreadable,
      });
    }
    // Merged, so the other themes and settings stay as they are, and a
    // fresh project's config/app is made.
    tx.set(ref, { themes: { [scheme]: after }, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
    return { scheme, before, after };
  });
}

/**
 * Takes a theme's colors away: a built-in scheme goes back to how it
 * ships; a saved theme is deleted, and every pick of it (a member's for a
 * team, a team's default, someone's own default) is cleared, so they get
 * what comes next. Returns the entry before, and how many picks it cleared.
 */
export async function deleteTheme(scheme: string): Promise<{ before: StoredTheme | null; cleared: number }> {
  const ref = db().collection(Collections.config).doc('app');
  const snap = await ref.get();
  const before = ((snap.get('themes') ?? {}) as Record<string, StoredTheme | undefined>)[scheme] ?? null;
  if (snap.exists) {
    await ref.update({ [`themes.${scheme}`]: FieldValue.delete(), updatedAt: FieldValue.serverTimestamp() });
  }
  let cleared = 0;
  if (scheme.startsWith('custom')) {
    for (const collection of [Collections.groupMembers, Collections.groups, Collections.users]) {
      await forEachPage(db().collection(collection).where('colorScheme', '==', scheme), (batch, doc) => {
        batch.update(doc.ref, { colorScheme: FieldValue.delete() });
        cleared++;
      });
    }
  }
  return { before, cleared };
}

// ---- Nearly the same colors (#83) ----------------------------------------

/** Coral, every built-in scheme's "you" color. */
const CORAL = '#F45B5B';
const WHITE = '#FFFFFF';

/** sRGB channel i of '#RRGGBB', linear, as the app's ColorMath has it. */
function linear(hex: string, i: number): number {
  const c = parseInt(hex.slice(i, i + 2), 16) / 255;
  return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
}

/** WCAG 2 relative luminance of '#RRGGBB'. */
function luminance(hex: string): number {
  return 0.2126 * linear(hex, 1) + 0.7152 * linear(hex, 3) + 0.0722 * linear(hex, 5);
}

/** The WCAG 2 contrast ratio of two '#RRGGBB' colors, 1 to 21. */
export function contrast(a: string, b: string): number {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
}

/** '#RRGGBB' in CIE Lab (D65), with the app's ColorMath constants. */
function lab(hex: string): [number, number, number] {
  const [r, g, b] = [linear(hex, 1), linear(hex, 3), linear(hex, 5)];
  const x = 0.4124 * r + 0.3576 * g + 0.1805 * b;
  const y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
  const z = 0.0193 * r + 0.1192 * g + 0.9505 * b;
  const epsilon = 216 / 24389;
  const kappa = 24389 / 27;
  const f = (t: number) => (t > epsilon ? Math.cbrt(t) : (kappa * t + 16) / 116);
  const [fx, fy, fz] = [f(x / 0.95047), f(y), f(z / 1.08883)];
  return [116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)];
}

/** How different two '#RRGGBB' colors look: CIE76 ΔE, the app's ColorMath.deltaE. */
export function deltaE(a: string, b: string): number {
  const [x, y] = [lab(a), lab(b)];
  return Math.hypot(x[0] - y[0], x[1] - y[1], x[2] - y[2]);
}

/** Under this ΔE two colors look nearly the same: the app's nearlySame. */
export const NEARLY_SAME = 15;

/**
 * Where [colors] over the built-in scheme [base] would put a color on one
 * nearly the same as it, by name; none when there's nowhere (#83, owner's
 * request 2026-11-21: "I only want to block colors that are nearly
 * identical"). The pairs are the app's themePairs: the text on the page,
 * the tab bar and text boxes (which keep the base's colors), cards, text
 * boxes on cards, and pop-ups; the writing on the "you" color (the
 * scheme's ink, or white where the ink doesn't read); and the "you" color
 * on the page, cards and tab bar. Anything else goes; the app keeps the
 * Super Admin Panel as it ships, so a theme can always be put right.
 */
export function unreadableParts(base: string, colors: ThemeColors): string[] {
  const ink = SCHEME_INK[base];
  if (ink === undefined) return ['base'];
  const page = colors.page ?? ink.page;
  const card = colors.card ?? ink.card;
  const text = colors.text ?? ink.text;
  // The card's text follows the text where it was the page's (all but
  // Candy Pop), and pop-ups follow the card where they were the card's.
  const cardText = colors.cardText ?? (colors.text !== null && ink.cardText === ink.text ? colors.text : ink.cardText);
  const popup = colors.card !== null && ink.popup === ink.card ? colors.card : ink.popup;
  const accent = colors.accent ?? CORAL;
  // The writing on the "you" color: the ink, or white where the ink doesn't
  // read 4.5:1 and white reads better (the app's youInk).
  const inkOn = (face: string) => {
    const dark = contrast(ink.candyInk, face);
    return dark >= 4.5 || contrast(WHITE, face) <= dark ? ink.candyInk : WHITE;
  };
  const pairs: [string, string, string, string, string][] = [
    // [what, fg, bg, the shipped fg, the shipped bg]
    ['text on page', text, page, ink.text, ink.page],
    ['text on tab bar', text, ink.tabbar, ink.text, ink.tabbar],
    ['text in text boxes', text, ink.field, ink.text, ink.field],
    ['text in text boxes on cards', cardText, ink.cardField, ink.cardText, ink.cardField],
    ['text on cards', cardText, card, ink.cardText, ink.card],
    ['text on pop-ups', text, popup, ink.text, ink.popup],
    ['writing on buttons', inkOn(accent), accent, inkOn(CORAL), CORAL],
    ['buttons on page', accent, page, CORAL, ink.page],
    ['buttons on cards', accent, card, CORAL, ink.card],
    ['picked tab on tab bar', accent, ink.tabbar, CORAL, ink.tabbar],
  ];
  // Never refused for what the shipped scheme has itself.
  return pairs
    .filter(([, fg, bg, shippedFg, shippedBg]) => deltaE(fg, bg) < NEARLY_SAME && deltaE(shippedFg, shippedBg) >= NEARLY_SAME)
    .map(([what]) => what);
}

// ---- Boot Camp Mix (#88) -------------------------------------------------
//
// The theme editor back for Boot Camp Mix (owner's request 2026-11-22: "can
// you put the theme editor back in? only available to super admins, of
// course."): every color a scheme is drawn from, games, send and alerts
// too, in config/app.campThemes under the scheme's value, token by token.
// config/app.themes above keeps the first editor's colors, for the schemes
// before Boot Camp Mix; the app no longer draws them.

/** The Boot Camp Mix schemes the editor changes. */
export const campSchemeValues = Object.keys(CAMP_PALETTES) as [string, ...string[]];

/** A scheme's changed colors, by token, as '#RRGGBB'. */
export type CampColors = Partial<Record<CampColor, string>>;

/**
 * A scheme's entry in config/app.campThemes: its colors, its header
 * background (#91) unless camouflage, and `sprinkles: false` when its
 * headers have no candy sprinkles (#98's; on unless turned off).
 */
export type CampThemeEntry = CampColors & { header?: string; sprinkles?: false };

export const SaveCampThemeInput = z.object({
  scheme: z.enum(campSchemeValues),
  colors: z.partialRecord(
    z.enum(campColorValues),
    z
      .string()
      .regex(/^#[0-9A-Fa-f]{6}$/)
      .transform((s) => s.toUpperCase()),
  ),
  // The header's background (#91); camouflage, as every scheme ships, when absent.
  header: z.enum(headerStyleValues).optional(),
  // Whether the headers have the candy sprinkles (#98); on, as every scheme ships, when absent.
  sprinkles: z.boolean().optional(),
});
export type SaveCampThemeInput = z.infer<typeof SaveCampThemeInput>;

export const ResetCampThemeInput = z.object({ scheme: z.enum(campSchemeValues) });

/**
 * Saves the colors changed in a Boot Camp Mix scheme, its header
 * background (#91), and whether its headers have sprinkles, in place of
 * what was saved for it, or refuses with `unreadable-theme` when a color
 * would be nearly the same as what it sits on. No colors, the camouflage
 * and the sprinkles on puts it back as it ships. Returns the entry before
 * and after, for the audit.
 */
export async function saveCampTheme(input: SaveCampThemeInput): Promise<{
  before: CampThemeEntry | null;
  after: CampThemeEntry | null;
}> {
  const { scheme } = input;
  const colors = input.colors as CampColors;
  const header = input.header !== undefined && input.header !== 'camo' ? input.header : undefined;
  // Only turned off is kept: on is how every scheme ships.
  const noSprinkles = input.sprinkles === false;
  const unreadable = unreadableCampParts(scheme, colors);
  if (unreadable.length > 0) {
    throw new HttpsError('failed-precondition', 'Some of those colors are nearly the same as what they sit on.', {
      reason: 'unreadable-theme',
      parts: unreadable,
    });
  }
  if (Object.keys(colors).length === 0 && header === undefined && !noSprinkles) {
    const { before } = await resetCampTheme(scheme);
    return { before, after: null };
  }
  const entry: CampThemeEntry = {
    ...colors,
    ...(header === undefined ? {} : { header }),
    ...(noSprinkles ? { sprinkles: false as const } : {}),
  };
  const ref = db().collection(Collections.config).doc('app');
  return db().runTransaction(async (tx) => {
    const before = (((await tx.get(ref)).get('campThemes') ?? {}) as Record<string, CampThemeEntry | undefined>)[scheme] ?? null;
    // The scheme's entry replaced whole, so a color put back to the
    // original goes; the other schemes and settings stay, and a fresh
    // project's config/app is made.
    tx.set(
      ref,
      { campThemes: { [scheme]: entry }, updatedAt: FieldValue.serverTimestamp() },
      { mergeFields: [`campThemes.${scheme}`, 'updatedAt'] },
    );
    return { before, after: entry };
  });
}

/** Puts a Boot Camp Mix scheme back as it ships. Returns the entry before. */
export async function resetCampTheme(scheme: string): Promise<{ before: CampThemeEntry | null }> {
  const ref = db().collection(Collections.config).doc('app');
  const snap = await ref.get();
  const before = ((snap.get('campThemes') ?? {}) as Record<string, CampThemeEntry | undefined>)[scheme] ?? null;
  if (snap.exists) {
    await ref.update({ [`campThemes.${scheme}`]: FieldValue.delete(), updatedAt: FieldValue.serverTimestamp() });
  }
  return { before };
}

/**
 * Where [colors] over the Boot Camp Mix scheme [scheme] would put a color
 * on one nearly the same as it, as "fg on bg"; none when there's nowhere.
 * The pairs are the app's campPairs: the text on the page, the tab bar and
 * text boxes (Candy Pop's are the camouflage's ground, where its page's
 * white reads), the panels' text on them, the header's lettering on the
 * camouflage, the tags' ink lettering on the trim, the current tab's trim
 * on the tab bar, games, send and alerts on the page and on panels, and
 * your messages on the page. Never refused for what the scheme ships with.
 */
export function unreadableCampParts(scheme: string, colors: CampColors): string[] {
  const base = CAMP_PALETTES[scheme];
  if (base === undefined) return ['scheme'];
  const themed: Record<CampColor, string> = { ...base, ...colors };
  const pairs = (p: Record<CampColor, string>): [CampColor, CampColor][] => [
    ['text', 'page'],
    ['text', 'tabBar'],
    ['text', p.panelText !== p.text ? 'camoGround' : 'panel'],
    ['panelText', 'panel'],
    ['headerLettering', 'camoGround'],
    ['ink', 'mustard'],
    ['mustard', 'tabBar'],
    ['red', 'page'],
    ['red', 'panel'],
    ['balloon', 'page'],
  ];
  const before = pairs(base);
  return pairs(themed)
    .filter(([fg, bg], i) => {
      const [shippedFg, shippedBg] = before[i];
      return deltaE(themed[fg], themed[bg]) < NEARLY_SAME && deltaE(base[shippedFg], base[shippedBg]) >= NEARLY_SAME;
    })
    .map(([fg, bg]) => `${fg} on ${bg}`);
}

