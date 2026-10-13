// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthUser {

 String get uid; bool get emailVerified; String? get email; String? get displayName; bool get isSuperAdmin;/// Linked sign-in methods: `password`, `google.com`, `apple.com`. An
/// emailed sign-in link also adds `password`, with no password behind
/// it (AUTH-6).
 List<String> get providerIds;/// How this session signed in, from the ID token: `password`,
/// `emailLink`, `google.com`, or `apple.com`. `password` means the
/// account really has a password (AUTH-7).
 String? get signInProvider;/// When this device's session signed in (the ID token's auth_time).
/// "Sign out of all devices" ends sessions older than that (AUTH-9),
/// and method changes need it to be recent (AUTH-7).
 DateTime? get authTime;
/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthUserCopyWith<AuthUser> get copyWith => _$AuthUserCopyWithImpl<AuthUser>(this as AuthUser, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthUser;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthUser&&(identical(other.uid, _this.uid) || other.uid == _this.uid)&&(identical(other.emailVerified, _this.emailVerified) || other.emailVerified == _this.emailVerified)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.isSuperAdmin, _this.isSuperAdmin) || other.isSuperAdmin == _this.isSuperAdmin)&&const DeepCollectionEquality().equals(other.providerIds, _this.providerIds)&&(identical(other.signInProvider, _this.signInProvider) || other.signInProvider == _this.signInProvider)&&(identical(other.authTime, _this.authTime) || other.authTime == _this.authTime));
}


@override
int get hashCode {
  final _this = this as AuthUser;
  return Object.hash(runtimeType,_this.uid,_this.emailVerified,_this.email,_this.displayName,_this.isSuperAdmin,const DeepCollectionEquality().hash(_this.providerIds),_this.signInProvider,_this.authTime);
}

@override
String toString() {
  final _this = this as AuthUser;
  return 'AuthUser(uid: ${_this.uid}, emailVerified: ${_this.emailVerified}, email: ${_this.email}, displayName: ${_this.displayName}, isSuperAdmin: ${_this.isSuperAdmin}, providerIds: ${_this.providerIds}, signInProvider: ${_this.signInProvider}, authTime: ${_this.authTime})';
}


}

/// @nodoc
abstract mixin class $AuthUserCopyWith<$Res>  {
  factory $AuthUserCopyWith(AuthUser value, $Res Function(AuthUser) _then) = _$AuthUserCopyWithImpl;
@useResult
$Res call({
 String uid, bool emailVerified, String? email, String? displayName, bool isSuperAdmin, List<String> providerIds, String? signInProvider, DateTime? authTime
});




}
/// @nodoc
class _$AuthUserCopyWithImpl<$Res>
    implements $AuthUserCopyWith<$Res> {
  _$AuthUserCopyWithImpl(this._self, this._then);

  final AuthUser _self;
  final $Res Function(AuthUser) _then;

/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? emailVerified = null,Object? email = freezed,Object? displayName = freezed,Object? isSuperAdmin = null,Object? providerIds = null,Object? signInProvider = freezed,Object? authTime = freezed,}) {
  return _then(AuthUser(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,emailVerified: null == emailVerified ? _self.emailVerified : emailVerified // ignore: cast_nullable_to_non_nullable
as bool,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,isSuperAdmin: null == isSuperAdmin ? _self.isSuperAdmin : isSuperAdmin // ignore: cast_nullable_to_non_nullable
as bool,providerIds: null == providerIds ? _self.providerIds : providerIds // ignore: cast_nullable_to_non_nullable
as List<String>,signInProvider: freezed == signInProvider ? _self.signInProvider : signInProvider // ignore: cast_nullable_to_non_nullable
as String?,authTime: freezed == authTime ? _self.authTime : authTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthUser].
extension AuthUserPatterns on AuthUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthUser value)  $default,){
final _that = this;
switch (_that) {
case _AuthUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthUser value)?  $default,){
final _that = this;
switch (_that) {
case _AuthUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  bool emailVerified,  String? email,  String? displayName,  bool isSuperAdmin,  List<String> providerIds,  String? signInProvider,  DateTime? authTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthUser() when $default != null:
return $default(_that.uid,_that.emailVerified,_that.email,_that.displayName,_that.isSuperAdmin,_that.providerIds,_that.signInProvider,_that.authTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  bool emailVerified,  String? email,  String? displayName,  bool isSuperAdmin,  List<String> providerIds,  String? signInProvider,  DateTime? authTime)  $default,) {final _that = this;
switch (_that) {
case _AuthUser():
return $default(_that.uid,_that.emailVerified,_that.email,_that.displayName,_that.isSuperAdmin,_that.providerIds,_that.signInProvider,_that.authTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  bool emailVerified,  String? email,  String? displayName,  bool isSuperAdmin,  List<String> providerIds,  String? signInProvider,  DateTime? authTime)?  $default,) {final _that = this;
switch (_that) {
case _AuthUser() when $default != null:
return $default(_that.uid,_that.emailVerified,_that.email,_that.displayName,_that.isSuperAdmin,_that.providerIds,_that.signInProvider,_that.authTime);case _:
  return null;

}
}

}

/// @nodoc


class _AuthUser implements AuthUser {
  const _AuthUser({required this.uid, required this.emailVerified, this.email, this.displayName, this.isSuperAdmin = false,  List<String> providerIds = const <String>[], this.signInProvider, this.authTime}): _providerIds = providerIds;
  

@override final  String uid;
@override final  bool emailVerified;
@override final  String? email;
@override final  String? displayName;
@override@JsonKey() final  bool isSuperAdmin;
/// Linked sign-in methods: `password`, `google.com`, `apple.com`. An
/// emailed sign-in link also adds `password`, with no password behind
/// it (AUTH-6).
 final  List<String> _providerIds;
/// Linked sign-in methods: `password`, `google.com`, `apple.com`. An
/// emailed sign-in link also adds `password`, with no password behind
/// it (AUTH-6).
@override@JsonKey() List<String> get providerIds {
  if (_providerIds is EqualUnmodifiableListView) return _providerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_providerIds);
}

/// How this session signed in, from the ID token: `password`,
/// `emailLink`, `google.com`, or `apple.com`. `password` means the
/// account really has a password (AUTH-7).
@override final  String? signInProvider;
/// When this device's session signed in (the ID token's auth_time).
/// "Sign out of all devices" ends sessions older than that (AUTH-9),
/// and method changes need it to be recent (AUTH-7).
@override final  DateTime? authTime;

/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthUserCopyWith<_AuthUser> get copyWith => __$AuthUserCopyWithImpl<_AuthUser>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthUser&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.emailVerified, emailVerified) || other.emailVerified == emailVerified)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.isSuperAdmin, isSuperAdmin) || other.isSuperAdmin == isSuperAdmin)&&const DeepCollectionEquality().equals(other.providerIds, _providerIds)&&(identical(other.signInProvider, signInProvider) || other.signInProvider == signInProvider)&&(identical(other.authTime, authTime) || other.authTime == authTime));
}


@override
int get hashCode {
    return Object.hash(runtimeType,uid,emailVerified,email,displayName,isSuperAdmin,const DeepCollectionEquality().hash(_providerIds),signInProvider,authTime);
}

@override
String toString() {
    return 'AuthUser(uid: $uid, emailVerified: $emailVerified, email: $email, displayName: $displayName, isSuperAdmin: $isSuperAdmin, providerIds: $providerIds, signInProvider: $signInProvider, authTime: $authTime)';
}


}

/// @nodoc
abstract mixin class _$AuthUserCopyWith<$Res> implements $AuthUserCopyWith<$Res> {
  factory _$AuthUserCopyWith(_AuthUser value, $Res Function(_AuthUser) _then) = __$AuthUserCopyWithImpl;
@override @useResult
$Res call({
 String uid, bool emailVerified, String? email, String? displayName, bool isSuperAdmin, List<String> providerIds, String? signInProvider, DateTime? authTime
});




}
/// @nodoc
class __$AuthUserCopyWithImpl<$Res>
    implements _$AuthUserCopyWith<$Res> {
  __$AuthUserCopyWithImpl(this._self, this._then);

  final _AuthUser _self;
  final $Res Function(_AuthUser) _then;

/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? emailVerified = null,Object? email = freezed,Object? displayName = freezed,Object? isSuperAdmin = null,Object? providerIds = null,Object? signInProvider = freezed,Object? authTime = freezed,}) {
  return _then(_AuthUser(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,emailVerified: null == emailVerified ? _self.emailVerified : emailVerified // ignore: cast_nullable_to_non_nullable
as bool,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,isSuperAdmin: null == isSuperAdmin ? _self.isSuperAdmin : isSuperAdmin // ignore: cast_nullable_to_non_nullable
as bool,providerIds: null == providerIds ? _self._providerIds : providerIds // ignore: cast_nullable_to_non_nullable
as List<String>,signInProvider: freezed == signInProvider ? _self.signInProvider : signInProvider // ignore: cast_nullable_to_non_nullable
as String?,authTime: freezed == authTime ? _self.authTime : authTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
