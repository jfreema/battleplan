// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'providers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DocumentsView {

 DocumentSort get sort; String get filter;
/// Create a copy of DocumentsView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentsViewCopyWith<DocumentsView> get copyWith => _$DocumentsViewCopyWithImpl<DocumentsView>(this as DocumentsView, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DocumentsView;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentsView&&(identical(other.sort, _this.sort) || other.sort == _this.sort)&&(identical(other.filter, _this.filter) || other.filter == _this.filter));
}


@override
int get hashCode {
  final _this = this as DocumentsView;
  return Object.hash(runtimeType,_this.sort,_this.filter);
}

@override
String toString() {
  final _this = this as DocumentsView;
  return 'DocumentsView(sort: ${_this.sort}, filter: ${_this.filter})';
}


}

/// @nodoc
abstract mixin class $DocumentsViewCopyWith<$Res>  {
  factory $DocumentsViewCopyWith(DocumentsView value, $Res Function(DocumentsView) _then) = _$DocumentsViewCopyWithImpl;
@useResult
$Res call({
 DocumentSort sort, String filter
});




}
/// @nodoc
class _$DocumentsViewCopyWithImpl<$Res>
    implements $DocumentsViewCopyWith<$Res> {
  _$DocumentsViewCopyWithImpl(this._self, this._then);

  final DocumentsView _self;
  final $Res Function(DocumentsView) _then;

/// Create a copy of DocumentsView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sort = null,Object? filter = null,}) {
  return _then(DocumentsView(
sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as DocumentSort,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentsView].
extension DocumentsViewPatterns on DocumentsView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentsView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentsView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentsView value)  $default,){
final _that = this;
switch (_that) {
case _DocumentsView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentsView value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentsView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DocumentSort sort,  String filter)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentsView() when $default != null:
return $default(_that.sort,_that.filter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DocumentSort sort,  String filter)  $default,) {final _that = this;
switch (_that) {
case _DocumentsView():
return $default(_that.sort,_that.filter);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DocumentSort sort,  String filter)?  $default,) {final _that = this;
switch (_that) {
case _DocumentsView() when $default != null:
return $default(_that.sort,_that.filter);case _:
  return null;

}
}

}

/// @nodoc


class _DocumentsView implements DocumentsView {
  const _DocumentsView({this.sort = DocumentSort.recent, this.filter = ''});
  

@override@JsonKey() final  DocumentSort sort;
@override@JsonKey() final  String filter;

/// Create a copy of DocumentsView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentsViewCopyWith<_DocumentsView> get copyWith => __$DocumentsViewCopyWithImpl<_DocumentsView>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentsView&&(identical(other.sort, sort) || other.sort == sort)&&(identical(other.filter, filter) || other.filter == filter));
}


@override
int get hashCode {
    return Object.hash(runtimeType,sort,filter);
}

@override
String toString() {
    return 'DocumentsView(sort: $sort, filter: $filter)';
}


}

/// @nodoc
abstract mixin class _$DocumentsViewCopyWith<$Res> implements $DocumentsViewCopyWith<$Res> {
  factory _$DocumentsViewCopyWith(_DocumentsView value, $Res Function(_DocumentsView) _then) = __$DocumentsViewCopyWithImpl;
@override @useResult
$Res call({
 DocumentSort sort, String filter
});




}
/// @nodoc
class __$DocumentsViewCopyWithImpl<$Res>
    implements _$DocumentsViewCopyWith<$Res> {
  __$DocumentsViewCopyWithImpl(this._self, this._then);

  final _DocumentsView _self;
  final $Res Function(_DocumentsView) _then;

/// Create a copy of DocumentsView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sort = null,Object? filter = null,}) {
  return _then(_DocumentsView(
sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as DocumentSort,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$DocumentListState {

/// Pinned first, then in the chosen order, not yet filtered.
 List<Document> get documents; bool get loading; bool get loadingMore;/// True once there's nothing more to load.
 bool get reachedEnd; bool get failed;
/// Create a copy of DocumentListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentListStateCopyWith<DocumentListState> get copyWith => _$DocumentListStateCopyWithImpl<DocumentListState>(this as DocumentListState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DocumentListState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentListState&&const DeepCollectionEquality().equals(other.documents, _this.documents)&&(identical(other.loading, _this.loading) || other.loading == _this.loading)&&(identical(other.loadingMore, _this.loadingMore) || other.loadingMore == _this.loadingMore)&&(identical(other.reachedEnd, _this.reachedEnd) || other.reachedEnd == _this.reachedEnd)&&(identical(other.failed, _this.failed) || other.failed == _this.failed));
}


@override
int get hashCode {
  final _this = this as DocumentListState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.documents),_this.loading,_this.loadingMore,_this.reachedEnd,_this.failed);
}

@override
String toString() {
  final _this = this as DocumentListState;
  return 'DocumentListState(documents: ${_this.documents}, loading: ${_this.loading}, loadingMore: ${_this.loadingMore}, reachedEnd: ${_this.reachedEnd}, failed: ${_this.failed})';
}


}

/// @nodoc
abstract mixin class $DocumentListStateCopyWith<$Res>  {
  factory $DocumentListStateCopyWith(DocumentListState value, $Res Function(DocumentListState) _then) = _$DocumentListStateCopyWithImpl;
@useResult
$Res call({
 List<Document> documents, bool loading, bool loadingMore, bool reachedEnd, bool failed
});




}
/// @nodoc
class _$DocumentListStateCopyWithImpl<$Res>
    implements $DocumentListStateCopyWith<$Res> {
  _$DocumentListStateCopyWithImpl(this._self, this._then);

  final DocumentListState _self;
  final $Res Function(DocumentListState) _then;

/// Create a copy of DocumentListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? documents = null,Object? loading = null,Object? loadingMore = null,Object? reachedEnd = null,Object? failed = null,}) {
  return _then(DocumentListState(
documents: null == documents ? _self.documents : documents // ignore: cast_nullable_to_non_nullable
as List<Document>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,reachedEnd: null == reachedEnd ? _self.reachedEnd : reachedEnd // ignore: cast_nullable_to_non_nullable
as bool,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentListState].
extension DocumentListStatePatterns on DocumentListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentListState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentListState value)  $default,){
final _that = this;
switch (_that) {
case _DocumentListState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentListState value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentListState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Document> documents,  bool loading,  bool loadingMore,  bool reachedEnd,  bool failed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentListState() when $default != null:
return $default(_that.documents,_that.loading,_that.loadingMore,_that.reachedEnd,_that.failed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Document> documents,  bool loading,  bool loadingMore,  bool reachedEnd,  bool failed)  $default,) {final _that = this;
switch (_that) {
case _DocumentListState():
return $default(_that.documents,_that.loading,_that.loadingMore,_that.reachedEnd,_that.failed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Document> documents,  bool loading,  bool loadingMore,  bool reachedEnd,  bool failed)?  $default,) {final _that = this;
switch (_that) {
case _DocumentListState() when $default != null:
return $default(_that.documents,_that.loading,_that.loadingMore,_that.reachedEnd,_that.failed);case _:
  return null;

}
}

}

/// @nodoc


class _DocumentListState implements DocumentListState {
  const _DocumentListState({ List<Document> documents = const <Document>[], this.loading = true, this.loadingMore = false, this.reachedEnd = false, this.failed = false}): _documents = documents;
  

/// Pinned first, then in the chosen order, not yet filtered.
 final  List<Document> _documents;
/// Pinned first, then in the chosen order, not yet filtered.
@override@JsonKey() List<Document> get documents {
  if (_documents is EqualUnmodifiableListView) return _documents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_documents);
}

@override@JsonKey() final  bool loading;
@override@JsonKey() final  bool loadingMore;
/// True once there's nothing more to load.
@override@JsonKey() final  bool reachedEnd;
@override@JsonKey() final  bool failed;

/// Create a copy of DocumentListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentListStateCopyWith<_DocumentListState> get copyWith => __$DocumentListStateCopyWithImpl<_DocumentListState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentListState&&const DeepCollectionEquality().equals(other.documents, _documents)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.reachedEnd, reachedEnd) || other.reachedEnd == reachedEnd)&&(identical(other.failed, failed) || other.failed == failed));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_documents),loading,loadingMore,reachedEnd,failed);
}

@override
String toString() {
    return 'DocumentListState(documents: $documents, loading: $loading, loadingMore: $loadingMore, reachedEnd: $reachedEnd, failed: $failed)';
}


}

/// @nodoc
abstract mixin class _$DocumentListStateCopyWith<$Res> implements $DocumentListStateCopyWith<$Res> {
  factory _$DocumentListStateCopyWith(_DocumentListState value, $Res Function(_DocumentListState) _then) = __$DocumentListStateCopyWithImpl;
@override @useResult
$Res call({
 List<Document> documents, bool loading, bool loadingMore, bool reachedEnd, bool failed
});




}
/// @nodoc
class __$DocumentListStateCopyWithImpl<$Res>
    implements _$DocumentListStateCopyWith<$Res> {
  __$DocumentListStateCopyWithImpl(this._self, this._then);

  final _DocumentListState _self;
  final $Res Function(_DocumentListState) _then;

/// Create a copy of DocumentListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? documents = null,Object? loading = null,Object? loadingMore = null,Object? reachedEnd = null,Object? failed = null,}) {
  return _then(_DocumentListState(
documents: null == documents ? _self._documents : documents // ignore: cast_nullable_to_non_nullable
as List<Document>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,reachedEnd: null == reachedEnd ? _self.reachedEnd : reachedEnd // ignore: cast_nullable_to_non_nullable
as bool,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
