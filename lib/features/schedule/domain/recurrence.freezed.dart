// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurrence.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Recurrence {

 RepeatFreq get freq; String get startDate; int get interval;/// ISO weekdays, Monday = 1 (weekly only).
 List<int> get byWeekday;/// The last day it may fall on, 'YYYY-MM-DD'.
 String? get untilDate;/// How many events, counting only the dates kept after [skipDates].
 int? get count;/// Holidays and breaks (SCHED-3), 'YYYY-MM-DD'.
 List<String> get skipDates;
/// Create a copy of Recurrence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurrenceCopyWith<Recurrence> get copyWith => _$RecurrenceCopyWithImpl<Recurrence>(this as Recurrence, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Recurrence;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Recurrence&&(identical(other.freq, _this.freq) || other.freq == _this.freq)&&(identical(other.startDate, _this.startDate) || other.startDate == _this.startDate)&&(identical(other.interval, _this.interval) || other.interval == _this.interval)&&const DeepCollectionEquality().equals(other.byWeekday, _this.byWeekday)&&(identical(other.untilDate, _this.untilDate) || other.untilDate == _this.untilDate)&&(identical(other.count, _this.count) || other.count == _this.count)&&const DeepCollectionEquality().equals(other.skipDates, _this.skipDates));
}


@override
int get hashCode {
  final _this = this as Recurrence;
  return Object.hash(runtimeType,_this.freq,_this.startDate,_this.interval,const DeepCollectionEquality().hash(_this.byWeekday),_this.untilDate,_this.count,const DeepCollectionEquality().hash(_this.skipDates));
}

@override
String toString() {
  final _this = this as Recurrence;
  return 'Recurrence(freq: ${_this.freq}, startDate: ${_this.startDate}, interval: ${_this.interval}, byWeekday: ${_this.byWeekday}, untilDate: ${_this.untilDate}, count: ${_this.count}, skipDates: ${_this.skipDates})';
}


}

/// @nodoc
abstract mixin class $RecurrenceCopyWith<$Res>  {
  factory $RecurrenceCopyWith(Recurrence value, $Res Function(Recurrence) _then) = _$RecurrenceCopyWithImpl;
@useResult
$Res call({
 RepeatFreq freq, String startDate, int interval, List<int> byWeekday, String? untilDate, int? count, List<String> skipDates
});




}
/// @nodoc
class _$RecurrenceCopyWithImpl<$Res>
    implements $RecurrenceCopyWith<$Res> {
  _$RecurrenceCopyWithImpl(this._self, this._then);

  final Recurrence _self;
  final $Res Function(Recurrence) _then;

/// Create a copy of Recurrence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? freq = null,Object? startDate = null,Object? interval = null,Object? byWeekday = null,Object? untilDate = freezed,Object? count = freezed,Object? skipDates = null,}) {
  return _then(Recurrence(
freq: null == freq ? _self.freq : freq // ignore: cast_nullable_to_non_nullable
as RepeatFreq,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,byWeekday: null == byWeekday ? _self.byWeekday : byWeekday // ignore: cast_nullable_to_non_nullable
as List<int>,untilDate: freezed == untilDate ? _self.untilDate : untilDate // ignore: cast_nullable_to_non_nullable
as String?,count: freezed == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int?,skipDates: null == skipDates ? _self.skipDates : skipDates // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [Recurrence].
extension RecurrencePatterns on Recurrence {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Recurrence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Recurrence() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Recurrence value)  $default,){
final _that = this;
switch (_that) {
case _Recurrence():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Recurrence value)?  $default,){
final _that = this;
switch (_that) {
case _Recurrence() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RepeatFreq freq,  String startDate,  int interval,  List<int> byWeekday,  String? untilDate,  int? count,  List<String> skipDates)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Recurrence() when $default != null:
return $default(_that.freq,_that.startDate,_that.interval,_that.byWeekday,_that.untilDate,_that.count,_that.skipDates);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RepeatFreq freq,  String startDate,  int interval,  List<int> byWeekday,  String? untilDate,  int? count,  List<String> skipDates)  $default,) {final _that = this;
switch (_that) {
case _Recurrence():
return $default(_that.freq,_that.startDate,_that.interval,_that.byWeekday,_that.untilDate,_that.count,_that.skipDates);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RepeatFreq freq,  String startDate,  int interval,  List<int> byWeekday,  String? untilDate,  int? count,  List<String> skipDates)?  $default,) {final _that = this;
switch (_that) {
case _Recurrence() when $default != null:
return $default(_that.freq,_that.startDate,_that.interval,_that.byWeekday,_that.untilDate,_that.count,_that.skipDates);case _:
  return null;

}
}

}

/// @nodoc


class _Recurrence extends Recurrence {
  const _Recurrence({required this.freq, required this.startDate, this.interval = 1,  List<int> byWeekday = const <int>[], this.untilDate, this.count,  List<String> skipDates = const <String>[]}): _byWeekday = byWeekday,_skipDates = skipDates,super._();
  

@override final  RepeatFreq freq;
@override final  String startDate;
@override@JsonKey() final  int interval;
/// ISO weekdays, Monday = 1 (weekly only).
 final  List<int> _byWeekday;
/// ISO weekdays, Monday = 1 (weekly only).
@override@JsonKey() List<int> get byWeekday {
  if (_byWeekday is EqualUnmodifiableListView) return _byWeekday;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_byWeekday);
}

/// The last day it may fall on, 'YYYY-MM-DD'.
@override final  String? untilDate;
/// How many events, counting only the dates kept after [skipDates].
@override final  int? count;
/// Holidays and breaks (SCHED-3), 'YYYY-MM-DD'.
 final  List<String> _skipDates;
/// Holidays and breaks (SCHED-3), 'YYYY-MM-DD'.
@override@JsonKey() List<String> get skipDates {
  if (_skipDates is EqualUnmodifiableListView) return _skipDates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_skipDates);
}


/// Create a copy of Recurrence
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurrenceCopyWith<_Recurrence> get copyWith => __$RecurrenceCopyWithImpl<_Recurrence>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Recurrence&&(identical(other.freq, freq) || other.freq == freq)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.interval, interval) || other.interval == interval)&&const DeepCollectionEquality().equals(other.byWeekday, _byWeekday)&&(identical(other.untilDate, untilDate) || other.untilDate == untilDate)&&(identical(other.count, count) || other.count == count)&&const DeepCollectionEquality().equals(other.skipDates, _skipDates));
}


@override
int get hashCode {
    return Object.hash(runtimeType,freq,startDate,interval,const DeepCollectionEquality().hash(_byWeekday),untilDate,count,const DeepCollectionEquality().hash(_skipDates));
}

@override
String toString() {
    return 'Recurrence(freq: $freq, startDate: $startDate, interval: $interval, byWeekday: $byWeekday, untilDate: $untilDate, count: $count, skipDates: $skipDates)';
}


}

/// @nodoc
abstract mixin class _$RecurrenceCopyWith<$Res> implements $RecurrenceCopyWith<$Res> {
  factory _$RecurrenceCopyWith(_Recurrence value, $Res Function(_Recurrence) _then) = __$RecurrenceCopyWithImpl;
@override @useResult
$Res call({
 RepeatFreq freq, String startDate, int interval, List<int> byWeekday, String? untilDate, int? count, List<String> skipDates
});




}
/// @nodoc
class __$RecurrenceCopyWithImpl<$Res>
    implements _$RecurrenceCopyWith<$Res> {
  __$RecurrenceCopyWithImpl(this._self, this._then);

  final _Recurrence _self;
  final $Res Function(_Recurrence) _then;

/// Create a copy of Recurrence
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? freq = null,Object? startDate = null,Object? interval = null,Object? byWeekday = null,Object? untilDate = freezed,Object? count = freezed,Object? skipDates = null,}) {
  return _then(_Recurrence(
freq: null == freq ? _self.freq : freq // ignore: cast_nullable_to_non_nullable
as RepeatFreq,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,byWeekday: null == byWeekday ? _self._byWeekday : byWeekday // ignore: cast_nullable_to_non_nullable
as List<int>,untilDate: freezed == untilDate ? _self.untilDate : untilDate // ignore: cast_nullable_to_non_nullable
as String?,count: freezed == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int?,skipDates: null == skipDates ? _self._skipDates : skipDates // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$EventSeries {

 String get id; GroupId get groupId; String get timeZone; Recurrence get recurrence; String get createdBy;
/// Create a copy of EventSeries
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventSeriesCopyWith<EventSeries> get copyWith => _$EventSeriesCopyWithImpl<EventSeries>(this as EventSeries, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EventSeries;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventSeries&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.timeZone, _this.timeZone) || other.timeZone == _this.timeZone)&&(identical(other.recurrence, _this.recurrence) || other.recurrence == _this.recurrence)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy));
}


@override
int get hashCode {
  final _this = this as EventSeries;
  return Object.hash(runtimeType,_this.id,_this.groupId,_this.timeZone,_this.recurrence,_this.createdBy);
}

@override
String toString() {
  final _this = this as EventSeries;
  return 'EventSeries(id: ${_this.id}, groupId: ${_this.groupId}, timeZone: ${_this.timeZone}, recurrence: ${_this.recurrence}, createdBy: ${_this.createdBy})';
}


}

/// @nodoc
abstract mixin class $EventSeriesCopyWith<$Res>  {
  factory $EventSeriesCopyWith(EventSeries value, $Res Function(EventSeries) _then) = _$EventSeriesCopyWithImpl;
@useResult
$Res call({
 String id, GroupId groupId, String timeZone, Recurrence recurrence, String createdBy
});


$RecurrenceCopyWith<$Res> get recurrence;

}
/// @nodoc
class _$EventSeriesCopyWithImpl<$Res>
    implements $EventSeriesCopyWith<$Res> {
  _$EventSeriesCopyWithImpl(this._self, this._then);

  final EventSeries _self;
  final $Res Function(EventSeries) _then;

/// Create a copy of EventSeries
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? groupId = null,Object? timeZone = null,Object? recurrence = null,Object? createdBy = null,}) {
  return _then(EventSeries(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,timeZone: null == timeZone ? _self.timeZone : timeZone // ignore: cast_nullable_to_non_nullable
as String,recurrence: null == recurrence ? _self.recurrence : recurrence // ignore: cast_nullable_to_non_nullable
as Recurrence,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of EventSeries
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecurrenceCopyWith<$Res> get recurrence {
  
  return $RecurrenceCopyWith<$Res>(_self.recurrence, (value) {
    return _then(_self.copyWith(recurrence: value));
  });
}
}


/// Adds pattern-matching-related methods to [EventSeries].
extension EventSeriesPatterns on EventSeries {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventSeries value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventSeries() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventSeries value)  $default,){
final _that = this;
switch (_that) {
case _EventSeries():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventSeries value)?  $default,){
final _that = this;
switch (_that) {
case _EventSeries() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  GroupId groupId,  String timeZone,  Recurrence recurrence,  String createdBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventSeries() when $default != null:
return $default(_that.id,_that.groupId,_that.timeZone,_that.recurrence,_that.createdBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  GroupId groupId,  String timeZone,  Recurrence recurrence,  String createdBy)  $default,) {final _that = this;
switch (_that) {
case _EventSeries():
return $default(_that.id,_that.groupId,_that.timeZone,_that.recurrence,_that.createdBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  GroupId groupId,  String timeZone,  Recurrence recurrence,  String createdBy)?  $default,) {final _that = this;
switch (_that) {
case _EventSeries() when $default != null:
return $default(_that.id,_that.groupId,_that.timeZone,_that.recurrence,_that.createdBy);case _:
  return null;

}
}

}

/// @nodoc


class _EventSeries implements EventSeries {
  const _EventSeries({required this.id, required this.groupId, required this.timeZone, required this.recurrence, required this.createdBy});
  

@override final  String id;
@override final  GroupId groupId;
@override final  String timeZone;
@override final  Recurrence recurrence;
@override final  String createdBy;

/// Create a copy of EventSeries
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventSeriesCopyWith<_EventSeries> get copyWith => __$EventSeriesCopyWithImpl<_EventSeries>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventSeries&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.timeZone, timeZone) || other.timeZone == timeZone)&&(identical(other.recurrence, recurrence) || other.recurrence == recurrence)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,groupId,timeZone,recurrence,createdBy);
}

@override
String toString() {
    return 'EventSeries(id: $id, groupId: $groupId, timeZone: $timeZone, recurrence: $recurrence, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$EventSeriesCopyWith<$Res> implements $EventSeriesCopyWith<$Res> {
  factory _$EventSeriesCopyWith(_EventSeries value, $Res Function(_EventSeries) _then) = __$EventSeriesCopyWithImpl;
@override @useResult
$Res call({
 String id, GroupId groupId, String timeZone, Recurrence recurrence, String createdBy
});


@override $RecurrenceCopyWith<$Res> get recurrence;

}
/// @nodoc
class __$EventSeriesCopyWithImpl<$Res>
    implements _$EventSeriesCopyWith<$Res> {
  __$EventSeriesCopyWithImpl(this._self, this._then);

  final _EventSeries _self;
  final $Res Function(_EventSeries) _then;

/// Create a copy of EventSeries
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? groupId = null,Object? timeZone = null,Object? recurrence = null,Object? createdBy = null,}) {
  return _then(_EventSeries(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,timeZone: null == timeZone ? _self.timeZone : timeZone // ignore: cast_nullable_to_non_nullable
as String,recurrence: null == recurrence ? _self.recurrence : recurrence // ignore: cast_nullable_to_non_nullable
as Recurrence,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of EventSeries
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecurrenceCopyWith<$Res> get recurrence {
  
  return $RecurrenceCopyWith<$Res>(_self.recurrence, (value) {
    return _then(_self.copyWith(recurrence: value));
  });
}
}

/// @nodoc
mixin _$SeriesResult {

 String? get seriesId; int get created; int get updated; int get removed; int get removedRsvps; int get canceled;
/// Create a copy of SeriesResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeriesResultCopyWith<SeriesResult> get copyWith => _$SeriesResultCopyWithImpl<SeriesResult>(this as SeriesResult, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SeriesResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SeriesResult&&(identical(other.seriesId, _this.seriesId) || other.seriesId == _this.seriesId)&&(identical(other.created, _this.created) || other.created == _this.created)&&(identical(other.updated, _this.updated) || other.updated == _this.updated)&&(identical(other.removed, _this.removed) || other.removed == _this.removed)&&(identical(other.removedRsvps, _this.removedRsvps) || other.removedRsvps == _this.removedRsvps)&&(identical(other.canceled, _this.canceled) || other.canceled == _this.canceled));
}


@override
int get hashCode {
  final _this = this as SeriesResult;
  return Object.hash(runtimeType,_this.seriesId,_this.created,_this.updated,_this.removed,_this.removedRsvps,_this.canceled);
}

@override
String toString() {
  final _this = this as SeriesResult;
  return 'SeriesResult(seriesId: ${_this.seriesId}, created: ${_this.created}, updated: ${_this.updated}, removed: ${_this.removed}, removedRsvps: ${_this.removedRsvps}, canceled: ${_this.canceled})';
}


}

/// @nodoc
abstract mixin class $SeriesResultCopyWith<$Res>  {
  factory $SeriesResultCopyWith(SeriesResult value, $Res Function(SeriesResult) _then) = _$SeriesResultCopyWithImpl;
@useResult
$Res call({
 String? seriesId, int created, int updated, int removed, int removedRsvps, int canceled
});




}
/// @nodoc
class _$SeriesResultCopyWithImpl<$Res>
    implements $SeriesResultCopyWith<$Res> {
  _$SeriesResultCopyWithImpl(this._self, this._then);

  final SeriesResult _self;
  final $Res Function(SeriesResult) _then;

/// Create a copy of SeriesResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seriesId = freezed,Object? created = null,Object? updated = null,Object? removed = null,Object? removedRsvps = null,Object? canceled = null,}) {
  return _then(SeriesResult(
seriesId: freezed == seriesId ? _self.seriesId : seriesId // ignore: cast_nullable_to_non_nullable
as String?,created: null == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as int,updated: null == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as int,removed: null == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int,removedRsvps: null == removedRsvps ? _self.removedRsvps : removedRsvps // ignore: cast_nullable_to_non_nullable
as int,canceled: null == canceled ? _self.canceled : canceled // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SeriesResult].
extension SeriesResultPatterns on SeriesResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SeriesResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SeriesResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SeriesResult value)  $default,){
final _that = this;
switch (_that) {
case _SeriesResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SeriesResult value)?  $default,){
final _that = this;
switch (_that) {
case _SeriesResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? seriesId,  int created,  int updated,  int removed,  int removedRsvps,  int canceled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SeriesResult() when $default != null:
return $default(_that.seriesId,_that.created,_that.updated,_that.removed,_that.removedRsvps,_that.canceled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? seriesId,  int created,  int updated,  int removed,  int removedRsvps,  int canceled)  $default,) {final _that = this;
switch (_that) {
case _SeriesResult():
return $default(_that.seriesId,_that.created,_that.updated,_that.removed,_that.removedRsvps,_that.canceled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? seriesId,  int created,  int updated,  int removed,  int removedRsvps,  int canceled)?  $default,) {final _that = this;
switch (_that) {
case _SeriesResult() when $default != null:
return $default(_that.seriesId,_that.created,_that.updated,_that.removed,_that.removedRsvps,_that.canceled);case _:
  return null;

}
}

}

/// @nodoc


class _SeriesResult implements SeriesResult {
  const _SeriesResult({this.seriesId, this.created = 0, this.updated = 0, this.removed = 0, this.removedRsvps = 0, this.canceled = 0});
  

@override final  String? seriesId;
@override@JsonKey() final  int created;
@override@JsonKey() final  int updated;
@override@JsonKey() final  int removed;
@override@JsonKey() final  int removedRsvps;
@override@JsonKey() final  int canceled;

/// Create a copy of SeriesResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SeriesResultCopyWith<_SeriesResult> get copyWith => __$SeriesResultCopyWithImpl<_SeriesResult>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SeriesResult&&(identical(other.seriesId, seriesId) || other.seriesId == seriesId)&&(identical(other.created, created) || other.created == created)&&(identical(other.updated, updated) || other.updated == updated)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.removedRsvps, removedRsvps) || other.removedRsvps == removedRsvps)&&(identical(other.canceled, canceled) || other.canceled == canceled));
}


@override
int get hashCode {
    return Object.hash(runtimeType,seriesId,created,updated,removed,removedRsvps,canceled);
}

@override
String toString() {
    return 'SeriesResult(seriesId: $seriesId, created: $created, updated: $updated, removed: $removed, removedRsvps: $removedRsvps, canceled: $canceled)';
}


}

/// @nodoc
abstract mixin class _$SeriesResultCopyWith<$Res> implements $SeriesResultCopyWith<$Res> {
  factory _$SeriesResultCopyWith(_SeriesResult value, $Res Function(_SeriesResult) _then) = __$SeriesResultCopyWithImpl;
@override @useResult
$Res call({
 String? seriesId, int created, int updated, int removed, int removedRsvps, int canceled
});




}
/// @nodoc
class __$SeriesResultCopyWithImpl<$Res>
    implements _$SeriesResultCopyWith<$Res> {
  __$SeriesResultCopyWithImpl(this._self, this._then);

  final _SeriesResult _self;
  final $Res Function(_SeriesResult) _then;

/// Create a copy of SeriesResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seriesId = freezed,Object? created = null,Object? updated = null,Object? removed = null,Object? removedRsvps = null,Object? canceled = null,}) {
  return _then(_SeriesResult(
seriesId: freezed == seriesId ? _self.seriesId : seriesId // ignore: cast_nullable_to_non_nullable
as String?,created: null == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as int,updated: null == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as int,removed: null == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int,removedRsvps: null == removedRsvps ? _self.removedRsvps : removedRsvps // ignore: cast_nullable_to_non_nullable
as int,canceled: null == canceled ? _self.canceled : canceled // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
