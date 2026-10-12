// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'providers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EventListState {

/// Upcoming: soonest first. Past: newest first.
 List<Event> get events; bool get loading; bool get loadingMore;/// True once there's nothing more to load.
 bool get reachedEnd;
/// Create a copy of EventListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventListStateCopyWith<EventListState> get copyWith => _$EventListStateCopyWithImpl<EventListState>(this as EventListState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EventListState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventListState&&const DeepCollectionEquality().equals(other.events, _this.events)&&(identical(other.loading, _this.loading) || other.loading == _this.loading)&&(identical(other.loadingMore, _this.loadingMore) || other.loadingMore == _this.loadingMore)&&(identical(other.reachedEnd, _this.reachedEnd) || other.reachedEnd == _this.reachedEnd));
}


@override
int get hashCode {
  final _this = this as EventListState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.events),_this.loading,_this.loadingMore,_this.reachedEnd);
}

@override
String toString() {
  final _this = this as EventListState;
  return 'EventListState(events: ${_this.events}, loading: ${_this.loading}, loadingMore: ${_this.loadingMore}, reachedEnd: ${_this.reachedEnd})';
}


}

/// @nodoc
abstract mixin class $EventListStateCopyWith<$Res>  {
  factory $EventListStateCopyWith(EventListState value, $Res Function(EventListState) _then) = _$EventListStateCopyWithImpl;
@useResult
$Res call({
 List<Event> events, bool loading, bool loadingMore, bool reachedEnd
});




}
/// @nodoc
class _$EventListStateCopyWithImpl<$Res>
    implements $EventListStateCopyWith<$Res> {
  _$EventListStateCopyWithImpl(this._self, this._then);

  final EventListState _self;
  final $Res Function(EventListState) _then;

/// Create a copy of EventListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? events = null,Object? loading = null,Object? loadingMore = null,Object? reachedEnd = null,}) {
  return _then(EventListState(
events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<Event>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,reachedEnd: null == reachedEnd ? _self.reachedEnd : reachedEnd // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [EventListState].
extension EventListStatePatterns on EventListState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventListState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventListState value)  $default,){
final _that = this;
switch (_that) {
case _EventListState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventListState value)?  $default,){
final _that = this;
switch (_that) {
case _EventListState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Event> events,  bool loading,  bool loadingMore,  bool reachedEnd)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventListState() when $default != null:
return $default(_that.events,_that.loading,_that.loadingMore,_that.reachedEnd);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Event> events,  bool loading,  bool loadingMore,  bool reachedEnd)  $default,) {final _that = this;
switch (_that) {
case _EventListState():
return $default(_that.events,_that.loading,_that.loadingMore,_that.reachedEnd);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Event> events,  bool loading,  bool loadingMore,  bool reachedEnd)?  $default,) {final _that = this;
switch (_that) {
case _EventListState() when $default != null:
return $default(_that.events,_that.loading,_that.loadingMore,_that.reachedEnd);case _:
  return null;

}
}

}

/// @nodoc


class _EventListState implements EventListState {
  const _EventListState({ List<Event> events = const <Event>[], this.loading = true, this.loadingMore = false, this.reachedEnd = false}): _events = events;
  

/// Upcoming: soonest first. Past: newest first.
 final  List<Event> _events;
/// Upcoming: soonest first. Past: newest first.
@override@JsonKey() List<Event> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}

@override@JsonKey() final  bool loading;
@override@JsonKey() final  bool loadingMore;
/// True once there's nothing more to load.
@override@JsonKey() final  bool reachedEnd;

/// Create a copy of EventListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventListStateCopyWith<_EventListState> get copyWith => __$EventListStateCopyWithImpl<_EventListState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventListState&&const DeepCollectionEquality().equals(other.events, _events)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.reachedEnd, reachedEnd) || other.reachedEnd == reachedEnd));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_events),loading,loadingMore,reachedEnd);
}

@override
String toString() {
    return 'EventListState(events: $events, loading: $loading, loadingMore: $loadingMore, reachedEnd: $reachedEnd)';
}


}

/// @nodoc
abstract mixin class _$EventListStateCopyWith<$Res> implements $EventListStateCopyWith<$Res> {
  factory _$EventListStateCopyWith(_EventListState value, $Res Function(_EventListState) _then) = __$EventListStateCopyWithImpl;
@override @useResult
$Res call({
 List<Event> events, bool loading, bool loadingMore, bool reachedEnd
});




}
/// @nodoc
class __$EventListStateCopyWithImpl<$Res>
    implements _$EventListStateCopyWith<$Res> {
  __$EventListStateCopyWithImpl(this._self, this._then);

  final _EventListState _self;
  final $Res Function(_EventListState) _then;

/// Create a copy of EventListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? events = null,Object? loading = null,Object? loadingMore = null,Object? reachedEnd = null,}) {
  return _then(_EventListState(
events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<Event>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,reachedEnd: null == reachedEnd ? _self.reachedEnd : reachedEnd // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$ScheduleOptions {

 bool get allTeams;/// Empty shows everything.
 Set<EventFilter> get filters;
/// Create a copy of ScheduleOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduleOptionsCopyWith<ScheduleOptions> get copyWith => _$ScheduleOptionsCopyWithImpl<ScheduleOptions>(this as ScheduleOptions, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ScheduleOptions;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduleOptions&&(identical(other.allTeams, _this.allTeams) || other.allTeams == _this.allTeams)&&const DeepCollectionEquality().equals(other.filters, _this.filters));
}


@override
int get hashCode {
  final _this = this as ScheduleOptions;
  return Object.hash(runtimeType,_this.allTeams,const DeepCollectionEquality().hash(_this.filters));
}

@override
String toString() {
  final _this = this as ScheduleOptions;
  return 'ScheduleOptions(allTeams: ${_this.allTeams}, filters: ${_this.filters})';
}


}

/// @nodoc
abstract mixin class $ScheduleOptionsCopyWith<$Res>  {
  factory $ScheduleOptionsCopyWith(ScheduleOptions value, $Res Function(ScheduleOptions) _then) = _$ScheduleOptionsCopyWithImpl;
@useResult
$Res call({
 bool allTeams, Set<EventFilter> filters
});




}
/// @nodoc
class _$ScheduleOptionsCopyWithImpl<$Res>
    implements $ScheduleOptionsCopyWith<$Res> {
  _$ScheduleOptionsCopyWithImpl(this._self, this._then);

  final ScheduleOptions _self;
  final $Res Function(ScheduleOptions) _then;

/// Create a copy of ScheduleOptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? allTeams = null,Object? filters = null,}) {
  return _then(ScheduleOptions(
allTeams: null == allTeams ? _self.allTeams : allTeams // ignore: cast_nullable_to_non_nullable
as bool,filters: null == filters ? _self.filters : filters // ignore: cast_nullable_to_non_nullable
as Set<EventFilter>,
  ));
}

}


/// Adds pattern-matching-related methods to [ScheduleOptions].
extension ScheduleOptionsPatterns on ScheduleOptions {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScheduleOptions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScheduleOptions() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScheduleOptions value)  $default,){
final _that = this;
switch (_that) {
case _ScheduleOptions():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScheduleOptions value)?  $default,){
final _that = this;
switch (_that) {
case _ScheduleOptions() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool allTeams,  Set<EventFilter> filters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScheduleOptions() when $default != null:
return $default(_that.allTeams,_that.filters);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool allTeams,  Set<EventFilter> filters)  $default,) {final _that = this;
switch (_that) {
case _ScheduleOptions():
return $default(_that.allTeams,_that.filters);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool allTeams,  Set<EventFilter> filters)?  $default,) {final _that = this;
switch (_that) {
case _ScheduleOptions() when $default != null:
return $default(_that.allTeams,_that.filters);case _:
  return null;

}
}

}

/// @nodoc


class _ScheduleOptions extends ScheduleOptions {
  const _ScheduleOptions({this.allTeams = false,  Set<EventFilter> filters = const <EventFilter>{}}): _filters = filters,super._();
  

@override@JsonKey() final  bool allTeams;
/// Empty shows everything.
 final  Set<EventFilter> _filters;
/// Empty shows everything.
@override@JsonKey() Set<EventFilter> get filters {
  if (_filters is EqualUnmodifiableSetView) return _filters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_filters);
}


/// Create a copy of ScheduleOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduleOptionsCopyWith<_ScheduleOptions> get copyWith => __$ScheduleOptionsCopyWithImpl<_ScheduleOptions>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduleOptions&&(identical(other.allTeams, allTeams) || other.allTeams == allTeams)&&const DeepCollectionEquality().equals(other.filters, _filters));
}


@override
int get hashCode {
    return Object.hash(runtimeType,allTeams,const DeepCollectionEquality().hash(_filters));
}

@override
String toString() {
    return 'ScheduleOptions(allTeams: $allTeams, filters: $filters)';
}


}

/// @nodoc
abstract mixin class _$ScheduleOptionsCopyWith<$Res> implements $ScheduleOptionsCopyWith<$Res> {
  factory _$ScheduleOptionsCopyWith(_ScheduleOptions value, $Res Function(_ScheduleOptions) _then) = __$ScheduleOptionsCopyWithImpl;
@override @useResult
$Res call({
 bool allTeams, Set<EventFilter> filters
});




}
/// @nodoc
class __$ScheduleOptionsCopyWithImpl<$Res>
    implements _$ScheduleOptionsCopyWith<$Res> {
  __$ScheduleOptionsCopyWithImpl(this._self, this._then);

  final _ScheduleOptions _self;
  final $Res Function(_ScheduleOptions) _then;

/// Create a copy of ScheduleOptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? allTeams = null,Object? filters = null,}) {
  return _then(_ScheduleOptions(
allTeams: null == allTeams ? _self.allTeams : allTeams // ignore: cast_nullable_to_non_nullable
as bool,filters: null == filters ? _self._filters : filters // ignore: cast_nullable_to_non_nullable
as Set<EventFilter>,
  ));
}


}

// dart format on
