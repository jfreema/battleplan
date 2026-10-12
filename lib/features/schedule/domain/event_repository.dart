import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/chat/domain/message.dart' show PageCursor;
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/event_draft.dart';
import 'package:battleplan/features/schedule/domain/recurrence.dart';

/// A page of events and where the next one starts (ARCH §5.3).
typedef EventPage = ({List<Event> events, PageCursor? next});

/// Owns `events` and `eventSeries` (ARCH §5.2). One-off events are written
/// directly under the rules; series change only through the
/// `saveEventSeries` callable (ARCH §6.4).
abstract interface class EventRepository {
  /// The team's events starting at or after [from], soonest first: the
  /// first [limit] live (Upcoming, SCHED-1).
  Stream<EventPage> watchUpcoming(GroupId groupId, DateTime from, {int limit});

  /// The team's events starting before [before], newest first, live (Past).
  Stream<EventPage> watchPast(GroupId groupId, DateTime before, {int limit});

  /// The next page after [cursor], one-shot, in the same order as the page
  /// it came from.
  Future<EventPage> loadMore(
    GroupId groupId,
    PageCursor cursor, {
    required bool past,
    int limit,
  });

  /// Events starting in [from, until), soonest first (Calendar month).
  Stream<List<Event>> watchRange(
    GroupId groupId,
    DateTime from,
    DateTime until,
  );

  /// One event, live; null once it's deleted.
  Stream<Event?> watchEvent(EventId id);

  /// The series' first event starting at or after [from], live; null when
  /// none is left. A series' chat card falls back to it once its own
  /// event is gone (CHAT-11).
  Stream<Event?> watchNextInSeries(
    GroupId groupId,
    String seriesId,
    DateTime from,
  );

  /// A series, live, for its "Repeats weekly…" line (SCHED-4).
  Stream<EventSeries?> watchSeries(String seriesId);

  /// Writes a new one-off event (SCHED-3). [youth] makes it take RSVPs per
  /// player. Returns its ID.
  Future<EventId> createEvent(
    GroupId groupId,
    EventDraft draft, {
    required UserId createdBy,
    required bool youth,
  });

  /// Saves the form over a one-off event (SCHED-6).
  Future<void> updateEvent(Event event, EventDraft draft);

  /// Cancels a one-off event (SCHED-7): it stays, struck through.
  Future<void> cancelEvent(Event event, UserId by);

  /// Deletes a one-off event; the server removes its RSVPs.
  Future<void> deleteEvent(Event event);

  /// Creates a repeating series and its events (SCHED-3).
  Future<SeriesResult> createSeries(
    GroupId groupId,
    Recurrence recurrence,
    EventTemplate template, {
    bool dryRun,
  });

  /// Edits a series event: this one ([date] moves it), or this and the
  /// following ones with a new [recurrence] (SCHED-6).
  Future<SeriesResult> updateSeries(
    EventId eventId,
    SeriesScope scope,
    EventTemplate template, {
    Recurrence? recurrence,
    String? date,
    bool dryRun,
  });

  /// Cancels a series event, or it and the following ones (SCHED-7).
  Future<SeriesResult> cancelSeries(
    EventId eventId,
    SeriesScope scope, {
    bool dryRun,
  });

  /// Deletes a series event, or it and the following ones, with their
  /// RSVPs (SCHED-7).
  Future<SeriesResult> deleteSeries(
    EventId eventId,
    SeriesScope scope, {
    bool dryRun,
  });
}
