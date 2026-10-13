// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rsvp.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Rsvp {

 EventId get eventId; GroupId get groupId; ParticipantType get participantType;/// A uid for members, a player ID for players.
 String get participantId; String get participantName; RsvpStatus get status; String get note;/// Who gave the answer: "Answered by Maria" (PLAYER-6).
 String get respondedBy; DateTime? get eventStartAt; DateTime? get updatedAt;/// True until the server has it (SCHED-5 works offline).
 bool get pending;
/// Create a copy of Rsvp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RsvpCopyWith<Rsvp> get copyWith => _$RsvpCopyWithImpl<Rsvp>(this as Rsvp, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Rsvp;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Rsvp&&(identical(other.eventId, _this.eventId) || other.eventId == _this.eventId)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.participantType, _this.participantType) || other.participantType == _this.participantType)&&(identical(other.participantId, _this.participantId) || other.participantId == _this.participantId)&&(identical(other.participantName, _this.participantName) || other.participantName == _this.participantName)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.respondedBy, _this.respondedBy) || other.respondedBy == _this.respondedBy)&&(identical(other.eventStartAt, _this.eventStartAt) || other.eventStartAt == _this.eventStartAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.pending, _this.pending) || other.pending == _this.pending));
}


@override
int get hashCode {
  final _this = this as Rsvp;
  return Object.hash(runtimeType,_this.eventId,_this.groupId,_this.participantType,_this.participantId,_this.participantName,_this.status,_this.note,_this.respondedBy,_this.eventStartAt,_this.updatedAt,_this.pending);
}

@override
String toString() {
  final _this = this as Rsvp;
  return 'Rsvp(eventId: ${_this.eventId}, groupId: ${_this.groupId}, participantType: ${_this.participantType}, participantId: ${_this.participantId}, participantName: ${_this.participantName}, status: ${_this.status}, note: ${_this.note}, respondedBy: ${_this.respondedBy}, eventStartAt: ${_this.eventStartAt}, updatedAt: ${_this.updatedAt}, pending: ${_this.pending})';
}


}

/// @nodoc
abstract mixin class $RsvpCopyWith<$Res>  {
  factory $RsvpCopyWith(Rsvp value, $Res Function(Rsvp) _then) = _$RsvpCopyWithImpl;
@useResult
$Res call({
 EventId eventId, GroupId groupId, ParticipantType participantType, String participantId, String participantName, RsvpStatus status, String note, String respondedBy, DateTime? eventStartAt, DateTime? updatedAt, bool pending
});




}
/// @nodoc
class _$RsvpCopyWithImpl<$Res>
    implements $RsvpCopyWith<$Res> {
  _$RsvpCopyWithImpl(this._self, this._then);

  final Rsvp _self;
  final $Res Function(Rsvp) _then;

/// Create a copy of Rsvp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventId = null,Object? groupId = null,Object? participantType = null,Object? participantId = null,Object? participantName = null,Object? status = null,Object? note = null,Object? respondedBy = null,Object? eventStartAt = freezed,Object? updatedAt = freezed,Object? pending = null,}) {
  return _then(Rsvp(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as EventId,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,participantType: null == participantType ? _self.participantType : participantType // ignore: cast_nullable_to_non_nullable
as ParticipantType,participantId: null == participantId ? _self.participantId : participantId // ignore: cast_nullable_to_non_nullable
as String,participantName: null == participantName ? _self.participantName : participantName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RsvpStatus,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,respondedBy: null == respondedBy ? _self.respondedBy : respondedBy // ignore: cast_nullable_to_non_nullable
as String,eventStartAt: freezed == eventStartAt ? _self.eventStartAt : eventStartAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Rsvp].
extension RsvpPatterns on Rsvp {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Rsvp value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Rsvp() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Rsvp value)  $default,){
final _that = this;
switch (_that) {
case _Rsvp():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Rsvp value)?  $default,){
final _that = this;
switch (_that) {
case _Rsvp() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EventId eventId,  GroupId groupId,  ParticipantType participantType,  String participantId,  String participantName,  RsvpStatus status,  String note,  String respondedBy,  DateTime? eventStartAt,  DateTime? updatedAt,  bool pending)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Rsvp() when $default != null:
return $default(_that.eventId,_that.groupId,_that.participantType,_that.participantId,_that.participantName,_that.status,_that.note,_that.respondedBy,_that.eventStartAt,_that.updatedAt,_that.pending);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EventId eventId,  GroupId groupId,  ParticipantType participantType,  String participantId,  String participantName,  RsvpStatus status,  String note,  String respondedBy,  DateTime? eventStartAt,  DateTime? updatedAt,  bool pending)  $default,) {final _that = this;
switch (_that) {
case _Rsvp():
return $default(_that.eventId,_that.groupId,_that.participantType,_that.participantId,_that.participantName,_that.status,_that.note,_that.respondedBy,_that.eventStartAt,_that.updatedAt,_that.pending);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EventId eventId,  GroupId groupId,  ParticipantType participantType,  String participantId,  String participantName,  RsvpStatus status,  String note,  String respondedBy,  DateTime? eventStartAt,  DateTime? updatedAt,  bool pending)?  $default,) {final _that = this;
switch (_that) {
case _Rsvp() when $default != null:
return $default(_that.eventId,_that.groupId,_that.participantType,_that.participantId,_that.participantName,_that.status,_that.note,_that.respondedBy,_that.eventStartAt,_that.updatedAt,_that.pending);case _:
  return null;

}
}

}

/// @nodoc


class _Rsvp implements Rsvp {
  const _Rsvp({required this.eventId, required this.groupId, required this.participantType, required this.participantId, required this.participantName, required this.status, this.note = '', this.respondedBy = '', this.eventStartAt, this.updatedAt, this.pending = false});
  

@override final  EventId eventId;
@override final  GroupId groupId;
@override final  ParticipantType participantType;
/// A uid for members, a player ID for players.
@override final  String participantId;
@override final  String participantName;
@override final  RsvpStatus status;
@override@JsonKey() final  String note;
/// Who gave the answer: "Answered by Maria" (PLAYER-6).
@override@JsonKey() final  String respondedBy;
@override final  DateTime? eventStartAt;
@override final  DateTime? updatedAt;
/// True until the server has it (SCHED-5 works offline).
@override@JsonKey() final  bool pending;

/// Create a copy of Rsvp
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RsvpCopyWith<_Rsvp> get copyWith => __$RsvpCopyWithImpl<_Rsvp>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Rsvp&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.participantType, participantType) || other.participantType == participantType)&&(identical(other.participantId, participantId) || other.participantId == participantId)&&(identical(other.participantName, participantName) || other.participantName == participantName)&&(identical(other.status, status) || other.status == status)&&(identical(other.note, note) || other.note == note)&&(identical(other.respondedBy, respondedBy) || other.respondedBy == respondedBy)&&(identical(other.eventStartAt, eventStartAt) || other.eventStartAt == eventStartAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.pending, pending) || other.pending == pending));
}


@override
int get hashCode {
    return Object.hash(runtimeType,eventId,groupId,participantType,participantId,participantName,status,note,respondedBy,eventStartAt,updatedAt,pending);
}

@override
String toString() {
    return 'Rsvp(eventId: $eventId, groupId: $groupId, participantType: $participantType, participantId: $participantId, participantName: $participantName, status: $status, note: $note, respondedBy: $respondedBy, eventStartAt: $eventStartAt, updatedAt: $updatedAt, pending: $pending)';
}


}

/// @nodoc
abstract mixin class _$RsvpCopyWith<$Res> implements $RsvpCopyWith<$Res> {
  factory _$RsvpCopyWith(_Rsvp value, $Res Function(_Rsvp) _then) = __$RsvpCopyWithImpl;
@override @useResult
$Res call({
 EventId eventId, GroupId groupId, ParticipantType participantType, String participantId, String participantName, RsvpStatus status, String note, String respondedBy, DateTime? eventStartAt, DateTime? updatedAt, bool pending
});




}
/// @nodoc
class __$RsvpCopyWithImpl<$Res>
    implements _$RsvpCopyWith<$Res> {
  __$RsvpCopyWithImpl(this._self, this._then);

  final _Rsvp _self;
  final $Res Function(_Rsvp) _then;

/// Create a copy of Rsvp
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? groupId = null,Object? participantType = null,Object? participantId = null,Object? participantName = null,Object? status = null,Object? note = null,Object? respondedBy = null,Object? eventStartAt = freezed,Object? updatedAt = freezed,Object? pending = null,}) {
  return _then(_Rsvp(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as EventId,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,participantType: null == participantType ? _self.participantType : participantType // ignore: cast_nullable_to_non_nullable
as ParticipantType,participantId: null == participantId ? _self.participantId : participantId // ignore: cast_nullable_to_non_nullable
as String,participantName: null == participantName ? _self.participantName : participantName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RsvpStatus,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,respondedBy: null == respondedBy ? _self.respondedBy : respondedBy // ignore: cast_nullable_to_non_nullable
as String,eventStartAt: freezed == eventStartAt ? _self.eventStartAt : eventStartAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$Participant {

 ParticipantType get type; String get id;/// The member's display name, or the player's.
 String get name;/// "Emma #7" for a player (PLAYER-8).
 String? get label;/// The signed-in member is this player ("I am this player").
 bool get isMe;
/// Create a copy of Participant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParticipantCopyWith<Participant> get copyWith => _$ParticipantCopyWithImpl<Participant>(this as Participant, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Participant;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Participant&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.isMe, _this.isMe) || other.isMe == _this.isMe));
}


@override
int get hashCode {
  final _this = this as Participant;
  return Object.hash(runtimeType,_this.type,_this.id,_this.name,_this.label,_this.isMe);
}

@override
String toString() {
  final _this = this as Participant;
  return 'Participant(type: ${_this.type}, id: ${_this.id}, name: ${_this.name}, label: ${_this.label}, isMe: ${_this.isMe})';
}


}

/// @nodoc
abstract mixin class $ParticipantCopyWith<$Res>  {
  factory $ParticipantCopyWith(Participant value, $Res Function(Participant) _then) = _$ParticipantCopyWithImpl;
@useResult
$Res call({
 ParticipantType type, String id, String name, String? label, bool isMe
});




}
/// @nodoc
class _$ParticipantCopyWithImpl<$Res>
    implements $ParticipantCopyWith<$Res> {
  _$ParticipantCopyWithImpl(this._self, this._then);

  final Participant _self;
  final $Res Function(Participant) _then;

/// Create a copy of Participant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? id = null,Object? name = null,Object? label = freezed,Object? isMe = null,}) {
  return _then(Participant(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ParticipantType,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,isMe: null == isMe ? _self.isMe : isMe // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Participant].
extension ParticipantPatterns on Participant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Participant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Participant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Participant value)  $default,){
final _that = this;
switch (_that) {
case _Participant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Participant value)?  $default,){
final _that = this;
switch (_that) {
case _Participant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ParticipantType type,  String id,  String name,  String? label,  bool isMe)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Participant() when $default != null:
return $default(_that.type,_that.id,_that.name,_that.label,_that.isMe);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ParticipantType type,  String id,  String name,  String? label,  bool isMe)  $default,) {final _that = this;
switch (_that) {
case _Participant():
return $default(_that.type,_that.id,_that.name,_that.label,_that.isMe);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ParticipantType type,  String id,  String name,  String? label,  bool isMe)?  $default,) {final _that = this;
switch (_that) {
case _Participant() when $default != null:
return $default(_that.type,_that.id,_that.name,_that.label,_that.isMe);case _:
  return null;

}
}

}

/// @nodoc


class _Participant extends Participant {
  const _Participant({required this.type, required this.id, required this.name, this.label, this.isMe = false}): super._();
  

@override final  ParticipantType type;
@override final  String id;
/// The member's display name, or the player's.
@override final  String name;
/// "Emma #7" for a player (PLAYER-8).
@override final  String? label;
/// The signed-in member is this player ("I am this player").
@override@JsonKey() final  bool isMe;

/// Create a copy of Participant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParticipantCopyWith<_Participant> get copyWith => __$ParticipantCopyWithImpl<_Participant>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Participant&&(identical(other.type, type) || other.type == type)&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.label, label) || other.label == label)&&(identical(other.isMe, isMe) || other.isMe == isMe));
}


@override
int get hashCode {
    return Object.hash(runtimeType,type,id,name,label,isMe);
}

@override
String toString() {
    return 'Participant(type: $type, id: $id, name: $name, label: $label, isMe: $isMe)';
}


}

/// @nodoc
abstract mixin class _$ParticipantCopyWith<$Res> implements $ParticipantCopyWith<$Res> {
  factory _$ParticipantCopyWith(_Participant value, $Res Function(_Participant) _then) = __$ParticipantCopyWithImpl;
@override @useResult
$Res call({
 ParticipantType type, String id, String name, String? label, bool isMe
});




}
/// @nodoc
class __$ParticipantCopyWithImpl<$Res>
    implements _$ParticipantCopyWith<$Res> {
  __$ParticipantCopyWithImpl(this._self, this._then);

  final _Participant _self;
  final $Res Function(_Participant) _then;

/// Create a copy of Participant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? id = null,Object? name = null,Object? label = freezed,Object? isMe = null,}) {
  return _then(_Participant(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ParticipantType,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,isMe: null == isMe ? _self.isMe : isMe // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$RsvpAnswer {

 Participant get participant; RsvpStatus get status; String get note;
/// Create a copy of RsvpAnswer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RsvpAnswerCopyWith<RsvpAnswer> get copyWith => _$RsvpAnswerCopyWithImpl<RsvpAnswer>(this as RsvpAnswer, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RsvpAnswer;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RsvpAnswer&&(identical(other.participant, _this.participant) || other.participant == _this.participant)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.note, _this.note) || other.note == _this.note));
}


@override
int get hashCode {
  final _this = this as RsvpAnswer;
  return Object.hash(runtimeType,_this.participant,_this.status,_this.note);
}

@override
String toString() {
  final _this = this as RsvpAnswer;
  return 'RsvpAnswer(participant: ${_this.participant}, status: ${_this.status}, note: ${_this.note})';
}


}

/// @nodoc
abstract mixin class $RsvpAnswerCopyWith<$Res>  {
  factory $RsvpAnswerCopyWith(RsvpAnswer value, $Res Function(RsvpAnswer) _then) = _$RsvpAnswerCopyWithImpl;
@useResult
$Res call({
 Participant participant, RsvpStatus status, String note
});


$ParticipantCopyWith<$Res> get participant;

}
/// @nodoc
class _$RsvpAnswerCopyWithImpl<$Res>
    implements $RsvpAnswerCopyWith<$Res> {
  _$RsvpAnswerCopyWithImpl(this._self, this._then);

  final RsvpAnswer _self;
  final $Res Function(RsvpAnswer) _then;

/// Create a copy of RsvpAnswer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? participant = null,Object? status = null,Object? note = null,}) {
  return _then(RsvpAnswer(
participant: null == participant ? _self.participant : participant // ignore: cast_nullable_to_non_nullable
as Participant,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RsvpStatus,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of RsvpAnswer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParticipantCopyWith<$Res> get participant {
  
  return $ParticipantCopyWith<$Res>(_self.participant, (value) {
    return _then(_self.copyWith(participant: value));
  });
}
}


/// Adds pattern-matching-related methods to [RsvpAnswer].
extension RsvpAnswerPatterns on RsvpAnswer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RsvpAnswer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RsvpAnswer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RsvpAnswer value)  $default,){
final _that = this;
switch (_that) {
case _RsvpAnswer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RsvpAnswer value)?  $default,){
final _that = this;
switch (_that) {
case _RsvpAnswer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Participant participant,  RsvpStatus status,  String note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RsvpAnswer() when $default != null:
return $default(_that.participant,_that.status,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Participant participant,  RsvpStatus status,  String note)  $default,) {final _that = this;
switch (_that) {
case _RsvpAnswer():
return $default(_that.participant,_that.status,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Participant participant,  RsvpStatus status,  String note)?  $default,) {final _that = this;
switch (_that) {
case _RsvpAnswer() when $default != null:
return $default(_that.participant,_that.status,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _RsvpAnswer implements RsvpAnswer {
  const _RsvpAnswer({required this.participant, required this.status, this.note = ''});
  

@override final  Participant participant;
@override final  RsvpStatus status;
@override@JsonKey() final  String note;

/// Create a copy of RsvpAnswer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RsvpAnswerCopyWith<_RsvpAnswer> get copyWith => __$RsvpAnswerCopyWithImpl<_RsvpAnswer>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RsvpAnswer&&(identical(other.participant, participant) || other.participant == participant)&&(identical(other.status, status) || other.status == status)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode {
    return Object.hash(runtimeType,participant,status,note);
}

@override
String toString() {
    return 'RsvpAnswer(participant: $participant, status: $status, note: $note)';
}


}

/// @nodoc
abstract mixin class _$RsvpAnswerCopyWith<$Res> implements $RsvpAnswerCopyWith<$Res> {
  factory _$RsvpAnswerCopyWith(_RsvpAnswer value, $Res Function(_RsvpAnswer) _then) = __$RsvpAnswerCopyWithImpl;
@override @useResult
$Res call({
 Participant participant, RsvpStatus status, String note
});


@override $ParticipantCopyWith<$Res> get participant;

}
/// @nodoc
class __$RsvpAnswerCopyWithImpl<$Res>
    implements _$RsvpAnswerCopyWith<$Res> {
  __$RsvpAnswerCopyWithImpl(this._self, this._then);

  final _RsvpAnswer _self;
  final $Res Function(_RsvpAnswer) _then;

/// Create a copy of RsvpAnswer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? participant = null,Object? status = null,Object? note = null,}) {
  return _then(_RsvpAnswer(
participant: null == participant ? _self.participant : participant // ignore: cast_nullable_to_non_nullable
as Participant,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RsvpStatus,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of RsvpAnswer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParticipantCopyWith<$Res> get participant {
  
  return $ParticipantCopyWith<$Res>(_self.participant, (value) {
    return _then(_self.copyWith(participant: value));
  });
}
}

// dart format on
