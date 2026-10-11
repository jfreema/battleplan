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
mixin _$ChatState {

/// Every message loaded so far, newest first.
 List<Message> get messages;/// True until the newest page first arrives.
 bool get loading; bool get loadingOlder;/// True once the first message of the chat is loaded.
 bool get reachedStart;
/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatStateCopyWith<ChatState> get copyWith => _$ChatStateCopyWithImpl<ChatState>(this as ChatState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ChatState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatState&&const DeepCollectionEquality().equals(other.messages, _this.messages)&&(identical(other.loading, _this.loading) || other.loading == _this.loading)&&(identical(other.loadingOlder, _this.loadingOlder) || other.loadingOlder == _this.loadingOlder)&&(identical(other.reachedStart, _this.reachedStart) || other.reachedStart == _this.reachedStart));
}


@override
int get hashCode {
  final _this = this as ChatState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.messages),_this.loading,_this.loadingOlder,_this.reachedStart);
}

@override
String toString() {
  final _this = this as ChatState;
  return 'ChatState(messages: ${_this.messages}, loading: ${_this.loading}, loadingOlder: ${_this.loadingOlder}, reachedStart: ${_this.reachedStart})';
}


}

/// @nodoc
abstract mixin class $ChatStateCopyWith<$Res>  {
  factory $ChatStateCopyWith(ChatState value, $Res Function(ChatState) _then) = _$ChatStateCopyWithImpl;
@useResult
$Res call({
 List<Message> messages, bool loading, bool loadingOlder, bool reachedStart
});




}
/// @nodoc
class _$ChatStateCopyWithImpl<$Res>
    implements $ChatStateCopyWith<$Res> {
  _$ChatStateCopyWithImpl(this._self, this._then);

  final ChatState _self;
  final $Res Function(ChatState) _then;

/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messages = null,Object? loading = null,Object? loadingOlder = null,Object? reachedStart = null,}) {
  return _then(ChatState(
messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<Message>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,loadingOlder: null == loadingOlder ? _self.loadingOlder : loadingOlder // ignore: cast_nullable_to_non_nullable
as bool,reachedStart: null == reachedStart ? _self.reachedStart : reachedStart // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatState].
extension ChatStatePatterns on ChatState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatState value)  $default,){
final _that = this;
switch (_that) {
case _ChatState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatState value)?  $default,){
final _that = this;
switch (_that) {
case _ChatState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Message> messages,  bool loading,  bool loadingOlder,  bool reachedStart)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatState() when $default != null:
return $default(_that.messages,_that.loading,_that.loadingOlder,_that.reachedStart);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Message> messages,  bool loading,  bool loadingOlder,  bool reachedStart)  $default,) {final _that = this;
switch (_that) {
case _ChatState():
return $default(_that.messages,_that.loading,_that.loadingOlder,_that.reachedStart);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Message> messages,  bool loading,  bool loadingOlder,  bool reachedStart)?  $default,) {final _that = this;
switch (_that) {
case _ChatState() when $default != null:
return $default(_that.messages,_that.loading,_that.loadingOlder,_that.reachedStart);case _:
  return null;

}
}

}

/// @nodoc


class _ChatState implements ChatState {
  const _ChatState({ List<Message> messages = const <Message>[], this.loading = true, this.loadingOlder = false, this.reachedStart = false}): _messages = messages;
  

/// Every message loaded so far, newest first.
 final  List<Message> _messages;
/// Every message loaded so far, newest first.
@override@JsonKey() List<Message> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}

/// True until the newest page first arrives.
@override@JsonKey() final  bool loading;
@override@JsonKey() final  bool loadingOlder;
/// True once the first message of the chat is loaded.
@override@JsonKey() final  bool reachedStart;

/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatStateCopyWith<_ChatState> get copyWith => __$ChatStateCopyWithImpl<_ChatState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatState&&const DeepCollectionEquality().equals(other.messages, _messages)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.loadingOlder, loadingOlder) || other.loadingOlder == loadingOlder)&&(identical(other.reachedStart, reachedStart) || other.reachedStart == reachedStart));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_messages),loading,loadingOlder,reachedStart);
}

@override
String toString() {
    return 'ChatState(messages: $messages, loading: $loading, loadingOlder: $loadingOlder, reachedStart: $reachedStart)';
}


}

/// @nodoc
abstract mixin class _$ChatStateCopyWith<$Res> implements $ChatStateCopyWith<$Res> {
  factory _$ChatStateCopyWith(_ChatState value, $Res Function(_ChatState) _then) = __$ChatStateCopyWithImpl;
@override @useResult
$Res call({
 List<Message> messages, bool loading, bool loadingOlder, bool reachedStart
});




}
/// @nodoc
class __$ChatStateCopyWithImpl<$Res>
    implements _$ChatStateCopyWith<$Res> {
  __$ChatStateCopyWithImpl(this._self, this._then);

  final _ChatState _self;
  final $Res Function(_ChatState) _then;

/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messages = null,Object? loading = null,Object? loadingOlder = null,Object? reachedStart = null,}) {
  return _then(_ChatState(
messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<Message>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,loadingOlder: null == loadingOlder ? _self.loadingOlder : loadingOlder // ignore: cast_nullable_to_non_nullable
as bool,reachedStart: null == reachedStart ? _self.reachedStart : reachedStart // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
