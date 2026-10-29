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

/// The viewer's own time zone: times show in it (SCHED-9).

@ProviderFor(viewerTimeZone)
final viewerTimeZoneProvider = ViewerTimeZoneProvider._();

/// The viewer's own time zone: times show in it (SCHED-9).

final class ViewerTimeZoneProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// The viewer's own time zone: times show in it (SCHED-9).
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

String _$viewerTimeZoneHash() => r'73cbf660c75001d4b5b8460f7b66a9db9ea85e3c';

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

/// The people the signed-in person answers for on a team (PLAYER-6): the
/// players they're linked to, and themselves when they're an admin or
/// aren't linked to any player ([participantsFor]). In a basic group
/// (TEAM-14) it's only themselves.

@ProviderFor(myParticipants)
final myParticipantsProvider = MyParticipantsFamily._();

/// The people the signed-in person answers for on a team (PLAYER-6): the
/// players they're linked to, and themselves when they're an admin or
/// aren't linked to any player ([participantsFor]). In a basic group
/// (TEAM-14) it's only themselves.

final class MyParticipantsProvider
    extends
        $FunctionalProvider<
          List<Participant>,
          List<Participant>,
          List<Participant>
        >
    with $Provider<List<Participant>> {
  /// The people the signed-in person answers for on a team (PLAYER-6): the
  /// players they're linked to, and themselves when they're an admin or
  /// aren't linked to any player ([participantsFor]). In a basic group
  /// (TEAM-14) it's only themselves.
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

String _$myParticipantsHash() => r'013e50d7bc0bf6810fb376a36d4e87d90ec72bb2';

/// The people the signed-in person answers for on a team (PLAYER-6): the
/// players they're linked to, and themselves when they're an admin or
/// aren't linked to any player ([participantsFor]). In a basic group
/// (TEAM-14) it's only themselves.

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

  /// The people the signed-in person answers for on a team (PLAYER-6): the
  /// players they're linked to, and themselves when they're an admin or
  /// aren't linked to any player ([participantsFor]). In a basic group
  /// (TEAM-14) it's only themselves.

  MyParticipantsProvider call(GroupId groupId) =>
      MyParticipantsProvider._(argument: groupId, from: this);

  @override
  String toString() => r'myParticipantsProvider';
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
/// first): the first 50 live, then pages of 50 (ARCH §5.3). All-day events
/// go by their dates instead (see [isUpcoming]).

@ProviderFor(TeamEvents)
final teamEventsProvider = TeamEventsFamily._();

/// One team's Upcoming (from the start of today) or Past (before it, newest
/// first): the first 50 live, then pages of 50 (ARCH §5.3). All-day events
/// go by their dates instead (see [isUpcoming]).
final class TeamEventsProvider
    extends $NotifierProvider<TeamEvents, EventListState> {
  /// One team's Upcoming (from the start of today) or Past (before it, newest
  /// first): the first 50 live, then pages of 50 (ARCH §5.3). All-day events
  /// go by their dates instead (see [isUpcoming]).
  TeamEventsProvider._({
    required TeamEventsFamily super.from,
    required (GroupId, {bool past}) super.argument,
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

String _$teamEventsHash() => r'60c36ad65b4e5908d4c7617db006e9a0ae809027';

/// One team's Upcoming (from the start of today) or Past (before it, newest
/// first): the first 50 live, then pages of 50 (ARCH §5.3). All-day events
/// go by their dates instead (see [isUpcoming]).

final class TeamEventsFamily extends $Family
    with
        $ClassFamilyOverride<
          TeamEvents,
          EventListState,
          EventListState,
          EventListState,
          (GroupId, {bool past})
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
  /// first): the first 50 live, then pages of 50 (ARCH §5.3). All-day events
  /// go by their dates instead (see [isUpcoming]).

  TeamEventsProvider call(GroupId groupId, {required bool past}) =>
      TeamEventsProvider._(argument: (groupId, past: past), from: this);

  @override
  String toString() => r'teamEventsProvider';
}

/// One team's Upcoming (from the start of today) or Past (before it, newest
/// first): the first 50 live, then pages of 50 (ARCH §5.3). All-day events
/// go by their dates instead (see [isUpcoming]).

abstract class _$TeamEvents extends $Notifier<EventListState> {
  late final _$args = ref.$arg as (GroupId, {bool past});
  GroupId get groupId => _$args.$1;
  bool get past => _$args.past;

  EventListState build(GroupId groupId, {required bool past});
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
    return element.handleCreate(ref, () => build(_$args.$1, past: _$args.past));
  }
}

/// The teams "All my teams" merges (SCHED-2): every team I'm on.

@ProviderFor(scheduleTeams)
final scheduleTeamsProvider = ScheduleTeamsProvider._();

/// The teams "All my teams" merges (SCHED-2): every team I'm on.

final class ScheduleTeamsProvider
    extends $FunctionalProvider<List<Group>, List<Group>, List<Group>>
    with $Provider<List<Group>> {
  /// The teams "All my teams" merges (SCHED-2): every team I'm on.
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

/// Every team's Upcoming or Past merged (SCHED-2), one query per team.
/// The merged list stops where the team with the least loaded runs out,
/// so loading more never fills in a gap above what's shown.

@ProviderFor(allTeamsEvents)
final allTeamsEventsProvider = AllTeamsEventsFamily._();

/// Every team's Upcoming or Past merged (SCHED-2), one query per team.
/// The merged list stops where the team with the least loaded runs out,
/// so loading more never fills in a gap above what's shown.

final class AllTeamsEventsProvider
    extends $FunctionalProvider<EventListState, EventListState, EventListState>
    with $Provider<EventListState> {
  /// Every team's Upcoming or Past merged (SCHED-2), one query per team.
  /// The merged list stops where the team with the least loaded runs out,
  /// so loading more never fills in a gap above what's shown.
  AllTeamsEventsProvider._({
    required AllTeamsEventsFamily super.from,
    required bool super.argument,
  }) : super(
         retry: null,
         name: r'allTeamsEventsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$allTeamsEventsHash();

  @override
  String toString() {
    return r'allTeamsEventsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<EventListState> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EventListState create(Ref ref) {
    final argument = this.argument as bool;
    return allTeamsEvents(ref, past: argument);
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
    return other is AllTeamsEventsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$allTeamsEventsHash() => r'0b59f13460a46b361f7c0ed88d1e226c0a58eba1';

/// Every team's Upcoming or Past merged (SCHED-2), one query per team.
/// The merged list stops where the team with the least loaded runs out,
/// so loading more never fills in a gap above what's shown.

final class AllTeamsEventsFamily extends $Family
    with $FunctionalFamilyOverride<EventListState, bool> {
  AllTeamsEventsFamily._()
    : super(
        retry: null,
        name: r'allTeamsEventsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Every team's Upcoming or Past merged (SCHED-2), one query per team.
  /// The merged list stops where the team with the least loaded runs out,
  /// so loading more never fills in a gap above what's shown.

  AllTeamsEventsProvider call({required bool past}) =>
      AllTeamsEventsProvider._(argument: past, from: this);

  @override
  String toString() => r'allTeamsEventsProvider';
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

/// A month of every team's events (SCHED-2 with the calendar).

@ProviderFor(allTeamsMonthEvents)
final allTeamsMonthEventsProvider = AllTeamsMonthEventsFamily._();

/// A month of every team's events (SCHED-2 with the calendar).

final class AllTeamsMonthEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>,
          AsyncValue<List<Event>>
        >
    with $Provider<AsyncValue<List<Event>>> {
  /// A month of every team's events (SCHED-2 with the calendar).
  AllTeamsMonthEventsProvider._({
    required AllTeamsMonthEventsFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'allTeamsMonthEventsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$allTeamsMonthEventsHash();

  @override
  String toString() {
    return r'allTeamsMonthEventsProvider'
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
    return allTeamsMonthEvents(ref, argument);
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
    return other is AllTeamsMonthEventsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$allTeamsMonthEventsHash() =>
    r'0f76f70fb6e6f533611c62e1666d27b9619b11b3';

/// A month of every team's events (SCHED-2 with the calendar).

final class AllTeamsMonthEventsFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<List<Event>>, DateTime> {
  AllTeamsMonthEventsFamily._()
    : super(
        retry: null,
        name: r'allTeamsMonthEventsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A month of every team's events (SCHED-2 with the calendar).

  AllTeamsMonthEventsProvider call(DateTime month) =>
      AllTeamsMonthEventsProvider._(argument: month, from: this);

  @override
  String toString() => r'allTeamsMonthEventsProvider';
}

/// The schedule's toggle and filter (SCHED-2).

@ProviderFor(ScheduleView)
final scheduleViewProvider = ScheduleViewProvider._();

/// The schedule's toggle and filter (SCHED-2).
final class ScheduleViewProvider
    extends $NotifierProvider<ScheduleView, ScheduleOptions> {
  /// The schedule's toggle and filter (SCHED-2).
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

String _$scheduleViewHash() => r'6af0da7f98c8add3bf2258e004fd403975f1c079';

/// The schedule's toggle and filter (SCHED-2).

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
