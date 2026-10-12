// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MediaItem {

/// The Storage path, which `deleteTeamMedia` takes.
 String get path; int get size; MediaKind get kind; String? get contentType; DateTime? get createdAt;/// A chat photo's message and its author.
 String? get messageId; String? get authorName;/// A document's record and its name (M7), while the record exists.
/// [authorName] is then who added it.
 String? get documentId; String? get documentName;/// For a logo or background: whether the team still uses it. An older
/// one left behind reads as false.
 bool? get current;
/// Create a copy of MediaItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaItemCopyWith<MediaItem> get copyWith => _$MediaItemCopyWithImpl<MediaItem>(this as MediaItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MediaItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaItem&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.contentType, _this.contentType) || other.contentType == _this.contentType)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.messageId, _this.messageId) || other.messageId == _this.messageId)&&(identical(other.authorName, _this.authorName) || other.authorName == _this.authorName)&&(identical(other.documentId, _this.documentId) || other.documentId == _this.documentId)&&(identical(other.documentName, _this.documentName) || other.documentName == _this.documentName)&&(identical(other.current, _this.current) || other.current == _this.current));
}


@override
int get hashCode {
  final _this = this as MediaItem;
  return Object.hash(runtimeType,_this.path,_this.size,_this.kind,_this.contentType,_this.createdAt,_this.messageId,_this.authorName,_this.documentId,_this.documentName,_this.current);
}

@override
String toString() {
  final _this = this as MediaItem;
  return 'MediaItem(path: ${_this.path}, size: ${_this.size}, kind: ${_this.kind}, contentType: ${_this.contentType}, createdAt: ${_this.createdAt}, messageId: ${_this.messageId}, authorName: ${_this.authorName}, documentId: ${_this.documentId}, documentName: ${_this.documentName}, current: ${_this.current})';
}


}

/// @nodoc
abstract mixin class $MediaItemCopyWith<$Res>  {
  factory $MediaItemCopyWith(MediaItem value, $Res Function(MediaItem) _then) = _$MediaItemCopyWithImpl;
@useResult
$Res call({
 String path, int size, MediaKind kind, String? contentType, DateTime? createdAt, String? messageId, String? authorName, String? documentId, String? documentName, bool? current
});




}
/// @nodoc
class _$MediaItemCopyWithImpl<$Res>
    implements $MediaItemCopyWith<$Res> {
  _$MediaItemCopyWithImpl(this._self, this._then);

  final MediaItem _self;
  final $Res Function(MediaItem) _then;

/// Create a copy of MediaItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? size = null,Object? kind = null,Object? contentType = freezed,Object? createdAt = freezed,Object? messageId = freezed,Object? authorName = freezed,Object? documentId = freezed,Object? documentName = freezed,Object? current = freezed,}) {
  return _then(MediaItem(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MediaKind,contentType: freezed == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,messageId: freezed == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String?,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,documentId: freezed == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String?,documentName: freezed == documentName ? _self.documentName : documentName // ignore: cast_nullable_to_non_nullable
as String?,current: freezed == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [MediaItem].
extension MediaItemPatterns on MediaItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaItem value)  $default,){
final _that = this;
switch (_that) {
case _MediaItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaItem value)?  $default,){
final _that = this;
switch (_that) {
case _MediaItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  int size,  MediaKind kind,  String? contentType,  DateTime? createdAt,  String? messageId,  String? authorName,  String? documentId,  String? documentName,  bool? current)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaItem() when $default != null:
return $default(_that.path,_that.size,_that.kind,_that.contentType,_that.createdAt,_that.messageId,_that.authorName,_that.documentId,_that.documentName,_that.current);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  int size,  MediaKind kind,  String? contentType,  DateTime? createdAt,  String? messageId,  String? authorName,  String? documentId,  String? documentName,  bool? current)  $default,) {final _that = this;
switch (_that) {
case _MediaItem():
return $default(_that.path,_that.size,_that.kind,_that.contentType,_that.createdAt,_that.messageId,_that.authorName,_that.documentId,_that.documentName,_that.current);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  int size,  MediaKind kind,  String? contentType,  DateTime? createdAt,  String? messageId,  String? authorName,  String? documentId,  String? documentName,  bool? current)?  $default,) {final _that = this;
switch (_that) {
case _MediaItem() when $default != null:
return $default(_that.path,_that.size,_that.kind,_that.contentType,_that.createdAt,_that.messageId,_that.authorName,_that.documentId,_that.documentName,_that.current);case _:
  return null;

}
}

}

/// @nodoc


class _MediaItem extends MediaItem {
  const _MediaItem({required this.path, required this.size, required this.kind, this.contentType, this.createdAt, this.messageId, this.authorName, this.documentId, this.documentName, this.current}): super._();
  

/// The Storage path, which `deleteTeamMedia` takes.
@override final  String path;
@override final  int size;
@override final  MediaKind kind;
@override final  String? contentType;
@override final  DateTime? createdAt;
/// A chat photo's message and its author.
@override final  String? messageId;
@override final  String? authorName;
/// A document's record and its name (M7), while the record exists.
/// [authorName] is then who added it.
@override final  String? documentId;
@override final  String? documentName;
/// For a logo or background: whether the team still uses it. An older
/// one left behind reads as false.
@override final  bool? current;

/// Create a copy of MediaItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaItemCopyWith<_MediaItem> get copyWith => __$MediaItemCopyWithImpl<_MediaItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaItem&&(identical(other.path, path) || other.path == path)&&(identical(other.size, size) || other.size == size)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.documentName, documentName) || other.documentName == documentName)&&(identical(other.current, current) || other.current == current));
}


@override
int get hashCode {
    return Object.hash(runtimeType,path,size,kind,contentType,createdAt,messageId,authorName,documentId,documentName,current);
}

@override
String toString() {
    return 'MediaItem(path: $path, size: $size, kind: $kind, contentType: $contentType, createdAt: $createdAt, messageId: $messageId, authorName: $authorName, documentId: $documentId, documentName: $documentName, current: $current)';
}


}

/// @nodoc
abstract mixin class _$MediaItemCopyWith<$Res> implements $MediaItemCopyWith<$Res> {
  factory _$MediaItemCopyWith(_MediaItem value, $Res Function(_MediaItem) _then) = __$MediaItemCopyWithImpl;
@override @useResult
$Res call({
 String path, int size, MediaKind kind, String? contentType, DateTime? createdAt, String? messageId, String? authorName, String? documentId, String? documentName, bool? current
});




}
/// @nodoc
class __$MediaItemCopyWithImpl<$Res>
    implements _$MediaItemCopyWith<$Res> {
  __$MediaItemCopyWithImpl(this._self, this._then);

  final _MediaItem _self;
  final $Res Function(_MediaItem) _then;

/// Create a copy of MediaItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? size = null,Object? kind = null,Object? contentType = freezed,Object? createdAt = freezed,Object? messageId = freezed,Object? authorName = freezed,Object? documentId = freezed,Object? documentName = freezed,Object? current = freezed,}) {
  return _then(_MediaItem(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MediaKind,contentType: freezed == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,messageId: freezed == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String?,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,documentId: freezed == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String?,documentName: freezed == documentName ? _self.documentName : documentName // ignore: cast_nullable_to_non_nullable
as String?,current: freezed == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

/// @nodoc
mixin _$TeamMedia {

/// Largest first.
 List<MediaItem> get items; int get storageBytes; int get storageQuotaBytes;/// The server left out the smallest files of a very large team; deleting
/// some brings the rest in.
 bool get truncated;
/// Create a copy of TeamMedia
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamMediaCopyWith<TeamMedia> get copyWith => _$TeamMediaCopyWithImpl<TeamMedia>(this as TeamMedia, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TeamMedia;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeamMedia&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.storageBytes, _this.storageBytes) || other.storageBytes == _this.storageBytes)&&(identical(other.storageQuotaBytes, _this.storageQuotaBytes) || other.storageQuotaBytes == _this.storageQuotaBytes)&&(identical(other.truncated, _this.truncated) || other.truncated == _this.truncated));
}


@override
int get hashCode {
  final _this = this as TeamMedia;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.storageBytes,_this.storageQuotaBytes,_this.truncated);
}

@override
String toString() {
  final _this = this as TeamMedia;
  return 'TeamMedia(items: ${_this.items}, storageBytes: ${_this.storageBytes}, storageQuotaBytes: ${_this.storageQuotaBytes}, truncated: ${_this.truncated})';
}


}

/// @nodoc
abstract mixin class $TeamMediaCopyWith<$Res>  {
  factory $TeamMediaCopyWith(TeamMedia value, $Res Function(TeamMedia) _then) = _$TeamMediaCopyWithImpl;
@useResult
$Res call({
 List<MediaItem> items, int storageBytes, int storageQuotaBytes, bool truncated
});




}
/// @nodoc
class _$TeamMediaCopyWithImpl<$Res>
    implements $TeamMediaCopyWith<$Res> {
  _$TeamMediaCopyWithImpl(this._self, this._then);

  final TeamMedia _self;
  final $Res Function(TeamMedia) _then;

/// Create a copy of TeamMedia
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? storageBytes = null,Object? storageQuotaBytes = null,Object? truncated = null,}) {
  return _then(TeamMedia(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<MediaItem>,storageBytes: null == storageBytes ? _self.storageBytes : storageBytes // ignore: cast_nullable_to_non_nullable
as int,storageQuotaBytes: null == storageQuotaBytes ? _self.storageQuotaBytes : storageQuotaBytes // ignore: cast_nullable_to_non_nullable
as int,truncated: null == truncated ? _self.truncated : truncated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TeamMedia].
extension TeamMediaPatterns on TeamMedia {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeamMedia value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeamMedia() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeamMedia value)  $default,){
final _that = this;
switch (_that) {
case _TeamMedia():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeamMedia value)?  $default,){
final _that = this;
switch (_that) {
case _TeamMedia() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MediaItem> items,  int storageBytes,  int storageQuotaBytes,  bool truncated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeamMedia() when $default != null:
return $default(_that.items,_that.storageBytes,_that.storageQuotaBytes,_that.truncated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MediaItem> items,  int storageBytes,  int storageQuotaBytes,  bool truncated)  $default,) {final _that = this;
switch (_that) {
case _TeamMedia():
return $default(_that.items,_that.storageBytes,_that.storageQuotaBytes,_that.truncated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MediaItem> items,  int storageBytes,  int storageQuotaBytes,  bool truncated)?  $default,) {final _that = this;
switch (_that) {
case _TeamMedia() when $default != null:
return $default(_that.items,_that.storageBytes,_that.storageQuotaBytes,_that.truncated);case _:
  return null;

}
}

}

/// @nodoc


class _TeamMedia implements TeamMedia {
  const _TeamMedia({required  List<MediaItem> items, required this.storageBytes, required this.storageQuotaBytes, this.truncated = false}): _items = items;
  

/// Largest first.
 final  List<MediaItem> _items;
/// Largest first.
@override List<MediaItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  int storageBytes;
@override final  int storageQuotaBytes;
/// The server left out the smallest files of a very large team; deleting
/// some brings the rest in.
@override@JsonKey() final  bool truncated;

/// Create a copy of TeamMedia
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamMediaCopyWith<_TeamMedia> get copyWith => __$TeamMediaCopyWithImpl<_TeamMedia>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeamMedia&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.storageBytes, storageBytes) || other.storageBytes == storageBytes)&&(identical(other.storageQuotaBytes, storageQuotaBytes) || other.storageQuotaBytes == storageQuotaBytes)&&(identical(other.truncated, truncated) || other.truncated == truncated));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),storageBytes,storageQuotaBytes,truncated);
}

@override
String toString() {
    return 'TeamMedia(items: $items, storageBytes: $storageBytes, storageQuotaBytes: $storageQuotaBytes, truncated: $truncated)';
}


}

/// @nodoc
abstract mixin class _$TeamMediaCopyWith<$Res> implements $TeamMediaCopyWith<$Res> {
  factory _$TeamMediaCopyWith(_TeamMedia value, $Res Function(_TeamMedia) _then) = __$TeamMediaCopyWithImpl;
@override @useResult
$Res call({
 List<MediaItem> items, int storageBytes, int storageQuotaBytes, bool truncated
});




}
/// @nodoc
class __$TeamMediaCopyWithImpl<$Res>
    implements _$TeamMediaCopyWith<$Res> {
  __$TeamMediaCopyWithImpl(this._self, this._then);

  final _TeamMedia _self;
  final $Res Function(_TeamMedia) _then;

/// Create a copy of TeamMedia
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? storageBytes = null,Object? storageQuotaBytes = null,Object? truncated = null,}) {
  return _then(_TeamMedia(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<MediaItem>,storageBytes: null == storageBytes ? _self.storageBytes : storageBytes // ignore: cast_nullable_to_non_nullable
as int,storageQuotaBytes: null == storageQuotaBytes ? _self.storageQuotaBytes : storageQuotaBytes // ignore: cast_nullable_to_non_nullable
as int,truncated: null == truncated ? _self.truncated : truncated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
