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

// dart format on
