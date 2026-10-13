// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GroupSettings {

 bool get membersCanCreateEvents; bool get membersCanCreatePolls; bool get membersCanUploadDocs; bool get membersCanInvite; bool get allowMaybe;/// Minutes before an event (1440 = 1 day).
 List<int> get defaultReminderOffsets;
/// Create a copy of GroupSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupSettingsCopyWith<GroupSettings> get copyWith => _$GroupSettingsCopyWithImpl<GroupSettings>(this as GroupSettings, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GroupSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupSettings&&(identical(other.membersCanCreateEvents, _this.membersCanCreateEvents) || other.membersCanCreateEvents == _this.membersCanCreateEvents)&&(identical(other.membersCanCreatePolls, _this.membersCanCreatePolls) || other.membersCanCreatePolls == _this.membersCanCreatePolls)&&(identical(other.membersCanUploadDocs, _this.membersCanUploadDocs) || other.membersCanUploadDocs == _this.membersCanUploadDocs)&&(identical(other.membersCanInvite, _this.membersCanInvite) || other.membersCanInvite == _this.membersCanInvite)&&(identical(other.allowMaybe, _this.allowMaybe) || other.allowMaybe == _this.allowMaybe)&&const DeepCollectionEquality().equals(other.defaultReminderOffsets, _this.defaultReminderOffsets));
}


@override
int get hashCode {
  final _this = this as GroupSettings;
  return Object.hash(runtimeType,_this.membersCanCreateEvents,_this.membersCanCreatePolls,_this.membersCanUploadDocs,_this.membersCanInvite,_this.allowMaybe,const DeepCollectionEquality().hash(_this.defaultReminderOffsets));
}

@override
String toString() {
  final _this = this as GroupSettings;
  return 'GroupSettings(membersCanCreateEvents: ${_this.membersCanCreateEvents}, membersCanCreatePolls: ${_this.membersCanCreatePolls}, membersCanUploadDocs: ${_this.membersCanUploadDocs}, membersCanInvite: ${_this.membersCanInvite}, allowMaybe: ${_this.allowMaybe}, defaultReminderOffsets: ${_this.defaultReminderOffsets})';
}


}

/// @nodoc
abstract mixin class $GroupSettingsCopyWith<$Res>  {
  factory $GroupSettingsCopyWith(GroupSettings value, $Res Function(GroupSettings) _then) = _$GroupSettingsCopyWithImpl;
@useResult
$Res call({
 bool membersCanCreateEvents, bool membersCanCreatePolls, bool membersCanUploadDocs, bool membersCanInvite, bool allowMaybe, List<int> defaultReminderOffsets
});




}
/// @nodoc
class _$GroupSettingsCopyWithImpl<$Res>
    implements $GroupSettingsCopyWith<$Res> {
  _$GroupSettingsCopyWithImpl(this._self, this._then);

  final GroupSettings _self;
  final $Res Function(GroupSettings) _then;

/// Create a copy of GroupSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? membersCanCreateEvents = null,Object? membersCanCreatePolls = null,Object? membersCanUploadDocs = null,Object? membersCanInvite = null,Object? allowMaybe = null,Object? defaultReminderOffsets = null,}) {
  return _then(GroupSettings(
membersCanCreateEvents: null == membersCanCreateEvents ? _self.membersCanCreateEvents : membersCanCreateEvents // ignore: cast_nullable_to_non_nullable
as bool,membersCanCreatePolls: null == membersCanCreatePolls ? _self.membersCanCreatePolls : membersCanCreatePolls // ignore: cast_nullable_to_non_nullable
as bool,membersCanUploadDocs: null == membersCanUploadDocs ? _self.membersCanUploadDocs : membersCanUploadDocs // ignore: cast_nullable_to_non_nullable
as bool,membersCanInvite: null == membersCanInvite ? _self.membersCanInvite : membersCanInvite // ignore: cast_nullable_to_non_nullable
as bool,allowMaybe: null == allowMaybe ? _self.allowMaybe : allowMaybe // ignore: cast_nullable_to_non_nullable
as bool,defaultReminderOffsets: null == defaultReminderOffsets ? _self.defaultReminderOffsets : defaultReminderOffsets // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupSettings].
extension GroupSettingsPatterns on GroupSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupSettings value)  $default,){
final _that = this;
switch (_that) {
case _GroupSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupSettings value)?  $default,){
final _that = this;
switch (_that) {
case _GroupSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool membersCanCreateEvents,  bool membersCanCreatePolls,  bool membersCanUploadDocs,  bool membersCanInvite,  bool allowMaybe,  List<int> defaultReminderOffsets)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupSettings() when $default != null:
return $default(_that.membersCanCreateEvents,_that.membersCanCreatePolls,_that.membersCanUploadDocs,_that.membersCanInvite,_that.allowMaybe,_that.defaultReminderOffsets);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool membersCanCreateEvents,  bool membersCanCreatePolls,  bool membersCanUploadDocs,  bool membersCanInvite,  bool allowMaybe,  List<int> defaultReminderOffsets)  $default,) {final _that = this;
switch (_that) {
case _GroupSettings():
return $default(_that.membersCanCreateEvents,_that.membersCanCreatePolls,_that.membersCanUploadDocs,_that.membersCanInvite,_that.allowMaybe,_that.defaultReminderOffsets);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool membersCanCreateEvents,  bool membersCanCreatePolls,  bool membersCanUploadDocs,  bool membersCanInvite,  bool allowMaybe,  List<int> defaultReminderOffsets)?  $default,) {final _that = this;
switch (_that) {
case _GroupSettings() when $default != null:
return $default(_that.membersCanCreateEvents,_that.membersCanCreatePolls,_that.membersCanUploadDocs,_that.membersCanInvite,_that.allowMaybe,_that.defaultReminderOffsets);case _:
  return null;

}
}

}

/// @nodoc


class _GroupSettings implements GroupSettings {
  const _GroupSettings({this.membersCanCreateEvents = false, this.membersCanCreatePolls = true, this.membersCanUploadDocs = true, this.membersCanInvite = true, this.allowMaybe = true,  List<int> defaultReminderOffsets = const <int>[1440]}): _defaultReminderOffsets = defaultReminderOffsets;
  

@override@JsonKey() final  bool membersCanCreateEvents;
@override@JsonKey() final  bool membersCanCreatePolls;
@override@JsonKey() final  bool membersCanUploadDocs;
@override@JsonKey() final  bool membersCanInvite;
@override@JsonKey() final  bool allowMaybe;
/// Minutes before an event (1440 = 1 day).
 final  List<int> _defaultReminderOffsets;
/// Minutes before an event (1440 = 1 day).
@override@JsonKey() List<int> get defaultReminderOffsets {
  if (_defaultReminderOffsets is EqualUnmodifiableListView) return _defaultReminderOffsets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_defaultReminderOffsets);
}


/// Create a copy of GroupSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupSettingsCopyWith<_GroupSettings> get copyWith => __$GroupSettingsCopyWithImpl<_GroupSettings>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupSettings&&(identical(other.membersCanCreateEvents, membersCanCreateEvents) || other.membersCanCreateEvents == membersCanCreateEvents)&&(identical(other.membersCanCreatePolls, membersCanCreatePolls) || other.membersCanCreatePolls == membersCanCreatePolls)&&(identical(other.membersCanUploadDocs, membersCanUploadDocs) || other.membersCanUploadDocs == membersCanUploadDocs)&&(identical(other.membersCanInvite, membersCanInvite) || other.membersCanInvite == membersCanInvite)&&(identical(other.allowMaybe, allowMaybe) || other.allowMaybe == allowMaybe)&&const DeepCollectionEquality().equals(other.defaultReminderOffsets, _defaultReminderOffsets));
}


@override
int get hashCode {
    return Object.hash(runtimeType,membersCanCreateEvents,membersCanCreatePolls,membersCanUploadDocs,membersCanInvite,allowMaybe,const DeepCollectionEquality().hash(_defaultReminderOffsets));
}

@override
String toString() {
    return 'GroupSettings(membersCanCreateEvents: $membersCanCreateEvents, membersCanCreatePolls: $membersCanCreatePolls, membersCanUploadDocs: $membersCanUploadDocs, membersCanInvite: $membersCanInvite, allowMaybe: $allowMaybe, defaultReminderOffsets: $defaultReminderOffsets)';
}


}

/// @nodoc
abstract mixin class _$GroupSettingsCopyWith<$Res> implements $GroupSettingsCopyWith<$Res> {
  factory _$GroupSettingsCopyWith(_GroupSettings value, $Res Function(_GroupSettings) _then) = __$GroupSettingsCopyWithImpl;
@override @useResult
$Res call({
 bool membersCanCreateEvents, bool membersCanCreatePolls, bool membersCanUploadDocs, bool membersCanInvite, bool allowMaybe, List<int> defaultReminderOffsets
});




}
/// @nodoc
class __$GroupSettingsCopyWithImpl<$Res>
    implements _$GroupSettingsCopyWith<$Res> {
  __$GroupSettingsCopyWithImpl(this._self, this._then);

  final _GroupSettings _self;
  final $Res Function(_GroupSettings) _then;

/// Create a copy of GroupSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? membersCanCreateEvents = null,Object? membersCanCreatePolls = null,Object? membersCanUploadDocs = null,Object? membersCanInvite = null,Object? allowMaybe = null,Object? defaultReminderOffsets = null,}) {
  return _then(_GroupSettings(
membersCanCreateEvents: null == membersCanCreateEvents ? _self.membersCanCreateEvents : membersCanCreateEvents // ignore: cast_nullable_to_non_nullable
as bool,membersCanCreatePolls: null == membersCanCreatePolls ? _self.membersCanCreatePolls : membersCanCreatePolls // ignore: cast_nullable_to_non_nullable
as bool,membersCanUploadDocs: null == membersCanUploadDocs ? _self.membersCanUploadDocs : membersCanUploadDocs // ignore: cast_nullable_to_non_nullable
as bool,membersCanInvite: null == membersCanInvite ? _self.membersCanInvite : membersCanInvite // ignore: cast_nullable_to_non_nullable
as bool,allowMaybe: null == allowMaybe ? _self.allowMaybe : allowMaybe // ignore: cast_nullable_to_non_nullable
as bool,defaultReminderOffsets: null == defaultReminderOffsets ? _self._defaultReminderOffsets : defaultReminderOffsets // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

/// @nodoc
mixin _$ChatTheme {

/// ARGB from the team palette; null uses the team's own color.
 int? get bubbleColor; ChatBackground get background; String? get backgroundPath;
/// Create a copy of ChatTheme
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatThemeCopyWith<ChatTheme> get copyWith => _$ChatThemeCopyWithImpl<ChatTheme>(this as ChatTheme, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ChatTheme;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatTheme&&(identical(other.bubbleColor, _this.bubbleColor) || other.bubbleColor == _this.bubbleColor)&&(identical(other.background, _this.background) || other.background == _this.background)&&(identical(other.backgroundPath, _this.backgroundPath) || other.backgroundPath == _this.backgroundPath));
}


@override
int get hashCode {
  final _this = this as ChatTheme;
  return Object.hash(runtimeType,_this.bubbleColor,_this.background,_this.backgroundPath);
}

@override
String toString() {
  final _this = this as ChatTheme;
  return 'ChatTheme(bubbleColor: ${_this.bubbleColor}, background: ${_this.background}, backgroundPath: ${_this.backgroundPath})';
}


}

/// @nodoc
abstract mixin class $ChatThemeCopyWith<$Res>  {
  factory $ChatThemeCopyWith(ChatTheme value, $Res Function(ChatTheme) _then) = _$ChatThemeCopyWithImpl;
@useResult
$Res call({
 int? bubbleColor, ChatBackground background, String? backgroundPath
});




}
/// @nodoc
class _$ChatThemeCopyWithImpl<$Res>
    implements $ChatThemeCopyWith<$Res> {
  _$ChatThemeCopyWithImpl(this._self, this._then);

  final ChatTheme _self;
  final $Res Function(ChatTheme) _then;

/// Create a copy of ChatTheme
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bubbleColor = freezed,Object? background = null,Object? backgroundPath = freezed,}) {
  return _then(ChatTheme(
bubbleColor: freezed == bubbleColor ? _self.bubbleColor : bubbleColor // ignore: cast_nullable_to_non_nullable
as int?,background: null == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as ChatBackground,backgroundPath: freezed == backgroundPath ? _self.backgroundPath : backgroundPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatTheme].
extension ChatThemePatterns on ChatTheme {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatTheme value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatTheme() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatTheme value)  $default,){
final _that = this;
switch (_that) {
case _ChatTheme():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatTheme value)?  $default,){
final _that = this;
switch (_that) {
case _ChatTheme() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? bubbleColor,  ChatBackground background,  String? backgroundPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatTheme() when $default != null:
return $default(_that.bubbleColor,_that.background,_that.backgroundPath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? bubbleColor,  ChatBackground background,  String? backgroundPath)  $default,) {final _that = this;
switch (_that) {
case _ChatTheme():
return $default(_that.bubbleColor,_that.background,_that.backgroundPath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? bubbleColor,  ChatBackground background,  String? backgroundPath)?  $default,) {final _that = this;
switch (_that) {
case _ChatTheme() when $default != null:
return $default(_that.bubbleColor,_that.background,_that.backgroundPath);case _:
  return null;

}
}

}

/// @nodoc


class _ChatTheme implements ChatTheme {
  const _ChatTheme({this.bubbleColor, this.background = ChatBackground.plain, this.backgroundPath});
  

/// ARGB from the team palette; null uses the team's own color.
@override final  int? bubbleColor;
@override@JsonKey() final  ChatBackground background;
@override final  String? backgroundPath;

/// Create a copy of ChatTheme
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatThemeCopyWith<_ChatTheme> get copyWith => __$ChatThemeCopyWithImpl<_ChatTheme>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatTheme&&(identical(other.bubbleColor, bubbleColor) || other.bubbleColor == bubbleColor)&&(identical(other.background, background) || other.background == background)&&(identical(other.backgroundPath, backgroundPath) || other.backgroundPath == backgroundPath));
}


@override
int get hashCode {
    return Object.hash(runtimeType,bubbleColor,background,backgroundPath);
}

@override
String toString() {
    return 'ChatTheme(bubbleColor: $bubbleColor, background: $background, backgroundPath: $backgroundPath)';
}


}

/// @nodoc
abstract mixin class _$ChatThemeCopyWith<$Res> implements $ChatThemeCopyWith<$Res> {
  factory _$ChatThemeCopyWith(_ChatTheme value, $Res Function(_ChatTheme) _then) = __$ChatThemeCopyWithImpl;
@override @useResult
$Res call({
 int? bubbleColor, ChatBackground background, String? backgroundPath
});




}
/// @nodoc
class __$ChatThemeCopyWithImpl<$Res>
    implements _$ChatThemeCopyWith<$Res> {
  __$ChatThemeCopyWithImpl(this._self, this._then);

  final _ChatTheme _self;
  final $Res Function(_ChatTheme) _then;

/// Create a copy of ChatTheme
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bubbleColor = freezed,Object? background = null,Object? backgroundPath = freezed,}) {
  return _then(_ChatTheme(
bubbleColor: freezed == bubbleColor ? _self.bubbleColor : bubbleColor // ignore: cast_nullable_to_non_nullable
as int?,background: null == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as ChatBackground,backgroundPath: freezed == backgroundPath ? _self.backgroundPath : backgroundPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$Group {

 GroupId get id; String get name; Sport get sport; int get memberCount;/// One kind of team (TEAM-1); a missing kind reads as a team, so a
/// basic group can be added later (TEAM-14).
 GroupKind get kind; String? get description;/// ARGB team color (one of `teamColorValues`).
 int? get color; DateTime? get lastMessageAt; String? get lastMessagePreview; DateTime? get archivedAt; DateTime? get suspendedAt; String? get ownerId; String? get photoPath; String get timeZone; GroupSettings get settings;/// Bytes stored under `groups/{id}/`, kept by the Storage triggers.
 int get storageBytes;/// The team's limit: 500 MB unless a super admin changed it (STORE-1,
/// STORE-6). The data layer fills in the default when it's missing.
 int get storageQuotaBytes; ChatTheme? get chatTheme;/// The chat's pinned messages, oldest pin first, at most
/// [Limits.pinnedMessagesMax] (CHAT-15). Only the server changes them.
 List<String> get pinnedMessageIds;
/// Create a copy of Group
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupCopyWith<Group> get copyWith => _$GroupCopyWithImpl<Group>(this as Group, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Group;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Group&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.sport, _this.sport) || other.sport == _this.sport)&&(identical(other.memberCount, _this.memberCount) || other.memberCount == _this.memberCount)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.lastMessageAt, _this.lastMessageAt) || other.lastMessageAt == _this.lastMessageAt)&&(identical(other.lastMessagePreview, _this.lastMessagePreview) || other.lastMessagePreview == _this.lastMessagePreview)&&(identical(other.archivedAt, _this.archivedAt) || other.archivedAt == _this.archivedAt)&&(identical(other.suspendedAt, _this.suspendedAt) || other.suspendedAt == _this.suspendedAt)&&(identical(other.ownerId, _this.ownerId) || other.ownerId == _this.ownerId)&&(identical(other.photoPath, _this.photoPath) || other.photoPath == _this.photoPath)&&(identical(other.timeZone, _this.timeZone) || other.timeZone == _this.timeZone)&&(identical(other.settings, _this.settings) || other.settings == _this.settings)&&(identical(other.storageBytes, _this.storageBytes) || other.storageBytes == _this.storageBytes)&&(identical(other.storageQuotaBytes, _this.storageQuotaBytes) || other.storageQuotaBytes == _this.storageQuotaBytes)&&(identical(other.chatTheme, _this.chatTheme) || other.chatTheme == _this.chatTheme)&&const DeepCollectionEquality().equals(other.pinnedMessageIds, _this.pinnedMessageIds));
}


@override
int get hashCode {
  final _this = this as Group;
  return Object.hashAll([runtimeType,_this.id,_this.name,_this.sport,_this.memberCount,_this.kind,_this.description,_this.color,_this.lastMessageAt,_this.lastMessagePreview,_this.archivedAt,_this.suspendedAt,_this.ownerId,_this.photoPath,_this.timeZone,_this.settings,_this.storageBytes,_this.storageQuotaBytes,_this.chatTheme,const DeepCollectionEquality().hash(_this.pinnedMessageIds)]);
}

@override
String toString() {
  final _this = this as Group;
  return 'Group(id: ${_this.id}, name: ${_this.name}, sport: ${_this.sport}, memberCount: ${_this.memberCount}, kind: ${_this.kind}, description: ${_this.description}, color: ${_this.color}, lastMessageAt: ${_this.lastMessageAt}, lastMessagePreview: ${_this.lastMessagePreview}, archivedAt: ${_this.archivedAt}, suspendedAt: ${_this.suspendedAt}, ownerId: ${_this.ownerId}, photoPath: ${_this.photoPath}, timeZone: ${_this.timeZone}, settings: ${_this.settings}, storageBytes: ${_this.storageBytes}, storageQuotaBytes: ${_this.storageQuotaBytes}, chatTheme: ${_this.chatTheme}, pinnedMessageIds: ${_this.pinnedMessageIds})';
}


}

/// @nodoc
abstract mixin class $GroupCopyWith<$Res>  {
  factory $GroupCopyWith(Group value, $Res Function(Group) _then) = _$GroupCopyWithImpl;
@useResult
$Res call({
 GroupId id, String name, Sport sport, int memberCount, GroupKind kind, String? description, int? color, DateTime? lastMessageAt, String? lastMessagePreview, DateTime? archivedAt, DateTime? suspendedAt, String? ownerId, String? photoPath, String timeZone, GroupSettings settings, int storageBytes, int storageQuotaBytes, ChatTheme? chatTheme, List<String> pinnedMessageIds
});


$GroupSettingsCopyWith<$Res> get settings;$ChatThemeCopyWith<$Res>? get chatTheme;

}
/// @nodoc
class _$GroupCopyWithImpl<$Res>
    implements $GroupCopyWith<$Res> {
  _$GroupCopyWithImpl(this._self, this._then);

  final Group _self;
  final $Res Function(Group) _then;

/// Create a copy of Group
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? sport = null,Object? memberCount = null,Object? kind = null,Object? description = freezed,Object? color = freezed,Object? lastMessageAt = freezed,Object? lastMessagePreview = freezed,Object? archivedAt = freezed,Object? suspendedAt = freezed,Object? ownerId = freezed,Object? photoPath = freezed,Object? timeZone = null,Object? settings = null,Object? storageBytes = null,Object? storageQuotaBytes = null,Object? chatTheme = freezed,Object? pinnedMessageIds = null,}) {
  return _then(Group(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as GroupId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Sport,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as GroupKind,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int?,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastMessagePreview: freezed == lastMessagePreview ? _self.lastMessagePreview : lastMessagePreview // ignore: cast_nullable_to_non_nullable
as String?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,suspendedAt: freezed == suspendedAt ? _self.suspendedAt : suspendedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,ownerId: freezed == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String?,photoPath: freezed == photoPath ? _self.photoPath : photoPath // ignore: cast_nullable_to_non_nullable
as String?,timeZone: null == timeZone ? _self.timeZone : timeZone // ignore: cast_nullable_to_non_nullable
as String,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as GroupSettings,storageBytes: null == storageBytes ? _self.storageBytes : storageBytes // ignore: cast_nullable_to_non_nullable
as int,storageQuotaBytes: null == storageQuotaBytes ? _self.storageQuotaBytes : storageQuotaBytes // ignore: cast_nullable_to_non_nullable
as int,chatTheme: freezed == chatTheme ? _self.chatTheme : chatTheme // ignore: cast_nullable_to_non_nullable
as ChatTheme?,pinnedMessageIds: null == pinnedMessageIds ? _self.pinnedMessageIds : pinnedMessageIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of Group
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GroupSettingsCopyWith<$Res> get settings {
  
  return $GroupSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}/// Create a copy of Group
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatThemeCopyWith<$Res>? get chatTheme {
    if (_self.chatTheme == null) {
    return null;
  }

  return $ChatThemeCopyWith<$Res>(_self.chatTheme!, (value) {
    return _then(_self.copyWith(chatTheme: value));
  });
}
}


/// Adds pattern-matching-related methods to [Group].
extension GroupPatterns on Group {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Group value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Group() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Group value)  $default,){
final _that = this;
switch (_that) {
case _Group():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Group value)?  $default,){
final _that = this;
switch (_that) {
case _Group() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GroupId id,  String name,  Sport sport,  int memberCount,  GroupKind kind,  String? description,  int? color,  DateTime? lastMessageAt,  String? lastMessagePreview,  DateTime? archivedAt,  DateTime? suspendedAt,  String? ownerId,  String? photoPath,  String timeZone,  GroupSettings settings,  int storageBytes,  int storageQuotaBytes,  ChatTheme? chatTheme,  List<String> pinnedMessageIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Group() when $default != null:
return $default(_that.id,_that.name,_that.sport,_that.memberCount,_that.kind,_that.description,_that.color,_that.lastMessageAt,_that.lastMessagePreview,_that.archivedAt,_that.suspendedAt,_that.ownerId,_that.photoPath,_that.timeZone,_that.settings,_that.storageBytes,_that.storageQuotaBytes,_that.chatTheme,_that.pinnedMessageIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GroupId id,  String name,  Sport sport,  int memberCount,  GroupKind kind,  String? description,  int? color,  DateTime? lastMessageAt,  String? lastMessagePreview,  DateTime? archivedAt,  DateTime? suspendedAt,  String? ownerId,  String? photoPath,  String timeZone,  GroupSettings settings,  int storageBytes,  int storageQuotaBytes,  ChatTheme? chatTheme,  List<String> pinnedMessageIds)  $default,) {final _that = this;
switch (_that) {
case _Group():
return $default(_that.id,_that.name,_that.sport,_that.memberCount,_that.kind,_that.description,_that.color,_that.lastMessageAt,_that.lastMessagePreview,_that.archivedAt,_that.suspendedAt,_that.ownerId,_that.photoPath,_that.timeZone,_that.settings,_that.storageBytes,_that.storageQuotaBytes,_that.chatTheme,_that.pinnedMessageIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GroupId id,  String name,  Sport sport,  int memberCount,  GroupKind kind,  String? description,  int? color,  DateTime? lastMessageAt,  String? lastMessagePreview,  DateTime? archivedAt,  DateTime? suspendedAt,  String? ownerId,  String? photoPath,  String timeZone,  GroupSettings settings,  int storageBytes,  int storageQuotaBytes,  ChatTheme? chatTheme,  List<String> pinnedMessageIds)?  $default,) {final _that = this;
switch (_that) {
case _Group() when $default != null:
return $default(_that.id,_that.name,_that.sport,_that.memberCount,_that.kind,_that.description,_that.color,_that.lastMessageAt,_that.lastMessagePreview,_that.archivedAt,_that.suspendedAt,_that.ownerId,_that.photoPath,_that.timeZone,_that.settings,_that.storageBytes,_that.storageQuotaBytes,_that.chatTheme,_that.pinnedMessageIds);case _:
  return null;

}
}

}

/// @nodoc


class _Group extends Group {
  const _Group({required this.id, required this.name, required this.sport, required this.memberCount, this.kind = GroupKind.team, this.description, this.color, this.lastMessageAt, this.lastMessagePreview, this.archivedAt, this.suspendedAt, this.ownerId, this.photoPath, this.timeZone = 'America/Chicago', this.settings = const GroupSettings(), this.storageBytes = 0, this.storageQuotaBytes = 0, this.chatTheme,  List<String> pinnedMessageIds = const <String>[]}): _pinnedMessageIds = pinnedMessageIds,super._();
  

@override final  GroupId id;
@override final  String name;
@override final  Sport sport;
@override final  int memberCount;
/// One kind of team (TEAM-1); a missing kind reads as a team, so a
/// basic group can be added later (TEAM-14).
@override@JsonKey() final  GroupKind kind;
@override final  String? description;
/// ARGB team color (one of `teamColorValues`).
@override final  int? color;
@override final  DateTime? lastMessageAt;
@override final  String? lastMessagePreview;
@override final  DateTime? archivedAt;
@override final  DateTime? suspendedAt;
@override final  String? ownerId;
@override final  String? photoPath;
@override@JsonKey() final  String timeZone;
@override@JsonKey() final  GroupSettings settings;
/// Bytes stored under `groups/{id}/`, kept by the Storage triggers.
@override@JsonKey() final  int storageBytes;
/// The team's limit: 500 MB unless a super admin changed it (STORE-1,
/// STORE-6). The data layer fills in the default when it's missing.
@override@JsonKey() final  int storageQuotaBytes;
@override final  ChatTheme? chatTheme;
/// The chat's pinned messages, oldest pin first, at most
/// [Limits.pinnedMessagesMax] (CHAT-15). Only the server changes them.
 final  List<String> _pinnedMessageIds;
/// The chat's pinned messages, oldest pin first, at most
/// [Limits.pinnedMessagesMax] (CHAT-15). Only the server changes them.
@override@JsonKey() List<String> get pinnedMessageIds {
  if (_pinnedMessageIds is EqualUnmodifiableListView) return _pinnedMessageIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pinnedMessageIds);
}


/// Create a copy of Group
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupCopyWith<_Group> get copyWith => __$GroupCopyWithImpl<_Group>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Group&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.sport, sport) || other.sport == sport)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.description, description) || other.description == description)&&(identical(other.color, color) || other.color == color)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&(identical(other.lastMessagePreview, lastMessagePreview) || other.lastMessagePreview == lastMessagePreview)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.suspendedAt, suspendedAt) || other.suspendedAt == suspendedAt)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.photoPath, photoPath) || other.photoPath == photoPath)&&(identical(other.timeZone, timeZone) || other.timeZone == timeZone)&&(identical(other.settings, settings) || other.settings == settings)&&(identical(other.storageBytes, storageBytes) || other.storageBytes == storageBytes)&&(identical(other.storageQuotaBytes, storageQuotaBytes) || other.storageQuotaBytes == storageQuotaBytes)&&(identical(other.chatTheme, chatTheme) || other.chatTheme == chatTheme)&&const DeepCollectionEquality().equals(other.pinnedMessageIds, _pinnedMessageIds));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,id,name,sport,memberCount,kind,description,color,lastMessageAt,lastMessagePreview,archivedAt,suspendedAt,ownerId,photoPath,timeZone,settings,storageBytes,storageQuotaBytes,chatTheme,const DeepCollectionEquality().hash(_pinnedMessageIds)]);
}

@override
String toString() {
    return 'Group(id: $id, name: $name, sport: $sport, memberCount: $memberCount, kind: $kind, description: $description, color: $color, lastMessageAt: $lastMessageAt, lastMessagePreview: $lastMessagePreview, archivedAt: $archivedAt, suspendedAt: $suspendedAt, ownerId: $ownerId, photoPath: $photoPath, timeZone: $timeZone, settings: $settings, storageBytes: $storageBytes, storageQuotaBytes: $storageQuotaBytes, chatTheme: $chatTheme, pinnedMessageIds: $pinnedMessageIds)';
}


}

/// @nodoc
abstract mixin class _$GroupCopyWith<$Res> implements $GroupCopyWith<$Res> {
  factory _$GroupCopyWith(_Group value, $Res Function(_Group) _then) = __$GroupCopyWithImpl;
@override @useResult
$Res call({
 GroupId id, String name, Sport sport, int memberCount, GroupKind kind, String? description, int? color, DateTime? lastMessageAt, String? lastMessagePreview, DateTime? archivedAt, DateTime? suspendedAt, String? ownerId, String? photoPath, String timeZone, GroupSettings settings, int storageBytes, int storageQuotaBytes, ChatTheme? chatTheme, List<String> pinnedMessageIds
});


@override $GroupSettingsCopyWith<$Res> get settings;@override $ChatThemeCopyWith<$Res>? get chatTheme;

}
/// @nodoc
class __$GroupCopyWithImpl<$Res>
    implements _$GroupCopyWith<$Res> {
  __$GroupCopyWithImpl(this._self, this._then);

  final _Group _self;
  final $Res Function(_Group) _then;

/// Create a copy of Group
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? sport = null,Object? memberCount = null,Object? kind = null,Object? description = freezed,Object? color = freezed,Object? lastMessageAt = freezed,Object? lastMessagePreview = freezed,Object? archivedAt = freezed,Object? suspendedAt = freezed,Object? ownerId = freezed,Object? photoPath = freezed,Object? timeZone = null,Object? settings = null,Object? storageBytes = null,Object? storageQuotaBytes = null,Object? chatTheme = freezed,Object? pinnedMessageIds = null,}) {
  return _then(_Group(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as GroupId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sport: null == sport ? _self.sport : sport // ignore: cast_nullable_to_non_nullable
as Sport,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as GroupKind,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int?,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastMessagePreview: freezed == lastMessagePreview ? _self.lastMessagePreview : lastMessagePreview // ignore: cast_nullable_to_non_nullable
as String?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,suspendedAt: freezed == suspendedAt ? _self.suspendedAt : suspendedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,ownerId: freezed == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String?,photoPath: freezed == photoPath ? _self.photoPath : photoPath // ignore: cast_nullable_to_non_nullable
as String?,timeZone: null == timeZone ? _self.timeZone : timeZone // ignore: cast_nullable_to_non_nullable
as String,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as GroupSettings,storageBytes: null == storageBytes ? _self.storageBytes : storageBytes // ignore: cast_nullable_to_non_nullable
as int,storageQuotaBytes: null == storageQuotaBytes ? _self.storageQuotaBytes : storageQuotaBytes // ignore: cast_nullable_to_non_nullable
as int,chatTheme: freezed == chatTheme ? _self.chatTheme : chatTheme // ignore: cast_nullable_to_non_nullable
as ChatTheme?,pinnedMessageIds: null == pinnedMessageIds ? _self._pinnedMessageIds : pinnedMessageIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of Group
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GroupSettingsCopyWith<$Res> get settings {
  
  return $GroupSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}/// Create a copy of Group
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatThemeCopyWith<$Res>? get chatTheme {
    if (_self.chatTheme == null) {
    return null;
  }

  return $ChatThemeCopyWith<$Res>(_self.chatTheme!, (value) {
    return _then(_self.copyWith(chatTheme: value));
  });
}
}

// dart format on
