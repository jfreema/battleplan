// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Group {

 GroupId get id; String get name; Sport get sport; TeamType get teamType; int get memberCount; String? get description;/// ARGB team color (one of `teamColorValues`).
 int? get color; DateTime? get lastMessageAt; String? get lastMessagePreview; DateTime? get archivedAt; DateTime? get suspendedAt;
/// Create a copy of Group
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupCopyWith<Group> get copyWith => _$GroupCopyWithImpl<Group>(this as Group, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Group;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Group&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.sport, _this.sport) || other.sport == _this.sport)&&(identical(other.teamType, _this.teamType) || other.teamType == _this.teamType)&&(identical(other.memberCount, _this.memberCount) || other.memberCount == _this.memberCount)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.lastMessageAt, _this.lastMessageAt) || other.lastMessageAt == _this.lastMessageAt)&&(identical(other.lastMessagePreview, _this.lastMessagePreview) || other.lastMessagePreview == _this.lastMessagePreview)&&(identical(other.archivedAt, _this.archivedAt) || other.archivedAt == _this.archivedAt)&&(identical(other.suspendedAt, _this.suspendedAt) || other.suspendedAt == _this.suspendedAt));
}


@override
int get hashCode {
  final _this = this as Group;
  return Object.hash(runtimeType,_this.id,_this.name,_this.sport,_this.teamType,_this.memberCount,_this.description,_this.color,_this.lastMessageAt,_this.lastMessagePreview,_this.archivedAt,_this.suspendedAt);
}

@override
String toString() {
  final _this = this as Group;
  return 'Group(id: ${_this.id}, name: ${_this.name}, sport: ${_this.sport}, teamType: ${_this.teamType}, memberCount: ${_this.memberCount}, description: ${_this.description}, color: ${_this.color}, lastMessageAt: ${_this.lastMessageAt}, lastMessagePreview: ${_this.lastMessagePreview}, archivedAt: ${_this.archivedAt}, suspendedAt: ${_this.suspendedAt})';
}


}

/// @nodoc
abstract mixin class $GroupCopyWith<$Res>  {
  factory $GroupCopyWith(Group value, $Res Function(Group) _then) = _$GroupCopyWithImpl;
@useResult
$Res call({
 GroupId id, String name, Sport sport, TeamType teamType, int memberCount, String? description, int? color, DateTime? lastMessageAt, String? lastMessagePreview, DateTime? archivedAt, DateTime? suspendedAt
});




}
/// @nodoc
class _$GroupCopyWithImpl<$Res>
    implements $GroupCopyWith<$Res> {
  _$GroupCopyWithImpl(this._self, this._then);

  final Group _self;
  final $Res Function(Group) _then;

/// Create a copy of Group
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? sport = null,Object? teamType = null,Object? memberCount = null,Object? description = freezed,Object? color = freezed,Object? lastMessageAt = freezed,Object? lastMessagePreview = freezed,Object? archivedAt = freezed,Object? suspendedAt = freezed,}) {
  return _then(Group(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as GroupId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Sport,teamType: null == teamType ? _self.teamType : teamType // ignore: cast_nullable_to_non_nullable
as TeamType,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int?,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastMessagePreview: freezed == lastMessagePreview ? _self.lastMessagePreview : lastMessagePreview // ignore: cast_nullable_to_non_nullable
as String?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,suspendedAt: freezed == suspendedAt ? _self.suspendedAt : suspendedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Group].
extension GroupPatterns on Group {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Group value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Group() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Group value)  $default,){
final _that = this;
switch (_that) {
case _Group():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Group value)?  $default,){
final _that = this;
switch (_that) {
case _Group() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GroupId id,  String name,  Sport sport,  TeamType teamType,  int memberCount,  String? description,  int? color,  DateTime? lastMessageAt,  String? lastMessagePreview,  DateTime? archivedAt,  DateTime? suspendedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Group() when $default != null:
return $default(_that.id,_that.name,_that.sport,_that.teamType,_that.memberCount,_that.description,_that.color,_that.lastMessageAt,_that.lastMessagePreview,_that.archivedAt,_that.suspendedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GroupId id,  String name,  Sport sport,  TeamType teamType,  int memberCount,  String? description,  int? color,  DateTime? lastMessageAt,  String? lastMessagePreview,  DateTime? archivedAt,  DateTime? suspendedAt)  $default,) {final _that = this;
switch (_that) {
case _Group():
return $default(_that.id,_that.name,_that.sport,_that.teamType,_that.memberCount,_that.description,_that.color,_that.lastMessageAt,_that.lastMessagePreview,_that.archivedAt,_that.suspendedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GroupId id,  String name,  Sport sport,  TeamType teamType,  int memberCount,  String? description,  int? color,  DateTime? lastMessageAt,  String? lastMessagePreview,  DateTime? archivedAt,  DateTime? suspendedAt)?  $default,) {final _that = this;
switch (_that) {
case _Group() when $default != null:
return $default(_that.id,_that.name,_that.sport,_that.teamType,_that.memberCount,_that.description,_that.color,_that.lastMessageAt,_that.lastMessagePreview,_that.archivedAt,_that.suspendedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Group extends Group {
  const _Group({required this.id, required this.name, required this.sport, required this.teamType, required this.memberCount, this.description, this.color, this.lastMessageAt, this.lastMessagePreview, this.archivedAt, this.suspendedAt}): super._();
  

@override final  GroupId id;
@override final  String name;
@override final  Sport sport;
@override final  TeamType teamType;
@override final  int memberCount;
@override final  String? description;
/// ARGB team color (one of `teamColorValues`).
@override final  int? color;
@override final  DateTime? lastMessageAt;
@override final  String? lastMessagePreview;
@override final  DateTime? archivedAt;
@override final  DateTime? suspendedAt;

/// Create a copy of Group
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupCopyWith<_Group> get copyWith => __$GroupCopyWithImpl<_Group>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Group&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.sport, sport) || other.sport == sport)&&(identical(other.teamType, teamType) || other.teamType == teamType)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount)&&(identical(other.description, description) || other.description == description)&&(identical(other.color, color) || other.color == color)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&(identical(other.lastMessagePreview, lastMessagePreview) || other.lastMessagePreview == lastMessagePreview)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.suspendedAt, suspendedAt) || other.suspendedAt == suspendedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,sport,teamType,memberCount,description,color,lastMessageAt,lastMessagePreview,archivedAt,suspendedAt);
}

@override
String toString() {
    return 'Group(id: $id, name: $name, sport: $sport, teamType: $teamType, memberCount: $memberCount, description: $description, color: $color, lastMessageAt: $lastMessageAt, lastMessagePreview: $lastMessagePreview, archivedAt: $archivedAt, suspendedAt: $suspendedAt)';
}


}

/// @nodoc
abstract mixin class _$GroupCopyWith<$Res> implements $GroupCopyWith<$Res> {
  factory _$GroupCopyWith(_Group value, $Res Function(_Group) _then) = __$GroupCopyWithImpl;
@override @useResult
$Res call({
 GroupId id, String name, Sport sport, TeamType teamType, int memberCount, String? description, int? color, DateTime? lastMessageAt, String? lastMessagePreview, DateTime? archivedAt, DateTime? suspendedAt
});




}
/// @nodoc
class __$GroupCopyWithImpl<$Res>
    implements _$GroupCopyWith<$Res> {
  __$GroupCopyWithImpl(this._self, this._then);

  final _Group _self;
  final $Res Function(_Group) _then;

/// Create a copy of Group
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? sport = null,Object? teamType = null,Object? memberCount = null,Object? description = freezed,Object? color = freezed,Object? lastMessageAt = freezed,Object? lastMessagePreview = freezed,Object? archivedAt = freezed,Object? suspendedAt = freezed,}) {
  return _then(_Group(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as GroupId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Sport,teamType: null == teamType ? _self.teamType : teamType // ignore: cast_nullable_to_non_nullable
as TeamType,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int?,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastMessagePreview: freezed == lastMessagePreview ? _self.lastMessagePreview : lastMessagePreview // ignore: cast_nullable_to_non_nullable
as String?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,suspendedAt: freezed == suspendedAt ? _self.suspendedAt : suspendedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
