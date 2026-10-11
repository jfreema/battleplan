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
