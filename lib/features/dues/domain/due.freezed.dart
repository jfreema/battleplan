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
mixin _$DuePayment {

/// The app's ID for it, the same on every try, so a retry never
/// records it twice ([newRequestId]).
 String get id;/// In cents, from 1 up to what was left.
 int get amountCents;/// The day it was paid, "2026-11-05".
 String get paidOn;/// Who recorded it (a uid), or empty for a share marked paid before
/// payments were recorded, which became one payment when its amount
/// changed.
 String get by;/// A short note, like "Venmo" or "Cash at practice" (up to
/// [Limits.duePaymentNoteMax]).
 String get note;
/// Create a copy of DuePayment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DuePaymentCopyWith<DuePayment> get copyWith => _$DuePaymentCopyWithImpl<DuePayment>(this as DuePayment, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DuePayment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DuePayment&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.amountCents, _this.amountCents) || other.amountCents == _this.amountCents)&&(identical(other.paidOn, _this.paidOn) || other.paidOn == _this.paidOn)&&(identical(other.by, _this.by) || other.by == _this.by)&&(identical(other.note, _this.note) || other.note == _this.note));
}


@override
int get hashCode {
  final _this = this as DuePayment;
  return Object.hash(runtimeType,_this.id,_this.amountCents,_this.paidOn,_this.by,_this.note);
}

@override
String toString() {
  final _this = this as DuePayment;
  return 'DuePayment(id: ${_this.id}, amountCents: ${_this.amountCents}, paidOn: ${_this.paidOn}, by: ${_this.by}, note: ${_this.note})';
}


}

/// @nodoc
abstract mixin class $DuePaymentCopyWith<$Res>  {
  factory $DuePaymentCopyWith(DuePayment value, $Res Function(DuePayment) _then) = _$DuePaymentCopyWithImpl;
@useResult
$Res call({
 String id, int amountCents, String paidOn, String by, String note
});




}
/// @nodoc
class _$DuePaymentCopyWithImpl<$Res>
    implements $DuePaymentCopyWith<$Res> {
  _$DuePaymentCopyWithImpl(this._self, this._then);

  final DuePayment _self;
  final $Res Function(DuePayment) _then;

/// Create a copy of DuePayment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? amountCents = null,Object? paidOn = null,Object? by = null,Object? note = null,}) {
  return _then(DuePayment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,paidOn: null == paidOn ? _self.paidOn : paidOn // ignore: cast_nullable_to_non_nullable
as String,by: null == by ? _self.by : by // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DuePayment].
extension DuePaymentPatterns on DuePayment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DuePayment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DuePayment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DuePayment value)  $default,){
final _that = this;
switch (_that) {
case _DuePayment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DuePayment value)?  $default,){
final _that = this;
switch (_that) {
case _DuePayment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int amountCents,  String paidOn,  String by,  String note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DuePayment() when $default != null:
return $default(_that.id,_that.amountCents,_that.paidOn,_that.by,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int amountCents,  String paidOn,  String by,  String note)  $default,) {final _that = this;
switch (_that) {
case _DuePayment():
return $default(_that.id,_that.amountCents,_that.paidOn,_that.by,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int amountCents,  String paidOn,  String by,  String note)?  $default,) {final _that = this;
switch (_that) {
case _DuePayment() when $default != null:
return $default(_that.id,_that.amountCents,_that.paidOn,_that.by,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _DuePayment implements DuePayment {
  const _DuePayment({required this.id, required this.amountCents, required this.paidOn, this.by = '', this.note = ''});
  

/// The app's ID for it, the same on every try, so a retry never
/// records it twice ([newRequestId]).
@override final  String id;
/// In cents, from 1 up to what was left.
@override final  int amountCents;
/// The day it was paid, "2026-11-05".
@override final  String paidOn;
/// Who recorded it (a uid), or empty for a share marked paid before
/// payments were recorded, which became one payment when its amount
/// changed.
@override@JsonKey() final  String by;
/// A short note, like "Venmo" or "Cash at practice" (up to
/// [Limits.duePaymentNoteMax]).
@override@JsonKey() final  String note;

/// Create a copy of DuePayment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DuePaymentCopyWith<_DuePayment> get copyWith => __$DuePaymentCopyWithImpl<_DuePayment>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DuePayment&&(identical(other.id, id) || other.id == id)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.paidOn, paidOn) || other.paidOn == paidOn)&&(identical(other.by, by) || other.by == by)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,amountCents,paidOn,by,note);
}

@override
String toString() {
    return 'DuePayment(id: $id, amountCents: $amountCents, paidOn: $paidOn, by: $by, note: $note)';
}


}

/// @nodoc
abstract mixin class _$DuePaymentCopyWith<$Res> implements $DuePaymentCopyWith<$Res> {
  factory _$DuePaymentCopyWith(_DuePayment value, $Res Function(_DuePayment) _then) = __$DuePaymentCopyWithImpl;
@override @useResult
$Res call({
 String id, int amountCents, String paidOn, String by, String note
});




}
/// @nodoc
class __$DuePaymentCopyWithImpl<$Res>
    implements _$DuePaymentCopyWith<$Res> {
  __$DuePaymentCopyWithImpl(this._self, this._then);

  final _DuePayment _self;
  final $Res Function(_DuePayment) _then;

/// Create a copy of DuePayment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? amountCents = null,Object? paidOn = null,Object? by = null,Object? note = null,}) {
  return _then(_DuePayment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,paidOn: null == paidOn ? _self.paidOn : paidOn // ignore: cast_nullable_to_non_nullable
as String,by: null == by ? _self.by : by // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$DueCharge {

 String get id; GroupId get groupId; String get dueId; String get title; int get amountCents; ParticipantType get participantType; String get participantId; String get participantName; String? get dueOn;/// The due's note, for everyone who owes it (DUES-2).
 String get note; DueStatus get status; DateTime? get paidAt; DateTime? get updatedAt;/// What's been recorded as paid, oldest first (DUES-2).
 List<DuePayment> get payments;/// Their total, in cents, as stored; null on a share from before
/// payments were recorded, where Paid means paid in full.
 int? get recordedCents;
/// Create a copy of DueCharge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DueChargeCopyWith<DueCharge> get copyWith => _$DueChargeCopyWithImpl<DueCharge>(this as DueCharge, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DueCharge;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DueCharge&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.dueId, _this.dueId) || other.dueId == _this.dueId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.amountCents, _this.amountCents) || other.amountCents == _this.amountCents)&&(identical(other.participantType, _this.participantType) || other.participantType == _this.participantType)&&(identical(other.participantId, _this.participantId) || other.participantId == _this.participantId)&&(identical(other.participantName, _this.participantName) || other.participantName == _this.participantName)&&(identical(other.dueOn, _this.dueOn) || other.dueOn == _this.dueOn)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.paidAt, _this.paidAt) || other.paidAt == _this.paidAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&const DeepCollectionEquality().equals(other.payments, _this.payments)&&(identical(other.recordedCents, _this.recordedCents) || other.recordedCents == _this.recordedCents));
}


@override
int get hashCode {
  final _this = this as DueCharge;
  return Object.hash(runtimeType,_this.id,_this.groupId,_this.dueId,_this.title,_this.amountCents,_this.participantType,_this.participantId,_this.participantName,_this.dueOn,_this.note,_this.status,_this.paidAt,_this.updatedAt,const DeepCollectionEquality().hash(_this.payments),_this.recordedCents);
}

@override
String toString() {
  final _this = this as DueCharge;
  return 'DueCharge(id: ${_this.id}, groupId: ${_this.groupId}, dueId: ${_this.dueId}, title: ${_this.title}, amountCents: ${_this.amountCents}, participantType: ${_this.participantType}, participantId: ${_this.participantId}, participantName: ${_this.participantName}, dueOn: ${_this.dueOn}, note: ${_this.note}, status: ${_this.status}, paidAt: ${_this.paidAt}, updatedAt: ${_this.updatedAt}, payments: ${_this.payments}, recordedCents: ${_this.recordedCents})';
}


}

/// @nodoc
abstract mixin class $DueChargeCopyWith<$Res>  {
  factory $DueChargeCopyWith(DueCharge value, $Res Function(DueCharge) _then) = _$DueChargeCopyWithImpl;
@useResult
$Res call({
 String id, GroupId groupId, String dueId, String title, int amountCents, ParticipantType participantType, String participantId, String participantName, String? dueOn, String note, DueStatus status, DateTime? paidAt, DateTime? updatedAt, List<DuePayment> payments, int? recordedCents
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? groupId = null,Object? dueId = null,Object? title = null,Object? amountCents = null,Object? participantType = null,Object? participantId = null,Object? participantName = null,Object? dueOn = freezed,Object? note = null,Object? status = null,Object? paidAt = freezed,Object? updatedAt = freezed,Object? payments = null,Object? recordedCents = freezed,}) {
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
as String?,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DueStatus,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,payments: null == payments ? _self.payments : payments // ignore: cast_nullable_to_non_nullable
as List<DuePayment>,recordedCents: freezed == recordedCents ? _self.recordedCents : recordedCents // ignore: cast_nullable_to_non_nullable
as int?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  GroupId groupId,  String dueId,  String title,  int amountCents,  ParticipantType participantType,  String participantId,  String participantName,  String? dueOn,  String note,  DueStatus status,  DateTime? paidAt,  DateTime? updatedAt,  List<DuePayment> payments,  int? recordedCents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DueCharge() when $default != null:
return $default(_that.id,_that.groupId,_that.dueId,_that.title,_that.amountCents,_that.participantType,_that.participantId,_that.participantName,_that.dueOn,_that.note,_that.status,_that.paidAt,_that.updatedAt,_that.payments,_that.recordedCents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  GroupId groupId,  String dueId,  String title,  int amountCents,  ParticipantType participantType,  String participantId,  String participantName,  String? dueOn,  String note,  DueStatus status,  DateTime? paidAt,  DateTime? updatedAt,  List<DuePayment> payments,  int? recordedCents)  $default,) {final _that = this;
switch (_that) {
case _DueCharge():
return $default(_that.id,_that.groupId,_that.dueId,_that.title,_that.amountCents,_that.participantType,_that.participantId,_that.participantName,_that.dueOn,_that.note,_that.status,_that.paidAt,_that.updatedAt,_that.payments,_that.recordedCents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  GroupId groupId,  String dueId,  String title,  int amountCents,  ParticipantType participantType,  String participantId,  String participantName,  String? dueOn,  String note,  DueStatus status,  DateTime? paidAt,  DateTime? updatedAt,  List<DuePayment> payments,  int? recordedCents)?  $default,) {final _that = this;
switch (_that) {
case _DueCharge() when $default != null:
return $default(_that.id,_that.groupId,_that.dueId,_that.title,_that.amountCents,_that.participantType,_that.participantId,_that.participantName,_that.dueOn,_that.note,_that.status,_that.paidAt,_that.updatedAt,_that.payments,_that.recordedCents);case _:
  return null;

}
}

}

/// @nodoc


class _DueCharge extends DueCharge {
  const _DueCharge({required this.id, required this.groupId, required this.dueId, required this.title, required this.amountCents, required this.participantType, required this.participantId, required this.participantName, this.dueOn, this.note = '', this.status = DueStatus.owed, this.paidAt, this.updatedAt,  List<DuePayment> payments = const <DuePayment>[], this.recordedCents}): _payments = payments,super._();
  

@override final  String id;
@override final  GroupId groupId;
@override final  String dueId;
@override final  String title;
@override final  int amountCents;
@override final  ParticipantType participantType;
@override final  String participantId;
@override final  String participantName;
@override final  String? dueOn;
/// The due's note, for everyone who owes it (DUES-2).
@override@JsonKey() final  String note;
@override@JsonKey() final  DueStatus status;
@override final  DateTime? paidAt;
@override final  DateTime? updatedAt;
/// What's been recorded as paid, oldest first (DUES-2).
 final  List<DuePayment> _payments;
/// What's been recorded as paid, oldest first (DUES-2).
@override@JsonKey() List<DuePayment> get payments {
  if (_payments is EqualUnmodifiableListView) return _payments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_payments);
}

/// Their total, in cents, as stored; null on a share from before
/// payments were recorded, where Paid means paid in full.
@override final  int? recordedCents;

/// Create a copy of DueCharge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DueChargeCopyWith<_DueCharge> get copyWith => __$DueChargeCopyWithImpl<_DueCharge>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DueCharge&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.dueId, dueId) || other.dueId == dueId)&&(identical(other.title, title) || other.title == title)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.participantType, participantType) || other.participantType == participantType)&&(identical(other.participantId, participantId) || other.participantId == participantId)&&(identical(other.participantName, participantName) || other.participantName == participantName)&&(identical(other.dueOn, dueOn) || other.dueOn == dueOn)&&(identical(other.note, note) || other.note == note)&&(identical(other.status, status) || other.status == status)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.payments, _payments)&&(identical(other.recordedCents, recordedCents) || other.recordedCents == recordedCents));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,groupId,dueId,title,amountCents,participantType,participantId,participantName,dueOn,note,status,paidAt,updatedAt,const DeepCollectionEquality().hash(_payments),recordedCents);
}

@override
String toString() {
    return 'DueCharge(id: $id, groupId: $groupId, dueId: $dueId, title: $title, amountCents: $amountCents, participantType: $participantType, participantId: $participantId, participantName: $participantName, dueOn: $dueOn, note: $note, status: $status, paidAt: $paidAt, updatedAt: $updatedAt, payments: $payments, recordedCents: $recordedCents)';
}


}

/// @nodoc
abstract mixin class _$DueChargeCopyWith<$Res> implements $DueChargeCopyWith<$Res> {
  factory _$DueChargeCopyWith(_DueCharge value, $Res Function(_DueCharge) _then) = __$DueChargeCopyWithImpl;
@override @useResult
$Res call({
 String id, GroupId groupId, String dueId, String title, int amountCents, ParticipantType participantType, String participantId, String participantName, String? dueOn, String note, DueStatus status, DateTime? paidAt, DateTime? updatedAt, List<DuePayment> payments, int? recordedCents
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? groupId = null,Object? dueId = null,Object? title = null,Object? amountCents = null,Object? participantType = null,Object? participantId = null,Object? participantName = null,Object? dueOn = freezed,Object? note = null,Object? status = null,Object? paidAt = freezed,Object? updatedAt = freezed,Object? payments = null,Object? recordedCents = freezed,}) {
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
as String?,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DueStatus,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,payments: null == payments ? _self._payments : payments // ignore: cast_nullable_to_non_nullable
as List<DuePayment>,recordedCents: freezed == recordedCents ? _self.recordedCents : recordedCents // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$DuesPayments {

 String get venmo; String get cashApp; String get appleCash; String get note;/// Who saved it last, which everyone sees ("Updated by Coach Lee").
 String get updatedBy;
/// Create a copy of DuesPayments
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DuesPaymentsCopyWith<DuesPayments> get copyWith => _$DuesPaymentsCopyWithImpl<DuesPayments>(this as DuesPayments, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DuesPayments;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DuesPayments&&(identical(other.venmo, _this.venmo) || other.venmo == _this.venmo)&&(identical(other.cashApp, _this.cashApp) || other.cashApp == _this.cashApp)&&(identical(other.appleCash, _this.appleCash) || other.appleCash == _this.appleCash)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.updatedBy, _this.updatedBy) || other.updatedBy == _this.updatedBy));
}


@override
int get hashCode {
  final _this = this as DuesPayments;
  return Object.hash(runtimeType,_this.venmo,_this.cashApp,_this.appleCash,_this.note,_this.updatedBy);
}

@override
String toString() {
  final _this = this as DuesPayments;
  return 'DuesPayments(venmo: ${_this.venmo}, cashApp: ${_this.cashApp}, appleCash: ${_this.appleCash}, note: ${_this.note}, updatedBy: ${_this.updatedBy})';
}


}

/// @nodoc
abstract mixin class $DuesPaymentsCopyWith<$Res>  {
  factory $DuesPaymentsCopyWith(DuesPayments value, $Res Function(DuesPayments) _then) = _$DuesPaymentsCopyWithImpl;
@useResult
$Res call({
 String venmo, String cashApp, String appleCash, String note, String updatedBy
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
@pragma('vm:prefer-inline') @override $Res call({Object? venmo = null,Object? cashApp = null,Object? appleCash = null,Object? note = null,Object? updatedBy = null,}) {
  return _then(DuesPayments(
venmo: null == venmo ? _self.venmo : venmo // ignore: cast_nullable_to_non_nullable
as String,cashApp: null == cashApp ? _self.cashApp : cashApp // ignore: cast_nullable_to_non_nullable
as String,appleCash: null == appleCash ? _self.appleCash : appleCash // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String venmo,  String cashApp,  String appleCash,  String note,  String updatedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DuesPayments() when $default != null:
return $default(_that.venmo,_that.cashApp,_that.appleCash,_that.note,_that.updatedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String venmo,  String cashApp,  String appleCash,  String note,  String updatedBy)  $default,) {final _that = this;
switch (_that) {
case _DuesPayments():
return $default(_that.venmo,_that.cashApp,_that.appleCash,_that.note,_that.updatedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String venmo,  String cashApp,  String appleCash,  String note,  String updatedBy)?  $default,) {final _that = this;
switch (_that) {
case _DuesPayments() when $default != null:
return $default(_that.venmo,_that.cashApp,_that.appleCash,_that.note,_that.updatedBy);case _:
  return null;

}
}

}

/// @nodoc


class _DuesPayments extends DuesPayments {
  const _DuesPayments({this.venmo = '', this.cashApp = '', this.appleCash = '', this.note = '', this.updatedBy = ''}): super._();
  

@override@JsonKey() final  String venmo;
@override@JsonKey() final  String cashApp;
@override@JsonKey() final  String appleCash;
@override@JsonKey() final  String note;
/// Who saved it last, which everyone sees ("Updated by Coach Lee").
@override@JsonKey() final  String updatedBy;

/// Create a copy of DuesPayments
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DuesPaymentsCopyWith<_DuesPayments> get copyWith => __$DuesPaymentsCopyWithImpl<_DuesPayments>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DuesPayments&&(identical(other.venmo, venmo) || other.venmo == venmo)&&(identical(other.cashApp, cashApp) || other.cashApp == cashApp)&&(identical(other.appleCash, appleCash) || other.appleCash == appleCash)&&(identical(other.note, note) || other.note == note)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}


@override
int get hashCode {
    return Object.hash(runtimeType,venmo,cashApp,appleCash,note,updatedBy);
}

@override
String toString() {
    return 'DuesPayments(venmo: $venmo, cashApp: $cashApp, appleCash: $appleCash, note: $note, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class _$DuesPaymentsCopyWith<$Res> implements $DuesPaymentsCopyWith<$Res> {
  factory _$DuesPaymentsCopyWith(_DuesPayments value, $Res Function(_DuesPayments) _then) = __$DuesPaymentsCopyWithImpl;
@override @useResult
$Res call({
 String venmo, String cashApp, String appleCash, String note, String updatedBy
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
@override @pragma('vm:prefer-inline') $Res call({Object? venmo = null,Object? cashApp = null,Object? appleCash = null,Object? note = null,Object? updatedBy = null,}) {
  return _then(_DuesPayments(
venmo: null == venmo ? _self.venmo : venmo // ignore: cast_nullable_to_non_nullable
as String,cashApp: null == cashApp ? _self.cashApp : cashApp // ignore: cast_nullable_to_non_nullable
as String,appleCash: null == appleCash ? _self.appleCash : appleCash // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
