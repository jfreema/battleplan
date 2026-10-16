// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'membership.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Membership {

 GroupId get groupId; UserId get uid; MemberRole get role; String get displayName; NotificationLevel get notificationLevel; DateTime? get mutedUntil; DateTime? get lastReadAt; String? get title;/// Their profile photo's Storage path, copied onto the membership, for
/// the roster (TEAM-3).
 String? get photoPath;/// Who's who from their player links (PLAYER-8): "Emma #7, Liam #23"
/// for a guardian, "#12" for a member who is a player (number first
/// when both), or null.
 String? get playerSummary;/// Added by email and hasn't signed in yet: "Not joined yet" (AUTH-6).
 bool get pending;/// A phone number and email they chose to share with this team, shown
/// on their card with call, text, and email buttons (TEAM-10).
 String? get contactPhone; String? get contactEmail;/// A coach of the team (TEAM-3), set by its admins: on the roster's
/// Coaches, and answering for themselves on events (PLAYER-6). Unset,
/// the owner counts as one ([isCoach]).
 bool? get coach;/// In a direct conversation (CHAT-19, role participant): the other
/// person, and when it last had a message, which orders Messages.
 String? get otherUid; DateTime? get lastMessageAt;
/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MembershipCopyWith<Membership> get copyWith => _$MembershipCopyWithImpl<Membership>(this as Membership, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Membership;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Membership&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.uid, _this.uid) || other.uid == _this.uid)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.notificationLevel, _this.notificationLevel) || other.notificationLevel == _this.notificationLevel)&&(identical(other.mutedUntil, _this.mutedUntil) || other.mutedUntil == _this.mutedUntil)&&(identical(other.lastReadAt, _this.lastReadAt) || other.lastReadAt == _this.lastReadAt)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.photoPath, _this.photoPath) || other.photoPath == _this.photoPath)&&(identical(other.playerSummary, _this.playerSummary) || other.playerSummary == _this.playerSummary)&&(identical(other.pending, _this.pending) || other.pending == _this.pending)&&(identical(other.contactPhone, _this.contactPhone) || other.contactPhone == _this.contactPhone)&&(identical(other.contactEmail, _this.contactEmail) || other.contactEmail == _this.contactEmail)&&(identical(other.coach, _this.coach) || other.coach == _this.coach)&&(identical(other.otherUid, _this.otherUid) || other.otherUid == _this.otherUid)&&(identical(other.lastMessageAt, _this.lastMessageAt) || other.lastMessageAt == _this.lastMessageAt));
}


@override
int get hashCode {
  final _this = this as Membership;
  return Object.hash(runtimeType,_this.groupId,_this.uid,_this.role,_this.displayName,_this.notificationLevel,_this.mutedUntil,_this.lastReadAt,_this.title,_this.photoPath,_this.playerSummary,_this.pending,_this.contactPhone,_this.contactEmail,_this.coach,_this.otherUid,_this.lastMessageAt);
}

@override
String toString() {
  final _this = this as Membership;
  return 'Membership(groupId: ${_this.groupId}, uid: ${_this.uid}, role: ${_this.role}, displayName: ${_this.displayName}, notificationLevel: ${_this.notificationLevel}, mutedUntil: ${_this.mutedUntil}, lastReadAt: ${_this.lastReadAt}, title: ${_this.title}, photoPath: ${_this.photoPath}, playerSummary: ${_this.playerSummary}, pending: ${_this.pending}, contactPhone: ${_this.contactPhone}, contactEmail: ${_this.contactEmail}, coach: ${_this.coach}, otherUid: ${_this.otherUid}, lastMessageAt: ${_this.lastMessageAt})';
}


}

/// @nodoc
abstract mixin class $MembershipCopyWith<$Res>  {
  factory $MembershipCopyWith(Membership value, $Res Function(Membership) _then) = _$MembershipCopyWithImpl;
@useResult
$Res call({
 GroupId groupId, UserId uid, MemberRole role, String displayName, NotificationLevel notificationLevel, DateTime? mutedUntil, DateTime? lastReadAt, String? title, String? photoPath, String? playerSummary, bool pending, String? contactPhone, String? contactEmail, bool? coach, String? otherUid, DateTime? lastMessageAt
});




}
/// @nodoc
class _$MembershipCopyWithImpl<$Res>
    implements $MembershipCopyWith<$Res> {
  _$MembershipCopyWithImpl(this._self, this._then);

  final Membership _self;
  final $Res Function(Membership) _then;

/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groupId = null,Object? uid = null,Object? role = null,Object? displayName = null,Object? notificationLevel = null,Object? mutedUntil = freezed,Object? lastReadAt = freezed,Object? title = freezed,Object? photoPath = freezed,Object? playerSummary = freezed,Object? pending = null,Object? contactPhone = freezed,Object? contactEmail = freezed,Object? coach = freezed,Object? otherUid = freezed,Object? lastMessageAt = freezed,}) {
  return _then(Membership(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as UserId,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as MemberRole,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,notificationLevel: null == notificationLevel ? _self.notificationLevel : notificationLevel // ignore: cast_nullable_to_non_nullable
as NotificationLevel,mutedUntil: freezed == mutedUntil ? _self.mutedUntil : mutedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,lastReadAt: freezed == lastReadAt ? _self.lastReadAt : lastReadAt // ignore: cast_nullable_to_non_nullable
as DateTime?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,photoPath: freezed == photoPath ? _self.photoPath : photoPath // ignore: cast_nullable_to_non_nullable
as String?,playerSummary: freezed == playerSummary ? _self.playerSummary : playerSummary // ignore: cast_nullable_to_non_nullable
as String?,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,contactPhone: freezed == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String?,contactEmail: freezed == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String?,coach: freezed == coach ? _self.coach : coach // ignore: cast_nullable_to_non_nullable
as bool?,otherUid: freezed == otherUid ? _self.otherUid : otherUid // ignore: cast_nullable_to_non_nullable
as String?,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Membership].
extension MembershipPatterns on Membership {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Membership value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Membership() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Membership value)  $default,){
final _that = this;
switch (_that) {
case _Membership():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Membership value)?  $default,){
final _that = this;
switch (_that) {
case _Membership() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GroupId groupId,  UserId uid,  MemberRole role,  String displayName,  NotificationLevel notificationLevel,  DateTime? mutedUntil,  DateTime? lastReadAt,  String? title,  String? photoPath,  String? playerSummary,  bool pending,  String? contactPhone,  String? contactEmail,  bool? coach,  String? otherUid,  DateTime? lastMessageAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Membership() when $default != null:
return $default(_that.groupId,_that.uid,_that.role,_that.displayName,_that.notificationLevel,_that.mutedUntil,_that.lastReadAt,_that.title,_that.photoPath,_that.playerSummary,_that.pending,_that.contactPhone,_that.contactEmail,_that.coach,_that.otherUid,_that.lastMessageAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GroupId groupId,  UserId uid,  MemberRole role,  String displayName,  NotificationLevel notificationLevel,  DateTime? mutedUntil,  DateTime? lastReadAt,  String? title,  String? photoPath,  String? playerSummary,  bool pending,  String? contactPhone,  String? contactEmail,  bool? coach,  String? otherUid,  DateTime? lastMessageAt)  $default,) {final _that = this;
switch (_that) {
case _Membership():
return $default(_that.groupId,_that.uid,_that.role,_that.displayName,_that.notificationLevel,_that.mutedUntil,_that.lastReadAt,_that.title,_that.photoPath,_that.playerSummary,_that.pending,_that.contactPhone,_that.contactEmail,_that.coach,_that.otherUid,_that.lastMessageAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GroupId groupId,  UserId uid,  MemberRole role,  String displayName,  NotificationLevel notificationLevel,  DateTime? mutedUntil,  DateTime? lastReadAt,  String? title,  String? photoPath,  String? playerSummary,  bool pending,  String? contactPhone,  String? contactEmail,  bool? coach,  String? otherUid,  DateTime? lastMessageAt)?  $default,) {final _that = this;
switch (_that) {
case _Membership() when $default != null:
return $default(_that.groupId,_that.uid,_that.role,_that.displayName,_that.notificationLevel,_that.mutedUntil,_that.lastReadAt,_that.title,_that.photoPath,_that.playerSummary,_that.pending,_that.contactPhone,_that.contactEmail,_that.coach,_that.otherUid,_that.lastMessageAt);case _:
  return null;

}
}

}

/// @nodoc


class _Membership extends Membership {
  const _Membership({required this.groupId, required this.uid, required this.role, required this.displayName, this.notificationLevel = NotificationLevel.all, this.mutedUntil, this.lastReadAt, this.title, this.photoPath, this.playerSummary, this.pending = false, this.contactPhone, this.contactEmail, this.coach, this.otherUid, this.lastMessageAt}): super._();
  

@override final  GroupId groupId;
@override final  UserId uid;
@override final  MemberRole role;
@override final  String displayName;
@override@JsonKey() final  NotificationLevel notificationLevel;
@override final  DateTime? mutedUntil;
@override final  DateTime? lastReadAt;
@override final  String? title;
/// Their profile photo's Storage path, copied onto the membership, for
/// the roster (TEAM-3).
@override final  String? photoPath;
/// Who's who from their player links (PLAYER-8): "Emma #7, Liam #23"
/// for a guardian, "#12" for a member who is a player (number first
/// when both), or null.
@override final  String? playerSummary;
/// Added by email and hasn't signed in yet: "Not joined yet" (AUTH-6).
@override@JsonKey() final  bool pending;
/// A phone number and email they chose to share with this team, shown
/// on their card with call, text, and email buttons (TEAM-10).
@override final  String? contactPhone;
@override final  String? contactEmail;
/// A coach of the team (TEAM-3), set by its admins: on the roster's
/// Coaches, and answering for themselves on events (PLAYER-6). Unset,
/// the owner counts as one ([isCoach]).
@override final  bool? coach;
/// In a direct conversation (CHAT-19, role participant): the other
/// person, and when it last had a message, which orders Messages.
@override final  String? otherUid;
@override final  DateTime? lastMessageAt;

/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MembershipCopyWith<_Membership> get copyWith => __$MembershipCopyWithImpl<_Membership>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Membership&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.role, role) || other.role == role)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.notificationLevel, notificationLevel) || other.notificationLevel == notificationLevel)&&(identical(other.mutedUntil, mutedUntil) || other.mutedUntil == mutedUntil)&&(identical(other.lastReadAt, lastReadAt) || other.lastReadAt == lastReadAt)&&(identical(other.title, title) || other.title == title)&&(identical(other.photoPath, photoPath) || other.photoPath == photoPath)&&(identical(other.playerSummary, playerSummary) || other.playerSummary == playerSummary)&&(identical(other.pending, pending) || other.pending == pending)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone)&&(identical(other.contactEmail, contactEmail) || other.contactEmail == contactEmail)&&(identical(other.coach, coach) || other.coach == coach)&&(identical(other.otherUid, otherUid) || other.otherUid == otherUid)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,groupId,uid,role,displayName,notificationLevel,mutedUntil,lastReadAt,title,photoPath,playerSummary,pending,contactPhone,contactEmail,coach,otherUid,lastMessageAt);
}

@override
String toString() {
    return 'Membership(groupId: $groupId, uid: $uid, role: $role, displayName: $displayName, notificationLevel: $notificationLevel, mutedUntil: $mutedUntil, lastReadAt: $lastReadAt, title: $title, photoPath: $photoPath, playerSummary: $playerSummary, pending: $pending, contactPhone: $contactPhone, contactEmail: $contactEmail, coach: $coach, otherUid: $otherUid, lastMessageAt: $lastMessageAt)';
}


}

/// @nodoc
abstract mixin class _$MembershipCopyWith<$Res> implements $MembershipCopyWith<$Res> {
  factory _$MembershipCopyWith(_Membership value, $Res Function(_Membership) _then) = __$MembershipCopyWithImpl;
@override @useResult
$Res call({
 GroupId groupId, UserId uid, MemberRole role, String displayName, NotificationLevel notificationLevel, DateTime? mutedUntil, DateTime? lastReadAt, String? title, String? photoPath, String? playerSummary, bool pending, String? contactPhone, String? contactEmail, bool? coach, String? otherUid, DateTime? lastMessageAt
});




}
/// @nodoc
class __$MembershipCopyWithImpl<$Res>
    implements _$MembershipCopyWith<$Res> {
  __$MembershipCopyWithImpl(this._self, this._then);

  final _Membership _self;
  final $Res Function(_Membership) _then;

/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? groupId = null,Object? uid = null,Object? role = null,Object? displayName = null,Object? notificationLevel = null,Object? mutedUntil = freezed,Object? lastReadAt = freezed,Object? title = freezed,Object? photoPath = freezed,Object? playerSummary = freezed,Object? pending = null,Object? contactPhone = freezed,Object? contactEmail = freezed,Object? coach = freezed,Object? otherUid = freezed,Object? lastMessageAt = freezed,}) {
  return _then(_Membership(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as UserId,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as MemberRole,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,notificationLevel: null == notificationLevel ? _self.notificationLevel : notificationLevel // ignore: cast_nullable_to_non_nullable
as NotificationLevel,mutedUntil: freezed == mutedUntil ? _self.mutedUntil : mutedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,lastReadAt: freezed == lastReadAt ? _self.lastReadAt : lastReadAt // ignore: cast_nullable_to_non_nullable
as DateTime?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,photoPath: freezed == photoPath ? _self.photoPath : photoPath // ignore: cast_nullable_to_non_nullable
as String?,playerSummary: freezed == playerSummary ? _self.playerSummary : playerSummary // ignore: cast_nullable_to_non_nullable
as String?,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,contactPhone: freezed == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String?,contactEmail: freezed == contactEmail ? _self.contactEmail : contactEmail // ignore: cast_nullable_to_non_nullable
as String?,coach: freezed == coach ? _self.coach : coach // ignore: cast_nullable_to_non_nullable
as bool?,otherUid: freezed == otherUid ? _self.otherUid : otherUid // ignore: cast_nullable_to_non_nullable
as String?,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
