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
 bool get reachedStart;/// Opened at the first unread message with more unread than the newest
/// page holds (CHAT-1): the newest message loaded below it, after which
/// messages are missing until scrolling down loads them. Null when
/// nothing is missing.
 String? get gapAfter; bool get loadingNewer;/// False while the newest page comes from the offline cache: photos
/// wait for a connection (CHAT-4).
 bool get online;/// Photo messages still uploading, oldest first (CHAT-3).
 List<OutgoingPhotos> get outgoing;/// Text messages waiting their turn or refused, oldest first (CHAT-4).
/// Each disappears once the server has it.
 List<OutgoingText> get queued;/// Polls waiting their turn in the send queue or refused (POLL-1), so a
/// poll posted offline behind a queued text still shows as sending.
 List<OutgoingPoll> get polls;
/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatStateCopyWith<ChatState> get copyWith => _$ChatStateCopyWithImpl<ChatState>(this as ChatState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ChatState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatState&&const DeepCollectionEquality().equals(other.messages, _this.messages)&&(identical(other.loading, _this.loading) || other.loading == _this.loading)&&(identical(other.loadingOlder, _this.loadingOlder) || other.loadingOlder == _this.loadingOlder)&&(identical(other.reachedStart, _this.reachedStart) || other.reachedStart == _this.reachedStart)&&(identical(other.gapAfter, _this.gapAfter) || other.gapAfter == _this.gapAfter)&&(identical(other.loadingNewer, _this.loadingNewer) || other.loadingNewer == _this.loadingNewer)&&(identical(other.online, _this.online) || other.online == _this.online)&&const DeepCollectionEquality().equals(other.outgoing, _this.outgoing)&&const DeepCollectionEquality().equals(other.queued, _this.queued)&&const DeepCollectionEquality().equals(other.polls, _this.polls));
}


@override
int get hashCode {
  final _this = this as ChatState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.messages),_this.loading,_this.loadingOlder,_this.reachedStart,_this.gapAfter,_this.loadingNewer,_this.online,const DeepCollectionEquality().hash(_this.outgoing),const DeepCollectionEquality().hash(_this.queued),const DeepCollectionEquality().hash(_this.polls));
}

@override
String toString() {
  final _this = this as ChatState;
  return 'ChatState(messages: ${_this.messages}, loading: ${_this.loading}, loadingOlder: ${_this.loadingOlder}, reachedStart: ${_this.reachedStart}, gapAfter: ${_this.gapAfter}, loadingNewer: ${_this.loadingNewer}, online: ${_this.online}, outgoing: ${_this.outgoing}, queued: ${_this.queued}, polls: ${_this.polls})';
}


}

/// @nodoc
abstract mixin class $ChatStateCopyWith<$Res>  {
  factory $ChatStateCopyWith(ChatState value, $Res Function(ChatState) _then) = _$ChatStateCopyWithImpl;
@useResult
$Res call({
 List<Message> messages, bool loading, bool loadingOlder, bool reachedStart, String? gapAfter, bool loadingNewer, bool online, List<OutgoingPhotos> outgoing, List<OutgoingText> queued, List<OutgoingPoll> polls
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
@pragma('vm:prefer-inline') @override $Res call({Object? messages = null,Object? loading = null,Object? loadingOlder = null,Object? reachedStart = null,Object? gapAfter = freezed,Object? loadingNewer = null,Object? online = null,Object? outgoing = null,Object? queued = null,Object? polls = null,}) {
  return _then(ChatState(
messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<Message>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,loadingOlder: null == loadingOlder ? _self.loadingOlder : loadingOlder // ignore: cast_nullable_to_non_nullable
as bool,reachedStart: null == reachedStart ? _self.reachedStart : reachedStart // ignore: cast_nullable_to_non_nullable
as bool,gapAfter: freezed == gapAfter ? _self.gapAfter : gapAfter // ignore: cast_nullable_to_non_nullable
as String?,loadingNewer: null == loadingNewer ? _self.loadingNewer : loadingNewer // ignore: cast_nullable_to_non_nullable
as bool,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,outgoing: null == outgoing ? _self.outgoing : outgoing // ignore: cast_nullable_to_non_nullable
as List<OutgoingPhotos>,queued: null == queued ? _self.queued : queued // ignore: cast_nullable_to_non_nullable
as List<OutgoingText>,polls: null == polls ? _self.polls : polls // ignore: cast_nullable_to_non_nullable
as List<OutgoingPoll>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Message> messages,  bool loading,  bool loadingOlder,  bool reachedStart,  String? gapAfter,  bool loadingNewer,  bool online,  List<OutgoingPhotos> outgoing,  List<OutgoingText> queued,  List<OutgoingPoll> polls)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatState() when $default != null:
return $default(_that.messages,_that.loading,_that.loadingOlder,_that.reachedStart,_that.gapAfter,_that.loadingNewer,_that.online,_that.outgoing,_that.queued,_that.polls);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Message> messages,  bool loading,  bool loadingOlder,  bool reachedStart,  String? gapAfter,  bool loadingNewer,  bool online,  List<OutgoingPhotos> outgoing,  List<OutgoingText> queued,  List<OutgoingPoll> polls)  $default,) {final _that = this;
switch (_that) {
case _ChatState():
return $default(_that.messages,_that.loading,_that.loadingOlder,_that.reachedStart,_that.gapAfter,_that.loadingNewer,_that.online,_that.outgoing,_that.queued,_that.polls);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Message> messages,  bool loading,  bool loadingOlder,  bool reachedStart,  String? gapAfter,  bool loadingNewer,  bool online,  List<OutgoingPhotos> outgoing,  List<OutgoingText> queued,  List<OutgoingPoll> polls)?  $default,) {final _that = this;
switch (_that) {
case _ChatState() when $default != null:
return $default(_that.messages,_that.loading,_that.loadingOlder,_that.reachedStart,_that.gapAfter,_that.loadingNewer,_that.online,_that.outgoing,_that.queued,_that.polls);case _:
  return null;

}
}

}

/// @nodoc


class _ChatState implements ChatState {
  const _ChatState({ List<Message> messages = const <Message>[], this.loading = true, this.loadingOlder = false, this.reachedStart = false, this.gapAfter, this.loadingNewer = false, this.online = true,  List<OutgoingPhotos> outgoing = const <OutgoingPhotos>[],  List<OutgoingText> queued = const <OutgoingText>[],  List<OutgoingPoll> polls = const <OutgoingPoll>[]}): _messages = messages,_outgoing = outgoing,_queued = queued,_polls = polls;
  

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
/// Opened at the first unread message with more unread than the newest
/// page holds (CHAT-1): the newest message loaded below it, after which
/// messages are missing until scrolling down loads them. Null when
/// nothing is missing.
@override final  String? gapAfter;
@override@JsonKey() final  bool loadingNewer;
/// False while the newest page comes from the offline cache: photos
/// wait for a connection (CHAT-4).
@override@JsonKey() final  bool online;
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

/// Polls waiting their turn in the send queue or refused (POLL-1), so a
/// poll posted offline behind a queued text still shows as sending.
 final  List<OutgoingPoll> _polls;
/// Polls waiting their turn in the send queue or refused (POLL-1), so a
/// poll posted offline behind a queued text still shows as sending.
@override@JsonKey() List<OutgoingPoll> get polls {
  if (_polls is EqualUnmodifiableListView) return _polls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_polls);
}


/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatStateCopyWith<_ChatState> get copyWith => __$ChatStateCopyWithImpl<_ChatState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatState&&const DeepCollectionEquality().equals(other.messages, _messages)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.loadingOlder, loadingOlder) || other.loadingOlder == loadingOlder)&&(identical(other.reachedStart, reachedStart) || other.reachedStart == reachedStart)&&(identical(other.gapAfter, gapAfter) || other.gapAfter == gapAfter)&&(identical(other.loadingNewer, loadingNewer) || other.loadingNewer == loadingNewer)&&(identical(other.online, online) || other.online == online)&&const DeepCollectionEquality().equals(other.outgoing, _outgoing)&&const DeepCollectionEquality().equals(other.queued, _queued)&&const DeepCollectionEquality().equals(other.polls, _polls));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_messages),loading,loadingOlder,reachedStart,gapAfter,loadingNewer,online,const DeepCollectionEquality().hash(_outgoing),const DeepCollectionEquality().hash(_queued),const DeepCollectionEquality().hash(_polls));
}

@override
String toString() {
    return 'ChatState(messages: $messages, loading: $loading, loadingOlder: $loadingOlder, reachedStart: $reachedStart, gapAfter: $gapAfter, loadingNewer: $loadingNewer, online: $online, outgoing: $outgoing, queued: $queued, polls: $polls)';
}


}

/// @nodoc
abstract mixin class _$ChatStateCopyWith<$Res> implements $ChatStateCopyWith<$Res> {
  factory _$ChatStateCopyWith(_ChatState value, $Res Function(_ChatState) _then) = __$ChatStateCopyWithImpl;
@override @useResult
$Res call({
 List<Message> messages, bool loading, bool loadingOlder, bool reachedStart, String? gapAfter, bool loadingNewer, bool online, List<OutgoingPhotos> outgoing, List<OutgoingText> queued, List<OutgoingPoll> polls
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
@override @pragma('vm:prefer-inline') $Res call({Object? messages = null,Object? loading = null,Object? loadingOlder = null,Object? reachedStart = null,Object? gapAfter = freezed,Object? loadingNewer = null,Object? online = null,Object? outgoing = null,Object? queued = null,Object? polls = null,}) {
  return _then(_ChatState(
messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<Message>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,loadingOlder: null == loadingOlder ? _self.loadingOlder : loadingOlder // ignore: cast_nullable_to_non_nullable
as bool,reachedStart: null == reachedStart ? _self.reachedStart : reachedStart // ignore: cast_nullable_to_non_nullable
as bool,gapAfter: freezed == gapAfter ? _self.gapAfter : gapAfter // ignore: cast_nullable_to_non_nullable
as String?,loadingNewer: null == loadingNewer ? _self.loadingNewer : loadingNewer // ignore: cast_nullable_to_non_nullable
as bool,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,outgoing: null == outgoing ? _self._outgoing : outgoing // ignore: cast_nullable_to_non_nullable
as List<OutgoingPhotos>,queued: null == queued ? _self._queued : queued // ignore: cast_nullable_to_non_nullable
as List<OutgoingText>,polls: null == polls ? _self._polls : polls // ignore: cast_nullable_to_non_nullable
as List<OutgoingPoll>,
  ));
}


}

/// @nodoc
mixin _$OutgoingPoll {

/// The ID its poll and message will have.
 String get id; NewPoll get poll; bool get failed;
/// Create a copy of OutgoingPoll
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutgoingPollCopyWith<OutgoingPoll> get copyWith => _$OutgoingPollCopyWithImpl<OutgoingPoll>(this as OutgoingPoll, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OutgoingPoll;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutgoingPoll&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.poll, _this.poll) || other.poll == _this.poll)&&(identical(other.failed, _this.failed) || other.failed == _this.failed));
}


@override
int get hashCode {
  final _this = this as OutgoingPoll;
  return Object.hash(runtimeType,_this.id,_this.poll,_this.failed);
}

@override
String toString() {
  final _this = this as OutgoingPoll;
  return 'OutgoingPoll(id: ${_this.id}, poll: ${_this.poll}, failed: ${_this.failed})';
}


}

/// @nodoc
abstract mixin class $OutgoingPollCopyWith<$Res>  {
  factory $OutgoingPollCopyWith(OutgoingPoll value, $Res Function(OutgoingPoll) _then) = _$OutgoingPollCopyWithImpl;
@useResult
$Res call({
 String id, NewPoll poll, bool failed
});


$NewPollCopyWith<$Res> get poll;

}
/// @nodoc
class _$OutgoingPollCopyWithImpl<$Res>
    implements $OutgoingPollCopyWith<$Res> {
  _$OutgoingPollCopyWithImpl(this._self, this._then);

  final OutgoingPoll _self;
  final $Res Function(OutgoingPoll) _then;

/// Create a copy of OutgoingPoll
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? poll = null,Object? failed = null,}) {
  return _then(OutgoingPoll(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,poll: null == poll ? _self.poll : poll // ignore: cast_nullable_to_non_nullable
as NewPoll,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of OutgoingPoll
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NewPollCopyWith<$Res> get poll {
  
  return $NewPollCopyWith<$Res>(_self.poll, (value) {
    return _then(_self.copyWith(poll: value));
  });
}
}


/// Adds pattern-matching-related methods to [OutgoingPoll].
extension OutgoingPollPatterns on OutgoingPoll {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OutgoingPoll value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OutgoingPoll() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OutgoingPoll value)  $default,){
final _that = this;
switch (_that) {
case _OutgoingPoll():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OutgoingPoll value)?  $default,){
final _that = this;
switch (_that) {
case _OutgoingPoll() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  NewPoll poll,  bool failed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutgoingPoll() when $default != null:
return $default(_that.id,_that.poll,_that.failed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  NewPoll poll,  bool failed)  $default,) {final _that = this;
switch (_that) {
case _OutgoingPoll():
return $default(_that.id,_that.poll,_that.failed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  NewPoll poll,  bool failed)?  $default,) {final _that = this;
switch (_that) {
case _OutgoingPoll() when $default != null:
return $default(_that.id,_that.poll,_that.failed);case _:
  return null;

}
}

}

/// @nodoc


class _OutgoingPoll implements OutgoingPoll {
  const _OutgoingPoll({required this.id, required this.poll, this.failed = false});
  

/// The ID its poll and message will have.
@override final  String id;
@override final  NewPoll poll;
@override@JsonKey() final  bool failed;

/// Create a copy of OutgoingPoll
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutgoingPollCopyWith<_OutgoingPoll> get copyWith => __$OutgoingPollCopyWithImpl<_OutgoingPoll>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutgoingPoll&&(identical(other.id, id) || other.id == id)&&(identical(other.poll, poll) || other.poll == poll)&&(identical(other.failed, failed) || other.failed == failed));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,poll,failed);
}

@override
String toString() {
    return 'OutgoingPoll(id: $id, poll: $poll, failed: $failed)';
}


}

/// @nodoc
abstract mixin class _$OutgoingPollCopyWith<$Res> implements $OutgoingPollCopyWith<$Res> {
  factory _$OutgoingPollCopyWith(_OutgoingPoll value, $Res Function(_OutgoingPoll) _then) = __$OutgoingPollCopyWithImpl;
@override @useResult
$Res call({
 String id, NewPoll poll, bool failed
});


@override $NewPollCopyWith<$Res> get poll;

}
/// @nodoc
class __$OutgoingPollCopyWithImpl<$Res>
    implements _$OutgoingPollCopyWith<$Res> {
  __$OutgoingPollCopyWithImpl(this._self, this._then);

  final _OutgoingPoll _self;
  final $Res Function(_OutgoingPoll) _then;

/// Create a copy of OutgoingPoll
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? poll = null,Object? failed = null,}) {
  return _then(_OutgoingPoll(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,poll: null == poll ? _self.poll : poll // ignore: cast_nullable_to_non_nullable
as NewPoll,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of OutgoingPoll
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NewPollCopyWith<$Res> get poll {
  
  return $NewPollCopyWith<$Res>(_self.poll, (value) {
    return _then(_self.copyWith(poll: value));
  });
}
}

/// @nodoc
mixin _$OutgoingText {

/// The message ID it will have on the server.
 String get id; String get text; String? get replyToId;/// Who it names with @, and an admin's @everyone (CHAT-14).
 List<String> get mentions; bool get mentionsEveryone;/// An admin's announcement (CHAT-15).
 bool get announcement; bool get failed;
/// Create a copy of OutgoingText
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutgoingTextCopyWith<OutgoingText> get copyWith => _$OutgoingTextCopyWithImpl<OutgoingText>(this as OutgoingText, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OutgoingText;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutgoingText&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.replyToId, _this.replyToId) || other.replyToId == _this.replyToId)&&const DeepCollectionEquality().equals(other.mentions, _this.mentions)&&(identical(other.mentionsEveryone, _this.mentionsEveryone) || other.mentionsEveryone == _this.mentionsEveryone)&&(identical(other.announcement, _this.announcement) || other.announcement == _this.announcement)&&(identical(other.failed, _this.failed) || other.failed == _this.failed));
}


@override
int get hashCode {
  final _this = this as OutgoingText;
  return Object.hash(runtimeType,_this.id,_this.text,_this.replyToId,const DeepCollectionEquality().hash(_this.mentions),_this.mentionsEveryone,_this.announcement,_this.failed);
}

@override
String toString() {
  final _this = this as OutgoingText;
  return 'OutgoingText(id: ${_this.id}, text: ${_this.text}, replyToId: ${_this.replyToId}, mentions: ${_this.mentions}, mentionsEveryone: ${_this.mentionsEveryone}, announcement: ${_this.announcement}, failed: ${_this.failed})';
}


}

/// @nodoc
abstract mixin class $OutgoingTextCopyWith<$Res>  {
  factory $OutgoingTextCopyWith(OutgoingText value, $Res Function(OutgoingText) _then) = _$OutgoingTextCopyWithImpl;
@useResult
$Res call({
 String id, String text, String? replyToId, List<String> mentions, bool mentionsEveryone, bool announcement, bool failed
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? text = null,Object? replyToId = freezed,Object? mentions = null,Object? mentionsEveryone = null,Object? announcement = null,Object? failed = null,}) {
  return _then(OutgoingText(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,replyToId: freezed == replyToId ? _self.replyToId : replyToId // ignore: cast_nullable_to_non_nullable
as String?,mentions: null == mentions ? _self.mentions : mentions // ignore: cast_nullable_to_non_nullable
as List<String>,mentionsEveryone: null == mentionsEveryone ? _self.mentionsEveryone : mentionsEveryone // ignore: cast_nullable_to_non_nullable
as bool,announcement: null == announcement ? _self.announcement : announcement // ignore: cast_nullable_to_non_nullable
as bool,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String text,  String? replyToId,  List<String> mentions,  bool mentionsEveryone,  bool announcement,  bool failed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutgoingText() when $default != null:
return $default(_that.id,_that.text,_that.replyToId,_that.mentions,_that.mentionsEveryone,_that.announcement,_that.failed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String text,  String? replyToId,  List<String> mentions,  bool mentionsEveryone,  bool announcement,  bool failed)  $default,) {final _that = this;
switch (_that) {
case _OutgoingText():
return $default(_that.id,_that.text,_that.replyToId,_that.mentions,_that.mentionsEveryone,_that.announcement,_that.failed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String text,  String? replyToId,  List<String> mentions,  bool mentionsEveryone,  bool announcement,  bool failed)?  $default,) {final _that = this;
switch (_that) {
case _OutgoingText() when $default != null:
return $default(_that.id,_that.text,_that.replyToId,_that.mentions,_that.mentionsEveryone,_that.announcement,_that.failed);case _:
  return null;

}
}

}

/// @nodoc


class _OutgoingText implements OutgoingText {
  const _OutgoingText({required this.id, required this.text, this.replyToId,  List<String> mentions = const <String>[], this.mentionsEveryone = false, this.announcement = false, this.failed = false}): _mentions = mentions;
  

/// The message ID it will have on the server.
@override final  String id;
@override final  String text;
@override final  String? replyToId;
/// Who it names with @, and an admin's @everyone (CHAT-14).
 final  List<String> _mentions;
/// Who it names with @, and an admin's @everyone (CHAT-14).
@override@JsonKey() List<String> get mentions {
  if (_mentions is EqualUnmodifiableListView) return _mentions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mentions);
}

@override@JsonKey() final  bool mentionsEveryone;
/// An admin's announcement (CHAT-15).
@override@JsonKey() final  bool announcement;
@override@JsonKey() final  bool failed;

/// Create a copy of OutgoingText
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutgoingTextCopyWith<_OutgoingText> get copyWith => __$OutgoingTextCopyWithImpl<_OutgoingText>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutgoingText&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.replyToId, replyToId) || other.replyToId == replyToId)&&const DeepCollectionEquality().equals(other.mentions, _mentions)&&(identical(other.mentionsEveryone, mentionsEveryone) || other.mentionsEveryone == mentionsEveryone)&&(identical(other.announcement, announcement) || other.announcement == announcement)&&(identical(other.failed, failed) || other.failed == failed));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,text,replyToId,const DeepCollectionEquality().hash(_mentions),mentionsEveryone,announcement,failed);
}

@override
String toString() {
    return 'OutgoingText(id: $id, text: $text, replyToId: $replyToId, mentions: $mentions, mentionsEveryone: $mentionsEveryone, announcement: $announcement, failed: $failed)';
}


}

/// @nodoc
abstract mixin class _$OutgoingTextCopyWith<$Res> implements $OutgoingTextCopyWith<$Res> {
  factory _$OutgoingTextCopyWith(_OutgoingText value, $Res Function(_OutgoingText) _then) = __$OutgoingTextCopyWithImpl;
@override @useResult
$Res call({
 String id, String text, String? replyToId, List<String> mentions, bool mentionsEveryone, bool announcement, bool failed
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = null,Object? replyToId = freezed,Object? mentions = null,Object? mentionsEveryone = null,Object? announcement = null,Object? failed = null,}) {
  return _then(_OutgoingText(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,replyToId: freezed == replyToId ? _self.replyToId : replyToId // ignore: cast_nullable_to_non_nullable
as String?,mentions: null == mentions ? _self._mentions : mentions // ignore: cast_nullable_to_non_nullable
as List<String>,mentionsEveryone: null == mentionsEveryone ? _self.mentionsEveryone : mentionsEveryone // ignore: cast_nullable_to_non_nullable
as bool,announcement: null == announcement ? _self.announcement : announcement // ignore: cast_nullable_to_non_nullable
as bool,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$OutgoingPhotos {

 int get id; List<NewPhoto> get photos; String get caption;/// A posted play's saved play (BOARD-5).
 String? get playId; double get progress; bool get failed;/// Offline: waiting for the connection to come back, then it uploads
/// by itself (CHAT-4).
 bool get waiting;
/// Create a copy of OutgoingPhotos
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutgoingPhotosCopyWith<OutgoingPhotos> get copyWith => _$OutgoingPhotosCopyWithImpl<OutgoingPhotos>(this as OutgoingPhotos, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OutgoingPhotos;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutgoingPhotos&&(identical(other.id, _this.id) || other.id == _this.id)&&const DeepCollectionEquality().equals(other.photos, _this.photos)&&(identical(other.caption, _this.caption) || other.caption == _this.caption)&&(identical(other.playId, _this.playId) || other.playId == _this.playId)&&(identical(other.progress, _this.progress) || other.progress == _this.progress)&&(identical(other.failed, _this.failed) || other.failed == _this.failed)&&(identical(other.waiting, _this.waiting) || other.waiting == _this.waiting));
}


@override
int get hashCode {
  final _this = this as OutgoingPhotos;
  return Object.hash(runtimeType,_this.id,const DeepCollectionEquality().hash(_this.photos),_this.caption,_this.playId,_this.progress,_this.failed,_this.waiting);
}

@override
String toString() {
  final _this = this as OutgoingPhotos;
  return 'OutgoingPhotos(id: ${_this.id}, photos: ${_this.photos}, caption: ${_this.caption}, playId: ${_this.playId}, progress: ${_this.progress}, failed: ${_this.failed}, waiting: ${_this.waiting})';
}


}

/// @nodoc
abstract mixin class $OutgoingPhotosCopyWith<$Res>  {
  factory $OutgoingPhotosCopyWith(OutgoingPhotos value, $Res Function(OutgoingPhotos) _then) = _$OutgoingPhotosCopyWithImpl;
@useResult
$Res call({
 int id, List<NewPhoto> photos, String caption, String? playId, double progress, bool failed, bool waiting
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? photos = null,Object? caption = null,Object? playId = freezed,Object? progress = null,Object? failed = null,Object? waiting = null,}) {
  return _then(OutgoingPhotos(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<NewPhoto>,caption: null == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String,playId: freezed == playId ? _self.playId : playId // ignore: cast_nullable_to_non_nullable
as String?,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,waiting: null == waiting ? _self.waiting : waiting // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  List<NewPhoto> photos,  String caption,  String? playId,  double progress,  bool failed,  bool waiting)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutgoingPhotos() when $default != null:
return $default(_that.id,_that.photos,_that.caption,_that.playId,_that.progress,_that.failed,_that.waiting);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  List<NewPhoto> photos,  String caption,  String? playId,  double progress,  bool failed,  bool waiting)  $default,) {final _that = this;
switch (_that) {
case _OutgoingPhotos():
return $default(_that.id,_that.photos,_that.caption,_that.playId,_that.progress,_that.failed,_that.waiting);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  List<NewPhoto> photos,  String caption,  String? playId,  double progress,  bool failed,  bool waiting)?  $default,) {final _that = this;
switch (_that) {
case _OutgoingPhotos() when $default != null:
return $default(_that.id,_that.photos,_that.caption,_that.playId,_that.progress,_that.failed,_that.waiting);case _:
  return null;

}
}

}

/// @nodoc


class _OutgoingPhotos implements OutgoingPhotos {
  const _OutgoingPhotos({required this.id, required  List<NewPhoto> photos, this.caption = '', this.playId, this.progress = 0, this.failed = false, this.waiting = false}): _photos = photos;
  

@override final  int id;
 final  List<NewPhoto> _photos;
@override List<NewPhoto> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}

@override@JsonKey() final  String caption;
/// A posted play's saved play (BOARD-5).
@override final  String? playId;
@override@JsonKey() final  double progress;
@override@JsonKey() final  bool failed;
/// Offline: waiting for the connection to come back, then it uploads
/// by itself (CHAT-4).
@override@JsonKey() final  bool waiting;

/// Create a copy of OutgoingPhotos
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutgoingPhotosCopyWith<_OutgoingPhotos> get copyWith => __$OutgoingPhotosCopyWithImpl<_OutgoingPhotos>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutgoingPhotos&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.photos, _photos)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.playId, playId) || other.playId == playId)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.failed, failed) || other.failed == failed)&&(identical(other.waiting, waiting) || other.waiting == waiting));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_photos),caption,playId,progress,failed,waiting);
}

@override
String toString() {
    return 'OutgoingPhotos(id: $id, photos: $photos, caption: $caption, playId: $playId, progress: $progress, failed: $failed, waiting: $waiting)';
}


}

/// @nodoc
abstract mixin class _$OutgoingPhotosCopyWith<$Res> implements $OutgoingPhotosCopyWith<$Res> {
  factory _$OutgoingPhotosCopyWith(_OutgoingPhotos value, $Res Function(_OutgoingPhotos) _then) = __$OutgoingPhotosCopyWithImpl;
@override @useResult
$Res call({
 int id, List<NewPhoto> photos, String caption, String? playId, double progress, bool failed, bool waiting
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? photos = null,Object? caption = null,Object? playId = freezed,Object? progress = null,Object? failed = null,Object? waiting = null,}) {
  return _then(_OutgoingPhotos(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<NewPhoto>,caption: null == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String,playId: freezed == playId ? _self.playId : playId // ignore: cast_nullable_to_non_nullable
as String?,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,waiting: null == waiting ? _self.waiting : waiting // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$TeamPhotosState {

/// Every photo loaded so far, newest first.
 List<TeamPhoto> get photos; bool get loading; bool get loadingMore;/// True once the team's first photo is loaded.
 bool get reachedEnd; bool get failed;
/// Create a copy of TeamPhotosState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamPhotosStateCopyWith<TeamPhotosState> get copyWith => _$TeamPhotosStateCopyWithImpl<TeamPhotosState>(this as TeamPhotosState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TeamPhotosState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeamPhotosState&&const DeepCollectionEquality().equals(other.photos, _this.photos)&&(identical(other.loading, _this.loading) || other.loading == _this.loading)&&(identical(other.loadingMore, _this.loadingMore) || other.loadingMore == _this.loadingMore)&&(identical(other.reachedEnd, _this.reachedEnd) || other.reachedEnd == _this.reachedEnd)&&(identical(other.failed, _this.failed) || other.failed == _this.failed));
}


@override
int get hashCode {
  final _this = this as TeamPhotosState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.photos),_this.loading,_this.loadingMore,_this.reachedEnd,_this.failed);
}

@override
String toString() {
  final _this = this as TeamPhotosState;
  return 'TeamPhotosState(photos: ${_this.photos}, loading: ${_this.loading}, loadingMore: ${_this.loadingMore}, reachedEnd: ${_this.reachedEnd}, failed: ${_this.failed})';
}


}

/// @nodoc
abstract mixin class $TeamPhotosStateCopyWith<$Res>  {
  factory $TeamPhotosStateCopyWith(TeamPhotosState value, $Res Function(TeamPhotosState) _then) = _$TeamPhotosStateCopyWithImpl;
@useResult
$Res call({
 List<TeamPhoto> photos, bool loading, bool loadingMore, bool reachedEnd, bool failed
});




}
/// @nodoc
class _$TeamPhotosStateCopyWithImpl<$Res>
    implements $TeamPhotosStateCopyWith<$Res> {
  _$TeamPhotosStateCopyWithImpl(this._self, this._then);

  final TeamPhotosState _self;
  final $Res Function(TeamPhotosState) _then;

/// Create a copy of TeamPhotosState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? photos = null,Object? loading = null,Object? loadingMore = null,Object? reachedEnd = null,Object? failed = null,}) {
  return _then(TeamPhotosState(
photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<TeamPhoto>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,reachedEnd: null == reachedEnd ? _self.reachedEnd : reachedEnd // ignore: cast_nullable_to_non_nullable
as bool,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TeamPhotosState].
extension TeamPhotosStatePatterns on TeamPhotosState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeamPhotosState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeamPhotosState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeamPhotosState value)  $default,){
final _that = this;
switch (_that) {
case _TeamPhotosState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeamPhotosState value)?  $default,){
final _that = this;
switch (_that) {
case _TeamPhotosState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<TeamPhoto> photos,  bool loading,  bool loadingMore,  bool reachedEnd,  bool failed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeamPhotosState() when $default != null:
return $default(_that.photos,_that.loading,_that.loadingMore,_that.reachedEnd,_that.failed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<TeamPhoto> photos,  bool loading,  bool loadingMore,  bool reachedEnd,  bool failed)  $default,) {final _that = this;
switch (_that) {
case _TeamPhotosState():
return $default(_that.photos,_that.loading,_that.loadingMore,_that.reachedEnd,_that.failed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<TeamPhoto> photos,  bool loading,  bool loadingMore,  bool reachedEnd,  bool failed)?  $default,) {final _that = this;
switch (_that) {
case _TeamPhotosState() when $default != null:
return $default(_that.photos,_that.loading,_that.loadingMore,_that.reachedEnd,_that.failed);case _:
  return null;

}
}

}

/// @nodoc


class _TeamPhotosState implements TeamPhotosState {
  const _TeamPhotosState({ List<TeamPhoto> photos = const <TeamPhoto>[], this.loading = true, this.loadingMore = false, this.reachedEnd = false, this.failed = false}): _photos = photos;
  

/// Every photo loaded so far, newest first.
 final  List<TeamPhoto> _photos;
/// Every photo loaded so far, newest first.
@override@JsonKey() List<TeamPhoto> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}

@override@JsonKey() final  bool loading;
@override@JsonKey() final  bool loadingMore;
/// True once the team's first photo is loaded.
@override@JsonKey() final  bool reachedEnd;
@override@JsonKey() final  bool failed;

/// Create a copy of TeamPhotosState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamPhotosStateCopyWith<_TeamPhotosState> get copyWith => __$TeamPhotosStateCopyWithImpl<_TeamPhotosState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeamPhotosState&&const DeepCollectionEquality().equals(other.photos, _photos)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.reachedEnd, reachedEnd) || other.reachedEnd == reachedEnd)&&(identical(other.failed, failed) || other.failed == failed));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_photos),loading,loadingMore,reachedEnd,failed);
}

@override
String toString() {
    return 'TeamPhotosState(photos: $photos, loading: $loading, loadingMore: $loadingMore, reachedEnd: $reachedEnd, failed: $failed)';
}


}

/// @nodoc
abstract mixin class _$TeamPhotosStateCopyWith<$Res> implements $TeamPhotosStateCopyWith<$Res> {
  factory _$TeamPhotosStateCopyWith(_TeamPhotosState value, $Res Function(_TeamPhotosState) _then) = __$TeamPhotosStateCopyWithImpl;
@override @useResult
$Res call({
 List<TeamPhoto> photos, bool loading, bool loadingMore, bool reachedEnd, bool failed
});




}
/// @nodoc
class __$TeamPhotosStateCopyWithImpl<$Res>
    implements _$TeamPhotosStateCopyWith<$Res> {
  __$TeamPhotosStateCopyWithImpl(this._self, this._then);

  final _TeamPhotosState _self;
  final $Res Function(_TeamPhotosState) _then;

/// Create a copy of TeamPhotosState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? photos = null,Object? loading = null,Object? loadingMore = null,Object? reachedEnd = null,Object? failed = null,}) {
  return _then(_TeamPhotosState(
photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<TeamPhoto>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,reachedEnd: null == reachedEnd ? _self.reachedEnd : reachedEnd // ignore: cast_nullable_to_non_nullable
as bool,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
