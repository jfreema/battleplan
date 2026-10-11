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

 GroupId get groupId; UserId get uid; MemberRole get role; String get displayName; NotificationLevel get notificationLevel; DateTime? get mutedUntil; DateTime? get lastReadAt; String? get title;
/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MembershipCopyWith<Membership> get copyWith => _$MembershipCopyWithImpl<Membership>(this as Membership, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Membership;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Membership&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.uid, _this.uid) || other.uid == _this.uid)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.notificationLevel, _this.notificationLevel) || other.notificationLevel == _this.notificationLevel)&&(identical(other.mutedUntil, _this.mutedUntil) || other.mutedUntil == _this.mutedUntil)&&(identical(other.lastReadAt, _this.lastReadAt) || other.lastReadAt == _this.lastReadAt)&&(identical(other.title, _this.title) || other.title == _this.title));
}


@override
int get hashCode {
  final _this = this as Membership;
  return Object.hash(runtimeType,_this.groupId,_this.uid,_this.role,_this.displayName,_this.notificationLevel,_this.mutedUntil,_this.lastReadAt,_this.title);
}

@override
String toString() {
  final _this = this as Membership;
  return 'Membership(groupId: ${_this.groupId}, uid: ${_this.uid}, role: ${_this.role}, displayName: ${_this.displayName}, notificationLevel: ${_this.notificationLevel}, mutedUntil: ${_this.mutedUntil}, lastReadAt: ${_this.lastReadAt}, title: ${_this.title})';
}


}

/// @nodoc
abstract mixin class $MembershipCopyWith<$Res>  {
  factory $MembershipCopyWith(Membership value, $Res Function(Membership) _then) = _$MembershipCopyWithImpl;
@useResult
$Res call({
 GroupId groupId, UserId uid, MemberRole role, String displayName, NotificationLevel notificationLevel, DateTime? mutedUntil, DateTime? lastReadAt, String? title
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
@pragma('vm:prefer-inline') @override $Res call({Object? groupId = null,Object? uid = null,Object? role = null,Object? displayName = null,Object? notificationLevel = null,Object? mutedUntil = freezed,Object? lastReadAt = freezed,Object? title = freezed,}) {
  return _then(Membership(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as UserId,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as MemberRole,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,notificationLevel: null == notificationLevel ? _self.notificationLevel : notificationLevel // ignore: cast_nullable_to_non_nullable
as NotificationLevel,mutedUntil: freezed == mutedUntil ? _self.mutedUntil : mutedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,lastReadAt: freezed == lastReadAt ? _self.lastReadAt : lastReadAt // ignore: cast_nullable_to_non_nullable
as DateTime?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GroupId groupId,  UserId uid,  MemberRole role,  String displayName,  NotificationLevel notificationLevel,  DateTime? mutedUntil,  DateTime? lastReadAt,  String? title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Membership() when $default != null:
return $default(_that.groupId,_that.uid,_that.role,_that.displayName,_that.notificationLevel,_that.mutedUntil,_that.lastReadAt,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GroupId groupId,  UserId uid,  MemberRole role,  String displayName,  NotificationLevel notificationLevel,  DateTime? mutedUntil,  DateTime? lastReadAt,  String? title)  $default,) {final _that = this;
switch (_that) {
case _Membership():
return $default(_that.groupId,_that.uid,_that.role,_that.displayName,_that.notificationLevel,_that.mutedUntil,_that.lastReadAt,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GroupId groupId,  UserId uid,  MemberRole role,  String displayName,  NotificationLevel notificationLevel,  DateTime? mutedUntil,  DateTime? lastReadAt,  String? title)?  $default,) {final _that = this;
switch (_that) {
case _Membership() when $default != null:
return $default(_that.groupId,_that.uid,_that.role,_that.displayName,_that.notificationLevel,_that.mutedUntil,_that.lastReadAt,_that.title);case _:
  return null;

}
}

}

/// @nodoc


class _Membership extends Membership {
  const _Membership({required this.groupId, required this.uid, required this.role, required this.displayName, this.notificationLevel = NotificationLevel.all, this.mutedUntil, this.lastReadAt, this.title}): super._();
  

@override final  GroupId groupId;
@override final  UserId uid;
@override final  MemberRole role;
@override final  String displayName;
@override@JsonKey() final  NotificationLevel notificationLevel;
@override final  DateTime? mutedUntil;
@override final  DateTime? lastReadAt;
@override final  String? title;

/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MembershipCopyWith<_Membership> get copyWith => __$MembershipCopyWithImpl<_Membership>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Membership&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.role, role) || other.role == role)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.notificationLevel, notificationLevel) || other.notificationLevel == notificationLevel)&&(identical(other.mutedUntil, mutedUntil) || other.mutedUntil == mutedUntil)&&(identical(other.lastReadAt, lastReadAt) || other.lastReadAt == lastReadAt)&&(identical(other.title, title) || other.title == title));
}


@override
int get hashCode {
    return Object.hash(runtimeType,groupId,uid,role,displayName,notificationLevel,mutedUntil,lastReadAt,title);
}

@override
String toString() {
    return 'Membership(groupId: $groupId, uid: $uid, role: $role, displayName: $displayName, notificationLevel: $notificationLevel, mutedUntil: $mutedUntil, lastReadAt: $lastReadAt, title: $title)';
}


}

/// @nodoc
abstract mixin class _$MembershipCopyWith<$Res> implements $MembershipCopyWith<$Res> {
  factory _$MembershipCopyWith(_Membership value, $Res Function(_Membership) _then) = __$MembershipCopyWithImpl;
@override @useResult
$Res call({
 GroupId groupId, UserId uid, MemberRole role, String displayName, NotificationLevel notificationLevel, DateTime? mutedUntil, DateTime? lastReadAt, String? title
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
@override @pragma('vm:prefer-inline') $Res call({Object? groupId = null,Object? uid = null,Object? role = null,Object? displayName = null,Object? notificationLevel = null,Object? mutedUntil = freezed,Object? lastReadAt = freezed,Object? title = freezed,}) {
  return _then(_Membership(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as UserId,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as MemberRole,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,notificationLevel: null == notificationLevel ? _self.notificationLevel : notificationLevel // ignore: cast_nullable_to_non_nullable
as NotificationLevel,mutedUntil: freezed == mutedUntil ? _self.mutedUntil : mutedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,lastReadAt: freezed == lastReadAt ? _self.lastReadAt : lastReadAt // ignore: cast_nullable_to_non_nullable
as DateTime?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
