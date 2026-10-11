// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserProfile {

 String get uid; String get displayName; UserStatus get status; String? get email; String? get photoPath; ThemePreference get themeMode; List<String> get signInMethods; DateTime? get adultConfirmedAt; DateTime? get acceptedTermsAt;
/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileCopyWith<UserProfile> get copyWith => _$UserProfileCopyWithImpl<UserProfile>(this as UserProfile, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UserProfile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfile&&(identical(other.uid, _this.uid) || other.uid == _this.uid)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.photoPath, _this.photoPath) || other.photoPath == _this.photoPath)&&(identical(other.themeMode, _this.themeMode) || other.themeMode == _this.themeMode)&&const DeepCollectionEquality().equals(other.signInMethods, _this.signInMethods)&&(identical(other.adultConfirmedAt, _this.adultConfirmedAt) || other.adultConfirmedAt == _this.adultConfirmedAt)&&(identical(other.acceptedTermsAt, _this.acceptedTermsAt) || other.acceptedTermsAt == _this.acceptedTermsAt));
}


@override
int get hashCode {
  final _this = this as UserProfile;
  return Object.hash(runtimeType,_this.uid,_this.displayName,_this.status,_this.email,_this.photoPath,_this.themeMode,const DeepCollectionEquality().hash(_this.signInMethods),_this.adultConfirmedAt,_this.acceptedTermsAt);
}

@override
String toString() {
  final _this = this as UserProfile;
  return 'UserProfile(uid: ${_this.uid}, displayName: ${_this.displayName}, status: ${_this.status}, email: ${_this.email}, photoPath: ${_this.photoPath}, themeMode: ${_this.themeMode}, signInMethods: ${_this.signInMethods}, adultConfirmedAt: ${_this.adultConfirmedAt}, acceptedTermsAt: ${_this.acceptedTermsAt})';
}


}

/// @nodoc
abstract mixin class $UserProfileCopyWith<$Res>  {
  factory $UserProfileCopyWith(UserProfile value, $Res Function(UserProfile) _then) = _$UserProfileCopyWithImpl;
@useResult
$Res call({
 String uid, String displayName, UserStatus status, String? email, String? photoPath, ThemePreference themeMode, List<String> signInMethods, DateTime? adultConfirmedAt, DateTime? acceptedTermsAt
});




}
/// @nodoc
class _$UserProfileCopyWithImpl<$Res>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._self, this._then);

  final UserProfile _self;
  final $Res Function(UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? displayName = null,Object? status = null,Object? email = freezed,Object? photoPath = freezed,Object? themeMode = null,Object? signInMethods = null,Object? adultConfirmedAt = freezed,Object? acceptedTermsAt = freezed,}) {
  return _then(UserProfile(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as UserStatus,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,photoPath: freezed == photoPath ? _self.photoPath : photoPath // ignore: cast_nullable_to_non_nullable
as String?,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as ThemePreference,signInMethods: null == signInMethods ? _self.signInMethods : signInMethods // ignore: cast_nullable_to_non_nullable
as List<String>,adultConfirmedAt: freezed == adultConfirmedAt ? _self.adultConfirmedAt : adultConfirmedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,acceptedTermsAt: freezed == acceptedTermsAt ? _self.acceptedTermsAt : acceptedTermsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserProfile].
extension UserProfilePatterns on UserProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfile value)  $default,){
final _that = this;
switch (_that) {
case _UserProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfile value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String displayName,  UserStatus status,  String? email,  String? photoPath,  ThemePreference themeMode,  List<String> signInMethods,  DateTime? adultConfirmedAt,  DateTime? acceptedTermsAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.uid,_that.displayName,_that.status,_that.email,_that.photoPath,_that.themeMode,_that.signInMethods,_that.adultConfirmedAt,_that.acceptedTermsAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String displayName,  UserStatus status,  String? email,  String? photoPath,  ThemePreference themeMode,  List<String> signInMethods,  DateTime? adultConfirmedAt,  DateTime? acceptedTermsAt)  $default,) {final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that.uid,_that.displayName,_that.status,_that.email,_that.photoPath,_that.themeMode,_that.signInMethods,_that.adultConfirmedAt,_that.acceptedTermsAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String displayName,  UserStatus status,  String? email,  String? photoPath,  ThemePreference themeMode,  List<String> signInMethods,  DateTime? adultConfirmedAt,  DateTime? acceptedTermsAt)?  $default,) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.uid,_that.displayName,_that.status,_that.email,_that.photoPath,_that.themeMode,_that.signInMethods,_that.adultConfirmedAt,_that.acceptedTermsAt);case _:
  return null;

}
}

}

/// @nodoc


class _UserProfile extends UserProfile {
  const _UserProfile({required this.uid, required this.displayName, required this.status, this.email, this.photoPath, this.themeMode = ThemePreference.system,  List<String> signInMethods = const <String>[], this.adultConfirmedAt, this.acceptedTermsAt}): _signInMethods = signInMethods,super._();
  

@override final  String uid;
@override final  String displayName;
@override final  UserStatus status;
@override final  String? email;
@override final  String? photoPath;
@override@JsonKey() final  ThemePreference themeMode;
 final  List<String> _signInMethods;
@override@JsonKey() List<String> get signInMethods {
  if (_signInMethods is EqualUnmodifiableListView) return _signInMethods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_signInMethods);
}

@override final  DateTime? adultConfirmedAt;
@override final  DateTime? acceptedTermsAt;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfileCopyWith<_UserProfile> get copyWith => __$UserProfileCopyWithImpl<_UserProfile>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfile&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.status, status) || other.status == status)&&(identical(other.email, email) || other.email == email)&&(identical(other.photoPath, photoPath) || other.photoPath == photoPath)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&const DeepCollectionEquality().equals(other.signInMethods, _signInMethods)&&(identical(other.adultConfirmedAt, adultConfirmedAt) || other.adultConfirmedAt == adultConfirmedAt)&&(identical(other.acceptedTermsAt, acceptedTermsAt) || other.acceptedTermsAt == acceptedTermsAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,uid,displayName,status,email,photoPath,themeMode,const DeepCollectionEquality().hash(_signInMethods),adultConfirmedAt,acceptedTermsAt);
}

@override
String toString() {
    return 'UserProfile(uid: $uid, displayName: $displayName, status: $status, email: $email, photoPath: $photoPath, themeMode: $themeMode, signInMethods: $signInMethods, adultConfirmedAt: $adultConfirmedAt, acceptedTermsAt: $acceptedTermsAt)';
}


}

/// @nodoc
abstract mixin class _$UserProfileCopyWith<$Res> implements $UserProfileCopyWith<$Res> {
  factory _$UserProfileCopyWith(_UserProfile value, $Res Function(_UserProfile) _then) = __$UserProfileCopyWithImpl;
@override @useResult
$Res call({
 String uid, String displayName, UserStatus status, String? email, String? photoPath, ThemePreference themeMode, List<String> signInMethods, DateTime? adultConfirmedAt, DateTime? acceptedTermsAt
});




}
/// @nodoc
class __$UserProfileCopyWithImpl<$Res>
    implements _$UserProfileCopyWith<$Res> {
  __$UserProfileCopyWithImpl(this._self, this._then);

  final _UserProfile _self;
  final $Res Function(_UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? displayName = null,Object? status = null,Object? email = freezed,Object? photoPath = freezed,Object? themeMode = null,Object? signInMethods = null,Object? adultConfirmedAt = freezed,Object? acceptedTermsAt = freezed,}) {
  return _then(_UserProfile(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as UserStatus,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,photoPath: freezed == photoPath ? _self.photoPath : photoPath // ignore: cast_nullable_to_non_nullable
as String?,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as ThemePreference,signInMethods: null == signInMethods ? _self._signInMethods : signInMethods // ignore: cast_nullable_to_non_nullable
as List<String>,adultConfirmedAt: freezed == adultConfirmedAt ? _self.adultConfirmedAt : adultConfirmedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,acceptedTermsAt: freezed == acceptedTermsAt ? _self.acceptedTermsAt : acceptedTermsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
