// The users trigger (ARCH §6.4 trigger map): reacts to the person editing
// their own profile, which clients write directly.
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { updateMemberSnapshots } from '../teams/service.js';

/** True when the fields copied onto memberships changed. */
export function snapshotChanged(
  before: Record<string, unknown> | undefined,
  after: Record<string, unknown> | undefined,
): boolean {
  if (!before || !after) return false;
  return before.displayName !== after.displayName || before.photoPath !== after.photoPath;
}

/** users updated → displayName and photoPath on the person's groupMembers. */
export const onUserUpdated = onDocumentUpdated('users/{uid}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  // Exits early unless the name or photo changed.
  if (!snapshotChanged(before, after) || !after) return;
  await updateMemberSnapshots(
    event.params.uid,
    String(after.displayName ?? ''),
    (after.photoPath as string | null) ?? null,
  );
});
