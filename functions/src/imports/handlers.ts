// Thin entry points for imports (ARCH §6.13).
import { z } from 'zod';
import { onCall } from '../shared/callable.js';
import { requireAuth } from '../shared/guards.js';
import { parse } from '../shared/validate.js';
import { importEvents as runImport, importSources } from './service.js';

/** A calendar file's text: well over a season, under a callable's limit. */
const MAX_ICS_CHARS = 1_000_000;

const ImportEventsInput = z
  .object({
    groupId: z.string().min(1),
    source: z.enum(importSources),
    url: z.string().trim().min(1).max(2000).optional(),
    ics: z.string().min(1).max(MAX_ICS_CHARS).optional(),
    includePast: z.boolean().default(false),
    dryRun: z.boolean().default(true),
  })
  .refine((i) => (i.url === undefined) !== (i.ics === undefined), 'link-or-file');

/**
 * Previews (dryRun, the default) or imports a team's events from another
 * app (SPEC IMPORT-1 to IMPORT-5): { groupId, source: 'gamechanger', url
 * (the schedule's calendar link) or ics (a calendar file's text),
 * includePast?, dryRun? }. Team admins only. Returns the counts, what was
 * skipped and why, and a sample of the new events.
 */
export const importEvents = onCall({ timeoutSeconds: 120 }, async (request) => {
  const uid = requireAuth(request);
  const input = parse(ImportEventsInput, request.data);
  return runImport(input, { uid, superAdmin: request.auth?.token.superAdmin === true });
});
