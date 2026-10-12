import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/design/app_icons.dart';
import 'package:battleplan/features/groups/domain/membership.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// The global switches shown in Settings (NOTIF-4). Mentions arrive in
/// v1.1 (NOTIF-12), so their switch stays hidden until then.
const List<NotificationPref> shownNotificationPrefs = [
  NotificationPref.messages,
  NotificationPref.replies,
  NotificationPref.polls,
  NotificationPref.eventsNew,
  NotificationPref.eventsChanged,
  NotificationPref.reminders,
  NotificationPref.documents,
];

String notificationPrefLabel(AppLocalizations l10n, NotificationPref p) =>
    switch (p) {
      NotificationPref.messages => l10n.prefMessages,
      NotificationPref.replies => l10n.prefReplies,
      NotificationPref.mentions => l10n.prefMentions,
      NotificationPref.polls => l10n.prefPolls,
      NotificationPref.eventsNew => l10n.prefEventsNew,
      NotificationPref.eventsChanged => l10n.prefEventsChanged,
      NotificationPref.reminders => l10n.prefReminders,
      NotificationPref.documents => l10n.prefDocuments,
    };

/// All activity, Important only, or Off (NOTIF-3).
String notificationLevelLabel(AppLocalizations l10n, NotificationLevel l) =>
    switch (l) {
      NotificationLevel.all => l10n.levelAll,
      NotificationLevel.important => l10n.levelImportant,
      NotificationLevel.none => l10n.levelOff,
    };

String notificationLevelHelp(AppLocalizations l10n, NotificationLevel l) =>
    switch (l) {
      NotificationLevel.all => l10n.levelAllHelp,
      NotificationLevel.important => l10n.levelImportantHelp,
      NotificationLevel.none => l10n.levelOffHelp,
    };

/// "Muted until 3:45 PM", "Muted until Tue, Oct 14 9:00 AM", "Muted until
/// you unmute", or null when not muted.
String? muteLabel(AppLocalizations l10n, Membership m, DateTime now) {
  final until = m.mutedUntil;
  if (until == null || !m.isSnoozedAt(now)) return null;
  if (m.isMutedForever) return l10n.mutedUntilUnmuted;
  final local = until.toLocal();
  final sameDay =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  final format = sameDay
      ? DateFormat.jm(l10n.localeName)
      : DateFormat.MMMEd(l10n.localeName).add_jm();
  return l10n.mutedUntilTime(format.format(local));
}

/// The icon for a notification-center item (NOTIF-11).
IconData notificationIcon(NotifyKind? kind) => switch (kind) {
  NotifyKind.message || null => AppIcons.chat,
  NotifyKind.reply => AppIcons.reply,
  NotifyKind.addedToTeam => AppIcons.addedToTeam,
  NotifyKind.madeAdmin => AppIcons.admin,
  NotifyKind.guardianRequest ||
  NotifyKind.guardianApproved ||
  NotifyKind.playerAdded => AppIcons.family,
  NotifyKind.contentReported => AppIcons.report,
  NotifyKind.planReminder => AppIcons.plus,
  NotifyKind.pollCreated || NotifyKind.pollClosed => AppIcons.poll,
  NotifyKind.eventCreated || NotifyKind.eventChanged => AppIcons.event,
  NotifyKind.eventReminder => AppIcons.reminder,
  NotifyKind.documentAdded => AppIcons.document,
};

/// "now", "5m", "3h", "2d", then the date: short, for a list row.
String relativeTime(AppLocalizations l10n, DateTime at, DateTime now) {
  final diff = now.difference(at);
  if (diff.inMinutes < 1) return l10n.timeNow;
  if (diff.inHours < 1) return l10n.timeMinutes(diff.inMinutes);
  if (diff.inDays < 1) return l10n.timeHours(diff.inHours);
  if (diff.inDays < 7) return l10n.timeDays(diff.inDays);
  final local = at.toLocal();
  return local.year == now.year
      ? DateFormat.MMMd(l10n.localeName).format(local)
      : DateFormat.yMMMd(l10n.localeName).format(local);
}
