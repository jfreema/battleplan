// Thin entry points for the dues domain (ARCH §6.4).
import { onCall } from '../shared/callable.js';
import { requireAuth } from '../shared/guards.js';
import { parse } from '../shared/validate.js';
import { createDue, DeleteDueInput, deleteDueAndCharges, dueTerms, editDue, SaveDueInput } from './service.js';

/**
 * Adds a due with a charge for each person on it, or, with a dueId, edits
 * one and copies its terms to every charge (DUES-1, DUES-2): team admins
 * and super admins, on a team that isn't archived. Returns the due's ID.
 */
export const saveDue = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = parse(SaveDueInput, request.data);
  const actor = { uid, superAdmin: request.auth?.token.superAdmin === true };
  const terms = dueTerms(input);
  if (input.dueId) {
    await editDue(input.groupId, input.dueId, terms, actor);
    return { dueId: input.dueId };
  }
  return { dueId: await createDue(input.groupId, terms, input.participantIds ?? [], actor) };
});

/** Deletes a due and all its charges (DUES-1): team admins and super admins. */
export const deleteDue = onCall(async (request) => {
  const uid = requireAuth(request);
  const { dueId } = parse(DeleteDueInput, request.data);
  await deleteDueAndCharges(dueId, { uid, superAdmin: request.auth?.token.superAdmin === true });
  return { ok: true };
});
