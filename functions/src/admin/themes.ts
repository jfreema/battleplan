// The theme editor's saves (#82, owner's request 2026-11-20): each theme's
// own colors in config/app.themes, under the scheme's value, which every
// signed-in app reads with the rest of config/app. A built-in scheme's
// entry changes only the colors it sets. A saved theme takes one of the
// reserved slots (custom1 to custom12 in teamScheme), with a name and the
// built-in scheme it starts from, so picks of it are stored and checked
// like any other scheme's. The text colors came with #83 (2026-11-21), and
// with them the check that refuses a theme whose text would be hard to
// read ("a protection in there that prevents text and background from
// being the same color"), as the editor does before it sends one.
import { FieldValue } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { db } from '../shared/admin.js';
import { forEachPage } from '../shared/batch.js';
import { Collections, SCHEME_INK, teamSchemeValues } from '../shared/constants.js';

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
      throw new HttpsError('failed-precondition', 'Those colors would make some text hard to read.', {
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

// ---- Readability (#83) ---------------------------------------------------

/** Coral, every built-in scheme's "you" color. */
const CORAL = '#F45B5B';
const WHITE = '#FFFFFF';

/** WCAG 2 relative luminance of '#RRGGBB', as the app's ColorMath has it. */
function luminance(hex: string): number {
  const channel = (i: number) => {
    const c = parseInt(hex.slice(i, i + 2), 16) / 255;
    return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
  };
  return 0.2126 * channel(1) + 0.7152 * channel(3) + 0.0722 * channel(5);
}

/** The WCAG 2 contrast ratio of two '#RRGGBB' colors, 1 to 21. */
export function contrast(a: string, b: string): number {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
}

/**
 * What [colors] over the built-in scheme [base] would leave hard to read,
 * by name; none when they read. Text needs 4.5:1 on what it sits on (the
 * page, the tab bar and text boxes, which keep the base's colors, cards,
 * text boxes on cards, and pop-ups), the writing on the "you" color too
 * (the scheme's ink, or white where the ink doesn't read), and the "you"
 * color 3:1 on the page, cards and tab bar, or nearly as much as coral has
 * where that's less. The app checks these and more (theme_readability.dart),
 * and derives the colors that follow (muted text, colored labels); this is
 * the server's backstop for what it can't derive.
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
  // The standard, or nine tenths of what the shipped scheme reads where
  // that's under it, with a hair for rounding: the app's themeFloor.
  const floor = (minimum: number, shipped: number) => (shipped < minimum ? shipped * 0.9 : minimum) - 0.005;
  const checks: [string, number, number][] = [
    ['text on page', contrast(text, page), floor(4.5, contrast(ink.text, ink.page))],
    ['text on tab bar', contrast(text, ink.tabbar), floor(4.5, contrast(ink.text, ink.tabbar))],
    ['text in text boxes', contrast(text, ink.field), floor(4.5, contrast(ink.text, ink.field))],
    ['text on cards', contrast(cardText, card), floor(4.5, contrast(ink.cardText, ink.card))],
    ['text in text boxes on cards', contrast(cardText, ink.cardField), floor(4.5, contrast(ink.cardText, ink.cardField))],
    ['text on pop-ups', contrast(text, popup), floor(4.5, contrast(ink.text, ink.popup))],
    [
      'writing on buttons',
      Math.max(contrast(ink.candyInk, accent), contrast(WHITE, accent)),
      floor(4.5, contrast(ink.candyInk, CORAL)),
    ],
    ['buttons on page', contrast(accent, page), floor(3, contrast(CORAL, ink.page))],
    ['buttons on cards', contrast(accent, card), floor(3, contrast(CORAL, ink.card))],
    ['picked tab on tab bar', contrast(accent, ink.tabbar), floor(3, contrast(CORAL, ink.tabbar))],
  ];
  return checks.filter(([, ratio, least]) => ratio < least).map(([what]) => what);
}
