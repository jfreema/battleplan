// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'due.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Due {

 String get id; GroupId get groupId; String get title;/// In cents, so $45.50 is 4550 (US only, DUES-1).
 int get amountCents;/// The day it's due, "2026-11-30", or null for no date.
 String? get dueOn; String get note; String get createdBy; DateTime? get createdAt;
/// Create a copy of Due
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DueCopyWith<Due> get copyWith => _$DueCopyWithImpl<Due>(this as Due, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Due;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Due&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.amountCents, _this.amountCents) || other.amountCents == _this.amountCents)&&(identical(other.dueOn, _this.dueOn) || other.dueOn == _this.dueOn)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}


@override
int get hashCode {
  final _this = this as Due;
  return Object.hash(runtimeType,_this.id,_this.groupId,_this.title,_this.amountCents,_this.dueOn,_this.note,_this.createdBy,_this.createdAt);
}

@override
String toString() {
  final _this = this as Due;
  return 'Due(id: ${_this.id}, groupId: ${_this.groupId}, title: ${_this.title}, amountCents: ${_this.amountCents}, dueOn: ${_this.dueOn}, note: ${_this.note}, createdBy: ${_this.createdBy}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $DueCopyWith<$Res>  {
  factory $DueCopyWith(Due value, $Res Function(Due) _then) = _$DueCopyWithImpl;
@useResult
$Res call({
 String id, GroupId groupId, String title, int amountCents, String? dueOn, String note, String createdBy, DateTime? createdAt
});




}
/// @nodoc
class _$DueCopyWithImpl<$Res>
    implements $DueCopyWith<$Res> {
  _$DueCopyWithImpl(this._self, this._then);

  final Due _self;
  final $Res Function(Due) _then;

/// Create a copy of Due
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? groupId = null,Object? title = null,Object? amountCents = null,Object? dueOn = freezed,Object? note = null,Object? createdBy = null,Object? createdAt = freezed,}) {
  return _then(Due(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,dueOn: freezed == dueOn ? _self.dueOn : dueOn // ignore: cast_nullable_to_non_nullable
as String?,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Due].
extension DuePatterns on Due {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Due value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Due() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Due value)  $default,){
final _that = this;
switch (_that) {
case _Due():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Due value)?  $default,){
final _that = this;
switch (_that) {
case _Due() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  GroupId groupId,  String title,  int amountCents,  String? dueOn,  String note,  String createdBy,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Due() when $default != null:
return $default(_that.id,_that.groupId,_that.title,_that.amountCents,_that.dueOn,_that.note,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  GroupId groupId,  String title,  int amountCents,  String? dueOn,  String note,  String createdBy,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Due():
return $default(_that.id,_that.groupId,_that.title,_that.amountCents,_that.dueOn,_that.note,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  GroupId groupId,  String title,  int amountCents,  String? dueOn,  String note,  String createdBy,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Due() when $default != null:
return $default(_that.id,_that.groupId,_that.title,_that.amountCents,_that.dueOn,_that.note,_that.createdBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _Due implements Due {
  const _Due({required this.id, required this.groupId, required this.title, required this.amountCents, this.dueOn, this.note = '', this.createdBy = '', this.createdAt});
  

@override final  String id;
@override final  GroupId groupId;
@override final  String title;
/// In cents, so $45.50 is 4550 (US only, DUES-1).
@override final  int amountCents;
/// The day it's due, "2026-11-30", or null for no date.
@override final  String? dueOn;
@override@JsonKey() final  String note;
@override@JsonKey() final  String createdBy;
@override final  DateTime? createdAt;

/// Create a copy of Due
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DueCopyWith<_Due> get copyWith => __$DueCopyWithImpl<_Due>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Due&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.title, title) || other.title == title)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.dueOn, dueOn) || other.dueOn == dueOn)&&(identical(other.note, note) || other.note == note)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,groupId,title,amountCents,dueOn,note,createdBy,createdAt);
}

@override
String toString() {
    return 'Due(id: $id, groupId: $groupId, title: $title, amountCents: $amountCents, dueOn: $dueOn, note: $note, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$DueCopyWith<$Res> implements $DueCopyWith<$Res> {
  factory _$DueCopyWith(_Due value, $Res Function(_Due) _then) = __$DueCopyWithImpl;
@override @useResult
$Res call({
 String id, GroupId groupId, String title, int amountCents, String? dueOn, String note, String createdBy, DateTime? createdAt
});




}
/// @nodoc
class __$DueCopyWithImpl<$Res>
    implements _$DueCopyWith<$Res> {
  __$DueCopyWithImpl(this._self, this._then);

  final _Due _self;
  final $Res Function(_Due) _then;

/// Create a copy of Due
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? groupId = null,Object? title = null,Object? amountCents = null,Object? dueOn = freezed,Object? note = null,Object? createdBy = null,Object? createdAt = freezed,}) {
  return _then(_Due(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,dueOn: freezed == dueOn ? _self.dueOn : dueOn // ignore: cast_nullable_to_non_nullable
as String?,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$DueCharge {

 String get id; GroupId get groupId; String get dueId; String get title; int get amountCents; ParticipantType get participantType; String get participantId; String get participantName; String? get dueOn; DueStatus get status; DateTime? get paidAt; DateTime? get updatedAt;
/// Create a copy of DueCharge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DueChargeCopyWith<DueCharge> get copyWith => _$DueChargeCopyWithImpl<DueCharge>(this as DueCharge, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DueCharge;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DueCharge&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.dueId, _this.dueId) || other.dueId == _this.dueId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.amountCents, _this.amountCents) || other.amountCents == _this.amountCents)&&(identical(other.participantType, _this.participantType) || other.participantType == _this.participantType)&&(identical(other.participantId, _this.participantId) || other.participantId == _this.participantId)&&(identical(other.participantName, _this.participantName) || other.participantName == _this.participantName)&&(identical(other.dueOn, _this.dueOn) || other.dueOn == _this.dueOn)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.paidAt, _this.paidAt) || other.paidAt == _this.paidAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}


@override
int get hashCode {
  final _this = this as DueCharge;
  return Object.hash(runtimeType,_this.id,_this.groupId,_this.dueId,_this.title,_this.amountCents,_this.participantType,_this.participantId,_this.participantName,_this.dueOn,_this.status,_this.paidAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as DueCharge;
  return 'DueCharge(id: ${_this.id}, groupId: ${_this.groupId}, dueId: ${_this.dueId}, title: ${_this.title}, amountCents: ${_this.amountCents}, participantType: ${_this.participantType}, participantId: ${_this.participantId}, participantName: ${_this.participantName}, dueOn: ${_this.dueOn}, status: ${_this.status}, paidAt: ${_this.paidAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $DueChargeCopyWith<$Res>  {
  factory $DueChargeCopyWith(DueCharge value, $Res Function(DueCharge) _then) = _$DueChargeCopyWithImpl;
@useResult
$Res call({
 String id, GroupId groupId, String dueId, String title, int amountCents, ParticipantType participantType, String participantId, String participantName, String? dueOn, DueStatus status, DateTime? paidAt, DateTime? updatedAt
});




}
/// @nodoc
class _$DueChargeCopyWithImpl<$Res>
    implements $DueChargeCopyWith<$Res> {
  _$DueChargeCopyWithImpl(this._self, this._then);

  final DueCharge _self;
  final $Res Function(DueCharge) _then;

/// Create a copy of DueCharge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? groupId = null,Object? dueId = null,Object? title = null,Object? amountCents = null,Object? participantType = null,Object? participantId = null,Object? participantName = null,Object? dueOn = freezed,Object? status = null,Object? paidAt = freezed,Object? updatedAt = freezed,}) {
  return _then(DueCharge(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,dueId: null == dueId ? _self.dueId : dueId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,participantType: null == participantType ? _self.participantType : participantType // ignore: cast_nullable_to_non_nullable
as ParticipantType,participantId: null == participantId ? _self.participantId : participantId // ignore: cast_nullable_to_non_nullable
as String,participantName: null == participantName ? _self.participantName : participantName // ignore: cast_nullable_to_non_nullable
as String,dueOn: freezed == dueOn ? _self.dueOn : dueOn // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DueStatus,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [DueCharge].
extension DueChargePatterns on DueCharge {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DueCharge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DueCharge() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DueCharge value)  $default,){
final _that = this;
switch (_that) {
case _DueCharge():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DueCharge value)?  $default,){
final _that = this;
switch (_that) {
case _DueCharge() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  GroupId groupId,  String dueId,  String title,  int amountCents,  ParticipantType participantType,  String participantId,  String participantName,  String? dueOn,  DueStatus status,  DateTime? paidAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DueCharge() when $default != null:
return $default(_that.id,_that.groupId,_that.dueId,_that.title,_that.amountCents,_that.participantType,_that.participantId,_that.participantName,_that.dueOn,_that.status,_that.paidAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  GroupId groupId,  String dueId,  String title,  int amountCents,  ParticipantType participantType,  String participantId,  String participantName,  String? dueOn,  DueStatus status,  DateTime? paidAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _DueCharge():
return $default(_that.id,_that.groupId,_that.dueId,_that.title,_that.amountCents,_that.participantType,_that.participantId,_that.participantName,_that.dueOn,_that.status,_that.paidAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  GroupId groupId,  String dueId,  String title,  int amountCents,  ParticipantType participantType,  String participantId,  String participantName,  String? dueOn,  DueStatus status,  DateTime? paidAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _DueCharge() when $default != null:
return $default(_that.id,_that.groupId,_that.dueId,_that.title,_that.amountCents,_that.participantType,_that.participantId,_that.participantName,_that.dueOn,_that.status,_that.paidAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _DueCharge extends DueCharge {
  const _DueCharge({required this.id, required this.groupId, required this.dueId, required this.title, required this.amountCents, required this.participantType, required this.participantId, required this.participantName, this.dueOn, this.status = DueStatus.owed, this.paidAt, this.updatedAt}): super._();
  

@override final  String id;
@override final  GroupId groupId;
@override final  String dueId;
@override final  String title;
@override final  int amountCents;
@override final  ParticipantType participantType;
@override final  String participantId;
@override final  String participantName;
@override final  String? dueOn;
@override@JsonKey() final  DueStatus status;
@override final  DateTime? paidAt;
@override final  DateTime? updatedAt;

/// Create a copy of DueCharge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DueChargeCopyWith<_DueCharge> get copyWith => __$DueChargeCopyWithImpl<_DueCharge>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DueCharge&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.dueId, dueId) || other.dueId == dueId)&&(identical(other.title, title) || other.title == title)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.participantType, participantType) || other.participantType == participantType)&&(identical(other.participantId, participantId) || other.participantId == participantId)&&(identical(other.participantName, participantName) || other.participantName == participantName)&&(identical(other.dueOn, dueOn) || other.dueOn == dueOn)&&(identical(other.status, status) || other.status == status)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,groupId,dueId,title,amountCents,participantType,participantId,participantName,dueOn,status,paidAt,updatedAt);
}

@override
String toString() {
    return 'DueCharge(id: $id, groupId: $groupId, dueId: $dueId, title: $title, amountCents: $amountCents, participantType: $participantType, participantId: $participantId, participantName: $participantName, dueOn: $dueOn, status: $status, paidAt: $paidAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$DueChargeCopyWith<$Res> implements $DueChargeCopyWith<$Res> {
  factory _$DueChargeCopyWith(_DueCharge value, $Res Function(_DueCharge) _then) = __$DueChargeCopyWithImpl;
@override @useResult
$Res call({
 String id, GroupId groupId, String dueId, String title, int amountCents, ParticipantType participantType, String participantId, String participantName, String? dueOn, DueStatus status, DateTime? paidAt, DateTime? updatedAt
});




}
/// @nodoc
class __$DueChargeCopyWithImpl<$Res>
    implements _$DueChargeCopyWith<$Res> {
  __$DueChargeCopyWithImpl(this._self, this._then);

  final _DueCharge _self;
  final $Res Function(_DueCharge) _then;

/// Create a copy of DueCharge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? groupId = null,Object? dueId = null,Object? title = null,Object? amountCents = null,Object? participantType = null,Object? participantId = null,Object? participantName = null,Object? dueOn = freezed,Object? status = null,Object? paidAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_DueCharge(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,dueId: null == dueId ? _self.dueId : dueId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,participantType: null == participantType ? _self.participantType : participantType // ignore: cast_nullable_to_non_nullable
as ParticipantType,participantId: null == participantId ? _self.participantId : participantId // ignore: cast_nullable_to_non_nullable
as String,participantName: null == participantName ? _self.participantName : participantName // ignore: cast_nullable_to_non_nullable
as String,dueOn: freezed == dueOn ? _self.dueOn : dueOn // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DueStatus,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$DuesPayments {

 String get venmo; String get cashApp; String get appleCash; String get note;
/// Create a copy of DuesPayments
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DuesPaymentsCopyWith<DuesPayments> get copyWith => _$DuesPaymentsCopyWithImpl<DuesPayments>(this as DuesPayments, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DuesPayments;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DuesPayments&&(identical(other.venmo, _this.venmo) || other.venmo == _this.venmo)&&(identical(other.cashApp, _this.cashApp) || other.cashApp == _this.cashApp)&&(identical(other.appleCash, _this.appleCash) || other.appleCash == _this.appleCash)&&(identical(other.note, _this.note) || other.note == _this.note));
}


@override
int get hashCode {
  final _this = this as DuesPayments;
  return Object.hash(runtimeType,_this.venmo,_this.cashApp,_this.appleCash,_this.note);
}

@override
String toString() {
  final _this = this as DuesPayments;
  return 'DuesPayments(venmo: ${_this.venmo}, cashApp: ${_this.cashApp}, appleCash: ${_this.appleCash}, note: ${_this.note})';
}


}

/// @nodoc
abstract mixin class $DuesPaymentsCopyWith<$Res>  {
  factory $DuesPaymentsCopyWith(DuesPayments value, $Res Function(DuesPayments) _then) = _$DuesPaymentsCopyWithImpl;
@useResult
$Res call({
 String venmo, String cashApp, String appleCash, String note
});




}
/// @nodoc
class _$DuesPaymentsCopyWithImpl<$Res>
    implements $DuesPaymentsCopyWith<$Res> {
  _$DuesPaymentsCopyWithImpl(this._self, this._then);

  final DuesPayments _self;
  final $Res Function(DuesPayments) _then;

/// Create a copy of DuesPayments
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? venmo = null,Object? cashApp = null,Object? appleCash = null,Object? note = null,}) {
  return _then(DuesPayments(
venmo: null == venmo ? _self.venmo : venmo // ignore: cast_nullable_to_non_nullable
as String,cashApp: null == cashApp ? _self.cashApp : cashApp // ignore: cast_nullable_to_non_nullable
as String,appleCash: null == appleCash ? _self.appleCash : appleCash // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DuesPayments].
extension DuesPaymentsPatterns on DuesPayments {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DuesPayments value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DuesPayments() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DuesPayments value)  $default,){
final _that = this;
switch (_that) {
case _DuesPayments():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DuesPayments value)?  $default,){
final _that = this;
switch (_that) {
case _DuesPayments() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String venmo,  String cashApp,  String appleCash,  String note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DuesPayments() when $default != null:
return $default(_that.venmo,_that.cashApp,_that.appleCash,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String venmo,  String cashApp,  String appleCash,  String note)  $default,) {final _that = this;
switch (_that) {
case _DuesPayments():
return $default(_that.venmo,_that.cashApp,_that.appleCash,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String venmo,  String cashApp,  String appleCash,  String note)?  $default,) {final _that = this;
switch (_that) {
case _DuesPayments() when $default != null:
return $default(_that.venmo,_that.cashApp,_that.appleCash,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _DuesPayments extends DuesPayments {
  const _DuesPayments({this.venmo = '', this.cashApp = '', this.appleCash = '', this.note = ''}): super._();
  

@override@JsonKey() final  String venmo;
@override@JsonKey() final  String cashApp;
@override@JsonKey() final  String appleCash;
@override@JsonKey() final  String note;

/// Create a copy of DuesPayments
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DuesPaymentsCopyWith<_DuesPayments> get copyWith => __$DuesPaymentsCopyWithImpl<_DuesPayments>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DuesPayments&&(identical(other.venmo, venmo) || other.venmo == venmo)&&(identical(other.cashApp, cashApp) || other.cashApp == cashApp)&&(identical(other.appleCash, appleCash) || other.appleCash == appleCash)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode {
    return Object.hash(runtimeType,venmo,cashApp,appleCash,note);
}

@override
String toString() {
    return 'DuesPayments(venmo: $venmo, cashApp: $cashApp, appleCash: $appleCash, note: $note)';
}


}

/// @nodoc
abstract mixin class _$DuesPaymentsCopyWith<$Res> implements $DuesPaymentsCopyWith<$Res> {
  factory _$DuesPaymentsCopyWith(_DuesPayments value, $Res Function(_DuesPayments) _then) = __$DuesPaymentsCopyWithImpl;
@override @useResult
$Res call({
 String venmo, String cashApp, String appleCash, String note
});




}
/// @nodoc
class __$DuesPaymentsCopyWithImpl<$Res>
    implements _$DuesPaymentsCopyWith<$Res> {
  __$DuesPaymentsCopyWithImpl(this._self, this._then);

  final _DuesPayments _self;
  final $Res Function(_DuesPayments) _then;

/// Create a copy of DuesPayments
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? venmo = null,Object? cashApp = null,Object? appleCash = null,Object? note = null,}) {
  return _then(_DuesPayments(
venmo: null == venmo ? _self.venmo : venmo // ignore: cast_nullable_to_non_nullable
as String,cashApp: null == cashApp ? _self.cashApp : cashApp // ignore: cast_nullable_to_non_nullable
as String,appleCash: null == appleCash ? _self.appleCash : appleCash // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
