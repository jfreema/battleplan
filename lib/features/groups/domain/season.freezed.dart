// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'season.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SeasonChoices {

/// The players, with their parents' links, and so the members linked
/// to them: parents keep answering for their kids.
 bool get players;/// The coaches and admins, keeping their roles and titles.
 bool get staff;/// Everyone else.
 bool get members; bool get documents; bool get plays;
/// Create a copy of SeasonChoices
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeasonChoicesCopyWith<SeasonChoices> get copyWith => _$SeasonChoicesCopyWithImpl<SeasonChoices>(this as SeasonChoices, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SeasonChoices;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SeasonChoices&&(identical(other.players, _this.players) || other.players == _this.players)&&(identical(other.staff, _this.staff) || other.staff == _this.staff)&&(identical(other.members, _this.members) || other.members == _this.members)&&(identical(other.documents, _this.documents) || other.documents == _this.documents)&&(identical(other.plays, _this.plays) || other.plays == _this.plays));
}


@override
int get hashCode {
  final _this = this as SeasonChoices;
  return Object.hash(runtimeType,_this.players,_this.staff,_this.members,_this.documents,_this.plays);
}

@override
String toString() {
  final _this = this as SeasonChoices;
  return 'SeasonChoices(players: ${_this.players}, staff: ${_this.staff}, members: ${_this.members}, documents: ${_this.documents}, plays: ${_this.plays})';
}


}

/// @nodoc
abstract mixin class $SeasonChoicesCopyWith<$Res>  {
  factory $SeasonChoicesCopyWith(SeasonChoices value, $Res Function(SeasonChoices) _then) = _$SeasonChoicesCopyWithImpl;
@useResult
$Res call({
 bool players, bool staff, bool members, bool documents, bool plays
});




}
/// @nodoc
class _$SeasonChoicesCopyWithImpl<$Res>
    implements $SeasonChoicesCopyWith<$Res> {
  _$SeasonChoicesCopyWithImpl(this._self, this._then);

  final SeasonChoices _self;
  final $Res Function(SeasonChoices) _then;

/// Create a copy of SeasonChoices
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? players = null,Object? staff = null,Object? members = null,Object? documents = null,Object? plays = null,}) {
  return _then(SeasonChoices(
players: null == players ? _self.players : players // ignore: cast_nullable_to_non_nullable
as bool,staff: null == staff ? _self.staff : staff // ignore: cast_nullable_to_non_nullable
as bool,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as bool,documents: null == documents ? _self.documents : documents // ignore: cast_nullable_to_non_nullable
as bool,plays: null == plays ? _self.plays : plays // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SeasonChoices].
extension SeasonChoicesPatterns on SeasonChoices {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SeasonChoices value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SeasonChoices() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SeasonChoices value)  $default,){
final _that = this;
switch (_that) {
case _SeasonChoices():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SeasonChoices value)?  $default,){
final _that = this;
switch (_that) {
case _SeasonChoices() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool players,  bool staff,  bool members,  bool documents,  bool plays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SeasonChoices() when $default != null:
return $default(_that.players,_that.staff,_that.members,_that.documents,_that.plays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool players,  bool staff,  bool members,  bool documents,  bool plays)  $default,) {final _that = this;
switch (_that) {
case _SeasonChoices():
return $default(_that.players,_that.staff,_that.members,_that.documents,_that.plays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool players,  bool staff,  bool members,  bool documents,  bool plays)?  $default,) {final _that = this;
switch (_that) {
case _SeasonChoices() when $default != null:
return $default(_that.players,_that.staff,_that.members,_that.documents,_that.plays);case _:
  return null;

}
}

}

/// @nodoc


class _SeasonChoices implements SeasonChoices {
  const _SeasonChoices({this.players = true, this.staff = true, this.members = true, this.documents = false, this.plays = false});
  

/// The players, with their parents' links, and so the members linked
/// to them: parents keep answering for their kids.
@override@JsonKey() final  bool players;
/// The coaches and admins, keeping their roles and titles.
@override@JsonKey() final  bool staff;
/// Everyone else.
@override@JsonKey() final  bool members;
@override@JsonKey() final  bool documents;
@override@JsonKey() final  bool plays;

/// Create a copy of SeasonChoices
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SeasonChoicesCopyWith<_SeasonChoices> get copyWith => __$SeasonChoicesCopyWithImpl<_SeasonChoices>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SeasonChoices&&(identical(other.players, players) || other.players == players)&&(identical(other.staff, staff) || other.staff == staff)&&(identical(other.members, members) || other.members == members)&&(identical(other.documents, documents) || other.documents == documents)&&(identical(other.plays, plays) || other.plays == plays));
}


@override
int get hashCode {
    return Object.hash(runtimeType,players,staff,members,documents,plays);
}

@override
String toString() {
    return 'SeasonChoices(players: $players, staff: $staff, members: $members, documents: $documents, plays: $plays)';
}


}

/// @nodoc
abstract mixin class _$SeasonChoicesCopyWith<$Res> implements $SeasonChoicesCopyWith<$Res> {
  factory _$SeasonChoicesCopyWith(_SeasonChoices value, $Res Function(_SeasonChoices) _then) = __$SeasonChoicesCopyWithImpl;
@override @useResult
$Res call({
 bool players, bool staff, bool members, bool documents, bool plays
});




}
/// @nodoc
class __$SeasonChoicesCopyWithImpl<$Res>
    implements _$SeasonChoicesCopyWith<$Res> {
  __$SeasonChoicesCopyWithImpl(this._self, this._then);

  final _SeasonChoices _self;
  final $Res Function(_SeasonChoices) _then;

/// Create a copy of SeasonChoices
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? players = null,Object? staff = null,Object? members = null,Object? documents = null,Object? plays = null,}) {
  return _then(_SeasonChoices(
players: null == players ? _self.players : players // ignore: cast_nullable_to_non_nullable
as bool,staff: null == staff ? _self.staff : staff // ignore: cast_nullable_to_non_nullable
as bool,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as bool,documents: null == documents ? _self.documents : documents // ignore: cast_nullable_to_non_nullable
as bool,plays: null == plays ? _self.plays : plays // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
