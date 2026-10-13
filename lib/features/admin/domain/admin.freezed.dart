// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AdminTotals {

 int get users; int get teams;/// Teams created in the last 7 days.
 int get newTeams;/// Teams with a message in the last 7 days.
 int get activeTeams;/// Messages sent in the last 7 days.
 int get messages;/// Bytes stored across every team.
 int get storageBytes; int get openReports;
/// Create a copy of AdminTotals
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminTotalsCopyWith<AdminTotals> get copyWith => _$AdminTotalsCopyWithImpl<AdminTotals>(this as AdminTotals, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AdminTotals;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminTotals&&(identical(other.users, _this.users) || other.users == _this.users)&&(identical(other.teams, _this.teams) || other.teams == _this.teams)&&(identical(other.newTeams, _this.newTeams) || other.newTeams == _this.newTeams)&&(identical(other.activeTeams, _this.activeTeams) || other.activeTeams == _this.activeTeams)&&(identical(other.messages, _this.messages) || other.messages == _this.messages)&&(identical(other.storageBytes, _this.storageBytes) || other.storageBytes == _this.storageBytes)&&(identical(other.openReports, _this.openReports) || other.openReports == _this.openReports));
}


@override
int get hashCode {
  final _this = this as AdminTotals;
  return Object.hash(runtimeType,_this.users,_this.teams,_this.newTeams,_this.activeTeams,_this.messages,_this.storageBytes,_this.openReports);
}

@override
String toString() {
  final _this = this as AdminTotals;
  return 'AdminTotals(users: ${_this.users}, teams: ${_this.teams}, newTeams: ${_this.newTeams}, activeTeams: ${_this.activeTeams}, messages: ${_this.messages}, storageBytes: ${_this.storageBytes}, openReports: ${_this.openReports})';
}


}

/// @nodoc
abstract mixin class $AdminTotalsCopyWith<$Res>  {
  factory $AdminTotalsCopyWith(AdminTotals value, $Res Function(AdminTotals) _then) = _$AdminTotalsCopyWithImpl;
@useResult
$Res call({
 int users, int teams, int newTeams, int activeTeams, int messages, int storageBytes, int openReports
});




}
/// @nodoc
class _$AdminTotalsCopyWithImpl<$Res>
    implements $AdminTotalsCopyWith<$Res> {
  _$AdminTotalsCopyWithImpl(this._self, this._then);

  final AdminTotals _self;
  final $Res Function(AdminTotals) _then;

/// Create a copy of AdminTotals
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? users = null,Object? teams = null,Object? newTeams = null,Object? activeTeams = null,Object? messages = null,Object? storageBytes = null,Object? openReports = null,}) {
  return _then(AdminTotals(
users: null == users ? _self.users : users // ignore: cast_nullable_to_non_nullable
as int,teams: null == teams ? _self.teams : teams // ignore: cast_nullable_to_non_nullable
as int,newTeams: null == newTeams ? _self.newTeams : newTeams // ignore: cast_nullable_to_non_nullable
as int,activeTeams: null == activeTeams ? _self.activeTeams : activeTeams // ignore: cast_nullable_to_non_nullable
as int,messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as int,storageBytes: null == storageBytes ? _self.storageBytes : storageBytes // ignore: cast_nullable_to_non_nullable
as int,openReports: null == openReports ? _self.openReports : openReports // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminTotals].
extension AdminTotalsPatterns on AdminTotals {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminTotals value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminTotals() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminTotals value)  $default,){
final _that = this;
switch (_that) {
case _AdminTotals():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminTotals value)?  $default,){
final _that = this;
switch (_that) {
case _AdminTotals() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int users,  int teams,  int newTeams,  int activeTeams,  int messages,  int storageBytes,  int openReports)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminTotals() when $default != null:
return $default(_that.users,_that.teams,_that.newTeams,_that.activeTeams,_that.messages,_that.storageBytes,_that.openReports);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int users,  int teams,  int newTeams,  int activeTeams,  int messages,  int storageBytes,  int openReports)  $default,) {final _that = this;
switch (_that) {
case _AdminTotals():
return $default(_that.users,_that.teams,_that.newTeams,_that.activeTeams,_that.messages,_that.storageBytes,_that.openReports);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int users,  int teams,  int newTeams,  int activeTeams,  int messages,  int storageBytes,  int openReports)?  $default,) {final _that = this;
switch (_that) {
case _AdminTotals() when $default != null:
return $default(_that.users,_that.teams,_that.newTeams,_that.activeTeams,_that.messages,_that.storageBytes,_that.openReports);case _:
  return null;

}
}

}

/// @nodoc


class _AdminTotals implements AdminTotals {
  const _AdminTotals({this.users = 0, this.teams = 0, this.newTeams = 0, this.activeTeams = 0, this.messages = 0, this.storageBytes = 0, this.openReports = 0});
  

@override@JsonKey() final  int users;
@override@JsonKey() final  int teams;
/// Teams created in the last 7 days.
@override@JsonKey() final  int newTeams;
/// Teams with a message in the last 7 days.
@override@JsonKey() final  int activeTeams;
/// Messages sent in the last 7 days.
@override@JsonKey() final  int messages;
/// Bytes stored across every team.
@override@JsonKey() final  int storageBytes;
@override@JsonKey() final  int openReports;

/// Create a copy of AdminTotals
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminTotalsCopyWith<_AdminTotals> get copyWith => __$AdminTotalsCopyWithImpl<_AdminTotals>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminTotals&&(identical(other.users, users) || other.users == users)&&(identical(other.teams, teams) || other.teams == teams)&&(identical(other.newTeams, newTeams) || other.newTeams == newTeams)&&(identical(other.activeTeams, activeTeams) || other.activeTeams == activeTeams)&&(identical(other.messages, messages) || other.messages == messages)&&(identical(other.storageBytes, storageBytes) || other.storageBytes == storageBytes)&&(identical(other.openReports, openReports) || other.openReports == openReports));
}


@override
int get hashCode {
    return Object.hash(runtimeType,users,teams,newTeams,activeTeams,messages,storageBytes,openReports);
}

@override
String toString() {
    return 'AdminTotals(users: $users, teams: $teams, newTeams: $newTeams, activeTeams: $activeTeams, messages: $messages, storageBytes: $storageBytes, openReports: $openReports)';
}


}

/// @nodoc
abstract mixin class _$AdminTotalsCopyWith<$Res> implements $AdminTotalsCopyWith<$Res> {
  factory _$AdminTotalsCopyWith(_AdminTotals value, $Res Function(_AdminTotals) _then) = __$AdminTotalsCopyWithImpl;
@override @useResult
$Res call({
 int users, int teams, int newTeams, int activeTeams, int messages, int storageBytes, int openReports
});




}
/// @nodoc
class __$AdminTotalsCopyWithImpl<$Res>
    implements _$AdminTotalsCopyWith<$Res> {
  __$AdminTotalsCopyWithImpl(this._self, this._then);

  final _AdminTotals _self;
  final $Res Function(_AdminTotals) _then;

/// Create a copy of AdminTotals
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? users = null,Object? teams = null,Object? newTeams = null,Object? activeTeams = null,Object? messages = null,Object? storageBytes = null,Object? openReports = null,}) {
  return _then(_AdminTotals(
users: null == users ? _self.users : users // ignore: cast_nullable_to_non_nullable
as int,teams: null == teams ? _self.teams : teams // ignore: cast_nullable_to_non_nullable
as int,newTeams: null == newTeams ? _self.newTeams : newTeams // ignore: cast_nullable_to_non_nullable
as int,activeTeams: null == activeTeams ? _self.activeTeams : activeTeams // ignore: cast_nullable_to_non_nullable
as int,messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as int,storageBytes: null == storageBytes ? _self.storageBytes : storageBytes // ignore: cast_nullable_to_non_nullable
as int,openReports: null == openReports ? _self.openReports : openReports // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$AdminTeamQuery {

/// A name prefix; blank lists every team.
 String get query; AdminTeamSort get sort;/// Null shows every status.
 TeamStatus? get status;
/// Create a copy of AdminTeamQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminTeamQueryCopyWith<AdminTeamQuery> get copyWith => _$AdminTeamQueryCopyWithImpl<AdminTeamQuery>(this as AdminTeamQuery, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AdminTeamQuery;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminTeamQuery&&(identical(other.query, _this.query) || other.query == _this.query)&&(identical(other.sort, _this.sort) || other.sort == _this.sort)&&(identical(other.status, _this.status) || other.status == _this.status));
}


@override
int get hashCode {
  final _this = this as AdminTeamQuery;
  return Object.hash(runtimeType,_this.query,_this.sort,_this.status);
}

@override
String toString() {
  final _this = this as AdminTeamQuery;
  return 'AdminTeamQuery(query: ${_this.query}, sort: ${_this.sort}, status: ${_this.status})';
}


}

/// @nodoc
abstract mixin class $AdminTeamQueryCopyWith<$Res>  {
  factory $AdminTeamQueryCopyWith(AdminTeamQuery value, $Res Function(AdminTeamQuery) _then) = _$AdminTeamQueryCopyWithImpl;
@useResult
$Res call({
 String query, AdminTeamSort sort, TeamStatus? status
});




}
/// @nodoc
class _$AdminTeamQueryCopyWithImpl<$Res>
    implements $AdminTeamQueryCopyWith<$Res> {
  _$AdminTeamQueryCopyWithImpl(this._self, this._then);

  final AdminTeamQuery _self;
  final $Res Function(AdminTeamQuery) _then;

/// Create a copy of AdminTeamQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? sort = null,Object? status = freezed,}) {
  return _then(AdminTeamQuery(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as AdminTeamSort,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TeamStatus?,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminTeamQuery].
extension AdminTeamQueryPatterns on AdminTeamQuery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminTeamQuery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminTeamQuery() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminTeamQuery value)  $default,){
final _that = this;
switch (_that) {
case _AdminTeamQuery():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminTeamQuery value)?  $default,){
final _that = this;
switch (_that) {
case _AdminTeamQuery() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  AdminTeamSort sort,  TeamStatus? status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminTeamQuery() when $default != null:
return $default(_that.query,_that.sort,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  AdminTeamSort sort,  TeamStatus? status)  $default,) {final _that = this;
switch (_that) {
case _AdminTeamQuery():
return $default(_that.query,_that.sort,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  AdminTeamSort sort,  TeamStatus? status)?  $default,) {final _that = this;
switch (_that) {
case _AdminTeamQuery() when $default != null:
return $default(_that.query,_that.sort,_that.status);case _:
  return null;

}
}

}

/// @nodoc


class _AdminTeamQuery implements AdminTeamQuery {
  const _AdminTeamQuery({this.query = '', this.sort = AdminTeamSort.created, this.status});
  

/// A name prefix; blank lists every team.
@override@JsonKey() final  String query;
@override@JsonKey() final  AdminTeamSort sort;
/// Null shows every status.
@override final  TeamStatus? status;

/// Create a copy of AdminTeamQuery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminTeamQueryCopyWith<_AdminTeamQuery> get copyWith => __$AdminTeamQueryCopyWithImpl<_AdminTeamQuery>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminTeamQuery&&(identical(other.query, query) || other.query == query)&&(identical(other.sort, sort) || other.sort == sort)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode {
    return Object.hash(runtimeType,query,sort,status);
}

@override
String toString() {
    return 'AdminTeamQuery(query: $query, sort: $sort, status: $status)';
}


}

/// @nodoc
abstract mixin class _$AdminTeamQueryCopyWith<$Res> implements $AdminTeamQueryCopyWith<$Res> {
  factory _$AdminTeamQueryCopyWith(_AdminTeamQuery value, $Res Function(_AdminTeamQuery) _then) = __$AdminTeamQueryCopyWithImpl;
@override @useResult
$Res call({
 String query, AdminTeamSort sort, TeamStatus? status
});




}
/// @nodoc
class __$AdminTeamQueryCopyWithImpl<$Res>
    implements _$AdminTeamQueryCopyWith<$Res> {
  __$AdminTeamQueryCopyWithImpl(this._self, this._then);

  final _AdminTeamQuery _self;
  final $Res Function(_AdminTeamQuery) _then;

/// Create a copy of AdminTeamQuery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? sort = null,Object? status = freezed,}) {
  return _then(_AdminTeamQuery(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as AdminTeamSort,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TeamStatus?,
  ));
}


}

/// @nodoc
mixin _$AdminTeamRow {

 GroupId get id; String get name; Sport get sport; String? get ownerId; String get ownerName; int get memberCount; DateTime? get lastMessageAt; int get storageBytes; int get storageQuotaBytes; TeamStatus get status; DateTime? get createdAt;
/// Create a copy of AdminTeamRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminTeamRowCopyWith<AdminTeamRow> get copyWith => _$AdminTeamRowCopyWithImpl<AdminTeamRow>(this as AdminTeamRow, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AdminTeamRow;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminTeamRow&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.sport, _this.sport) || other.sport == _this.sport)&&(identical(other.ownerId, _this.ownerId) || other.ownerId == _this.ownerId)&&(identical(other.ownerName, _this.ownerName) || other.ownerName == _this.ownerName)&&(identical(other.memberCount, _this.memberCount) || other.memberCount == _this.memberCount)&&(identical(other.lastMessageAt, _this.lastMessageAt) || other.lastMessageAt == _this.lastMessageAt)&&(identical(other.storageBytes, _this.storageBytes) || other.storageBytes == _this.storageBytes)&&(identical(other.storageQuotaBytes, _this.storageQuotaBytes) || other.storageQuotaBytes == _this.storageQuotaBytes)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}


@override
int get hashCode {
  final _this = this as AdminTeamRow;
  return Object.hash(runtimeType,_this.id,_this.name,_this.sport,_this.ownerId,_this.ownerName,_this.memberCount,_this.lastMessageAt,_this.storageBytes,_this.storageQuotaBytes,_this.status,_this.createdAt);
}

@override
String toString() {
  final _this = this as AdminTeamRow;
  return 'AdminTeamRow(id: ${_this.id}, name: ${_this.name}, sport: ${_this.sport}, ownerId: ${_this.ownerId}, ownerName: ${_this.ownerName}, memberCount: ${_this.memberCount}, lastMessageAt: ${_this.lastMessageAt}, storageBytes: ${_this.storageBytes}, storageQuotaBytes: ${_this.storageQuotaBytes}, status: ${_this.status}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $AdminTeamRowCopyWith<$Res>  {
  factory $AdminTeamRowCopyWith(AdminTeamRow value, $Res Function(AdminTeamRow) _then) = _$AdminTeamRowCopyWithImpl;
@useResult
$Res call({
 GroupId id, String name, Sport sport, String? ownerId, String ownerName, int memberCount, DateTime? lastMessageAt, int storageBytes, int storageQuotaBytes, TeamStatus status, DateTime? createdAt
});




}
/// @nodoc
class _$AdminTeamRowCopyWithImpl<$Res>
    implements $AdminTeamRowCopyWith<$Res> {
  _$AdminTeamRowCopyWithImpl(this._self, this._then);

  final AdminTeamRow _self;
  final $Res Function(AdminTeamRow) _then;

/// Create a copy of AdminTeamRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? sport = null,Object? ownerId = freezed,Object? ownerName = null,Object? memberCount = null,Object? lastMessageAt = freezed,Object? storageBytes = null,Object? storageQuotaBytes = null,Object? status = null,Object? createdAt = freezed,}) {
  return _then(AdminTeamRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as GroupId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Sport,ownerId: freezed == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String?,ownerName: null == ownerName ? _self.ownerName : ownerName // ignore: cast_nullable_to_non_nullable
as String,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,storageBytes: null == storageBytes ? _self.storageBytes : storageBytes // ignore: cast_nullable_to_non_nullable
as int,storageQuotaBytes: null == storageQuotaBytes ? _self.storageQuotaBytes : storageQuotaBytes // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TeamStatus,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminTeamRow].
extension AdminTeamRowPatterns on AdminTeamRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminTeamRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminTeamRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminTeamRow value)  $default,){
final _that = this;
switch (_that) {
case _AdminTeamRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminTeamRow value)?  $default,){
final _that = this;
switch (_that) {
case _AdminTeamRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GroupId id,  String name,  Sport sport,  String? ownerId,  String ownerName,  int memberCount,  DateTime? lastMessageAt,  int storageBytes,  int storageQuotaBytes,  TeamStatus status,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminTeamRow() when $default != null:
return $default(_that.id,_that.name,_that.sport,_that.ownerId,_that.ownerName,_that.memberCount,_that.lastMessageAt,_that.storageBytes,_that.storageQuotaBytes,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GroupId id,  String name,  Sport sport,  String? ownerId,  String ownerName,  int memberCount,  DateTime? lastMessageAt,  int storageBytes,  int storageQuotaBytes,  TeamStatus status,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _AdminTeamRow():
return $default(_that.id,_that.name,_that.sport,_that.ownerId,_that.ownerName,_that.memberCount,_that.lastMessageAt,_that.storageBytes,_that.storageQuotaBytes,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GroupId id,  String name,  Sport sport,  String? ownerId,  String ownerName,  int memberCount,  DateTime? lastMessageAt,  int storageBytes,  int storageQuotaBytes,  TeamStatus status,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AdminTeamRow() when $default != null:
return $default(_that.id,_that.name,_that.sport,_that.ownerId,_that.ownerName,_that.memberCount,_that.lastMessageAt,_that.storageBytes,_that.storageQuotaBytes,_that.status,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _AdminTeamRow implements AdminTeamRow {
  const _AdminTeamRow({required this.id, required this.name, this.sport = Sport.other, this.ownerId, this.ownerName = '', this.memberCount = 0, this.lastMessageAt, this.storageBytes = 0, this.storageQuotaBytes = 0, this.status = TeamStatus.active, this.createdAt});
  

@override final  GroupId id;
@override final  String name;
@override@JsonKey() final  Sport sport;
@override final  String? ownerId;
@override@JsonKey() final  String ownerName;
@override@JsonKey() final  int memberCount;
@override final  DateTime? lastMessageAt;
@override@JsonKey() final  int storageBytes;
@override@JsonKey() final  int storageQuotaBytes;
@override@JsonKey() final  TeamStatus status;
@override final  DateTime? createdAt;

/// Create a copy of AdminTeamRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminTeamRowCopyWith<_AdminTeamRow> get copyWith => __$AdminTeamRowCopyWithImpl<_AdminTeamRow>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminTeamRow&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.sport, sport) || other.sport == sport)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.ownerName, ownerName) || other.ownerName == ownerName)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&(identical(other.storageBytes, storageBytes) || other.storageBytes == storageBytes)&&(identical(other.storageQuotaBytes, storageQuotaBytes) || other.storageQuotaBytes == storageQuotaBytes)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,sport,ownerId,ownerName,memberCount,lastMessageAt,storageBytes,storageQuotaBytes,status,createdAt);
}

@override
String toString() {
    return 'AdminTeamRow(id: $id, name: $name, sport: $sport, ownerId: $ownerId, ownerName: $ownerName, memberCount: $memberCount, lastMessageAt: $lastMessageAt, storageBytes: $storageBytes, storageQuotaBytes: $storageQuotaBytes, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AdminTeamRowCopyWith<$Res> implements $AdminTeamRowCopyWith<$Res> {
  factory _$AdminTeamRowCopyWith(_AdminTeamRow value, $Res Function(_AdminTeamRow) _then) = __$AdminTeamRowCopyWithImpl;
@override @useResult
$Res call({
 GroupId id, String name, Sport sport, String? ownerId, String ownerName, int memberCount, DateTime? lastMessageAt, int storageBytes, int storageQuotaBytes, TeamStatus status, DateTime? createdAt
});




}
/// @nodoc
class __$AdminTeamRowCopyWithImpl<$Res>
    implements _$AdminTeamRowCopyWith<$Res> {
  __$AdminTeamRowCopyWithImpl(this._self, this._then);

  final _AdminTeamRow _self;
  final $Res Function(_AdminTeamRow) _then;

/// Create a copy of AdminTeamRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? sport = null,Object? ownerId = freezed,Object? ownerName = null,Object? memberCount = null,Object? lastMessageAt = freezed,Object? storageBytes = null,Object? storageQuotaBytes = null,Object? status = null,Object? createdAt = freezed,}) {
  return _then(_AdminTeamRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as GroupId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Sport,ownerId: freezed == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String?,ownerName: null == ownerName ? _self.ownerName : ownerName // ignore: cast_nullable_to_non_nullable
as String,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,storageBytes: null == storageBytes ? _self.storageBytes : storageBytes // ignore: cast_nullable_to_non_nullable
as int,storageQuotaBytes: null == storageQuotaBytes ? _self.storageQuotaBytes : storageQuotaBytes // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TeamStatus,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$AdminInvite {

 String get code;/// True for the team's reusable link, false for an email invite.
 bool get isLink; String? get email; int get useCount; int? get maxUses; DateTime? get expiresAt; DateTime? get createdAt;
/// Create a copy of AdminInvite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminInviteCopyWith<AdminInvite> get copyWith => _$AdminInviteCopyWithImpl<AdminInvite>(this as AdminInvite, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AdminInvite;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminInvite&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.isLink, _this.isLink) || other.isLink == _this.isLink)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.useCount, _this.useCount) || other.useCount == _this.useCount)&&(identical(other.maxUses, _this.maxUses) || other.maxUses == _this.maxUses)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}


@override
int get hashCode {
  final _this = this as AdminInvite;
  return Object.hash(runtimeType,_this.code,_this.isLink,_this.email,_this.useCount,_this.maxUses,_this.expiresAt,_this.createdAt);
}

@override
String toString() {
  final _this = this as AdminInvite;
  return 'AdminInvite(code: ${_this.code}, isLink: ${_this.isLink}, email: ${_this.email}, useCount: ${_this.useCount}, maxUses: ${_this.maxUses}, expiresAt: ${_this.expiresAt}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $AdminInviteCopyWith<$Res>  {
  factory $AdminInviteCopyWith(AdminInvite value, $Res Function(AdminInvite) _then) = _$AdminInviteCopyWithImpl;
@useResult
$Res call({
 String code, bool isLink, String? email, int useCount, int? maxUses, DateTime? expiresAt, DateTime? createdAt
});




}
/// @nodoc
class _$AdminInviteCopyWithImpl<$Res>
    implements $AdminInviteCopyWith<$Res> {
  _$AdminInviteCopyWithImpl(this._self, this._then);

  final AdminInvite _self;
  final $Res Function(AdminInvite) _then;

/// Create a copy of AdminInvite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? isLink = null,Object? email = freezed,Object? useCount = null,Object? maxUses = freezed,Object? expiresAt = freezed,Object? createdAt = freezed,}) {
  return _then(AdminInvite(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,isLink: null == isLink ? _self.isLink : isLink // ignore: cast_nullable_to_non_nullable
as bool,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,useCount: null == useCount ? _self.useCount : useCount // ignore: cast_nullable_to_non_nullable
as int,maxUses: freezed == maxUses ? _self.maxUses : maxUses // ignore: cast_nullable_to_non_nullable
as int?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminInvite].
extension AdminInvitePatterns on AdminInvite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminInvite value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminInvite() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminInvite value)  $default,){
final _that = this;
switch (_that) {
case _AdminInvite():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminInvite value)?  $default,){
final _that = this;
switch (_that) {
case _AdminInvite() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  bool isLink,  String? email,  int useCount,  int? maxUses,  DateTime? expiresAt,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminInvite() when $default != null:
return $default(_that.code,_that.isLink,_that.email,_that.useCount,_that.maxUses,_that.expiresAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  bool isLink,  String? email,  int useCount,  int? maxUses,  DateTime? expiresAt,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _AdminInvite():
return $default(_that.code,_that.isLink,_that.email,_that.useCount,_that.maxUses,_that.expiresAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  bool isLink,  String? email,  int useCount,  int? maxUses,  DateTime? expiresAt,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AdminInvite() when $default != null:
return $default(_that.code,_that.isLink,_that.email,_that.useCount,_that.maxUses,_that.expiresAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _AdminInvite implements AdminInvite {
  const _AdminInvite({required this.code, this.isLink = true, this.email, this.useCount = 0, this.maxUses, this.expiresAt, this.createdAt});
  

@override final  String code;
/// True for the team's reusable link, false for an email invite.
@override@JsonKey() final  bool isLink;
@override final  String? email;
@override@JsonKey() final  int useCount;
@override final  int? maxUses;
@override final  DateTime? expiresAt;
@override final  DateTime? createdAt;

/// Create a copy of AdminInvite
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminInviteCopyWith<_AdminInvite> get copyWith => __$AdminInviteCopyWithImpl<_AdminInvite>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminInvite&&(identical(other.code, code) || other.code == code)&&(identical(other.isLink, isLink) || other.isLink == isLink)&&(identical(other.email, email) || other.email == email)&&(identical(other.useCount, useCount) || other.useCount == useCount)&&(identical(other.maxUses, maxUses) || other.maxUses == maxUses)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,code,isLink,email,useCount,maxUses,expiresAt,createdAt);
}

@override
String toString() {
    return 'AdminInvite(code: $code, isLink: $isLink, email: $email, useCount: $useCount, maxUses: $maxUses, expiresAt: $expiresAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AdminInviteCopyWith<$Res> implements $AdminInviteCopyWith<$Res> {
  factory _$AdminInviteCopyWith(_AdminInvite value, $Res Function(_AdminInvite) _then) = __$AdminInviteCopyWithImpl;
@override @useResult
$Res call({
 String code, bool isLink, String? email, int useCount, int? maxUses, DateTime? expiresAt, DateTime? createdAt
});




}
/// @nodoc
class __$AdminInviteCopyWithImpl<$Res>
    implements _$AdminInviteCopyWith<$Res> {
  __$AdminInviteCopyWithImpl(this._self, this._then);

  final _AdminInvite _self;
  final $Res Function(_AdminInvite) _then;

/// Create a copy of AdminInvite
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? isLink = null,Object? email = freezed,Object? useCount = null,Object? maxUses = freezed,Object? expiresAt = freezed,Object? createdAt = freezed,}) {
  return _then(_AdminInvite(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,isLink: null == isLink ? _self.isLink : isLink // ignore: cast_nullable_to_non_nullable
as bool,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,useCount: null == useCount ? _self.useCount : useCount // ignore: cast_nullable_to_non_nullable
as int,maxUses: freezed == maxUses ? _self.maxUses : maxUses // ignore: cast_nullable_to_non_nullable
as int?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$AdminMessage {

 String get id; String get authorName; String get text; int get photoCount; DateTime? get createdAt;
/// Create a copy of AdminMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminMessageCopyWith<AdminMessage> get copyWith => _$AdminMessageCopyWithImpl<AdminMessage>(this as AdminMessage, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AdminMessage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminMessage&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.authorName, _this.authorName) || other.authorName == _this.authorName)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.photoCount, _this.photoCount) || other.photoCount == _this.photoCount)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}


@override
int get hashCode {
  final _this = this as AdminMessage;
  return Object.hash(runtimeType,_this.id,_this.authorName,_this.text,_this.photoCount,_this.createdAt);
}

@override
String toString() {
  final _this = this as AdminMessage;
  return 'AdminMessage(id: ${_this.id}, authorName: ${_this.authorName}, text: ${_this.text}, photoCount: ${_this.photoCount}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $AdminMessageCopyWith<$Res>  {
  factory $AdminMessageCopyWith(AdminMessage value, $Res Function(AdminMessage) _then) = _$AdminMessageCopyWithImpl;
@useResult
$Res call({
 String id, String authorName, String text, int photoCount, DateTime? createdAt
});




}
/// @nodoc
class _$AdminMessageCopyWithImpl<$Res>
    implements $AdminMessageCopyWith<$Res> {
  _$AdminMessageCopyWithImpl(this._self, this._then);

  final AdminMessage _self;
  final $Res Function(AdminMessage) _then;

/// Create a copy of AdminMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? authorName = null,Object? text = null,Object? photoCount = null,Object? createdAt = freezed,}) {
  return _then(AdminMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,photoCount: null == photoCount ? _self.photoCount : photoCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminMessage].
extension AdminMessagePatterns on AdminMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminMessage value)  $default,){
final _that = this;
switch (_that) {
case _AdminMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminMessage value)?  $default,){
final _that = this;
switch (_that) {
case _AdminMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String authorName,  String text,  int photoCount,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminMessage() when $default != null:
return $default(_that.id,_that.authorName,_that.text,_that.photoCount,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String authorName,  String text,  int photoCount,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _AdminMessage():
return $default(_that.id,_that.authorName,_that.text,_that.photoCount,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String authorName,  String text,  int photoCount,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AdminMessage() when $default != null:
return $default(_that.id,_that.authorName,_that.text,_that.photoCount,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _AdminMessage implements AdminMessage {
  const _AdminMessage({required this.id, this.authorName = '', this.text = '', this.photoCount = 0, this.createdAt});
  

@override final  String id;
@override@JsonKey() final  String authorName;
@override@JsonKey() final  String text;
@override@JsonKey() final  int photoCount;
@override final  DateTime? createdAt;

/// Create a copy of AdminMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminMessageCopyWith<_AdminMessage> get copyWith => __$AdminMessageCopyWithImpl<_AdminMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.text, text) || other.text == text)&&(identical(other.photoCount, photoCount) || other.photoCount == photoCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,authorName,text,photoCount,createdAt);
}

@override
String toString() {
    return 'AdminMessage(id: $id, authorName: $authorName, text: $text, photoCount: $photoCount, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AdminMessageCopyWith<$Res> implements $AdminMessageCopyWith<$Res> {
  factory _$AdminMessageCopyWith(_AdminMessage value, $Res Function(_AdminMessage) _then) = __$AdminMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String authorName, String text, int photoCount, DateTime? createdAt
});




}
/// @nodoc
class __$AdminMessageCopyWithImpl<$Res>
    implements _$AdminMessageCopyWith<$Res> {
  __$AdminMessageCopyWithImpl(this._self, this._then);

  final _AdminMessage _self;
  final $Res Function(_AdminMessage) _then;

/// Create a copy of AdminMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? authorName = null,Object? text = null,Object? photoCount = null,Object? createdAt = freezed,}) {
  return _then(_AdminMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,photoCount: null == photoCount ? _self.photoCount : photoCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$AdminTeamDetail {

 GroupId get id; String get ownerName; TeamStatus get status; DateTime? get createdAt;/// Everyone on the team, with their roles.
 List<Membership> get members;/// The players (active and pending) and their links, as the player or
/// a guardian.
 List<Player> get players; List<GuardianLink> get guardians; List<AdminInvite> get invites;/// The latest messages, newest first, to review (ADMIN-3 Content).
 List<AdminMessage> get recentMessages; int get eventCount; int get documentCount; int get pollCount;
/// Create a copy of AdminTeamDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminTeamDetailCopyWith<AdminTeamDetail> get copyWith => _$AdminTeamDetailCopyWithImpl<AdminTeamDetail>(this as AdminTeamDetail, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AdminTeamDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminTeamDetail&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.ownerName, _this.ownerName) || other.ownerName == _this.ownerName)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&const DeepCollectionEquality().equals(other.members, _this.members)&&const DeepCollectionEquality().equals(other.players, _this.players)&&const DeepCollectionEquality().equals(other.guardians, _this.guardians)&&const DeepCollectionEquality().equals(other.invites, _this.invites)&&const DeepCollectionEquality().equals(other.recentMessages, _this.recentMessages)&&(identical(other.eventCount, _this.eventCount) || other.eventCount == _this.eventCount)&&(identical(other.documentCount, _this.documentCount) || other.documentCount == _this.documentCount)&&(identical(other.pollCount, _this.pollCount) || other.pollCount == _this.pollCount));
}


@override
int get hashCode {
  final _this = this as AdminTeamDetail;
  return Object.hash(runtimeType,_this.id,_this.ownerName,_this.status,_this.createdAt,const DeepCollectionEquality().hash(_this.members),const DeepCollectionEquality().hash(_this.players),const DeepCollectionEquality().hash(_this.guardians),const DeepCollectionEquality().hash(_this.invites),const DeepCollectionEquality().hash(_this.recentMessages),_this.eventCount,_this.documentCount,_this.pollCount);
}

@override
String toString() {
  final _this = this as AdminTeamDetail;
  return 'AdminTeamDetail(id: ${_this.id}, ownerName: ${_this.ownerName}, status: ${_this.status}, createdAt: ${_this.createdAt}, members: ${_this.members}, players: ${_this.players}, guardians: ${_this.guardians}, invites: ${_this.invites}, recentMessages: ${_this.recentMessages}, eventCount: ${_this.eventCount}, documentCount: ${_this.documentCount}, pollCount: ${_this.pollCount})';
}


}

/// @nodoc
abstract mixin class $AdminTeamDetailCopyWith<$Res>  {
  factory $AdminTeamDetailCopyWith(AdminTeamDetail value, $Res Function(AdminTeamDetail) _then) = _$AdminTeamDetailCopyWithImpl;
@useResult
$Res call({
 GroupId id, String ownerName, TeamStatus status, DateTime? createdAt, List<Membership> members, List<Player> players, List<GuardianLink> guardians, List<AdminInvite> invites, List<AdminMessage> recentMessages, int eventCount, int documentCount, int pollCount
});




}
/// @nodoc
class _$AdminTeamDetailCopyWithImpl<$Res>
    implements $AdminTeamDetailCopyWith<$Res> {
  _$AdminTeamDetailCopyWithImpl(this._self, this._then);

  final AdminTeamDetail _self;
  final $Res Function(AdminTeamDetail) _then;

/// Create a copy of AdminTeamDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ownerName = null,Object? status = null,Object? createdAt = freezed,Object? members = null,Object? players = null,Object? guardians = null,Object? invites = null,Object? recentMessages = null,Object? eventCount = null,Object? documentCount = null,Object? pollCount = null,}) {
  return _then(AdminTeamDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as GroupId,ownerName: null == ownerName ? _self.ownerName : ownerName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TeamStatus,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<Membership>,players: null == players ? _self.players : players // ignore: cast_nullable_to_non_nullable
as List<Player>,guardians: null == guardians ? _self.guardians : guardians // ignore: cast_nullable_to_non_nullable
as List<GuardianLink>,invites: null == invites ? _self.invites : invites // ignore: cast_nullable_to_non_nullable
as List<AdminInvite>,recentMessages: null == recentMessages ? _self.recentMessages : recentMessages // ignore: cast_nullable_to_non_nullable
as List<AdminMessage>,eventCount: null == eventCount ? _self.eventCount : eventCount // ignore: cast_nullable_to_non_nullable
as int,documentCount: null == documentCount ? _self.documentCount : documentCount // ignore: cast_nullable_to_non_nullable
as int,pollCount: null == pollCount ? _self.pollCount : pollCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminTeamDetail].
extension AdminTeamDetailPatterns on AdminTeamDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminTeamDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminTeamDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminTeamDetail value)  $default,){
final _that = this;
switch (_that) {
case _AdminTeamDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminTeamDetail value)?  $default,){
final _that = this;
switch (_that) {
case _AdminTeamDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GroupId id,  String ownerName,  TeamStatus status,  DateTime? createdAt,  List<Membership> members,  List<Player> players,  List<GuardianLink> guardians,  List<AdminInvite> invites,  List<AdminMessage> recentMessages,  int eventCount,  int documentCount,  int pollCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminTeamDetail() when $default != null:
return $default(_that.id,_that.ownerName,_that.status,_that.createdAt,_that.members,_that.players,_that.guardians,_that.invites,_that.recentMessages,_that.eventCount,_that.documentCount,_that.pollCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GroupId id,  String ownerName,  TeamStatus status,  DateTime? createdAt,  List<Membership> members,  List<Player> players,  List<GuardianLink> guardians,  List<AdminInvite> invites,  List<AdminMessage> recentMessages,  int eventCount,  int documentCount,  int pollCount)  $default,) {final _that = this;
switch (_that) {
case _AdminTeamDetail():
return $default(_that.id,_that.ownerName,_that.status,_that.createdAt,_that.members,_that.players,_that.guardians,_that.invites,_that.recentMessages,_that.eventCount,_that.documentCount,_that.pollCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GroupId id,  String ownerName,  TeamStatus status,  DateTime? createdAt,  List<Membership> members,  List<Player> players,  List<GuardianLink> guardians,  List<AdminInvite> invites,  List<AdminMessage> recentMessages,  int eventCount,  int documentCount,  int pollCount)?  $default,) {final _that = this;
switch (_that) {
case _AdminTeamDetail() when $default != null:
return $default(_that.id,_that.ownerName,_that.status,_that.createdAt,_that.members,_that.players,_that.guardians,_that.invites,_that.recentMessages,_that.eventCount,_that.documentCount,_that.pollCount);case _:
  return null;

}
}

}

/// @nodoc


class _AdminTeamDetail implements AdminTeamDetail {
  const _AdminTeamDetail({required this.id, this.ownerName = '', this.status = TeamStatus.active, this.createdAt,  List<Membership> members = const <Membership>[],  List<Player> players = const <Player>[],  List<GuardianLink> guardians = const <GuardianLink>[],  List<AdminInvite> invites = const <AdminInvite>[],  List<AdminMessage> recentMessages = const <AdminMessage>[], this.eventCount = 0, this.documentCount = 0, this.pollCount = 0}): _members = members,_players = players,_guardians = guardians,_invites = invites,_recentMessages = recentMessages;
  

@override final  GroupId id;
@override@JsonKey() final  String ownerName;
@override@JsonKey() final  TeamStatus status;
@override final  DateTime? createdAt;
/// Everyone on the team, with their roles.
 final  List<Membership> _members;
/// Everyone on the team, with their roles.
@override@JsonKey() List<Membership> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}

/// The players (active and pending) and their links, as the player or
/// a guardian.
 final  List<Player> _players;
/// The players (active and pending) and their links, as the player or
/// a guardian.
@override@JsonKey() List<Player> get players {
  if (_players is EqualUnmodifiableListView) return _players;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_players);
}

 final  List<GuardianLink> _guardians;
@override@JsonKey() List<GuardianLink> get guardians {
  if (_guardians is EqualUnmodifiableListView) return _guardians;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_guardians);
}

 final  List<AdminInvite> _invites;
@override@JsonKey() List<AdminInvite> get invites {
  if (_invites is EqualUnmodifiableListView) return _invites;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_invites);
}

/// The latest messages, newest first, to review (ADMIN-3 Content).
 final  List<AdminMessage> _recentMessages;
/// The latest messages, newest first, to review (ADMIN-3 Content).
@override@JsonKey() List<AdminMessage> get recentMessages {
  if (_recentMessages is EqualUnmodifiableListView) return _recentMessages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentMessages);
}

@override@JsonKey() final  int eventCount;
@override@JsonKey() final  int documentCount;
@override@JsonKey() final  int pollCount;

/// Create a copy of AdminTeamDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminTeamDetailCopyWith<_AdminTeamDetail> get copyWith => __$AdminTeamDetailCopyWithImpl<_AdminTeamDetail>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminTeamDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerName, ownerName) || other.ownerName == ownerName)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.members, _members)&&const DeepCollectionEquality().equals(other.players, _players)&&const DeepCollectionEquality().equals(other.guardians, _guardians)&&const DeepCollectionEquality().equals(other.invites, _invites)&&const DeepCollectionEquality().equals(other.recentMessages, _recentMessages)&&(identical(other.eventCount, eventCount) || other.eventCount == eventCount)&&(identical(other.documentCount, documentCount) || other.documentCount == documentCount)&&(identical(other.pollCount, pollCount) || other.pollCount == pollCount));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,ownerName,status,createdAt,const DeepCollectionEquality().hash(_members),const DeepCollectionEquality().hash(_players),const DeepCollectionEquality().hash(_guardians),const DeepCollectionEquality().hash(_invites),const DeepCollectionEquality().hash(_recentMessages),eventCount,documentCount,pollCount);
}

@override
String toString() {
    return 'AdminTeamDetail(id: $id, ownerName: $ownerName, status: $status, createdAt: $createdAt, members: $members, players: $players, guardians: $guardians, invites: $invites, recentMessages: $recentMessages, eventCount: $eventCount, documentCount: $documentCount, pollCount: $pollCount)';
}


}

/// @nodoc
abstract mixin class _$AdminTeamDetailCopyWith<$Res> implements $AdminTeamDetailCopyWith<$Res> {
  factory _$AdminTeamDetailCopyWith(_AdminTeamDetail value, $Res Function(_AdminTeamDetail) _then) = __$AdminTeamDetailCopyWithImpl;
@override @useResult
$Res call({
 GroupId id, String ownerName, TeamStatus status, DateTime? createdAt, List<Membership> members, List<Player> players, List<GuardianLink> guardians, List<AdminInvite> invites, List<AdminMessage> recentMessages, int eventCount, int documentCount, int pollCount
});




}
/// @nodoc
class __$AdminTeamDetailCopyWithImpl<$Res>
    implements _$AdminTeamDetailCopyWith<$Res> {
  __$AdminTeamDetailCopyWithImpl(this._self, this._then);

  final _AdminTeamDetail _self;
  final $Res Function(_AdminTeamDetail) _then;

/// Create a copy of AdminTeamDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ownerName = null,Object? status = null,Object? createdAt = freezed,Object? members = null,Object? players = null,Object? guardians = null,Object? invites = null,Object? recentMessages = null,Object? eventCount = null,Object? documentCount = null,Object? pollCount = null,}) {
  return _then(_AdminTeamDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as GroupId,ownerName: null == ownerName ? _self.ownerName : ownerName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TeamStatus,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<Membership>,players: null == players ? _self._players : players // ignore: cast_nullable_to_non_nullable
as List<Player>,guardians: null == guardians ? _self._guardians : guardians // ignore: cast_nullable_to_non_nullable
as List<GuardianLink>,invites: null == invites ? _self._invites : invites // ignore: cast_nullable_to_non_nullable
as List<AdminInvite>,recentMessages: null == recentMessages ? _self._recentMessages : recentMessages // ignore: cast_nullable_to_non_nullable
as List<AdminMessage>,eventCount: null == eventCount ? _self.eventCount : eventCount // ignore: cast_nullable_to_non_nullable
as int,documentCount: null == documentCount ? _self.documentCount : documentCount // ignore: cast_nullable_to_non_nullable
as int,pollCount: null == pollCount ? _self.pollCount : pollCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$AdminUserQuery {

/// A name or email prefix; blank lists everyone.
 String get query; AdminUserFilter? get filter;
/// Create a copy of AdminUserQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminUserQueryCopyWith<AdminUserQuery> get copyWith => _$AdminUserQueryCopyWithImpl<AdminUserQuery>(this as AdminUserQuery, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AdminUserQuery;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminUserQuery&&(identical(other.query, _this.query) || other.query == _this.query)&&(identical(other.filter, _this.filter) || other.filter == _this.filter));
}


@override
int get hashCode {
  final _this = this as AdminUserQuery;
  return Object.hash(runtimeType,_this.query,_this.filter);
}

@override
String toString() {
  final _this = this as AdminUserQuery;
  return 'AdminUserQuery(query: ${_this.query}, filter: ${_this.filter})';
}


}

/// @nodoc
abstract mixin class $AdminUserQueryCopyWith<$Res>  {
  factory $AdminUserQueryCopyWith(AdminUserQuery value, $Res Function(AdminUserQuery) _then) = _$AdminUserQueryCopyWithImpl;
@useResult
$Res call({
 String query, AdminUserFilter? filter
});




}
/// @nodoc
class _$AdminUserQueryCopyWithImpl<$Res>
    implements $AdminUserQueryCopyWith<$Res> {
  _$AdminUserQueryCopyWithImpl(this._self, this._then);

  final AdminUserQuery _self;
  final $Res Function(AdminUserQuery) _then;

/// Create a copy of AdminUserQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? filter = freezed,}) {
  return _then(AdminUserQuery(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,filter: freezed == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as AdminUserFilter?,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminUserQuery].
extension AdminUserQueryPatterns on AdminUserQuery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminUserQuery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminUserQuery() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminUserQuery value)  $default,){
final _that = this;
switch (_that) {
case _AdminUserQuery():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminUserQuery value)?  $default,){
final _that = this;
switch (_that) {
case _AdminUserQuery() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  AdminUserFilter? filter)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminUserQuery() when $default != null:
return $default(_that.query,_that.filter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  AdminUserFilter? filter)  $default,) {final _that = this;
switch (_that) {
case _AdminUserQuery():
return $default(_that.query,_that.filter);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  AdminUserFilter? filter)?  $default,) {final _that = this;
switch (_that) {
case _AdminUserQuery() when $default != null:
return $default(_that.query,_that.filter);case _:
  return null;

}
}

}

/// @nodoc


class _AdminUserQuery implements AdminUserQuery {
  const _AdminUserQuery({this.query = '', this.filter});
  

/// A name or email prefix; blank lists everyone.
@override@JsonKey() final  String query;
@override final  AdminUserFilter? filter;

/// Create a copy of AdminUserQuery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminUserQueryCopyWith<_AdminUserQuery> get copyWith => __$AdminUserQueryCopyWithImpl<_AdminUserQuery>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminUserQuery&&(identical(other.query, query) || other.query == query)&&(identical(other.filter, filter) || other.filter == filter));
}


@override
int get hashCode {
    return Object.hash(runtimeType,query,filter);
}

@override
String toString() {
    return 'AdminUserQuery(query: $query, filter: $filter)';
}


}

/// @nodoc
abstract mixin class _$AdminUserQueryCopyWith<$Res> implements $AdminUserQueryCopyWith<$Res> {
  factory _$AdminUserQueryCopyWith(_AdminUserQuery value, $Res Function(_AdminUserQuery) _then) = __$AdminUserQueryCopyWithImpl;
@override @useResult
$Res call({
 String query, AdminUserFilter? filter
});




}
/// @nodoc
class __$AdminUserQueryCopyWithImpl<$Res>
    implements _$AdminUserQueryCopyWith<$Res> {
  __$AdminUserQueryCopyWithImpl(this._self, this._then);

  final _AdminUserQuery _self;
  final $Res Function(_AdminUserQuery) _then;

/// Create a copy of AdminUserQuery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? filter = freezed,}) {
  return _then(_AdminUserQuery(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,filter: freezed == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as AdminUserFilter?,
  ));
}


}

/// @nodoc
mixin _$AdminUserRow {

 UserId get uid; String get displayName; String? get email; UserStatus get status; bool get superAdmin; DateTime? get createdAt; DateTime? get lastActiveAt;
/// Create a copy of AdminUserRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminUserRowCopyWith<AdminUserRow> get copyWith => _$AdminUserRowCopyWithImpl<AdminUserRow>(this as AdminUserRow, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AdminUserRow;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminUserRow&&(identical(other.uid, _this.uid) || other.uid == _this.uid)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.superAdmin, _this.superAdmin) || other.superAdmin == _this.superAdmin)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.lastActiveAt, _this.lastActiveAt) || other.lastActiveAt == _this.lastActiveAt));
}


@override
int get hashCode {
  final _this = this as AdminUserRow;
  return Object.hash(runtimeType,_this.uid,_this.displayName,_this.email,_this.status,_this.superAdmin,_this.createdAt,_this.lastActiveAt);
}

@override
String toString() {
  final _this = this as AdminUserRow;
  return 'AdminUserRow(uid: ${_this.uid}, displayName: ${_this.displayName}, email: ${_this.email}, status: ${_this.status}, superAdmin: ${_this.superAdmin}, createdAt: ${_this.createdAt}, lastActiveAt: ${_this.lastActiveAt})';
}


}

/// @nodoc
abstract mixin class $AdminUserRowCopyWith<$Res>  {
  factory $AdminUserRowCopyWith(AdminUserRow value, $Res Function(AdminUserRow) _then) = _$AdminUserRowCopyWithImpl;
@useResult
$Res call({
 UserId uid, String displayName, String? email, UserStatus status, bool superAdmin, DateTime? createdAt, DateTime? lastActiveAt
});




}
/// @nodoc
class _$AdminUserRowCopyWithImpl<$Res>
    implements $AdminUserRowCopyWith<$Res> {
  _$AdminUserRowCopyWithImpl(this._self, this._then);

  final AdminUserRow _self;
  final $Res Function(AdminUserRow) _then;

/// Create a copy of AdminUserRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? displayName = null,Object? email = freezed,Object? status = null,Object? superAdmin = null,Object? createdAt = freezed,Object? lastActiveAt = freezed,}) {
  return _then(AdminUserRow(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as UserId,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as UserStatus,superAdmin: null == superAdmin ? _self.superAdmin : superAdmin // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastActiveAt: freezed == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminUserRow].
extension AdminUserRowPatterns on AdminUserRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminUserRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminUserRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminUserRow value)  $default,){
final _that = this;
switch (_that) {
case _AdminUserRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminUserRow value)?  $default,){
final _that = this;
switch (_that) {
case _AdminUserRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UserId uid,  String displayName,  String? email,  UserStatus status,  bool superAdmin,  DateTime? createdAt,  DateTime? lastActiveAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminUserRow() when $default != null:
return $default(_that.uid,_that.displayName,_that.email,_that.status,_that.superAdmin,_that.createdAt,_that.lastActiveAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UserId uid,  String displayName,  String? email,  UserStatus status,  bool superAdmin,  DateTime? createdAt,  DateTime? lastActiveAt)  $default,) {final _that = this;
switch (_that) {
case _AdminUserRow():
return $default(_that.uid,_that.displayName,_that.email,_that.status,_that.superAdmin,_that.createdAt,_that.lastActiveAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UserId uid,  String displayName,  String? email,  UserStatus status,  bool superAdmin,  DateTime? createdAt,  DateTime? lastActiveAt)?  $default,) {final _that = this;
switch (_that) {
case _AdminUserRow() when $default != null:
return $default(_that.uid,_that.displayName,_that.email,_that.status,_that.superAdmin,_that.createdAt,_that.lastActiveAt);case _:
  return null;

}
}

}

/// @nodoc


class _AdminUserRow implements AdminUserRow {
  const _AdminUserRow({required this.uid, this.displayName = '', this.email, this.status = UserStatus.active, this.superAdmin = false, this.createdAt, this.lastActiveAt});
  

@override final  UserId uid;
@override@JsonKey() final  String displayName;
@override final  String? email;
@override@JsonKey() final  UserStatus status;
@override@JsonKey() final  bool superAdmin;
@override final  DateTime? createdAt;
@override final  DateTime? lastActiveAt;

/// Create a copy of AdminUserRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminUserRowCopyWith<_AdminUserRow> get copyWith => __$AdminUserRowCopyWithImpl<_AdminUserRow>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminUserRow&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.status, status) || other.status == status)&&(identical(other.superAdmin, superAdmin) || other.superAdmin == superAdmin)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,uid,displayName,email,status,superAdmin,createdAt,lastActiveAt);
}

@override
String toString() {
    return 'AdminUserRow(uid: $uid, displayName: $displayName, email: $email, status: $status, superAdmin: $superAdmin, createdAt: $createdAt, lastActiveAt: $lastActiveAt)';
}


}

/// @nodoc
abstract mixin class _$AdminUserRowCopyWith<$Res> implements $AdminUserRowCopyWith<$Res> {
  factory _$AdminUserRowCopyWith(_AdminUserRow value, $Res Function(_AdminUserRow) _then) = __$AdminUserRowCopyWithImpl;
@override @useResult
$Res call({
 UserId uid, String displayName, String? email, UserStatus status, bool superAdmin, DateTime? createdAt, DateTime? lastActiveAt
});




}
/// @nodoc
class __$AdminUserRowCopyWithImpl<$Res>
    implements _$AdminUserRowCopyWith<$Res> {
  __$AdminUserRowCopyWithImpl(this._self, this._then);

  final _AdminUserRow _self;
  final $Res Function(_AdminUserRow) _then;

/// Create a copy of AdminUserRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? displayName = null,Object? email = freezed,Object? status = null,Object? superAdmin = null,Object? createdAt = freezed,Object? lastActiveAt = freezed,}) {
  return _then(_AdminUserRow(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as UserId,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as UserStatus,superAdmin: null == superAdmin ? _self.superAdmin : superAdmin // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastActiveAt: freezed == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$AdminUserTeam {

 GroupId get groupId; String get name; MemberRole get role;
/// Create a copy of AdminUserTeam
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminUserTeamCopyWith<AdminUserTeam> get copyWith => _$AdminUserTeamCopyWithImpl<AdminUserTeam>(this as AdminUserTeam, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AdminUserTeam;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminUserTeam&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.role, _this.role) || other.role == _this.role));
}


@override
int get hashCode {
  final _this = this as AdminUserTeam;
  return Object.hash(runtimeType,_this.groupId,_this.name,_this.role);
}

@override
String toString() {
  final _this = this as AdminUserTeam;
  return 'AdminUserTeam(groupId: ${_this.groupId}, name: ${_this.name}, role: ${_this.role})';
}


}

/// @nodoc
abstract mixin class $AdminUserTeamCopyWith<$Res>  {
  factory $AdminUserTeamCopyWith(AdminUserTeam value, $Res Function(AdminUserTeam) _then) = _$AdminUserTeamCopyWithImpl;
@useResult
$Res call({
 GroupId groupId, String name, MemberRole role
});




}
/// @nodoc
class _$AdminUserTeamCopyWithImpl<$Res>
    implements $AdminUserTeamCopyWith<$Res> {
  _$AdminUserTeamCopyWithImpl(this._self, this._then);

  final AdminUserTeam _self;
  final $Res Function(AdminUserTeam) _then;

/// Create a copy of AdminUserTeam
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groupId = null,Object? name = null,Object? role = null,}) {
  return _then(AdminUserTeam(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as MemberRole,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminUserTeam].
extension AdminUserTeamPatterns on AdminUserTeam {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminUserTeam value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminUserTeam() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminUserTeam value)  $default,){
final _that = this;
switch (_that) {
case _AdminUserTeam():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminUserTeam value)?  $default,){
final _that = this;
switch (_that) {
case _AdminUserTeam() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GroupId groupId,  String name,  MemberRole role)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminUserTeam() when $default != null:
return $default(_that.groupId,_that.name,_that.role);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GroupId groupId,  String name,  MemberRole role)  $default,) {final _that = this;
switch (_that) {
case _AdminUserTeam():
return $default(_that.groupId,_that.name,_that.role);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GroupId groupId,  String name,  MemberRole role)?  $default,) {final _that = this;
switch (_that) {
case _AdminUserTeam() when $default != null:
return $default(_that.groupId,_that.name,_that.role);case _:
  return null;

}
}

}

/// @nodoc


class _AdminUserTeam implements AdminUserTeam {
  const _AdminUserTeam({required this.groupId, this.name = '', this.role = MemberRole.member});
  

@override final  GroupId groupId;
@override@JsonKey() final  String name;
@override@JsonKey() final  MemberRole role;

/// Create a copy of AdminUserTeam
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminUserTeamCopyWith<_AdminUserTeam> get copyWith => __$AdminUserTeamCopyWithImpl<_AdminUserTeam>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminUserTeam&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.name, name) || other.name == name)&&(identical(other.role, role) || other.role == role));
}


@override
int get hashCode {
    return Object.hash(runtimeType,groupId,name,role);
}

@override
String toString() {
    return 'AdminUserTeam(groupId: $groupId, name: $name, role: $role)';
}


}

/// @nodoc
abstract mixin class _$AdminUserTeamCopyWith<$Res> implements $AdminUserTeamCopyWith<$Res> {
  factory _$AdminUserTeamCopyWith(_AdminUserTeam value, $Res Function(_AdminUserTeam) _then) = __$AdminUserTeamCopyWithImpl;
@override @useResult
$Res call({
 GroupId groupId, String name, MemberRole role
});




}
/// @nodoc
class __$AdminUserTeamCopyWithImpl<$Res>
    implements _$AdminUserTeamCopyWith<$Res> {
  __$AdminUserTeamCopyWithImpl(this._self, this._then);

  final _AdminUserTeam _self;
  final $Res Function(_AdminUserTeam) _then;

/// Create a copy of AdminUserTeam
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? groupId = null,Object? name = null,Object? role = null,}) {
  return _then(_AdminUserTeam(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as MemberRole,
  ));
}


}

/// @nodoc
mixin _$AdminUserDetail {

 AdminUserRow get user;/// `password`, `google.com`, `apple.com`.
 List<String> get signInMethods; List<AdminUserTeam> get teams;
/// Create a copy of AdminUserDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminUserDetailCopyWith<AdminUserDetail> get copyWith => _$AdminUserDetailCopyWithImpl<AdminUserDetail>(this as AdminUserDetail, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AdminUserDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminUserDetail&&(identical(other.user, _this.user) || other.user == _this.user)&&const DeepCollectionEquality().equals(other.signInMethods, _this.signInMethods)&&const DeepCollectionEquality().equals(other.teams, _this.teams));
}


@override
int get hashCode {
  final _this = this as AdminUserDetail;
  return Object.hash(runtimeType,_this.user,const DeepCollectionEquality().hash(_this.signInMethods),const DeepCollectionEquality().hash(_this.teams));
}

@override
String toString() {
  final _this = this as AdminUserDetail;
  return 'AdminUserDetail(user: ${_this.user}, signInMethods: ${_this.signInMethods}, teams: ${_this.teams})';
}


}

/// @nodoc
abstract mixin class $AdminUserDetailCopyWith<$Res>  {
  factory $AdminUserDetailCopyWith(AdminUserDetail value, $Res Function(AdminUserDetail) _then) = _$AdminUserDetailCopyWithImpl;
@useResult
$Res call({
 AdminUserRow user, List<String> signInMethods, List<AdminUserTeam> teams
});


$AdminUserRowCopyWith<$Res> get user;

}
/// @nodoc
class _$AdminUserDetailCopyWithImpl<$Res>
    implements $AdminUserDetailCopyWith<$Res> {
  _$AdminUserDetailCopyWithImpl(this._self, this._then);

  final AdminUserDetail _self;
  final $Res Function(AdminUserDetail) _then;

/// Create a copy of AdminUserDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? user = null,Object? signInMethods = null,Object? teams = null,}) {
  return _then(AdminUserDetail(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AdminUserRow,signInMethods: null == signInMethods ? _self.signInMethods : signInMethods // ignore: cast_nullable_to_non_nullable
as List<String>,teams: null == teams ? _self.teams : teams // ignore: cast_nullable_to_non_nullable
as List<AdminUserTeam>,
  ));
}
/// Create a copy of AdminUserDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminUserRowCopyWith<$Res> get user {
  
  return $AdminUserRowCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [AdminUserDetail].
extension AdminUserDetailPatterns on AdminUserDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminUserDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminUserDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminUserDetail value)  $default,){
final _that = this;
switch (_that) {
case _AdminUserDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminUserDetail value)?  $default,){
final _that = this;
switch (_that) {
case _AdminUserDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AdminUserRow user,  List<String> signInMethods,  List<AdminUserTeam> teams)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminUserDetail() when $default != null:
return $default(_that.user,_that.signInMethods,_that.teams);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AdminUserRow user,  List<String> signInMethods,  List<AdminUserTeam> teams)  $default,) {final _that = this;
switch (_that) {
case _AdminUserDetail():
return $default(_that.user,_that.signInMethods,_that.teams);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AdminUserRow user,  List<String> signInMethods,  List<AdminUserTeam> teams)?  $default,) {final _that = this;
switch (_that) {
case _AdminUserDetail() when $default != null:
return $default(_that.user,_that.signInMethods,_that.teams);case _:
  return null;

}
}

}

/// @nodoc


class _AdminUserDetail implements AdminUserDetail {
  const _AdminUserDetail({required this.user,  List<String> signInMethods = const <String>[],  List<AdminUserTeam> teams = const <AdminUserTeam>[]}): _signInMethods = signInMethods,_teams = teams;
  

@override final  AdminUserRow user;
/// `password`, `google.com`, `apple.com`.
 final  List<String> _signInMethods;
/// `password`, `google.com`, `apple.com`.
@override@JsonKey() List<String> get signInMethods {
  if (_signInMethods is EqualUnmodifiableListView) return _signInMethods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_signInMethods);
}

 final  List<AdminUserTeam> _teams;
@override@JsonKey() List<AdminUserTeam> get teams {
  if (_teams is EqualUnmodifiableListView) return _teams;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_teams);
}


/// Create a copy of AdminUserDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminUserDetailCopyWith<_AdminUserDetail> get copyWith => __$AdminUserDetailCopyWithImpl<_AdminUserDetail>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminUserDetail&&(identical(other.user, user) || other.user == user)&&const DeepCollectionEquality().equals(other.signInMethods, _signInMethods)&&const DeepCollectionEquality().equals(other.teams, _teams));
}


@override
int get hashCode {
    return Object.hash(runtimeType,user,const DeepCollectionEquality().hash(_signInMethods),const DeepCollectionEquality().hash(_teams));
}

@override
String toString() {
    return 'AdminUserDetail(user: $user, signInMethods: $signInMethods, teams: $teams)';
}


}

/// @nodoc
abstract mixin class _$AdminUserDetailCopyWith<$Res> implements $AdminUserDetailCopyWith<$Res> {
  factory _$AdminUserDetailCopyWith(_AdminUserDetail value, $Res Function(_AdminUserDetail) _then) = __$AdminUserDetailCopyWithImpl;
@override @useResult
$Res call({
 AdminUserRow user, List<String> signInMethods, List<AdminUserTeam> teams
});


@override $AdminUserRowCopyWith<$Res> get user;

}
/// @nodoc
class __$AdminUserDetailCopyWithImpl<$Res>
    implements _$AdminUserDetailCopyWith<$Res> {
  __$AdminUserDetailCopyWithImpl(this._self, this._then);

  final _AdminUserDetail _self;
  final $Res Function(_AdminUserDetail) _then;

/// Create a copy of AdminUserDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? user = null,Object? signInMethods = null,Object? teams = null,}) {
  return _then(_AdminUserDetail(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AdminUserRow,signInMethods: null == signInMethods ? _self._signInMethods : signInMethods // ignore: cast_nullable_to_non_nullable
as List<String>,teams: null == teams ? _self._teams : teams // ignore: cast_nullable_to_non_nullable
as List<AdminUserTeam>,
  ));
}

/// Create a copy of AdminUserDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminUserRowCopyWith<$Res> get user {
  
  return $AdminUserRowCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

/// @nodoc
mixin _$AdminReport {

 String get id; GroupId get groupId; String get groupName; ReportTargetType get targetType; String get targetId; ReportReason get reason;/// The person it's about, and a copy of what was reported.
 String get subjectId; String get subjectName; String get excerpt; String? get details; String get reporterId; String get reporterName; ReportStatus get status;/// How it was closed, and the super admin's note.
 String? get resolution; String? get note; DateTime? get createdAt;
/// Create a copy of AdminReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminReportCopyWith<AdminReport> get copyWith => _$AdminReportCopyWithImpl<AdminReport>(this as AdminReport, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AdminReport;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminReport&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.groupName, _this.groupName) || other.groupName == _this.groupName)&&(identical(other.targetType, _this.targetType) || other.targetType == _this.targetType)&&(identical(other.targetId, _this.targetId) || other.targetId == _this.targetId)&&(identical(other.reason, _this.reason) || other.reason == _this.reason)&&(identical(other.subjectId, _this.subjectId) || other.subjectId == _this.subjectId)&&(identical(other.subjectName, _this.subjectName) || other.subjectName == _this.subjectName)&&(identical(other.excerpt, _this.excerpt) || other.excerpt == _this.excerpt)&&(identical(other.details, _this.details) || other.details == _this.details)&&(identical(other.reporterId, _this.reporterId) || other.reporterId == _this.reporterId)&&(identical(other.reporterName, _this.reporterName) || other.reporterName == _this.reporterName)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.resolution, _this.resolution) || other.resolution == _this.resolution)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}


@override
int get hashCode {
  final _this = this as AdminReport;
  return Object.hash(runtimeType,_this.id,_this.groupId,_this.groupName,_this.targetType,_this.targetId,_this.reason,_this.subjectId,_this.subjectName,_this.excerpt,_this.details,_this.reporterId,_this.reporterName,_this.status,_this.resolution,_this.note,_this.createdAt);
}

@override
String toString() {
  final _this = this as AdminReport;
  return 'AdminReport(id: ${_this.id}, groupId: ${_this.groupId}, groupName: ${_this.groupName}, targetType: ${_this.targetType}, targetId: ${_this.targetId}, reason: ${_this.reason}, subjectId: ${_this.subjectId}, subjectName: ${_this.subjectName}, excerpt: ${_this.excerpt}, details: ${_this.details}, reporterId: ${_this.reporterId}, reporterName: ${_this.reporterName}, status: ${_this.status}, resolution: ${_this.resolution}, note: ${_this.note}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $AdminReportCopyWith<$Res>  {
  factory $AdminReportCopyWith(AdminReport value, $Res Function(AdminReport) _then) = _$AdminReportCopyWithImpl;
@useResult
$Res call({
 String id, GroupId groupId, String groupName, ReportTargetType targetType, String targetId, ReportReason reason, String subjectId, String subjectName, String excerpt, String? details, String reporterId, String reporterName, ReportStatus status, String? resolution, String? note, DateTime? createdAt
});




}
/// @nodoc
class _$AdminReportCopyWithImpl<$Res>
    implements $AdminReportCopyWith<$Res> {
  _$AdminReportCopyWithImpl(this._self, this._then);

  final AdminReport _self;
  final $Res Function(AdminReport) _then;

/// Create a copy of AdminReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? groupId = null,Object? groupName = null,Object? targetType = null,Object? targetId = null,Object? reason = null,Object? subjectId = null,Object? subjectName = null,Object? excerpt = null,Object? details = freezed,Object? reporterId = null,Object? reporterName = null,Object? status = null,Object? resolution = freezed,Object? note = freezed,Object? createdAt = freezed,}) {
  return _then(AdminReport(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,groupName: null == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as ReportTargetType,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as ReportReason,subjectId: null == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String,subjectName: null == subjectName ? _self.subjectName : subjectName // ignore: cast_nullable_to_non_nullable
as String,excerpt: null == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as String,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String?,reporterId: null == reporterId ? _self.reporterId : reporterId // ignore: cast_nullable_to_non_nullable
as String,reporterName: null == reporterName ? _self.reporterName : reporterName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReportStatus,resolution: freezed == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminReport].
extension AdminReportPatterns on AdminReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminReport value)  $default,){
final _that = this;
switch (_that) {
case _AdminReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminReport value)?  $default,){
final _that = this;
switch (_that) {
case _AdminReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  GroupId groupId,  String groupName,  ReportTargetType targetType,  String targetId,  ReportReason reason,  String subjectId,  String subjectName,  String excerpt,  String? details,  String reporterId,  String reporterName,  ReportStatus status,  String? resolution,  String? note,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminReport() when $default != null:
return $default(_that.id,_that.groupId,_that.groupName,_that.targetType,_that.targetId,_that.reason,_that.subjectId,_that.subjectName,_that.excerpt,_that.details,_that.reporterId,_that.reporterName,_that.status,_that.resolution,_that.note,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  GroupId groupId,  String groupName,  ReportTargetType targetType,  String targetId,  ReportReason reason,  String subjectId,  String subjectName,  String excerpt,  String? details,  String reporterId,  String reporterName,  ReportStatus status,  String? resolution,  String? note,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _AdminReport():
return $default(_that.id,_that.groupId,_that.groupName,_that.targetType,_that.targetId,_that.reason,_that.subjectId,_that.subjectName,_that.excerpt,_that.details,_that.reporterId,_that.reporterName,_that.status,_that.resolution,_that.note,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  GroupId groupId,  String groupName,  ReportTargetType targetType,  String targetId,  ReportReason reason,  String subjectId,  String subjectName,  String excerpt,  String? details,  String reporterId,  String reporterName,  ReportStatus status,  String? resolution,  String? note,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AdminReport() when $default != null:
return $default(_that.id,_that.groupId,_that.groupName,_that.targetType,_that.targetId,_that.reason,_that.subjectId,_that.subjectName,_that.excerpt,_that.details,_that.reporterId,_that.reporterName,_that.status,_that.resolution,_that.note,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _AdminReport implements AdminReport {
  const _AdminReport({required this.id, required this.groupId, this.groupName = '', this.targetType = ReportTargetType.message, this.targetId = '', this.reason = ReportReason.other, this.subjectId = '', this.subjectName = '', this.excerpt = '', this.details, this.reporterId = '', this.reporterName = '', this.status = ReportStatus.open, this.resolution, this.note, this.createdAt});
  

@override final  String id;
@override final  GroupId groupId;
@override@JsonKey() final  String groupName;
@override@JsonKey() final  ReportTargetType targetType;
@override@JsonKey() final  String targetId;
@override@JsonKey() final  ReportReason reason;
/// The person it's about, and a copy of what was reported.
@override@JsonKey() final  String subjectId;
@override@JsonKey() final  String subjectName;
@override@JsonKey() final  String excerpt;
@override final  String? details;
@override@JsonKey() final  String reporterId;
@override@JsonKey() final  String reporterName;
@override@JsonKey() final  ReportStatus status;
/// How it was closed, and the super admin's note.
@override final  String? resolution;
@override final  String? note;
@override final  DateTime? createdAt;

/// Create a copy of AdminReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminReportCopyWith<_AdminReport> get copyWith => __$AdminReportCopyWithImpl<_AdminReport>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminReport&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.subjectId, subjectId) || other.subjectId == subjectId)&&(identical(other.subjectName, subjectName) || other.subjectName == subjectName)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt)&&(identical(other.details, details) || other.details == details)&&(identical(other.reporterId, reporterId) || other.reporterId == reporterId)&&(identical(other.reporterName, reporterName) || other.reporterName == reporterName)&&(identical(other.status, status) || other.status == status)&&(identical(other.resolution, resolution) || other.resolution == resolution)&&(identical(other.note, note) || other.note == note)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,groupId,groupName,targetType,targetId,reason,subjectId,subjectName,excerpt,details,reporterId,reporterName,status,resolution,note,createdAt);
}

@override
String toString() {
    return 'AdminReport(id: $id, groupId: $groupId, groupName: $groupName, targetType: $targetType, targetId: $targetId, reason: $reason, subjectId: $subjectId, subjectName: $subjectName, excerpt: $excerpt, details: $details, reporterId: $reporterId, reporterName: $reporterName, status: $status, resolution: $resolution, note: $note, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AdminReportCopyWith<$Res> implements $AdminReportCopyWith<$Res> {
  factory _$AdminReportCopyWith(_AdminReport value, $Res Function(_AdminReport) _then) = __$AdminReportCopyWithImpl;
@override @useResult
$Res call({
 String id, GroupId groupId, String groupName, ReportTargetType targetType, String targetId, ReportReason reason, String subjectId, String subjectName, String excerpt, String? details, String reporterId, String reporterName, ReportStatus status, String? resolution, String? note, DateTime? createdAt
});




}
/// @nodoc
class __$AdminReportCopyWithImpl<$Res>
    implements _$AdminReportCopyWith<$Res> {
  __$AdminReportCopyWithImpl(this._self, this._then);

  final _AdminReport _self;
  final $Res Function(_AdminReport) _then;

/// Create a copy of AdminReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? groupId = null,Object? groupName = null,Object? targetType = null,Object? targetId = null,Object? reason = null,Object? subjectId = null,Object? subjectName = null,Object? excerpt = null,Object? details = freezed,Object? reporterId = null,Object? reporterName = null,Object? status = null,Object? resolution = freezed,Object? note = freezed,Object? createdAt = freezed,}) {
  return _then(_AdminReport(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,groupName: null == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as ReportTargetType,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as ReportReason,subjectId: null == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String,subjectName: null == subjectName ? _self.subjectName : subjectName // ignore: cast_nullable_to_non_nullable
as String,excerpt: null == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as String,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String?,reporterId: null == reporterId ? _self.reporterId : reporterId // ignore: cast_nullable_to_non_nullable
as String,reporterName: null == reporterName ? _self.reporterName : reporterName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReportStatus,resolution: freezed == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$AuditEntry {

 String get id; String get actorId; String get action; GroupId? get groupId; String get targetType; String get targetId; Map<String, Object?>? get before; Map<String, Object?>? get after; DateTime? get createdAt;
/// Create a copy of AuditEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuditEntryCopyWith<AuditEntry> get copyWith => _$AuditEntryCopyWithImpl<AuditEntry>(this as AuditEntry, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuditEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuditEntry&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.actorId, _this.actorId) || other.actorId == _this.actorId)&&(identical(other.action, _this.action) || other.action == _this.action)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.targetType, _this.targetType) || other.targetType == _this.targetType)&&(identical(other.targetId, _this.targetId) || other.targetId == _this.targetId)&&const DeepCollectionEquality().equals(other.before, _this.before)&&const DeepCollectionEquality().equals(other.after, _this.after)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}


@override
int get hashCode {
  final _this = this as AuditEntry;
  return Object.hash(runtimeType,_this.id,_this.actorId,_this.action,_this.groupId,_this.targetType,_this.targetId,const DeepCollectionEquality().hash(_this.before),const DeepCollectionEquality().hash(_this.after),_this.createdAt);
}

@override
String toString() {
  final _this = this as AuditEntry;
  return 'AuditEntry(id: ${_this.id}, actorId: ${_this.actorId}, action: ${_this.action}, groupId: ${_this.groupId}, targetType: ${_this.targetType}, targetId: ${_this.targetId}, before: ${_this.before}, after: ${_this.after}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $AuditEntryCopyWith<$Res>  {
  factory $AuditEntryCopyWith(AuditEntry value, $Res Function(AuditEntry) _then) = _$AuditEntryCopyWithImpl;
@useResult
$Res call({
 String id, String actorId, String action, GroupId? groupId, String targetType, String targetId, Map<String, Object?>? before, Map<String, Object?>? after, DateTime? createdAt
});




}
/// @nodoc
class _$AuditEntryCopyWithImpl<$Res>
    implements $AuditEntryCopyWith<$Res> {
  _$AuditEntryCopyWithImpl(this._self, this._then);

  final AuditEntry _self;
  final $Res Function(AuditEntry) _then;

/// Create a copy of AuditEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? actorId = null,Object? action = null,Object? groupId = freezed,Object? targetType = null,Object? targetId = null,Object? before = freezed,Object? after = freezed,Object? createdAt = freezed,}) {
  return _then(AuditEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,actorId: null == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId?,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,before: freezed == before ? _self.before : before // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,after: freezed == after ? _self.after : after // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuditEntry].
extension AuditEntryPatterns on AuditEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuditEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuditEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuditEntry value)  $default,){
final _that = this;
switch (_that) {
case _AuditEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuditEntry value)?  $default,){
final _that = this;
switch (_that) {
case _AuditEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String actorId,  String action,  GroupId? groupId,  String targetType,  String targetId,  Map<String, Object?>? before,  Map<String, Object?>? after,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuditEntry() when $default != null:
return $default(_that.id,_that.actorId,_that.action,_that.groupId,_that.targetType,_that.targetId,_that.before,_that.after,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String actorId,  String action,  GroupId? groupId,  String targetType,  String targetId,  Map<String, Object?>? before,  Map<String, Object?>? after,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _AuditEntry():
return $default(_that.id,_that.actorId,_that.action,_that.groupId,_that.targetType,_that.targetId,_that.before,_that.after,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String actorId,  String action,  GroupId? groupId,  String targetType,  String targetId,  Map<String, Object?>? before,  Map<String, Object?>? after,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AuditEntry() when $default != null:
return $default(_that.id,_that.actorId,_that.action,_that.groupId,_that.targetType,_that.targetId,_that.before,_that.after,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _AuditEntry implements AuditEntry {
  const _AuditEntry({required this.id, required this.actorId, required this.action, this.groupId, this.targetType = '', this.targetId = '',  Map<String, Object?>? before,  Map<String, Object?>? after, this.createdAt}): _before = before,_after = after;
  

@override final  String id;
@override final  String actorId;
@override final  String action;
@override final  GroupId? groupId;
@override@JsonKey() final  String targetType;
@override@JsonKey() final  String targetId;
 final  Map<String, Object?>? _before;
@override Map<String, Object?>? get before {
  final value = _before;
  if (value == null) return null;
  if (_before is EqualUnmodifiableMapView) return _before;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, Object?>? _after;
@override Map<String, Object?>? get after {
  final value = _after;
  if (value == null) return null;
  if (_after is EqualUnmodifiableMapView) return _after;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  DateTime? createdAt;

/// Create a copy of AuditEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuditEntryCopyWith<_AuditEntry> get copyWith => __$AuditEntryCopyWithImpl<_AuditEntry>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuditEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.actorId, actorId) || other.actorId == actorId)&&(identical(other.action, action) || other.action == action)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&const DeepCollectionEquality().equals(other.before, _before)&&const DeepCollectionEquality().equals(other.after, _after)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,actorId,action,groupId,targetType,targetId,const DeepCollectionEquality().hash(_before),const DeepCollectionEquality().hash(_after),createdAt);
}

@override
String toString() {
    return 'AuditEntry(id: $id, actorId: $actorId, action: $action, groupId: $groupId, targetType: $targetType, targetId: $targetId, before: $before, after: $after, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AuditEntryCopyWith<$Res> implements $AuditEntryCopyWith<$Res> {
  factory _$AuditEntryCopyWith(_AuditEntry value, $Res Function(_AuditEntry) _then) = __$AuditEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String actorId, String action, GroupId? groupId, String targetType, String targetId, Map<String, Object?>? before, Map<String, Object?>? after, DateTime? createdAt
});




}
/// @nodoc
class __$AuditEntryCopyWithImpl<$Res>
    implements _$AuditEntryCopyWith<$Res> {
  __$AuditEntryCopyWithImpl(this._self, this._then);

  final _AuditEntry _self;
  final $Res Function(_AuditEntry) _then;

/// Create a copy of AuditEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? actorId = null,Object? action = null,Object? groupId = freezed,Object? targetType = null,Object? targetId = null,Object? before = freezed,Object? after = freezed,Object? createdAt = freezed,}) {
  return _then(_AuditEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,actorId: null == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId?,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,before: freezed == before ? _self._before : before // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,after: freezed == after ? _self._after : after // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$AuditFilter {

 String? get actorId; String? get action; GroupId? get groupId;/// From the start of [from] through the end of [until], local days.
 DateTime? get from; DateTime? get until;
/// Create a copy of AuditFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuditFilterCopyWith<AuditFilter> get copyWith => _$AuditFilterCopyWithImpl<AuditFilter>(this as AuditFilter, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuditFilter;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuditFilter&&(identical(other.actorId, _this.actorId) || other.actorId == _this.actorId)&&(identical(other.action, _this.action) || other.action == _this.action)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.from, _this.from) || other.from == _this.from)&&(identical(other.until, _this.until) || other.until == _this.until));
}


@override
int get hashCode {
  final _this = this as AuditFilter;
  return Object.hash(runtimeType,_this.actorId,_this.action,_this.groupId,_this.from,_this.until);
}

@override
String toString() {
  final _this = this as AuditFilter;
  return 'AuditFilter(actorId: ${_this.actorId}, action: ${_this.action}, groupId: ${_this.groupId}, from: ${_this.from}, until: ${_this.until})';
}


}

/// @nodoc
abstract mixin class $AuditFilterCopyWith<$Res>  {
  factory $AuditFilterCopyWith(AuditFilter value, $Res Function(AuditFilter) _then) = _$AuditFilterCopyWithImpl;
@useResult
$Res call({
 String? actorId, String? action, GroupId? groupId, DateTime? from, DateTime? until
});




}
/// @nodoc
class _$AuditFilterCopyWithImpl<$Res>
    implements $AuditFilterCopyWith<$Res> {
  _$AuditFilterCopyWithImpl(this._self, this._then);

  final AuditFilter _self;
  final $Res Function(AuditFilter) _then;

/// Create a copy of AuditFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? actorId = freezed,Object? action = freezed,Object? groupId = freezed,Object? from = freezed,Object? until = freezed,}) {
  return _then(AuditFilter(
actorId: freezed == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String?,action: freezed == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String?,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId?,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as DateTime?,until: freezed == until ? _self.until : until // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuditFilter].
extension AuditFilterPatterns on AuditFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuditFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuditFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuditFilter value)  $default,){
final _that = this;
switch (_that) {
case _AuditFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuditFilter value)?  $default,){
final _that = this;
switch (_that) {
case _AuditFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? actorId,  String? action,  GroupId? groupId,  DateTime? from,  DateTime? until)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuditFilter() when $default != null:
return $default(_that.actorId,_that.action,_that.groupId,_that.from,_that.until);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? actorId,  String? action,  GroupId? groupId,  DateTime? from,  DateTime? until)  $default,) {final _that = this;
switch (_that) {
case _AuditFilter():
return $default(_that.actorId,_that.action,_that.groupId,_that.from,_that.until);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? actorId,  String? action,  GroupId? groupId,  DateTime? from,  DateTime? until)?  $default,) {final _that = this;
switch (_that) {
case _AuditFilter() when $default != null:
return $default(_that.actorId,_that.action,_that.groupId,_that.from,_that.until);case _:
  return null;

}
}

}

/// @nodoc


class _AuditFilter extends AuditFilter {
  const _AuditFilter({this.actorId, this.action, this.groupId, this.from, this.until}): super._();
  

@override final  String? actorId;
@override final  String? action;
@override final  GroupId? groupId;
/// From the start of [from] through the end of [until], local days.
@override final  DateTime? from;
@override final  DateTime? until;

/// Create a copy of AuditFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuditFilterCopyWith<_AuditFilter> get copyWith => __$AuditFilterCopyWithImpl<_AuditFilter>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuditFilter&&(identical(other.actorId, actorId) || other.actorId == actorId)&&(identical(other.action, action) || other.action == action)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.from, from) || other.from == from)&&(identical(other.until, until) || other.until == until));
}


@override
int get hashCode {
    return Object.hash(runtimeType,actorId,action,groupId,from,until);
}

@override
String toString() {
    return 'AuditFilter(actorId: $actorId, action: $action, groupId: $groupId, from: $from, until: $until)';
}


}

/// @nodoc
abstract mixin class _$AuditFilterCopyWith<$Res> implements $AuditFilterCopyWith<$Res> {
  factory _$AuditFilterCopyWith(_AuditFilter value, $Res Function(_AuditFilter) _then) = __$AuditFilterCopyWithImpl;
@override @useResult
$Res call({
 String? actorId, String? action, GroupId? groupId, DateTime? from, DateTime? until
});




}
/// @nodoc
class __$AuditFilterCopyWithImpl<$Res>
    implements _$AuditFilterCopyWith<$Res> {
  __$AuditFilterCopyWithImpl(this._self, this._then);

  final _AuditFilter _self;
  final $Res Function(_AuditFilter) _then;

/// Create a copy of AuditFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? actorId = freezed,Object? action = freezed,Object? groupId = freezed,Object? from = freezed,Object? until = freezed,}) {
  return _then(_AuditFilter(
actorId: freezed == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String?,action: freezed == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String?,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId?,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as DateTime?,until: freezed == until ? _self.until : until // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$Announcement {

 String get text; BannerSeverity get severity; DateTime get expiresAt;
/// Create a copy of Announcement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnnouncementCopyWith<Announcement> get copyWith => _$AnnouncementCopyWithImpl<Announcement>(this as Announcement, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Announcement;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Announcement&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.severity, _this.severity) || other.severity == _this.severity)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt));
}


@override
int get hashCode {
  final _this = this as Announcement;
  return Object.hash(runtimeType,_this.text,_this.severity,_this.expiresAt);
}

@override
String toString() {
  final _this = this as Announcement;
  return 'Announcement(text: ${_this.text}, severity: ${_this.severity}, expiresAt: ${_this.expiresAt})';
}


}

/// @nodoc
abstract mixin class $AnnouncementCopyWith<$Res>  {
  factory $AnnouncementCopyWith(Announcement value, $Res Function(Announcement) _then) = _$AnnouncementCopyWithImpl;
@useResult
$Res call({
 String text, BannerSeverity severity, DateTime expiresAt
});




}
/// @nodoc
class _$AnnouncementCopyWithImpl<$Res>
    implements $AnnouncementCopyWith<$Res> {
  _$AnnouncementCopyWithImpl(this._self, this._then);

  final Announcement _self;
  final $Res Function(Announcement) _then;

/// Create a copy of Announcement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? severity = null,Object? expiresAt = null,}) {
  return _then(Announcement(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as BannerSeverity,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Announcement].
extension AnnouncementPatterns on Announcement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Announcement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Announcement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Announcement value)  $default,){
final _that = this;
switch (_that) {
case _Announcement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Announcement value)?  $default,){
final _that = this;
switch (_that) {
case _Announcement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  BannerSeverity severity,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Announcement() when $default != null:
return $default(_that.text,_that.severity,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  BannerSeverity severity,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _Announcement():
return $default(_that.text,_that.severity,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  BannerSeverity severity,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _Announcement() when $default != null:
return $default(_that.text,_that.severity,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc


class _Announcement extends Announcement {
  const _Announcement({required this.text, required this.severity, required this.expiresAt}): super._();
  

@override final  String text;
@override final  BannerSeverity severity;
@override final  DateTime expiresAt;

/// Create a copy of Announcement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnnouncementCopyWith<_Announcement> get copyWith => __$AnnouncementCopyWithImpl<_Announcement>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Announcement&&(identical(other.text, text) || other.text == text)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,text,severity,expiresAt);
}

@override
String toString() {
    return 'Announcement(text: $text, severity: $severity, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$AnnouncementCopyWith<$Res> implements $AnnouncementCopyWith<$Res> {
  factory _$AnnouncementCopyWith(_Announcement value, $Res Function(_Announcement) _then) = __$AnnouncementCopyWithImpl;
@override @useResult
$Res call({
 String text, BannerSeverity severity, DateTime expiresAt
});




}
/// @nodoc
class __$AnnouncementCopyWithImpl<$Res>
    implements _$AnnouncementCopyWith<$Res> {
  __$AnnouncementCopyWithImpl(this._self, this._then);

  final _Announcement _self;
  final $Res Function(_Announcement) _then;

/// Create a copy of Announcement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? severity = null,Object? expiresAt = null,}) {
  return _then(_Announcement(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as BannerSeverity,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$AppConfig {

 bool get allowUserGroupCreation; int get maxGroupsCreatedPerUserPerDay; int get defaultStorageQuotaMb; int get maxUploadMb; String get supportEmail; Announcement? get announcementBanner;
/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigCopyWith<AppConfig> get copyWith => _$AppConfigCopyWithImpl<AppConfig>(this as AppConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfig&&(identical(other.allowUserGroupCreation, _this.allowUserGroupCreation) || other.allowUserGroupCreation == _this.allowUserGroupCreation)&&(identical(other.maxGroupsCreatedPerUserPerDay, _this.maxGroupsCreatedPerUserPerDay) || other.maxGroupsCreatedPerUserPerDay == _this.maxGroupsCreatedPerUserPerDay)&&(identical(other.defaultStorageQuotaMb, _this.defaultStorageQuotaMb) || other.defaultStorageQuotaMb == _this.defaultStorageQuotaMb)&&(identical(other.maxUploadMb, _this.maxUploadMb) || other.maxUploadMb == _this.maxUploadMb)&&(identical(other.supportEmail, _this.supportEmail) || other.supportEmail == _this.supportEmail)&&(identical(other.announcementBanner, _this.announcementBanner) || other.announcementBanner == _this.announcementBanner));
}


@override
int get hashCode {
  final _this = this as AppConfig;
  return Object.hash(runtimeType,_this.allowUserGroupCreation,_this.maxGroupsCreatedPerUserPerDay,_this.defaultStorageQuotaMb,_this.maxUploadMb,_this.supportEmail,_this.announcementBanner);
}

@override
String toString() {
  final _this = this as AppConfig;
  return 'AppConfig(allowUserGroupCreation: ${_this.allowUserGroupCreation}, maxGroupsCreatedPerUserPerDay: ${_this.maxGroupsCreatedPerUserPerDay}, defaultStorageQuotaMb: ${_this.defaultStorageQuotaMb}, maxUploadMb: ${_this.maxUploadMb}, supportEmail: ${_this.supportEmail}, announcementBanner: ${_this.announcementBanner})';
}


}

/// @nodoc
abstract mixin class $AppConfigCopyWith<$Res>  {
  factory $AppConfigCopyWith(AppConfig value, $Res Function(AppConfig) _then) = _$AppConfigCopyWithImpl;
@useResult
$Res call({
 bool allowUserGroupCreation, int maxGroupsCreatedPerUserPerDay, int defaultStorageQuotaMb, int maxUploadMb, String supportEmail, Announcement? announcementBanner
});


$AnnouncementCopyWith<$Res>? get announcementBanner;

}
/// @nodoc
class _$AppConfigCopyWithImpl<$Res>
    implements $AppConfigCopyWith<$Res> {
  _$AppConfigCopyWithImpl(this._self, this._then);

  final AppConfig _self;
  final $Res Function(AppConfig) _then;

/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? allowUserGroupCreation = null,Object? maxGroupsCreatedPerUserPerDay = null,Object? defaultStorageQuotaMb = null,Object? maxUploadMb = null,Object? supportEmail = null,Object? announcementBanner = freezed,}) {
  return _then(AppConfig(
allowUserGroupCreation: null == allowUserGroupCreation ? _self.allowUserGroupCreation : allowUserGroupCreation // ignore: cast_nullable_to_non_nullable
as bool,maxGroupsCreatedPerUserPerDay: null == maxGroupsCreatedPerUserPerDay ? _self.maxGroupsCreatedPerUserPerDay : maxGroupsCreatedPerUserPerDay // ignore: cast_nullable_to_non_nullable
as int,defaultStorageQuotaMb: null == defaultStorageQuotaMb ? _self.defaultStorageQuotaMb : defaultStorageQuotaMb // ignore: cast_nullable_to_non_nullable
as int,maxUploadMb: null == maxUploadMb ? _self.maxUploadMb : maxUploadMb // ignore: cast_nullable_to_non_nullable
as int,supportEmail: null == supportEmail ? _self.supportEmail : supportEmail // ignore: cast_nullable_to_non_nullable
as String,announcementBanner: freezed == announcementBanner ? _self.announcementBanner : announcementBanner // ignore: cast_nullable_to_non_nullable
as Announcement?,
  ));
}
/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AnnouncementCopyWith<$Res>? get announcementBanner {
    if (_self.announcementBanner == null) {
    return null;
  }

  return $AnnouncementCopyWith<$Res>(_self.announcementBanner!, (value) {
    return _then(_self.copyWith(announcementBanner: value));
  });
}
}


/// Adds pattern-matching-related methods to [AppConfig].
extension AppConfigPatterns on AppConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppConfig value)  $default,){
final _that = this;
switch (_that) {
case _AppConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppConfig value)?  $default,){
final _that = this;
switch (_that) {
case _AppConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool allowUserGroupCreation,  int maxGroupsCreatedPerUserPerDay,  int defaultStorageQuotaMb,  int maxUploadMb,  String supportEmail,  Announcement? announcementBanner)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppConfig() when $default != null:
return $default(_that.allowUserGroupCreation,_that.maxGroupsCreatedPerUserPerDay,_that.defaultStorageQuotaMb,_that.maxUploadMb,_that.supportEmail,_that.announcementBanner);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool allowUserGroupCreation,  int maxGroupsCreatedPerUserPerDay,  int defaultStorageQuotaMb,  int maxUploadMb,  String supportEmail,  Announcement? announcementBanner)  $default,) {final _that = this;
switch (_that) {
case _AppConfig():
return $default(_that.allowUserGroupCreation,_that.maxGroupsCreatedPerUserPerDay,_that.defaultStorageQuotaMb,_that.maxUploadMb,_that.supportEmail,_that.announcementBanner);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool allowUserGroupCreation,  int maxGroupsCreatedPerUserPerDay,  int defaultStorageQuotaMb,  int maxUploadMb,  String supportEmail,  Announcement? announcementBanner)?  $default,) {final _that = this;
switch (_that) {
case _AppConfig() when $default != null:
return $default(_that.allowUserGroupCreation,_that.maxGroupsCreatedPerUserPerDay,_that.defaultStorageQuotaMb,_that.maxUploadMb,_that.supportEmail,_that.announcementBanner);case _:
  return null;

}
}

}

/// @nodoc


class _AppConfig extends AppConfig {
  const _AppConfig({this.allowUserGroupCreation = true, this.maxGroupsCreatedPerUserPerDay = Limits.groupsCreatedPerUserPerDay, this.defaultStorageQuotaMb = Limits.defaultStorageQuotaMb, this.maxUploadMb = Limits.maxUploadMb, this.supportEmail = '', this.announcementBanner}): super._();
  

@override@JsonKey() final  bool allowUserGroupCreation;
@override@JsonKey() final  int maxGroupsCreatedPerUserPerDay;
@override@JsonKey() final  int defaultStorageQuotaMb;
@override@JsonKey() final  int maxUploadMb;
@override@JsonKey() final  String supportEmail;
@override final  Announcement? announcementBanner;

/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppConfigCopyWith<_AppConfig> get copyWith => __$AppConfigCopyWithImpl<_AppConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppConfig&&(identical(other.allowUserGroupCreation, allowUserGroupCreation) || other.allowUserGroupCreation == allowUserGroupCreation)&&(identical(other.maxGroupsCreatedPerUserPerDay, maxGroupsCreatedPerUserPerDay) || other.maxGroupsCreatedPerUserPerDay == maxGroupsCreatedPerUserPerDay)&&(identical(other.defaultStorageQuotaMb, defaultStorageQuotaMb) || other.defaultStorageQuotaMb == defaultStorageQuotaMb)&&(identical(other.maxUploadMb, maxUploadMb) || other.maxUploadMb == maxUploadMb)&&(identical(other.supportEmail, supportEmail) || other.supportEmail == supportEmail)&&(identical(other.announcementBanner, announcementBanner) || other.announcementBanner == announcementBanner));
}


@override
int get hashCode {
    return Object.hash(runtimeType,allowUserGroupCreation,maxGroupsCreatedPerUserPerDay,defaultStorageQuotaMb,maxUploadMb,supportEmail,announcementBanner);
}

@override
String toString() {
    return 'AppConfig(allowUserGroupCreation: $allowUserGroupCreation, maxGroupsCreatedPerUserPerDay: $maxGroupsCreatedPerUserPerDay, defaultStorageQuotaMb: $defaultStorageQuotaMb, maxUploadMb: $maxUploadMb, supportEmail: $supportEmail, announcementBanner: $announcementBanner)';
}


}

/// @nodoc
abstract mixin class _$AppConfigCopyWith<$Res> implements $AppConfigCopyWith<$Res> {
  factory _$AppConfigCopyWith(_AppConfig value, $Res Function(_AppConfig) _then) = __$AppConfigCopyWithImpl;
@override @useResult
$Res call({
 bool allowUserGroupCreation, int maxGroupsCreatedPerUserPerDay, int defaultStorageQuotaMb, int maxUploadMb, String supportEmail, Announcement? announcementBanner
});


@override $AnnouncementCopyWith<$Res>? get announcementBanner;

}
/// @nodoc
class __$AppConfigCopyWithImpl<$Res>
    implements _$AppConfigCopyWith<$Res> {
  __$AppConfigCopyWithImpl(this._self, this._then);

  final _AppConfig _self;
  final $Res Function(_AppConfig) _then;

/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? allowUserGroupCreation = null,Object? maxGroupsCreatedPerUserPerDay = null,Object? defaultStorageQuotaMb = null,Object? maxUploadMb = null,Object? supportEmail = null,Object? announcementBanner = freezed,}) {
  return _then(_AppConfig(
allowUserGroupCreation: null == allowUserGroupCreation ? _self.allowUserGroupCreation : allowUserGroupCreation // ignore: cast_nullable_to_non_nullable
as bool,maxGroupsCreatedPerUserPerDay: null == maxGroupsCreatedPerUserPerDay ? _self.maxGroupsCreatedPerUserPerDay : maxGroupsCreatedPerUserPerDay // ignore: cast_nullable_to_non_nullable
as int,defaultStorageQuotaMb: null == defaultStorageQuotaMb ? _self.defaultStorageQuotaMb : defaultStorageQuotaMb // ignore: cast_nullable_to_non_nullable
as int,maxUploadMb: null == maxUploadMb ? _self.maxUploadMb : maxUploadMb // ignore: cast_nullable_to_non_nullable
as int,supportEmail: null == supportEmail ? _self.supportEmail : supportEmail // ignore: cast_nullable_to_non_nullable
as String,announcementBanner: freezed == announcementBanner ? _self.announcementBanner : announcementBanner // ignore: cast_nullable_to_non_nullable
as Announcement?,
  ));
}

/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AnnouncementCopyWith<$Res>? get announcementBanner {
    if (_self.announcementBanner == null) {
    return null;
  }

  return $AnnouncementCopyWith<$Res>(_self.announcementBanner!, (value) {
    return _then(_self.copyWith(announcementBanner: value));
  });
}
}

// dart format on
