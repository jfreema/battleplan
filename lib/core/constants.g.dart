// GENERATED from shared/constants.json by tools/gen_constants.dart. Do not edit.
// ignore_for_file: public_member_api_docs, constant_identifier_names

const String idSeparator = '_';
const String inviteCodeAlphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

/// Firestore collection names.
abstract final class Collections {
  static const String users = 'users';
  static const String devices = 'devices';
  static const String userBlocks = 'userBlocks';
  static const String groups = 'groups';
  static const String groupMembers = 'groupMembers';
  static const String players = 'players';
  static const String playerGuardians = 'playerGuardians';
  static const String playerDetails = 'playerDetails';
  static const String guardianRequests = 'guardianRequests';
  static const String invites = 'invites';
  static const String messages = 'messages';
  static const String polls = 'polls';
  static const String pollVotes = 'pollVotes';
  static const String eventSeries = 'eventSeries';
  static const String events = 'events';
  static const String rsvps = 'rsvps';
  static const String groupDocuments = 'groupDocuments';
  static const String notifications = 'notifications';
  static const String reports = 'reports';
  static const String auditLogs = 'auditLogs';
  static const String rateLimits = 'rateLimits';
  static const String config = 'config';
  static const String notifyLog = 'notifyLog';
  static const String plays = 'plays';
  static const String calendarLinks = 'calendarLinks';
  static const String teamCalendars = 'teamCalendars';
  static const String answerLinks = 'answerLinks';
}

/// Limits shared with the server and security rules.
abstract final class Limits {
  static const int messageTextMax = 4000;
  static const int messageAttachmentsMax = 10;
  static const int messagePageSize = 50;
  static const int messageMinIntervalMs = 1000;
  static const int mentionsMax = 20;
  static const int pollQuestionMax = 200;
  static const int pollOptionsMin = 2;
  static const int pollOptionsMax = 10;
  static const int pollOptionTextMax = 80;
  static const int eventRemindersMax = 6;
  static const int eventTitleMax = 100;
  static const int eventNotesMax = 2000;
  static const int locationNameMax = 100;
  static const int locationAddressMax = 200;
  static const int opponentMax = 60;
  static const int arriveMinutesMax = 240;
  static const int rsvpNoteMax = 200;
  static const int documentNameMax = 100;
  static const int documentDescriptionMax = 500;
  static const int documentUrlMax = 2000;
  static const int playTitleMax = 80;
  static const int playNoteMax = 1000;
  static const int playStepsMax = 10;
  static const int playElementsMax = 150;
  static const int playPointsMax = 64;
  static const int playLabelMax = 12;
  static const int playTextMax = 200;
  static const int playsPerEventMax = 5;
  static const int announcementBannerMax = 280;
  static const int reportNoteMax = 500;
  static const int seriesIntervalMax = 8;
  static const int seriesEventsMax = 400;
  static const int seriesSkipDatesMax = 100;
  static const int seriesMaxMonths = 12;
  static const int groupNameMax = 50;
  static const int groupsPerUserMax = 100;
  static const int groupsCreatedPerUserPerDay = 5;
  static const int membersPerGroupMax = 500;
  static const int playersPerGroupMax = 200;
  static const int guardiansPerPlayerMax = 4;
  static const int contactPhoneMax = 30;
  static const int contactEmailMax = 254;
  static const int emergencyContactsMax = 2;
  static const int emergencyContactNameMax = 60;
  static const int emergencyContactPhoneMax = 30;
  static const int emergencyContactRelationshipMax = 30;
  static const int medicalNotesMax = 500;
  static const int playerNotesMax = 500;
  static const int walkUpSongMax = 100;
  static const int playerAgeMaxYears = 100;
  static const int pastedRosterLinesMax = 200;
  static const int pastedMembersMax = 100;
  static const int emailInvitesPerBatchMax = 50;
  static const int emailInvitesPerUserPerDay = 50;
  static const int emailInvitesPerGroupPerDay = 200;
  static const int addByEmailPerGroupPerDay = 200;
  static const int inviteRedeemsPerUserPerHour = 20;
  static const int invitePreviewsPerIpPerHour = 60;
  static const int guardianRequestsPerUserPerDay = 10;
  static const int reportsPerUserPerDay = 20;
  static const int directChatsPerUserPerDay = 20;
  static const int clientErrorsPerIpPerHour = 30;
  static const int securityNoticesPerUserPerDay = 10;
  static const int superAdminEmailsPerDay = 50;
  static const int avatarFilesPerUserMax = 3;
  static const int queryLimitMax = 100;
  static const int unreadCountCap = 100;
  static const int notificationPageSize = 30;
  static const int notificationTtlDays = 90;
  static const int auditLogTtlDays = 365;
  static const int rateLimitTtlDays = 2;
  static const int inviteCodeLength = 8;
  static const int emailInviteExpiryDays = 14;
  static const int defaultStorageQuotaMb = 200;
  static const int directChatStorageQuotaMb = 50;
  static const int storageQuotaMaxMb = 51200;
  static const int storageWarnPercent = 90;
  static const int maxUploadMb = 10;
  static const int maxImageMb = 10;
  static const int lastReadThrottleSeconds = 10;
  static const int pinnedMessagesMax = 3;
  static const int deviceStaleDays = 60;
  static const int notificationBodyMax = 140;
  static const int notifyLogTtlDays = 7;
  static const int pushTokensPerSend = 500;
  static const int mutedForeverMs = 253402214400000;
  static const int calendarPastDays = 60;
  static const int calendarFutureDays = 366;
  static const int calendarEventsMax = 500;
  static const int calendarCacheHours = 6;
  static const int calendarFetchedEveryMinutes = 60;
  static const int rsvpEmailPeopleMax = 100;
  static const int answerLinkTriesPerHour = 20;
}

/// The team colors (TEAM-1), as ARGB.
const List<int> teamColorValues = [
  0xFF2F5BEA,
  0xFF7BAFD4,
  0xFF0F8A5F,
  0xFFC2410C,
  0xFFB91C1C,
  0xFF7C3AED,
  0xFF0E7490,
  0xFFA16207,
  0xFFBE185D,
  0xFF4D7C0F,
  0xFF1D4ED8,
  0xFF9333EA,
  0xFF334155,
  0xFF1E3A5F,
  0xFFD4A017,
];

/// The reminder times an event can have, in minutes before (SCHED-3).
const List<int> reminderOffsetsMinutes = [15, 60, 120, 1440, 2880, 10080];

enum UserStatus {
  provisioned('provisioned'),
  active('active'),
  disabled('disabled');

  const UserStatus(this.value);

  /// The string stored in Firestore.
  final String value;

  static UserStatus? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum ThemePreference {
  system('system'),
  light('light'),
  dark('dark');

  const ThemePreference(this.value);

  /// The string stored in Firestore.
  final String value;

  static ThemePreference? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum GroupKind {
  team('team'),
  direct('direct');

  const GroupKind(this.value);

  /// The string stored in Firestore.
  final String value;

  static GroupKind? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum Sport {
  baseball('baseball'),
  basketball('basketball'),
  football('football'),
  hockey('hockey'),
  lacrosse('lacrosse'),
  soccer('soccer'),
  softball('softball'),
  volleyball('volleyball'),
  other('other');

  const Sport(this.value);

  /// The string stored in Firestore.
  final String value;

  static Sport? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum MemberRole {
  owner('owner'),
  admin('admin'),
  member('member'),
  participant('participant');

  const MemberRole(this.value);

  /// The string stored in Firestore.
  final String value;

  static MemberRole? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum NotificationLevel {
  all('all'),
  important('important'),
  none('none');

  const NotificationLevel(this.value);

  /// The string stored in Firestore.
  final String value;

  static NotificationLevel? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum MessageType {
  text('text'),
  image('image'),
  poll('poll'),
  event('event'),
  system('system');

  const MessageType(this.value);

  /// The string stored in Firestore.
  final String value;

  static MessageType? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum Reaction {
  like('like'),
  love('love'),
  dislike('dislike'),
  laugh('laugh'),
  fire('fire'),
  clap('clap'),
  party('party'),
  hundred('hundred'),
  pray('pray'),
  wow('wow'),
  sad('sad'),
  angry('angry'),
  baseball('baseball'),
  basketball('basketball'),
  soccer('soccer'),
  trophy('trophy');

  const Reaction(this.value);

  /// The string stored in Firestore.
  final String value;

  static Reaction? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum EventType {
  game('game'),
  practice('practice'),
  meeting('meeting'),
  social('social'),
  other('other');

  const EventType(this.value);

  /// The string stored in Firestore.
  final String value;

  static EventType? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum HomeAway {
  home('home'),
  away('away');

  const HomeAway(this.value);

  /// The string stored in Firestore.
  final String value;

  static HomeAway? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum PlayerStatus {
  active('active'),
  pending('pending');

  const PlayerStatus(this.value);

  /// The string stored in Firestore.
  final String value;

  static PlayerStatus? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum PlayerRelation {
  self('self'),
  guardian('guardian');

  const PlayerRelation(this.value);

  /// The string stored in Firestore.
  final String value;

  static PlayerRelation? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum ParticipantType {
  member('member'),
  player('player');

  const ParticipantType(this.value);

  /// The string stored in Firestore.
  final String value;

  static ParticipantType? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum RsvpStatus {
  going('going'),
  maybe('maybe'),
  notGoing('not_going');

  const RsvpStatus(this.value);

  /// The string stored in Firestore.
  final String value;

  static RsvpStatus? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum DocumentKind {
  file('file'),
  link('link');

  const DocumentKind(this.value);

  /// The string stored in Firestore.
  final String value;

  static DocumentKind? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum PlayBoard {
  baseball('baseball'),
  basketball('basketball'),
  soccer('soccer'),
  football('football'),
  blank('blank');

  const PlayBoard(this.value);

  /// The string stored in Firestore.
  final String value;

  static PlayBoard? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum ReportReason {
  spam('spam'),
  harassment('harassment'),
  inappropriate('inappropriate'),
  other('other');

  const ReportReason(this.value);

  /// The string stored in Firestore.
  final String value;

  static ReportReason? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum ReportStatus {
  open('open'),
  actioned('actioned'),
  dismissed('dismissed');

  const ReportStatus(this.value);

  /// The string stored in Firestore.
  final String value;

  static ReportStatus? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum DevicePlatform {
  ios('ios'),
  android('android'),
  web('web');

  const DevicePlatform(this.value);

  /// The string stored in Firestore.
  final String value;

  static DevicePlatform? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum NotifyKind {
  message('message'),
  reply('reply'),
  addedToTeam('addedToTeam'),
  madeAdmin('madeAdmin'),
  guardianRequest('guardianRequest'),
  guardianApproved('guardianApproved'),
  playerAdded('playerAdded'),
  contentReported('contentReported'),
  storageWarning('storageWarning'),
  pollCreated('pollCreated'),
  pollClosed('pollClosed'),
  eventCreated('eventCreated'),
  eventChanged('eventChanged'),
  eventReminder('eventReminder'),
  documentAdded('documentAdded'),
  mention('mention'),
  announcement('announcement'),
  directMessage('directMessage');

  const NotifyKind(this.value);

  /// The string stored in Firestore.
  final String value;

  static NotifyKind? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum NotificationPref {
  messages('messages'),
  directMessages('directMessages'),
  replies('replies'),
  mentions('mentions'),
  polls('polls'),
  eventsNew('eventsNew'),
  eventsChanged('eventsChanged'),
  reminders('reminders'),
  documents('documents');

  const NotificationPref(this.value);

  /// The string stored in Firestore.
  final String value;

  static NotificationPref? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum NotifyChannel {
  messages('messages'),
  replies('replies'),
  team('team'),
  polls('polls'),
  events('events'),
  documents('documents');

  const NotifyChannel(this.value);

  /// The string stored in Firestore.
  final String value;

  static NotifyChannel? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

/// How a notification kind behaves (NOTIF-2).
class NotifyKindInfo {
  const NotifyKindInfo({
    required this.important,
    required this.pref,
    required this.center,
    required this.channel,
  });

  /// Pushes even at a team's "Important only" level.
  final bool important;

  /// The global switch that turns it off, if any (NOTIF-4).
  final NotificationPref? pref;

  /// Listed in the notification center (NOTIF-11).
  final bool center;
  final NotifyChannel channel;
}

const Map<NotifyKind, NotifyKindInfo> notifyKindInfo = {
  NotifyKind.message: NotifyKindInfo(
    important: false,
    pref: NotificationPref.messages,
    center: false,
    channel: NotifyChannel.messages,
  ),
  NotifyKind.reply: NotifyKindInfo(
    important: true,
    pref: NotificationPref.replies,
    center: true,
    channel: NotifyChannel.replies,
  ),
  NotifyKind.addedToTeam: NotifyKindInfo(
    important: true,
    pref: null,
    center: true,
    channel: NotifyChannel.team,
  ),
  NotifyKind.madeAdmin: NotifyKindInfo(
    important: true,
    pref: null,
    center: true,
    channel: NotifyChannel.team,
  ),
  NotifyKind.guardianRequest: NotifyKindInfo(
    important: true,
    pref: null,
    center: true,
    channel: NotifyChannel.team,
  ),
  NotifyKind.guardianApproved: NotifyKindInfo(
    important: true,
    pref: null,
    center: true,
    channel: NotifyChannel.team,
  ),
  NotifyKind.playerAdded: NotifyKindInfo(
    important: true,
    pref: null,
    center: true,
    channel: NotifyChannel.team,
  ),
  NotifyKind.contentReported: NotifyKindInfo(
    important: true,
    pref: null,
    center: true,
    channel: NotifyChannel.team,
  ),
  NotifyKind.storageWarning: NotifyKindInfo(
    important: true,
    pref: null,
    center: true,
    channel: NotifyChannel.team,
  ),
  NotifyKind.pollCreated: NotifyKindInfo(
    important: false,
    pref: NotificationPref.polls,
    center: true,
    channel: NotifyChannel.polls,
  ),
  NotifyKind.pollClosed: NotifyKindInfo(
    important: false,
    pref: NotificationPref.polls,
    center: true,
    channel: NotifyChannel.polls,
  ),
  NotifyKind.eventCreated: NotifyKindInfo(
    important: false,
    pref: NotificationPref.eventsNew,
    center: true,
    channel: NotifyChannel.events,
  ),
  NotifyKind.eventChanged: NotifyKindInfo(
    important: true,
    pref: NotificationPref.eventsChanged,
    center: true,
    channel: NotifyChannel.events,
  ),
  NotifyKind.eventReminder: NotifyKindInfo(
    important: true,
    pref: NotificationPref.reminders,
    center: true,
    channel: NotifyChannel.events,
  ),
  NotifyKind.documentAdded: NotifyKindInfo(
    important: false,
    pref: NotificationPref.documents,
    center: true,
    channel: NotifyChannel.documents,
  ),
  NotifyKind.mention: NotifyKindInfo(
    important: true,
    pref: NotificationPref.mentions,
    center: true,
    channel: NotifyChannel.replies,
  ),
  NotifyKind.announcement: NotifyKindInfo(
    important: true,
    pref: null,
    center: true,
    channel: NotifyChannel.team,
  ),
  NotifyKind.directMessage: NotifyKindInfo(
    important: true,
    pref: NotificationPref.directMessages,
    center: false,
    channel: NotifyChannel.messages,
  ),
};

/// The words a team's language filter masks (SAFE-7), from shared/strong_language.json.
const List<String> strongLanguage = [
  'fuck*',
  'motherfuck*',
  'clusterfuck*',
  'shit*',
  'bullshit*',
  'dipshit*',
  'horseshit*',
  'apeshit',
  'batshit',
  'cunt*',
  'asshole*',
  'asshat*',
  'assclown*',
  'dumbass*',
  'jackass*',
  'fatass*',
  'smartass*',
  'bitch*',
  'sonofabitch',
  'bastard*',
  'dickhead*',
  'dickwad*',
  'cock',
  'cocks',
  'cocksuck*',
  'prick',
  'pricks',
  'twat*',
  'wank*',
  'douche*',
  'goddamn*',
  'pussy',
  'pussies',
  'slut*',
  'whore*',
  'skank*',
  'tits',
  'titties',
  'blowjob*',
  'handjob*',
  'cumshot*',
  'jizz*',
  'dildo*',
  'jackoff',
  'jerkoff',
  'nigger*',
  'nigga*',
  'faggot*',
  'fagot*',
  'fag',
  'fags',
  'dyke',
  'dykes',
  'tranny',
  'trannies',
  'retard',
  'retards',
  'retarded',
  'spic',
  'spics',
  'kike',
  'kikes',
  'chink',
  'chinks',
  'gook',
  'gooks',
  'wetback*',
  'beaner*',
  'raghead*',
  'towelhead*',
  'coon',
  'coons',
  'jap',
  'japs',
  'paki',
  'pakis',
];
