import 'dart:async';

import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/core/services/calendar.dart';
import 'package:battleplan/core/services/service_providers.dart';
import 'package:battleplan/core/widgets/confirm_dialog.dart';
import 'package:battleplan/core/widgets/snackbar.dart';
import 'package:battleplan/features/auth/application/providers.dart';
import 'package:battleplan/features/groups/groups.dart';
import 'package:battleplan/features/schedule/application/providers.dart';
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/recurrence.dart';
import 'package:battleplan/features/schedule/presentation/schedule_format.dart';
import 'package:battleplan/l10n/gen/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The event actions that need a question first: series scope (SCHED-6,
/// SCHED-7), cancel, and delete; plus Add to calendar, Share, and
/// Directions (SCHED-4, SCHED-10).

/// "This event" or "This and following events"; null if dismissed.
Future<SeriesScope?> askSeriesScope(BuildContext context, String title) {
  final l10n = AppLocalizations.of(context);
  return showDialog<SeriesScope>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(title),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(SeriesScope.thisEvent),
          child: Text(l10n.seriesThisEvent),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(SeriesScope.following),
          child: Text(l10n.seriesFollowing),
        ),
      ],
    ),
  );
}

/// "Removes 4 practices; 9 people had answered." (SCHED-6), or null when
/// nothing would be removed.
String? removalLine(AppLocalizations l10n, EventType type, SeriesResult dry) =>
    dry.removed == 0
    ? null
    : l10n.seriesRemoves(
        eventCount(l10n, type, dry.removed),
        l10n.peopleHadAnswered(dry.removedRsvps),
      );

/// The message for a failed action.
String failureText(AppLocalizations l10n, AppFailure e) => switch (e) {
  StorageFull() => l10n.storageFullMessage,
  PermissionDenied() => l10n.eventNotAllowed,
  _ => l10n.eventActionFailed,
};

/// Cancels [event] after asking, for a series this one or the rest
/// (SCHED-7). Returns true if it was canceled.
Future<bool> cancelEventFlow(
  BuildContext context,
  WidgetRef ref,
  Event event,
) async {
  final l10n = AppLocalizations.of(context);
  final repo = ref.read(eventRepositoryProvider);
  SeriesScope? scope;
  if (event.inSeries) {
    scope = await askSeriesScope(context, l10n.seriesCancelTitle);
    if (scope == null || !context.mounted) return false;
  }
  final ok = await showConfirmDialog(
    context,
    title: scope == SeriesScope.following
        ? l10n.eventCancelFollowingTitle
        : l10n.eventCancelTitle,
    message: l10n.eventCancelBody,
    confirmLabel: l10n.eventCancel,
    cancelLabel: l10n.eventKeep,
    destructive: true,
  );
  if (!ok) return false;
  try {
    if (scope == null) {
      final uid = ref.read(authUserProvider).value!.uid;
      await repo.cancelEvent(event, UserId(uid));
    } else {
      await repo.cancelSeries(event.id, scope);
    }
    return true;
  } on AppFailure catch (e) {
    if (context.mounted) showAppSnackBar(context, failureText(l10n, e));
    return false;
  }
}

/// What the delete confirmation's buttons do.
enum _DeleteChoice { delete, cancelInstead }

/// Deletes [event] after asking (SCHED-7): within 7 days it suggests
/// canceling instead; for a series it asks the scope and says what goes
/// with it. Returns true if it was deleted.
Future<bool> deleteEventFlow(
  BuildContext context,
  WidgetRef ref,
  Event event,
) async {
  final l10n = AppLocalizations.of(context);
  final repo = ref.read(eventRepositoryProvider);
  SeriesScope? scope;
  String? removes;
  if (event.inSeries) {
    scope = await askSeriesScope(context, l10n.seriesDeleteTitle);
    if (scope == null || !context.mounted) return false;
    try {
      final dry = await repo.deleteSeries(event.id, scope, dryRun: true);
      removes = removalLine(l10n, event.type, dry);
    } on AppFailure catch (e) {
      if (context.mounted) showAppSnackBar(context, failureText(l10n, e));
      return false;
    }
    if (!context.mounted) return false;
  }
  final now = DateTime.now();
  final soon =
      !event.isCanceled &&
      event.startAt.isAfter(now) &&
      event.startAt.difference(now) <= const Duration(days: 7);
  final choice = await showDialog<_DeleteChoice>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text(
          scope == SeriesScope.following
              ? l10n.eventDeleteFollowingTitle
              : l10n.eventDeleteTitle,
        ),
        content: Text(
          [
            ?removes,
            if (soon) l10n.eventDeleteSoonBody else l10n.eventDeleteBody,
          ].join('\n\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.eventKeep),
          ),
          if (soon)
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_DeleteChoice.cancelInstead),
              child: Text(l10n.eventCancelInstead),
            ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(_DeleteChoice.delete),
            child: Text(l10n.eventDelete),
          ),
        ],
      );
    },
  );
  if (choice == null || !context.mounted) return false;
  try {
    if (choice == _DeleteChoice.cancelInstead) {
      if (scope == null) {
        final uid = ref.read(authUserProvider).value!.uid;
        await repo.cancelEvent(event, UserId(uid));
      } else {
        await repo.cancelSeries(event.id, scope);
      }
      return false;
    }
    if (scope == null) {
      await repo.deleteEvent(event);
    } else {
      await repo.deleteSeries(event.id, scope);
    }
    return true;
  } on AppFailure catch (e) {
    if (context.mounted) showAppSnackBar(context, failureText(l10n, e));
    return false;
  }
}

/// Adds [event] to the person's calendar (SCHED-10).
Future<void> addToCalendar(
  BuildContext context,
  WidgetRef ref,
  Event event,
) async {
  final l10n = AppLocalizations.of(context);
  final entry = CalendarEntry(
    id: event.id.value,
    title: event.isCanceled
        ? '${l10n.eventCanceled}: ${event.title}'
        : event.title,
    description: event.description,
    location: event.location?.mapsQuery ?? '',
    start: event.startAt,
    end: event.endAt,
    timeZone: event.timeZone,
    allDay: event.allDay,
    startDate: event.startDate == null ? null : parseDateKey(event.startDate!),
    endDate: event.endDate == null
        ? null
        : addDays(parseDateKey(event.endDate!), 1),
    url: ref.read(eventLinkProvider(event.groupId, event.id)),
  );
  final ok = await ref.read(calendarAdderProvider).add(entry);
  if (!ok && context.mounted) {
    showAppSnackBar(context, l10n.eventCalendarFailed);
  }
}

/// Shares a link to [event] (SCHED-4), or copies it where sharing isn't
/// available.
Future<void> shareEvent(
  BuildContext context,
  WidgetRef ref,
  Event event,
) async {
  final l10n = AppLocalizations.of(context);
  final link = ref.read(eventLinkProvider(event.groupId, event.id));
  final shared = await ref
      .read(sharerProvider)
      .shareLink(link, subject: event.title);
  if (shared) return;
  await Clipboard.setData(ClipboardData(text: link.toString()));
  if (context.mounted) showAppSnackBar(context, l10n.linkCopied);
}

/// Opens Maps with directions to the event's place (SCHED-4).
Future<void> openDirections(WidgetRef ref, EventLocation location) => ref
    .read(linkOpenerProvider)
    .open(
      Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': location.mapsQuery,
      }),
    );

/// Shows the storage-full message when [e] is that failure (STORE-4).
void showSaveFailure(BuildContext context, AppFailure e) {
  if (e is StorageFull) {
    showStorageFull(context);
  } else {
    showAppSnackBar(context, failureText(AppLocalizations.of(context), e));
  }
}
