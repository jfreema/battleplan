// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'next_up.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The next few events from the start of today, for the chat's strip: one
/// small listener, five events at most.

@ProviderFor(_soonestEvents)
final _soonestEventsProvider = _SoonestEventsFamily._();

/// The next few events from the start of today, for the chat's strip: one
/// small listener, five events at most.

final class _SoonestEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          List<Event>,
          Stream<List<Event>>
        >
    with $FutureModifier<List<Event>>, $StreamProvider<List<Event>> {
  /// The next few events from the start of today, for the chat's strip: one
  /// small listener, five events at most.
  _SoonestEventsProvider._({
    required _SoonestEventsFamily super.from,
    required (GroupId, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'_soonestEventsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_soonestEventsHash();

  @override
  String toString() {
    return r'_soonestEventsProvider'
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
    return _soonestEvents(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is _SoonestEventsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_soonestEventsHash() => r'2203a329552c7551d063109af29da7fc483f24b1';

/// The next few events from the start of today, for the chat's strip: one
/// small listener, five events at most.

final class _SoonestEventsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Event>>, (GroupId, DateTime)> {
  _SoonestEventsFamily._()
    : super(
        retry: null,
        name: r'_soonestEventsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The next few events from the start of today, for the chat's strip: one
  /// small listener, five events at most.

  _SoonestEventsProvider call(GroupId groupId, DateTime from) =>
      _SoonestEventsProvider._(argument: (groupId, from), from: this);

  @override
  String toString() => r'_soonestEventsProvider';
}

/// [groupId]'s next event that hasn't ended, within [nextUpDays] (#43), with
/// my answers to it: one source for the chat's Next up strip and the line on
/// the team's card on Teams, from the same reads as the Schedule, so they
/// agree. [onTeams] reads Your schedule's own list of the team's next ten,
/// already open under the cards, and only my answers on that one event;
/// the chat reads the next five, and the answers its event cards already
/// listen to. Null with none coming up, and on an archived team, which gets
/// no listener.

@ProviderFor(nextUp)
final nextUpProvider = NextUpFamily._();

/// [groupId]'s next event that hasn't ended, within [nextUpDays] (#43), with
/// my answers to it: one source for the chat's Next up strip and the line on
/// the team's card on Teams, from the same reads as the Schedule, so they
/// agree. [onTeams] reads Your schedule's own list of the team's next ten,
/// already open under the cards, and only my answers on that one event;
/// the chat reads the next five, and the answers its event cards already
/// listen to. Null with none coming up, and on an archived team, which gets
/// no listener.

final class NextUpProvider
    extends
        $FunctionalProvider<
          AsyncValue<NextUp?>,
          AsyncValue<NextUp?>,
          AsyncValue<NextUp?>
        >
    with $Provider<AsyncValue<NextUp?>> {
  /// [groupId]'s next event that hasn't ended, within [nextUpDays] (#43), with
  /// my answers to it: one source for the chat's Next up strip and the line on
  /// the team's card on Teams, from the same reads as the Schedule, so they
  /// agree. [onTeams] reads Your schedule's own list of the team's next ten,
  /// already open under the cards, and only my answers on that one event;
  /// the chat reads the next five, and the answers its event cards already
  /// listen to. Null with none coming up, and on an archived team, which gets
  /// no listener.
  NextUpProvider._({
    required NextUpFamily super.from,
    required (GroupId, {bool onTeams}) super.argument,
  }) : super(
         retry: null,
         name: r'nextUpProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$nextUpHash();

  @override
  String toString() {
    return r'nextUpProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<NextUp?>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<NextUp?> create(Ref ref) {
    final argument = this.argument as (GroupId, {bool onTeams});
    return nextUp(ref, argument.$1, onTeams: argument.onTeams);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<NextUp?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<NextUp?>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NextUpProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$nextUpHash() => r'a99793c03a2b8329b4087d325effc888dadd27e4';

/// [groupId]'s next event that hasn't ended, within [nextUpDays] (#43), with
/// my answers to it: one source for the chat's Next up strip and the line on
/// the team's card on Teams, from the same reads as the Schedule, so they
/// agree. [onTeams] reads Your schedule's own list of the team's next ten,
/// already open under the cards, and only my answers on that one event;
/// the chat reads the next five, and the answers its event cards already
/// listen to. Null with none coming up, and on an archived team, which gets
/// no listener.

final class NextUpFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<NextUp?>,
          (GroupId, {bool onTeams})
        > {
  NextUpFamily._()
    : super(
        retry: null,
        name: r'nextUpProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// [groupId]'s next event that hasn't ended, within [nextUpDays] (#43), with
  /// my answers to it: one source for the chat's Next up strip and the line on
  /// the team's card on Teams, from the same reads as the Schedule, so they
  /// agree. [onTeams] reads Your schedule's own list of the team's next ten,
  /// already open under the cards, and only my answers on that one event;
  /// the chat reads the next five, and the answers its event cards already
  /// listen to. Null with none coming up, and on an archived team, which gets
  /// no listener.

  NextUpProvider call(GroupId groupId, {bool onTeams = false}) =>
      NextUpProvider._(argument: (groupId, onTeams: onTeams), from: this);

  @override
  String toString() => r'nextUpProvider';
}
