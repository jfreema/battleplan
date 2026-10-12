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

/// The people the signed-in person answers for on a team (PLAYER-6):
/// themselves, or on youth teams their players (and themselves when an
/// admin, Q14).

@ProviderFor(myParticipants)
final myParticipantsProvider = MyParticipantsFamily._();

/// The people the signed-in person answers for on a team (PLAYER-6):
/// themselves, or on youth teams their players (and themselves when an
/// admin, Q14).

final class MyParticipantsProvider
    extends
        $FunctionalProvider<
          List<Participant>,
          List<Participant>,
          List<Participant>
        >
    with $Provider<List<Participant>> {
  /// The people the signed-in person answers for on a team (PLAYER-6):
  /// themselves, or on youth teams their players (and themselves when an
  /// admin, Q14).
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

String _$myParticipantsHash() => r'6c9b56f91400060cea94acfb649eecb8ffc0e804';

/// The people the signed-in person answers for on a team (PLAYER-6):
/// themselves, or on youth teams their players (and themselves when an
/// admin, Q14).

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

  /// The people the signed-in person answers for on a team (PLAYER-6):
  /// themselves, or on youth teams their players (and themselves when an
  /// admin, Q14).

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
/// first): the first 50 live, then pages of 50 (ARCH §5.3).

@ProviderFor(TeamEvents)
final teamEventsProvider = TeamEventsFamily._();

/// One team's Upcoming (from the start of today) or Past (before it, newest
/// first): the first 50 live, then pages of 50 (ARCH §5.3).
final class TeamEventsProvider
    extends $NotifierProvider<TeamEvents, EventListState> {
  /// One team's Upcoming (from the start of today) or Past (before it, newest
  /// first): the first 50 live, then pages of 50 (ARCH §5.3).
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

String _$teamEventsHash() => r'3fe0da1f5c917c7e9be96d08242f391d75692874';

/// One team's Upcoming (from the start of today) or Past (before it, newest
/// first): the first 50 live, then pages of 50 (ARCH §5.3).

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
  /// first): the first 50 live, then pages of 50 (ARCH §5.3).

  TeamEventsProvider call(GroupId groupId, {required bool past}) =>
      TeamEventsProvider._(argument: (groupId, past: past), from: this);

  @override
  String toString() => r'teamEventsProvider';
}

/// One team's Upcoming (from the start of today) or Past (before it, newest
/// first): the first 50 live, then pages of 50 (ARCH §5.3).

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

String _$allTeamsEventsHash() => r'2ab1b8b716bfeb6aa3cad20b2997d84397f6f6c3';

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

/// A month of one team's events for the calendar (SCHED-1). [month] is
/// any day in it (date-only); the month runs midnight to midnight in the
/// viewer's zone.

@ProviderFor(monthEvents)
final monthEventsProvider = MonthEventsFamily._();

/// A month of one team's events for the calendar (SCHED-1). [month] is
/// any day in it (date-only); the month runs midnight to midnight in the
/// viewer's zone.

final class MonthEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          List<Event>,
          Stream<List<Event>>
        >
    with $FutureModifier<List<Event>>, $StreamProvider<List<Event>> {
  /// A month of one team's events for the calendar (SCHED-1). [month] is
  /// any day in it (date-only); the month runs midnight to midnight in the
  /// viewer's zone.
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
  $StreamProviderElement<List<Event>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Event>> create(Ref ref) {
    final argument = this.argument as (GroupId, DateTime);
    return monthEvents(ref, argument.$1, argument.$2);
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

String _$monthEventsHash() => r'e145233a6c4f24c9595cda2179bb8d1eb258a333';

/// A month of one team's events for the calendar (SCHED-1). [month] is
/// any day in it (date-only); the month runs midnight to midnight in the
/// viewer's zone.

final class MonthEventsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Event>>, (GroupId, DateTime)> {
  MonthEventsFamily._()
    : super(
        retry: null,
        name: r'monthEventsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A month of one team's events for the calendar (SCHED-1). [month] is
  /// any day in it (date-only); the month runs midnight to midnight in the
  /// viewer's zone.

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

String _$eventLinkHash() => r'551c3dc1d2b2122ef255f97410eeab5aae295ff1';

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
