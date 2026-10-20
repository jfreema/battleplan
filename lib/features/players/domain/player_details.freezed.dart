// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_details.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EmergencyContact {

 String get name; String get phone; String? get relationship;
/// Create a copy of EmergencyContact
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmergencyContactCopyWith<EmergencyContact> get copyWith => _$EmergencyContactCopyWithImpl<EmergencyContact>(this as EmergencyContact, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EmergencyContact;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmergencyContact&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.relationship, _this.relationship) || other.relationship == _this.relationship));
}


@override
int get hashCode {
  final _this = this as EmergencyContact;
  return Object.hash(runtimeType,_this.name,_this.phone,_this.relationship);
}

@override
String toString() {
  final _this = this as EmergencyContact;
  return 'EmergencyContact(name: ${_this.name}, phone: ${_this.phone}, relationship: ${_this.relationship})';
}


}

/// @nodoc
abstract mixin class $EmergencyContactCopyWith<$Res>  {
  factory $EmergencyContactCopyWith(EmergencyContact value, $Res Function(EmergencyContact) _then) = _$EmergencyContactCopyWithImpl;
@useResult
$Res call({
 String name, String phone, String? relationship
});




}
/// @nodoc
class _$EmergencyContactCopyWithImpl<$Res>
    implements $EmergencyContactCopyWith<$Res> {
  _$EmergencyContactCopyWithImpl(this._self, this._then);

  final EmergencyContact _self;
  final $Res Function(EmergencyContact) _then;

/// Create a copy of EmergencyContact
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? phone = null,Object? relationship = freezed,}) {
  return _then(EmergencyContact(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,relationship: freezed == relationship ? _self.relationship : relationship // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EmergencyContact].
extension EmergencyContactPatterns on EmergencyContact {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmergencyContact value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmergencyContact() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmergencyContact value)  $default,){
final _that = this;
switch (_that) {
case _EmergencyContact():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmergencyContact value)?  $default,){
final _that = this;
switch (_that) {
case _EmergencyContact() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String phone,  String? relationship)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmergencyContact() when $default != null:
return $default(_that.name,_that.phone,_that.relationship);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String phone,  String? relationship)  $default,) {final _that = this;
switch (_that) {
case _EmergencyContact():
return $default(_that.name,_that.phone,_that.relationship);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String phone,  String? relationship)?  $default,) {final _that = this;
switch (_that) {
case _EmergencyContact() when $default != null:
return $default(_that.name,_that.phone,_that.relationship);case _:
  return null;

}
}

}

/// @nodoc


class _EmergencyContact extends EmergencyContact {
  const _EmergencyContact({required this.name, required this.phone, this.relationship}): super._();
  

@override final  String name;
@override final  String phone;
@override final  String? relationship;

/// Create a copy of EmergencyContact
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmergencyContactCopyWith<_EmergencyContact> get copyWith => __$EmergencyContactCopyWithImpl<_EmergencyContact>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmergencyContact&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.relationship, relationship) || other.relationship == relationship));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,phone,relationship);
}

@override
String toString() {
    return 'EmergencyContact(name: $name, phone: $phone, relationship: $relationship)';
}


}

/// @nodoc
abstract mixin class _$EmergencyContactCopyWith<$Res> implements $EmergencyContactCopyWith<$Res> {
  factory _$EmergencyContactCopyWith(_EmergencyContact value, $Res Function(_EmergencyContact) _then) = __$EmergencyContactCopyWithImpl;
@override @useResult
$Res call({
 String name, String phone, String? relationship
});




}
/// @nodoc
class __$EmergencyContactCopyWithImpl<$Res>
    implements _$EmergencyContactCopyWith<$Res> {
  __$EmergencyContactCopyWithImpl(this._self, this._then);

  final _EmergencyContact _self;
  final $Res Function(_EmergencyContact) _then;

/// Create a copy of EmergencyContact
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? phone = null,Object? relationship = freezed,}) {
  return _then(_EmergencyContact(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,relationship: freezed == relationship ? _self.relationship : relationship // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$PlayerDetails {

 PlayerId get playerId; GroupId get groupId;/// 'YYYY-MM-DD': a calendar day, with no time or time zone.
 String? get dateOfBirth; List<EmergencyContact> get emergencyContacts;/// "Anything else coaches should know".
 String? get notes; String? get updatedBy; DateTime? get updatedAt;
/// Create a copy of PlayerDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerDetailsCopyWith<PlayerDetails> get copyWith => _$PlayerDetailsCopyWithImpl<PlayerDetails>(this as PlayerDetails, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlayerDetails;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerDetails&&(identical(other.playerId, _this.playerId) || other.playerId == _this.playerId)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.dateOfBirth, _this.dateOfBirth) || other.dateOfBirth == _this.dateOfBirth)&&const DeepCollectionEquality().equals(other.emergencyContacts, _this.emergencyContacts)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.updatedBy, _this.updatedBy) || other.updatedBy == _this.updatedBy)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}


@override
int get hashCode {
  final _this = this as PlayerDetails;
  return Object.hash(runtimeType,_this.playerId,_this.groupId,_this.dateOfBirth,const DeepCollectionEquality().hash(_this.emergencyContacts),_this.notes,_this.updatedBy,_this.updatedAt);
}

@override
String toString() {
  final _this = this as PlayerDetails;
  return 'PlayerDetails(playerId: ${_this.playerId}, groupId: ${_this.groupId}, dateOfBirth: ${_this.dateOfBirth}, emergencyContacts: ${_this.emergencyContacts}, notes: ${_this.notes}, updatedBy: ${_this.updatedBy}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $PlayerDetailsCopyWith<$Res>  {
  factory $PlayerDetailsCopyWith(PlayerDetails value, $Res Function(PlayerDetails) _then) = _$PlayerDetailsCopyWithImpl;
@useResult
$Res call({
 PlayerId playerId, GroupId groupId, String? dateOfBirth, List<EmergencyContact> emergencyContacts, String? notes, String? updatedBy, DateTime? updatedAt
});




}
/// @nodoc
class _$PlayerDetailsCopyWithImpl<$Res>
    implements $PlayerDetailsCopyWith<$Res> {
  _$PlayerDetailsCopyWithImpl(this._self, this._then);

  final PlayerDetails _self;
  final $Res Function(PlayerDetails) _then;

/// Create a copy of PlayerDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playerId = null,Object? groupId = null,Object? dateOfBirth = freezed,Object? emergencyContacts = null,Object? notes = freezed,Object? updatedBy = freezed,Object? updatedAt = freezed,}) {
  return _then(PlayerDetails(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as PlayerId,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String?,emergencyContacts: null == emergencyContacts ? _self.emergencyContacts : emergencyContacts // ignore: cast_nullable_to_non_nullable
as List<EmergencyContact>,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerDetails].
extension PlayerDetailsPatterns on PlayerDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerDetails value)  $default,){
final _that = this;
switch (_that) {
case _PlayerDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerDetails value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlayerId playerId,  GroupId groupId,  String? dateOfBirth,  List<EmergencyContact> emergencyContacts,  String? notes,  String? updatedBy,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerDetails() when $default != null:
return $default(_that.playerId,_that.groupId,_that.dateOfBirth,_that.emergencyContacts,_that.notes,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlayerId playerId,  GroupId groupId,  String? dateOfBirth,  List<EmergencyContact> emergencyContacts,  String? notes,  String? updatedBy,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PlayerDetails():
return $default(_that.playerId,_that.groupId,_that.dateOfBirth,_that.emergencyContacts,_that.notes,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlayerId playerId,  GroupId groupId,  String? dateOfBirth,  List<EmergencyContact> emergencyContacts,  String? notes,  String? updatedBy,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PlayerDetails() when $default != null:
return $default(_that.playerId,_that.groupId,_that.dateOfBirth,_that.emergencyContacts,_that.notes,_that.updatedBy,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _PlayerDetails extends PlayerDetails {
  const _PlayerDetails({required this.playerId, required this.groupId, this.dateOfBirth,  List<EmergencyContact> emergencyContacts = const <EmergencyContact>[], this.notes, this.updatedBy, this.updatedAt}): _emergencyContacts = emergencyContacts,super._();
  

@override final  PlayerId playerId;
@override final  GroupId groupId;
/// 'YYYY-MM-DD': a calendar day, with no time or time zone.
@override final  String? dateOfBirth;
 final  List<EmergencyContact> _emergencyContacts;
@override@JsonKey() List<EmergencyContact> get emergencyContacts {
  if (_emergencyContacts is EqualUnmodifiableListView) return _emergencyContacts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_emergencyContacts);
}

/// "Anything else coaches should know".
@override final  String? notes;
@override final  String? updatedBy;
@override final  DateTime? updatedAt;

/// Create a copy of PlayerDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerDetailsCopyWith<_PlayerDetails> get copyWith => __$PlayerDetailsCopyWithImpl<_PlayerDetails>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerDetails&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&const DeepCollectionEquality().equals(other.emergencyContacts, _emergencyContacts)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,playerId,groupId,dateOfBirth,const DeepCollectionEquality().hash(_emergencyContacts),notes,updatedBy,updatedAt);
}

@override
String toString() {
    return 'PlayerDetails(playerId: $playerId, groupId: $groupId, dateOfBirth: $dateOfBirth, emergencyContacts: $emergencyContacts, notes: $notes, updatedBy: $updatedBy, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PlayerDetailsCopyWith<$Res> implements $PlayerDetailsCopyWith<$Res> {
  factory _$PlayerDetailsCopyWith(_PlayerDetails value, $Res Function(_PlayerDetails) _then) = __$PlayerDetailsCopyWithImpl;
@override @useResult
$Res call({
 PlayerId playerId, GroupId groupId, String? dateOfBirth, List<EmergencyContact> emergencyContacts, String? notes, String? updatedBy, DateTime? updatedAt
});




}
/// @nodoc
class __$PlayerDetailsCopyWithImpl<$Res>
    implements _$PlayerDetailsCopyWith<$Res> {
  __$PlayerDetailsCopyWithImpl(this._self, this._then);

  final _PlayerDetails _self;
  final $Res Function(_PlayerDetails) _then;

/// Create a copy of PlayerDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playerId = null,Object? groupId = null,Object? dateOfBirth = freezed,Object? emergencyContacts = null,Object? notes = freezed,Object? updatedBy = freezed,Object? updatedAt = freezed,}) {
  return _then(_PlayerDetails(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as PlayerId,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String?,emergencyContacts: null == emergencyContacts ? _self._emergencyContacts : emergencyContacts // ignore: cast_nullable_to_non_nullable
as List<EmergencyContact>,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
