// The theme editor's saves (#82, owner's request 2026-11-20): each theme's
// own colors in config/app.themes, under the scheme's value, which every
// signed-in app reads with the rest of config/app. A built-in scheme's
// entry changes only the colors it sets. A saved theme takes one of the
// reserved slots (custom1 to custom12 in teamScheme), with a name and the
// built-in scheme it starts from, so picks of it are stored and checked
// like any other scheme's.
import { FieldValue } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { db } from '../shared/admin.js';
import { forEachPage } from '../shared/batch.js';
import { Collections, teamSchemeValues } from '../shared/constants.js';

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
  // The "you" color (buttons, your messages, unread counts), the page, and
  // the cards and bubbles.
  accent: Hex,
  page: Hex,
  card: Hex,
});
export type SaveThemeInput = z.infer<typeof SaveThemeInput>;

export const DeleteThemeInput = z.object({ scheme: z.enum(teamSchemeValues) });

/** A theme as config/app.themes keeps it. */
type StoredTheme = { name?: string; base?: string; accent: string | null; page: string | null; card: string | null };

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
    const colors = { accent: input.accent ?? null, page: input.page ?? null, card: input.card ?? null };
    let after: StoredTheme = colors;
    if (scheme.startsWith('custom')) {
      const name = input.name ?? before?.name;
      const base = input.base ?? before?.base;
      if (!name || !base) {
        throw new HttpsError('failed-precondition', 'A saved theme needs a name and a scheme to start from.', {
          reason: 'theme-needs-name',
        });
      }
      after = { name, base, ...colors };
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
