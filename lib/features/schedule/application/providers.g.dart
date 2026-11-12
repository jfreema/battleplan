// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridden in app/providers.dart.

@ProviderFor(eventRepository)
final eventRepositoryProvider = EventRepositoryProvider._();

/// Overridden in app/providers.dart.

final class EventRepositoryProvider
    extends
        $FunctionalProvider<EventRepository, EventRepository, EventRepository>
    with $Provider<EventRepository> {
  /// Overridden in app/providers.dart.
  EventRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventRepositoryHash();

  @$internal
  @override
  $ProviderElement<EventRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EventRepository create(Ref ref) {
    return eventRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventRepository>(value),
    );
  }
}

String _$eventRepositoryHash() => r'7d02a4b32adae1f1bdb9d3fb0e4eb907f3d524f2';

/// Overridden in app/providers.dart.

@ProviderFor(rsvpRepository)
final rsvpRepositoryProvider = RsvpRepositoryProvider._();

/// Overridden in app/providers.dart.

final class RsvpRepositoryProvider
    extends $FunctionalProvider<RsvpRepository, RsvpRepository, RsvpRepository>
    with $Provider<RsvpRepository> {
  /// Overridden in app/providers.dart.
  RsvpRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rsvpRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rsvpRepositoryHash();

  @$internal
  @override
  $ProviderElement<RsvpRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RsvpRepository create(Ref ref) {
    return rsvpRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RsvpRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RsvpRepository>(value),
    );
  }
}

String _$rsvpRepositoryHash() => r'dae2f30aa727a35ad456a18c6c01f61ef621d5e0';

/// Overridden in app/providers.dart.

@ProviderFor(calendarLinkRepository)
final calendarLinkRepositoryProvider = CalendarLinkRepositoryProvider._();

/// Overridden in app/providers.dart.

final class CalendarLinkRepositoryProvider
    extends
        $FunctionalProvider<
          CalendarLinkRepository,
          CalendarLinkRepository,
          CalendarLinkRepository
        >
    with $Provider<CalendarLinkRepository> {
  /// Overridden in app/providers.dart.
  CalendarLinkRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarLinkRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarLinkRepositoryHash();

  @$internal
  @override
  $ProviderElement<CalendarLinkRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalendarLinkRepository create(Ref ref) {
    return calendarLinkRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarLinkRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarLinkRepository>(value),
    );
  }
}

String _$calendarLinkRepositoryHash() =>
    r'1f3bcfc6ae7f681d39571cef729b3ed092f226a0';

/// Overridden in app/providers.dart.

@ProviderFor(assignmentRepository)
final assignmentRepositoryProvider = AssignmentRepositoryProvider._();

/// Overridden in app/providers.dart.

final class AssignmentRepositoryProvider
    extends
        $FunctionalProvider<
          AssignmentRepository,
          AssignmentRepository,
          AssignmentRepository
        >
    with $Provider<AssignmentRepository> {
  /// Overridden in app/providers.dart.
  AssignmentRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'assignmentRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$assignmentRepositoryHash();

  @$internal
  @override
  $ProviderElement<AssignmentRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AssignmentRepository create(Ref ref) {
    return assignmentRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AssignmentRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AssignmentRepository>(value),
    );
  }
}

String _$assignmentRepositoryHash() =>
    r'41423d491b2d4f4adab24dfba13ba8418cdfcc1e';

/// An event's tasks (snacks, drinks, scorekeeper...), live (SCHED-15).

@ProviderFor(eventAssignments)
final eventAssignmentsProvider = EventAssignmentsFamily._();

/// An event's tasks (snacks, drinks, scorekeeper...), live (SCHED-15).

final class EventAssignmentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Assignment>>,
          List<Assignment>,
          Stream<List<Assignment>>
        >
    with $FutureModifier<List<Assignment>>, $StreamProvider<List<Assignment>> {
  /// An event's tasks (snacks, drinks, scorekeeper...), live (SCHED-15).
  EventAssignmentsProvider._({
    required EventAssignmentsFamily super.from,
    required (GroupId, EventId) super.argument,
  }) : super(
         retry: null,
         name: r'eventAssignmentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventAssignmentsHash();

  @override
  String toString() {
    return r'eventAssignmentsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<Assignment>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Assignment>> create(Ref ref) {
    final argument = this.argument as (GroupId, EventId);
    return eventAssignments(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is EventAssignmentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventAssignmentsHash() => r'1ff0903864622e5e47fa8ca9d42d4fb8c31dc48a';

/// An event's tasks (snacks, drinks, scorekeeper...), live (SCHED-15).

final class EventAssignmentsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<Assignment>>,
          (GroupId, EventId)
        > {
  EventAssignmentsFamily._()
    : super(
        retry: null,
        name: r'eventAssignmentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// An event's tasks (snacks, drinks, scorekeeper...), live (SCHED-15).

  EventAssignmentsProvider call(GroupId groupId, EventId eventId) =>
      EventAssignmentsProvider._(argument: (groupId, eventId), from: this);

  @override
  String toString() => r'eventAssignmentsProvider';
}

/// The signed-in person's calendar links, live (SCHED-11).

@ProviderFor(myCalendarLinks)
final myCalendarLinksProvider = MyCalendarLinksProvider._();

/// The signed-in person's calendar links, live (SCHED-11).

final class MyCalendarLinksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CalendarLink>>,
          List<CalendarLink>,
          Stream<List<CalendarLink>>
        >
    with
        $FutureModifier<List<CalendarLink>>,
        $StreamProvider<List<CalendarLink>> {
  /// The signed-in person's calendar links, live (SCHED-11).
  MyCalendarLinksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myCalendarLinksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myCalendarLinksHash();

  @$internal
  @override
  $StreamProviderElement<List<CalendarLink>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CalendarLink>> create(Ref ref) {
    return myCalendarLinks(ref);
  }
}

String _$myCalendarLinksHash() => r'aa7d23a070fb6e6ad8d20dccc22dcdc6d54ac05a';

/// This device's time zone, which Automatic follows (SET-7). Asked again
/// on each return to the app and each minute while it's open, so a trip
/// shows whether the app was in the background or on screen.

@ProviderFor(deviceTimeZone)
final deviceTimeZoneProvider = DeviceTimeZoneProvider._();

/// This device's time zone, which Automatic follows (SET-7). Asked again
/// on each return to the app and each minute while it's open, so a trip
/// shows whether the app was in the background or on screen.

final class DeviceTimeZoneProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// This device's time zone, which Automatic follows (SET-7). Asked again
  /// on each return to the app and each minute while it's open, so a trip
  /// shows whether the app was in the background or on screen.
  DeviceTimeZoneProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceTimeZoneProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceTimeZoneHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return deviceTimeZone(ref);
  }
}

String _$deviceTimeZoneHash() => r'ce912516f32d5b9f6bb12f98c18e176ce0c0138c';

/// The viewer's time zone: every time shows in it (SCHED-9). The one they
/// picked under Profile → Time zone (SET-7), which stays put as they
/// travel, or this device's (Automatic, and until the profile arrives).

@ProviderFor(viewerTimeZone)
final viewerTimeZoneProvider = ViewerTimeZoneProvider._();

/// The viewer's time zone: every time shows in it (SCHED-9). The one they
/// picked under Profile → Time zone (SET-7), which stays put as they
/// travel, or this device's (Automatic, and until the profile arrives).

final class ViewerTimeZoneProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// The viewer's time zone: every time shows in it (SCHED-9). The one they
  /// picked under Profile → Time zone (SET-7), which stays put as they
  /// travel, or this device's (Automatic, and until the profile arrives).
  ViewerTimeZoneProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'viewerTimeZoneProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$viewerTimeZoneHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return viewerTimeZone(ref);
  }
}

String _$viewerTimeZoneHash() => r'73dafcca1d587286929c257f5e5bc245c64ec726';

/// The time now, for what goes by the time of day (when today began, which
/// events are over): read again each minute and on each return to the app,
/// so a screen left open, like Teams overnight, catches up.

@ProviderFor(minuteClock)
final minuteClockProvider = MinuteClockProvider._();

/// The time now, for what goes by the time of day (when today began, which
/// events are over): read again each minute and on each return to the app,
/// so a screen left open, like Teams overnight, catches up.

final class MinuteClockProvider
    extends $FunctionalProvider<DateTime, DateTime, DateTime>
    with $Provider<DateTime> {
  /// The time now, for what goes by the time of day (when today began, which
  /// events are over): read again each minute and on each return to the app,
  /// so a screen left open, like Teams overnight, catches up.
  MinuteClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'minuteClockProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$minuteClockHash();

  @$internal
  @override
  $ProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DateTime create(Ref ref) {
    return minuteClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$minuteClockHash() => r'1122dc2b46167ff19165bc5e14977f88f8bd3470';

/// The instant today began for the viewer ([startOfDay]), which moves at
/// midnight; null until their time zone is known.

@ProviderFor(viewerToday)
final viewerTodayProvider = ViewerTodayProvider._();

/// The instant today began for the viewer ([startOfDay]), which moves at
/// midnight; null until their time zone is known.

final class ViewerTodayProvider
    extends $FunctionalProvider<DateTime?, DateTime?, DateTime?>
    with $Provider<DateTime?> {
  /// The instant today began for the viewer ([startOfDay]), which moves at
  /// midnight; null until their time zone is known.
  ViewerTodayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'viewerTodayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$viewerTodayHash();

  @$internal
  @override
  $ProviderElement<DateTime?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DateTime? create(Ref ref) {
    return viewerToday(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime?>(value),
    );
  }
}

String _$viewerTodayHash() => r'50cec6417405682099e761f4d6df39d3e6185c6c';

/// One event, live (SCHED-4). Null once it's deleted.

@ProviderFor(event)
final eventProvider = EventFamily._();

/// One event, live (SCHED-4). Null once it's deleted.

final class EventProvider
    extends $FunctionalProvider<AsyncValue<Event?>, Event?, Stream<Event?>>
    with $FutureModifier<Event?>, $StreamProvider<Event?> {
  /// One event, live (SCHED-4). Null once it's deleted.
  EventProvider._({
    required EventFamily super.from,
    required EventId super.argument,
  }) : super(
         retry: null,
         name: r'eventProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventHash();

  @override
  String toString() {
    return r'eventProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Event?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Event?> create(Ref ref) {
    final argument = this.argument as EventId;
    return event(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EventProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventHash() => r'dd27c47764289ab6b4e5cb6b36893d24e1622fc0';

/// One event, live (SCHED-4). Null once it's deleted.

final class EventFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Event?>, EventId> {
  EventFamily._()
    : super(
        retry: null,
        name: r'eventProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One event, live (SCHED-4). Null once it's deleted.

  EventProvider call(EventId id) => EventProvider._(argument: id, from: this);

  @override
  String toString() => r'eventProvider';
}

/// A series' next event from now on, live, for its chat card once the
/// card's own event is gone (CHAT-11). Null when none is left.

@ProviderFor(nextSeriesEvent)
final nextSeriesEventProvider = NextSeriesEventFamily._();

/// A series' next event from now on, live, for its chat card once the
/// card's own event is gone (CHAT-11). Null when none is left.

final class NextSeriesEventProvider
    extends $FunctionalProvider<AsyncValue<Event?>, Event?, Stream<Event?>>
    with $FutureModifier<Event?>, $StreamProvider<Event?> {
  /// A series' next event from now on, live, for its chat card once the
  /// card's own event is gone (CHAT-11). Null when none is left.
  NextSeriesEventProvider._({
    required NextSeriesEventFamily super.from,
    required (GroupId, String) super.argument,
  }) : super(
         retry: null,
         name: r'nextSeriesEventProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$nextSeriesEventHash();

  @override
  String toString() {
    return r'nextSeriesEventProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<Event?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Event?> create(Ref ref) {
    final argument = this.argument as (GroupId, String);
    return nextSeriesEvent(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is NextSeriesEventProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$nextSeriesEventHash() => r'b81042b3431ca17971cbb32e2bc08a03a2a22921';

/// A series' next event from now on, live, for its chat card once the
/// card's own event is gone (CHAT-11). Null when none is left.

final class NextSeriesEventFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Event?>, (GroupId, String)> {
  NextSeriesEventFamily._()
    : super(
        retry: null,
        name: r'nextSeriesEventProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A series' next event from now on, live, for its chat card once the
  /// card's own event is gone (CHAT-11). Null when none is left.

  NextSeriesEventProvider call(GroupId groupId, String seriesId) =>
      NextSeriesEventProvider._(argument: (groupId, seriesId), from: this);

  @override
  String toString() => r'nextSeriesEventProvider';
}

/// A repeating series, live, for "Repeats weekly…" (SCHED-4).

@ProviderFor(eventSeries)
final eventSeriesProvider = EventSeriesFamily._();

/// A repeating series, live, for "Repeats weekly…" (SCHED-4).

final class EventSeriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<EventSeries?>,
          EventSeries?,
          Stream<EventSeries?>
        >
    with $FutureModifier<EventSeries?>, $StreamProvider<EventSeries?> {
  /// A repeating series, live, for "Repeats weekly…" (SCHED-4).
  EventSeriesProvider._({
    required EventSeriesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventSeriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventSeriesHash();

  @override
  String toString() {
    return r'eventSeriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<EventSeries?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<EventSeries?> create(Ref ref) {
    final argument = this.argument as String;
    return eventSeries(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EventSeriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventSeriesHash() => r'33461a31ee83b9aeaa55d9d15d739fa056456688';

/// A repeating series, live, for "Repeats weekly…" (SCHED-4).

final class EventSeriesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<EventSeries?>, String> {
  EventSeriesFamily._()
    : super(
        retry: null,
        name: r'eventSeriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A repeating series, live, for "Repeats weekly…" (SCHED-4).

  EventSeriesProvider call(String seriesId) =>
      EventSeriesProvider._(argument: seriesId, from: this);

  @override
  String toString() => r'eventSeriesProvider';
}

/// Everyone's answers on an event, live (SCHED-4).

@ProviderFor(eventRsvps)
final eventRsvpsProvider = EventRsvpsFamily._();

/// Everyone's answers on an event, live (SCHED-4).

final class EventRsvpsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Rsvp>>,
          List<Rsvp>,
          Stream<List<Rsvp>>
        >
    with $FutureModifier<List<Rsvp>>, $StreamProvider<List<Rsvp>> {
  /// Everyone's answers on an event, live (SCHED-4).
  EventRsvpsProvider._({
    required EventRsvpsFamily super.from,
    required (GroupId, EventId) super.argument,
  }) : super(
         retry: null,
         name: r'eventRsvpsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventRsvpsHash();

  @override
  String toString() {
    return r'eventRsvpsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<Rsvp>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Rsvp>> create(Ref ref) {
    final argument = this.argument as (GroupId, EventId);
    return eventRsvps(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is EventRsvpsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventRsvpsHash() => r'46549e02a93280670f8fb4230635d2a84f2cdb55';

/// Everyone's answers on an event, live (SCHED-4).

final class EventRsvpsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Rsvp>>, (GroupId, EventId)> {
  EventRsvpsFamily._()
    : super(
        retry: null,
        name: r'eventRsvpsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Everyone's answers on an event, live (SCHED-4).

  EventRsvpsProvider call(GroupId groupId, EventId eventId) =>
      EventRsvpsProvider._(argument: (groupId, eventId), from: this);

  @override
  String toString() => r'eventRsvpsProvider';
}

/// The people the signed-in person answers for (PLAYER-6): on a team, the
/// players they're linked to, as the player or a guardian; in a basic
/// group (TEAM-14), only themselves ([participantsFor]).

@ProviderFor(myParticipants)
final myParticipantsProvider = MyParticipantsFamily._();

/// The people the signed-in person answers for (PLAYER-6): on a team, the
/// players they're linked to, as the player or a guardian; in a basic
/// group (TEAM-14), only themselves ([participantsFor]).

final class MyParticipantsProvider
    extends
        $FunctionalProvider<
          List<Participant>,
          List<Participant>,
          List<Participant>
        >
    with $Provider<List<Participant>> {
  /// The people the signed-in person answers for (PLAYER-6): on a team, the
  /// players they're linked to, as the player or a guardian; in a basic
  /// group (TEAM-14), only themselves ([participantsFor]).
  MyParticipantsProvider._({
    required MyParticipantsFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'myParticipantsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myParticipantsHash();

  @override
  String toString() {
    return r'myParticipantsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<Participant>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<Participant> create(Ref ref) {
    final argument = this.argument as GroupId;
    return myParticipants(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Participant> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Participant>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MyParticipantsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myParticipantsHash() => r'a0d881ac59507f60435f3a0f3d46409d92c7b85f';

/// The people the signed-in person answers for (PLAYER-6): on a team, the
/// players they're linked to, as the player or a guardian; in a basic
/// group (TEAM-14), only themselves ([participantsFor]).

final class MyParticipantsFamily extends $Family
    with $FunctionalFamilyOverride<List<Participant>, GroupId> {
  MyParticipantsFamily._()
    : super(
        retry: null,
        name: r'myParticipantsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The people the signed-in person answers for (PLAYER-6): on a team, the
  /// players they're linked to, as the player or a guardian; in a basic
  /// group (TEAM-14), only themselves ([participantsFor]).

  MyParticipantsProvider call(GroupId groupId) =>
      MyParticipantsProvider._(argument: groupId, from: this);

  @override
  String toString() => r'myParticipantsProvider';
}

/// Whether [myParticipants] is final for [groupId]: the team's players
/// and my links to them have arrived (or failed). A basic group needs
/// neither. Lets a card wait for its RSVP rows rather than grow them.

@ProviderFor(myParticipantsReady)
final myParticipantsReadyProvider = MyParticipantsReadyFamily._();

/// Whether [myParticipants] is final for [groupId]: the team's players
/// and my links to them have arrived (or failed). A basic group needs
/// neither. Lets a card wait for its RSVP rows rather than grow them.

final class MyParticipantsReadyProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether [myParticipants] is final for [groupId]: the team's players
  /// and my links to them have arrived (or failed). A basic group needs
  /// neither. Lets a card wait for its RSVP rows rather than grow them.
  MyParticipantsReadyProvider._({
    required MyParticipantsReadyFamily super.from,
    required GroupId super.argument,
  }) : super(
         retry: null,
         name: r'myParticipantsReadyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myParticipantsReadyHash();

  @override
  String toString() {
    return r'myParticipantsReadyProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as GroupId;
    return myParticipantsReady(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MyParticipantsReadyProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myParticipantsReadyHash() =>
    r'497baea27338a7d8f2e4323b37f898440640e7be';

/// Whether [myParticipants] is final for [groupId]: the team's players
/// and my links to them have arrived (or failed). A basic group needs
/// neither. Lets a card wait for its RSVP rows rather than grow them.

final class MyParticipantsReadyFamily extends $Family
    with $FunctionalFamilyOverride<bool, GroupId> {
  MyParticipantsReadyFamily._()
    : super(
        retry: null,
        name: r'myParticipantsReadyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether [myParticipants] is final for [groupId]: the team's players
  /// and my links to them have arrived (or failed). A basic group needs
  /// neither. Lets a card wait for its RSVP rows rather than grow them.

  MyParticipantsReadyProvider call(GroupId groupId) =>
      MyParticipantsReadyProvider._(argument: groupId, from: this);

  @override
  String toString() => r'myParticipantsReadyProvider';
}

/// My answers (and my players') on a team's events starting in
/// [from, until), by event ID then participant ID (ARCH §6.2 "My RSVPs").

@ProviderFor(myRsvps)
final myRsvpsProvider = MyRsvpsFamily._();

/// My answers (and my players') on a team's events starting in
/// [from, until), by event ID then participant ID (ARCH §6.2 "My RSVPs").

final class MyRsvpsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, Map<String, Rsvp>>>,
          Map<String, Map<String, Rsvp>>,
          Stream<Map<String, Map<String, Rsvp>>>
        >
    with
        $FutureModifier<Map<String, Map<String, Rsvp>>>,
        $StreamProvider<Map<String, Map<String, Rsvp>>> {
  /// My answers (and my players') on a team's events starting in
  /// [from, until), by event ID then participant ID (ARCH §6.2 "My RSVPs").
  MyRsvpsProvider._({
    required MyRsvpsFamily super.from,
    required (GroupId, {DateTime? from, DateTime? until}) super.argument,
  }) : super(
         retry: null,
         name: r'myRsvpsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myRsvpsHash();

  @override
  String toString() {
    return r'myRsvpsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<Map<String, Map<String, Rsvp>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, Map<String, Rsvp>>> create(Ref ref) {
    final argument =
        this.argument as (GroupId, {DateTime? from, DateTime? until});
    return myRsvps(
      ref,
      argument.$1,
      from: argument.from,
      until: argument.until,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MyRsvpsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myRsvpsHash() => r'0c42fd3f9cc548678f3ad166edf22c416ea91671';

/// My answers (and my players') on a team's events starting in
/// [from, until), by event ID then participant ID (ARCH §6.2 "My RSVPs").

final class MyRsvpsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<Map<String, Map<String, Rsvp>>>,
          (GroupId, {DateTime? from, DateTime? until})
        > {
  MyRsvpsFamily._()
    : super(
        retry: null,
        name: r'myRsvpsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// My answers (and my players') on a team's events starting in
  /// [from, until), by event ID then participant ID (ARCH §6.2 "My RSVPs").

  MyRsvpsProvider call(GroupId groupId, {DateTime? from, DateTime? until}) =>
      MyRsvpsProvider._(
        argument: (groupId, from: from, until: until),
        from: this,
      );

  @override
  String toString() => r'myRsvpsProvider';
}

/// One team's Upcoming (from the start of today) or Past (before it, newest
/// first): the first [limit] live (50, or fewer for Your schedule on Teams,
/// [yourScheduleLive]), then pages of 50 (ARCH §5.3). All-day events go by
/// their dates instead (see [isUpcoming]). It starts over when the day
/// changes ([viewerToday]).

@ProviderFor(TeamEvents)
final teamEventsProvider = TeamEventsFamily._();

/// One team's Upcoming (from the start of today) or Past (before it, newest
/// first): the first [limit] live (50, or fewer for Your schedule on Teams,
/// [yourScheduleLive]), then pages of 50 (ARCH §5.3). All-day events go by
/// their dates instead (see [isUpcoming]). It starts over when the day
/// changes ([viewerToday]).
final class TeamEventsProvider
    extends $NotifierProvider<TeamEvents, EventListState> {
  /// One team's Upcoming (from the start of today) or Past (before it, newest
  /// first): the first [limit] live (50, or fewer for Your schedule on Teams,
  /// [yourScheduleLive]), then pages of 50 (ARCH §5.3). All-day events go by
  /// their dates instead (see [isUpcoming]). It starts over when the day
  /// changes ([viewerToday]).
  TeamEventsProvider._({
    required TeamEventsFamily super.from,
    required (GroupId, {bool past, int limit}) super.argument,
  }) : super(
         retry: null,
         name: r'teamEventsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamEventsHash();

  @override
  String toString() {
    return r'teamEventsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  TeamEvents create() => TeamEvents();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventListState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventListState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TeamEventsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamEventsHash() => r'8e5740c3002d6e002e9d137ff78e3ec83a082bc3';

/// One team's Upcoming (from the start of today) or Past (before it, newest
/// first): the first [limit] live (50, or fewer for Your schedule on Teams,
/// [yourScheduleLive]), then pages of 50 (ARCH §5.3). All-day events go by
/// their dates instead (see [isUpcoming]). It starts over when the day
/// changes ([viewerToday]).

final class TeamEventsFamily extends $Family
    with
        $ClassFamilyOverride<
          TeamEvents,
          EventListState,
          EventListState,
          EventListState,
          (GroupId, {bool past, int limit})
        > {
  TeamEventsFamily._()
    : super(
        retry: null,
        name: r'teamEventsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One team's Upcoming (from the start of today) or Past (before it, newest
  /// first): the first [limit] live (50, or fewer for Your schedule on Teams,
  /// [yourScheduleLive]), then pages of 50 (ARCH §5.3). All-day events go by
  /// their dates instead (see [isUpcoming]). It starts over when the day
  /// changes ([viewerToday]).

  TeamEventsProvider call(
    GroupId groupId, {
    required bool past,
    int limit = 50,
  }) => TeamEventsProvider._(
    argument: (groupId, past: past, limit: limit),
    from: this,
  );

  @override
  String toString() => r'teamEventsProvider';
}

/// One team's Upcoming (from the start of today) or Past (before it, newest
/// first): the first [limit] live (50, or fewer for Your schedule on Teams,
/// [yourScheduleLive]), then pages of 50 (ARCH §5.3). All-day events go by
/// their dates instead (see [isUpcoming]). It starts over when the day
/// changes ([viewerToday]).

abstract class _$TeamEvents extends $Notifier<EventListState> {
  late final _$args = ref.$arg as (GroupId, {bool past, int limit});
  GroupId get groupId => _$args.$1;
  bool get past => _$args.past;
  int get limit => _$args.limit;

  EventListState build(GroupId groupId, {required bool past, int limit = 50});
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EventListState, EventListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EventListState, EventListState>,
              EventListState,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(_$args.$1, past: _$args.past, limit: _$args.limit),
    );
  }
}

/// Every team I'm on, archived ones too: a calendar link's All my teams
/// is offered with more than one (SCHED-11).

@ProviderFor(scheduleTeams)
final scheduleTeamsProvider = ScheduleTeamsProvider._();

/// Every team I'm on, archived ones too: a calendar link's All my teams
/// is offered with more than one (SCHED-11).

final class ScheduleTeamsProvider
    extends $FunctionalProvider<List<Group>, List<Group>, List<Group>>
    with $Provider<List<Group>> {
  /// Every team I'm on, archived ones too: a calendar link's All my teams
  /// is offered with more than one (SCHED-11).
  ScheduleTeamsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scheduleTeamsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scheduleTeamsHash();

  @$internal
  @override
  $ProviderElement<List<Group>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Group> create(Ref ref) {
    return scheduleTeams(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Group> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Group>>(value),
    );
  }
}

String _$scheduleTeamsHash() => r'0bb0a08e239db28bf8248af64272e19c78d42ed1';

/// The teams and groups Your schedule covers (SCHED-2): the active ones
/// I'm on. An archived team's events stay on its own schedule.

@ProviderFor(yourScheduleTeams)
final yourScheduleTeamsProvider = YourScheduleTeamsProvider._();

/// The teams and groups Your schedule covers (SCHED-2): the active ones
/// I'm on. An archived team's events stay on its own schedule.

final class YourScheduleTeamsProvider
    extends $FunctionalProvider<List<Group>, List<Group>, List<Group>>
    with $Provider<List<Group>> {
  /// The teams and groups Your schedule covers (SCHED-2): the active ones
  /// I'm on. An archived team's events stay on its own schedule.
  YourScheduleTeamsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'yourScheduleTeamsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$yourScheduleTeamsHash();

  @$internal
  @override
  $ProviderElement<List<Group>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Group> create(Ref ref) {
    return yourScheduleTeams(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Group> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Group>>(value),
    );
  }
}

String _$yourScheduleTeamsHash() => r'd9e2c99a8233a8113080eb6511a798568f93e3ce';

/// Your schedule (SCHED-2): the Upcoming or Past of every team in
/// [yourScheduleTeams] merged, one query per team, each listening to its
/// first [limit]. The merged list stops where the team with the least
/// loaded runs out, so loading more never fills in a gap above what's
/// shown.

@ProviderFor(yourScheduleEvents)
final yourScheduleEventsProvider = YourScheduleEventsFamily._();

/// Your schedule (SCHED-2): the Upcoming or Past of every team in
/// [yourScheduleTeams] merged, one query per team, each listening to its
/// first [limit]. The merged list stops where the team with the least
/// loaded runs out, so loading more never fills in a gap above what's
/// shown.

final class YourScheduleEventsProvider
    extends $FunctionalProvider<EventListState, EventListState, EventListState>
    with $Provider<EventListState> {
  /// Your schedule (SCHED-2): the Upcoming or Past of every team in
  /// [yourScheduleTeams] merged, one query per team, each listening to its
  /// first [limit]. The merged list stops where the team with the least
  /// loaded runs out, so loading more never fills in a gap above what's
  /// shown.
  YourScheduleEventsProvider._({
    required YourScheduleEventsFamily super.from,
    required ({bool past, int limit}) super.argument,
  }) : super(
         retry: null,
         name: r'yourScheduleEventsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$yourScheduleEventsHash();

  @override
  String toString() {
    return r'yourScheduleEventsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<EventListState> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EventListState create(Ref ref) {
    final argument = this.argument as ({bool past, int limit});
    return yourScheduleEvents(ref, past: argument.past, limit: argument.limit);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventListState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventListState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is YourScheduleEventsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$yourScheduleEventsHash() =>
    r'a64cfdd49435bc2d1be4d77d974d5c69e8a8456e';

/// Your schedule (SCHED-2): the Upcoming or Past of every team in
/// [yourScheduleTeams] merged, one query per team, each listening to its
/// first [limit]. The merged list stops where the team with the least
/// loaded runs out, so loading more never fills in a gap above what's
/// shown.

final class YourScheduleEventsFamily extends $Family
    with $FunctionalFamilyOverride<EventListState, ({bool past, int limit})> {
  YourScheduleEventsFamily._()
    : super(
        retry: null,
        name: r'yourScheduleEventsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Your schedule (SCHED-2): the Upcoming or Past of every team in
  /// [yourScheduleTeams] merged, one query per team, each listening to its
  /// first [limit]. The merged list stops where the team with the least
  /// loaded runs out, so loading more never fills in a gap above what's
  /// shown.

  YourScheduleEventsProvider call({required bool past, int limit = 50}) =>
      YourScheduleEventsProvider._(
        argument: (past: past, limit: limit),
        from: this,
      );

  @override
  String toString() => r'yourScheduleEventsProvider';
}

/// A team's events starting in [from, until), live.

@ProviderFor(eventsInRange)
final eventsInRangeProvider = EventsInRangeFamily._();

/// A team's events starting in [from, until), live.

final class EventsInRangeProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          List<Event>,
          Stream<List<Event>>
        >
    with $FutureModifier<List<Event>>, $StreamProvider<List<Event>> {
  /// A team's events starting in [from, until), live.
  EventsInRangeProvider._({
    required EventsInRangeFamily super.from,
    required (GroupId, DateTime, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'eventsInRangeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventsInRangeHash();

  @override
  String toString() {
    return r'eventsInRangeProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<Event>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Event>> create(Ref ref) {
    final argument = this.argument as (GroupId, DateTime, DateTime);
    return eventsInRange(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is EventsInRangeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventsInRangeHash() => r'9eef473679afe800b1e58d0f15c270e989aa624c';

/// A team's events starting in [from, until), live.

final class EventsInRangeFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<Event>>,
          (GroupId, DateTime, DateTime)
        > {
  EventsInRangeFamily._()
    : super(
        retry: null,
        name: r'eventsInRangeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A team's events starting in [from, until), live.

  EventsInRangeProvider call(GroupId groupId, DateTime from, DateTime until) =>
      EventsInRangeProvider._(argument: (groupId, from, until), from: this);

  @override
  String toString() => r'eventsInRangeProvider';
}

/// Every event of a team starting in [from, until), read once (PLAYER-11).

@ProviderFor(eventsBetween)
final eventsBetweenProvider = EventsBetweenFamily._();

/// Every event of a team starting in [from, until), read once (PLAYER-11).

final class EventsBetweenProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          List<Event>,
          FutureOr<List<Event>>
        >
    with $FutureModifier<List<Event>>, $FutureProvider<List<Event>> {
  /// Every event of a team starting in [from, until), read once (PLAYER-11).
  EventsBetweenProvider._({
    required EventsBetweenFamily super.from,
    required (GroupId, DateTime, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'eventsBetweenProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventsBetweenHash();

  @override
  String toString() {
    return r'eventsBetweenProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Event>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Event>> create(Ref ref) {
    final argument = this.argument as (GroupId, DateTime, DateTime);
    return eventsBetween(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is EventsBetweenProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventsBetweenHash() => r'f0b827a74a9215848f9b9777e3716ed1fa36cdb3';

/// Every event of a team starting in [from, until), read once (PLAYER-11).

final class EventsBetweenFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Event>>,
          (GroupId, DateTime, DateTime)
        > {
  EventsBetweenFamily._()
    : super(
        retry: null,
        name: r'eventsBetweenProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Every event of a team starting in [from, until), read once (PLAYER-11).

  EventsBetweenProvider call(GroupId groupId, DateTime from, DateTime until) =>
      EventsBetweenProvider._(argument: (groupId, from, until), from: this);

  @override
  String toString() => r'eventsBetweenProvider';
}

/// A team's latest 50 events starting before [before], live.

@ProviderFor(eventsBefore)
final eventsBeforeProvider = EventsBeforeFamily._();

/// A team's latest 50 events starting before [before], live.

final class EventsBeforeProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          List<Event>,
          Stream<List<Event>>
        >
    with $FutureModifier<List<Event>>, $StreamProvider<List<Event>> {
  /// A team's latest 50 events starting before [before], live.
  EventsBeforeProvider._({
    required EventsBeforeFamily super.from,
    required (GroupId, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'eventsBeforeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventsBeforeHash();

  @override
  String toString() {
    return r'eventsBeforeProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<Event>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Event>> create(Ref ref) {
    final argument = this.argument as (GroupId, DateTime);
    return eventsBefore(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is EventsBeforeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventsBeforeHash() => r'ded03215e13d8f60444be6e42f030fdb04d0fc66';

/// A team's latest 50 events starting before [before], live.

final class EventsBeforeFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Event>>, (GroupId, DateTime)> {
  EventsBeforeFamily._()
    : super(
        retry: null,
        name: r'eventsBeforeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A team's latest 50 events starting before [before], live.

  EventsBeforeProvider call(GroupId groupId, DateTime before) =>
      EventsBeforeProvider._(argument: (groupId, before), from: this);

  @override
  String toString() => r'eventsBeforeProvider';
}

/// A month of one team's events for the calendar (SCHED-1), for every cell
/// of its grid (see [calendarWindow]), with the all-day events that began
/// before and run into it, such as a tournament from the last days of the
/// month before.

@ProviderFor(monthEvents)
final monthEventsProvider = MonthEventsFamily._();

/// A month of one team's events for the calendar (SCHED-1), for every cell
/// of its grid (see [calendarWindow]), with the all-day events that began
/// before and run into it, such as a tournament from the last days of the
/// month before.

final class MonthEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>
        >
    with $Provider<AsyncValue<List<Event>>> {
  /// A month of one team's events for the calendar (SCHED-1), for every cell
  /// of its grid (see [calendarWindow]), with the all-day events that began
  /// before and run into it, such as a tournament from the last days of the
  /// month before.
  MonthEventsProvider._({
    required MonthEventsFamily super.from,
    required (GroupId, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'monthEventsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$monthEventsHash();

  @override
  String toString() {
    return r'monthEventsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<List<Event>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Event>> create(Ref ref) {
    final argument = this.argument as (GroupId, DateTime);
    return monthEvents(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Event>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Event>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MonthEventsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$monthEventsHash() => r'1a42e448ac6eab58255072d119daa8bc5e53f531';

/// A month of one team's events for the calendar (SCHED-1), for every cell
/// of its grid (see [calendarWindow]), with the all-day events that began
/// before and run into it, such as a tournament from the last days of the
/// month before.

final class MonthEventsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<List<Event>>,
          (GroupId, DateTime)
        > {
  MonthEventsFamily._()
    : super(
        retry: null,
        name: r'monthEventsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A month of one team's events for the calendar (SCHED-1), for every cell
  /// of its grid (see [calendarWindow]), with the all-day events that began
  /// before and run into it, such as a tournament from the last days of the
  /// month before.

  MonthEventsProvider call(GroupId groupId, DateTime month) =>
      MonthEventsProvider._(argument: (groupId, month), from: this);

  @override
  String toString() => r'monthEventsProvider';
}

/// A month of Your schedule for its calendar (SCHED-2): every team's in
/// [yourScheduleTeams].

@ProviderFor(yourScheduleMonthEvents)
final yourScheduleMonthEventsProvider = YourScheduleMonthEventsFamily._();

/// A month of Your schedule for its calendar (SCHED-2): every team's in
/// [yourScheduleTeams].

final class YourScheduleMonthEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>
        >
    with $Provider<AsyncValue<List<Event>>> {
  /// A month of Your schedule for its calendar (SCHED-2): every team's in
  /// [yourScheduleTeams].
  YourScheduleMonthEventsProvider._({
    required YourScheduleMonthEventsFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'yourScheduleMonthEventsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$yourScheduleMonthEventsHash();

  @override
  String toString() {
    return r'yourScheduleMonthEventsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<List<Event>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Event>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return yourScheduleMonthEvents(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Event>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Event>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is YourScheduleMonthEventsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$yourScheduleMonthEventsHash() =>
    r'b5e909429c8bd983599352615d8b35d6c8940b38';

/// A month of Your schedule for its calendar (SCHED-2): every team's in
/// [yourScheduleTeams].

final class YourScheduleMonthEventsFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<List<Event>>, DateTime> {
  YourScheduleMonthEventsFamily._()
    : super(
        retry: null,
        name: r'yourScheduleMonthEventsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A month of Your schedule for its calendar (SCHED-2): every team's in
  /// [yourScheduleTeams].

  YourScheduleMonthEventsProvider call(DateTime month) =>
      YourScheduleMonthEventsProvider._(argument: month, from: this);

  @override
  String toString() => r'yourScheduleMonthEventsProvider';
}

/// The schedule's type filter (SCHED-2), set from the filter sheet.

@ProviderFor(ScheduleView)
final scheduleViewProvider = ScheduleViewProvider._();

/// The schedule's type filter (SCHED-2), set from the filter sheet.
final class ScheduleViewProvider
    extends $NotifierProvider<ScheduleView, ScheduleOptions> {
  /// The schedule's type filter (SCHED-2), set from the filter sheet.
  ScheduleViewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scheduleViewProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scheduleViewHash();

  @$internal
  @override
  ScheduleView create() => ScheduleView();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScheduleOptions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScheduleOptions>(value),
    );
  }
}

String _$scheduleViewHash() => r'42b07c23811247995d2290c013242338ca9fc3d6';

/// The schedule's type filter (SCHED-2), set from the filter sheet.

abstract class _$ScheduleView extends $Notifier<ScheduleOptions> {
  ScheduleOptions build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ScheduleOptions, ScheduleOptions>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ScheduleOptions, ScheduleOptions>,
              ScheduleOptions,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// A link to an event in the web app, for Share (SCHED-4).

@ProviderFor(eventLink)
final eventLinkProvider = EventLinkFamily._();

/// A link to an event in the web app, for Share (SCHED-4).

final class EventLinkProvider extends $FunctionalProvider<Uri, Uri, Uri>
    with $Provider<Uri> {
  /// A link to an event in the web app, for Share (SCHED-4).
  EventLinkProvider._({
    required EventLinkFamily super.from,
    required (GroupId, EventId) super.argument,
  }) : super(
         retry: null,
         name: r'eventLinkProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventLinkHash();

  @override
  String toString() {
    return r'eventLinkProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<Uri> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Uri create(Ref ref) {
    final argument = this.argument as (GroupId, EventId);
    return eventLink(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Uri value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Uri>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EventLinkProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventLinkHash() => r'555152fd8b6f602a74731d1e354a0d0a3264c8a0';

/// A link to an event in the web app, for Share (SCHED-4).

final class EventLinkFamily extends $Family
    with $FunctionalFamilyOverride<Uri, (GroupId, EventId)> {
  EventLinkFamily._()
    : super(
        retry: null,
        name: r'eventLinkProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A link to an event in the web app, for Share (SCHED-4).

  EventLinkProvider call(GroupId groupId, EventId eventId) =>
      EventLinkProvider._(argument: (groupId, eventId), from: this);

  @override
  String toString() => r'eventLinkProvider';
}
