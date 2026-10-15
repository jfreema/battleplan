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

 PlayerId get id; GroupId get groupId; String get displayName; String? get jerseyNumber;/// Pending until a team admin approves a member's new player
/// (PLAYER-4). Players without a status are active.
 PlayerStatus get status;/// Who added it, and how they said they're linked (PLAYER-4).
 String? get proposedBy; PlayerRelation? get proposedRelation;/// When it was added to the roster, so its RSVP history starts there
/// (PLAYER-11). Null on records read without it.
 DateTime? get addedAt;
/// Create a copy of Player
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerCopyWith<Player> get copyWith => _$PlayerCopyWithImpl<Player>(this as Player, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Player;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Player&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.jerseyNumber, _this.jerseyNumber) || other.jerseyNumber == _this.jerseyNumber)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.proposedBy, _this.proposedBy) || other.proposedBy == _this.proposedBy)&&(identical(other.proposedRelation, _this.proposedRelation) || other.proposedRelation == _this.proposedRelation)&&(identical(other.addedAt, _this.addedAt) || other.addedAt == _this.addedAt));
}


@override
int get hashCode {
  final _this = this as Player;
  return Object.hash(runtimeType,_this.id,_this.groupId,_this.displayName,_this.jerseyNumber,_this.status,_this.proposedBy,_this.proposedRelation,_this.addedAt);
}

@override
String toString() {
  final _this = this as Player;
  return 'Player(id: ${_this.id}, groupId: ${_this.groupId}, displayName: ${_this.displayName}, jerseyNumber: ${_this.jerseyNumber}, status: ${_this.status}, proposedBy: ${_this.proposedBy}, proposedRelation: ${_this.proposedRelation}, addedAt: ${_this.addedAt})';
}


}

/// @nodoc
abstract mixin class $PlayerCopyWith<$Res>  {
  factory $PlayerCopyWith(Player value, $Res Function(Player) _then) = _$PlayerCopyWithImpl;
@useResult
$Res call({
 PlayerId id, GroupId groupId, String displayName, String? jerseyNumber, PlayerStatus status, String? proposedBy, PlayerRelation? proposedRelation, DateTime? addedAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? groupId = null,Object? displayName = null,Object? jerseyNumber = freezed,Object? status = null,Object? proposedBy = freezed,Object? proposedRelation = freezed,Object? addedAt = freezed,}) {
  return _then(Player(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PlayerId,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,jerseyNumber: freezed == jerseyNumber ? _self.jerseyNumber : jerseyNumber // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PlayerStatus,proposedBy: freezed == proposedBy ? _self.proposedBy : proposedBy // ignore: cast_nullable_to_non_nullable
as String?,proposedRelation: freezed == proposedRelation ? _self.proposedRelation : proposedRelation // ignore: cast_nullable_to_non_nullable
as PlayerRelation?,addedAt: freezed == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlayerId id,  GroupId groupId,  String displayName,  String? jerseyNumber,  PlayerStatus status,  String? proposedBy,  PlayerRelation? proposedRelation,  DateTime? addedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Player() when $default != null:
return $default(_that.id,_that.groupId,_that.displayName,_that.jerseyNumber,_that.status,_that.proposedBy,_that.proposedRelation,_that.addedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlayerId id,  GroupId groupId,  String displayName,  String? jerseyNumber,  PlayerStatus status,  String? proposedBy,  PlayerRelation? proposedRelation,  DateTime? addedAt)  $default,) {final _that = this;
switch (_that) {
case _Player():
return $default(_that.id,_that.groupId,_that.displayName,_that.jerseyNumber,_that.status,_that.proposedBy,_that.proposedRelation,_that.addedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlayerId id,  GroupId groupId,  String displayName,  String? jerseyNumber,  PlayerStatus status,  String? proposedBy,  PlayerRelation? proposedRelation,  DateTime? addedAt)?  $default,) {final _that = this;
switch (_that) {
case _Player() when $default != null:
return $default(_that.id,_that.groupId,_that.displayName,_that.jerseyNumber,_that.status,_that.proposedBy,_that.proposedRelation,_that.addedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Player extends Player {
  const _Player({required this.id, required this.groupId, required this.displayName, this.jerseyNumber, this.status = PlayerStatus.active, this.proposedBy, this.proposedRelation, this.addedAt}): super._();
  

@override final  PlayerId id;
@override final  GroupId groupId;
@override final  String displayName;
@override final  String? jerseyNumber;
/// Pending until a team admin approves a member's new player
/// (PLAYER-4). Players without a status are active.
@override@JsonKey() final  PlayerStatus status;
/// Who added it, and how they said they're linked (PLAYER-4).
@override final  String? proposedBy;
@override final  PlayerRelation? proposedRelation;
/// When it was added to the roster, so its RSVP history starts there
/// (PLAYER-11). Null on records read without it.
@override final  DateTime? addedAt;

/// Create a copy of Player
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerCopyWith<_Player> get copyWith => __$PlayerCopyWithImpl<_Player>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Player&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.jerseyNumber, jerseyNumber) || other.jerseyNumber == jerseyNumber)&&(identical(other.status, status) || other.status == status)&&(identical(other.proposedBy, proposedBy) || other.proposedBy == proposedBy)&&(identical(other.proposedRelation, proposedRelation) || other.proposedRelation == proposedRelation)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,groupId,displayName,jerseyNumber,status,proposedBy,proposedRelation,addedAt);
}

@override
String toString() {
    return 'Player(id: $id, groupId: $groupId, displayName: $displayName, jerseyNumber: $jerseyNumber, status: $status, proposedBy: $proposedBy, proposedRelation: $proposedRelation, addedAt: $addedAt)';
}


}

/// @nodoc
abstract mixin class _$PlayerCopyWith<$Res> implements $PlayerCopyWith<$Res> {
  factory _$PlayerCopyWith(_Player value, $Res Function(_Player) _then) = __$PlayerCopyWithImpl;
@override @useResult
$Res call({
 PlayerId id, GroupId groupId, String displayName, String? jerseyNumber, PlayerStatus status, String? proposedBy, PlayerRelation? proposedRelation, DateTime? addedAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? groupId = null,Object? displayName = null,Object? jerseyNumber = freezed,Object? status = null,Object? proposedBy = freezed,Object? proposedRelation = freezed,Object? addedAt = freezed,}) {
  return _then(_Player(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PlayerId,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,jerseyNumber: freezed == jerseyNumber ? _self.jerseyNumber : jerseyNumber // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PlayerStatus,proposedBy: freezed == proposedBy ? _self.proposedBy : proposedBy // ignore: cast_nullable_to_non_nullable
as String?,proposedRelation: freezed == proposedRelation ? _self.proposedRelation : proposedRelation // ignore: cast_nullable_to_non_nullable
as PlayerRelation?,addedAt: freezed == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
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
mixin _$NewPlayer {

 String get name; String? get jerseyNumber;/// 'YYYY-MM-DD' (optional): saved in the player's details, never on
/// the roster (PLAYER-10, PLAYER-12).
 String? get dateOfBirth;
/// Create a copy of NewPlayer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewPlayerCopyWith<NewPlayer> get copyWith => _$NewPlayerCopyWithImpl<NewPlayer>(this as NewPlayer, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as NewPlayer;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewPlayer&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.jerseyNumber, _this.jerseyNumber) || other.jerseyNumber == _this.jerseyNumber)&&(identical(other.dateOfBirth, _this.dateOfBirth) || other.dateOfBirth == _this.dateOfBirth));
}


@override
int get hashCode {
  final _this = this as NewPlayer;
  return Object.hash(runtimeType,_this.name,_this.jerseyNumber,_this.dateOfBirth);
}

@override
String toString() {
  final _this = this as NewPlayer;
  return 'NewPlayer(name: ${_this.name}, jerseyNumber: ${_this.jerseyNumber}, dateOfBirth: ${_this.dateOfBirth})';
}


}

/// @nodoc
abstract mixin class $NewPlayerCopyWith<$Res>  {
  factory $NewPlayerCopyWith(NewPlayer value, $Res Function(NewPlayer) _then) = _$NewPlayerCopyWithImpl;
@useResult
$Res call({
 String name, String? jerseyNumber, String? dateOfBirth
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
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? jerseyNumber = freezed,Object? dateOfBirth = freezed,}) {
  return _then(NewPlayer(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,jerseyNumber: freezed == jerseyNumber ? _self.jerseyNumber : jerseyNumber // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? jerseyNumber,  String? dateOfBirth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewPlayer() when $default != null:
return $default(_that.name,_that.jerseyNumber,_that.dateOfBirth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? jerseyNumber,  String? dateOfBirth)  $default,) {final _that = this;
switch (_that) {
case _NewPlayer():
return $default(_that.name,_that.jerseyNumber,_that.dateOfBirth);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? jerseyNumber,  String? dateOfBirth)?  $default,) {final _that = this;
switch (_that) {
case _NewPlayer() when $default != null:
return $default(_that.name,_that.jerseyNumber,_that.dateOfBirth);case _:
  return null;

}
}

}

/// @nodoc


class _NewPlayer implements NewPlayer {
  const _NewPlayer({required this.name, this.jerseyNumber, this.dateOfBirth});
  

@override final  String name;
@override final  String? jerseyNumber;
/// 'YYYY-MM-DD' (optional): saved in the player's details, never on
/// the roster (PLAYER-10, PLAYER-12).
@override final  String? dateOfBirth;

/// Create a copy of NewPlayer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewPlayerCopyWith<_NewPlayer> get copyWith => __$NewPlayerCopyWithImpl<_NewPlayer>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewPlayer&&(identical(other.name, name) || other.name == name)&&(identical(other.jerseyNumber, jerseyNumber) || other.jerseyNumber == jerseyNumber)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,jerseyNumber,dateOfBirth);
}

@override
String toString() {
    return 'NewPlayer(name: $name, jerseyNumber: $jerseyNumber, dateOfBirth: $dateOfBirth)';
}


}

/// @nodoc
abstract mixin class _$NewPlayerCopyWith<$Res> implements $NewPlayerCopyWith<$Res> {
  factory _$NewPlayerCopyWith(_NewPlayer value, $Res Function(_NewPlayer) _then) = __$NewPlayerCopyWithImpl;
@override @useResult
$Res call({
 String name, String? jerseyNumber, String? dateOfBirth
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
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? jerseyNumber = freezed,Object? dateOfBirth = freezed,}) {
  return _then(_NewPlayer(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,jerseyNumber: freezed == jerseyNumber ? _self.jerseyNumber : jerseyNumber // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String?,
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
