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
  return (
    before.displayName !== after.displayName ||
    before.photoPath !== after.photoPath ||
    before.avatarColor !== after.avatarColor
  );
}

/**
 * users updated → name, photo, and icon color (SET-8) on the person's
 * groupMembers and direct conversations.
 */
export const onUserUpdated = onDocumentUpdated('users/{uid}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  // Exits early unless the name, photo, or icon color changed.
  if (!snapshotChanged(before, after) || !event.data) return;
  // Copies the profile as it is now, not this event's snapshot: quick
  // changes (a few color taps) can run out of order or twice, and a late
  // run must not put an older name, photo, or color back.
  const current = (await event.data.after.ref.get()).data();
  if (!current) return;
  await updateMemberSnapshots(
    event.params.uid,
    String(current.displayName ?? ''),
    (current.photoPath as string | null) ?? null,
    (current.avatarColor as string | null) ?? null,
  );
});
