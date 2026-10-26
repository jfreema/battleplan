// What the admin callables accept (SPEC §6.11, ARCH §6.4), and the small
// pure rules they share, kept free of Firebase calls so they can be unit
// tested. Every list is bounded: at most ADMIN_PAGE_MAX rows per call.
import { Timestamp } from 'firebase-admin/firestore';
import { z } from 'zod';
import {
  Limits,
  memberRoleValues,
  REMINDER_OFFSETS_MINUTES,
  reportStatusValues,
  sportValues,
} from '../shared/constants.js';
import { teamColor } from '../shared/team_color.js';
import { teamStatusValues } from '../teams/status.js';

/** The Gumdrop candy message colors of the chat look (CHAT-18), stored as their
 * Gumdrop Pop Dark faces (lib/features/groups/domain/chat_colors.dart; also listed in
 * firestore.rules validChatTheme). */
export const CHAT_CANDY_COLORS = ['#4D9BFF', '#FF7AC8', '#A88BFF', '#4DDC8C', '#FFD84A', '#FF9B42', '#FF5D73'] as const;

/** The most rows one admin list call returns (ADMIN-2, ADMIN-4, ADMIN-5). */
export const ADMIN_PAGE_MAX = 50;

/** The longest announcement banner (ADMIN-7). */
export const BANNER_TEXT_MAX = Limits.announcementBannerMax;
/** The longest note a report resolution saves (ADMIN-5). */
export const REPORT_NOTE_MAX = Limits.reportNoteMax;

/** A document ID or uid as callers send it: no slashes, so it can't name a path. */
export const Id = z.string().min(1).max(128).regex(/^[^/]+$/);

const Limit = z.number().int().min(1).max(ADMIN_PAGE_MAX).default(25);
/** A page's last row ID, from the previous call's `nextCursor`. */
const Cursor = Id.optional();
/** A search: a name (or email) prefix, case-insensitive. Blank means none. */
const Query = z
  .string()
  .trim()
  .max(100)
  .optional()
  .transform((q) => (q ? q.toLowerCase() : undefined));

export const GroupInput = z.object({ groupId: Id });
export const UidInput = z.object({ uid: Id });

// ---- Teams (ADMIN-2, ADMIN-3) ------------------------------------------------

export const teamSortValues = ['created', 'activity', 'members', 'storage'] as const;
export type TeamSort = (typeof teamSortValues)[number];

export { teamStatus, teamStatusValues, type TeamStatus } from '../teams/status.js';

/** The groups field each sort orders by, newest or largest first. */
export const TEAM_SORT_FIELD: Record<TeamSort, string> = {
  created: 'createdAt',
  activity: 'lastMessageAt',
  members: 'memberCount',
  storage: 'storageBytes',
};

export const ListTeamsInput = z.object({
  query: Query,
  sort: z.enum(teamSortValues).default('created'),
  status: z.enum(teamStatusValues).optional(),
  cursor: Cursor,
  limit: Limit,
});

export const SetSuspendedInput = z.object({
  groupId: Id,
  suspended: z.boolean(),
  note: z.string().trim().max(REPORT_NOTE_MAX).optional(),
});

export const ArchiveInput = z.object({ groupId: Id, archived: z.boolean() });

export const DeleteGroupInput = z.object({ groupId: Id, confirmName: z.string().max(Limits.groupNameMax + 10) });

/** The longest team description (TEAM-5), as the rules' validGroup allows. */
export const GROUP_DESCRIPTION_MAX = 500;
/** The longest Storage path a team's logo or background may have. */
const PATH_MAX = 512;

/** A file name under one of a team's folders, as validGroup and validChatTheme match it. */
const teamFile = (groupId: string, folder: 'avatar' | 'theme', path: string) =>
  path.startsWith(`groups/${groupId}/${folder}/`) && /^[^/]+$/.test(path.slice(`groups/${groupId}/${folder}/`.length));

const StoragePath = z.string().min(1).max(PATH_MAX).nullable().optional();

/**
 * A super admin's edit to a team they aren't on (ADMIN-3): the profile and
 * settings fields its admins may write, validated as the rules' validGroup
 * and validChatTheme do (TEAM-5, CHAT-18). The logo and background are
 * uploaded first (storage.rules let super admins) and named here by path.
 * `backgroundPath` changes only the chat look's photo.
 */
export const UpdateGroupInput = z
  .object({
    groupId: Id,
    name: z.string().trim().min(1).max(Limits.groupNameMax).optional(),
    description: z.string().trim().max(GROUP_DESCRIPTION_MAX).optional(),
    color: teamColor.nullable().optional(),
    sport: z.enum(sportValues).optional(),
    timeZone: z.string().min(1).max(64).optional(),
    settings: z
      .strictObject({
        membersCanCreateEvents: z.boolean().optional(),
        membersCanCreatePolls: z.boolean().optional(),
        membersCanUploadDocs: z.boolean().optional(),
        membersCanInvite: z.boolean().optional(),
        allowMaybe: z.boolean().optional(),
        defaultReminderOffsets: z
          .array(z.number().int().refine((m) => (REMINDER_OFFSETS_MINUTES as readonly number[]).includes(m)))
          .max(Limits.eventRemindersMax)
          .optional(),
      })
      .optional(),
    chatTheme: z
      .strictObject({
        bubbleColor: z.union([teamColor, z.enum(CHAT_CANDY_COLORS)]).nullable().optional(),
        background: z.enum(['plain', 'pattern', 'photo']).optional(),
        backgroundPath: StoragePath,
      })
      .optional(),
    photoPath: StoragePath,
    backgroundPath: StoragePath,
  })
  .superRefine((g, ctx) => {
    const check = (path: string | null | undefined, folder: 'avatar' | 'theme', at: (string | number)[]) => {
      if (path && !teamFile(g.groupId, folder, path)) {
        ctx.addIssue({ code: 'custom', path: at, message: `Must be a file in groups/${g.groupId}/${folder}/.` });
      }
    };
    check(g.photoPath, 'avatar', ['photoPath']);
    check(g.backgroundPath, 'theme', ['backgroundPath']);
    check(g.chatTheme?.backgroundPath, 'theme', ['chatTheme', 'backgroundPath']);
  })
  .refine((g) => Object.entries(g).some(([k, v]) => k !== 'groupId' && v !== undefined), {
    message: 'Nothing to change.',
  });
export type UpdateGroup = z.infer<typeof UpdateGroupInput>;


// ---- Users (ADMIN-4) ---------------------------------------------------------

export const userFilterValues = ['added', 'active', 'disabled', 'superAdmin'] as const;
export type UserFilter = (typeof userFilterValues)[number];

/** The users field and value each filter matches ("Added" = an added account that hasn't signed in). */
export const USER_FILTER: Record<UserFilter, [field: string, value: string | boolean]> = {
  added: ['status', 'provisioned'],
  active: ['status', 'active'],
  disabled: ['status', 'disabled'],
  superAdmin: ['superAdmin', true],
};

export const ListUsersInput = z.object({
  query: Query,
  filter: z.enum(userFilterValues).optional(),
  cursor: Cursor,
  limit: Limit,
});

/**
 * Roles an admin can give when adding someone to a team; ownership moves
 * only by transfer, and 'participant' is a direct conversation's (CHAT-19).
 */
const AddRole = z.enum(memberRoleValues).exclude(['owner', 'participant']);
const DisplayName = z.string().trim().min(1).max(50);
const Email = z.string().trim().toLowerCase().pipe(z.email()).pipe(z.string().max(200));

export const CreateUserInput = z
  .object({ email: Email, displayName: DisplayName, groupId: Id.optional(), role: AddRole.optional() })
  .refine((u) => u.role === undefined || u.groupId !== undefined, { message: 'A role needs a team.' });

export const UpdateUserInput = z
  .object({
    uid: Id,
    displayName: DisplayName.optional(),
    addToGroup: z.object({ groupId: Id, role: AddRole.default('member') }).optional(),
  })
  .refine((u) => u.displayName !== undefined || u.addToGroup !== undefined, { message: 'Nothing to change.' });

export const SetDisabledInput = z.object({ uid: Id, disabled: z.boolean() });
export const SetSuperAdminInput = z.object({ uid: Id, superAdmin: z.boolean() });

// ---- Players (ADMIN-3) -------------------------------------------------------

/** A player's optional text (number, position): trimmed, and blank saves as none. */
const PlayerText = (max: number) =>
  z
    .string()
    .trim()
    .max(max)
    .nullable()
    .optional()
    .transform((v) => (v === undefined ? undefined : v || null));

/**
 * A super admin's edit to a player on a team they aren't on (ADMIN-3):
 * only a name, number, position, and walk-up song (PLAYER-10), within the
 * rules' validPlayer limits.
 */
export const UpdatePlayerInput = z
  .object({
    playerId: Id,
    displayName: z.string().trim().min(1).max(60).optional(),
    jerseyNumber: PlayerText(4),
    position: PlayerText(30),
    walkUpSong: PlayerText(Limits.walkUpSongMax),
  })
  .refine(
    (p) =>
      p.displayName !== undefined ||
      p.jerseyNumber !== undefined ||
      p.position !== undefined ||
      p.walkUpSong !== undefined,
    { message: 'Nothing to change.' },
  );

// ---- Reports (ADMIN-5) -------------------------------------------------------

export const ListReportsInput = z.object({
  status: z.enum(reportStatusValues).default('open'),
  cursor: Cursor,
  limit: Limit,
});

export const reportActionValues = ['deleteContent', 'removeMember', 'disableUser', 'suspendTeam', 'dismiss'] as const;
export type ReportAction = (typeof reportActionValues)[number];

export const ResolveReportInput = z.object({
  reportId: Id,
  action: z.enum(reportActionValues),
  note: z.string().trim().min(1).max(REPORT_NOTE_MAX),
});

/**
 * What a report's resolution records for [action] (ARCH §6.2
 * reports.resolution), or null when the action can't apply: a reported
 * person has no content to delete.
 */
export function resolutionFor(
  action: ReportAction,
  targetType: string,
): 'deletedMessage' | 'deletedDocument' | 'removedMember' | 'disabledUser' | 'suspendedTeam' | 'none' | null {
  switch (action) {
    case 'deleteContent':
      return targetType === 'message' ? 'deletedMessage' : targetType === 'document' ? 'deletedDocument' : null;
    case 'removeMember':
      return 'removedMember';
    case 'disableUser':
      return 'disabledUser';
    case 'suspendTeam':
      return 'suspendedTeam';
    case 'dismiss':
      return 'none';
  }
}

// ---- Platform settings (ADMIN-7) ---------------------------------------------

export const bannerSeverityValues = ['info', 'warning', 'critical'] as const;

export const UpdateConfigInput = z.object({
  allowUserGroupCreation: z.boolean(),
  // Nobody can be on more than groupsPerUserMax teams, so a higher daily
  // limit would mean nothing.
  maxGroupsCreatedPerUserPerDay: z.number().int().min(1).max(Limits.groupsPerUserMax),
  defaultStorageQuotaMb: z.number().int().min(1).max(Limits.storageQuotaMaxMb),
  // storage.rules refuse files over Limits.maxUploadMb whatever this says.
  maxUploadMb: z.number().int().min(1).max(Limits.maxUploadMb),
  supportEmail: Email,
  // ADMIN-9: email super admins about new accounts and teams. Optional, so
  // an admin panel from before it still saves (and leaves it as it was).
  emailAdminAlerts: z.boolean().optional(),
  announcementBanner: z
    .object({
      text: z.string().trim().min(1).max(BANNER_TEXT_MAX),
      severity: z.enum(bannerSeverityValues),
      // ISO 8601, e.g. "2026-11-01T00:00:00.000Z"; shown until then.
      expiresAt: z.iso.datetime({ offset: true }),
    })
    .nullable(),
});
export type AppConfigInput = z.infer<typeof UpdateConfigInput>;

/** config/app's fields for [input] (ARCH §6.2), with the banner's end as a Timestamp. */
export function configFields(input: AppConfigInput): Record<string, unknown> {
  const { emailAdminAlerts, ...rest } = input;
  return {
    ...rest,
    ...(emailAdminAlerts === undefined ? {} : { emailAdminAlerts }),
    announcementBanner: input.announcementBanner && {
      text: input.announcementBanner.text,
      severity: input.announcementBanner.severity,
      expiresAt: Timestamp.fromDate(new Date(input.announcementBanner.expiresAt)),
    },
  };
}

// ---- Shapes the app reads ----------------------------------------------------

/** A Firestore Timestamp as ISO 8601 (the callables' date format, as in Media), else null. */
export function iso(value: unknown): string | null {
  return value instanceof Timestamp ? value.toDate().toISOString() : null;
}

/** [data] with every Timestamp in it as ISO 8601, so it travels as plain JSON. */
export function plain(data: unknown): unknown {
  if (data instanceof Timestamp) return data.toDate().toISOString();
  if (Array.isArray(data)) return data.map(plain);
  if (data && typeof data === 'object') {
    return Object.fromEntries(Object.entries(data).map(([k, v]) => [k, plain(v)]));
  }
  return data;
}

/** The end of a prefix range: every string that starts with [prefix] sorts below it. */
export function prefixEnd(prefix: string): string {
  return `${prefix}`;
}
