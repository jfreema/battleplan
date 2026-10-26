// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'assignment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Assignment {

 String get id; GroupId get groupId; EventId get eventId; AssignmentKind get kind;/// The task's own name for [AssignmentKind.other] ("Field setup"), or a
/// detail for the others ("Halftime oranges"). Null when there's none.
 String? get label;/// Who has it; null while it's open.
 String? get assigneeUid;/// Who put [assigneeUid] there: the person themselves when they
/// volunteered, or the admin who assigned them.
 String? get assignedBy; String get createdBy; DateTime? get createdAt;/// True until the server has it.
 bool get pending;
/// Create a copy of Assignment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssignmentCopyWith<Assignment> get copyWith => _$AssignmentCopyWithImpl<Assignment>(this as Assignment, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Assignment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Assignment&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.eventId, _this.eventId) || other.eventId == _this.eventId)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.assigneeUid, _this.assigneeUid) || other.assigneeUid == _this.assigneeUid)&&(identical(other.assignedBy, _this.assignedBy) || other.assignedBy == _this.assignedBy)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.pending, _this.pending) || other.pending == _this.pending));
}


@override
int get hashCode {
  final _this = this as Assignment;
  return Object.hash(runtimeType,_this.id,_this.groupId,_this.eventId,_this.kind,_this.label,_this.assigneeUid,_this.assignedBy,_this.createdBy,_this.createdAt,_this.pending);
}

@override
String toString() {
  final _this = this as Assignment;
  return 'Assignment(id: ${_this.id}, groupId: ${_this.groupId}, eventId: ${_this.eventId}, kind: ${_this.kind}, label: ${_this.label}, assigneeUid: ${_this.assigneeUid}, assignedBy: ${_this.assignedBy}, createdBy: ${_this.createdBy}, createdAt: ${_this.createdAt}, pending: ${_this.pending})';
}


}

/// @nodoc
abstract mixin class $AssignmentCopyWith<$Res>  {
  factory $AssignmentCopyWith(Assignment value, $Res Function(Assignment) _then) = _$AssignmentCopyWithImpl;
@useResult
$Res call({
 String id, GroupId groupId, EventId eventId, AssignmentKind kind, String? label, String? assigneeUid, String? assignedBy, String createdBy, DateTime? createdAt, bool pending
});




}
/// @nodoc
class _$AssignmentCopyWithImpl<$Res>
    implements $AssignmentCopyWith<$Res> {
  _$AssignmentCopyWithImpl(this._self, this._then);

  final Assignment _self;
  final $Res Function(Assignment) _then;

/// Create a copy of Assignment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? groupId = null,Object? eventId = null,Object? kind = null,Object? label = freezed,Object? assigneeUid = freezed,Object? assignedBy = freezed,Object? createdBy = null,Object? createdAt = freezed,Object? pending = null,}) {
  return _then(Assignment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as EventId,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as AssignmentKind,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,assigneeUid: freezed == assigneeUid ? _self.assigneeUid : assigneeUid // ignore: cast_nullable_to_non_nullable
as String?,assignedBy: freezed == assignedBy ? _self.assignedBy : assignedBy // ignore: cast_nullable_to_non_nullable
as String?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Assignment].
extension AssignmentPatterns on Assignment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Assignment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Assignment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Assignment value)  $default,){
final _that = this;
switch (_that) {
case _Assignment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Assignment value)?  $default,){
final _that = this;
switch (_that) {
case _Assignment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  GroupId groupId,  EventId eventId,  AssignmentKind kind,  String? label,  String? assigneeUid,  String? assignedBy,  String createdBy,  DateTime? createdAt,  bool pending)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Assignment() when $default != null:
return $default(_that.id,_that.groupId,_that.eventId,_that.kind,_that.label,_that.assigneeUid,_that.assignedBy,_that.createdBy,_that.createdAt,_that.pending);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  GroupId groupId,  EventId eventId,  AssignmentKind kind,  String? label,  String? assigneeUid,  String? assignedBy,  String createdBy,  DateTime? createdAt,  bool pending)  $default,) {final _that = this;
switch (_that) {
case _Assignment():
return $default(_that.id,_that.groupId,_that.eventId,_that.kind,_that.label,_that.assigneeUid,_that.assignedBy,_that.createdBy,_that.createdAt,_that.pending);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  GroupId groupId,  EventId eventId,  AssignmentKind kind,  String? label,  String? assigneeUid,  String? assignedBy,  String createdBy,  DateTime? createdAt,  bool pending)?  $default,) {final _that = this;
switch (_that) {
case _Assignment() when $default != null:
return $default(_that.id,_that.groupId,_that.eventId,_that.kind,_that.label,_that.assigneeUid,_that.assignedBy,_that.createdBy,_that.createdAt,_that.pending);case _:
  return null;

}
}

}

/// @nodoc


class _Assignment extends Assignment {
  const _Assignment({required this.id, required this.groupId, required this.eventId, required this.kind, this.label, this.assigneeUid, this.assignedBy, this.createdBy = '', this.createdAt, this.pending = false}): super._();
  

@override final  String id;
@override final  GroupId groupId;
@override final  EventId eventId;
@override final  AssignmentKind kind;
/// The task's own name for [AssignmentKind.other] ("Field setup"), or a
/// detail for the others ("Halftime oranges"). Null when there's none.
@override final  String? label;
/// Who has it; null while it's open.
@override final  String? assigneeUid;
/// Who put [assigneeUid] there: the person themselves when they
/// volunteered, or the admin who assigned them.
@override final  String? assignedBy;
@override@JsonKey() final  String createdBy;
@override final  DateTime? createdAt;
/// True until the server has it.
@override@JsonKey() final  bool pending;

/// Create a copy of Assignment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssignmentCopyWith<_Assignment> get copyWith => __$AssignmentCopyWithImpl<_Assignment>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Assignment&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.label, label) || other.label == label)&&(identical(other.assigneeUid, assigneeUid) || other.assigneeUid == assigneeUid)&&(identical(other.assignedBy, assignedBy) || other.assignedBy == assignedBy)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.pending, pending) || other.pending == pending));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,groupId,eventId,kind,label,assigneeUid,assignedBy,createdBy,createdAt,pending);
}

@override
String toString() {
    return 'Assignment(id: $id, groupId: $groupId, eventId: $eventId, kind: $kind, label: $label, assigneeUid: $assigneeUid, assignedBy: $assignedBy, createdBy: $createdBy, createdAt: $createdAt, pending: $pending)';
}


}

/// @nodoc
abstract mixin class _$AssignmentCopyWith<$Res> implements $AssignmentCopyWith<$Res> {
  factory _$AssignmentCopyWith(_Assignment value, $Res Function(_Assignment) _then) = __$AssignmentCopyWithImpl;
@override @useResult
$Res call({
 String id, GroupId groupId, EventId eventId, AssignmentKind kind, String? label, String? assigneeUid, String? assignedBy, String createdBy, DateTime? createdAt, bool pending
});




}
/// @nodoc
class __$AssignmentCopyWithImpl<$Res>
    implements _$AssignmentCopyWith<$Res> {
  __$AssignmentCopyWithImpl(this._self, this._then);

  final _Assignment _self;
  final $Res Function(_Assignment) _then;

/// Create a copy of Assignment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? groupId = null,Object? eventId = null,Object? kind = null,Object? label = freezed,Object? assigneeUid = freezed,Object? assignedBy = freezed,Object? createdBy = null,Object? createdAt = freezed,Object? pending = null,}) {
  return _then(_Assignment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as EventId,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as AssignmentKind,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,assigneeUid: freezed == assigneeUid ? _self.assigneeUid : assigneeUid // ignore: cast_nullable_to_non_nullable
as String?,assignedBy: freezed == assignedBy ? _self.assignedBy : assignedBy // ignore: cast_nullable_to_non_nullable
as String?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
