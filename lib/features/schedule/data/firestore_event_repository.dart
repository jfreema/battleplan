import 'package:battleplan/core/constants.g.dart';
import 'package:battleplan/core/failure.dart';
import 'package:battleplan/core/ids.dart';
import 'package:battleplan/features/chat/domain/message.dart' show PageCursor;
import 'package:battleplan/features/schedule/domain/event.dart';
import 'package:battleplan/features/schedule/domain/event_draft.dart';
import 'package:battleplan/features/schedule/domain/event_repository.dart';
import 'package:battleplan/features/schedule/domain/recurrence.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Events and series in Firestore (ARCH §6.2). One-off events are written
/// directly under the rules (counts start at 0, the server keeps them);
/// series go through the `saveEventSeries` callable.
class FirestoreEventRepository implements EventRepository {
  new(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection(Collections.events);

  Query<Map<String, dynamic>> _team(GroupId groupId) =>
      _events.where('groupId', isEqualTo: groupId.value);

  EventPage _page(QuerySnapshot<Map<String, dynamic>> q, int limit) => (
    events: [for (final d in q.docs) eventFromFirestore(d.id, d.data())],
    next: q.docs.length < limit ? null : PageCursor(q.docs.last),
  );

  @override
  Stream<EventPage> watchUpcoming(
    GroupId groupId,
    DateTime from, {
    int limit = 50,
  }) =>
      _team(groupId)
          .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .orderBy('startAt')
          .limit(limit)
          .snapshots()
          .map((q) => _page(q, limit));

  @override
  Stream<EventPage> watchPast(
    GroupId groupId,
    DateTime before, {
    int limit = 50,
  }) =>
      _team(groupId)
          .where('startAt', isLessThan: Timestamp.fromDate(before))
          .orderBy('startAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((q) => _page(q, limit));

  @override
  Future<EventPage> loadMore(
    GroupId groupId,
    PageCursor cursor, {
    required bool past,
    int limit = 50,
  }) async {
    final last = cursor.handle as DocumentSnapshot<Object?>;
    final q = await _team(groupId)
        .orderBy('startAt', descending: past)
        .startAfterDocument(last)
        .limit(limit)
        .get();
    return _page(q, limit);
  }

  @override
  Stream<List<Event>> watchRange(
    GroupId groupId,
    DateTime from,
    DateTime until,
  ) => _team(groupId)
      .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
      .where('startAt', isLessThan: Timestamp.fromDate(until))
      .orderBy('startAt')
      .limit(Limits.queryLimitMax)
      .snapshots()
      .map((q) => [for (final d in q.docs) eventFromFirestore(d.id, d.data())]);

  @override
  Stream<Event?> watchEvent(EventId id) => _events
      .doc(id.value)
      .snapshots()
      // Offline, an event that was never cached reads as missing; wait for
      // the server rather than call it deleted.
      .where((d) => d.exists || !d.metadata.isFromCache)
      .map((d) => d.exists ? eventFromFirestore(d.id, d.data()!) : null);

  @override
  Stream<Event?> watchNextInSeries(
    GroupId groupId,
    String seriesId,
    DateTime from,
  ) =>
      _team(groupId)
          .where('seriesId', isEqualTo: seriesId)
          .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .orderBy('startAt')
          .limit(1)
          .snapshots()
          .map(
            (q) => q.docs.isEmpty
                ? null
                : eventFromFirestore(q.docs.first.id, q.docs.first.data()),
          );

  @override
  Stream<EventSeries?> watchSeries(String seriesId) => _db
      .collection(Collections.eventSeries)
      .doc(seriesId)
      .snapshots()
      .map((d) => d.exists ? seriesFromFirestore(d.id, d.data()!) : null);

  /// The fields the form sets, as the rules expect them (ARCH §6.2).
  Map<String, Object?> _fields(EventDraft draft) {
    final t = draft.template;
    return {
      'type': t.type.value,
      'title': t.title,
      'description': t.description,
      'location': t.location == null
          ? null
          : {'name': t.location!.name, 'address': t.location!.address},
      'allDay': t.allDay,
      'startAt': Timestamp.fromDate(draft.startAt!),
      'endAt': Timestamp.fromDate(draft.endAt!),
      'startDate': draft.allDay ? dateKey(draft.date!) : null,
      'endDate': draft.allDay ? dateKey(draft.lastDay!) : null,
      'timeZone': t.timeZone,
      'arriveMinutesBefore': t.arriveMinutesBefore,
      'opponent': t.opponent,
      'homeAway': t.homeAway?.value,
      'rsvpEnabled': t.rsvpEnabled,
      'rsvpDeadline': t.rsvpEnabled && draft.deadline != null
          ? Timestamp.fromDate(draft.deadline!)
          : null,
      'reminderOffsets': t.reminderOffsets,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  Future<EventId> createEvent(
    GroupId groupId,
    EventDraft draft, {
    required UserId createdBy,
  }) async {
    const zero = {'going': 0, 'maybe': 0, 'notGoing': 0};
    final ref = _events.doc();
    await _write(
      () => ref.set({
        ..._fields(draft),
        'groupId': groupId.value,
        'notifyTeam': draft.notifyTeam,
        'postToChat': draft.postToChat,
        'rsvpCounts': zero,
        'staffCounts': zero,
        'seriesId': null,
        'seriesDate': null,
        'nextReminderAt': null,
        'messageId': null,
        'canceledAt': null,
        'canceledBy': null,
        'createdBy': createdBy.value,
        'createdAt': FieldValue.serverTimestamp(),
      }),
    );
    return EventId(ref.id);
  }

  @override
  Future<void> updateEvent(Event event, EventDraft draft) => _write(() {
    // notifyTeam and postToChat are read once, on create; the rules keep
    // them as they were.
    final fields = _fields(draft);
    return _events.doc(event.id.value).update(fields);
  });

  @override
  Future<void> cancelEvent(Event event, UserId by) => _write(
    () => _events.doc(event.id.value).update({
      'canceledAt': FieldValue.serverTimestamp(),
      'canceledBy': by.value,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> deleteEvent(Event event) =>
      _write(() => _events.doc(event.id.value).delete());

  Future<void> _write(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(e.code),
        'not-found' => NotFound(e.code),
        'unavailable' => Offline(e.code),
        _ => UnknownFailure(e.code),
      };
    }
  }

  @override
  Future<SeriesResult> createSeries(
    GroupId groupId,
    Recurrence recurrence,
    EventTemplate template, {
    bool dryRun = false,
  }) => _callSeries({
    'action': 'create',
    'groupId': groupId.value,
    'recurrence': recurrenceToJson(recurrence),
    'template': templateToJson(template),
    'dryRun': dryRun,
  });

  @override
  Future<SeriesResult> updateSeries(
    EventId eventId,
    SeriesScope scope,
    EventTemplate template, {
    Recurrence? recurrence,
    String? date,
    bool dryRun = false,
  }) => _callSeries({
    'action': 'update',
    'eventId': eventId.value,
    'scope': scope.value,
    'template': {...templateToJson(template), 'date': ?date},
    if (scope == SeriesScope.following && recurrence != null)
      'recurrence': recurrenceToJson(recurrence),
    'dryRun': dryRun,
  });

  @override
  Future<SeriesResult> cancelSeries(
    EventId eventId,
    SeriesScope scope, {
    bool dryRun = false,
  }) => _callSeries({
    'action': 'cancel',
    'eventId': eventId.value,
    'scope': scope.value,
    'dryRun': dryRun,
  });

  @override
  Future<SeriesResult> deleteSeries(
    EventId eventId,
    SeriesScope scope, {
    bool dryRun = false,
  }) => _callSeries({
    'action': 'delete',
    'eventId': eventId.value,
    'scope': scope.value,
    'dryRun': dryRun,
  });

  Future<SeriesResult> _callSeries(Map<String, Object?> input) async {
    try {
      final result = await _functions
          .httpsCallable('saveEventSeries')
          .call<Object?>(input);
      final x = (result.data as Map?) ?? const {};
      int n(String k) => (x[k] as num?)?.toInt() ?? 0;
      return SeriesResult(
        seriesId: x['seriesId'] as String?,
        created: n('created'),
        updated: n('updated'),
        removed: n('removed'),
        removedRsvps: n('removedRsvps'),
        canceled: n('canceled'),
      );
    } on FirebaseFunctionsException catch (e) {
      final storage = (e.message ?? '').toLowerCase().contains('storage');
      throw switch (e.code) {
        'permission-denied' => PermissionDenied(e.message),
        'not-found' => NotFound(e.message),
        'invalid-argument' => InvalidInput(e.message),
        'failed-precondition' ||
        'resource-exhausted' when storage => StorageFull(e.message),
        'resource-exhausted' => RateLimited(e.message),
        'unavailable' || 'deadline-exceeded' => Offline(e.message),
        _ => UnknownFailure('${e.code}: ${e.message}'),
      };
    }
  }
}

/// The callable's `recurrence` (ARCH §6.2).
Map<String, Object?> recurrenceToJson(Recurrence r) => {
  'freq': r.freq.value,
  'interval': r.interval,
  'byWeekday': r.freq == RepeatFreq.weekly ? r.byWeekday : <int>[],
  'startDate': r.startDate,
  'untilDate': r.untilDate,
  'count': r.count,
  'skipDates': r.skipDates,
};

/// The callable's `template` (ARCH §6.2).
Map<String, Object?> templateToJson(EventTemplate t) => {
  'type': t.type.value,
  'title': t.title,
  'description': t.description,
  'location': t.location == null
      ? null
      : {'name': t.location!.name, 'address': t.location!.address},
  'allDay': t.allDay,
  'startTime': t.startTime,
  'endTime': t.endTime,
  'timeZone': t.timeZone,
  'arriveMinutesBefore': t.arriveMinutesBefore,
  'opponent': t.opponent,
  'homeAway': t.homeAway?.value,
  'rsvpEnabled': t.rsvpEnabled,
  'reminderOffsets': t.reminderOffsets,
  'notifyTeam': t.notifyTeam,
  'postToChat': t.postToChat,
};

RsvpCounts _counts(Object? x) => x is Map
    ? RsvpCounts(
        going: (x['going'] as num?)?.toInt() ?? 0,
        maybe: (x['maybe'] as num?)?.toInt() ?? 0,
        notGoing: (x['notGoing'] as num?)?.toInt() ?? 0,
      )
    : const RsvpCounts();

DateTime? _time(Object? x) => x is Timestamp ? x.toDate() : null;

/// Reads an `events` document (ARCH §6.2).
Event eventFromFirestore(String id, Map<String, dynamic> x) {
  final location = x['location'];
  // A local write has no server times yet.
  final start = _time(x['startAt']) ?? DateTime.now();
  return Event(
    id: EventId(id),
    groupId: GroupId(x['groupId'] as String? ?? ''),
    type: EventType.tryParse(x['type'] as String?) ?? EventType.other,
    title: x['title'] as String? ?? '',
    description: x['description'] as String? ?? '',
    location: location is Map
        ? EventLocation(
            name: location['name'] as String? ?? '',
            address: location['address'] as String? ?? '',
          )
        : null,
    allDay: x['allDay'] == true,
    startAt: start,
    endAt: _time(x['endAt']) ?? start,
    startDate: x['startDate'] as String?,
    endDate: x['endDate'] as String?,
    timeZone: x['timeZone'] as String? ?? 'America/Chicago',
    arriveMinutesBefore: (x['arriveMinutesBefore'] as num?)?.toInt(),
    opponent: x['opponent'] as String?,
    homeAway: HomeAway.tryParse(x['homeAway'] as String?),
    rsvpEnabled: x['rsvpEnabled'] != false,
    rsvpDeadline: _time(x['rsvpDeadline']),
    reminderOffsets: [
      for (final o in (x['reminderOffsets'] as List?) ?? const [])
        if (o is num) o.toInt(),
    ],
    notifyTeam: x['notifyTeam'] != false,
    postToChat: x['postToChat'] != false,
    seriesId: x['seriesId'] as String?,
    seriesDate: x['seriesDate'] as String?,
    seriesOverrides: [
      for (final f in (x['seriesOverrides'] as List?) ?? const [])
        if (f is String) f,
    ],
    rsvpCounts: _counts(x['rsvpCounts']),
    staffCounts: _counts(x['staffCounts']),
    canceledAt:
        _time(x['canceledAt']) ??
        // Canceled offline: the server time isn't back yet.
        (x.containsKey('canceledBy') && x['canceledBy'] != null
            ? DateTime.now()
            : null),
    canceledBy: x['canceledBy'] as String?,
    createdBy: x['createdBy'] as String? ?? '',
    createdAt: _time(x['createdAt']),
    updatedAt: _time(x['updatedAt']),
  );
}

/// Reads an `eventSeries` document (ARCH §6.2).
EventSeries seriesFromFirestore(String id, Map<String, dynamic> x) {
  final r = (x['recurrence'] as Map?) ?? const {};
  return EventSeries(
    id: id,
    groupId: GroupId(x['groupId'] as String? ?? ''),
    timeZone: x['timeZone'] as String? ?? 'America/Chicago',
    createdBy: x['createdBy'] as String? ?? '',
    recurrence: Recurrence(
      freq: RepeatFreq.tryParse(r['freq'] as String?) ?? RepeatFreq.weekly,
      startDate: r['startDate'] as String? ?? '1970-01-01',
      interval: (r['interval'] as num?)?.toInt() ?? 1,
      byWeekday: [
        for (final d in (r['byWeekday'] as List?) ?? const [])
          if (d is num) d.toInt(),
      ],
      untilDate: r['untilDate'] as String?,
      count: (r['count'] as num?)?.toInt(),
      skipDates: [
        for (final d in (r['skipDates'] as List?) ?? const [])
          if (d is String) d,
      ],
    ),
  );
}
