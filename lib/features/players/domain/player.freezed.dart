// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Player {

 PlayerId get id; GroupId get groupId; String get displayName; String? get jerseyNumber; String? get position;/// Pending until a team admin approves a member's new player
/// (PLAYER-4). Players without a status are active.
 PlayerStatus get status;/// Who added it, and how they said they're linked (PLAYER-4).
 String? get proposedBy; PlayerRelation? get proposedRelation;
/// Create a copy of Player
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerCopyWith<Player> get copyWith => _$PlayerCopyWithImpl<Player>(this as Player, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Player;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Player&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.jerseyNumber, _this.jerseyNumber) || other.jerseyNumber == _this.jerseyNumber)&&(identical(other.position, _this.position) || other.position == _this.position)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.proposedBy, _this.proposedBy) || other.proposedBy == _this.proposedBy)&&(identical(other.proposedRelation, _this.proposedRelation) || other.proposedRelation == _this.proposedRelation));
}


@override
int get hashCode {
  final _this = this as Player;
  return Object.hash(runtimeType,_this.id,_this.groupId,_this.displayName,_this.jerseyNumber,_this.position,_this.status,_this.proposedBy,_this.proposedRelation);
}

@override
String toString() {
  final _this = this as Player;
  return 'Player(id: ${_this.id}, groupId: ${_this.groupId}, displayName: ${_this.displayName}, jerseyNumber: ${_this.jerseyNumber}, position: ${_this.position}, status: ${_this.status}, proposedBy: ${_this.proposedBy}, proposedRelation: ${_this.proposedRelation})';
}


}

/// @nodoc
abstract mixin class $PlayerCopyWith<$Res>  {
  factory $PlayerCopyWith(Player value, $Res Function(Player) _then) = _$PlayerCopyWithImpl;
@useResult
$Res call({
 PlayerId id, GroupId groupId, String displayName, String? jerseyNumber, String? position, PlayerStatus status, String? proposedBy, PlayerRelation? proposedRelation
});




}
/// @nodoc
class _$PlayerCopyWithImpl<$Res>
    implements $PlayerCopyWith<$Res> {
  _$PlayerCopyWithImpl(this._self, this._then);

  final Player _self;
  final $Res Function(Player) _then;

/// Create a copy of Player
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? groupId = null,Object? displayName = null,Object? jerseyNumber = freezed,Object? position = freezed,Object? status = null,Object? proposedBy = freezed,Object? proposedRelation = freezed,}) {
  return _then(Player(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PlayerId,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,jerseyNumber: freezed == jerseyNumber ? _self.jerseyNumber : jerseyNumber // ignore: cast_nullable_to_non_nullable
as String?,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PlayerStatus,proposedBy: freezed == proposedBy ? _self.proposedBy : proposedBy // ignore: cast_nullable_to_non_nullable
as String?,proposedRelation: freezed == proposedRelation ? _self.proposedRelation : proposedRelation // ignore: cast_nullable_to_non_nullable
as PlayerRelation?,
  ));
}

}


/// Adds pattern-matching-related methods to [Player].
extension PlayerPatterns on Player {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Player value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Player() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Player value)  $default,){
final _that = this;
switch (_that) {
case _Player():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Player value)?  $default,){
final _that = this;
switch (_that) {
case _Player() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlayerId id,  GroupId groupId,  String displayName,  String? jerseyNumber,  String? position,  PlayerStatus status,  String? proposedBy,  PlayerRelation? proposedRelation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Player() when $default != null:
return $default(_that.id,_that.groupId,_that.displayName,_that.jerseyNumber,_that.position,_that.status,_that.proposedBy,_that.proposedRelation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlayerId id,  GroupId groupId,  String displayName,  String? jerseyNumber,  String? position,  PlayerStatus status,  String? proposedBy,  PlayerRelation? proposedRelation)  $default,) {final _that = this;
switch (_that) {
case _Player():
return $default(_that.id,_that.groupId,_that.displayName,_that.jerseyNumber,_that.position,_that.status,_that.proposedBy,_that.proposedRelation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlayerId id,  GroupId groupId,  String displayName,  String? jerseyNumber,  String? position,  PlayerStatus status,  String? proposedBy,  PlayerRelation? proposedRelation)?  $default,) {final _that = this;
switch (_that) {
case _Player() when $default != null:
return $default(_that.id,_that.groupId,_that.displayName,_that.jerseyNumber,_that.position,_that.status,_that.proposedBy,_that.proposedRelation);case _:
  return null;

}
}

}

/// @nodoc


class _Player extends Player {
  const _Player({required this.id, required this.groupId, required this.displayName, this.jerseyNumber, this.position, this.status = PlayerStatus.active, this.proposedBy, this.proposedRelation}): super._();
  

@override final  PlayerId id;
@override final  GroupId groupId;
@override final  String displayName;
@override final  String? jerseyNumber;
@override final  String? position;
/// Pending until a team admin approves a member's new player
/// (PLAYER-4). Players without a status are active.
@override@JsonKey() final  PlayerStatus status;
/// Who added it, and how they said they're linked (PLAYER-4).
@override final  String? proposedBy;
@override final  PlayerRelation? proposedRelation;

/// Create a copy of Player
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerCopyWith<_Player> get copyWith => __$PlayerCopyWithImpl<_Player>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Player&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.jerseyNumber, jerseyNumber) || other.jerseyNumber == jerseyNumber)&&(identical(other.position, position) || other.position == position)&&(identical(other.status, status) || other.status == status)&&(identical(other.proposedBy, proposedBy) || other.proposedBy == proposedBy)&&(identical(other.proposedRelation, proposedRelation) || other.proposedRelation == proposedRelation));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,groupId,displayName,jerseyNumber,position,status,proposedBy,proposedRelation);
}

@override
String toString() {
    return 'Player(id: $id, groupId: $groupId, displayName: $displayName, jerseyNumber: $jerseyNumber, position: $position, status: $status, proposedBy: $proposedBy, proposedRelation: $proposedRelation)';
}


}

/// @nodoc
abstract mixin class _$PlayerCopyWith<$Res> implements $PlayerCopyWith<$Res> {
  factory _$PlayerCopyWith(_Player value, $Res Function(_Player) _then) = __$PlayerCopyWithImpl;
@override @useResult
$Res call({
 PlayerId id, GroupId groupId, String displayName, String? jerseyNumber, String? position, PlayerStatus status, String? proposedBy, PlayerRelation? proposedRelation
});




}
/// @nodoc
class __$PlayerCopyWithImpl<$Res>
    implements _$PlayerCopyWith<$Res> {
  __$PlayerCopyWithImpl(this._self, this._then);

  final _Player _self;
  final $Res Function(_Player) _then;

/// Create a copy of Player
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? groupId = null,Object? displayName = null,Object? jerseyNumber = freezed,Object? position = freezed,Object? status = null,Object? proposedBy = freezed,Object? proposedRelation = freezed,}) {
  return _then(_Player(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PlayerId,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,jerseyNumber: freezed == jerseyNumber ? _self.jerseyNumber : jerseyNumber // ignore: cast_nullable_to_non_nullable
as String?,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PlayerStatus,proposedBy: freezed == proposedBy ? _self.proposedBy : proposedBy // ignore: cast_nullable_to_non_nullable
as String?,proposedRelation: freezed == proposedRelation ? _self.proposedRelation : proposedRelation // ignore: cast_nullable_to_non_nullable
as PlayerRelation?,
  ));
}


}

/// @nodoc
mixin _$GuardianLink {

 PlayerId get playerId; GroupId get groupId; UserId get uid; PlayerRelation get relation;
/// Create a copy of GuardianLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuardianLinkCopyWith<GuardianLink> get copyWith => _$GuardianLinkCopyWithImpl<GuardianLink>(this as GuardianLink, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GuardianLink;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuardianLink&&(identical(other.playerId, _this.playerId) || other.playerId == _this.playerId)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.uid, _this.uid) || other.uid == _this.uid)&&(identical(other.relation, _this.relation) || other.relation == _this.relation));
}


@override
int get hashCode {
  final _this = this as GuardianLink;
  return Object.hash(runtimeType,_this.playerId,_this.groupId,_this.uid,_this.relation);
}

@override
String toString() {
  final _this = this as GuardianLink;
  return 'GuardianLink(playerId: ${_this.playerId}, groupId: ${_this.groupId}, uid: ${_this.uid}, relation: ${_this.relation})';
}


}

/// @nodoc
abstract mixin class $GuardianLinkCopyWith<$Res>  {
  factory $GuardianLinkCopyWith(GuardianLink value, $Res Function(GuardianLink) _then) = _$GuardianLinkCopyWithImpl;
@useResult
$Res call({
 PlayerId playerId, GroupId groupId, UserId uid, PlayerRelation relation
});




}
/// @nodoc
class _$GuardianLinkCopyWithImpl<$Res>
    implements $GuardianLinkCopyWith<$Res> {
  _$GuardianLinkCopyWithImpl(this._self, this._then);

  final GuardianLink _self;
  final $Res Function(GuardianLink) _then;

/// Create a copy of GuardianLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playerId = null,Object? groupId = null,Object? uid = null,Object? relation = null,}) {
  return _then(GuardianLink(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as PlayerId,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as UserId,relation: null == relation ? _self.relation : relation // ignore: cast_nullable_to_non_nullable
as PlayerRelation,
  ));
}

}


/// Adds pattern-matching-related methods to [GuardianLink].
extension GuardianLinkPatterns on GuardianLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuardianLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuardianLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuardianLink value)  $default,){
final _that = this;
switch (_that) {
case _GuardianLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuardianLink value)?  $default,){
final _that = this;
switch (_that) {
case _GuardianLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlayerId playerId,  GroupId groupId,  UserId uid,  PlayerRelation relation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuardianLink() when $default != null:
return $default(_that.playerId,_that.groupId,_that.uid,_that.relation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlayerId playerId,  GroupId groupId,  UserId uid,  PlayerRelation relation)  $default,) {final _that = this;
switch (_that) {
case _GuardianLink():
return $default(_that.playerId,_that.groupId,_that.uid,_that.relation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlayerId playerId,  GroupId groupId,  UserId uid,  PlayerRelation relation)?  $default,) {final _that = this;
switch (_that) {
case _GuardianLink() when $default != null:
return $default(_that.playerId,_that.groupId,_that.uid,_that.relation);case _:
  return null;

}
}

}

/// @nodoc


class _GuardianLink extends GuardianLink {
  const _GuardianLink({required this.playerId, required this.groupId, required this.uid, this.relation = PlayerRelation.guardian}): super._();
  

@override final  PlayerId playerId;
@override final  GroupId groupId;
@override final  UserId uid;
@override@JsonKey() final  PlayerRelation relation;

/// Create a copy of GuardianLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuardianLinkCopyWith<_GuardianLink> get copyWith => __$GuardianLinkCopyWithImpl<_GuardianLink>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuardianLink&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.relation, relation) || other.relation == relation));
}


@override
int get hashCode {
    return Object.hash(runtimeType,playerId,groupId,uid,relation);
}

@override
String toString() {
    return 'GuardianLink(playerId: $playerId, groupId: $groupId, uid: $uid, relation: $relation)';
}


}

/// @nodoc
abstract mixin class _$GuardianLinkCopyWith<$Res> implements $GuardianLinkCopyWith<$Res> {
  factory _$GuardianLinkCopyWith(_GuardianLink value, $Res Function(_GuardianLink) _then) = __$GuardianLinkCopyWithImpl;
@override @useResult
$Res call({
 PlayerId playerId, GroupId groupId, UserId uid, PlayerRelation relation
});




}
/// @nodoc
class __$GuardianLinkCopyWithImpl<$Res>
    implements _$GuardianLinkCopyWith<$Res> {
  __$GuardianLinkCopyWithImpl(this._self, this._then);

  final _GuardianLink _self;
  final $Res Function(_GuardianLink) _then;

/// Create a copy of GuardianLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playerId = null,Object? groupId = null,Object? uid = null,Object? relation = null,}) {
  return _then(_GuardianLink(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as PlayerId,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as UserId,relation: null == relation ? _self.relation : relation // ignore: cast_nullable_to_non_nullable
as PlayerRelation,
  ));
}


}

/// @nodoc
mixin _$NewGuardian {

 String? get name; String? get email;
/// Create a copy of NewGuardian
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewGuardianCopyWith<NewGuardian> get copyWith => _$NewGuardianCopyWithImpl<NewGuardian>(this as NewGuardian, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as NewGuardian;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewGuardian&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.email, _this.email) || other.email == _this.email));
}


@override
int get hashCode {
  final _this = this as NewGuardian;
  return Object.hash(runtimeType,_this.name,_this.email);
}

@override
String toString() {
  final _this = this as NewGuardian;
  return 'NewGuardian(name: ${_this.name}, email: ${_this.email})';
}


}

/// @nodoc
abstract mixin class $NewGuardianCopyWith<$Res>  {
  factory $NewGuardianCopyWith(NewGuardian value, $Res Function(NewGuardian) _then) = _$NewGuardianCopyWithImpl;
@useResult
$Res call({
 String? name, String? email
});




}
/// @nodoc
class _$NewGuardianCopyWithImpl<$Res>
    implements $NewGuardianCopyWith<$Res> {
  _$NewGuardianCopyWithImpl(this._self, this._then);

  final NewGuardian _self;
  final $Res Function(NewGuardian) _then;

/// Create a copy of NewGuardian
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? email = freezed,}) {
  return _then(NewGuardian(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NewGuardian].
extension NewGuardianPatterns on NewGuardian {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewGuardian value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewGuardian() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewGuardian value)  $default,){
final _that = this;
switch (_that) {
case _NewGuardian():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewGuardian value)?  $default,){
final _that = this;
switch (_that) {
case _NewGuardian() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name,  String? email)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewGuardian() when $default != null:
return $default(_that.name,_that.email);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name,  String? email)  $default,) {final _that = this;
switch (_that) {
case _NewGuardian():
return $default(_that.name,_that.email);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name,  String? email)?  $default,) {final _that = this;
switch (_that) {
case _NewGuardian() when $default != null:
return $default(_that.name,_that.email);case _:
  return null;

}
}

}

/// @nodoc


class _NewGuardian implements NewGuardian {
  const _NewGuardian({this.name, this.email});
  

@override final  String? name;
@override final  String? email;

/// Create a copy of NewGuardian
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewGuardianCopyWith<_NewGuardian> get copyWith => __$NewGuardianCopyWithImpl<_NewGuardian>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewGuardian&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,email);
}

@override
String toString() {
    return 'NewGuardian(name: $name, email: $email)';
}


}

/// @nodoc
abstract mixin class _$NewGuardianCopyWith<$Res> implements $NewGuardianCopyWith<$Res> {
  factory _$NewGuardianCopyWith(_NewGuardian value, $Res Function(_NewGuardian) _then) = __$NewGuardianCopyWithImpl;
@override @useResult
$Res call({
 String? name, String? email
});




}
/// @nodoc
class __$NewGuardianCopyWithImpl<$Res>
    implements _$NewGuardianCopyWith<$Res> {
  __$NewGuardianCopyWithImpl(this._self, this._then);

  final _NewGuardian _self;
  final $Res Function(_NewGuardian) _then;

/// Create a copy of NewGuardian
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? email = freezed,}) {
  return _then(_NewGuardian(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$NewPlayer {

 String get name; String? get jerseyNumber; String? get position; String? get email; List<NewGuardian> get guardians;
/// Create a copy of NewPlayer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewPlayerCopyWith<NewPlayer> get copyWith => _$NewPlayerCopyWithImpl<NewPlayer>(this as NewPlayer, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as NewPlayer;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewPlayer&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.jerseyNumber, _this.jerseyNumber) || other.jerseyNumber == _this.jerseyNumber)&&(identical(other.position, _this.position) || other.position == _this.position)&&(identical(other.email, _this.email) || other.email == _this.email)&&const DeepCollectionEquality().equals(other.guardians, _this.guardians));
}


@override
int get hashCode {
  final _this = this as NewPlayer;
  return Object.hash(runtimeType,_this.name,_this.jerseyNumber,_this.position,_this.email,const DeepCollectionEquality().hash(_this.guardians));
}

@override
String toString() {
  final _this = this as NewPlayer;
  return 'NewPlayer(name: ${_this.name}, jerseyNumber: ${_this.jerseyNumber}, position: ${_this.position}, email: ${_this.email}, guardians: ${_this.guardians})';
}


}

/// @nodoc
abstract mixin class $NewPlayerCopyWith<$Res>  {
  factory $NewPlayerCopyWith(NewPlayer value, $Res Function(NewPlayer) _then) = _$NewPlayerCopyWithImpl;
@useResult
$Res call({
 String name, String? jerseyNumber, String? position, String? email, List<NewGuardian> guardians
});




}
/// @nodoc
class _$NewPlayerCopyWithImpl<$Res>
    implements $NewPlayerCopyWith<$Res> {
  _$NewPlayerCopyWithImpl(this._self, this._then);

  final NewPlayer _self;
  final $Res Function(NewPlayer) _then;

/// Create a copy of NewPlayer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? jerseyNumber = freezed,Object? position = freezed,Object? email = freezed,Object? guardians = null,}) {
  return _then(NewPlayer(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,jerseyNumber: freezed == jerseyNumber ? _self.jerseyNumber : jerseyNumber // ignore: cast_nullable_to_non_nullable
as String?,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,guardians: null == guardians ? _self.guardians : guardians // ignore: cast_nullable_to_non_nullable
as List<NewGuardian>,
  ));
}

}


/// Adds pattern-matching-related methods to [NewPlayer].
extension NewPlayerPatterns on NewPlayer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewPlayer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewPlayer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewPlayer value)  $default,){
final _that = this;
switch (_that) {
case _NewPlayer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewPlayer value)?  $default,){
final _that = this;
switch (_that) {
case _NewPlayer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? jerseyNumber,  String? position,  String? email,  List<NewGuardian> guardians)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewPlayer() when $default != null:
return $default(_that.name,_that.jerseyNumber,_that.position,_that.email,_that.guardians);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? jerseyNumber,  String? position,  String? email,  List<NewGuardian> guardians)  $default,) {final _that = this;
switch (_that) {
case _NewPlayer():
return $default(_that.name,_that.jerseyNumber,_that.position,_that.email,_that.guardians);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? jerseyNumber,  String? position,  String? email,  List<NewGuardian> guardians)?  $default,) {final _that = this;
switch (_that) {
case _NewPlayer() when $default != null:
return $default(_that.name,_that.jerseyNumber,_that.position,_that.email,_that.guardians);case _:
  return null;

}
}

}

/// @nodoc


class _NewPlayer implements NewPlayer {
  const _NewPlayer({required this.name, this.jerseyNumber, this.position, this.email,  List<NewGuardian> guardians = const <NewGuardian>[]}): _guardians = guardians;
  

@override final  String name;
@override final  String? jerseyNumber;
@override final  String? position;
@override final  String? email;
 final  List<NewGuardian> _guardians;
@override@JsonKey() List<NewGuardian> get guardians {
  if (_guardians is EqualUnmodifiableListView) return _guardians;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_guardians);
}


/// Create a copy of NewPlayer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewPlayerCopyWith<_NewPlayer> get copyWith => __$NewPlayerCopyWithImpl<_NewPlayer>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewPlayer&&(identical(other.name, name) || other.name == name)&&(identical(other.jerseyNumber, jerseyNumber) || other.jerseyNumber == jerseyNumber)&&(identical(other.position, position) || other.position == position)&&(identical(other.email, email) || other.email == email)&&const DeepCollectionEquality().equals(other.guardians, _guardians));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,jerseyNumber,position,email,const DeepCollectionEquality().hash(_guardians));
}

@override
String toString() {
    return 'NewPlayer(name: $name, jerseyNumber: $jerseyNumber, position: $position, email: $email, guardians: $guardians)';
}


}

/// @nodoc
abstract mixin class _$NewPlayerCopyWith<$Res> implements $NewPlayerCopyWith<$Res> {
  factory _$NewPlayerCopyWith(_NewPlayer value, $Res Function(_NewPlayer) _then) = __$NewPlayerCopyWithImpl;
@override @useResult
$Res call({
 String name, String? jerseyNumber, String? position, String? email, List<NewGuardian> guardians
});




}
/// @nodoc
class __$NewPlayerCopyWithImpl<$Res>
    implements _$NewPlayerCopyWith<$Res> {
  __$NewPlayerCopyWithImpl(this._self, this._then);

  final _NewPlayer _self;
  final $Res Function(_NewPlayer) _then;

/// Create a copy of NewPlayer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? jerseyNumber = freezed,Object? position = freezed,Object? email = freezed,Object? guardians = null,}) {
  return _then(_NewPlayer(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,jerseyNumber: freezed == jerseyNumber ? _self.jerseyNumber : jerseyNumber // ignore: cast_nullable_to_non_nullable
as String?,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,guardians: null == guardians ? _self._guardians : guardians // ignore: cast_nullable_to_non_nullable
as List<NewGuardian>,
  ));
}


}

/// @nodoc
mixin _$AddPlayersResult {

 int get playersAdded; int get guardiansLinked; int get guardiansInvited;/// Players linked as themselves by their own email: to an account they
/// had, or a new one that got a setup email (PLAYER-1).
 int get playersLinked; int get playersInvited;/// Guardians given a name and no email, "Emma: Maria R.": nobody can be
/// linked without an email, so they're listed instead (PLAYER-1).
 List<String> get guardiansWithoutEmail;/// "Emma: maria@example.com", with the reason when there is one, such
/// as " (too-many-teams)" for someone on 100 teams already (TEAM-2) or
/// " (already-a-player)" (PLAYER-3); see describeAddProblem.
 List<String> get problems;
/// Create a copy of AddPlayersResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddPlayersResultCopyWith<AddPlayersResult> get copyWith => _$AddPlayersResultCopyWithImpl<AddPlayersResult>(this as AddPlayersResult, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AddPlayersResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddPlayersResult&&(identical(other.playersAdded, _this.playersAdded) || other.playersAdded == _this.playersAdded)&&(identical(other.guardiansLinked, _this.guardiansLinked) || other.guardiansLinked == _this.guardiansLinked)&&(identical(other.guardiansInvited, _this.guardiansInvited) || other.guardiansInvited == _this.guardiansInvited)&&(identical(other.playersLinked, _this.playersLinked) || other.playersLinked == _this.playersLinked)&&(identical(other.playersInvited, _this.playersInvited) || other.playersInvited == _this.playersInvited)&&const DeepCollectionEquality().equals(other.guardiansWithoutEmail, _this.guardiansWithoutEmail)&&const DeepCollectionEquality().equals(other.problems, _this.problems));
}


@override
int get hashCode {
  final _this = this as AddPlayersResult;
  return Object.hash(runtimeType,_this.playersAdded,_this.guardiansLinked,_this.guardiansInvited,_this.playersLinked,_this.playersInvited,const DeepCollectionEquality().hash(_this.guardiansWithoutEmail),const DeepCollectionEquality().hash(_this.problems));
}

@override
String toString() {
  final _this = this as AddPlayersResult;
  return 'AddPlayersResult(playersAdded: ${_this.playersAdded}, guardiansLinked: ${_this.guardiansLinked}, guardiansInvited: ${_this.guardiansInvited}, playersLinked: ${_this.playersLinked}, playersInvited: ${_this.playersInvited}, guardiansWithoutEmail: ${_this.guardiansWithoutEmail}, problems: ${_this.problems})';
}


}

/// @nodoc
abstract mixin class $AddPlayersResultCopyWith<$Res>  {
  factory $AddPlayersResultCopyWith(AddPlayersResult value, $Res Function(AddPlayersResult) _then) = _$AddPlayersResultCopyWithImpl;
@useResult
$Res call({
 int playersAdded, int guardiansLinked, int guardiansInvited, int playersLinked, int playersInvited, List<String> guardiansWithoutEmail, List<String> problems
});




}
/// @nodoc
class _$AddPlayersResultCopyWithImpl<$Res>
    implements $AddPlayersResultCopyWith<$Res> {
  _$AddPlayersResultCopyWithImpl(this._self, this._then);

  final AddPlayersResult _self;
  final $Res Function(AddPlayersResult) _then;

/// Create a copy of AddPlayersResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playersAdded = null,Object? guardiansLinked = null,Object? guardiansInvited = null,Object? playersLinked = null,Object? playersInvited = null,Object? guardiansWithoutEmail = null,Object? problems = null,}) {
  return _then(AddPlayersResult(
playersAdded: null == playersAdded ? _self.playersAdded : playersAdded // ignore: cast_nullable_to_non_nullable
as int,guardiansLinked: null == guardiansLinked ? _self.guardiansLinked : guardiansLinked // ignore: cast_nullable_to_non_nullable
as int,guardiansInvited: null == guardiansInvited ? _self.guardiansInvited : guardiansInvited // ignore: cast_nullable_to_non_nullable
as int,playersLinked: null == playersLinked ? _self.playersLinked : playersLinked // ignore: cast_nullable_to_non_nullable
as int,playersInvited: null == playersInvited ? _self.playersInvited : playersInvited // ignore: cast_nullable_to_non_nullable
as int,guardiansWithoutEmail: null == guardiansWithoutEmail ? _self.guardiansWithoutEmail : guardiansWithoutEmail // ignore: cast_nullable_to_non_nullable
as List<String>,problems: null == problems ? _self.problems : problems // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [AddPlayersResult].
extension AddPlayersResultPatterns on AddPlayersResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AddPlayersResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AddPlayersResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AddPlayersResult value)  $default,){
final _that = this;
switch (_that) {
case _AddPlayersResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AddPlayersResult value)?  $default,){
final _that = this;
switch (_that) {
case _AddPlayersResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int playersAdded,  int guardiansLinked,  int guardiansInvited,  int playersLinked,  int playersInvited,  List<String> guardiansWithoutEmail,  List<String> problems)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AddPlayersResult() when $default != null:
return $default(_that.playersAdded,_that.guardiansLinked,_that.guardiansInvited,_that.playersLinked,_that.playersInvited,_that.guardiansWithoutEmail,_that.problems);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int playersAdded,  int guardiansLinked,  int guardiansInvited,  int playersLinked,  int playersInvited,  List<String> guardiansWithoutEmail,  List<String> problems)  $default,) {final _that = this;
switch (_that) {
case _AddPlayersResult():
return $default(_that.playersAdded,_that.guardiansLinked,_that.guardiansInvited,_that.playersLinked,_that.playersInvited,_that.guardiansWithoutEmail,_that.problems);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int playersAdded,  int guardiansLinked,  int guardiansInvited,  int playersLinked,  int playersInvited,  List<String> guardiansWithoutEmail,  List<String> problems)?  $default,) {final _that = this;
switch (_that) {
case _AddPlayersResult() when $default != null:
return $default(_that.playersAdded,_that.guardiansLinked,_that.guardiansInvited,_that.playersLinked,_that.playersInvited,_that.guardiansWithoutEmail,_that.problems);case _:
  return null;

}
}

}

/// @nodoc


class _AddPlayersResult implements AddPlayersResult {
  const _AddPlayersResult({required this.playersAdded, required this.guardiansLinked, required this.guardiansInvited, this.playersLinked = 0, this.playersInvited = 0,  List<String> guardiansWithoutEmail = const <String>[],  List<String> problems = const <String>[]}): _guardiansWithoutEmail = guardiansWithoutEmail,_problems = problems;
  

@override final  int playersAdded;
@override final  int guardiansLinked;
@override final  int guardiansInvited;
/// Players linked as themselves by their own email: to an account they
/// had, or a new one that got a setup email (PLAYER-1).
@override@JsonKey() final  int playersLinked;
@override@JsonKey() final  int playersInvited;
/// Guardians given a name and no email, "Emma: Maria R.": nobody can be
/// linked without an email, so they're listed instead (PLAYER-1).
 final  List<String> _guardiansWithoutEmail;
/// Guardians given a name and no email, "Emma: Maria R.": nobody can be
/// linked without an email, so they're listed instead (PLAYER-1).
@override@JsonKey() List<String> get guardiansWithoutEmail {
  if (_guardiansWithoutEmail is EqualUnmodifiableListView) return _guardiansWithoutEmail;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_guardiansWithoutEmail);
}

/// "Emma: maria@example.com", with the reason when there is one, such
/// as " (too-many-teams)" for someone on 100 teams already (TEAM-2) or
/// " (already-a-player)" (PLAYER-3); see describeAddProblem.
 final  List<String> _problems;
/// "Emma: maria@example.com", with the reason when there is one, such
/// as " (too-many-teams)" for someone on 100 teams already (TEAM-2) or
/// " (already-a-player)" (PLAYER-3); see describeAddProblem.
@override@JsonKey() List<String> get problems {
  if (_problems is EqualUnmodifiableListView) return _problems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_problems);
}


/// Create a copy of AddPlayersResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddPlayersResultCopyWith<_AddPlayersResult> get copyWith => __$AddPlayersResultCopyWithImpl<_AddPlayersResult>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddPlayersResult&&(identical(other.playersAdded, playersAdded) || other.playersAdded == playersAdded)&&(identical(other.guardiansLinked, guardiansLinked) || other.guardiansLinked == guardiansLinked)&&(identical(other.guardiansInvited, guardiansInvited) || other.guardiansInvited == guardiansInvited)&&(identical(other.playersLinked, playersLinked) || other.playersLinked == playersLinked)&&(identical(other.playersInvited, playersInvited) || other.playersInvited == playersInvited)&&const DeepCollectionEquality().equals(other.guardiansWithoutEmail, _guardiansWithoutEmail)&&const DeepCollectionEquality().equals(other.problems, _problems));
}


@override
int get hashCode {
    return Object.hash(runtimeType,playersAdded,guardiansLinked,guardiansInvited,playersLinked,playersInvited,const DeepCollectionEquality().hash(_guardiansWithoutEmail),const DeepCollectionEquality().hash(_problems));
}

@override
String toString() {
    return 'AddPlayersResult(playersAdded: $playersAdded, guardiansLinked: $guardiansLinked, guardiansInvited: $guardiansInvited, playersLinked: $playersLinked, playersInvited: $playersInvited, guardiansWithoutEmail: $guardiansWithoutEmail, problems: $problems)';
}


}

/// @nodoc
abstract mixin class _$AddPlayersResultCopyWith<$Res> implements $AddPlayersResultCopyWith<$Res> {
  factory _$AddPlayersResultCopyWith(_AddPlayersResult value, $Res Function(_AddPlayersResult) _then) = __$AddPlayersResultCopyWithImpl;
@override @useResult
$Res call({
 int playersAdded, int guardiansLinked, int guardiansInvited, int playersLinked, int playersInvited, List<String> guardiansWithoutEmail, List<String> problems
});




}
/// @nodoc
class __$AddPlayersResultCopyWithImpl<$Res>
    implements _$AddPlayersResultCopyWith<$Res> {
  __$AddPlayersResultCopyWithImpl(this._self, this._then);

  final _AddPlayersResult _self;
  final $Res Function(_AddPlayersResult) _then;

/// Create a copy of AddPlayersResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playersAdded = null,Object? guardiansLinked = null,Object? guardiansInvited = null,Object? playersLinked = null,Object? playersInvited = null,Object? guardiansWithoutEmail = null,Object? problems = null,}) {
  return _then(_AddPlayersResult(
playersAdded: null == playersAdded ? _self.playersAdded : playersAdded // ignore: cast_nullable_to_non_nullable
as int,guardiansLinked: null == guardiansLinked ? _self.guardiansLinked : guardiansLinked // ignore: cast_nullable_to_non_nullable
as int,guardiansInvited: null == guardiansInvited ? _self.guardiansInvited : guardiansInvited // ignore: cast_nullable_to_non_nullable
as int,playersLinked: null == playersLinked ? _self.playersLinked : playersLinked // ignore: cast_nullable_to_non_nullable
as int,playersInvited: null == playersInvited ? _self.playersInvited : playersInvited // ignore: cast_nullable_to_non_nullable
as int,guardiansWithoutEmail: null == guardiansWithoutEmail ? _self._guardiansWithoutEmail : guardiansWithoutEmail // ignore: cast_nullable_to_non_nullable
as List<String>,problems: null == problems ? _self._problems : problems // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$GuardianRequest {

 PlayerId get playerId; GroupId get groupId; UserId get uid; GuardianRequestStatus get status; PlayerRelation get relation;
/// Create a copy of GuardianRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuardianRequestCopyWith<GuardianRequest> get copyWith => _$GuardianRequestCopyWithImpl<GuardianRequest>(this as GuardianRequest, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GuardianRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuardianRequest&&(identical(other.playerId, _this.playerId) || other.playerId == _this.playerId)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.uid, _this.uid) || other.uid == _this.uid)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.relation, _this.relation) || other.relation == _this.relation));
}


@override
int get hashCode {
  final _this = this as GuardianRequest;
  return Object.hash(runtimeType,_this.playerId,_this.groupId,_this.uid,_this.status,_this.relation);
}

@override
String toString() {
  final _this = this as GuardianRequest;
  return 'GuardianRequest(playerId: ${_this.playerId}, groupId: ${_this.groupId}, uid: ${_this.uid}, status: ${_this.status}, relation: ${_this.relation})';
}


}

/// @nodoc
abstract mixin class $GuardianRequestCopyWith<$Res>  {
  factory $GuardianRequestCopyWith(GuardianRequest value, $Res Function(GuardianRequest) _then) = _$GuardianRequestCopyWithImpl;
@useResult
$Res call({
 PlayerId playerId, GroupId groupId, UserId uid, GuardianRequestStatus status, PlayerRelation relation
});




}
/// @nodoc
class _$GuardianRequestCopyWithImpl<$Res>
    implements $GuardianRequestCopyWith<$Res> {
  _$GuardianRequestCopyWithImpl(this._self, this._then);

  final GuardianRequest _self;
  final $Res Function(GuardianRequest) _then;

/// Create a copy of GuardianRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playerId = null,Object? groupId = null,Object? uid = null,Object? status = null,Object? relation = null,}) {
  return _then(GuardianRequest(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as PlayerId,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as UserId,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GuardianRequestStatus,relation: null == relation ? _self.relation : relation // ignore: cast_nullable_to_non_nullable
as PlayerRelation,
  ));
}

}


/// Adds pattern-matching-related methods to [GuardianRequest].
extension GuardianRequestPatterns on GuardianRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuardianRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuardianRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuardianRequest value)  $default,){
final _that = this;
switch (_that) {
case _GuardianRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuardianRequest value)?  $default,){
final _that = this;
switch (_that) {
case _GuardianRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlayerId playerId,  GroupId groupId,  UserId uid,  GuardianRequestStatus status,  PlayerRelation relation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuardianRequest() when $default != null:
return $default(_that.playerId,_that.groupId,_that.uid,_that.status,_that.relation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlayerId playerId,  GroupId groupId,  UserId uid,  GuardianRequestStatus status,  PlayerRelation relation)  $default,) {final _that = this;
switch (_that) {
case _GuardianRequest():
return $default(_that.playerId,_that.groupId,_that.uid,_that.status,_that.relation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlayerId playerId,  GroupId groupId,  UserId uid,  GuardianRequestStatus status,  PlayerRelation relation)?  $default,) {final _that = this;
switch (_that) {
case _GuardianRequest() when $default != null:
return $default(_that.playerId,_that.groupId,_that.uid,_that.status,_that.relation);case _:
  return null;

}
}

}

/// @nodoc


class _GuardianRequest implements GuardianRequest {
  const _GuardianRequest({required this.playerId, required this.groupId, required this.uid, required this.status, this.relation = PlayerRelation.guardian});
  

@override final  PlayerId playerId;
@override final  GroupId groupId;
@override final  UserId uid;
@override final  GuardianRequestStatus status;
@override@JsonKey() final  PlayerRelation relation;

/// Create a copy of GuardianRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuardianRequestCopyWith<_GuardianRequest> get copyWith => __$GuardianRequestCopyWithImpl<_GuardianRequest>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuardianRequest&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.status, status) || other.status == status)&&(identical(other.relation, relation) || other.relation == relation));
}


@override
int get hashCode {
    return Object.hash(runtimeType,playerId,groupId,uid,status,relation);
}

@override
String toString() {
    return 'GuardianRequest(playerId: $playerId, groupId: $groupId, uid: $uid, status: $status, relation: $relation)';
}


}

/// @nodoc
abstract mixin class _$GuardianRequestCopyWith<$Res> implements $GuardianRequestCopyWith<$Res> {
  factory _$GuardianRequestCopyWith(_GuardianRequest value, $Res Function(_GuardianRequest) _then) = __$GuardianRequestCopyWithImpl;
@override @useResult
$Res call({
 PlayerId playerId, GroupId groupId, UserId uid, GuardianRequestStatus status, PlayerRelation relation
});




}
/// @nodoc
class __$GuardianRequestCopyWithImpl<$Res>
    implements _$GuardianRequestCopyWith<$Res> {
  __$GuardianRequestCopyWithImpl(this._self, this._then);

  final _GuardianRequest _self;
  final $Res Function(_GuardianRequest) _then;

/// Create a copy of GuardianRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playerId = null,Object? groupId = null,Object? uid = null,Object? status = null,Object? relation = null,}) {
  return _then(_GuardianRequest(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as PlayerId,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as UserId,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GuardianRequestStatus,relation: null == relation ? _self.relation : relation // ignore: cast_nullable_to_non_nullable
as PlayerRelation,
  ));
}


}

// dart format on
