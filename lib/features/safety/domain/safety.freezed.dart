// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'safety.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BlockedPerson {

 UserId get uid; String get name;
/// Create a copy of BlockedPerson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BlockedPersonCopyWith<BlockedPerson> get copyWith => _$BlockedPersonCopyWithImpl<BlockedPerson>(this as BlockedPerson, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BlockedPerson;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BlockedPerson&&(identical(other.uid, _this.uid) || other.uid == _this.uid)&&(identical(other.name, _this.name) || other.name == _this.name));
}


@override
int get hashCode {
  final _this = this as BlockedPerson;
  return Object.hash(runtimeType,_this.uid,_this.name);
}

@override
String toString() {
  final _this = this as BlockedPerson;
  return 'BlockedPerson(uid: ${_this.uid}, name: ${_this.name})';
}


}

/// @nodoc
abstract mixin class $BlockedPersonCopyWith<$Res>  {
  factory $BlockedPersonCopyWith(BlockedPerson value, $Res Function(BlockedPerson) _then) = _$BlockedPersonCopyWithImpl;
@useResult
$Res call({
 UserId uid, String name
});




}
/// @nodoc
class _$BlockedPersonCopyWithImpl<$Res>
    implements $BlockedPersonCopyWith<$Res> {
  _$BlockedPersonCopyWithImpl(this._self, this._then);

  final BlockedPerson _self;
  final $Res Function(BlockedPerson) _then;

/// Create a copy of BlockedPerson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? name = null,}) {
  return _then(BlockedPerson(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as UserId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BlockedPerson].
extension BlockedPersonPatterns on BlockedPerson {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BlockedPerson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BlockedPerson() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BlockedPerson value)  $default,){
final _that = this;
switch (_that) {
case _BlockedPerson():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BlockedPerson value)?  $default,){
final _that = this;
switch (_that) {
case _BlockedPerson() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UserId uid,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BlockedPerson() when $default != null:
return $default(_that.uid,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UserId uid,  String name)  $default,) {final _that = this;
switch (_that) {
case _BlockedPerson():
return $default(_that.uid,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UserId uid,  String name)?  $default,) {final _that = this;
switch (_that) {
case _BlockedPerson() when $default != null:
return $default(_that.uid,_that.name);case _:
  return null;

}
}

}

/// @nodoc


class _BlockedPerson implements BlockedPerson {
  const _BlockedPerson({required this.uid, this.name = ''});
  

@override final  UserId uid;
@override@JsonKey() final  String name;

/// Create a copy of BlockedPerson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BlockedPersonCopyWith<_BlockedPerson> get copyWith => __$BlockedPersonCopyWithImpl<_BlockedPerson>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BlockedPerson&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode {
    return Object.hash(runtimeType,uid,name);
}

@override
String toString() {
    return 'BlockedPerson(uid: $uid, name: $name)';
}


}

/// @nodoc
abstract mixin class _$BlockedPersonCopyWith<$Res> implements $BlockedPersonCopyWith<$Res> {
  factory _$BlockedPersonCopyWith(_BlockedPerson value, $Res Function(_BlockedPerson) _then) = __$BlockedPersonCopyWithImpl;
@override @useResult
$Res call({
 UserId uid, String name
});




}
/// @nodoc
class __$BlockedPersonCopyWithImpl<$Res>
    implements _$BlockedPersonCopyWith<$Res> {
  __$BlockedPersonCopyWithImpl(this._self, this._then);

  final _BlockedPerson _self;
  final $Res Function(_BlockedPerson) _then;

/// Create a copy of BlockedPerson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? name = null,}) {
  return _then(_BlockedPerson(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as UserId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$Report {

 String get id; GroupId get groupId; ReportTargetType get targetType; String get targetId; ReportReason get reason;/// The person the report is about, and a copy of what was reported.
 String get subjectId; String get subjectName; String get excerpt; String? get details; DateTime? get createdAt;
/// Create a copy of Report
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportCopyWith<Report> get copyWith => _$ReportCopyWithImpl<Report>(this as Report, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Report;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Report&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.targetType, _this.targetType) || other.targetType == _this.targetType)&&(identical(other.targetId, _this.targetId) || other.targetId == _this.targetId)&&(identical(other.reason, _this.reason) || other.reason == _this.reason)&&(identical(other.subjectId, _this.subjectId) || other.subjectId == _this.subjectId)&&(identical(other.subjectName, _this.subjectName) || other.subjectName == _this.subjectName)&&(identical(other.excerpt, _this.excerpt) || other.excerpt == _this.excerpt)&&(identical(other.details, _this.details) || other.details == _this.details)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}


@override
int get hashCode {
  final _this = this as Report;
  return Object.hash(runtimeType,_this.id,_this.groupId,_this.targetType,_this.targetId,_this.reason,_this.subjectId,_this.subjectName,_this.excerpt,_this.details,_this.createdAt);
}

@override
String toString() {
  final _this = this as Report;
  return 'Report(id: ${_this.id}, groupId: ${_this.groupId}, targetType: ${_this.targetType}, targetId: ${_this.targetId}, reason: ${_this.reason}, subjectId: ${_this.subjectId}, subjectName: ${_this.subjectName}, excerpt: ${_this.excerpt}, details: ${_this.details}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $ReportCopyWith<$Res>  {
  factory $ReportCopyWith(Report value, $Res Function(Report) _then) = _$ReportCopyWithImpl;
@useResult
$Res call({
 String id, GroupId groupId, ReportTargetType targetType, String targetId, ReportReason reason, String subjectId, String subjectName, String excerpt, String? details, DateTime? createdAt
});




}
/// @nodoc
class _$ReportCopyWithImpl<$Res>
    implements $ReportCopyWith<$Res> {
  _$ReportCopyWithImpl(this._self, this._then);

  final Report _self;
  final $Res Function(Report) _then;

/// Create a copy of Report
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? groupId = null,Object? targetType = null,Object? targetId = null,Object? reason = null,Object? subjectId = null,Object? subjectName = null,Object? excerpt = null,Object? details = freezed,Object? createdAt = freezed,}) {
  return _then(Report(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as ReportTargetType,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as ReportReason,subjectId: null == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String,subjectName: null == subjectName ? _self.subjectName : subjectName // ignore: cast_nullable_to_non_nullable
as String,excerpt: null == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as String,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Report].
extension ReportPatterns on Report {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Report value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Report() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Report value)  $default,){
final _that = this;
switch (_that) {
case _Report():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Report value)?  $default,){
final _that = this;
switch (_that) {
case _Report() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  GroupId groupId,  ReportTargetType targetType,  String targetId,  ReportReason reason,  String subjectId,  String subjectName,  String excerpt,  String? details,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Report() when $default != null:
return $default(_that.id,_that.groupId,_that.targetType,_that.targetId,_that.reason,_that.subjectId,_that.subjectName,_that.excerpt,_that.details,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  GroupId groupId,  ReportTargetType targetType,  String targetId,  ReportReason reason,  String subjectId,  String subjectName,  String excerpt,  String? details,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Report():
return $default(_that.id,_that.groupId,_that.targetType,_that.targetId,_that.reason,_that.subjectId,_that.subjectName,_that.excerpt,_that.details,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  GroupId groupId,  ReportTargetType targetType,  String targetId,  ReportReason reason,  String subjectId,  String subjectName,  String excerpt,  String? details,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Report() when $default != null:
return $default(_that.id,_that.groupId,_that.targetType,_that.targetId,_that.reason,_that.subjectId,_that.subjectName,_that.excerpt,_that.details,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _Report implements Report {
  const _Report({required this.id, required this.groupId, required this.targetType, required this.targetId, required this.reason, required this.subjectId, required this.subjectName, this.excerpt = '', this.details, this.createdAt});
  

@override final  String id;
@override final  GroupId groupId;
@override final  ReportTargetType targetType;
@override final  String targetId;
@override final  ReportReason reason;
/// The person the report is about, and a copy of what was reported.
@override final  String subjectId;
@override final  String subjectName;
@override@JsonKey() final  String excerpt;
@override final  String? details;
@override final  DateTime? createdAt;

/// Create a copy of Report
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReportCopyWith<_Report> get copyWith => __$ReportCopyWithImpl<_Report>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Report&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.subjectId, subjectId) || other.subjectId == subjectId)&&(identical(other.subjectName, subjectName) || other.subjectName == subjectName)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt)&&(identical(other.details, details) || other.details == details)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,groupId,targetType,targetId,reason,subjectId,subjectName,excerpt,details,createdAt);
}

@override
String toString() {
    return 'Report(id: $id, groupId: $groupId, targetType: $targetType, targetId: $targetId, reason: $reason, subjectId: $subjectId, subjectName: $subjectName, excerpt: $excerpt, details: $details, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ReportCopyWith<$Res> implements $ReportCopyWith<$Res> {
  factory _$ReportCopyWith(_Report value, $Res Function(_Report) _then) = __$ReportCopyWithImpl;
@override @useResult
$Res call({
 String id, GroupId groupId, ReportTargetType targetType, String targetId, ReportReason reason, String subjectId, String subjectName, String excerpt, String? details, DateTime? createdAt
});




}
/// @nodoc
class __$ReportCopyWithImpl<$Res>
    implements _$ReportCopyWith<$Res> {
  __$ReportCopyWithImpl(this._self, this._then);

  final _Report _self;
  final $Res Function(_Report) _then;

/// Create a copy of Report
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? groupId = null,Object? targetType = null,Object? targetId = null,Object? reason = null,Object? subjectId = null,Object? subjectName = null,Object? excerpt = null,Object? details = freezed,Object? createdAt = freezed,}) {
  return _then(_Report(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as ReportTargetType,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as ReportReason,subjectId: null == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String,subjectName: null == subjectName ? _self.subjectName : subjectName // ignore: cast_nullable_to_non_nullable
as String,excerpt: null == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as String,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
