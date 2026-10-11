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
 bool get reachedStart;/// Photo messages still uploading, oldest first (CHAT-3).
 List<OutgoingPhotos> get outgoing;/// Text messages waiting their turn or refused, oldest first (CHAT-4).
/// Each disappears once the server has it.
 List<OutgoingText> get queued;
/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatStateCopyWith<ChatState> get copyWith => _$ChatStateCopyWithImpl<ChatState>(this as ChatState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ChatState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatState&&const DeepCollectionEquality().equals(other.messages, _this.messages)&&(identical(other.loading, _this.loading) || other.loading == _this.loading)&&(identical(other.loadingOlder, _this.loadingOlder) || other.loadingOlder == _this.loadingOlder)&&(identical(other.reachedStart, _this.reachedStart) || other.reachedStart == _this.reachedStart)&&const DeepCollectionEquality().equals(other.outgoing, _this.outgoing)&&const DeepCollectionEquality().equals(other.queued, _this.queued));
}


@override
int get hashCode {
  final _this = this as ChatState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.messages),_this.loading,_this.loadingOlder,_this.reachedStart,const DeepCollectionEquality().hash(_this.outgoing),const DeepCollectionEquality().hash(_this.queued));
}

@override
String toString() {
  final _this = this as ChatState;
  return 'ChatState(messages: ${_this.messages}, loading: ${_this.loading}, loadingOlder: ${_this.loadingOlder}, reachedStart: ${_this.reachedStart}, outgoing: ${_this.outgoing}, queued: ${_this.queued})';
}


}

/// @nodoc
abstract mixin class $ChatStateCopyWith<$Res>  {
  factory $ChatStateCopyWith(ChatState value, $Res Function(ChatState) _then) = _$ChatStateCopyWithImpl;
@useResult
$Res call({
 List<Message> messages, bool loading, bool loadingOlder, bool reachedStart, List<OutgoingPhotos> outgoing, List<OutgoingText> queued
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
@pragma('vm:prefer-inline') @override $Res call({Object? messages = null,Object? loading = null,Object? loadingOlder = null,Object? reachedStart = null,Object? outgoing = null,Object? queued = null,}) {
  return _then(ChatState(
messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<Message>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,loadingOlder: null == loadingOlder ? _self.loadingOlder : loadingOlder // ignore: cast_nullable_to_non_nullable
as bool,reachedStart: null == reachedStart ? _self.reachedStart : reachedStart // ignore: cast_nullable_to_non_nullable
as bool,outgoing: null == outgoing ? _self.outgoing : outgoing // ignore: cast_nullable_to_non_nullable
as List<OutgoingPhotos>,queued: null == queued ? _self.queued : queued // ignore: cast_nullable_to_non_nullable
as List<OutgoingText>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Message> messages,  bool loading,  bool loadingOlder,  bool reachedStart,  List<OutgoingPhotos> outgoing,  List<OutgoingText> queued)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatState() when $default != null:
return $default(_that.messages,_that.loading,_that.loadingOlder,_that.reachedStart,_that.outgoing,_that.queued);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Message> messages,  bool loading,  bool loadingOlder,  bool reachedStart,  List<OutgoingPhotos> outgoing,  List<OutgoingText> queued)  $default,) {final _that = this;
switch (_that) {
case _ChatState():
return $default(_that.messages,_that.loading,_that.loadingOlder,_that.reachedStart,_that.outgoing,_that.queued);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Message> messages,  bool loading,  bool loadingOlder,  bool reachedStart,  List<OutgoingPhotos> outgoing,  List<OutgoingText> queued)?  $default,) {final _that = this;
switch (_that) {
case _ChatState() when $default != null:
return $default(_that.messages,_that.loading,_that.loadingOlder,_that.reachedStart,_that.outgoing,_that.queued);case _:
  return null;

}
}

}

/// @nodoc


class _ChatState implements ChatState {
  const _ChatState({ List<Message> messages = const <Message>[], this.loading = true, this.loadingOlder = false, this.reachedStart = false,  List<OutgoingPhotos> outgoing = const <OutgoingPhotos>[],  List<OutgoingText> queued = const <OutgoingText>[]}): _messages = messages,_outgoing = outgoing,_queued = queued;
  

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
/// Photo messages still uploading, oldest first (CHAT-3).
 final  List<OutgoingPhotos> _outgoing;
/// Photo messages still uploading, oldest first (CHAT-3).
@override@JsonKey() List<OutgoingPhotos> get outgoing {
  if (_outgoing is EqualUnmodifiableListView) return _outgoing;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_outgoing);
}

/// Text messages waiting their turn or refused, oldest first (CHAT-4).
/// Each disappears once the server has it.
 final  List<OutgoingText> _queued;
/// Text messages waiting their turn or refused, oldest first (CHAT-4).
/// Each disappears once the server has it.
@override@JsonKey() List<OutgoingText> get queued {
  if (_queued is EqualUnmodifiableListView) return _queued;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_queued);
}


/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatStateCopyWith<_ChatState> get copyWith => __$ChatStateCopyWithImpl<_ChatState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatState&&const DeepCollectionEquality().equals(other.messages, _messages)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.loadingOlder, loadingOlder) || other.loadingOlder == loadingOlder)&&(identical(other.reachedStart, reachedStart) || other.reachedStart == reachedStart)&&const DeepCollectionEquality().equals(other.outgoing, _outgoing)&&const DeepCollectionEquality().equals(other.queued, _queued));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_messages),loading,loadingOlder,reachedStart,const DeepCollectionEquality().hash(_outgoing),const DeepCollectionEquality().hash(_queued));
}

@override
String toString() {
    return 'ChatState(messages: $messages, loading: $loading, loadingOlder: $loadingOlder, reachedStart: $reachedStart, outgoing: $outgoing, queued: $queued)';
}


}

/// @nodoc
abstract mixin class _$ChatStateCopyWith<$Res> implements $ChatStateCopyWith<$Res> {
  factory _$ChatStateCopyWith(_ChatState value, $Res Function(_ChatState) _then) = __$ChatStateCopyWithImpl;
@override @useResult
$Res call({
 List<Message> messages, bool loading, bool loadingOlder, bool reachedStart, List<OutgoingPhotos> outgoing, List<OutgoingText> queued
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
@override @pragma('vm:prefer-inline') $Res call({Object? messages = null,Object? loading = null,Object? loadingOlder = null,Object? reachedStart = null,Object? outgoing = null,Object? queued = null,}) {
  return _then(_ChatState(
messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<Message>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,loadingOlder: null == loadingOlder ? _self.loadingOlder : loadingOlder // ignore: cast_nullable_to_non_nullable
as bool,reachedStart: null == reachedStart ? _self.reachedStart : reachedStart // ignore: cast_nullable_to_non_nullable
as bool,outgoing: null == outgoing ? _self._outgoing : outgoing // ignore: cast_nullable_to_non_nullable
as List<OutgoingPhotos>,queued: null == queued ? _self._queued : queued // ignore: cast_nullable_to_non_nullable
as List<OutgoingText>,
  ));
}


}

/// @nodoc
mixin _$OutgoingText {

/// The message ID it will have on the server.
 String get id; String get text; bool get failed;
/// Create a copy of OutgoingText
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutgoingTextCopyWith<OutgoingText> get copyWith => _$OutgoingTextCopyWithImpl<OutgoingText>(this as OutgoingText, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OutgoingText;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutgoingText&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.failed, _this.failed) || other.failed == _this.failed));
}


@override
int get hashCode {
  final _this = this as OutgoingText;
  return Object.hash(runtimeType,_this.id,_this.text,_this.failed);
}

@override
String toString() {
  final _this = this as OutgoingText;
  return 'OutgoingText(id: ${_this.id}, text: ${_this.text}, failed: ${_this.failed})';
}


}

/// @nodoc
abstract mixin class $OutgoingTextCopyWith<$Res>  {
  factory $OutgoingTextCopyWith(OutgoingText value, $Res Function(OutgoingText) _then) = _$OutgoingTextCopyWithImpl;
@useResult
$Res call({
 String id, String text, bool failed
});




}
/// @nodoc
class _$OutgoingTextCopyWithImpl<$Res>
    implements $OutgoingTextCopyWith<$Res> {
  _$OutgoingTextCopyWithImpl(this._self, this._then);

  final OutgoingText _self;
  final $Res Function(OutgoingText) _then;

/// Create a copy of OutgoingText
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? text = null,Object? failed = null,}) {
  return _then(OutgoingText(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [OutgoingText].
extension OutgoingTextPatterns on OutgoingText {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OutgoingText value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OutgoingText() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OutgoingText value)  $default,){
final _that = this;
switch (_that) {
case _OutgoingText():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OutgoingText value)?  $default,){
final _that = this;
switch (_that) {
case _OutgoingText() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String text,  bool failed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutgoingText() when $default != null:
return $default(_that.id,_that.text,_that.failed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String text,  bool failed)  $default,) {final _that = this;
switch (_that) {
case _OutgoingText():
return $default(_that.id,_that.text,_that.failed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String text,  bool failed)?  $default,) {final _that = this;
switch (_that) {
case _OutgoingText() when $default != null:
return $default(_that.id,_that.text,_that.failed);case _:
  return null;

}
}

}

/// @nodoc


class _OutgoingText implements OutgoingText {
  const _OutgoingText({required this.id, required this.text, this.failed = false});
  

/// The message ID it will have on the server.
@override final  String id;
@override final  String text;
@override@JsonKey() final  bool failed;

/// Create a copy of OutgoingText
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutgoingTextCopyWith<_OutgoingText> get copyWith => __$OutgoingTextCopyWithImpl<_OutgoingText>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutgoingText&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.failed, failed) || other.failed == failed));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,text,failed);
}

@override
String toString() {
    return 'OutgoingText(id: $id, text: $text, failed: $failed)';
}


}

/// @nodoc
abstract mixin class _$OutgoingTextCopyWith<$Res> implements $OutgoingTextCopyWith<$Res> {
  factory _$OutgoingTextCopyWith(_OutgoingText value, $Res Function(_OutgoingText) _then) = __$OutgoingTextCopyWithImpl;
@override @useResult
$Res call({
 String id, String text, bool failed
});




}
/// @nodoc
class __$OutgoingTextCopyWithImpl<$Res>
    implements _$OutgoingTextCopyWith<$Res> {
  __$OutgoingTextCopyWithImpl(this._self, this._then);

  final _OutgoingText _self;
  final $Res Function(_OutgoingText) _then;

/// Create a copy of OutgoingText
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = null,Object? failed = null,}) {
  return _then(_OutgoingText(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$OutgoingPhotos {

 int get id; List<NewPhoto> get photos; String get caption; double get progress; bool get failed;
/// Create a copy of OutgoingPhotos
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutgoingPhotosCopyWith<OutgoingPhotos> get copyWith => _$OutgoingPhotosCopyWithImpl<OutgoingPhotos>(this as OutgoingPhotos, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OutgoingPhotos;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutgoingPhotos&&(identical(other.id, _this.id) || other.id == _this.id)&&const DeepCollectionEquality().equals(other.photos, _this.photos)&&(identical(other.caption, _this.caption) || other.caption == _this.caption)&&(identical(other.progress, _this.progress) || other.progress == _this.progress)&&(identical(other.failed, _this.failed) || other.failed == _this.failed));
}


@override
int get hashCode {
  final _this = this as OutgoingPhotos;
  return Object.hash(runtimeType,_this.id,const DeepCollectionEquality().hash(_this.photos),_this.caption,_this.progress,_this.failed);
}

@override
String toString() {
  final _this = this as OutgoingPhotos;
  return 'OutgoingPhotos(id: ${_this.id}, photos: ${_this.photos}, caption: ${_this.caption}, progress: ${_this.progress}, failed: ${_this.failed})';
}


}

/// @nodoc
abstract mixin class $OutgoingPhotosCopyWith<$Res>  {
  factory $OutgoingPhotosCopyWith(OutgoingPhotos value, $Res Function(OutgoingPhotos) _then) = _$OutgoingPhotosCopyWithImpl;
@useResult
$Res call({
 int id, List<NewPhoto> photos, String caption, double progress, bool failed
});




}
/// @nodoc
class _$OutgoingPhotosCopyWithImpl<$Res>
    implements $OutgoingPhotosCopyWith<$Res> {
  _$OutgoingPhotosCopyWithImpl(this._self, this._then);

  final OutgoingPhotos _self;
  final $Res Function(OutgoingPhotos) _then;

/// Create a copy of OutgoingPhotos
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? photos = null,Object? caption = null,Object? progress = null,Object? failed = null,}) {
  return _then(OutgoingPhotos(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<NewPhoto>,caption: null == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [OutgoingPhotos].
extension OutgoingPhotosPatterns on OutgoingPhotos {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OutgoingPhotos value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OutgoingPhotos() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OutgoingPhotos value)  $default,){
final _that = this;
switch (_that) {
case _OutgoingPhotos():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OutgoingPhotos value)?  $default,){
final _that = this;
switch (_that) {
case _OutgoingPhotos() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  List<NewPhoto> photos,  String caption,  double progress,  bool failed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutgoingPhotos() when $default != null:
return $default(_that.id,_that.photos,_that.caption,_that.progress,_that.failed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  List<NewPhoto> photos,  String caption,  double progress,  bool failed)  $default,) {final _that = this;
switch (_that) {
case _OutgoingPhotos():
return $default(_that.id,_that.photos,_that.caption,_that.progress,_that.failed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  List<NewPhoto> photos,  String caption,  double progress,  bool failed)?  $default,) {final _that = this;
switch (_that) {
case _OutgoingPhotos() when $default != null:
return $default(_that.id,_that.photos,_that.caption,_that.progress,_that.failed);case _:
  return null;

}
}

}

/// @nodoc


class _OutgoingPhotos implements OutgoingPhotos {
  const _OutgoingPhotos({required this.id, required  List<NewPhoto> photos, this.caption = '', this.progress = 0, this.failed = false}): _photos = photos;
  

@override final  int id;
 final  List<NewPhoto> _photos;
@override List<NewPhoto> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}

@override@JsonKey() final  String caption;
@override@JsonKey() final  double progress;
@override@JsonKey() final  bool failed;

/// Create a copy of OutgoingPhotos
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutgoingPhotosCopyWith<_OutgoingPhotos> get copyWith => __$OutgoingPhotosCopyWithImpl<_OutgoingPhotos>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutgoingPhotos&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.photos, _photos)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.failed, failed) || other.failed == failed));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_photos),caption,progress,failed);
}

@override
String toString() {
    return 'OutgoingPhotos(id: $id, photos: $photos, caption: $caption, progress: $progress, failed: $failed)';
}


}

/// @nodoc
abstract mixin class _$OutgoingPhotosCopyWith<$Res> implements $OutgoingPhotosCopyWith<$Res> {
  factory _$OutgoingPhotosCopyWith(_OutgoingPhotos value, $Res Function(_OutgoingPhotos) _then) = __$OutgoingPhotosCopyWithImpl;
@override @useResult
$Res call({
 int id, List<NewPhoto> photos, String caption, double progress, bool failed
});




}
/// @nodoc
class __$OutgoingPhotosCopyWithImpl<$Res>
    implements _$OutgoingPhotosCopyWith<$Res> {
  __$OutgoingPhotosCopyWithImpl(this._self, this._then);

  final _OutgoingPhotos _self;
  final $Res Function(_OutgoingPhotos) _then;

/// Create a copy of OutgoingPhotos
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? photos = null,Object? caption = null,Object? progress = null,Object? failed = null,}) {
  return _then(_OutgoingPhotos(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<NewPhoto>,caption: null == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
