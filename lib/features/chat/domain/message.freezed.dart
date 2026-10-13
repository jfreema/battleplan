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
 String? get authorPlayerSummary; String? get replyToId;/// The poll a poll message shows; it has the message's ID (POLL-1).
 String? get pollId;/// The event an event card shows (CHAT-11, SCHED-3).
 String? get eventId;/// A repeating series' card: its series, so the card can show the next
/// event once [eventId] is gone (SCHED-3).
 String? get seriesId;/// The quote a reply shows, written by the server (CHAT-13, D25).
 ReplyPreview? get replyPreview;/// Photos, up to 10 (CHAT-3).
 List<Attachment> get attachments; Map<String, Reaction> get reactions; DateTime? get deletedAt;/// Set when the author edited the text (CHAT-15); shows "edited".
 DateTime? get editedAt;/// Who deleted it: the author ("This message was deleted") or an admin
/// ("Removed by a team admin") (CHAT-8).
 String? get deletedReason;/// When the server stamped it. Null while a sent message is still local.
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Message&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.authorId, _this.authorId) || other.authorId == _this.authorId)&&(identical(other.authorName, _this.authorName) || other.authorName == _this.authorName)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.authorPhotoPath, _this.authorPhotoPath) || other.authorPhotoPath == _this.authorPhotoPath)&&(identical(other.authorPlayerSummary, _this.authorPlayerSummary) || other.authorPlayerSummary == _this.authorPlayerSummary)&&(identical(other.replyToId, _this.replyToId) || other.replyToId == _this.replyToId)&&(identical(other.pollId, _this.pollId) || other.pollId == _this.pollId)&&(identical(other.eventId, _this.eventId) || other.eventId == _this.eventId)&&(identical(other.seriesId, _this.seriesId) || other.seriesId == _this.seriesId)&&(identical(other.replyPreview, _this.replyPreview) || other.replyPreview == _this.replyPreview)&&const DeepCollectionEquality().equals(other.attachments, _this.attachments)&&const DeepCollectionEquality().equals(other.reactions, _this.reactions)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt)&&(identical(other.editedAt, _this.editedAt) || other.editedAt == _this.editedAt)&&(identical(other.deletedReason, _this.deletedReason) || other.deletedReason == _this.deletedReason)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.pending, _this.pending) || other.pending == _this.pending));
}


@override
int get hashCode {
  final _this = this as Message;
  return Object.hashAll([runtimeType,_this.id,_this.groupId,_this.authorId,_this.authorName,_this.type,_this.text,_this.authorPhotoPath,_this.authorPlayerSummary,_this.replyToId,_this.pollId,_this.eventId,_this.seriesId,_this.replyPreview,const DeepCollectionEquality().hash(_this.attachments),const DeepCollectionEquality().hash(_this.reactions),_this.deletedAt,_this.editedAt,_this.deletedReason,_this.createdAt,_this.pending]);
}

@override
String toString() {
  final _this = this as Message;
  return 'Message(id: ${_this.id}, groupId: ${_this.groupId}, authorId: ${_this.authorId}, authorName: ${_this.authorName}, type: ${_this.type}, text: ${_this.text}, authorPhotoPath: ${_this.authorPhotoPath}, authorPlayerSummary: ${_this.authorPlayerSummary}, replyToId: ${_this.replyToId}, pollId: ${_this.pollId}, eventId: ${_this.eventId}, seriesId: ${_this.seriesId}, replyPreview: ${_this.replyPreview}, attachments: ${_this.attachments}, reactions: ${_this.reactions}, deletedAt: ${_this.deletedAt}, editedAt: ${_this.editedAt}, deletedReason: ${_this.deletedReason}, createdAt: ${_this.createdAt}, pending: ${_this.pending})';
}


}

/// @nodoc
abstract mixin class $MessageCopyWith<$Res>  {
  factory $MessageCopyWith(Message value, $Res Function(Message) _then) = _$MessageCopyWithImpl;
@useResult
$Res call({
 String id, GroupId groupId, String authorId, String authorName, MessageType type, String text, String? authorPhotoPath, String? authorPlayerSummary, String? replyToId, String? pollId, String? eventId, String? seriesId, ReplyPreview? replyPreview, List<Attachment> attachments, Map<String, Reaction> reactions, DateTime? deletedAt, DateTime? editedAt, String? deletedReason, DateTime? createdAt, bool pending
});


$ReplyPreviewCopyWith<$Res>? get replyPreview;

}
/// @nodoc
class _$MessageCopyWithImpl<$Res>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._self, this._then);

  final Message _self;
  final $Res Function(Message) _then;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? groupId = null,Object? authorId = null,Object? authorName = null,Object? type = null,Object? text = null,Object? authorPhotoPath = freezed,Object? authorPlayerSummary = freezed,Object? replyToId = freezed,Object? pollId = freezed,Object? eventId = freezed,Object? seriesId = freezed,Object? replyPreview = freezed,Object? attachments = null,Object? reactions = null,Object? deletedAt = freezed,Object? editedAt = freezed,Object? deletedReason = freezed,Object? createdAt = freezed,Object? pending = null,}) {
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
as String?,pollId: freezed == pollId ? _self.pollId : pollId // ignore: cast_nullable_to_non_nullable
as String?,eventId: freezed == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String?,seriesId: freezed == seriesId ? _self.seriesId : seriesId // ignore: cast_nullable_to_non_nullable
as String?,replyPreview: freezed == replyPreview ? _self.replyPreview : replyPreview // ignore: cast_nullable_to_non_nullable
as ReplyPreview?,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<Attachment>,reactions: null == reactions ? _self.reactions : reactions // ignore: cast_nullable_to_non_nullable
as Map<String, Reaction>,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedReason: freezed == deletedReason ? _self.deletedReason : deletedReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReplyPreviewCopyWith<$Res>? get replyPreview {
    if (_self.replyPreview == null) {
    return null;
  }

  return $ReplyPreviewCopyWith<$Res>(_self.replyPreview!, (value) {
    return _then(_self.copyWith(replyPreview: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  GroupId groupId,  String authorId,  String authorName,  MessageType type,  String text,  String? authorPhotoPath,  String? authorPlayerSummary,  String? replyToId,  String? pollId,  String? eventId,  String? seriesId,  ReplyPreview? replyPreview,  List<Attachment> attachments,  Map<String, Reaction> reactions,  DateTime? deletedAt,  DateTime? editedAt,  String? deletedReason,  DateTime? createdAt,  bool pending)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that.id,_that.groupId,_that.authorId,_that.authorName,_that.type,_that.text,_that.authorPhotoPath,_that.authorPlayerSummary,_that.replyToId,_that.pollId,_that.eventId,_that.seriesId,_that.replyPreview,_that.attachments,_that.reactions,_that.deletedAt,_that.editedAt,_that.deletedReason,_that.createdAt,_that.pending);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  GroupId groupId,  String authorId,  String authorName,  MessageType type,  String text,  String? authorPhotoPath,  String? authorPlayerSummary,  String? replyToId,  String? pollId,  String? eventId,  String? seriesId,  ReplyPreview? replyPreview,  List<Attachment> attachments,  Map<String, Reaction> reactions,  DateTime? deletedAt,  DateTime? editedAt,  String? deletedReason,  DateTime? createdAt,  bool pending)  $default,) {final _that = this;
switch (_that) {
case _Message():
return $default(_that.id,_that.groupId,_that.authorId,_that.authorName,_that.type,_that.text,_that.authorPhotoPath,_that.authorPlayerSummary,_that.replyToId,_that.pollId,_that.eventId,_that.seriesId,_that.replyPreview,_that.attachments,_that.reactions,_that.deletedAt,_that.editedAt,_that.deletedReason,_that.createdAt,_that.pending);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  GroupId groupId,  String authorId,  String authorName,  MessageType type,  String text,  String? authorPhotoPath,  String? authorPlayerSummary,  String? replyToId,  String? pollId,  String? eventId,  String? seriesId,  ReplyPreview? replyPreview,  List<Attachment> attachments,  Map<String, Reaction> reactions,  DateTime? deletedAt,  DateTime? editedAt,  String? deletedReason,  DateTime? createdAt,  bool pending)?  $default,) {final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that.id,_that.groupId,_that.authorId,_that.authorName,_that.type,_that.text,_that.authorPhotoPath,_that.authorPlayerSummary,_that.replyToId,_that.pollId,_that.eventId,_that.seriesId,_that.replyPreview,_that.attachments,_that.reactions,_that.deletedAt,_that.editedAt,_that.deletedReason,_that.createdAt,_that.pending);case _:
  return null;

}
}

}

/// @nodoc


class _Message extends Message {
  const _Message({required this.id, required this.groupId, required this.authorId, required this.authorName, required this.type, this.text = '', this.authorPhotoPath, this.authorPlayerSummary, this.replyToId, this.pollId, this.eventId, this.seriesId, this.replyPreview,  List<Attachment> attachments = const <Attachment>[],  Map<String, Reaction> reactions = const <String, Reaction>{}, this.deletedAt, this.editedAt, this.deletedReason, this.createdAt, this.pending = false}): _attachments = attachments,_reactions = reactions,super._();
  

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
/// The poll a poll message shows; it has the message's ID (POLL-1).
@override final  String? pollId;
/// The event an event card shows (CHAT-11, SCHED-3).
@override final  String? eventId;
/// A repeating series' card: its series, so the card can show the next
/// event once [eventId] is gone (SCHED-3).
@override final  String? seriesId;
/// The quote a reply shows, written by the server (CHAT-13, D25).
@override final  ReplyPreview? replyPreview;
/// Photos, up to 10 (CHAT-3).
 final  List<Attachment> _attachments;
/// Photos, up to 10 (CHAT-3).
@override@JsonKey() List<Attachment> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}

 final  Map<String, Reaction> _reactions;
@override@JsonKey() Map<String, Reaction> get reactions {
  if (_reactions is EqualUnmodifiableMapView) return _reactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_reactions);
}

@override final  DateTime? deletedAt;
/// Set when the author edited the text (CHAT-15); shows "edited".
@override final  DateTime? editedAt;
/// Who deleted it: the author ("This message was deleted") or an admin
/// ("Removed by a team admin") (CHAT-8).
@override final  String? deletedReason;
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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Message&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.type, type) || other.type == type)&&(identical(other.text, text) || other.text == text)&&(identical(other.authorPhotoPath, authorPhotoPath) || other.authorPhotoPath == authorPhotoPath)&&(identical(other.authorPlayerSummary, authorPlayerSummary) || other.authorPlayerSummary == authorPlayerSummary)&&(identical(other.replyToId, replyToId) || other.replyToId == replyToId)&&(identical(other.pollId, pollId) || other.pollId == pollId)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.seriesId, seriesId) || other.seriesId == seriesId)&&(identical(other.replyPreview, replyPreview) || other.replyPreview == replyPreview)&&const DeepCollectionEquality().equals(other.attachments, _attachments)&&const DeepCollectionEquality().equals(other.reactions, _reactions)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.deletedReason, deletedReason) || other.deletedReason == deletedReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.pending, pending) || other.pending == pending));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,id,groupId,authorId,authorName,type,text,authorPhotoPath,authorPlayerSummary,replyToId,pollId,eventId,seriesId,replyPreview,const DeepCollectionEquality().hash(_attachments),const DeepCollectionEquality().hash(_reactions),deletedAt,editedAt,deletedReason,createdAt,pending]);
}

@override
String toString() {
    return 'Message(id: $id, groupId: $groupId, authorId: $authorId, authorName: $authorName, type: $type, text: $text, authorPhotoPath: $authorPhotoPath, authorPlayerSummary: $authorPlayerSummary, replyToId: $replyToId, pollId: $pollId, eventId: $eventId, seriesId: $seriesId, replyPreview: $replyPreview, attachments: $attachments, reactions: $reactions, deletedAt: $deletedAt, editedAt: $editedAt, deletedReason: $deletedReason, createdAt: $createdAt, pending: $pending)';
}


}

/// @nodoc
abstract mixin class _$MessageCopyWith<$Res> implements $MessageCopyWith<$Res> {
  factory _$MessageCopyWith(_Message value, $Res Function(_Message) _then) = __$MessageCopyWithImpl;
@override @useResult
$Res call({
 String id, GroupId groupId, String authorId, String authorName, MessageType type, String text, String? authorPhotoPath, String? authorPlayerSummary, String? replyToId, String? pollId, String? eventId, String? seriesId, ReplyPreview? replyPreview, List<Attachment> attachments, Map<String, Reaction> reactions, DateTime? deletedAt, DateTime? editedAt, String? deletedReason, DateTime? createdAt, bool pending
});


@override $ReplyPreviewCopyWith<$Res>? get replyPreview;

}
/// @nodoc
class __$MessageCopyWithImpl<$Res>
    implements _$MessageCopyWith<$Res> {
  __$MessageCopyWithImpl(this._self, this._then);

  final _Message _self;
  final $Res Function(_Message) _then;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? groupId = null,Object? authorId = null,Object? authorName = null,Object? type = null,Object? text = null,Object? authorPhotoPath = freezed,Object? authorPlayerSummary = freezed,Object? replyToId = freezed,Object? pollId = freezed,Object? eventId = freezed,Object? seriesId = freezed,Object? replyPreview = freezed,Object? attachments = null,Object? reactions = null,Object? deletedAt = freezed,Object? editedAt = freezed,Object? deletedReason = freezed,Object? createdAt = freezed,Object? pending = null,}) {
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
as String?,pollId: freezed == pollId ? _self.pollId : pollId // ignore: cast_nullable_to_non_nullable
as String?,eventId: freezed == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String?,seriesId: freezed == seriesId ? _self.seriesId : seriesId // ignore: cast_nullable_to_non_nullable
as String?,replyPreview: freezed == replyPreview ? _self.replyPreview : replyPreview // ignore: cast_nullable_to_non_nullable
as ReplyPreview?,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<Attachment>,reactions: null == reactions ? _self._reactions : reactions // ignore: cast_nullable_to_non_nullable
as Map<String, Reaction>,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedReason: freezed == deletedReason ? _self.deletedReason : deletedReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReplyPreviewCopyWith<$Res>? get replyPreview {
    if (_self.replyPreview == null) {
    return null;
  }

  return $ReplyPreviewCopyWith<$Res>(_self.replyPreview!, (value) {
    return _then(_self.copyWith(replyPreview: value));
  });
}
}

/// @nodoc
mixin _$MessagePage {

 List<Message> get messages;/// Continues the paging: older messages for the newest page and older
/// pages, newer ones for a newer page. Null at the chat's start or end.
 PageCursor? get next;/// For a newer page: continues older, before its oldest message.
 PageCursor? get older;/// True when the page came from the offline cache rather than the
/// server: the device is offline, or hasn't heard back yet (CHAT-4).
 bool get fromCache;
/// Create a copy of MessagePage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessagePageCopyWith<MessagePage> get copyWith => _$MessagePageCopyWithImpl<MessagePage>(this as MessagePage, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MessagePage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessagePage&&const DeepCollectionEquality().equals(other.messages, _this.messages)&&(identical(other.next, _this.next) || other.next == _this.next)&&(identical(other.older, _this.older) || other.older == _this.older)&&(identical(other.fromCache, _this.fromCache) || other.fromCache == _this.fromCache));
}


@override
int get hashCode {
  final _this = this as MessagePage;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.messages),_this.next,_this.older,_this.fromCache);
}

@override
String toString() {
  final _this = this as MessagePage;
  return 'MessagePage(messages: ${_this.messages}, next: ${_this.next}, older: ${_this.older}, fromCache: ${_this.fromCache})';
}


}

/// @nodoc
abstract mixin class $MessagePageCopyWith<$Res>  {
  factory $MessagePageCopyWith(MessagePage value, $Res Function(MessagePage) _then) = _$MessagePageCopyWithImpl;
@useResult
$Res call({
 List<Message> messages, PageCursor? next, PageCursor? older, bool fromCache
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
@pragma('vm:prefer-inline') @override $Res call({Object? messages = null,Object? next = freezed,Object? older = freezed,Object? fromCache = null,}) {
  return _then(MessagePage(
messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<Message>,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as PageCursor?,older: freezed == older ? _self.older : older // ignore: cast_nullable_to_non_nullable
as PageCursor?,fromCache: null == fromCache ? _self.fromCache : fromCache // ignore: cast_nullable_to_non_nullable
as bool,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Message> messages,  PageCursor? next,  PageCursor? older,  bool fromCache)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessagePage() when $default != null:
return $default(_that.messages,_that.next,_that.older,_that.fromCache);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Message> messages,  PageCursor? next,  PageCursor? older,  bool fromCache)  $default,) {final _that = this;
switch (_that) {
case _MessagePage():
return $default(_that.messages,_that.next,_that.older,_that.fromCache);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Message> messages,  PageCursor? next,  PageCursor? older,  bool fromCache)?  $default,) {final _that = this;
switch (_that) {
case _MessagePage() when $default != null:
return $default(_that.messages,_that.next,_that.older,_that.fromCache);case _:
  return null;

}
}

}

/// @nodoc


class _MessagePage extends MessagePage {
  const _MessagePage({required  List<Message> messages, this.next, this.older, this.fromCache = false}): _messages = messages,super._();
  

 final  List<Message> _messages;
@override List<Message> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}

/// Continues the paging: older messages for the newest page and older
/// pages, newer ones for a newer page. Null at the chat's start or end.
@override final  PageCursor? next;
/// For a newer page: continues older, before its oldest message.
@override final  PageCursor? older;
/// True when the page came from the offline cache rather than the
/// server: the device is offline, or hasn't heard back yet (CHAT-4).
@override@JsonKey() final  bool fromCache;

/// Create a copy of MessagePage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessagePageCopyWith<_MessagePage> get copyWith => __$MessagePageCopyWithImpl<_MessagePage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessagePage&&const DeepCollectionEquality().equals(other.messages, _messages)&&(identical(other.next, next) || other.next == next)&&(identical(other.older, older) || other.older == older)&&(identical(other.fromCache, fromCache) || other.fromCache == fromCache));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_messages),next,older,fromCache);
}

@override
String toString() {
    return 'MessagePage(messages: $messages, next: $next, older: $older, fromCache: $fromCache)';
}


}

/// @nodoc
abstract mixin class _$MessagePageCopyWith<$Res> implements $MessagePageCopyWith<$Res> {
  factory _$MessagePageCopyWith(_MessagePage value, $Res Function(_MessagePage) _then) = __$MessagePageCopyWithImpl;
@override @useResult
$Res call({
 List<Message> messages, PageCursor? next, PageCursor? older, bool fromCache
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
@override @pragma('vm:prefer-inline') $Res call({Object? messages = null,Object? next = freezed,Object? older = freezed,Object? fromCache = null,}) {
  return _then(_MessagePage(
messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<Message>,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as PageCursor?,older: freezed == older ? _self.older : older // ignore: cast_nullable_to_non_nullable
as PageCursor?,fromCache: null == fromCache ? _self.fromCache : fromCache // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$Attachment {

 String get path; String get contentType; int get width; int get height; int get size;
/// Create a copy of Attachment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttachmentCopyWith<Attachment> get copyWith => _$AttachmentCopyWithImpl<Attachment>(this as Attachment, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Attachment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Attachment&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.contentType, _this.contentType) || other.contentType == _this.contentType)&&(identical(other.width, _this.width) || other.width == _this.width)&&(identical(other.height, _this.height) || other.height == _this.height)&&(identical(other.size, _this.size) || other.size == _this.size));
}


@override
int get hashCode {
  final _this = this as Attachment;
  return Object.hash(runtimeType,_this.path,_this.contentType,_this.width,_this.height,_this.size);
}

@override
String toString() {
  final _this = this as Attachment;
  return 'Attachment(path: ${_this.path}, contentType: ${_this.contentType}, width: ${_this.width}, height: ${_this.height}, size: ${_this.size})';
}


}

/// @nodoc
abstract mixin class $AttachmentCopyWith<$Res>  {
  factory $AttachmentCopyWith(Attachment value, $Res Function(Attachment) _then) = _$AttachmentCopyWithImpl;
@useResult
$Res call({
 String path, String contentType, int width, int height, int size
});




}
/// @nodoc
class _$AttachmentCopyWithImpl<$Res>
    implements $AttachmentCopyWith<$Res> {
  _$AttachmentCopyWithImpl(this._self, this._then);

  final Attachment _self;
  final $Res Function(Attachment) _then;

/// Create a copy of Attachment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? contentType = null,Object? width = null,Object? height = null,Object? size = null,}) {
  return _then(Attachment(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Attachment].
extension AttachmentPatterns on Attachment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Attachment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Attachment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Attachment value)  $default,){
final _that = this;
switch (_that) {
case _Attachment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Attachment value)?  $default,){
final _that = this;
switch (_that) {
case _Attachment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String contentType,  int width,  int height,  int size)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Attachment() when $default != null:
return $default(_that.path,_that.contentType,_that.width,_that.height,_that.size);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String contentType,  int width,  int height,  int size)  $default,) {final _that = this;
switch (_that) {
case _Attachment():
return $default(_that.path,_that.contentType,_that.width,_that.height,_that.size);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String contentType,  int width,  int height,  int size)?  $default,) {final _that = this;
switch (_that) {
case _Attachment() when $default != null:
return $default(_that.path,_that.contentType,_that.width,_that.height,_that.size);case _:
  return null;

}
}

}

/// @nodoc


class _Attachment extends Attachment {
  const _Attachment({required this.path, this.contentType = 'image/jpeg', this.width = 0, this.height = 0, this.size = 0}): super._();
  

@override final  String path;
@override@JsonKey() final  String contentType;
@override@JsonKey() final  int width;
@override@JsonKey() final  int height;
@override@JsonKey() final  int size;

/// Create a copy of Attachment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttachmentCopyWith<_Attachment> get copyWith => __$AttachmentCopyWithImpl<_Attachment>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Attachment&&(identical(other.path, path) || other.path == path)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.size, size) || other.size == size));
}


@override
int get hashCode {
    return Object.hash(runtimeType,path,contentType,width,height,size);
}

@override
String toString() {
    return 'Attachment(path: $path, contentType: $contentType, width: $width, height: $height, size: $size)';
}


}

/// @nodoc
abstract mixin class _$AttachmentCopyWith<$Res> implements $AttachmentCopyWith<$Res> {
  factory _$AttachmentCopyWith(_Attachment value, $Res Function(_Attachment) _then) = __$AttachmentCopyWithImpl;
@override @useResult
$Res call({
 String path, String contentType, int width, int height, int size
});




}
/// @nodoc
class __$AttachmentCopyWithImpl<$Res>
    implements _$AttachmentCopyWith<$Res> {
  __$AttachmentCopyWithImpl(this._self, this._then);

  final _Attachment _self;
  final $Res Function(_Attachment) _then;

/// Create a copy of Attachment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? contentType = null,Object? width = null,Object? height = null,Object? size = null,}) {
  return _then(_Attachment(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$ReplyPreview {

 String get authorName; String get text; MessageType get type; bool get deleted;
/// Create a copy of ReplyPreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReplyPreviewCopyWith<ReplyPreview> get copyWith => _$ReplyPreviewCopyWithImpl<ReplyPreview>(this as ReplyPreview, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ReplyPreview;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReplyPreview&&(identical(other.authorName, _this.authorName) || other.authorName == _this.authorName)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.deleted, _this.deleted) || other.deleted == _this.deleted));
}


@override
int get hashCode {
  final _this = this as ReplyPreview;
  return Object.hash(runtimeType,_this.authorName,_this.text,_this.type,_this.deleted);
}

@override
String toString() {
  final _this = this as ReplyPreview;
  return 'ReplyPreview(authorName: ${_this.authorName}, text: ${_this.text}, type: ${_this.type}, deleted: ${_this.deleted})';
}


}

/// @nodoc
abstract mixin class $ReplyPreviewCopyWith<$Res>  {
  factory $ReplyPreviewCopyWith(ReplyPreview value, $Res Function(ReplyPreview) _then) = _$ReplyPreviewCopyWithImpl;
@useResult
$Res call({
 String authorName, String text, MessageType type, bool deleted
});




}
/// @nodoc
class _$ReplyPreviewCopyWithImpl<$Res>
    implements $ReplyPreviewCopyWith<$Res> {
  _$ReplyPreviewCopyWithImpl(this._self, this._then);

  final ReplyPreview _self;
  final $Res Function(ReplyPreview) _then;

/// Create a copy of ReplyPreview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? authorName = null,Object? text = null,Object? type = null,Object? deleted = null,}) {
  return _then(ReplyPreview(
authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MessageType,deleted: null == deleted ? _self.deleted : deleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ReplyPreview].
extension ReplyPreviewPatterns on ReplyPreview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReplyPreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReplyPreview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReplyPreview value)  $default,){
final _that = this;
switch (_that) {
case _ReplyPreview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReplyPreview value)?  $default,){
final _that = this;
switch (_that) {
case _ReplyPreview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String authorName,  String text,  MessageType type,  bool deleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReplyPreview() when $default != null:
return $default(_that.authorName,_that.text,_that.type,_that.deleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String authorName,  String text,  MessageType type,  bool deleted)  $default,) {final _that = this;
switch (_that) {
case _ReplyPreview():
return $default(_that.authorName,_that.text,_that.type,_that.deleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String authorName,  String text,  MessageType type,  bool deleted)?  $default,) {final _that = this;
switch (_that) {
case _ReplyPreview() when $default != null:
return $default(_that.authorName,_that.text,_that.type,_that.deleted);case _:
  return null;

}
}

}

/// @nodoc


class _ReplyPreview implements ReplyPreview {
  const _ReplyPreview({required this.authorName, required this.text, this.type = MessageType.text, this.deleted = false});
  

@override final  String authorName;
@override final  String text;
@override@JsonKey() final  MessageType type;
@override@JsonKey() final  bool deleted;

/// Create a copy of ReplyPreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReplyPreviewCopyWith<_ReplyPreview> get copyWith => __$ReplyPreviewCopyWithImpl<_ReplyPreview>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReplyPreview&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.text, text) || other.text == text)&&(identical(other.type, type) || other.type == type)&&(identical(other.deleted, deleted) || other.deleted == deleted));
}


@override
int get hashCode {
    return Object.hash(runtimeType,authorName,text,type,deleted);
}

@override
String toString() {
    return 'ReplyPreview(authorName: $authorName, text: $text, type: $type, deleted: $deleted)';
}


}

/// @nodoc
abstract mixin class _$ReplyPreviewCopyWith<$Res> implements $ReplyPreviewCopyWith<$Res> {
  factory _$ReplyPreviewCopyWith(_ReplyPreview value, $Res Function(_ReplyPreview) _then) = __$ReplyPreviewCopyWithImpl;
@override @useResult
$Res call({
 String authorName, String text, MessageType type, bool deleted
});




}
/// @nodoc
class __$ReplyPreviewCopyWithImpl<$Res>
    implements _$ReplyPreviewCopyWith<$Res> {
  __$ReplyPreviewCopyWithImpl(this._self, this._then);

  final _ReplyPreview _self;
  final $Res Function(_ReplyPreview) _then;

/// Create a copy of ReplyPreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? authorName = null,Object? text = null,Object? type = null,Object? deleted = null,}) {
  return _then(_ReplyPreview(
authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MessageType,deleted: null == deleted ? _self.deleted : deleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
