// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poll.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Poll {

 PollId get id; GroupId get groupId; String get createdBy; String get question; List<PollOption> get options; bool get allowMultiple;/// Only counts are shown; nobody in the app sees who chose what (POLL-3).
 bool get anonymous;/// When it closes by itself (POLL-4), if set.
 DateTime? get closesAt;/// When it closed, early or on time. Closed polls never reopen.
 DateTime? get closedAt;/// Votes per option ID.
 Map<String, int> get voteCounts;/// How many people voted.
 int get voterCount;
/// Create a copy of Poll
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PollCopyWith<Poll> get copyWith => _$PollCopyWithImpl<Poll>(this as Poll, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Poll;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Poll&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.question, _this.question) || other.question == _this.question)&&const DeepCollectionEquality().equals(other.options, _this.options)&&(identical(other.allowMultiple, _this.allowMultiple) || other.allowMultiple == _this.allowMultiple)&&(identical(other.anonymous, _this.anonymous) || other.anonymous == _this.anonymous)&&(identical(other.closesAt, _this.closesAt) || other.closesAt == _this.closesAt)&&(identical(other.closedAt, _this.closedAt) || other.closedAt == _this.closedAt)&&const DeepCollectionEquality().equals(other.voteCounts, _this.voteCounts)&&(identical(other.voterCount, _this.voterCount) || other.voterCount == _this.voterCount));
}


@override
int get hashCode {
  final _this = this as Poll;
  return Object.hash(runtimeType,_this.id,_this.groupId,_this.createdBy,_this.question,const DeepCollectionEquality().hash(_this.options),_this.allowMultiple,_this.anonymous,_this.closesAt,_this.closedAt,const DeepCollectionEquality().hash(_this.voteCounts),_this.voterCount);
}

@override
String toString() {
  final _this = this as Poll;
  return 'Poll(id: ${_this.id}, groupId: ${_this.groupId}, createdBy: ${_this.createdBy}, question: ${_this.question}, options: ${_this.options}, allowMultiple: ${_this.allowMultiple}, anonymous: ${_this.anonymous}, closesAt: ${_this.closesAt}, closedAt: ${_this.closedAt}, voteCounts: ${_this.voteCounts}, voterCount: ${_this.voterCount})';
}


}

/// @nodoc
abstract mixin class $PollCopyWith<$Res>  {
  factory $PollCopyWith(Poll value, $Res Function(Poll) _then) = _$PollCopyWithImpl;
@useResult
$Res call({
 PollId id, GroupId groupId, String createdBy, String question, List<PollOption> options, bool allowMultiple, bool anonymous, DateTime? closesAt, DateTime? closedAt, Map<String, int> voteCounts, int voterCount
});




}
/// @nodoc
class _$PollCopyWithImpl<$Res>
    implements $PollCopyWith<$Res> {
  _$PollCopyWithImpl(this._self, this._then);

  final Poll _self;
  final $Res Function(Poll) _then;

/// Create a copy of Poll
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? groupId = null,Object? createdBy = null,Object? question = null,Object? options = null,Object? allowMultiple = null,Object? anonymous = null,Object? closesAt = freezed,Object? closedAt = freezed,Object? voteCounts = null,Object? voterCount = null,}) {
  return _then(Poll(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PollId,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<PollOption>,allowMultiple: null == allowMultiple ? _self.allowMultiple : allowMultiple // ignore: cast_nullable_to_non_nullable
as bool,anonymous: null == anonymous ? _self.anonymous : anonymous // ignore: cast_nullable_to_non_nullable
as bool,closesAt: freezed == closesAt ? _self.closesAt : closesAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,voteCounts: null == voteCounts ? _self.voteCounts : voteCounts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,voterCount: null == voterCount ? _self.voterCount : voterCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Poll].
extension PollPatterns on Poll {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Poll value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Poll() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Poll value)  $default,){
final _that = this;
switch (_that) {
case _Poll():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Poll value)?  $default,){
final _that = this;
switch (_that) {
case _Poll() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PollId id,  GroupId groupId,  String createdBy,  String question,  List<PollOption> options,  bool allowMultiple,  bool anonymous,  DateTime? closesAt,  DateTime? closedAt,  Map<String, int> voteCounts,  int voterCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Poll() when $default != null:
return $default(_that.id,_that.groupId,_that.createdBy,_that.question,_that.options,_that.allowMultiple,_that.anonymous,_that.closesAt,_that.closedAt,_that.voteCounts,_that.voterCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PollId id,  GroupId groupId,  String createdBy,  String question,  List<PollOption> options,  bool allowMultiple,  bool anonymous,  DateTime? closesAt,  DateTime? closedAt,  Map<String, int> voteCounts,  int voterCount)  $default,) {final _that = this;
switch (_that) {
case _Poll():
return $default(_that.id,_that.groupId,_that.createdBy,_that.question,_that.options,_that.allowMultiple,_that.anonymous,_that.closesAt,_that.closedAt,_that.voteCounts,_that.voterCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PollId id,  GroupId groupId,  String createdBy,  String question,  List<PollOption> options,  bool allowMultiple,  bool anonymous,  DateTime? closesAt,  DateTime? closedAt,  Map<String, int> voteCounts,  int voterCount)?  $default,) {final _that = this;
switch (_that) {
case _Poll() when $default != null:
return $default(_that.id,_that.groupId,_that.createdBy,_that.question,_that.options,_that.allowMultiple,_that.anonymous,_that.closesAt,_that.closedAt,_that.voteCounts,_that.voterCount);case _:
  return null;

}
}

}

/// @nodoc


class _Poll extends Poll {
  const _Poll({required this.id, required this.groupId, required this.createdBy, required this.question, required  List<PollOption> options, this.allowMultiple = false, this.anonymous = false, this.closesAt, this.closedAt,  Map<String, int> voteCounts = const <String, int>{}, this.voterCount = 0}): _options = options,_voteCounts = voteCounts,super._();
  

@override final  PollId id;
@override final  GroupId groupId;
@override final  String createdBy;
@override final  String question;
 final  List<PollOption> _options;
@override List<PollOption> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

@override@JsonKey() final  bool allowMultiple;
/// Only counts are shown; nobody in the app sees who chose what (POLL-3).
@override@JsonKey() final  bool anonymous;
/// When it closes by itself (POLL-4), if set.
@override final  DateTime? closesAt;
/// When it closed, early or on time. Closed polls never reopen.
@override final  DateTime? closedAt;
/// Votes per option ID.
 final  Map<String, int> _voteCounts;
/// Votes per option ID.
@override@JsonKey() Map<String, int> get voteCounts {
  if (_voteCounts is EqualUnmodifiableMapView) return _voteCounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_voteCounts);
}

/// How many people voted.
@override@JsonKey() final  int voterCount;

/// Create a copy of Poll
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PollCopyWith<_Poll> get copyWith => __$PollCopyWithImpl<_Poll>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Poll&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.question, question) || other.question == question)&&const DeepCollectionEquality().equals(other.options, _options)&&(identical(other.allowMultiple, allowMultiple) || other.allowMultiple == allowMultiple)&&(identical(other.anonymous, anonymous) || other.anonymous == anonymous)&&(identical(other.closesAt, closesAt) || other.closesAt == closesAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&const DeepCollectionEquality().equals(other.voteCounts, _voteCounts)&&(identical(other.voterCount, voterCount) || other.voterCount == voterCount));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,groupId,createdBy,question,const DeepCollectionEquality().hash(_options),allowMultiple,anonymous,closesAt,closedAt,const DeepCollectionEquality().hash(_voteCounts),voterCount);
}

@override
String toString() {
    return 'Poll(id: $id, groupId: $groupId, createdBy: $createdBy, question: $question, options: $options, allowMultiple: $allowMultiple, anonymous: $anonymous, closesAt: $closesAt, closedAt: $closedAt, voteCounts: $voteCounts, voterCount: $voterCount)';
}


}

/// @nodoc
abstract mixin class _$PollCopyWith<$Res> implements $PollCopyWith<$Res> {
  factory _$PollCopyWith(_Poll value, $Res Function(_Poll) _then) = __$PollCopyWithImpl;
@override @useResult
$Res call({
 PollId id, GroupId groupId, String createdBy, String question, List<PollOption> options, bool allowMultiple, bool anonymous, DateTime? closesAt, DateTime? closedAt, Map<String, int> voteCounts, int voterCount
});




}
/// @nodoc
class __$PollCopyWithImpl<$Res>
    implements _$PollCopyWith<$Res> {
  __$PollCopyWithImpl(this._self, this._then);

  final _Poll _self;
  final $Res Function(_Poll) _then;

/// Create a copy of Poll
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? groupId = null,Object? createdBy = null,Object? question = null,Object? options = null,Object? allowMultiple = null,Object? anonymous = null,Object? closesAt = freezed,Object? closedAt = freezed,Object? voteCounts = null,Object? voterCount = null,}) {
  return _then(_Poll(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PollId,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<PollOption>,allowMultiple: null == allowMultiple ? _self.allowMultiple : allowMultiple // ignore: cast_nullable_to_non_nullable
as bool,anonymous: null == anonymous ? _self.anonymous : anonymous // ignore: cast_nullable_to_non_nullable
as bool,closesAt: freezed == closesAt ? _self.closesAt : closesAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,voteCounts: null == voteCounts ? _self._voteCounts : voteCounts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,voterCount: null == voterCount ? _self.voterCount : voterCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$PollOption {

 String get id; String get text;
/// Create a copy of PollOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PollOptionCopyWith<PollOption> get copyWith => _$PollOptionCopyWithImpl<PollOption>(this as PollOption, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PollOption;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PollOption&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.text, _this.text) || other.text == _this.text));
}


@override
int get hashCode {
  final _this = this as PollOption;
  return Object.hash(runtimeType,_this.id,_this.text);
}

@override
String toString() {
  final _this = this as PollOption;
  return 'PollOption(id: ${_this.id}, text: ${_this.text})';
}


}

/// @nodoc
abstract mixin class $PollOptionCopyWith<$Res>  {
  factory $PollOptionCopyWith(PollOption value, $Res Function(PollOption) _then) = _$PollOptionCopyWithImpl;
@useResult
$Res call({
 String id, String text
});




}
/// @nodoc
class _$PollOptionCopyWithImpl<$Res>
    implements $PollOptionCopyWith<$Res> {
  _$PollOptionCopyWithImpl(this._self, this._then);

  final PollOption _self;
  final $Res Function(PollOption) _then;

/// Create a copy of PollOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? text = null,}) {
  return _then(PollOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PollOption].
extension PollOptionPatterns on PollOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PollOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PollOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PollOption value)  $default,){
final _that = this;
switch (_that) {
case _PollOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PollOption value)?  $default,){
final _that = this;
switch (_that) {
case _PollOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PollOption() when $default != null:
return $default(_that.id,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String text)  $default,) {final _that = this;
switch (_that) {
case _PollOption():
return $default(_that.id,_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String text)?  $default,) {final _that = this;
switch (_that) {
case _PollOption() when $default != null:
return $default(_that.id,_that.text);case _:
  return null;

}
}

}

/// @nodoc


class _PollOption implements PollOption {
  const _PollOption({required this.id, required this.text});
  

@override final  String id;
@override final  String text;

/// Create a copy of PollOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PollOptionCopyWith<_PollOption> get copyWith => __$PollOptionCopyWithImpl<_PollOption>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PollOption&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,text);
}

@override
String toString() {
    return 'PollOption(id: $id, text: $text)';
}


}

/// @nodoc
abstract mixin class _$PollOptionCopyWith<$Res> implements $PollOptionCopyWith<$Res> {
  factory _$PollOptionCopyWith(_PollOption value, $Res Function(_PollOption) _then) = __$PollOptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String text
});




}
/// @nodoc
class __$PollOptionCopyWithImpl<$Res>
    implements _$PollOptionCopyWith<$Res> {
  __$PollOptionCopyWithImpl(this._self, this._then);

  final _PollOption _self;
  final $Res Function(_PollOption) _then;

/// Create a copy of PollOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = null,}) {
  return _then(_PollOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$PollVote {

 String get uid; Set<String> get optionIds;
/// Create a copy of PollVote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PollVoteCopyWith<PollVote> get copyWith => _$PollVoteCopyWithImpl<PollVote>(this as PollVote, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PollVote;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PollVote&&(identical(other.uid, _this.uid) || other.uid == _this.uid)&&const DeepCollectionEquality().equals(other.optionIds, _this.optionIds));
}


@override
int get hashCode {
  final _this = this as PollVote;
  return Object.hash(runtimeType,_this.uid,const DeepCollectionEquality().hash(_this.optionIds));
}

@override
String toString() {
  final _this = this as PollVote;
  return 'PollVote(uid: ${_this.uid}, optionIds: ${_this.optionIds})';
}


}

/// @nodoc
abstract mixin class $PollVoteCopyWith<$Res>  {
  factory $PollVoteCopyWith(PollVote value, $Res Function(PollVote) _then) = _$PollVoteCopyWithImpl;
@useResult
$Res call({
 String uid, Set<String> optionIds
});




}
/// @nodoc
class _$PollVoteCopyWithImpl<$Res>
    implements $PollVoteCopyWith<$Res> {
  _$PollVoteCopyWithImpl(this._self, this._then);

  final PollVote _self;
  final $Res Function(PollVote) _then;

/// Create a copy of PollVote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? optionIds = null,}) {
  return _then(PollVote(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,optionIds: null == optionIds ? _self.optionIds : optionIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [PollVote].
extension PollVotePatterns on PollVote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PollVote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PollVote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PollVote value)  $default,){
final _that = this;
switch (_that) {
case _PollVote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PollVote value)?  $default,){
final _that = this;
switch (_that) {
case _PollVote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  Set<String> optionIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PollVote() when $default != null:
return $default(_that.uid,_that.optionIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  Set<String> optionIds)  $default,) {final _that = this;
switch (_that) {
case _PollVote():
return $default(_that.uid,_that.optionIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  Set<String> optionIds)?  $default,) {final _that = this;
switch (_that) {
case _PollVote() when $default != null:
return $default(_that.uid,_that.optionIds);case _:
  return null;

}
}

}

/// @nodoc


class _PollVote implements PollVote {
  const _PollVote({required this.uid, required  Set<String> optionIds}): _optionIds = optionIds;
  

@override final  String uid;
 final  Set<String> _optionIds;
@override Set<String> get optionIds {
  if (_optionIds is EqualUnmodifiableSetView) return _optionIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_optionIds);
}


/// Create a copy of PollVote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PollVoteCopyWith<_PollVote> get copyWith => __$PollVoteCopyWithImpl<_PollVote>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PollVote&&(identical(other.uid, uid) || other.uid == uid)&&const DeepCollectionEquality().equals(other.optionIds, _optionIds));
}


@override
int get hashCode {
    return Object.hash(runtimeType,uid,const DeepCollectionEquality().hash(_optionIds));
}

@override
String toString() {
    return 'PollVote(uid: $uid, optionIds: $optionIds)';
}


}

/// @nodoc
abstract mixin class _$PollVoteCopyWith<$Res> implements $PollVoteCopyWith<$Res> {
  factory _$PollVoteCopyWith(_PollVote value, $Res Function(_PollVote) _then) = __$PollVoteCopyWithImpl;
@override @useResult
$Res call({
 String uid, Set<String> optionIds
});




}
/// @nodoc
class __$PollVoteCopyWithImpl<$Res>
    implements _$PollVoteCopyWith<$Res> {
  __$PollVoteCopyWithImpl(this._self, this._then);

  final _PollVote _self;
  final $Res Function(_PollVote) _then;

/// Create a copy of PollVote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? optionIds = null,}) {
  return _then(_PollVote(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,optionIds: null == optionIds ? _self._optionIds : optionIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

/// @nodoc
mixin _$NewPoll {

 String get question; List<String> get options; bool get allowMultiple; bool get anonymous; DateTime? get closesAt;
/// Create a copy of NewPoll
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewPollCopyWith<NewPoll> get copyWith => _$NewPollCopyWithImpl<NewPoll>(this as NewPoll, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as NewPoll;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewPoll&&(identical(other.question, _this.question) || other.question == _this.question)&&const DeepCollectionEquality().equals(other.options, _this.options)&&(identical(other.allowMultiple, _this.allowMultiple) || other.allowMultiple == _this.allowMultiple)&&(identical(other.anonymous, _this.anonymous) || other.anonymous == _this.anonymous)&&(identical(other.closesAt, _this.closesAt) || other.closesAt == _this.closesAt));
}


@override
int get hashCode {
  final _this = this as NewPoll;
  return Object.hash(runtimeType,_this.question,const DeepCollectionEquality().hash(_this.options),_this.allowMultiple,_this.anonymous,_this.closesAt);
}

@override
String toString() {
  final _this = this as NewPoll;
  return 'NewPoll(question: ${_this.question}, options: ${_this.options}, allowMultiple: ${_this.allowMultiple}, anonymous: ${_this.anonymous}, closesAt: ${_this.closesAt})';
}


}

/// @nodoc
abstract mixin class $NewPollCopyWith<$Res>  {
  factory $NewPollCopyWith(NewPoll value, $Res Function(NewPoll) _then) = _$NewPollCopyWithImpl;
@useResult
$Res call({
 String question, List<String> options, bool allowMultiple, bool anonymous, DateTime? closesAt
});




}
/// @nodoc
class _$NewPollCopyWithImpl<$Res>
    implements $NewPollCopyWith<$Res> {
  _$NewPollCopyWithImpl(this._self, this._then);

  final NewPoll _self;
  final $Res Function(NewPoll) _then;

/// Create a copy of NewPoll
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? question = null,Object? options = null,Object? allowMultiple = null,Object? anonymous = null,Object? closesAt = freezed,}) {
  return _then(NewPoll(
question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<String>,allowMultiple: null == allowMultiple ? _self.allowMultiple : allowMultiple // ignore: cast_nullable_to_non_nullable
as bool,anonymous: null == anonymous ? _self.anonymous : anonymous // ignore: cast_nullable_to_non_nullable
as bool,closesAt: freezed == closesAt ? _self.closesAt : closesAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [NewPoll].
extension NewPollPatterns on NewPoll {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewPoll value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewPoll() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewPoll value)  $default,){
final _that = this;
switch (_that) {
case _NewPoll():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewPoll value)?  $default,){
final _that = this;
switch (_that) {
case _NewPoll() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String question,  List<String> options,  bool allowMultiple,  bool anonymous,  DateTime? closesAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewPoll() when $default != null:
return $default(_that.question,_that.options,_that.allowMultiple,_that.anonymous,_that.closesAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String question,  List<String> options,  bool allowMultiple,  bool anonymous,  DateTime? closesAt)  $default,) {final _that = this;
switch (_that) {
case _NewPoll():
return $default(_that.question,_that.options,_that.allowMultiple,_that.anonymous,_that.closesAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String question,  List<String> options,  bool allowMultiple,  bool anonymous,  DateTime? closesAt)?  $default,) {final _that = this;
switch (_that) {
case _NewPoll() when $default != null:
return $default(_that.question,_that.options,_that.allowMultiple,_that.anonymous,_that.closesAt);case _:
  return null;

}
}

}

/// @nodoc


class _NewPoll extends NewPoll {
  const _NewPoll({required this.question, required  List<String> options, this.allowMultiple = false, this.anonymous = false, this.closesAt}): _options = options,super._();
  

@override final  String question;
 final  List<String> _options;
@override List<String> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

@override@JsonKey() final  bool allowMultiple;
@override@JsonKey() final  bool anonymous;
@override final  DateTime? closesAt;

/// Create a copy of NewPoll
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewPollCopyWith<_NewPoll> get copyWith => __$NewPollCopyWithImpl<_NewPoll>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewPoll&&(identical(other.question, question) || other.question == question)&&const DeepCollectionEquality().equals(other.options, _options)&&(identical(other.allowMultiple, allowMultiple) || other.allowMultiple == allowMultiple)&&(identical(other.anonymous, anonymous) || other.anonymous == anonymous)&&(identical(other.closesAt, closesAt) || other.closesAt == closesAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,question,const DeepCollectionEquality().hash(_options),allowMultiple,anonymous,closesAt);
}

@override
String toString() {
    return 'NewPoll(question: $question, options: $options, allowMultiple: $allowMultiple, anonymous: $anonymous, closesAt: $closesAt)';
}


}

/// @nodoc
abstract mixin class _$NewPollCopyWith<$Res> implements $NewPollCopyWith<$Res> {
  factory _$NewPollCopyWith(_NewPoll value, $Res Function(_NewPoll) _then) = __$NewPollCopyWithImpl;
@override @useResult
$Res call({
 String question, List<String> options, bool allowMultiple, bool anonymous, DateTime? closesAt
});




}
/// @nodoc
class __$NewPollCopyWithImpl<$Res>
    implements _$NewPollCopyWith<$Res> {
  __$NewPollCopyWithImpl(this._self, this._then);

  final _NewPoll _self;
  final $Res Function(_NewPoll) _then;

/// Create a copy of NewPoll
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? question = null,Object? options = null,Object? allowMultiple = null,Object? anonymous = null,Object? closesAt = freezed,}) {
  return _then(_NewPoll(
question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<String>,allowMultiple: null == allowMultiple ? _self.allowMultiple : allowMultiple // ignore: cast_nullable_to_non_nullable
as bool,anonymous: null == anonymous ? _self.anonymous : anonymous // ignore: cast_nullable_to_non_nullable
as bool,closesAt: freezed == closesAt ? _self.closesAt : closesAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
