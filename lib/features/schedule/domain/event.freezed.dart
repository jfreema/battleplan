// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Event {

 EventId get id; GroupId get groupId; EventType get type; String get title; DateTime get startAt; DateTime get endAt; String get timeZone; String get createdBy;/// The form's Notes; '' when none.
 String get description; EventLocation? get location; bool get allDay;/// 'YYYY-MM-DD', set only on all-day events. [endDate] is the last day.
 String? get startDate; String? get endDate;/// Games only (SCHED-3): "Arrive 30 min early".
 int? get arriveMinutesBefore; String? get opponent; HomeAway? get homeAway; bool get rsvpEnabled;/// 'players' on youth teams: guardians answer per player (PLAYER-6).
 RsvpFor get rsvpFor; DateTime? get rsvpDeadline;/// Minutes before the start, from [reminderOffsetsMinutes] (SCHED-8).
 List<int> get reminderOffsets; bool get notifyTeam; bool get postToChat;/// Set by Functions on events of a repeating series (SCHED-6).
 String? get seriesId;/// The occurrence's date in [timeZone], 'YYYY-MM-DD'.
 String? get seriesDate;/// Fields edited with "This event"; later series edits leave them be.
 List<String> get seriesOverrides;/// Kept by the server from the RSVPs. On 'players' events these count
/// players only; [staffCounts] counts the admins' own answers (D34).
 RsvpCounts get rsvpCounts; RsvpCounts get staffCounts;/// Set once when canceled (SCHED-7); never cleared.
 DateTime? get canceledAt; String? get canceledBy; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventCopyWith<Event> get copyWith => _$EventCopyWithImpl<Event>(this as Event, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Event;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Event&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.startAt, _this.startAt) || other.startAt == _this.startAt)&&(identical(other.endAt, _this.endAt) || other.endAt == _this.endAt)&&(identical(other.timeZone, _this.timeZone) || other.timeZone == _this.timeZone)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.allDay, _this.allDay) || other.allDay == _this.allDay)&&(identical(other.startDate, _this.startDate) || other.startDate == _this.startDate)&&(identical(other.endDate, _this.endDate) || other.endDate == _this.endDate)&&(identical(other.arriveMinutesBefore, _this.arriveMinutesBefore) || other.arriveMinutesBefore == _this.arriveMinutesBefore)&&(identical(other.opponent, _this.opponent) || other.opponent == _this.opponent)&&(identical(other.homeAway, _this.homeAway) || other.homeAway == _this.homeAway)&&(identical(other.rsvpEnabled, _this.rsvpEnabled) || other.rsvpEnabled == _this.rsvpEnabled)&&(identical(other.rsvpFor, _this.rsvpFor) || other.rsvpFor == _this.rsvpFor)&&(identical(other.rsvpDeadline, _this.rsvpDeadline) || other.rsvpDeadline == _this.rsvpDeadline)&&const DeepCollectionEquality().equals(other.reminderOffsets, _this.reminderOffsets)&&(identical(other.notifyTeam, _this.notifyTeam) || other.notifyTeam == _this.notifyTeam)&&(identical(other.postToChat, _this.postToChat) || other.postToChat == _this.postToChat)&&(identical(other.seriesId, _this.seriesId) || other.seriesId == _this.seriesId)&&(identical(other.seriesDate, _this.seriesDate) || other.seriesDate == _this.seriesDate)&&const DeepCollectionEquality().equals(other.seriesOverrides, _this.seriesOverrides)&&(identical(other.rsvpCounts, _this.rsvpCounts) || other.rsvpCounts == _this.rsvpCounts)&&(identical(other.staffCounts, _this.staffCounts) || other.staffCounts == _this.staffCounts)&&(identical(other.canceledAt, _this.canceledAt) || other.canceledAt == _this.canceledAt)&&(identical(other.canceledBy, _this.canceledBy) || other.canceledBy == _this.canceledBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}


@override
int get hashCode {
  final _this = this as Event;
  return Object.hashAll([runtimeType,_this.id,_this.groupId,_this.type,_this.title,_this.startAt,_this.endAt,_this.timeZone,_this.createdBy,_this.description,_this.location,_this.allDay,_this.startDate,_this.endDate,_this.arriveMinutesBefore,_this.opponent,_this.homeAway,_this.rsvpEnabled,_this.rsvpFor,_this.rsvpDeadline,const DeepCollectionEquality().hash(_this.reminderOffsets),_this.notifyTeam,_this.postToChat,_this.seriesId,_this.seriesDate,const DeepCollectionEquality().hash(_this.seriesOverrides),_this.rsvpCounts,_this.staffCounts,_this.canceledAt,_this.canceledBy,_this.createdAt,_this.updatedAt]);
}

@override
String toString() {
  final _this = this as Event;
  return 'Event(id: ${_this.id}, groupId: ${_this.groupId}, type: ${_this.type}, title: ${_this.title}, startAt: ${_this.startAt}, endAt: ${_this.endAt}, timeZone: ${_this.timeZone}, createdBy: ${_this.createdBy}, description: ${_this.description}, location: ${_this.location}, allDay: ${_this.allDay}, startDate: ${_this.startDate}, endDate: ${_this.endDate}, arriveMinutesBefore: ${_this.arriveMinutesBefore}, opponent: ${_this.opponent}, homeAway: ${_this.homeAway}, rsvpEnabled: ${_this.rsvpEnabled}, rsvpFor: ${_this.rsvpFor}, rsvpDeadline: ${_this.rsvpDeadline}, reminderOffsets: ${_this.reminderOffsets}, notifyTeam: ${_this.notifyTeam}, postToChat: ${_this.postToChat}, seriesId: ${_this.seriesId}, seriesDate: ${_this.seriesDate}, seriesOverrides: ${_this.seriesOverrides}, rsvpCounts: ${_this.rsvpCounts}, staffCounts: ${_this.staffCounts}, canceledAt: ${_this.canceledAt}, canceledBy: ${_this.canceledBy}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $EventCopyWith<$Res>  {
  factory $EventCopyWith(Event value, $Res Function(Event) _then) = _$EventCopyWithImpl;
@useResult
$Res call({
 EventId id, GroupId groupId, EventType type, String title, DateTime startAt, DateTime endAt, String timeZone, String createdBy, String description, EventLocation? location, bool allDay, String? startDate, String? endDate, int? arriveMinutesBefore, String? opponent, HomeAway? homeAway, bool rsvpEnabled, RsvpFor rsvpFor, DateTime? rsvpDeadline, List<int> reminderOffsets, bool notifyTeam, bool postToChat, String? seriesId, String? seriesDate, List<String> seriesOverrides, RsvpCounts rsvpCounts, RsvpCounts staffCounts, DateTime? canceledAt, String? canceledBy, DateTime? createdAt, DateTime? updatedAt
});


$EventLocationCopyWith<$Res>? get location;$RsvpCountsCopyWith<$Res> get rsvpCounts;$RsvpCountsCopyWith<$Res> get staffCounts;

}
/// @nodoc
class _$EventCopyWithImpl<$Res>
    implements $EventCopyWith<$Res> {
  _$EventCopyWithImpl(this._self, this._then);

  final Event _self;
  final $Res Function(Event) _then;

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? groupId = null,Object? type = null,Object? title = null,Object? startAt = null,Object? endAt = null,Object? timeZone = null,Object? createdBy = null,Object? description = null,Object? location = freezed,Object? allDay = null,Object? startDate = freezed,Object? endDate = freezed,Object? arriveMinutesBefore = freezed,Object? opponent = freezed,Object? homeAway = freezed,Object? rsvpEnabled = null,Object? rsvpFor = null,Object? rsvpDeadline = freezed,Object? reminderOffsets = null,Object? notifyTeam = null,Object? postToChat = null,Object? seriesId = freezed,Object? seriesDate = freezed,Object? seriesOverrides = null,Object? rsvpCounts = null,Object? staffCounts = null,Object? canceledAt = freezed,Object? canceledBy = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(Event(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as EventId,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as EventType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,startAt: null == startAt ? _self.startAt : startAt // ignore: cast_nullable_to_non_nullable
as DateTime,endAt: null == endAt ? _self.endAt : endAt // ignore: cast_nullable_to_non_nullable
as DateTime,timeZone: null == timeZone ? _self.timeZone : timeZone // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as EventLocation?,allDay: null == allDay ? _self.allDay : allDay // ignore: cast_nullable_to_non_nullable
as bool,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,arriveMinutesBefore: freezed == arriveMinutesBefore ? _self.arriveMinutesBefore : arriveMinutesBefore // ignore: cast_nullable_to_non_nullable
as int?,opponent: freezed == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as String?,homeAway: freezed == homeAway ? _self.homeAway : homeAway // ignore: cast_nullable_to_non_nullable
as HomeAway?,rsvpEnabled: null == rsvpEnabled ? _self.rsvpEnabled : rsvpEnabled // ignore: cast_nullable_to_non_nullable
as bool,rsvpFor: null == rsvpFor ? _self.rsvpFor : rsvpFor // ignore: cast_nullable_to_non_nullable
as RsvpFor,rsvpDeadline: freezed == rsvpDeadline ? _self.rsvpDeadline : rsvpDeadline // ignore: cast_nullable_to_non_nullable
as DateTime?,reminderOffsets: null == reminderOffsets ? _self.reminderOffsets : reminderOffsets // ignore: cast_nullable_to_non_nullable
as List<int>,notifyTeam: null == notifyTeam ? _self.notifyTeam : notifyTeam // ignore: cast_nullable_to_non_nullable
as bool,postToChat: null == postToChat ? _self.postToChat : postToChat // ignore: cast_nullable_to_non_nullable
as bool,seriesId: freezed == seriesId ? _self.seriesId : seriesId // ignore: cast_nullable_to_non_nullable
as String?,seriesDate: freezed == seriesDate ? _self.seriesDate : seriesDate // ignore: cast_nullable_to_non_nullable
as String?,seriesOverrides: null == seriesOverrides ? _self.seriesOverrides : seriesOverrides // ignore: cast_nullable_to_non_nullable
as List<String>,rsvpCounts: null == rsvpCounts ? _self.rsvpCounts : rsvpCounts // ignore: cast_nullable_to_non_nullable
as RsvpCounts,staffCounts: null == staffCounts ? _self.staffCounts : staffCounts // ignore: cast_nullable_to_non_nullable
as RsvpCounts,canceledAt: freezed == canceledAt ? _self.canceledAt : canceledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,canceledBy: freezed == canceledBy ? _self.canceledBy : canceledBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EventLocationCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $EventLocationCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RsvpCountsCopyWith<$Res> get rsvpCounts {
  
  return $RsvpCountsCopyWith<$Res>(_self.rsvpCounts, (value) {
    return _then(_self.copyWith(rsvpCounts: value));
  });
}/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RsvpCountsCopyWith<$Res> get staffCounts {
  
  return $RsvpCountsCopyWith<$Res>(_self.staffCounts, (value) {
    return _then(_self.copyWith(staffCounts: value));
  });
}
}


/// Adds pattern-matching-related methods to [Event].
extension EventPatterns on Event {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Event value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Event() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Event value)  $default,){
final _that = this;
switch (_that) {
case _Event():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Event value)?  $default,){
final _that = this;
switch (_that) {
case _Event() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EventId id,  GroupId groupId,  EventType type,  String title,  DateTime startAt,  DateTime endAt,  String timeZone,  String createdBy,  String description,  EventLocation? location,  bool allDay,  String? startDate,  String? endDate,  int? arriveMinutesBefore,  String? opponent,  HomeAway? homeAway,  bool rsvpEnabled,  RsvpFor rsvpFor,  DateTime? rsvpDeadline,  List<int> reminderOffsets,  bool notifyTeam,  bool postToChat,  String? seriesId,  String? seriesDate,  List<String> seriesOverrides,  RsvpCounts rsvpCounts,  RsvpCounts staffCounts,  DateTime? canceledAt,  String? canceledBy,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Event() when $default != null:
return $default(_that.id,_that.groupId,_that.type,_that.title,_that.startAt,_that.endAt,_that.timeZone,_that.createdBy,_that.description,_that.location,_that.allDay,_that.startDate,_that.endDate,_that.arriveMinutesBefore,_that.opponent,_that.homeAway,_that.rsvpEnabled,_that.rsvpFor,_that.rsvpDeadline,_that.reminderOffsets,_that.notifyTeam,_that.postToChat,_that.seriesId,_that.seriesDate,_that.seriesOverrides,_that.rsvpCounts,_that.staffCounts,_that.canceledAt,_that.canceledBy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EventId id,  GroupId groupId,  EventType type,  String title,  DateTime startAt,  DateTime endAt,  String timeZone,  String createdBy,  String description,  EventLocation? location,  bool allDay,  String? startDate,  String? endDate,  int? arriveMinutesBefore,  String? opponent,  HomeAway? homeAway,  bool rsvpEnabled,  RsvpFor rsvpFor,  DateTime? rsvpDeadline,  List<int> reminderOffsets,  bool notifyTeam,  bool postToChat,  String? seriesId,  String? seriesDate,  List<String> seriesOverrides,  RsvpCounts rsvpCounts,  RsvpCounts staffCounts,  DateTime? canceledAt,  String? canceledBy,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Event():
return $default(_that.id,_that.groupId,_that.type,_that.title,_that.startAt,_that.endAt,_that.timeZone,_that.createdBy,_that.description,_that.location,_that.allDay,_that.startDate,_that.endDate,_that.arriveMinutesBefore,_that.opponent,_that.homeAway,_that.rsvpEnabled,_that.rsvpFor,_that.rsvpDeadline,_that.reminderOffsets,_that.notifyTeam,_that.postToChat,_that.seriesId,_that.seriesDate,_that.seriesOverrides,_that.rsvpCounts,_that.staffCounts,_that.canceledAt,_that.canceledBy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EventId id,  GroupId groupId,  EventType type,  String title,  DateTime startAt,  DateTime endAt,  String timeZone,  String createdBy,  String description,  EventLocation? location,  bool allDay,  String? startDate,  String? endDate,  int? arriveMinutesBefore,  String? opponent,  HomeAway? homeAway,  bool rsvpEnabled,  RsvpFor rsvpFor,  DateTime? rsvpDeadline,  List<int> reminderOffsets,  bool notifyTeam,  bool postToChat,  String? seriesId,  String? seriesDate,  List<String> seriesOverrides,  RsvpCounts rsvpCounts,  RsvpCounts staffCounts,  DateTime? canceledAt,  String? canceledBy,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Event() when $default != null:
return $default(_that.id,_that.groupId,_that.type,_that.title,_that.startAt,_that.endAt,_that.timeZone,_that.createdBy,_that.description,_that.location,_that.allDay,_that.startDate,_that.endDate,_that.arriveMinutesBefore,_that.opponent,_that.homeAway,_that.rsvpEnabled,_that.rsvpFor,_that.rsvpDeadline,_that.reminderOffsets,_that.notifyTeam,_that.postToChat,_that.seriesId,_that.seriesDate,_that.seriesOverrides,_that.rsvpCounts,_that.staffCounts,_that.canceledAt,_that.canceledBy,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Event extends Event {
  const _Event({required this.id, required this.groupId, required this.type, required this.title, required this.startAt, required this.endAt, required this.timeZone, required this.createdBy, this.description = '', this.location, this.allDay = false, this.startDate, this.endDate, this.arriveMinutesBefore, this.opponent, this.homeAway, this.rsvpEnabled = true, this.rsvpFor = RsvpFor.members, this.rsvpDeadline,  List<int> reminderOffsets = const <int>[], this.notifyTeam = true, this.postToChat = true, this.seriesId, this.seriesDate,  List<String> seriesOverrides = const <String>[], this.rsvpCounts = const RsvpCounts(), this.staffCounts = const RsvpCounts(), this.canceledAt, this.canceledBy, this.createdAt, this.updatedAt}): _reminderOffsets = reminderOffsets,_seriesOverrides = seriesOverrides,super._();
  

@override final  EventId id;
@override final  GroupId groupId;
@override final  EventType type;
@override final  String title;
@override final  DateTime startAt;
@override final  DateTime endAt;
@override final  String timeZone;
@override final  String createdBy;
/// The form's Notes; '' when none.
@override@JsonKey() final  String description;
@override final  EventLocation? location;
@override@JsonKey() final  bool allDay;
/// 'YYYY-MM-DD', set only on all-day events. [endDate] is the last day.
@override final  String? startDate;
@override final  String? endDate;
/// Games only (SCHED-3): "Arrive 30 min early".
@override final  int? arriveMinutesBefore;
@override final  String? opponent;
@override final  HomeAway? homeAway;
@override@JsonKey() final  bool rsvpEnabled;
/// 'players' on youth teams: guardians answer per player (PLAYER-6).
@override@JsonKey() final  RsvpFor rsvpFor;
@override final  DateTime? rsvpDeadline;
/// Minutes before the start, from [reminderOffsetsMinutes] (SCHED-8).
 final  List<int> _reminderOffsets;
/// Minutes before the start, from [reminderOffsetsMinutes] (SCHED-8).
@override@JsonKey() List<int> get reminderOffsets {
  if (_reminderOffsets is EqualUnmodifiableListView) return _reminderOffsets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reminderOffsets);
}

@override@JsonKey() final  bool notifyTeam;
@override@JsonKey() final  bool postToChat;
/// Set by Functions on events of a repeating series (SCHED-6).
@override final  String? seriesId;
/// The occurrence's date in [timeZone], 'YYYY-MM-DD'.
@override final  String? seriesDate;
/// Fields edited with "This event"; later series edits leave them be.
 final  List<String> _seriesOverrides;
/// Fields edited with "This event"; later series edits leave them be.
@override@JsonKey() List<String> get seriesOverrides {
  if (_seriesOverrides is EqualUnmodifiableListView) return _seriesOverrides;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_seriesOverrides);
}

/// Kept by the server from the RSVPs. On 'players' events these count
/// players only; [staffCounts] counts the admins' own answers (D34).
@override@JsonKey() final  RsvpCounts rsvpCounts;
@override@JsonKey() final  RsvpCounts staffCounts;
/// Set once when canceled (SCHED-7); never cleared.
@override final  DateTime? canceledAt;
@override final  String? canceledBy;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventCopyWith<_Event> get copyWith => __$EventCopyWithImpl<_Event>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Event&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.startAt, startAt) || other.startAt == startAt)&&(identical(other.endAt, endAt) || other.endAt == endAt)&&(identical(other.timeZone, timeZone) || other.timeZone == timeZone)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.description, description) || other.description == description)&&(identical(other.location, location) || other.location == location)&&(identical(other.allDay, allDay) || other.allDay == allDay)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.arriveMinutesBefore, arriveMinutesBefore) || other.arriveMinutesBefore == arriveMinutesBefore)&&(identical(other.opponent, opponent) || other.opponent == opponent)&&(identical(other.homeAway, homeAway) || other.homeAway == homeAway)&&(identical(other.rsvpEnabled, rsvpEnabled) || other.rsvpEnabled == rsvpEnabled)&&(identical(other.rsvpFor, rsvpFor) || other.rsvpFor == rsvpFor)&&(identical(other.rsvpDeadline, rsvpDeadline) || other.rsvpDeadline == rsvpDeadline)&&const DeepCollectionEquality().equals(other.reminderOffsets, _reminderOffsets)&&(identical(other.notifyTeam, notifyTeam) || other.notifyTeam == notifyTeam)&&(identical(other.postToChat, postToChat) || other.postToChat == postToChat)&&(identical(other.seriesId, seriesId) || other.seriesId == seriesId)&&(identical(other.seriesDate, seriesDate) || other.seriesDate == seriesDate)&&const DeepCollectionEquality().equals(other.seriesOverrides, _seriesOverrides)&&(identical(other.rsvpCounts, rsvpCounts) || other.rsvpCounts == rsvpCounts)&&(identical(other.staffCounts, staffCounts) || other.staffCounts == staffCounts)&&(identical(other.canceledAt, canceledAt) || other.canceledAt == canceledAt)&&(identical(other.canceledBy, canceledBy) || other.canceledBy == canceledBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,id,groupId,type,title,startAt,endAt,timeZone,createdBy,description,location,allDay,startDate,endDate,arriveMinutesBefore,opponent,homeAway,rsvpEnabled,rsvpFor,rsvpDeadline,const DeepCollectionEquality().hash(_reminderOffsets),notifyTeam,postToChat,seriesId,seriesDate,const DeepCollectionEquality().hash(_seriesOverrides),rsvpCounts,staffCounts,canceledAt,canceledBy,createdAt,updatedAt]);
}

@override
String toString() {
    return 'Event(id: $id, groupId: $groupId, type: $type, title: $title, startAt: $startAt, endAt: $endAt, timeZone: $timeZone, createdBy: $createdBy, description: $description, location: $location, allDay: $allDay, startDate: $startDate, endDate: $endDate, arriveMinutesBefore: $arriveMinutesBefore, opponent: $opponent, homeAway: $homeAway, rsvpEnabled: $rsvpEnabled, rsvpFor: $rsvpFor, rsvpDeadline: $rsvpDeadline, reminderOffsets: $reminderOffsets, notifyTeam: $notifyTeam, postToChat: $postToChat, seriesId: $seriesId, seriesDate: $seriesDate, seriesOverrides: $seriesOverrides, rsvpCounts: $rsvpCounts, staffCounts: $staffCounts, canceledAt: $canceledAt, canceledBy: $canceledBy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$EventCopyWith<$Res> implements $EventCopyWith<$Res> {
  factory _$EventCopyWith(_Event value, $Res Function(_Event) _then) = __$EventCopyWithImpl;
@override @useResult
$Res call({
 EventId id, GroupId groupId, EventType type, String title, DateTime startAt, DateTime endAt, String timeZone, String createdBy, String description, EventLocation? location, bool allDay, String? startDate, String? endDate, int? arriveMinutesBefore, String? opponent, HomeAway? homeAway, bool rsvpEnabled, RsvpFor rsvpFor, DateTime? rsvpDeadline, List<int> reminderOffsets, bool notifyTeam, bool postToChat, String? seriesId, String? seriesDate, List<String> seriesOverrides, RsvpCounts rsvpCounts, RsvpCounts staffCounts, DateTime? canceledAt, String? canceledBy, DateTime? createdAt, DateTime? updatedAt
});


@override $EventLocationCopyWith<$Res>? get location;@override $RsvpCountsCopyWith<$Res> get rsvpCounts;@override $RsvpCountsCopyWith<$Res> get staffCounts;

}
/// @nodoc
class __$EventCopyWithImpl<$Res>
    implements _$EventCopyWith<$Res> {
  __$EventCopyWithImpl(this._self, this._then);

  final _Event _self;
  final $Res Function(_Event) _then;

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? groupId = null,Object? type = null,Object? title = null,Object? startAt = null,Object? endAt = null,Object? timeZone = null,Object? createdBy = null,Object? description = null,Object? location = freezed,Object? allDay = null,Object? startDate = freezed,Object? endDate = freezed,Object? arriveMinutesBefore = freezed,Object? opponent = freezed,Object? homeAway = freezed,Object? rsvpEnabled = null,Object? rsvpFor = null,Object? rsvpDeadline = freezed,Object? reminderOffsets = null,Object? notifyTeam = null,Object? postToChat = null,Object? seriesId = freezed,Object? seriesDate = freezed,Object? seriesOverrides = null,Object? rsvpCounts = null,Object? staffCounts = null,Object? canceledAt = freezed,Object? canceledBy = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Event(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as EventId,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as EventType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,startAt: null == startAt ? _self.startAt : startAt // ignore: cast_nullable_to_non_nullable
as DateTime,endAt: null == endAt ? _self.endAt : endAt // ignore: cast_nullable_to_non_nullable
as DateTime,timeZone: null == timeZone ? _self.timeZone : timeZone // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as EventLocation?,allDay: null == allDay ? _self.allDay : allDay // ignore: cast_nullable_to_non_nullable
as bool,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,arriveMinutesBefore: freezed == arriveMinutesBefore ? _self.arriveMinutesBefore : arriveMinutesBefore // ignore: cast_nullable_to_non_nullable
as int?,opponent: freezed == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as String?,homeAway: freezed == homeAway ? _self.homeAway : homeAway // ignore: cast_nullable_to_non_nullable
as HomeAway?,rsvpEnabled: null == rsvpEnabled ? _self.rsvpEnabled : rsvpEnabled // ignore: cast_nullable_to_non_nullable
as bool,rsvpFor: null == rsvpFor ? _self.rsvpFor : rsvpFor // ignore: cast_nullable_to_non_nullable
as RsvpFor,rsvpDeadline: freezed == rsvpDeadline ? _self.rsvpDeadline : rsvpDeadline // ignore: cast_nullable_to_non_nullable
as DateTime?,reminderOffsets: null == reminderOffsets ? _self._reminderOffsets : reminderOffsets // ignore: cast_nullable_to_non_nullable
as List<int>,notifyTeam: null == notifyTeam ? _self.notifyTeam : notifyTeam // ignore: cast_nullable_to_non_nullable
as bool,postToChat: null == postToChat ? _self.postToChat : postToChat // ignore: cast_nullable_to_non_nullable
as bool,seriesId: freezed == seriesId ? _self.seriesId : seriesId // ignore: cast_nullable_to_non_nullable
as String?,seriesDate: freezed == seriesDate ? _self.seriesDate : seriesDate // ignore: cast_nullable_to_non_nullable
as String?,seriesOverrides: null == seriesOverrides ? _self._seriesOverrides : seriesOverrides // ignore: cast_nullable_to_non_nullable
as List<String>,rsvpCounts: null == rsvpCounts ? _self.rsvpCounts : rsvpCounts // ignore: cast_nullable_to_non_nullable
as RsvpCounts,staffCounts: null == staffCounts ? _self.staffCounts : staffCounts // ignore: cast_nullable_to_non_nullable
as RsvpCounts,canceledAt: freezed == canceledAt ? _self.canceledAt : canceledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,canceledBy: freezed == canceledBy ? _self.canceledBy : canceledBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EventLocationCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $EventLocationCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RsvpCountsCopyWith<$Res> get rsvpCounts {
  
  return $RsvpCountsCopyWith<$Res>(_self.rsvpCounts, (value) {
    return _then(_self.copyWith(rsvpCounts: value));
  });
}/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RsvpCountsCopyWith<$Res> get staffCounts {
  
  return $RsvpCountsCopyWith<$Res>(_self.staffCounts, (value) {
    return _then(_self.copyWith(staffCounts: value));
  });
}
}

/// @nodoc
mixin _$EventLocation {

 String get name; String get address;
/// Create a copy of EventLocation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventLocationCopyWith<EventLocation> get copyWith => _$EventLocationCopyWithImpl<EventLocation>(this as EventLocation, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EventLocation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventLocation&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.address, _this.address) || other.address == _this.address));
}


@override
int get hashCode {
  final _this = this as EventLocation;
  return Object.hash(runtimeType,_this.name,_this.address);
}

@override
String toString() {
  final _this = this as EventLocation;
  return 'EventLocation(name: ${_this.name}, address: ${_this.address})';
}


}

/// @nodoc
abstract mixin class $EventLocationCopyWith<$Res>  {
  factory $EventLocationCopyWith(EventLocation value, $Res Function(EventLocation) _then) = _$EventLocationCopyWithImpl;
@useResult
$Res call({
 String name, String address
});




}
/// @nodoc
class _$EventLocationCopyWithImpl<$Res>
    implements $EventLocationCopyWith<$Res> {
  _$EventLocationCopyWithImpl(this._self, this._then);

  final EventLocation _self;
  final $Res Function(EventLocation) _then;

/// Create a copy of EventLocation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? address = null,}) {
  return _then(EventLocation(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [EventLocation].
extension EventLocationPatterns on EventLocation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventLocation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventLocation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventLocation value)  $default,){
final _that = this;
switch (_that) {
case _EventLocation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventLocation value)?  $default,){
final _that = this;
switch (_that) {
case _EventLocation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String address)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventLocation() when $default != null:
return $default(_that.name,_that.address);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String address)  $default,) {final _that = this;
switch (_that) {
case _EventLocation():
return $default(_that.name,_that.address);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String address)?  $default,) {final _that = this;
switch (_that) {
case _EventLocation() when $default != null:
return $default(_that.name,_that.address);case _:
  return null;

}
}

}

/// @nodoc


class _EventLocation extends EventLocation {
  const _EventLocation({this.name = '', this.address = ''}): super._();
  

@override@JsonKey() final  String name;
@override@JsonKey() final  String address;

/// Create a copy of EventLocation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventLocationCopyWith<_EventLocation> get copyWith => __$EventLocationCopyWithImpl<_EventLocation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventLocation&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,address);
}

@override
String toString() {
    return 'EventLocation(name: $name, address: $address)';
}


}

/// @nodoc
abstract mixin class _$EventLocationCopyWith<$Res> implements $EventLocationCopyWith<$Res> {
  factory _$EventLocationCopyWith(_EventLocation value, $Res Function(_EventLocation) _then) = __$EventLocationCopyWithImpl;
@override @useResult
$Res call({
 String name, String address
});




}
/// @nodoc
class __$EventLocationCopyWithImpl<$Res>
    implements _$EventLocationCopyWith<$Res> {
  __$EventLocationCopyWithImpl(this._self, this._then);

  final _EventLocation _self;
  final $Res Function(_EventLocation) _then;

/// Create a copy of EventLocation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? address = null,}) {
  return _then(_EventLocation(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$RsvpCounts {

 int get going; int get maybe; int get notGoing;
/// Create a copy of RsvpCounts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RsvpCountsCopyWith<RsvpCounts> get copyWith => _$RsvpCountsCopyWithImpl<RsvpCounts>(this as RsvpCounts, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RsvpCounts;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RsvpCounts&&(identical(other.going, _this.going) || other.going == _this.going)&&(identical(other.maybe, _this.maybe) || other.maybe == _this.maybe)&&(identical(other.notGoing, _this.notGoing) || other.notGoing == _this.notGoing));
}


@override
int get hashCode {
  final _this = this as RsvpCounts;
  return Object.hash(runtimeType,_this.going,_this.maybe,_this.notGoing);
}

@override
String toString() {
  final _this = this as RsvpCounts;
  return 'RsvpCounts(going: ${_this.going}, maybe: ${_this.maybe}, notGoing: ${_this.notGoing})';
}


}

/// @nodoc
abstract mixin class $RsvpCountsCopyWith<$Res>  {
  factory $RsvpCountsCopyWith(RsvpCounts value, $Res Function(RsvpCounts) _then) = _$RsvpCountsCopyWithImpl;
@useResult
$Res call({
 int going, int maybe, int notGoing
});




}
/// @nodoc
class _$RsvpCountsCopyWithImpl<$Res>
    implements $RsvpCountsCopyWith<$Res> {
  _$RsvpCountsCopyWithImpl(this._self, this._then);

  final RsvpCounts _self;
  final $Res Function(RsvpCounts) _then;

/// Create a copy of RsvpCounts
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? going = null,Object? maybe = null,Object? notGoing = null,}) {
  return _then(RsvpCounts(
going: null == going ? _self.going : going // ignore: cast_nullable_to_non_nullable
as int,maybe: null == maybe ? _self.maybe : maybe // ignore: cast_nullable_to_non_nullable
as int,notGoing: null == notGoing ? _self.notGoing : notGoing // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RsvpCounts].
extension RsvpCountsPatterns on RsvpCounts {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RsvpCounts value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RsvpCounts() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RsvpCounts value)  $default,){
final _that = this;
switch (_that) {
case _RsvpCounts():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RsvpCounts value)?  $default,){
final _that = this;
switch (_that) {
case _RsvpCounts() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int going,  int maybe,  int notGoing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RsvpCounts() when $default != null:
return $default(_that.going,_that.maybe,_that.notGoing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int going,  int maybe,  int notGoing)  $default,) {final _that = this;
switch (_that) {
case _RsvpCounts():
return $default(_that.going,_that.maybe,_that.notGoing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int going,  int maybe,  int notGoing)?  $default,) {final _that = this;
switch (_that) {
case _RsvpCounts() when $default != null:
return $default(_that.going,_that.maybe,_that.notGoing);case _:
  return null;

}
}

}

/// @nodoc


class _RsvpCounts extends RsvpCounts {
  const _RsvpCounts({this.going = 0, this.maybe = 0, this.notGoing = 0}): super._();
  

@override@JsonKey() final  int going;
@override@JsonKey() final  int maybe;
@override@JsonKey() final  int notGoing;

/// Create a copy of RsvpCounts
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RsvpCountsCopyWith<_RsvpCounts> get copyWith => __$RsvpCountsCopyWithImpl<_RsvpCounts>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RsvpCounts&&(identical(other.going, going) || other.going == going)&&(identical(other.maybe, maybe) || other.maybe == maybe)&&(identical(other.notGoing, notGoing) || other.notGoing == notGoing));
}


@override
int get hashCode {
    return Object.hash(runtimeType,going,maybe,notGoing);
}

@override
String toString() {
    return 'RsvpCounts(going: $going, maybe: $maybe, notGoing: $notGoing)';
}


}

/// @nodoc
abstract mixin class _$RsvpCountsCopyWith<$Res> implements $RsvpCountsCopyWith<$Res> {
  factory _$RsvpCountsCopyWith(_RsvpCounts value, $Res Function(_RsvpCounts) _then) = __$RsvpCountsCopyWithImpl;
@override @useResult
$Res call({
 int going, int maybe, int notGoing
});




}
/// @nodoc
class __$RsvpCountsCopyWithImpl<$Res>
    implements _$RsvpCountsCopyWith<$Res> {
  __$RsvpCountsCopyWithImpl(this._self, this._then);

  final _RsvpCounts _self;
  final $Res Function(_RsvpCounts) _then;

/// Create a copy of RsvpCounts
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? going = null,Object? maybe = null,Object? notGoing = null,}) {
  return _then(_RsvpCounts(
going: null == going ? _self.going : going // ignore: cast_nullable_to_non_nullable
as int,maybe: null == maybe ? _self.maybe : maybe // ignore: cast_nullable_to_non_nullable
as int,notGoing: null == notGoing ? _self.notGoing : notGoing // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
