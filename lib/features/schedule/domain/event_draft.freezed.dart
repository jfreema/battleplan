// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EventDraft {

 String get timeZone; EventType get type;/// Left blank on a game, it becomes "vs. Opponent" (see [effectiveTitle]).
 String get title; String get description; String get locationName; String get locationAddress; bool get allDay;/// Empty on a duplicate until picked (SCHED-3 Duplicate).
 DateTime? get date;/// An all-day event's last day; null means the same day as [date].
 DateTime? get endDate; int get startMinutes; int get endMinutes; String get opponent; HomeAway? get homeAway; int? get arriveMinutesBefore; bool get rsvpEnabled;/// A deadline picked as a day and time. See [deadline].
 DateTime? get rsvpDeadline;/// On a duplicate, the original's deadline as days before the start
/// at a time of day in [timeZone]: it lands as far before the copy's
/// date once one is picked (SCHED-3 copies the RSVP settings).
 int? get deadlineDaysBefore; int? get deadlineMinutes; List<int> get reminderOffsets; bool get notifyTeam; bool get postToChat;/// Null: doesn't repeat (the default).
 RepeatRule? get repeat;/// On a "This and following" edit, the edited event's series date: the
/// new rule starts there, as the server starts it, even when the event
/// was moved to another day (SCHED-6).
 String? get seriesFrom;/// On a "This and following" edit, how many of the old series' events
/// fall before [seriesFrom]. A rule that ends after N events counts
/// the whole series, so the server leaves these out (SCHED-6).
 int get countBefore;
/// Create a copy of EventDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventDraftCopyWith<EventDraft> get copyWith => _$EventDraftCopyWithImpl<EventDraft>(this as EventDraft, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EventDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventDraft&&(identical(other.timeZone, _this.timeZone) || other.timeZone == _this.timeZone)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.locationName, _this.locationName) || other.locationName == _this.locationName)&&(identical(other.locationAddress, _this.locationAddress) || other.locationAddress == _this.locationAddress)&&(identical(other.allDay, _this.allDay) || other.allDay == _this.allDay)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.endDate, _this.endDate) || other.endDate == _this.endDate)&&(identical(other.startMinutes, _this.startMinutes) || other.startMinutes == _this.startMinutes)&&(identical(other.endMinutes, _this.endMinutes) || other.endMinutes == _this.endMinutes)&&(identical(other.opponent, _this.opponent) || other.opponent == _this.opponent)&&(identical(other.homeAway, _this.homeAway) || other.homeAway == _this.homeAway)&&(identical(other.arriveMinutesBefore, _this.arriveMinutesBefore) || other.arriveMinutesBefore == _this.arriveMinutesBefore)&&(identical(other.rsvpEnabled, _this.rsvpEnabled) || other.rsvpEnabled == _this.rsvpEnabled)&&(identical(other.rsvpDeadline, _this.rsvpDeadline) || other.rsvpDeadline == _this.rsvpDeadline)&&(identical(other.deadlineDaysBefore, _this.deadlineDaysBefore) || other.deadlineDaysBefore == _this.deadlineDaysBefore)&&(identical(other.deadlineMinutes, _this.deadlineMinutes) || other.deadlineMinutes == _this.deadlineMinutes)&&const DeepCollectionEquality().equals(other.reminderOffsets, _this.reminderOffsets)&&(identical(other.notifyTeam, _this.notifyTeam) || other.notifyTeam == _this.notifyTeam)&&(identical(other.postToChat, _this.postToChat) || other.postToChat == _this.postToChat)&&(identical(other.repeat, _this.repeat) || other.repeat == _this.repeat)&&(identical(other.seriesFrom, _this.seriesFrom) || other.seriesFrom == _this.seriesFrom)&&(identical(other.countBefore, _this.countBefore) || other.countBefore == _this.countBefore));
}


@override
int get hashCode {
  final _this = this as EventDraft;
  return Object.hashAll([runtimeType,_this.timeZone,_this.type,_this.title,_this.description,_this.locationName,_this.locationAddress,_this.allDay,_this.date,_this.endDate,_this.startMinutes,_this.endMinutes,_this.opponent,_this.homeAway,_this.arriveMinutesBefore,_this.rsvpEnabled,_this.rsvpDeadline,_this.deadlineDaysBefore,_this.deadlineMinutes,const DeepCollectionEquality().hash(_this.reminderOffsets),_this.notifyTeam,_this.postToChat,_this.repeat,_this.seriesFrom,_this.countBefore]);
}

@override
String toString() {
  final _this = this as EventDraft;
  return 'EventDraft(timeZone: ${_this.timeZone}, type: ${_this.type}, title: ${_this.title}, description: ${_this.description}, locationName: ${_this.locationName}, locationAddress: ${_this.locationAddress}, allDay: ${_this.allDay}, date: ${_this.date}, endDate: ${_this.endDate}, startMinutes: ${_this.startMinutes}, endMinutes: ${_this.endMinutes}, opponent: ${_this.opponent}, homeAway: ${_this.homeAway}, arriveMinutesBefore: ${_this.arriveMinutesBefore}, rsvpEnabled: ${_this.rsvpEnabled}, rsvpDeadline: ${_this.rsvpDeadline}, deadlineDaysBefore: ${_this.deadlineDaysBefore}, deadlineMinutes: ${_this.deadlineMinutes}, reminderOffsets: ${_this.reminderOffsets}, notifyTeam: ${_this.notifyTeam}, postToChat: ${_this.postToChat}, repeat: ${_this.repeat}, seriesFrom: ${_this.seriesFrom}, countBefore: ${_this.countBefore})';
}


}

/// @nodoc
abstract mixin class $EventDraftCopyWith<$Res>  {
  factory $EventDraftCopyWith(EventDraft value, $Res Function(EventDraft) _then) = _$EventDraftCopyWithImpl;
@useResult
$Res call({
 String timeZone, EventType type, String title, String description, String locationName, String locationAddress, bool allDay, DateTime? date, DateTime? endDate, int startMinutes, int endMinutes, String opponent, HomeAway? homeAway, int? arriveMinutesBefore, bool rsvpEnabled, DateTime? rsvpDeadline, int? deadlineDaysBefore, int? deadlineMinutes, List<int> reminderOffsets, bool notifyTeam, bool postToChat, RepeatRule? repeat, String? seriesFrom, int countBefore
});


$RepeatRuleCopyWith<$Res>? get repeat;

}
/// @nodoc
class _$EventDraftCopyWithImpl<$Res>
    implements $EventDraftCopyWith<$Res> {
  _$EventDraftCopyWithImpl(this._self, this._then);

  final EventDraft _self;
  final $Res Function(EventDraft) _then;

/// Create a copy of EventDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? timeZone = null,Object? type = null,Object? title = null,Object? description = null,Object? locationName = null,Object? locationAddress = null,Object? allDay = null,Object? date = freezed,Object? endDate = freezed,Object? startMinutes = null,Object? endMinutes = null,Object? opponent = null,Object? homeAway = freezed,Object? arriveMinutesBefore = freezed,Object? rsvpEnabled = null,Object? rsvpDeadline = freezed,Object? deadlineDaysBefore = freezed,Object? deadlineMinutes = freezed,Object? reminderOffsets = null,Object? notifyTeam = null,Object? postToChat = null,Object? repeat = freezed,Object? seriesFrom = freezed,Object? countBefore = null,}) {
  return _then(EventDraft(
timeZone: null == timeZone ? _self.timeZone : timeZone // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as EventType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,locationName: null == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String,locationAddress: null == locationAddress ? _self.locationAddress : locationAddress // ignore: cast_nullable_to_non_nullable
as String,allDay: null == allDay ? _self.allDay : allDay // ignore: cast_nullable_to_non_nullable
as bool,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,startMinutes: null == startMinutes ? _self.startMinutes : startMinutes // ignore: cast_nullable_to_non_nullable
as int,endMinutes: null == endMinutes ? _self.endMinutes : endMinutes // ignore: cast_nullable_to_non_nullable
as int,opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as String,homeAway: freezed == homeAway ? _self.homeAway : homeAway // ignore: cast_nullable_to_non_nullable
as HomeAway?,arriveMinutesBefore: freezed == arriveMinutesBefore ? _self.arriveMinutesBefore : arriveMinutesBefore // ignore: cast_nullable_to_non_nullable
as int?,rsvpEnabled: null == rsvpEnabled ? _self.rsvpEnabled : rsvpEnabled // ignore: cast_nullable_to_non_nullable
as bool,rsvpDeadline: freezed == rsvpDeadline ? _self.rsvpDeadline : rsvpDeadline // ignore: cast_nullable_to_non_nullable
as DateTime?,deadlineDaysBefore: freezed == deadlineDaysBefore ? _self.deadlineDaysBefore : deadlineDaysBefore // ignore: cast_nullable_to_non_nullable
as int?,deadlineMinutes: freezed == deadlineMinutes ? _self.deadlineMinutes : deadlineMinutes // ignore: cast_nullable_to_non_nullable
as int?,reminderOffsets: null == reminderOffsets ? _self.reminderOffsets : reminderOffsets // ignore: cast_nullable_to_non_nullable
as List<int>,notifyTeam: null == notifyTeam ? _self.notifyTeam : notifyTeam // ignore: cast_nullable_to_non_nullable
as bool,postToChat: null == postToChat ? _self.postToChat : postToChat // ignore: cast_nullable_to_non_nullable
as bool,repeat: freezed == repeat ? _self.repeat : repeat // ignore: cast_nullable_to_non_nullable
as RepeatRule?,seriesFrom: freezed == seriesFrom ? _self.seriesFrom : seriesFrom // ignore: cast_nullable_to_non_nullable
as String?,countBefore: null == countBefore ? _self.countBefore : countBefore // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of EventDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RepeatRuleCopyWith<$Res>? get repeat {
    if (_self.repeat == null) {
    return null;
  }

  return $RepeatRuleCopyWith<$Res>(_self.repeat!, (value) {
    return _then(_self.copyWith(repeat: value));
  });
}
}


/// Adds pattern-matching-related methods to [EventDraft].
extension EventDraftPatterns on EventDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventDraft value)  $default,){
final _that = this;
switch (_that) {
case _EventDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventDraft value)?  $default,){
final _that = this;
switch (_that) {
case _EventDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String timeZone,  EventType type,  String title,  String description,  String locationName,  String locationAddress,  bool allDay,  DateTime? date,  DateTime? endDate,  int startMinutes,  int endMinutes,  String opponent,  HomeAway? homeAway,  int? arriveMinutesBefore,  bool rsvpEnabled,  DateTime? rsvpDeadline,  int? deadlineDaysBefore,  int? deadlineMinutes,  List<int> reminderOffsets,  bool notifyTeam,  bool postToChat,  RepeatRule? repeat,  String? seriesFrom,  int countBefore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventDraft() when $default != null:
return $default(_that.timeZone,_that.type,_that.title,_that.description,_that.locationName,_that.locationAddress,_that.allDay,_that.date,_that.endDate,_that.startMinutes,_that.endMinutes,_that.opponent,_that.homeAway,_that.arriveMinutesBefore,_that.rsvpEnabled,_that.rsvpDeadline,_that.deadlineDaysBefore,_that.deadlineMinutes,_that.reminderOffsets,_that.notifyTeam,_that.postToChat,_that.repeat,_that.seriesFrom,_that.countBefore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String timeZone,  EventType type,  String title,  String description,  String locationName,  String locationAddress,  bool allDay,  DateTime? date,  DateTime? endDate,  int startMinutes,  int endMinutes,  String opponent,  HomeAway? homeAway,  int? arriveMinutesBefore,  bool rsvpEnabled,  DateTime? rsvpDeadline,  int? deadlineDaysBefore,  int? deadlineMinutes,  List<int> reminderOffsets,  bool notifyTeam,  bool postToChat,  RepeatRule? repeat,  String? seriesFrom,  int countBefore)  $default,) {final _that = this;
switch (_that) {
case _EventDraft():
return $default(_that.timeZone,_that.type,_that.title,_that.description,_that.locationName,_that.locationAddress,_that.allDay,_that.date,_that.endDate,_that.startMinutes,_that.endMinutes,_that.opponent,_that.homeAway,_that.arriveMinutesBefore,_that.rsvpEnabled,_that.rsvpDeadline,_that.deadlineDaysBefore,_that.deadlineMinutes,_that.reminderOffsets,_that.notifyTeam,_that.postToChat,_that.repeat,_that.seriesFrom,_that.countBefore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String timeZone,  EventType type,  String title,  String description,  String locationName,  String locationAddress,  bool allDay,  DateTime? date,  DateTime? endDate,  int startMinutes,  int endMinutes,  String opponent,  HomeAway? homeAway,  int? arriveMinutesBefore,  bool rsvpEnabled,  DateTime? rsvpDeadline,  int? deadlineDaysBefore,  int? deadlineMinutes,  List<int> reminderOffsets,  bool notifyTeam,  bool postToChat,  RepeatRule? repeat,  String? seriesFrom,  int countBefore)?  $default,) {final _that = this;
switch (_that) {
case _EventDraft() when $default != null:
return $default(_that.timeZone,_that.type,_that.title,_that.description,_that.locationName,_that.locationAddress,_that.allDay,_that.date,_that.endDate,_that.startMinutes,_that.endMinutes,_that.opponent,_that.homeAway,_that.arriveMinutesBefore,_that.rsvpEnabled,_that.rsvpDeadline,_that.deadlineDaysBefore,_that.deadlineMinutes,_that.reminderOffsets,_that.notifyTeam,_that.postToChat,_that.repeat,_that.seriesFrom,_that.countBefore);case _:
  return null;

}
}

}

/// @nodoc


class _EventDraft extends EventDraft {
  const _EventDraft({required this.timeZone, this.type = EventType.practice, this.title = '', this.description = '', this.locationName = '', this.locationAddress = '', this.allDay = false, this.date, this.endDate, this.startMinutes = 18 * 60, this.endMinutes = 19 * 60 + 30, this.opponent = '', this.homeAway, this.arriveMinutesBefore, this.rsvpEnabled = true, this.rsvpDeadline, this.deadlineDaysBefore, this.deadlineMinutes,  List<int> reminderOffsets = const <int>[], this.notifyTeam = true, this.postToChat = true, this.repeat, this.seriesFrom, this.countBefore = 0}): _reminderOffsets = reminderOffsets,super._();
  

@override final  String timeZone;
@override@JsonKey() final  EventType type;
/// Left blank on a game, it becomes "vs. Opponent" (see [effectiveTitle]).
@override@JsonKey() final  String title;
@override@JsonKey() final  String description;
@override@JsonKey() final  String locationName;
@override@JsonKey() final  String locationAddress;
@override@JsonKey() final  bool allDay;
/// Empty on a duplicate until picked (SCHED-3 Duplicate).
@override final  DateTime? date;
/// An all-day event's last day; null means the same day as [date].
@override final  DateTime? endDate;
@override@JsonKey() final  int startMinutes;
@override@JsonKey() final  int endMinutes;
@override@JsonKey() final  String opponent;
@override final  HomeAway? homeAway;
@override final  int? arriveMinutesBefore;
@override@JsonKey() final  bool rsvpEnabled;
/// A deadline picked as a day and time. See [deadline].
@override final  DateTime? rsvpDeadline;
/// On a duplicate, the original's deadline as days before the start
/// at a time of day in [timeZone]: it lands as far before the copy's
/// date once one is picked (SCHED-3 copies the RSVP settings).
@override final  int? deadlineDaysBefore;
@override final  int? deadlineMinutes;
 final  List<int> _reminderOffsets;
@override@JsonKey() List<int> get reminderOffsets {
  if (_reminderOffsets is EqualUnmodifiableListView) return _reminderOffsets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reminderOffsets);
}

@override@JsonKey() final  bool notifyTeam;
@override@JsonKey() final  bool postToChat;
/// Null: doesn't repeat (the default).
@override final  RepeatRule? repeat;
/// On a "This and following" edit, the edited event's series date: the
/// new rule starts there, as the server starts it, even when the event
/// was moved to another day (SCHED-6).
@override final  String? seriesFrom;
/// On a "This and following" edit, how many of the old series' events
/// fall before [seriesFrom]. A rule that ends after N events counts
/// the whole series, so the server leaves these out (SCHED-6).
@override@JsonKey() final  int countBefore;

/// Create a copy of EventDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventDraftCopyWith<_EventDraft> get copyWith => __$EventDraftCopyWithImpl<_EventDraft>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventDraft&&(identical(other.timeZone, timeZone) || other.timeZone == timeZone)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.locationName, locationName) || other.locationName == locationName)&&(identical(other.locationAddress, locationAddress) || other.locationAddress == locationAddress)&&(identical(other.allDay, allDay) || other.allDay == allDay)&&(identical(other.date, date) || other.date == date)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.startMinutes, startMinutes) || other.startMinutes == startMinutes)&&(identical(other.endMinutes, endMinutes) || other.endMinutes == endMinutes)&&(identical(other.opponent, opponent) || other.opponent == opponent)&&(identical(other.homeAway, homeAway) || other.homeAway == homeAway)&&(identical(other.arriveMinutesBefore, arriveMinutesBefore) || other.arriveMinutesBefore == arriveMinutesBefore)&&(identical(other.rsvpEnabled, rsvpEnabled) || other.rsvpEnabled == rsvpEnabled)&&(identical(other.rsvpDeadline, rsvpDeadline) || other.rsvpDeadline == rsvpDeadline)&&(identical(other.deadlineDaysBefore, deadlineDaysBefore) || other.deadlineDaysBefore == deadlineDaysBefore)&&(identical(other.deadlineMinutes, deadlineMinutes) || other.deadlineMinutes == deadlineMinutes)&&const DeepCollectionEquality().equals(other.reminderOffsets, _reminderOffsets)&&(identical(other.notifyTeam, notifyTeam) || other.notifyTeam == notifyTeam)&&(identical(other.postToChat, postToChat) || other.postToChat == postToChat)&&(identical(other.repeat, repeat) || other.repeat == repeat)&&(identical(other.seriesFrom, seriesFrom) || other.seriesFrom == seriesFrom)&&(identical(other.countBefore, countBefore) || other.countBefore == countBefore));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,timeZone,type,title,description,locationName,locationAddress,allDay,date,endDate,startMinutes,endMinutes,opponent,homeAway,arriveMinutesBefore,rsvpEnabled,rsvpDeadline,deadlineDaysBefore,deadlineMinutes,const DeepCollectionEquality().hash(_reminderOffsets),notifyTeam,postToChat,repeat,seriesFrom,countBefore]);
}

@override
String toString() {
    return 'EventDraft(timeZone: $timeZone, type: $type, title: $title, description: $description, locationName: $locationName, locationAddress: $locationAddress, allDay: $allDay, date: $date, endDate: $endDate, startMinutes: $startMinutes, endMinutes: $endMinutes, opponent: $opponent, homeAway: $homeAway, arriveMinutesBefore: $arriveMinutesBefore, rsvpEnabled: $rsvpEnabled, rsvpDeadline: $rsvpDeadline, deadlineDaysBefore: $deadlineDaysBefore, deadlineMinutes: $deadlineMinutes, reminderOffsets: $reminderOffsets, notifyTeam: $notifyTeam, postToChat: $postToChat, repeat: $repeat, seriesFrom: $seriesFrom, countBefore: $countBefore)';
}


}

/// @nodoc
abstract mixin class _$EventDraftCopyWith<$Res> implements $EventDraftCopyWith<$Res> {
  factory _$EventDraftCopyWith(_EventDraft value, $Res Function(_EventDraft) _then) = __$EventDraftCopyWithImpl;
@override @useResult
$Res call({
 String timeZone, EventType type, String title, String description, String locationName, String locationAddress, bool allDay, DateTime? date, DateTime? endDate, int startMinutes, int endMinutes, String opponent, HomeAway? homeAway, int? arriveMinutesBefore, bool rsvpEnabled, DateTime? rsvpDeadline, int? deadlineDaysBefore, int? deadlineMinutes, List<int> reminderOffsets, bool notifyTeam, bool postToChat, RepeatRule? repeat, String? seriesFrom, int countBefore
});


@override $RepeatRuleCopyWith<$Res>? get repeat;

}
/// @nodoc
class __$EventDraftCopyWithImpl<$Res>
    implements _$EventDraftCopyWith<$Res> {
  __$EventDraftCopyWithImpl(this._self, this._then);

  final _EventDraft _self;
  final $Res Function(_EventDraft) _then;

/// Create a copy of EventDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? timeZone = null,Object? type = null,Object? title = null,Object? description = null,Object? locationName = null,Object? locationAddress = null,Object? allDay = null,Object? date = freezed,Object? endDate = freezed,Object? startMinutes = null,Object? endMinutes = null,Object? opponent = null,Object? homeAway = freezed,Object? arriveMinutesBefore = freezed,Object? rsvpEnabled = null,Object? rsvpDeadline = freezed,Object? deadlineDaysBefore = freezed,Object? deadlineMinutes = freezed,Object? reminderOffsets = null,Object? notifyTeam = null,Object? postToChat = null,Object? repeat = freezed,Object? seriesFrom = freezed,Object? countBefore = null,}) {
  return _then(_EventDraft(
timeZone: null == timeZone ? _self.timeZone : timeZone // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as EventType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,locationName: null == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String,locationAddress: null == locationAddress ? _self.locationAddress : locationAddress // ignore: cast_nullable_to_non_nullable
as String,allDay: null == allDay ? _self.allDay : allDay // ignore: cast_nullable_to_non_nullable
as bool,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,startMinutes: null == startMinutes ? _self.startMinutes : startMinutes // ignore: cast_nullable_to_non_nullable
as int,endMinutes: null == endMinutes ? _self.endMinutes : endMinutes // ignore: cast_nullable_to_non_nullable
as int,opponent: null == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as String,homeAway: freezed == homeAway ? _self.homeAway : homeAway // ignore: cast_nullable_to_non_nullable
as HomeAway?,arriveMinutesBefore: freezed == arriveMinutesBefore ? _self.arriveMinutesBefore : arriveMinutesBefore // ignore: cast_nullable_to_non_nullable
as int?,rsvpEnabled: null == rsvpEnabled ? _self.rsvpEnabled : rsvpEnabled // ignore: cast_nullable_to_non_nullable
as bool,rsvpDeadline: freezed == rsvpDeadline ? _self.rsvpDeadline : rsvpDeadline // ignore: cast_nullable_to_non_nullable
as DateTime?,deadlineDaysBefore: freezed == deadlineDaysBefore ? _self.deadlineDaysBefore : deadlineDaysBefore // ignore: cast_nullable_to_non_nullable
as int?,deadlineMinutes: freezed == deadlineMinutes ? _self.deadlineMinutes : deadlineMinutes // ignore: cast_nullable_to_non_nullable
as int?,reminderOffsets: null == reminderOffsets ? _self._reminderOffsets : reminderOffsets // ignore: cast_nullable_to_non_nullable
as List<int>,notifyTeam: null == notifyTeam ? _self.notifyTeam : notifyTeam // ignore: cast_nullable_to_non_nullable
as bool,postToChat: null == postToChat ? _self.postToChat : postToChat // ignore: cast_nullable_to_non_nullable
as bool,repeat: freezed == repeat ? _self.repeat : repeat // ignore: cast_nullable_to_non_nullable
as RepeatRule?,seriesFrom: freezed == seriesFrom ? _self.seriesFrom : seriesFrom // ignore: cast_nullable_to_non_nullable
as String?,countBefore: null == countBefore ? _self.countBefore : countBefore // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of EventDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RepeatRuleCopyWith<$Res>? get repeat {
    if (_self.repeat == null) {
    return null;
  }

  return $RepeatRuleCopyWith<$Res>(_self.repeat!, (value) {
    return _then(_self.copyWith(repeat: value));
  });
}
}

/// @nodoc
mixin _$RepeatRule {

 RepeatFreq get freq; int get interval; List<int> get byWeekday;/// Ends on a date ([untilDate]) or after [count] events.
 bool get endsOnDate; String? get untilDate; int get count; List<String> get skipDates;
/// Create a copy of RepeatRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RepeatRuleCopyWith<RepeatRule> get copyWith => _$RepeatRuleCopyWithImpl<RepeatRule>(this as RepeatRule, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RepeatRule;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RepeatRule&&(identical(other.freq, _this.freq) || other.freq == _this.freq)&&(identical(other.interval, _this.interval) || other.interval == _this.interval)&&const DeepCollectionEquality().equals(other.byWeekday, _this.byWeekday)&&(identical(other.endsOnDate, _this.endsOnDate) || other.endsOnDate == _this.endsOnDate)&&(identical(other.untilDate, _this.untilDate) || other.untilDate == _this.untilDate)&&(identical(other.count, _this.count) || other.count == _this.count)&&const DeepCollectionEquality().equals(other.skipDates, _this.skipDates));
}


@override
int get hashCode {
  final _this = this as RepeatRule;
  return Object.hash(runtimeType,_this.freq,_this.interval,const DeepCollectionEquality().hash(_this.byWeekday),_this.endsOnDate,_this.untilDate,_this.count,const DeepCollectionEquality().hash(_this.skipDates));
}

@override
String toString() {
  final _this = this as RepeatRule;
  return 'RepeatRule(freq: ${_this.freq}, interval: ${_this.interval}, byWeekday: ${_this.byWeekday}, endsOnDate: ${_this.endsOnDate}, untilDate: ${_this.untilDate}, count: ${_this.count}, skipDates: ${_this.skipDates})';
}


}

/// @nodoc
abstract mixin class $RepeatRuleCopyWith<$Res>  {
  factory $RepeatRuleCopyWith(RepeatRule value, $Res Function(RepeatRule) _then) = _$RepeatRuleCopyWithImpl;
@useResult
$Res call({
 RepeatFreq freq, int interval, List<int> byWeekday, bool endsOnDate, String? untilDate, int count, List<String> skipDates
});




}
/// @nodoc
class _$RepeatRuleCopyWithImpl<$Res>
    implements $RepeatRuleCopyWith<$Res> {
  _$RepeatRuleCopyWithImpl(this._self, this._then);

  final RepeatRule _self;
  final $Res Function(RepeatRule) _then;

/// Create a copy of RepeatRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? freq = null,Object? interval = null,Object? byWeekday = null,Object? endsOnDate = null,Object? untilDate = freezed,Object? count = null,Object? skipDates = null,}) {
  return _then(RepeatRule(
freq: null == freq ? _self.freq : freq // ignore: cast_nullable_to_non_nullable
as RepeatFreq,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,byWeekday: null == byWeekday ? _self.byWeekday : byWeekday // ignore: cast_nullable_to_non_nullable
as List<int>,endsOnDate: null == endsOnDate ? _self.endsOnDate : endsOnDate // ignore: cast_nullable_to_non_nullable
as bool,untilDate: freezed == untilDate ? _self.untilDate : untilDate // ignore: cast_nullable_to_non_nullable
as String?,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,skipDates: null == skipDates ? _self.skipDates : skipDates // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [RepeatRule].
extension RepeatRulePatterns on RepeatRule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RepeatRule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RepeatRule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RepeatRule value)  $default,){
final _that = this;
switch (_that) {
case _RepeatRule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RepeatRule value)?  $default,){
final _that = this;
switch (_that) {
case _RepeatRule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RepeatFreq freq,  int interval,  List<int> byWeekday,  bool endsOnDate,  String? untilDate,  int count,  List<String> skipDates)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RepeatRule() when $default != null:
return $default(_that.freq,_that.interval,_that.byWeekday,_that.endsOnDate,_that.untilDate,_that.count,_that.skipDates);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RepeatFreq freq,  int interval,  List<int> byWeekday,  bool endsOnDate,  String? untilDate,  int count,  List<String> skipDates)  $default,) {final _that = this;
switch (_that) {
case _RepeatRule():
return $default(_that.freq,_that.interval,_that.byWeekday,_that.endsOnDate,_that.untilDate,_that.count,_that.skipDates);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RepeatFreq freq,  int interval,  List<int> byWeekday,  bool endsOnDate,  String? untilDate,  int count,  List<String> skipDates)?  $default,) {final _that = this;
switch (_that) {
case _RepeatRule() when $default != null:
return $default(_that.freq,_that.interval,_that.byWeekday,_that.endsOnDate,_that.untilDate,_that.count,_that.skipDates);case _:
  return null;

}
}

}

/// @nodoc


class _RepeatRule extends RepeatRule {
  const _RepeatRule({this.freq = RepeatFreq.weekly, this.interval = 1,  List<int> byWeekday = const <int>[], this.endsOnDate = true, this.untilDate, this.count = 10,  List<String> skipDates = const <String>[]}): _byWeekday = byWeekday,_skipDates = skipDates,super._();
  

@override@JsonKey() final  RepeatFreq freq;
@override@JsonKey() final  int interval;
 final  List<int> _byWeekday;
@override@JsonKey() List<int> get byWeekday {
  if (_byWeekday is EqualUnmodifiableListView) return _byWeekday;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_byWeekday);
}

/// Ends on a date ([untilDate]) or after [count] events.
@override@JsonKey() final  bool endsOnDate;
@override final  String? untilDate;
@override@JsonKey() final  int count;
 final  List<String> _skipDates;
@override@JsonKey() List<String> get skipDates {
  if (_skipDates is EqualUnmodifiableListView) return _skipDates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_skipDates);
}


/// Create a copy of RepeatRule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RepeatRuleCopyWith<_RepeatRule> get copyWith => __$RepeatRuleCopyWithImpl<_RepeatRule>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RepeatRule&&(identical(other.freq, freq) || other.freq == freq)&&(identical(other.interval, interval) || other.interval == interval)&&const DeepCollectionEquality().equals(other.byWeekday, _byWeekday)&&(identical(other.endsOnDate, endsOnDate) || other.endsOnDate == endsOnDate)&&(identical(other.untilDate, untilDate) || other.untilDate == untilDate)&&(identical(other.count, count) || other.count == count)&&const DeepCollectionEquality().equals(other.skipDates, _skipDates));
}


@override
int get hashCode {
    return Object.hash(runtimeType,freq,interval,const DeepCollectionEquality().hash(_byWeekday),endsOnDate,untilDate,count,const DeepCollectionEquality().hash(_skipDates));
}

@override
String toString() {
    return 'RepeatRule(freq: $freq, interval: $interval, byWeekday: $byWeekday, endsOnDate: $endsOnDate, untilDate: $untilDate, count: $count, skipDates: $skipDates)';
}


}

/// @nodoc
abstract mixin class _$RepeatRuleCopyWith<$Res> implements $RepeatRuleCopyWith<$Res> {
  factory _$RepeatRuleCopyWith(_RepeatRule value, $Res Function(_RepeatRule) _then) = __$RepeatRuleCopyWithImpl;
@override @useResult
$Res call({
 RepeatFreq freq, int interval, List<int> byWeekday, bool endsOnDate, String? untilDate, int count, List<String> skipDates
});




}
/// @nodoc
class __$RepeatRuleCopyWithImpl<$Res>
    implements _$RepeatRuleCopyWith<$Res> {
  __$RepeatRuleCopyWithImpl(this._self, this._then);

  final _RepeatRule _self;
  final $Res Function(_RepeatRule) _then;

/// Create a copy of RepeatRule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? freq = null,Object? interval = null,Object? byWeekday = null,Object? endsOnDate = null,Object? untilDate = freezed,Object? count = null,Object? skipDates = null,}) {
  return _then(_RepeatRule(
freq: null == freq ? _self.freq : freq // ignore: cast_nullable_to_non_nullable
as RepeatFreq,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,byWeekday: null == byWeekday ? _self._byWeekday : byWeekday // ignore: cast_nullable_to_non_nullable
as List<int>,endsOnDate: null == endsOnDate ? _self.endsOnDate : endsOnDate // ignore: cast_nullable_to_non_nullable
as bool,untilDate: freezed == untilDate ? _self.untilDate : untilDate // ignore: cast_nullable_to_non_nullable
as String?,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,skipDates: null == skipDates ? _self._skipDates : skipDates // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$EventTemplate {

 EventType get type; String get title; String get description; bool get allDay; String get timeZone; bool get rsvpEnabled; List<int> get reminderOffsets; bool get notifyTeam; bool get postToChat; EventLocation? get location;/// 'HH:mm' in [timeZone]; null on all-day events.
 String? get startTime; String? get endTime; int? get arriveMinutesBefore; String? get opponent; HomeAway? get homeAway;
/// Create a copy of EventTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventTemplateCopyWith<EventTemplate> get copyWith => _$EventTemplateCopyWithImpl<EventTemplate>(this as EventTemplate, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EventTemplate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventTemplate&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.allDay, _this.allDay) || other.allDay == _this.allDay)&&(identical(other.timeZone, _this.timeZone) || other.timeZone == _this.timeZone)&&(identical(other.rsvpEnabled, _this.rsvpEnabled) || other.rsvpEnabled == _this.rsvpEnabled)&&const DeepCollectionEquality().equals(other.reminderOffsets, _this.reminderOffsets)&&(identical(other.notifyTeam, _this.notifyTeam) || other.notifyTeam == _this.notifyTeam)&&(identical(other.postToChat, _this.postToChat) || other.postToChat == _this.postToChat)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.startTime, _this.startTime) || other.startTime == _this.startTime)&&(identical(other.endTime, _this.endTime) || other.endTime == _this.endTime)&&(identical(other.arriveMinutesBefore, _this.arriveMinutesBefore) || other.arriveMinutesBefore == _this.arriveMinutesBefore)&&(identical(other.opponent, _this.opponent) || other.opponent == _this.opponent)&&(identical(other.homeAway, _this.homeAway) || other.homeAway == _this.homeAway));
}


@override
int get hashCode {
  final _this = this as EventTemplate;
  return Object.hash(runtimeType,_this.type,_this.title,_this.description,_this.allDay,_this.timeZone,_this.rsvpEnabled,const DeepCollectionEquality().hash(_this.reminderOffsets),_this.notifyTeam,_this.postToChat,_this.location,_this.startTime,_this.endTime,_this.arriveMinutesBefore,_this.opponent,_this.homeAway);
}

@override
String toString() {
  final _this = this as EventTemplate;
  return 'EventTemplate(type: ${_this.type}, title: ${_this.title}, description: ${_this.description}, allDay: ${_this.allDay}, timeZone: ${_this.timeZone}, rsvpEnabled: ${_this.rsvpEnabled}, reminderOffsets: ${_this.reminderOffsets}, notifyTeam: ${_this.notifyTeam}, postToChat: ${_this.postToChat}, location: ${_this.location}, startTime: ${_this.startTime}, endTime: ${_this.endTime}, arriveMinutesBefore: ${_this.arriveMinutesBefore}, opponent: ${_this.opponent}, homeAway: ${_this.homeAway})';
}


}

/// @nodoc
abstract mixin class $EventTemplateCopyWith<$Res>  {
  factory $EventTemplateCopyWith(EventTemplate value, $Res Function(EventTemplate) _then) = _$EventTemplateCopyWithImpl;
@useResult
$Res call({
 EventType type, String title, String description, bool allDay, String timeZone, bool rsvpEnabled, List<int> reminderOffsets, bool notifyTeam, bool postToChat, EventLocation? location, String? startTime, String? endTime, int? arriveMinutesBefore, String? opponent, HomeAway? homeAway
});


$EventLocationCopyWith<$Res>? get location;

}
/// @nodoc
class _$EventTemplateCopyWithImpl<$Res>
    implements $EventTemplateCopyWith<$Res> {
  _$EventTemplateCopyWithImpl(this._self, this._then);

  final EventTemplate _self;
  final $Res Function(EventTemplate) _then;

/// Create a copy of EventTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? title = null,Object? description = null,Object? allDay = null,Object? timeZone = null,Object? rsvpEnabled = null,Object? reminderOffsets = null,Object? notifyTeam = null,Object? postToChat = null,Object? location = freezed,Object? startTime = freezed,Object? endTime = freezed,Object? arriveMinutesBefore = freezed,Object? opponent = freezed,Object? homeAway = freezed,}) {
  return _then(EventTemplate(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as EventType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,allDay: null == allDay ? _self.allDay : allDay // ignore: cast_nullable_to_non_nullable
as bool,timeZone: null == timeZone ? _self.timeZone : timeZone // ignore: cast_nullable_to_non_nullable
as String,rsvpEnabled: null == rsvpEnabled ? _self.rsvpEnabled : rsvpEnabled // ignore: cast_nullable_to_non_nullable
as bool,reminderOffsets: null == reminderOffsets ? _self.reminderOffsets : reminderOffsets // ignore: cast_nullable_to_non_nullable
as List<int>,notifyTeam: null == notifyTeam ? _self.notifyTeam : notifyTeam // ignore: cast_nullable_to_non_nullable
as bool,postToChat: null == postToChat ? _self.postToChat : postToChat // ignore: cast_nullable_to_non_nullable
as bool,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as EventLocation?,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String?,arriveMinutesBefore: freezed == arriveMinutesBefore ? _self.arriveMinutesBefore : arriveMinutesBefore // ignore: cast_nullable_to_non_nullable
as int?,opponent: freezed == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as String?,homeAway: freezed == homeAway ? _self.homeAway : homeAway // ignore: cast_nullable_to_non_nullable
as HomeAway?,
  ));
}
/// Create a copy of EventTemplate
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
}
}


/// Adds pattern-matching-related methods to [EventTemplate].
extension EventTemplatePatterns on EventTemplate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventTemplate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventTemplate value)  $default,){
final _that = this;
switch (_that) {
case _EventTemplate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _EventTemplate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EventType type,  String title,  String description,  bool allDay,  String timeZone,  bool rsvpEnabled,  List<int> reminderOffsets,  bool notifyTeam,  bool postToChat,  EventLocation? location,  String? startTime,  String? endTime,  int? arriveMinutesBefore,  String? opponent,  HomeAway? homeAway)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventTemplate() when $default != null:
return $default(_that.type,_that.title,_that.description,_that.allDay,_that.timeZone,_that.rsvpEnabled,_that.reminderOffsets,_that.notifyTeam,_that.postToChat,_that.location,_that.startTime,_that.endTime,_that.arriveMinutesBefore,_that.opponent,_that.homeAway);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EventType type,  String title,  String description,  bool allDay,  String timeZone,  bool rsvpEnabled,  List<int> reminderOffsets,  bool notifyTeam,  bool postToChat,  EventLocation? location,  String? startTime,  String? endTime,  int? arriveMinutesBefore,  String? opponent,  HomeAway? homeAway)  $default,) {final _that = this;
switch (_that) {
case _EventTemplate():
return $default(_that.type,_that.title,_that.description,_that.allDay,_that.timeZone,_that.rsvpEnabled,_that.reminderOffsets,_that.notifyTeam,_that.postToChat,_that.location,_that.startTime,_that.endTime,_that.arriveMinutesBefore,_that.opponent,_that.homeAway);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EventType type,  String title,  String description,  bool allDay,  String timeZone,  bool rsvpEnabled,  List<int> reminderOffsets,  bool notifyTeam,  bool postToChat,  EventLocation? location,  String? startTime,  String? endTime,  int? arriveMinutesBefore,  String? opponent,  HomeAway? homeAway)?  $default,) {final _that = this;
switch (_that) {
case _EventTemplate() when $default != null:
return $default(_that.type,_that.title,_that.description,_that.allDay,_that.timeZone,_that.rsvpEnabled,_that.reminderOffsets,_that.notifyTeam,_that.postToChat,_that.location,_that.startTime,_that.endTime,_that.arriveMinutesBefore,_that.opponent,_that.homeAway);case _:
  return null;

}
}

}

/// @nodoc


class _EventTemplate implements EventTemplate {
  const _EventTemplate({required this.type, required this.title, required this.description, required this.allDay, required this.timeZone, required this.rsvpEnabled, required  List<int> reminderOffsets, required this.notifyTeam, required this.postToChat, this.location, this.startTime, this.endTime, this.arriveMinutesBefore, this.opponent, this.homeAway}): _reminderOffsets = reminderOffsets;
  

@override final  EventType type;
@override final  String title;
@override final  String description;
@override final  bool allDay;
@override final  String timeZone;
@override final  bool rsvpEnabled;
 final  List<int> _reminderOffsets;
@override List<int> get reminderOffsets {
  if (_reminderOffsets is EqualUnmodifiableListView) return _reminderOffsets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reminderOffsets);
}

@override final  bool notifyTeam;
@override final  bool postToChat;
@override final  EventLocation? location;
/// 'HH:mm' in [timeZone]; null on all-day events.
@override final  String? startTime;
@override final  String? endTime;
@override final  int? arriveMinutesBefore;
@override final  String? opponent;
@override final  HomeAway? homeAway;

/// Create a copy of EventTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventTemplateCopyWith<_EventTemplate> get copyWith => __$EventTemplateCopyWithImpl<_EventTemplate>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventTemplate&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.allDay, allDay) || other.allDay == allDay)&&(identical(other.timeZone, timeZone) || other.timeZone == timeZone)&&(identical(other.rsvpEnabled, rsvpEnabled) || other.rsvpEnabled == rsvpEnabled)&&const DeepCollectionEquality().equals(other.reminderOffsets, _reminderOffsets)&&(identical(other.notifyTeam, notifyTeam) || other.notifyTeam == notifyTeam)&&(identical(other.postToChat, postToChat) || other.postToChat == postToChat)&&(identical(other.location, location) || other.location == location)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.arriveMinutesBefore, arriveMinutesBefore) || other.arriveMinutesBefore == arriveMinutesBefore)&&(identical(other.opponent, opponent) || other.opponent == opponent)&&(identical(other.homeAway, homeAway) || other.homeAway == homeAway));
}


@override
int get hashCode {
    return Object.hash(runtimeType,type,title,description,allDay,timeZone,rsvpEnabled,const DeepCollectionEquality().hash(_reminderOffsets),notifyTeam,postToChat,location,startTime,endTime,arriveMinutesBefore,opponent,homeAway);
}

@override
String toString() {
    return 'EventTemplate(type: $type, title: $title, description: $description, allDay: $allDay, timeZone: $timeZone, rsvpEnabled: $rsvpEnabled, reminderOffsets: $reminderOffsets, notifyTeam: $notifyTeam, postToChat: $postToChat, location: $location, startTime: $startTime, endTime: $endTime, arriveMinutesBefore: $arriveMinutesBefore, opponent: $opponent, homeAway: $homeAway)';
}


}

/// @nodoc
abstract mixin class _$EventTemplateCopyWith<$Res> implements $EventTemplateCopyWith<$Res> {
  factory _$EventTemplateCopyWith(_EventTemplate value, $Res Function(_EventTemplate) _then) = __$EventTemplateCopyWithImpl;
@override @useResult
$Res call({
 EventType type, String title, String description, bool allDay, String timeZone, bool rsvpEnabled, List<int> reminderOffsets, bool notifyTeam, bool postToChat, EventLocation? location, String? startTime, String? endTime, int? arriveMinutesBefore, String? opponent, HomeAway? homeAway
});


@override $EventLocationCopyWith<$Res>? get location;

}
/// @nodoc
class __$EventTemplateCopyWithImpl<$Res>
    implements _$EventTemplateCopyWith<$Res> {
  __$EventTemplateCopyWithImpl(this._self, this._then);

  final _EventTemplate _self;
  final $Res Function(_EventTemplate) _then;

/// Create a copy of EventTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? title = null,Object? description = null,Object? allDay = null,Object? timeZone = null,Object? rsvpEnabled = null,Object? reminderOffsets = null,Object? notifyTeam = null,Object? postToChat = null,Object? location = freezed,Object? startTime = freezed,Object? endTime = freezed,Object? arriveMinutesBefore = freezed,Object? opponent = freezed,Object? homeAway = freezed,}) {
  return _then(_EventTemplate(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as EventType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,allDay: null == allDay ? _self.allDay : allDay // ignore: cast_nullable_to_non_nullable
as bool,timeZone: null == timeZone ? _self.timeZone : timeZone // ignore: cast_nullable_to_non_nullable
as String,rsvpEnabled: null == rsvpEnabled ? _self.rsvpEnabled : rsvpEnabled // ignore: cast_nullable_to_non_nullable
as bool,reminderOffsets: null == reminderOffsets ? _self._reminderOffsets : reminderOffsets // ignore: cast_nullable_to_non_nullable
as List<int>,notifyTeam: null == notifyTeam ? _self.notifyTeam : notifyTeam // ignore: cast_nullable_to_non_nullable
as bool,postToChat: null == postToChat ? _self.postToChat : postToChat // ignore: cast_nullable_to_non_nullable
as bool,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as EventLocation?,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String?,arriveMinutesBefore: freezed == arriveMinutesBefore ? _self.arriveMinutesBefore : arriveMinutesBefore // ignore: cast_nullable_to_non_nullable
as int?,opponent: freezed == opponent ? _self.opponent : opponent // ignore: cast_nullable_to_non_nullable
as String?,homeAway: freezed == homeAway ? _self.homeAway : homeAway // ignore: cast_nullable_to_non_nullable
as HomeAway?,
  ));
}

/// Create a copy of EventTemplate
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
}
}

// dart format on
