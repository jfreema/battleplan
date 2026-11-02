// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_search.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatSearchState {

/// What was searched for, as typed.
 String get query;/// Its words, as messages keep theirs (searchWords): empty when it has
/// none worth searching for, only short or everyday ones.
 List<String> get terms;/// The messages found so far, newest first.
 List<Message> get results; bool get loading; bool get loadingMore;/// True once there are no more to find.
 bool get reachedEnd; bool get failed;/// The results came from the offline cache: only the messages on this
/// device were searched.
 bool get fromCache;
/// Create a copy of ChatSearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatSearchStateCopyWith<ChatSearchState> get copyWith => _$ChatSearchStateCopyWithImpl<ChatSearchState>(this as ChatSearchState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ChatSearchState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatSearchState&&(identical(other.query, _this.query) || other.query == _this.query)&&const DeepCollectionEquality().equals(other.terms, _this.terms)&&const DeepCollectionEquality().equals(other.results, _this.results)&&(identical(other.loading, _this.loading) || other.loading == _this.loading)&&(identical(other.loadingMore, _this.loadingMore) || other.loadingMore == _this.loadingMore)&&(identical(other.reachedEnd, _this.reachedEnd) || other.reachedEnd == _this.reachedEnd)&&(identical(other.failed, _this.failed) || other.failed == _this.failed)&&(identical(other.fromCache, _this.fromCache) || other.fromCache == _this.fromCache));
}


@override
int get hashCode {
  final _this = this as ChatSearchState;
  return Object.hash(runtimeType,_this.query,const DeepCollectionEquality().hash(_this.terms),const DeepCollectionEquality().hash(_this.results),_this.loading,_this.loadingMore,_this.reachedEnd,_this.failed,_this.fromCache);
}

@override
String toString() {
  final _this = this as ChatSearchState;
  return 'ChatSearchState(query: ${_this.query}, terms: ${_this.terms}, results: ${_this.results}, loading: ${_this.loading}, loadingMore: ${_this.loadingMore}, reachedEnd: ${_this.reachedEnd}, failed: ${_this.failed}, fromCache: ${_this.fromCache})';
}


}

/// @nodoc
abstract mixin class $ChatSearchStateCopyWith<$Res>  {
  factory $ChatSearchStateCopyWith(ChatSearchState value, $Res Function(ChatSearchState) _then) = _$ChatSearchStateCopyWithImpl;
@useResult
$Res call({
 String query, List<String> terms, List<Message> results, bool loading, bool loadingMore, bool reachedEnd, bool failed, bool fromCache
});




}
/// @nodoc
class _$ChatSearchStateCopyWithImpl<$Res>
    implements $ChatSearchStateCopyWith<$Res> {
  _$ChatSearchStateCopyWithImpl(this._self, this._then);

  final ChatSearchState _self;
  final $Res Function(ChatSearchState) _then;

/// Create a copy of ChatSearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? terms = null,Object? results = null,Object? loading = null,Object? loadingMore = null,Object? reachedEnd = null,Object? failed = null,Object? fromCache = null,}) {
  return _then(ChatSearchState(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,terms: null == terms ? _self.terms : terms // ignore: cast_nullable_to_non_nullable
as List<String>,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<Message>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,reachedEnd: null == reachedEnd ? _self.reachedEnd : reachedEnd // ignore: cast_nullable_to_non_nullable
as bool,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,fromCache: null == fromCache ? _self.fromCache : fromCache // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatSearchState].
extension ChatSearchStatePatterns on ChatSearchState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatSearchState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatSearchState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatSearchState value)  $default,){
final _that = this;
switch (_that) {
case _ChatSearchState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatSearchState value)?  $default,){
final _that = this;
switch (_that) {
case _ChatSearchState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  List<String> terms,  List<Message> results,  bool loading,  bool loadingMore,  bool reachedEnd,  bool failed,  bool fromCache)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatSearchState() when $default != null:
return $default(_that.query,_that.terms,_that.results,_that.loading,_that.loadingMore,_that.reachedEnd,_that.failed,_that.fromCache);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  List<String> terms,  List<Message> results,  bool loading,  bool loadingMore,  bool reachedEnd,  bool failed,  bool fromCache)  $default,) {final _that = this;
switch (_that) {
case _ChatSearchState():
return $default(_that.query,_that.terms,_that.results,_that.loading,_that.loadingMore,_that.reachedEnd,_that.failed,_that.fromCache);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  List<String> terms,  List<Message> results,  bool loading,  bool loadingMore,  bool reachedEnd,  bool failed,  bool fromCache)?  $default,) {final _that = this;
switch (_that) {
case _ChatSearchState() when $default != null:
return $default(_that.query,_that.terms,_that.results,_that.loading,_that.loadingMore,_that.reachedEnd,_that.failed,_that.fromCache);case _:
  return null;

}
}

}

/// @nodoc


class _ChatSearchState extends ChatSearchState {
  const _ChatSearchState({this.query = '',  List<String> terms = const <String>[],  List<Message> results = const <Message>[], this.loading = false, this.loadingMore = false, this.reachedEnd = false, this.failed = false, this.fromCache = false}): _terms = terms,_results = results,super._();
  

/// What was searched for, as typed.
@override@JsonKey() final  String query;
/// Its words, as messages keep theirs (searchWords): empty when it has
/// none worth searching for, only short or everyday ones.
 final  List<String> _terms;
/// Its words, as messages keep theirs (searchWords): empty when it has
/// none worth searching for, only short or everyday ones.
@override@JsonKey() List<String> get terms {
  if (_terms is EqualUnmodifiableListView) return _terms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_terms);
}

/// The messages found so far, newest first.
 final  List<Message> _results;
/// The messages found so far, newest first.
@override@JsonKey() List<Message> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}

@override@JsonKey() final  bool loading;
@override@JsonKey() final  bool loadingMore;
/// True once there are no more to find.
@override@JsonKey() final  bool reachedEnd;
@override@JsonKey() final  bool failed;
/// The results came from the offline cache: only the messages on this
/// device were searched.
@override@JsonKey() final  bool fromCache;

/// Create a copy of ChatSearchState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatSearchStateCopyWith<_ChatSearchState> get copyWith => __$ChatSearchStateCopyWithImpl<_ChatSearchState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatSearchState&&(identical(other.query, query) || other.query == query)&&const DeepCollectionEquality().equals(other.terms, _terms)&&const DeepCollectionEquality().equals(other.results, _results)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.reachedEnd, reachedEnd) || other.reachedEnd == reachedEnd)&&(identical(other.failed, failed) || other.failed == failed)&&(identical(other.fromCache, fromCache) || other.fromCache == fromCache));
}


@override
int get hashCode {
    return Object.hash(runtimeType,query,const DeepCollectionEquality().hash(_terms),const DeepCollectionEquality().hash(_results),loading,loadingMore,reachedEnd,failed,fromCache);
}

@override
String toString() {
    return 'ChatSearchState(query: $query, terms: $terms, results: $results, loading: $loading, loadingMore: $loadingMore, reachedEnd: $reachedEnd, failed: $failed, fromCache: $fromCache)';
}


}

/// @nodoc
abstract mixin class _$ChatSearchStateCopyWith<$Res> implements $ChatSearchStateCopyWith<$Res> {
  factory _$ChatSearchStateCopyWith(_ChatSearchState value, $Res Function(_ChatSearchState) _then) = __$ChatSearchStateCopyWithImpl;
@override @useResult
$Res call({
 String query, List<String> terms, List<Message> results, bool loading, bool loadingMore, bool reachedEnd, bool failed, bool fromCache
});




}
/// @nodoc
class __$ChatSearchStateCopyWithImpl<$Res>
    implements _$ChatSearchStateCopyWith<$Res> {
  __$ChatSearchStateCopyWithImpl(this._self, this._then);

  final _ChatSearchState _self;
  final $Res Function(_ChatSearchState) _then;

/// Create a copy of ChatSearchState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? terms = null,Object? results = null,Object? loading = null,Object? loadingMore = null,Object? reachedEnd = null,Object? failed = null,Object? fromCache = null,}) {
  return _then(_ChatSearchState(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,terms: null == terms ? _self._terms : terms // ignore: cast_nullable_to_non_nullable
as List<String>,results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<Message>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,reachedEnd: null == reachedEnd ? _self.reachedEnd : reachedEnd // ignore: cast_nullable_to_non_nullable
as bool,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,fromCache: null == fromCache ? _self.fromCache : fromCache // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
