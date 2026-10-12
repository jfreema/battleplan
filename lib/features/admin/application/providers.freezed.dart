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
mixin _$AdminList<T> {

 List<T> get items; PageCursor? get next; bool get loadingMore;
/// Create a copy of AdminList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminListCopyWith<T, AdminList<T>> get copyWith => _$AdminListCopyWithImpl<T, AdminList<T>>(this as AdminList<T>, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AdminList<T>;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminList<T>&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.next, _this.next) || other.next == _this.next)&&(identical(other.loadingMore, _this.loadingMore) || other.loadingMore == _this.loadingMore));
}


@override
int get hashCode {
  final _this = this as AdminList<T>;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.next,_this.loadingMore);
}

@override
String toString() {
  final _this = this as AdminList<T>;
  return 'AdminList<$T>(items: ${_this.items}, next: ${_this.next}, loadingMore: ${_this.loadingMore})';
}


}

/// @nodoc
abstract mixin class $AdminListCopyWith<T,$Res>  {
  factory $AdminListCopyWith(AdminList<T> value, $Res Function(AdminList<T>) _then) = _$AdminListCopyWithImpl;
@useResult
$Res call({
 List<T> items, PageCursor? next, bool loadingMore
});




}
/// @nodoc
class _$AdminListCopyWithImpl<T,$Res>
    implements $AdminListCopyWith<T, $Res> {
  _$AdminListCopyWithImpl(this._self, this._then);

  final AdminList<T> _self;
  final $Res Function(AdminList<T>) _then;

/// Create a copy of AdminList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? next = freezed,Object? loadingMore = null,}) {
  return _then(AdminList(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<T>,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as PageCursor?,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminList].
extension AdminListPatterns<T> on AdminList<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminList<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminList() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminList<T> value)  $default,){
final _that = this;
switch (_that) {
case _AdminList():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminList<T> value)?  $default,){
final _that = this;
switch (_that) {
case _AdminList() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<T> items,  PageCursor? next,  bool loadingMore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminList() when $default != null:
return $default(_that.items,_that.next,_that.loadingMore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<T> items,  PageCursor? next,  bool loadingMore)  $default,) {final _that = this;
switch (_that) {
case _AdminList():
return $default(_that.items,_that.next,_that.loadingMore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<T> items,  PageCursor? next,  bool loadingMore)?  $default,) {final _that = this;
switch (_that) {
case _AdminList() when $default != null:
return $default(_that.items,_that.next,_that.loadingMore);case _:
  return null;

}
}

}

/// @nodoc


class _AdminList<T> extends AdminList<T> {
  const _AdminList({required  List<T> items, this.next, this.loadingMore = false}): _items = items,super._();
  

 final  List<T> _items;
@override List<T> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  PageCursor? next;
@override@JsonKey() final  bool loadingMore;

/// Create a copy of AdminList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminListCopyWith<T, _AdminList<T>> get copyWith => __$AdminListCopyWithImpl<T, _AdminList<T>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminList<T>&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.next, next) || other.next == next)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),next,loadingMore);
}

@override
String toString() {
    return 'AdminList<$T>(items: $items, next: $next, loadingMore: $loadingMore)';
}


}

/// @nodoc
abstract mixin class _$AdminListCopyWith<T,$Res> implements $AdminListCopyWith<T, $Res> {
  factory _$AdminListCopyWith(_AdminList<T> value, $Res Function(_AdminList<T>) _then) = __$AdminListCopyWithImpl;
@override @useResult
$Res call({
 List<T> items, PageCursor? next, bool loadingMore
});




}
/// @nodoc
class __$AdminListCopyWithImpl<T,$Res>
    implements _$AdminListCopyWith<T, $Res> {
  __$AdminListCopyWithImpl(this._self, this._then);

  final _AdminList<T> _self;
  final $Res Function(_AdminList<T>) _then;

/// Create a copy of AdminList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? next = freezed,Object? loadingMore = null,}) {
  return _then(_AdminList<T>(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<T>,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as PageCursor?,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
