// Chat search's words on the server (CHAT-20): putting right a message
// whose words don't match its text, and giving messages from before search
// theirs.
import { FieldPath, FieldValue, type DocumentData } from 'firebase-admin/firestore';
import { db } from '../shared/admin.js';
import { Collections } from '../shared/constants.js';
import { searchWordsOf } from './search_words.js';

/** Whether [stored], a message's words, are [words]; none stored reads as none. */
function sameWords(stored: unknown, words: string[]): boolean {
  const list = Array.isArray(stored) ? stored : [];
  return list.length === words.length && list.every((w, i) => w === words[i]);
}

/**
 * The update that gives [message] the words its text has, or null when it
 * already has them. A message with none keeps no field.
 */
export function searchWordsUpdate(message: DocumentData): { words: string[] | FieldValue } | null {
  const words = searchWordsOf(message.type, message.text);
  if (sameWords(message.words, words)) return null;
  return { words: words.length ? words : FieldValue.delete() };
}

/**
 * Gives a new or edited message the words its text has, when the app
 * didn't: an older app sends none, and the rules check only how many there
 * are. Most messages already have the right ones, and cost no write. A
 * deleted message keeps none.
 */
export async function syncSearchWords(messageId: string, message: DocumentData): Promise<void> {
  if (message.deletedAt) return;
  const update = searchWordsUpdate(message);
  if (update) await db().collection(Collections.messages).doc(messageId).update(update);
}

/**
 * Gives messages from before search their words: up to [limit] a run, in
 * ID order from where the last run stopped (`config/searchWords`), skipping
 * deleted ones and those that already have the right words. The 5-minute
 * tick runs it; once it reaches the end it's done, and each run after that
 * reads one document. Returns how many messages it gave words.
 */
export async function backfillSearchWords(limit = 400): Promise<number> {
  const state = db().collection(Collections.config).doc('searchWords');
  const snap = await state.get();
  if (snap.get('done') === true) return 0;
  const after = snap.get('after');
  let query = db()
    .collection(Collections.messages)
    .orderBy(FieldPath.documentId())
    .select('type', 'text', 'words', 'deletedAt')
    .limit(limit);
  if (typeof after === 'string') query = query.startAfter(after);
  const page = await query.get();
  const batch = db().batch();
  let updated = 0;
  for (const d of page.docs) {
    const data = d.data();
    if (data.deletedAt) continue;
    const update = searchWordsUpdate(data);
    if (!update) continue;
    batch.update(d.ref, update);
    updated++;
  }
  if (updated) await batch.commit();
  await state.set({
    after: page.docs.at(-1)?.id ?? (typeof after === 'string' ? after : null),
    done: page.size < limit,
    updatedAt: FieldValue.serverTimestamp(),
  });
  return updated;
}
