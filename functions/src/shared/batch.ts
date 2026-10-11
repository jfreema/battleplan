import type { Query, WriteBatch } from 'firebase-admin/firestore';
import { db } from './admin.js';

/**
 * Runs [apply] on every document [query] matches, a page at a time, with a
 * batched write per page (Firestore allows 500 writes per batch). The query
 * must not match the documents [apply] changes, or it will loop; use it for
 * deletes, or for updates that move documents out of the query.
 */
export async function forEachPage(
  query: Query,
  apply: (batch: WriteBatch, doc: FirebaseFirestore.QueryDocumentSnapshot) => void,
  pageSize = 400,
): Promise<number> {
  let total = 0;
  let last: FirebaseFirestore.QueryDocumentSnapshot | undefined;
  for (;;) {
    let page = query.limit(pageSize);
    if (last) page = page.startAfter(last);
    const snap = await page.get();
    if (snap.empty) break;
    const batch = db().batch();
    snap.docs.forEach((d) => apply(batch, d));
    await batch.commit();
    total += snap.size;
    last = snap.docs[snap.docs.length - 1];
    if (snap.size < pageSize) break;
  }
  return total;
}
