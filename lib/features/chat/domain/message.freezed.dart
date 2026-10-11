// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Message {

 String get id; GroupId get groupId; String get authorId; String get authorName; MessageType get type; String get text; String? get authorPhotoPath;/// "Emma #7, Liam #23" for a guardian on a youth team (PLAYER-8).
 String? get authorPlayerSummary; String? get replyToId; Map<String, Reaction> get reactions; DateTime? get deletedAt;/// When the server stamped it. Null while a sent message is still local.
 DateTime? get createdAt;/// True until the server has the message (CHAT-4 "sending").
 bool get pending;
/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageCopyWith<Message> get copyWith => _$MessageCopyWithImpl<Message>(this as Message, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Message;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Message&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.authorId, _this.authorId) || other.authorId == _this.authorId)&&(identical(other.authorName, _this.authorName) || other.authorName == _this.authorName)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.authorPhotoPath, _this.authorPhotoPath) || other.authorPhotoPath == _this.authorPhotoPath)&&(identical(other.authorPlayerSummary, _this.authorPlayerSummary) || other.authorPlayerSummary == _this.authorPlayerSummary)&&(identical(other.replyToId, _this.replyToId) || other.replyToId == _this.replyToId)&&const DeepCollectionEquality().equals(other.reactions, _this.reactions)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.pending, _this.pending) || other.pending == _this.pending));
}


@override
int get hashCode {
  final _this = this as Message;
  return Object.hash(runtimeType,_this.id,_this.groupId,_this.authorId,_this.authorName,_this.type,_this.text,_this.authorPhotoPath,_this.authorPlayerSummary,_this.replyToId,const DeepCollectionEquality().hash(_this.reactions),_this.deletedAt,_this.createdAt,_this.pending);
}

@override
String toString() {
  final _this = this as Message;
  return 'Message(id: ${_this.id}, groupId: ${_this.groupId}, authorId: ${_this.authorId}, authorName: ${_this.authorName}, type: ${_this.type}, text: ${_this.text}, authorPhotoPath: ${_this.authorPhotoPath}, authorPlayerSummary: ${_this.authorPlayerSummary}, replyToId: ${_this.replyToId}, reactions: ${_this.reactions}, deletedAt: ${_this.deletedAt}, createdAt: ${_this.createdAt}, pending: ${_this.pending})';
}


}

/// @nodoc
abstract mixin class $MessageCopyWith<$Res>  {
  factory $MessageCopyWith(Message value, $Res Function(Message) _then) = _$MessageCopyWithImpl;
@useResult
$Res call({
 String id, GroupId groupId, String authorId, String authorName, MessageType type, String text, String? authorPhotoPath, String? authorPlayerSummary, String? replyToId, Map<String, Reaction> reactions, DateTime? deletedAt, DateTime? createdAt, bool pending
});




}
/// @nodoc
class _$MessageCopyWithImpl<$Res>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._self, this._then);

  final Message _self;
  final $Res Function(Message) _then;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? groupId = null,Object? authorId = null,Object? authorName = null,Object? type = null,Object? text = null,Object? authorPhotoPath = freezed,Object? authorPlayerSummary = freezed,Object? replyToId = freezed,Object? reactions = null,Object? deletedAt = freezed,Object? createdAt = freezed,Object? pending = null,}) {
  return _then(Message(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MessageType,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,authorPhotoPath: freezed == authorPhotoPath ? _self.authorPhotoPath : authorPhotoPath // ignore: cast_nullable_to_non_nullable
as String?,authorPlayerSummary: freezed == authorPlayerSummary ? _self.authorPlayerSummary : authorPlayerSummary // ignore: cast_nullable_to_non_nullable
as String?,replyToId: freezed == replyToId ? _self.replyToId : replyToId // ignore: cast_nullable_to_non_nullable
as String?,reactions: null == reactions ? _self.reactions : reactions // ignore: cast_nullable_to_non_nullable
as Map<String, Reaction>,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Message].
extension MessagePatterns on Message {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Message value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Message() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Message value)  $default,){
final _that = this;
switch (_that) {
case _Message():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Message value)?  $default,){
final _that = this;
switch (_that) {
case _Message() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  GroupId groupId,  String authorId,  String authorName,  MessageType type,  String text,  String? authorPhotoPath,  String? authorPlayerSummary,  String? replyToId,  Map<String, Reaction> reactions,  DateTime? deletedAt,  DateTime? createdAt,  bool pending)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that.id,_that.groupId,_that.authorId,_that.authorName,_that.type,_that.text,_that.authorPhotoPath,_that.authorPlayerSummary,_that.replyToId,_that.reactions,_that.deletedAt,_that.createdAt,_that.pending);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  GroupId groupId,  String authorId,  String authorName,  MessageType type,  String text,  String? authorPhotoPath,  String? authorPlayerSummary,  String? replyToId,  Map<String, Reaction> reactions,  DateTime? deletedAt,  DateTime? createdAt,  bool pending)  $default,) {final _that = this;
switch (_that) {
case _Message():
return $default(_that.id,_that.groupId,_that.authorId,_that.authorName,_that.type,_that.text,_that.authorPhotoPath,_that.authorPlayerSummary,_that.replyToId,_that.reactions,_that.deletedAt,_that.createdAt,_that.pending);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  GroupId groupId,  String authorId,  String authorName,  MessageType type,  String text,  String? authorPhotoPath,  String? authorPlayerSummary,  String? replyToId,  Map<String, Reaction> reactions,  DateTime? deletedAt,  DateTime? createdAt,  bool pending)?  $default,) {final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that.id,_that.groupId,_that.authorId,_that.authorName,_that.type,_that.text,_that.authorPhotoPath,_that.authorPlayerSummary,_that.replyToId,_that.reactions,_that.deletedAt,_that.createdAt,_that.pending);case _:
  return null;

}
}

}

/// @nodoc


class _Message extends Message {
  const _Message({required this.id, required this.groupId, required this.authorId, required this.authorName, required this.type, this.text = '', this.authorPhotoPath, this.authorPlayerSummary, this.replyToId,  Map<String, Reaction> reactions = const <String, Reaction>{}, this.deletedAt, this.createdAt, this.pending = false}): _reactions = reactions,super._();
  

@override final  String id;
@override final  GroupId groupId;
@override final  String authorId;
@override final  String authorName;
@override final  MessageType type;
@override@JsonKey() final  String text;
@override final  String? authorPhotoPath;
/// "Emma #7, Liam #23" for a guardian on a youth team (PLAYER-8).
@override final  String? authorPlayerSummary;
@override final  String? replyToId;
 final  Map<String, Reaction> _reactions;
@override@JsonKey() Map<String, Reaction> get reactions {
  if (_reactions is EqualUnmodifiableMapView) return _reactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_reactions);
}

@override final  DateTime? deletedAt;
/// When the server stamped it. Null while a sent message is still local.
@override final  DateTime? createdAt;
/// True until the server has the message (CHAT-4 "sending").
@override@JsonKey() final  bool pending;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageCopyWith<_Message> get copyWith => __$MessageCopyWithImpl<_Message>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Message&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.type, type) || other.type == type)&&(identical(other.text, text) || other.text == text)&&(identical(other.authorPhotoPath, authorPhotoPath) || other.authorPhotoPath == authorPhotoPath)&&(identical(other.authorPlayerSummary, authorPlayerSummary) || other.authorPlayerSummary == authorPlayerSummary)&&(identical(other.replyToId, replyToId) || other.replyToId == replyToId)&&const DeepCollectionEquality().equals(other.reactions, _reactions)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.pending, pending) || other.pending == pending));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,groupId,authorId,authorName,type,text,authorPhotoPath,authorPlayerSummary,replyToId,const DeepCollectionEquality().hash(_reactions),deletedAt,createdAt,pending);
}

@override
String toString() {
    return 'Message(id: $id, groupId: $groupId, authorId: $authorId, authorName: $authorName, type: $type, text: $text, authorPhotoPath: $authorPhotoPath, authorPlayerSummary: $authorPlayerSummary, replyToId: $replyToId, reactions: $reactions, deletedAt: $deletedAt, createdAt: $createdAt, pending: $pending)';
}


}

/// @nodoc
abstract mixin class _$MessageCopyWith<$Res> implements $MessageCopyWith<$Res> {
  factory _$MessageCopyWith(_Message value, $Res Function(_Message) _then) = __$MessageCopyWithImpl;
@override @useResult
$Res call({
 String id, GroupId groupId, String authorId, String authorName, MessageType type, String text, String? authorPhotoPath, String? authorPlayerSummary, String? replyToId, Map<String, Reaction> reactions, DateTime? deletedAt, DateTime? createdAt, bool pending
});




}
/// @nodoc
class __$MessageCopyWithImpl<$Res>
    implements _$MessageCopyWith<$Res> {
  __$MessageCopyWithImpl(this._self, this._then);

  final _Message _self;
  final $Res Function(_Message) _then;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? groupId = null,Object? authorId = null,Object? authorName = null,Object? type = null,Object? text = null,Object? authorPhotoPath = freezed,Object? authorPlayerSummary = freezed,Object? replyToId = freezed,Object? reactions = null,Object? deletedAt = freezed,Object? createdAt = freezed,Object? pending = null,}) {
  return _then(_Message(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MessageType,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,authorPhotoPath: freezed == authorPhotoPath ? _self.authorPhotoPath : authorPhotoPath // ignore: cast_nullable_to_non_nullable
as String?,authorPlayerSummary: freezed == authorPlayerSummary ? _self.authorPlayerSummary : authorPlayerSummary // ignore: cast_nullable_to_non_nullable
as String?,replyToId: freezed == replyToId ? _self.replyToId : replyToId // ignore: cast_nullable_to_non_nullable
as String?,reactions: null == reactions ? _self._reactions : reactions // ignore: cast_nullable_to_non_nullable
as Map<String, Reaction>,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$MessagePage {

 List<Message> get messages; PageCursor? get next;
/// Create a copy of MessagePage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessagePageCopyWith<MessagePage> get copyWith => _$MessagePageCopyWithImpl<MessagePage>(this as MessagePage, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MessagePage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessagePage&&const DeepCollectionEquality().equals(other.messages, _this.messages)&&(identical(other.next, _this.next) || other.next == _this.next));
}


@override
int get hashCode {
  final _this = this as MessagePage;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.messages),_this.next);
}

@override
String toString() {
  final _this = this as MessagePage;
  return 'MessagePage(messages: ${_this.messages}, next: ${_this.next})';
}


}

/// @nodoc
abstract mixin class $MessagePageCopyWith<$Res>  {
  factory $MessagePageCopyWith(MessagePage value, $Res Function(MessagePage) _then) = _$MessagePageCopyWithImpl;
@useResult
$Res call({
 List<Message> messages, PageCursor? next
});




}
/// @nodoc
class _$MessagePageCopyWithImpl<$Res>
    implements $MessagePageCopyWith<$Res> {
  _$MessagePageCopyWithImpl(this._self, this._then);

  final MessagePage _self;
  final $Res Function(MessagePage) _then;

/// Create a copy of MessagePage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messages = null,Object? next = freezed,}) {
  return _then(MessagePage(
messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<Message>,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as PageCursor?,
  ));
}

}


/// Adds pattern-matching-related methods to [MessagePage].
extension MessagePagePatterns on MessagePage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessagePage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessagePage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessagePage value)  $default,){
final _that = this;
switch (_that) {
case _MessagePage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessagePage value)?  $default,){
final _that = this;
switch (_that) {
case _MessagePage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Message> messages,  PageCursor? next)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessagePage() when $default != null:
return $default(_that.messages,_that.next);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Message> messages,  PageCursor? next)  $default,) {final _that = this;
switch (_that) {
case _MessagePage():
return $default(_that.messages,_that.next);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Message> messages,  PageCursor? next)?  $default,) {final _that = this;
switch (_that) {
case _MessagePage() when $default != null:
return $default(_that.messages,_that.next);case _:
  return null;

}
}

}

/// @nodoc


class _MessagePage extends MessagePage {
  const _MessagePage({required  List<Message> messages, this.next}): _messages = messages,super._();
  

 final  List<Message> _messages;
@override List<Message> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}

@override final  PageCursor? next;

/// Create a copy of MessagePage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessagePageCopyWith<_MessagePage> get copyWith => __$MessagePageCopyWithImpl<_MessagePage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessagePage&&const DeepCollectionEquality().equals(other.messages, _messages)&&(identical(other.next, next) || other.next == next));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_messages),next);
}

@override
String toString() {
    return 'MessagePage(messages: $messages, next: $next)';
}


}

/// @nodoc
abstract mixin class _$MessagePageCopyWith<$Res> implements $MessagePageCopyWith<$Res> {
  factory _$MessagePageCopyWith(_MessagePage value, $Res Function(_MessagePage) _then) = __$MessagePageCopyWithImpl;
@override @useResult
$Res call({
 List<Message> messages, PageCursor? next
});




}
/// @nodoc
class __$MessagePageCopyWithImpl<$Res>
    implements _$MessagePageCopyWith<$Res> {
  __$MessagePageCopyWithImpl(this._self, this._then);

  final _MessagePage _self;
  final $Res Function(_MessagePage) _then;

/// Create a copy of MessagePage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messages = null,Object? next = freezed,}) {
  return _then(_MessagePage(
messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<Message>,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as PageCursor?,
  ));
}


}

// dart format on
