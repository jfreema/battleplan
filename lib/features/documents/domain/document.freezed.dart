// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Document {

 DocumentId get id; GroupId get groupId; DocumentKind get kind; String get name;/// Who added it, and their name then, kept after they leave (DOC-1).
 String get uploadedBy; String get uploaderName; String get description;/// Pinned items list first (DOC-1); only admins change it (DOC-5).
 bool get pinned;/// Files: the Storage path, its type, and its size in bytes.
 String? get path; String? get contentType; int? get size;/// Links: the web address (DOC-3).
 String? get url; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of Document
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentCopyWith<Document> get copyWith => _$DocumentCopyWithImpl<Document>(this as Document, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Document;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Document&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.uploadedBy, _this.uploadedBy) || other.uploadedBy == _this.uploadedBy)&&(identical(other.uploaderName, _this.uploaderName) || other.uploaderName == _this.uploaderName)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.pinned, _this.pinned) || other.pinned == _this.pinned)&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.contentType, _this.contentType) || other.contentType == _this.contentType)&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}


@override
int get hashCode {
  final _this = this as Document;
  return Object.hash(runtimeType,_this.id,_this.groupId,_this.kind,_this.name,_this.uploadedBy,_this.uploaderName,_this.description,_this.pinned,_this.path,_this.contentType,_this.size,_this.url,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as Document;
  return 'Document(id: ${_this.id}, groupId: ${_this.groupId}, kind: ${_this.kind}, name: ${_this.name}, uploadedBy: ${_this.uploadedBy}, uploaderName: ${_this.uploaderName}, description: ${_this.description}, pinned: ${_this.pinned}, path: ${_this.path}, contentType: ${_this.contentType}, size: ${_this.size}, url: ${_this.url}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $DocumentCopyWith<$Res>  {
  factory $DocumentCopyWith(Document value, $Res Function(Document) _then) = _$DocumentCopyWithImpl;
@useResult
$Res call({
 DocumentId id, GroupId groupId, DocumentKind kind, String name, String uploadedBy, String uploaderName, String description, bool pinned, String? path, String? contentType, int? size, String? url, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$DocumentCopyWithImpl<$Res>
    implements $DocumentCopyWith<$Res> {
  _$DocumentCopyWithImpl(this._self, this._then);

  final Document _self;
  final $Res Function(Document) _then;

/// Create a copy of Document
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? groupId = null,Object? kind = null,Object? name = null,Object? uploadedBy = null,Object? uploaderName = null,Object? description = null,Object? pinned = null,Object? path = freezed,Object? contentType = freezed,Object? size = freezed,Object? url = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(Document(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as DocumentId,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as DocumentKind,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,uploadedBy: null == uploadedBy ? _self.uploadedBy : uploadedBy // ignore: cast_nullable_to_non_nullable
as String,uploaderName: null == uploaderName ? _self.uploaderName : uploaderName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,pinned: null == pinned ? _self.pinned : pinned // ignore: cast_nullable_to_non_nullable
as bool,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,contentType: freezed == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String?,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Document].
extension DocumentPatterns on Document {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Document value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Document() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Document value)  $default,){
final _that = this;
switch (_that) {
case _Document():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Document value)?  $default,){
final _that = this;
switch (_that) {
case _Document() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DocumentId id,  GroupId groupId,  DocumentKind kind,  String name,  String uploadedBy,  String uploaderName,  String description,  bool pinned,  String? path,  String? contentType,  int? size,  String? url,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Document() when $default != null:
return $default(_that.id,_that.groupId,_that.kind,_that.name,_that.uploadedBy,_that.uploaderName,_that.description,_that.pinned,_that.path,_that.contentType,_that.size,_that.url,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DocumentId id,  GroupId groupId,  DocumentKind kind,  String name,  String uploadedBy,  String uploaderName,  String description,  bool pinned,  String? path,  String? contentType,  int? size,  String? url,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Document():
return $default(_that.id,_that.groupId,_that.kind,_that.name,_that.uploadedBy,_that.uploaderName,_that.description,_that.pinned,_that.path,_that.contentType,_that.size,_that.url,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DocumentId id,  GroupId groupId,  DocumentKind kind,  String name,  String uploadedBy,  String uploaderName,  String description,  bool pinned,  String? path,  String? contentType,  int? size,  String? url,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Document() when $default != null:
return $default(_that.id,_that.groupId,_that.kind,_that.name,_that.uploadedBy,_that.uploaderName,_that.description,_that.pinned,_that.path,_that.contentType,_that.size,_that.url,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Document extends Document {
  const _Document({required this.id, required this.groupId, required this.kind, required this.name, required this.uploadedBy, required this.uploaderName, this.description = '', this.pinned = false, this.path, this.contentType, this.size, this.url, this.createdAt, this.updatedAt}): super._();
  

@override final  DocumentId id;
@override final  GroupId groupId;
@override final  DocumentKind kind;
@override final  String name;
/// Who added it, and their name then, kept after they leave (DOC-1).
@override final  String uploadedBy;
@override final  String uploaderName;
@override@JsonKey() final  String description;
/// Pinned items list first (DOC-1); only admins change it (DOC-5).
@override@JsonKey() final  bool pinned;
/// Files: the Storage path, its type, and its size in bytes.
@override final  String? path;
@override final  String? contentType;
@override final  int? size;
/// Links: the web address (DOC-3).
@override final  String? url;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of Document
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentCopyWith<_Document> get copyWith => __$DocumentCopyWithImpl<_Document>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Document&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.name, name) || other.name == name)&&(identical(other.uploadedBy, uploadedBy) || other.uploadedBy == uploadedBy)&&(identical(other.uploaderName, uploaderName) || other.uploaderName == uploaderName)&&(identical(other.description, description) || other.description == description)&&(identical(other.pinned, pinned) || other.pinned == pinned)&&(identical(other.path, path) || other.path == path)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.size, size) || other.size == size)&&(identical(other.url, url) || other.url == url)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,groupId,kind,name,uploadedBy,uploaderName,description,pinned,path,contentType,size,url,createdAt,updatedAt);
}

@override
String toString() {
    return 'Document(id: $id, groupId: $groupId, kind: $kind, name: $name, uploadedBy: $uploadedBy, uploaderName: $uploaderName, description: $description, pinned: $pinned, path: $path, contentType: $contentType, size: $size, url: $url, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$DocumentCopyWith<$Res> implements $DocumentCopyWith<$Res> {
  factory _$DocumentCopyWith(_Document value, $Res Function(_Document) _then) = __$DocumentCopyWithImpl;
@override @useResult
$Res call({
 DocumentId id, GroupId groupId, DocumentKind kind, String name, String uploadedBy, String uploaderName, String description, bool pinned, String? path, String? contentType, int? size, String? url, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$DocumentCopyWithImpl<$Res>
    implements _$DocumentCopyWith<$Res> {
  __$DocumentCopyWithImpl(this._self, this._then);

  final _Document _self;
  final $Res Function(_Document) _then;

/// Create a copy of Document
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? groupId = null,Object? kind = null,Object? name = null,Object? uploadedBy = null,Object? uploaderName = null,Object? description = null,Object? pinned = null,Object? path = freezed,Object? contentType = freezed,Object? size = freezed,Object? url = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Document(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as DocumentId,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as DocumentKind,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,uploadedBy: null == uploadedBy ? _self.uploadedBy : uploadedBy // ignore: cast_nullable_to_non_nullable
as String,uploaderName: null == uploaderName ? _self.uploaderName : uploaderName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,pinned: null == pinned ? _self.pinned : pinned // ignore: cast_nullable_to_non_nullable
as bool,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,contentType: freezed == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String?,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
