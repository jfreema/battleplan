// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invite.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TeamInvite {

/// Stored without the dash, e.g. K7XPM2QR.
 String get code;/// For display, e.g. K7XP-M2QR.
 String get display; Uri get url; int get useCount; DateTime? get expiresAt; int? get maxUses;
/// Create a copy of TeamInvite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamInviteCopyWith<TeamInvite> get copyWith => _$TeamInviteCopyWithImpl<TeamInvite>(this as TeamInvite, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TeamInvite;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeamInvite&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.display, _this.display) || other.display == _this.display)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.useCount, _this.useCount) || other.useCount == _this.useCount)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.maxUses, _this.maxUses) || other.maxUses == _this.maxUses));
}


@override
int get hashCode {
  final _this = this as TeamInvite;
  return Object.hash(runtimeType,_this.code,_this.display,_this.url,_this.useCount,_this.expiresAt,_this.maxUses);
}

@override
String toString() {
  final _this = this as TeamInvite;
  return 'TeamInvite(code: ${_this.code}, display: ${_this.display}, url: ${_this.url}, useCount: ${_this.useCount}, expiresAt: ${_this.expiresAt}, maxUses: ${_this.maxUses})';
}


}

/// @nodoc
abstract mixin class $TeamInviteCopyWith<$Res>  {
  factory $TeamInviteCopyWith(TeamInvite value, $Res Function(TeamInvite) _then) = _$TeamInviteCopyWithImpl;
@useResult
$Res call({
 String code, String display, Uri url, int useCount, DateTime? expiresAt, int? maxUses
});




}
/// @nodoc
class _$TeamInviteCopyWithImpl<$Res>
    implements $TeamInviteCopyWith<$Res> {
  _$TeamInviteCopyWithImpl(this._self, this._then);

  final TeamInvite _self;
  final $Res Function(TeamInvite) _then;

/// Create a copy of TeamInvite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? display = null,Object? url = null,Object? useCount = null,Object? expiresAt = freezed,Object? maxUses = freezed,}) {
  return _then(TeamInvite(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,display: null == display ? _self.display : display // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as Uri,useCount: null == useCount ? _self.useCount : useCount // ignore: cast_nullable_to_non_nullable
as int,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,maxUses: freezed == maxUses ? _self.maxUses : maxUses // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [TeamInvite].
extension TeamInvitePatterns on TeamInvite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeamInvite value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeamInvite() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeamInvite value)  $default,){
final _that = this;
switch (_that) {
case _TeamInvite():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeamInvite value)?  $default,){
final _that = this;
switch (_that) {
case _TeamInvite() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String display,  Uri url,  int useCount,  DateTime? expiresAt,  int? maxUses)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeamInvite() when $default != null:
return $default(_that.code,_that.display,_that.url,_that.useCount,_that.expiresAt,_that.maxUses);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String display,  Uri url,  int useCount,  DateTime? expiresAt,  int? maxUses)  $default,) {final _that = this;
switch (_that) {
case _TeamInvite():
return $default(_that.code,_that.display,_that.url,_that.useCount,_that.expiresAt,_that.maxUses);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String display,  Uri url,  int useCount,  DateTime? expiresAt,  int? maxUses)?  $default,) {final _that = this;
switch (_that) {
case _TeamInvite() when $default != null:
return $default(_that.code,_that.display,_that.url,_that.useCount,_that.expiresAt,_that.maxUses);case _:
  return null;

}
}

}

/// @nodoc


class _TeamInvite implements TeamInvite {
  const _TeamInvite({required this.code, required this.display, required this.url, required this.useCount, this.expiresAt, this.maxUses});
  

/// Stored without the dash, e.g. K7XPM2QR.
@override final  String code;
/// For display, e.g. K7XP-M2QR.
@override final  String display;
@override final  Uri url;
@override final  int useCount;
@override final  DateTime? expiresAt;
@override final  int? maxUses;

/// Create a copy of TeamInvite
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamInviteCopyWith<_TeamInvite> get copyWith => __$TeamInviteCopyWithImpl<_TeamInvite>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeamInvite&&(identical(other.code, code) || other.code == code)&&(identical(other.display, display) || other.display == display)&&(identical(other.url, url) || other.url == url)&&(identical(other.useCount, useCount) || other.useCount == useCount)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.maxUses, maxUses) || other.maxUses == maxUses));
}


@override
int get hashCode {
    return Object.hash(runtimeType,code,display,url,useCount,expiresAt,maxUses);
}

@override
String toString() {
    return 'TeamInvite(code: $code, display: $display, url: $url, useCount: $useCount, expiresAt: $expiresAt, maxUses: $maxUses)';
}


}

/// @nodoc
abstract mixin class _$TeamInviteCopyWith<$Res> implements $TeamInviteCopyWith<$Res> {
  factory _$TeamInviteCopyWith(_TeamInvite value, $Res Function(_TeamInvite) _then) = __$TeamInviteCopyWithImpl;
@override @useResult
$Res call({
 String code, String display, Uri url, int useCount, DateTime? expiresAt, int? maxUses
});




}
/// @nodoc
class __$TeamInviteCopyWithImpl<$Res>
    implements _$TeamInviteCopyWith<$Res> {
  __$TeamInviteCopyWithImpl(this._self, this._then);

  final _TeamInvite _self;
  final $Res Function(_TeamInvite) _then;

/// Create a copy of TeamInvite
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? display = null,Object? url = null,Object? useCount = null,Object? expiresAt = freezed,Object? maxUses = freezed,}) {
  return _then(_TeamInvite(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,display: null == display ? _self.display : display // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as Uri,useCount: null == useCount ? _self.useCount : useCount // ignore: cast_nullable_to_non_nullable
as int,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,maxUses: freezed == maxUses ? _self.maxUses : maxUses // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$InvitePreview {

 String get groupId; String get name; Sport get sport; TeamType get teamType; int get memberCount; int? get color; String? get invitedBy;
/// Create a copy of InvitePreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvitePreviewCopyWith<InvitePreview> get copyWith => _$InvitePreviewCopyWithImpl<InvitePreview>(this as InvitePreview, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as InvitePreview;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvitePreview&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.sport, _this.sport) || other.sport == _this.sport)&&(identical(other.teamType, _this.teamType) || other.teamType == _this.teamType)&&(identical(other.memberCount, _this.memberCount) || other.memberCount == _this.memberCount)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.invitedBy, _this.invitedBy) || other.invitedBy == _this.invitedBy));
}


@override
int get hashCode {
  final _this = this as InvitePreview;
  return Object.hash(runtimeType,_this.groupId,_this.name,_this.sport,_this.teamType,_this.memberCount,_this.color,_this.invitedBy);
}

@override
String toString() {
  final _this = this as InvitePreview;
  return 'InvitePreview(groupId: ${_this.groupId}, name: ${_this.name}, sport: ${_this.sport}, teamType: ${_this.teamType}, memberCount: ${_this.memberCount}, color: ${_this.color}, invitedBy: ${_this.invitedBy})';
}


}

/// @nodoc
abstract mixin class $InvitePreviewCopyWith<$Res>  {
  factory $InvitePreviewCopyWith(InvitePreview value, $Res Function(InvitePreview) _then) = _$InvitePreviewCopyWithImpl;
@useResult
$Res call({
 String groupId, String name, Sport sport, TeamType teamType, int memberCount, int? color, String? invitedBy
});




}
/// @nodoc
class _$InvitePreviewCopyWithImpl<$Res>
    implements $InvitePreviewCopyWith<$Res> {
  _$InvitePreviewCopyWithImpl(this._self, this._then);

  final InvitePreview _self;
  final $Res Function(InvitePreview) _then;

/// Create a copy of InvitePreview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groupId = null,Object? name = null,Object? sport = null,Object? teamType = null,Object? memberCount = null,Object? color = freezed,Object? invitedBy = freezed,}) {
  return _then(InvitePreview(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Sport,teamType: null == teamType ? _self.teamType : teamType // ignore: cast_nullable_to_non_nullable
as TeamType,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int?,invitedBy: freezed == invitedBy ? _self.invitedBy : invitedBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InvitePreview].
extension InvitePreviewPatterns on InvitePreview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvitePreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvitePreview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvitePreview value)  $default,){
final _that = this;
switch (_that) {
case _InvitePreview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvitePreview value)?  $default,){
final _that = this;
switch (_that) {
case _InvitePreview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String groupId,  String name,  Sport sport,  TeamType teamType,  int memberCount,  int? color,  String? invitedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvitePreview() when $default != null:
return $default(_that.groupId,_that.name,_that.sport,_that.teamType,_that.memberCount,_that.color,_that.invitedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String groupId,  String name,  Sport sport,  TeamType teamType,  int memberCount,  int? color,  String? invitedBy)  $default,) {final _that = this;
switch (_that) {
case _InvitePreview():
return $default(_that.groupId,_that.name,_that.sport,_that.teamType,_that.memberCount,_that.color,_that.invitedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String groupId,  String name,  Sport sport,  TeamType teamType,  int memberCount,  int? color,  String? invitedBy)?  $default,) {final _that = this;
switch (_that) {
case _InvitePreview() when $default != null:
return $default(_that.groupId,_that.name,_that.sport,_that.teamType,_that.memberCount,_that.color,_that.invitedBy);case _:
  return null;

}
}

}

/// @nodoc


class _InvitePreview implements InvitePreview {
  const _InvitePreview({required this.groupId, required this.name, required this.sport, required this.teamType, required this.memberCount, this.color, this.invitedBy});
  

@override final  String groupId;
@override final  String name;
@override final  Sport sport;
@override final  TeamType teamType;
@override final  int memberCount;
@override final  int? color;
@override final  String? invitedBy;

/// Create a copy of InvitePreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvitePreviewCopyWith<_InvitePreview> get copyWith => __$InvitePreviewCopyWithImpl<_InvitePreview>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvitePreview&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.name, name) || other.name == name)&&(identical(other.sport, sport) || other.sport == sport)&&(identical(other.teamType, teamType) || other.teamType == teamType)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount)&&(identical(other.color, color) || other.color == color)&&(identical(other.invitedBy, invitedBy) || other.invitedBy == invitedBy));
}


@override
int get hashCode {
    return Object.hash(runtimeType,groupId,name,sport,teamType,memberCount,color,invitedBy);
}

@override
String toString() {
    return 'InvitePreview(groupId: $groupId, name: $name, sport: $sport, teamType: $teamType, memberCount: $memberCount, color: $color, invitedBy: $invitedBy)';
}


}

/// @nodoc
abstract mixin class _$InvitePreviewCopyWith<$Res> implements $InvitePreviewCopyWith<$Res> {
  factory _$InvitePreviewCopyWith(_InvitePreview value, $Res Function(_InvitePreview) _then) = __$InvitePreviewCopyWithImpl;
@override @useResult
$Res call({
 String groupId, String name, Sport sport, TeamType teamType, int memberCount, int? color, String? invitedBy
});




}
/// @nodoc
class __$InvitePreviewCopyWithImpl<$Res>
    implements _$InvitePreviewCopyWith<$Res> {
  __$InvitePreviewCopyWithImpl(this._self, this._then);

  final _InvitePreview _self;
  final $Res Function(_InvitePreview) _then;

/// Create a copy of InvitePreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? groupId = null,Object? name = null,Object? sport = null,Object? teamType = null,Object? memberCount = null,Object? color = freezed,Object? invitedBy = freezed,}) {
  return _then(_InvitePreview(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Sport,teamType: null == teamType ? _self.teamType : teamType // ignore: cast_nullable_to_non_nullable
as TeamType,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int?,invitedBy: freezed == invitedBy ? _self.invitedBy : invitedBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$JoinResult {

 String get groupId; TeamType get teamType; bool get alreadyMember;
/// Create a copy of JoinResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JoinResultCopyWith<JoinResult> get copyWith => _$JoinResultCopyWithImpl<JoinResult>(this as JoinResult, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as JoinResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JoinResult&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.teamType, _this.teamType) || other.teamType == _this.teamType)&&(identical(other.alreadyMember, _this.alreadyMember) || other.alreadyMember == _this.alreadyMember));
}


@override
int get hashCode {
  final _this = this as JoinResult;
  return Object.hash(runtimeType,_this.groupId,_this.teamType,_this.alreadyMember);
}

@override
String toString() {
  final _this = this as JoinResult;
  return 'JoinResult(groupId: ${_this.groupId}, teamType: ${_this.teamType}, alreadyMember: ${_this.alreadyMember})';
}


}

/// @nodoc
abstract mixin class $JoinResultCopyWith<$Res>  {
  factory $JoinResultCopyWith(JoinResult value, $Res Function(JoinResult) _then) = _$JoinResultCopyWithImpl;
@useResult
$Res call({
 String groupId, TeamType teamType, bool alreadyMember
});




}
/// @nodoc
class _$JoinResultCopyWithImpl<$Res>
    implements $JoinResultCopyWith<$Res> {
  _$JoinResultCopyWithImpl(this._self, this._then);

  final JoinResult _self;
  final $Res Function(JoinResult) _then;

/// Create a copy of JoinResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groupId = null,Object? teamType = null,Object? alreadyMember = null,}) {
  return _then(JoinResult(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,teamType: null == teamType ? _self.teamType : teamType // ignore: cast_nullable_to_non_nullable
as TeamType,alreadyMember: null == alreadyMember ? _self.alreadyMember : alreadyMember // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [JoinResult].
extension JoinResultPatterns on JoinResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JoinResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JoinResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JoinResult value)  $default,){
final _that = this;
switch (_that) {
case _JoinResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JoinResult value)?  $default,){
final _that = this;
switch (_that) {
case _JoinResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String groupId,  TeamType teamType,  bool alreadyMember)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JoinResult() when $default != null:
return $default(_that.groupId,_that.teamType,_that.alreadyMember);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String groupId,  TeamType teamType,  bool alreadyMember)  $default,) {final _that = this;
switch (_that) {
case _JoinResult():
return $default(_that.groupId,_that.teamType,_that.alreadyMember);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String groupId,  TeamType teamType,  bool alreadyMember)?  $default,) {final _that = this;
switch (_that) {
case _JoinResult() when $default != null:
return $default(_that.groupId,_that.teamType,_that.alreadyMember);case _:
  return null;

}
}

}

/// @nodoc


class _JoinResult implements JoinResult {
  const _JoinResult({required this.groupId, required this.teamType, required this.alreadyMember});
  

@override final  String groupId;
@override final  TeamType teamType;
@override final  bool alreadyMember;

/// Create a copy of JoinResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JoinResultCopyWith<_JoinResult> get copyWith => __$JoinResultCopyWithImpl<_JoinResult>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _JoinResult&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.teamType, teamType) || other.teamType == teamType)&&(identical(other.alreadyMember, alreadyMember) || other.alreadyMember == alreadyMember));
}


@override
int get hashCode {
    return Object.hash(runtimeType,groupId,teamType,alreadyMember);
}

@override
String toString() {
    return 'JoinResult(groupId: $groupId, teamType: $teamType, alreadyMember: $alreadyMember)';
}


}

/// @nodoc
abstract mixin class _$JoinResultCopyWith<$Res> implements $JoinResultCopyWith<$Res> {
  factory _$JoinResultCopyWith(_JoinResult value, $Res Function(_JoinResult) _then) = __$JoinResultCopyWithImpl;
@override @useResult
$Res call({
 String groupId, TeamType teamType, bool alreadyMember
});




}
/// @nodoc
class __$JoinResultCopyWithImpl<$Res>
    implements _$JoinResultCopyWith<$Res> {
  __$JoinResultCopyWithImpl(this._self, this._then);

  final _JoinResult _self;
  final $Res Function(_JoinResult) _then;

/// Create a copy of JoinResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? groupId = null,Object? teamType = null,Object? alreadyMember = null,}) {
  return _then(_JoinResult(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,teamType: null == teamType ? _self.teamType : teamType // ignore: cast_nullable_to_non_nullable
as TeamType,alreadyMember: null == alreadyMember ? _self.alreadyMember : alreadyMember // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$EmailInvite {

 String get code; String get email; EmailInviteStatus get status; DateTime? get createdAt;
/// Create a copy of EmailInvite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmailInviteCopyWith<EmailInvite> get copyWith => _$EmailInviteCopyWithImpl<EmailInvite>(this as EmailInvite, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EmailInvite;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmailInvite&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}


@override
int get hashCode {
  final _this = this as EmailInvite;
  return Object.hash(runtimeType,_this.code,_this.email,_this.status,_this.createdAt);
}

@override
String toString() {
  final _this = this as EmailInvite;
  return 'EmailInvite(code: ${_this.code}, email: ${_this.email}, status: ${_this.status}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $EmailInviteCopyWith<$Res>  {
  factory $EmailInviteCopyWith(EmailInvite value, $Res Function(EmailInvite) _then) = _$EmailInviteCopyWithImpl;
@useResult
$Res call({
 String code, String email, EmailInviteStatus status, DateTime? createdAt
});




}
/// @nodoc
class _$EmailInviteCopyWithImpl<$Res>
    implements $EmailInviteCopyWith<$Res> {
  _$EmailInviteCopyWithImpl(this._self, this._then);

  final EmailInvite _self;
  final $Res Function(EmailInvite) _then;

/// Create a copy of EmailInvite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? email = null,Object? status = null,Object? createdAt = freezed,}) {
  return _then(EmailInvite(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EmailInviteStatus,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [EmailInvite].
extension EmailInvitePatterns on EmailInvite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmailInvite value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmailInvite() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmailInvite value)  $default,){
final _that = this;
switch (_that) {
case _EmailInvite():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmailInvite value)?  $default,){
final _that = this;
switch (_that) {
case _EmailInvite() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String email,  EmailInviteStatus status,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmailInvite() when $default != null:
return $default(_that.code,_that.email,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String email,  EmailInviteStatus status,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _EmailInvite():
return $default(_that.code,_that.email,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String email,  EmailInviteStatus status,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _EmailInvite() when $default != null:
return $default(_that.code,_that.email,_that.status,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _EmailInvite implements EmailInvite {
  const _EmailInvite({required this.code, required this.email, required this.status, this.createdAt});
  

@override final  String code;
@override final  String email;
@override final  EmailInviteStatus status;
@override final  DateTime? createdAt;

/// Create a copy of EmailInvite
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmailInviteCopyWith<_EmailInvite> get copyWith => __$EmailInviteCopyWithImpl<_EmailInvite>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmailInvite&&(identical(other.code, code) || other.code == code)&&(identical(other.email, email) || other.email == email)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,code,email,status,createdAt);
}

@override
String toString() {
    return 'EmailInvite(code: $code, email: $email, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$EmailInviteCopyWith<$Res> implements $EmailInviteCopyWith<$Res> {
  factory _$EmailInviteCopyWith(_EmailInvite value, $Res Function(_EmailInvite) _then) = __$EmailInviteCopyWithImpl;
@override @useResult
$Res call({
 String code, String email, EmailInviteStatus status, DateTime? createdAt
});




}
/// @nodoc
class __$EmailInviteCopyWithImpl<$Res>
    implements _$EmailInviteCopyWith<$Res> {
  __$EmailInviteCopyWithImpl(this._self, this._then);

  final _EmailInvite _self;
  final $Res Function(_EmailInvite) _then;

/// Create a copy of EmailInvite
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? email = null,Object? status = null,Object? createdAt = freezed,}) {
  return _then(_EmailInvite(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EmailInviteStatus,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
