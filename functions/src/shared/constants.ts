// GENERATED from shared/constants.json by tools/gen_constants.dart. Do not edit.

export const ID_SEPARATOR = '_';
export const INVITE_CODE_ALPHABET = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

export const Collections = {
  users: 'users',
  devices: 'devices',
  userBlocks: 'userBlocks',
  groups: 'groups',
  groupMembers: 'groupMembers',
  players: 'players',
  playerGuardians: 'playerGuardians',
  guardianRequests: 'guardianRequests',
  invites: 'invites',
  messages: 'messages',
  polls: 'polls',
  pollVotes: 'pollVotes',
  eventSeries: 'eventSeries',
  events: 'events',
  rsvps: 'rsvps',
  groupDocuments: 'groupDocuments',
  notifications: 'notifications',
  reports: 'reports',
  auditLogs: 'auditLogs',
  rateLimits: 'rateLimits',
  config: 'config',
  licenses: 'licenses',
  notifyLog: 'notifyLog',
} as const;

export const Limits = {
  messageTextMax: 4000,
  messageAttachmentsMax: 10,
  messagePageSize: 50,
  messageMinIntervalMs: 1000,
  mentionsMax: 20,
  pollQuestionMax: 200,
  pollOptionsMin: 2,
  pollOptionsMax: 10,
  pollOptionTextMax: 80,
  eventRemindersMax: 6,
  seriesSkipDatesMax: 100,
  seriesMaxMonths: 12,
  groupNameMax: 50,
  groupsPerUserMax: 100,
  groupsCreatedPerUserPerDay: 5,
  membersPerGroupMax: 500,
  playersPerGroupMax: 200,
  guardiansPerPlayerMax: 4,
  pastedRosterLinesMax: 200,
  pastedMembersMax: 100,
  emailInvitesPerBatchMax: 50,
  emailInvitesPerUserPerDay: 50,
  emailInvitesPerGroupPerDay: 200,
  addByEmailPerGroupPerDay: 200,
  inviteRedeemsPerUserPerHour: 20,
  invitePreviewsPerIpPerHour: 60,
  guardianRequestsPerUserPerDay: 10,
  reportsPerUserPerDay: 20,
  queryLimitMax: 100,
  unreadCountCap: 100,
  notificationPageSize: 30,
  notificationTtlDays: 90,
  auditLogTtlDays: 365,
  rateLimitTtlDays: 2,
  inviteCodeLength: 8,
  emailInviteExpiryDays: 14,
  defaultStorageQuotaGb: 5,
  maxUploadMb: 25,
  maxImageMb: 10,
  lastReadThrottleSeconds: 10,
  plusStorageQuotaGb: 25,
  plusMaxUploadMb: 100,
  licenseDefaultMonths: 12,
  licenseMaxMonths: 36,
  licenseMoveCooldownDays: 30,
  licenseReminderFirstDays: 30,
  licenseReminderSecondDays: 7,
  pinnedMessagesMax: 3,
  deviceStaleDays: 60,
  notificationBodyMax: 140,
  notifyLogTtlDays: 7,
  pushTokensPerSend: 500,
  mutedForeverMs: 253402214400000,
} as const;

export const TEAM_COLORS = [
  '#2F5BEA',
  '#0F8A5F',
  '#C2410C',
  '#B91C1C',
  '#7C3AED',
  '#0E7490',
  '#A16207',
  '#BE185D',
  '#4D7C0F',
  '#1D4ED8',
  '#9333EA',
  '#334155',
] as const;

export const userStatusValues = ['provisioned', 'active', 'disabled'] as const;
export type UserStatus = (typeof userStatusValues)[number];

export const themePreferenceValues = ['system', 'light', 'dark'] as const;
export type ThemePreference = (typeof themePreferenceValues)[number];

export const teamTypeValues = ['adult', 'youth'] as const;
export type TeamType = (typeof teamTypeValues)[number];

export const sportValues = ['baseball', 'basketball', 'football', 'hockey', 'lacrosse', 'soccer', 'softball', 'volleyball', 'other'] as const;
export type Sport = (typeof sportValues)[number];

export const memberRoleValues = ['owner', 'admin', 'member'] as const;
export type MemberRole = (typeof memberRoleValues)[number];

export const notificationLevelValues = ['all', 'important', 'none'] as const;
export type NotificationLevel = (typeof notificationLevelValues)[number];

export const messageTypeValues = ['text', 'image', 'poll', 'event', 'system'] as const;
export type MessageType = (typeof messageTypeValues)[number];

export const reactionValues = ['like', 'love', 'dislike', 'laugh', 'fire', 'clap', 'party', 'hundred', 'pray', 'wow', 'sad', 'angry', 'baseball', 'basketball', 'soccer', 'trophy'] as const;
export type Reaction = (typeof reactionValues)[number];

export const freeReactionValues = ['like', 'love', 'dislike', 'laugh'] as const;
export type FreeReaction = (typeof freeReactionValues)[number];

export const eventTypeValues = ['game', 'practice', 'meeting', 'social', 'other'] as const;
export type EventType = (typeof eventTypeValues)[number];

export const homeAwayValues = ['home', 'away'] as const;
export type HomeAway = (typeof homeAwayValues)[number];

export const rsvpForValues = ['members', 'players'] as const;
export type RsvpFor = (typeof rsvpForValues)[number];

export const participantTypeValues = ['member', 'player'] as const;
export type ParticipantType = (typeof participantTypeValues)[number];

export const rsvpStatusValues = ['going', 'maybe', 'not_going'] as const;
export type RsvpStatus = (typeof rsvpStatusValues)[number];

export const documentKindValues = ['file', 'link'] as const;
export type DocumentKind = (typeof documentKindValues)[number];

export const reportReasonValues = ['spam', 'harassment', 'inappropriate', 'other'] as const;
export type ReportReason = (typeof reportReasonValues)[number];

export const reportStatusValues = ['open', 'actioned', 'dismissed'] as const;
export type ReportStatus = (typeof reportStatusValues)[number];

export const devicePlatformValues = ['ios', 'android', 'web'] as const;
export type DevicePlatform = (typeof devicePlatformValues)[number];

export const planTierValues = ['free', 'plus'] as const;
export type PlanTier = (typeof planTierValues)[number];

export const planFeatureValues = ['editMessages', 'extraReactions', 'chatTheme', 'pinMessages', 'attendanceExport', 'brandedInvite', 'moreStorage'] as const;
export type PlanFeature = (typeof planFeatureValues)[number];

export const licenseSourceValues = ['grant', 'stripe', 'appStore', 'play'] as const;
export type LicenseSource = (typeof licenseSourceValues)[number];

export const notifyKindValues = ['message', 'reply', 'addedToTeam', 'madeAdmin', 'guardianRequest', 'guardianApproved', 'playerAdded', 'contentReported', 'planReminder', 'pollCreated', 'pollClosed', 'eventCreated', 'eventChanged', 'eventReminder', 'documentAdded'] as const;
export type NotifyKind = (typeof notifyKindValues)[number];

export const notificationPrefValues = ['messages', 'replies', 'mentions', 'polls', 'eventsNew', 'eventsChanged', 'reminders', 'documents'] as const;
export type NotificationPref = (typeof notificationPrefValues)[number];

export const notifyChannelValues = ['messages', 'replies', 'team', 'polls', 'events', 'documents'] as const;
export type NotifyChannel = (typeof notifyChannelValues)[number];

/** How each notification kind behaves (NOTIF-2): pushes at "Important only", its global switch, center, channel. */
export const NOTIFY_KINDS = {
  message: { important: false, pref: 'messages' as NotificationPref | null, center: false, channel: 'messages' as NotifyChannel },
  reply: { important: true, pref: 'replies' as NotificationPref | null, center: true, channel: 'replies' as NotifyChannel },
  addedToTeam: { important: true, pref: null as NotificationPref | null, center: true, channel: 'team' as NotifyChannel },
  madeAdmin: { important: true, pref: null as NotificationPref | null, center: true, channel: 'team' as NotifyChannel },
  guardianRequest: { important: true, pref: null as NotificationPref | null, center: true, channel: 'team' as NotifyChannel },
  guardianApproved: { important: true, pref: null as NotificationPref | null, center: true, channel: 'team' as NotifyChannel },
  playerAdded: { important: true, pref: null as NotificationPref | null, center: true, channel: 'team' as NotifyChannel },
  contentReported: { important: true, pref: null as NotificationPref | null, center: true, channel: 'team' as NotifyChannel },
  planReminder: { important: true, pref: null as NotificationPref | null, center: true, channel: 'team' as NotifyChannel },
  pollCreated: { important: false, pref: 'polls' as NotificationPref | null, center: true, channel: 'polls' as NotifyChannel },
  pollClosed: { important: false, pref: 'polls' as NotificationPref | null, center: true, channel: 'polls' as NotifyChannel },
  eventCreated: { important: false, pref: 'eventsNew' as NotificationPref | null, center: true, channel: 'events' as NotifyChannel },
  eventChanged: { important: true, pref: 'eventsChanged' as NotificationPref | null, center: true, channel: 'events' as NotifyChannel },
  eventReminder: { important: true, pref: 'reminders' as NotificationPref | null, center: true, channel: 'events' as NotifyChannel },
  documentAdded: { important: false, pref: 'documents' as NotificationPref | null, center: true, channel: 'documents' as NotifyChannel },
} as const;
