// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_queue_store.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SavedText {

 String get id; String get text; String? get replyToId; List<String> get mentions; bool get mentionsEveryone; bool get announcement;
/// Create a copy of SavedText
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedTextCopyWith<SavedText> get copyWith => _$SavedTextCopyWithImpl<SavedText>(this as SavedText, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SavedText;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedText&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.replyToId, _this.replyToId) || other.replyToId == _this.replyToId)&&const DeepCollectionEquality().equals(other.mentions, _this.mentions)&&(identical(other.mentionsEveryone, _this.mentionsEveryone) || other.mentionsEveryone == _this.mentionsEveryone)&&(identical(other.announcement, _this.announcement) || other.announcement == _this.announcement));
}


@override
int get hashCode {
  final _this = this as SavedText;
  return Object.hash(runtimeType,_this.id,_this.text,_this.replyToId,const DeepCollectionEquality().hash(_this.mentions),_this.mentionsEveryone,_this.announcement);
}

@override
String toString() {
  final _this = this as SavedText;
  return 'SavedText(id: ${_this.id}, text: ${_this.text}, replyToId: ${_this.replyToId}, mentions: ${_this.mentions}, mentionsEveryone: ${_this.mentionsEveryone}, announcement: ${_this.announcement})';
}


}

/// @nodoc
abstract mixin class $SavedTextCopyWith<$Res>  {
  factory $SavedTextCopyWith(SavedText value, $Res Function(SavedText) _then) = _$SavedTextCopyWithImpl;
@useResult
$Res call({
 String id, String text, String? replyToId, List<String> mentions, bool mentionsEveryone, bool announcement
});




}
/// @nodoc
class _$SavedTextCopyWithImpl<$Res>
    implements $SavedTextCopyWith<$Res> {
  _$SavedTextCopyWithImpl(this._self, this._then);

  final SavedText _self;
  final $Res Function(SavedText) _then;

/// Create a copy of SavedText
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? text = null,Object? replyToId = freezed,Object? mentions = null,Object? mentionsEveryone = null,Object? announcement = null,}) {
  return _then(SavedText(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,replyToId: freezed == replyToId ? _self.replyToId : replyToId // ignore: cast_nullable_to_non_nullable
as String?,mentions: null == mentions ? _self.mentions : mentions // ignore: cast_nullable_to_non_nullable
as List<String>,mentionsEveryone: null == mentionsEveryone ? _self.mentionsEveryone : mentionsEveryone // ignore: cast_nullable_to_non_nullable
as bool,announcement: null == announcement ? _self.announcement : announcement // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SavedText].
extension SavedTextPatterns on SavedText {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedText value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedText() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedText value)  $default,){
final _that = this;
switch (_that) {
case _SavedText():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedText value)?  $default,){
final _that = this;
switch (_that) {
case _SavedText() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String text,  String? replyToId,  List<String> mentions,  bool mentionsEveryone,  bool announcement)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedText() when $default != null:
return $default(_that.id,_that.text,_that.replyToId,_that.mentions,_that.mentionsEveryone,_that.announcement);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String text,  String? replyToId,  List<String> mentions,  bool mentionsEveryone,  bool announcement)  $default,) {final _that = this;
switch (_that) {
case _SavedText():
return $default(_that.id,_that.text,_that.replyToId,_that.mentions,_that.mentionsEveryone,_that.announcement);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String text,  String? replyToId,  List<String> mentions,  bool mentionsEveryone,  bool announcement)?  $default,) {final _that = this;
switch (_that) {
case _SavedText() when $default != null:
return $default(_that.id,_that.text,_that.replyToId,_that.mentions,_that.mentionsEveryone,_that.announcement);case _:
  return null;

}
}

}

/// @nodoc


class _SavedText implements SavedText {
  const _SavedText({required this.id, required this.text, this.replyToId,  List<String> mentions = const <String>[], this.mentionsEveryone = false, this.announcement = false}): _mentions = mentions;
  

@override final  String id;
@override final  String text;
@override final  String? replyToId;
 final  List<String> _mentions;
@override@JsonKey() List<String> get mentions {
  if (_mentions is EqualUnmodifiableListView) return _mentions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mentions);
}

@override@JsonKey() final  bool mentionsEveryone;
@override@JsonKey() final  bool announcement;

/// Create a copy of SavedText
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedTextCopyWith<_SavedText> get copyWith => __$SavedTextCopyWithImpl<_SavedText>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedText&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.replyToId, replyToId) || other.replyToId == replyToId)&&const DeepCollectionEquality().equals(other.mentions, _mentions)&&(identical(other.mentionsEveryone, mentionsEveryone) || other.mentionsEveryone == mentionsEveryone)&&(identical(other.announcement, announcement) || other.announcement == announcement));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,text,replyToId,const DeepCollectionEquality().hash(_mentions),mentionsEveryone,announcement);
}

@override
String toString() {
    return 'SavedText(id: $id, text: $text, replyToId: $replyToId, mentions: $mentions, mentionsEveryone: $mentionsEveryone, announcement: $announcement)';
}


}

/// @nodoc
abstract mixin class _$SavedTextCopyWith<$Res> implements $SavedTextCopyWith<$Res> {
  factory _$SavedTextCopyWith(_SavedText value, $Res Function(_SavedText) _then) = __$SavedTextCopyWithImpl;
@override @useResult
$Res call({
 String id, String text, String? replyToId, List<String> mentions, bool mentionsEveryone, bool announcement
});




}
/// @nodoc
class __$SavedTextCopyWithImpl<$Res>
    implements _$SavedTextCopyWith<$Res> {
  __$SavedTextCopyWithImpl(this._self, this._then);

  final _SavedText _self;
  final $Res Function(_SavedText) _then;

/// Create a copy of SavedText
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = null,Object? replyToId = freezed,Object? mentions = null,Object? mentionsEveryone = null,Object? announcement = null,}) {
  return _then(_SavedText(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,replyToId: freezed == replyToId ? _self.replyToId : replyToId // ignore: cast_nullable_to_non_nullable
as String?,mentions: null == mentions ? _self._mentions : mentions // ignore: cast_nullable_to_non_nullable
as List<String>,mentionsEveryone: null == mentionsEveryone ? _self.mentionsEveryone : mentionsEveryone // ignore: cast_nullable_to_non_nullable
as bool,announcement: null == announcement ? _self.announcement : announcement // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
