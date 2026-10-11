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
  static const String licenses = 'licenses';
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
  static const int seriesSkipDatesMax = 100;
  static const int seriesMaxMonths = 12;
  static const int groupNameMax = 50;
  static const int groupsPerUserMax = 100;
  static const int groupsCreatedPerUserPerDay = 5;
  static const int membersPerGroupMax = 500;
  static const int playersPerGroupMax = 200;
  static const int guardiansPerPlayerMax = 4;
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
  static const int queryLimitMax = 100;
  static const int unreadCountCap = 100;
  static const int notificationPageSize = 30;
  static const int notificationTtlDays = 90;
  static const int auditLogTtlDays = 365;
  static const int rateLimitTtlDays = 2;
  static const int inviteCodeLength = 8;
  static const int emailInviteExpiryDays = 14;
  static const int defaultStorageQuotaGb = 5;
  static const int maxUploadMb = 25;
  static const int maxImageMb = 10;
  static const int lastReadThrottleSeconds = 10;
  static const int plusStorageQuotaGb = 25;
  static const int plusMaxUploadMb = 100;
  static const int licenseDefaultMonths = 12;
  static const int licenseMaxMonths = 36;
  static const int licenseMoveCooldownDays = 30;
  static const int licenseReminderFirstDays = 30;
  static const int licenseReminderSecondDays = 7;
  static const int pinnedMessagesMax = 3;
}

/// The 12 team colors (TEAM-1), as ARGB.
const List<int> teamColorValues = [
  0xFF2F5BEA,
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
];

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

enum TeamType {
  adult('adult'),
  youth('youth');

  const TeamType(this.value);

  /// The string stored in Firestore.
  final String value;

  static TeamType? tryParse(String? value) {
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
  member('member');

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

enum FreeReaction {
  like('like'),
  love('love'),
  dislike('dislike'),
  laugh('laugh');

  const FreeReaction(this.value);

  /// The string stored in Firestore.
  final String value;

  static FreeReaction? tryParse(String? value) {
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

enum RsvpFor {
  members('members'),
  players('players');

  const RsvpFor(this.value);

  /// The string stored in Firestore.
  final String value;

  static RsvpFor? tryParse(String? value) {
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

enum PlanTier {
  free('free'),
  plus('plus');

  const PlanTier(this.value);

  /// The string stored in Firestore.
  final String value;

  static PlanTier? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum PlanFeature {
  editMessages('editMessages'),
  extraReactions('extraReactions'),
  chatTheme('chatTheme'),
  pinMessages('pinMessages'),
  attendanceExport('attendanceExport'),
  brandedInvite('brandedInvite'),
  moreStorage('moreStorage');

  const PlanFeature(this.value);

  /// The string stored in Firestore.
  final String value;

  static PlanFeature? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum LicenseSource {
  grant('grant'),
  stripe('stripe'),
  appStore('appStore'),
  play('play');

  const LicenseSource(this.value);

  /// The string stored in Firestore.
  final String value;

  static LicenseSource? tryParse(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}
