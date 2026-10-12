// A team's status (ADMIN-2, ARCH §6.2 groups.status): active, archived, or
// suspended. archivedAt and suspendedAt say when; `status` is kept beside
// them so the admin panel can filter teams with one indexed query, in any
// sort, instead of scanning. Only Functions write the three fields.

export const teamStatusValues = ['active', 'archived', 'suspended'] as const;
export type TeamStatus = (typeof teamStatusValues)[number];

/**
 * A team's status from its archivedAt and suspendedAt. Suspended wins over
 * archived: a suspended team is closed to its members either way.
 */
export function teamStatus(group: { archivedAt?: unknown; suspendedAt?: unknown }): TeamStatus {
  if (group.suspendedAt != null) return 'suspended';
  if (group.archivedAt != null) return 'archived';
  return 'active';
}
