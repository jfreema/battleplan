// The audit log (ADMIN-6): every admin or destructive action gets an entry.
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { db } from '../shared/admin.js';
import { Collections, Limits } from '../shared/constants.js';

export interface AuditEntry {
  actorId: string;
  action: string;
  groupId?: string;
  targetType: string;
  targetId: string;
  before?: Record<string, unknown>;
  after?: Record<string, unknown>;
}

/** Who made a Firestore write, from a trigger's auth context. */
export interface WriteActor {
  /** 'app_user' for a signed-in person; Functions and the console are others. */
  authType: string;
  authId?: string;
}

/**
 * Records a document or event a person deleted from the app (ADMIN-6,
 * ADMIN-8), when it wasn't theirs: an admin or super admin removing
 * someone else's. Deletes by Functions (which audit their own actions, such
 * as resolving a report or deleting a team) and by the author are left
 * out. Returns whether an entry was written.
 */
export async function auditClientDelete(
  kind: 'document' | 'event',
  id: string,
  data: FirebaseFirestore.DocumentData | undefined,
  actor: WriteActor,
): Promise<boolean> {
  if (actor.authType !== 'app_user' || !actor.authId || !data) return false;
  const owner = String((kind === 'document' ? data.uploadedBy : data.createdBy) ?? '');
  if (owner === actor.authId) return false;
  await audit({
    actorId: actor.authId,
    action: kind === 'document' ? 'deleteDocument' : 'deleteEvent',
    groupId: typeof data.groupId === 'string' ? data.groupId : undefined,
    targetType: kind,
    targetId: id,
    before:
      kind === 'document'
        ? { name: data.name ?? null, kind: data.kind ?? null, uploadedBy: owner || null }
        : { title: data.title ?? null, type: data.type ?? null, createdBy: owner || null },
  });
  return true;
}

/** Records [entry], kept for a year through the auditLogs TTL policy. */
export async function audit(entry: AuditEntry): Promise<void> {
  await db()
    .collection(Collections.auditLogs)
    .add({
      ...entry,
      groupId: entry.groupId ?? null,
      before: entry.before ?? null,
      after: entry.after ?? null,
      createdAt: FieldValue.serverTimestamp(),
      expiresAt: Timestamp.fromMillis(Date.now() + Limits.auditLogTtlDays * 86_400_000),
    });
}
