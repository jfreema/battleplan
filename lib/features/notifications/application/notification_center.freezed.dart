// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_center.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NotificationCenterState {

/// Every item loaded so far, newest first, before hiding blocked and
/// expired ones (the screen does that, so unblocking shows them again).
 List<NotificationItem> get items;/// True until the first page arrives.
 bool get loading; bool get loadingMore;/// True once the oldest item is loaded.
 bool get reachedEnd;
/// Create a copy of NotificationCenterState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationCenterStateCopyWith<NotificationCenterState> get copyWith => _$NotificationCenterStateCopyWithImpl<NotificationCenterState>(this as NotificationCenterState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as NotificationCenterState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationCenterState&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.loading, _this.loading) || other.loading == _this.loading)&&(identical(other.loadingMore, _this.loadingMore) || other.loadingMore == _this.loadingMore)&&(identical(other.reachedEnd, _this.reachedEnd) || other.reachedEnd == _this.reachedEnd));
}


@override
int get hashCode {
  final _this = this as NotificationCenterState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.loading,_this.loadingMore,_this.reachedEnd);
}

@override
String toString() {
  final _this = this as NotificationCenterState;
  return 'NotificationCenterState(items: ${_this.items}, loading: ${_this.loading}, loadingMore: ${_this.loadingMore}, reachedEnd: ${_this.reachedEnd})';
}


}

/// @nodoc
abstract mixin class $NotificationCenterStateCopyWith<$Res>  {
  factory $NotificationCenterStateCopyWith(NotificationCenterState value, $Res Function(NotificationCenterState) _then) = _$NotificationCenterStateCopyWithImpl;
@useResult
$Res call({
 List<NotificationItem> items, bool loading, bool loadingMore, bool reachedEnd
});




}
/// @nodoc
class _$NotificationCenterStateCopyWithImpl<$Res>
    implements $NotificationCenterStateCopyWith<$Res> {
  _$NotificationCenterStateCopyWithImpl(this._self, this._then);

  final NotificationCenterState _self;
  final $Res Function(NotificationCenterState) _then;

/// Create a copy of NotificationCenterState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? loading = null,Object? loadingMore = null,Object? reachedEnd = null,}) {
  return _then(NotificationCenterState(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<NotificationItem>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,reachedEnd: null == reachedEnd ? _self.reachedEnd : reachedEnd // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationCenterState].
extension NotificationCenterStatePatterns on NotificationCenterState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationCenterState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationCenterState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationCenterState value)  $default,){
final _that = this;
switch (_that) {
case _NotificationCenterState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationCenterState value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationCenterState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<NotificationItem> items,  bool loading,  bool loadingMore,  bool reachedEnd)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationCenterState() when $default != null:
return $default(_that.items,_that.loading,_that.loadingMore,_that.reachedEnd);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<NotificationItem> items,  bool loading,  bool loadingMore,  bool reachedEnd)  $default,) {final _that = this;
switch (_that) {
case _NotificationCenterState():
return $default(_that.items,_that.loading,_that.loadingMore,_that.reachedEnd);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<NotificationItem> items,  bool loading,  bool loadingMore,  bool reachedEnd)?  $default,) {final _that = this;
switch (_that) {
case _NotificationCenterState() when $default != null:
return $default(_that.items,_that.loading,_that.loadingMore,_that.reachedEnd);case _:
  return null;

}
}

}

/// @nodoc


class _NotificationCenterState implements NotificationCenterState {
  const _NotificationCenterState({ List<NotificationItem> items = const <NotificationItem>[], this.loading = true, this.loadingMore = false, this.reachedEnd = false}): _items = items;
  

/// Every item loaded so far, newest first, before hiding blocked and
/// expired ones (the screen does that, so unblocking shows them again).
 final  List<NotificationItem> _items;
/// Every item loaded so far, newest first, before hiding blocked and
/// expired ones (the screen does that, so unblocking shows them again).
@override@JsonKey() List<NotificationItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// True until the first page arrives.
@override@JsonKey() final  bool loading;
@override@JsonKey() final  bool loadingMore;
/// True once the oldest item is loaded.
@override@JsonKey() final  bool reachedEnd;

/// Create a copy of NotificationCenterState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationCenterStateCopyWith<_NotificationCenterState> get copyWith => __$NotificationCenterStateCopyWithImpl<_NotificationCenterState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationCenterState&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.reachedEnd, reachedEnd) || other.reachedEnd == reachedEnd));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),loading,loadingMore,reachedEnd);
}

@override
String toString() {
    return 'NotificationCenterState(items: $items, loading: $loading, loadingMore: $loadingMore, reachedEnd: $reachedEnd)';
}


}

/// @nodoc
abstract mixin class _$NotificationCenterStateCopyWith<$Res> implements $NotificationCenterStateCopyWith<$Res> {
  factory _$NotificationCenterStateCopyWith(_NotificationCenterState value, $Res Function(_NotificationCenterState) _then) = __$NotificationCenterStateCopyWithImpl;
@override @useResult
$Res call({
 List<NotificationItem> items, bool loading, bool loadingMore, bool reachedEnd
});




}
/// @nodoc
class __$NotificationCenterStateCopyWithImpl<$Res>
    implements _$NotificationCenterStateCopyWith<$Res> {
  __$NotificationCenterStateCopyWithImpl(this._self, this._then);

  final _NotificationCenterState _self;
  final $Res Function(_NotificationCenterState) _then;

/// Create a copy of NotificationCenterState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? loading = null,Object? loadingMore = null,Object? reachedEnd = null,}) {
  return _then(_NotificationCenterState(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<NotificationItem>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,reachedEnd: null == reachedEnd ? _self.reachedEnd : reachedEnd // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
