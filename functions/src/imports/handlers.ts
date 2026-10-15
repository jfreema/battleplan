// Thin entry points for imports (ARCH §6.13).
import { z } from 'zod';
import { onCall } from '../shared/callable.js';
import { requireAuth } from '../shared/guards.js';
import { parse } from '../shared/validate.js';
import {
  chatSources,
  DOCUMENTS_PER_CALL,
  importDocuments as runDocumentImport,
  importMessages as runMessageImport,
  MESSAGES_PER_CALL,
} from './messages.js';
import { importEvents as runImport, importSources } from './service.js';

/** A calendar file's text: well over a season, under a callable's limit. */
const MAX_ICS_CHARS = 1_000_000;

const ImportEventsInput = z
  .object({
    groupId: z.string().min(1),
    source: z.enum(importSources),
    url: z.string().trim().min(1).max(2000).optional(),
    ics: z.string().min(1).max(MAX_ICS_CHARS).optional(),
    events: z
      .array(
        z.object({
          sourceId: z.string().min(1).max(200),
          title: z.string().max(500),
          description: z.string().max(10_000).default(''),
          location: z.string().max(1000).default(''),
          allDay: z.boolean(),
          startMs: z.number().int(),
          endMs: z.number().int().nullable().default(null),
          timeZone: z.string().max(64).nullable().default(null),
          canceled: z.boolean().default(false),
        }),
      )
      .max(5000)
      .optional(),
    includePast: z.boolean().default(false),
    dryRun: z.boolean().default(true),
  })
  // A calendar app's link or file, or GroupMe's events as a list.
  .refine(
    (i) =>
      i.source === 'groupme'
        ? i.events !== undefined && i.url === undefined && i.ics === undefined
        : i.events === undefined && (i.url === undefined) !== (i.ics === undefined),
    'link-or-file',
  );

/**
 * Previews (dryRun, the default) or imports a team's events from another
 * app (SPEC IMPORT-1 to IMPORT-9): { groupId, source: 'gamechanger' or
 * 'teamreach' with url (the schedule's calendar link) or ics (a calendar
 * file's text), or 'groupme' with events (read from its export),
 * includePast?, dryRun? }. Team admins only. Returns the counts, what was
 * skipped and why, and a sample of the new events.
 */
export const importEvents = onCall({ timeoutSeconds: 120 }, async (request) => {
  const uid = requireAuth(request);
  const input = parse(ImportEventsInput, request.data);
  return runImport(input, { uid, superAdmin: request.auth?.token.superAdmin === true });
});

/** A source's ID for a message, a person, or a file. */
const SourceId = z.string().regex(/^[A-Za-z0-9_.:-]{1,64}$/);
/** Times from GroupMe's start (2010) to a day ahead. */
const PastMs = z
  .number()
  .int()
  .min(Date.UTC(2010, 0, 1))
  .refine((ms) => ms <= Date.now() + 86_400_000, 'future');
const StoragePath = z.string().min(1).max(500);

const ImportMessagesInput = z.object({
  groupId: z.string().min(1),
  source: z.enum(chatSources),
  messages: z
    .array(
      z.object({
        sourceId: SourceId,
        authorSourceId: SourceId,
        authorName: z.string().max(200),
        text: z.string().max(8000),
        createdAtMs: PastMs,
        replyToSourceId: SourceId.optional(),
        photos: z
          .array(z.object({ path: StoragePath, width: z.number().int().min(0), height: z.number().int().min(0) }))
          .max(10)
          .default([]),
      }),
    )
    .min(1)
    .max(MESSAGES_PER_CALL),
  dryRun: z.boolean().default(false),
});

/**
 * Adds a batch of a team's chat history from another app (SPEC IMPORT-9):
 * { groupId, source: 'groupme', messages: [{ sourceId, authorSourceId,
 * authorName, text, createdAtMs, replyToSourceId?, photos: [{ path, width,
 * height }] }], dryRun? }, oldest first, photos already in each message's
 * folder. Team admins only. Returns how many were added and already
 * there; a dry run writes nothing and lists the ones already there.
 */
export const importMessages = onCall({ timeoutSeconds: 120 }, async (request) => {
  const uid = requireAuth(request);
  const input = parse(ImportMessagesInput, request.data);
  return runMessageImport(input, { uid, superAdmin: request.auth?.token.superAdmin === true });
});

const ImportDocumentsInput = z.object({
  groupId: z.string().min(1),
  source: z.enum(chatSources),
  documents: z
    .array(
      z.object({
        sourceId: SourceId,
        name: z.string().max(300),
        path: StoragePath,
        sharedByName: z.string().max(200),
        sharedAtMs: PastMs,
      }),
    )
    .min(1)
    .max(DOCUMENTS_PER_CALL),
  dryRun: z.boolean().default(false),
});

/**
 * Adds files shared in another app as the team's documents (SPEC
 * IMPORT-9): { groupId, source: 'groupme', documents: [{ sourceId, name,
 * path, sharedByName, sharedAtMs }], dryRun? }, each file already in its
 * document's folder. Team admins only. A dry run lists the ones already
 * there.
 */
export const importDocuments = onCall({ timeoutSeconds: 120 }, async (request) => {
  const uid = requireAuth(request);
  const input = parse(ImportDocumentsInput, request.data);
  return runDocumentImport(input, { uid, superAdmin: request.auth?.token.superAdmin === true });
});
