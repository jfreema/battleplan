// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'play.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BoardElement {

 String get id;
/// Create a copy of BoardElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BoardElementCopyWith<BoardElement> get copyWith => _$BoardElementCopyWithImpl<BoardElement>(this as BoardElement, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BoardElement;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BoardElement&&(identical(other.id, _this.id) || other.id == _this.id));
}


@override
int get hashCode {
  final _this = this as BoardElement;
  return Object.hash(runtimeType,_this.id);
}

@override
String toString() {
  final _this = this as BoardElement;
  return 'BoardElement(id: ${_this.id})';
}


}

/// @nodoc
abstract mixin class $BoardElementCopyWith<$Res>  {
  factory $BoardElementCopyWith(BoardElement value, $Res Function(BoardElement) _then) = _$BoardElementCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class _$BoardElementCopyWithImpl<$Res>
    implements $BoardElementCopyWith<$Res> {
  _$BoardElementCopyWithImpl(this._self, this._then);

  final BoardElement _self;
  final $Res Function(BoardElement) _then;

/// Create a copy of BoardElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BoardElement].
extension BoardElementPatterns on BoardElement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MarkerElement value)?  marker,TResult Function( ArrowElement value)?  arrow,TResult Function( LineElement value)?  line,TResult Function( NoteElement value)?  note,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MarkerElement() when marker != null:
return marker(_that);case ArrowElement() when arrow != null:
return arrow(_that);case LineElement() when line != null:
return line(_that);case NoteElement() when note != null:
return note(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MarkerElement value)  marker,required TResult Function( ArrowElement value)  arrow,required TResult Function( LineElement value)  line,required TResult Function( NoteElement value)  note,}){
final _that = this;
switch (_that) {
case MarkerElement():
return marker(_that);case ArrowElement():
return arrow(_that);case LineElement():
return line(_that);case NoteElement():
return note(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MarkerElement value)?  marker,TResult? Function( ArrowElement value)?  arrow,TResult? Function( LineElement value)?  line,TResult? Function( NoteElement value)?  note,}){
final _that = this;
switch (_that) {
case MarkerElement() when marker != null:
return marker(_that);case ArrowElement() when arrow != null:
return arrow(_that);case LineElement() when line != null:
return line(_that);case NoteElement() when note != null:
return note(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  BoardPoint at,  MarkerSide side,  String label,  PlayerId? playerId)?  marker,TResult Function( String id,  ArrowKind kind,  List<BoardPoint> points)?  arrow,TResult Function( String id,  List<BoardPoint> points)?  line,TResult Function( String id,  BoardPoint at,  String text)?  note,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MarkerElement() when marker != null:
return marker(_that.id,_that.at,_that.side,_that.label,_that.playerId);case ArrowElement() when arrow != null:
return arrow(_that.id,_that.kind,_that.points);case LineElement() when line != null:
return line(_that.id,_that.points);case NoteElement() when note != null:
return note(_that.id,_that.at,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  BoardPoint at,  MarkerSide side,  String label,  PlayerId? playerId)  marker,required TResult Function( String id,  ArrowKind kind,  List<BoardPoint> points)  arrow,required TResult Function( String id,  List<BoardPoint> points)  line,required TResult Function( String id,  BoardPoint at,  String text)  note,}) {final _that = this;
switch (_that) {
case MarkerElement():
return marker(_that.id,_that.at,_that.side,_that.label,_that.playerId);case ArrowElement():
return arrow(_that.id,_that.kind,_that.points);case LineElement():
return line(_that.id,_that.points);case NoteElement():
return note(_that.id,_that.at,_that.text);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  BoardPoint at,  MarkerSide side,  String label,  PlayerId? playerId)?  marker,TResult? Function( String id,  ArrowKind kind,  List<BoardPoint> points)?  arrow,TResult? Function( String id,  List<BoardPoint> points)?  line,TResult? Function( String id,  BoardPoint at,  String text)?  note,}) {final _that = this;
switch (_that) {
case MarkerElement() when marker != null:
return marker(_that.id,_that.at,_that.side,_that.label,_that.playerId);case ArrowElement() when arrow != null:
return arrow(_that.id,_that.kind,_that.points);case LineElement() when line != null:
return line(_that.id,_that.points);case NoteElement() when note != null:
return note(_that.id,_that.at,_that.text);case _:
  return null;

}
}

}

/// @nodoc


class MarkerElement implements BoardElement {
  const MarkerElement({required this.id, required this.at, required this.side, this.label = '', this.playerId});
  

@override final  String id;
 final  BoardPoint at;
 final  MarkerSide side;
@JsonKey() final  String label;
 final  PlayerId? playerId;

/// Create a copy of BoardElement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkerElementCopyWith<MarkerElement> get copyWith => _$MarkerElementCopyWithImpl<MarkerElement>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkerElement&&(identical(other.id, id) || other.id == id)&&(identical(other.at, at) || other.at == at)&&(identical(other.side, side) || other.side == side)&&(identical(other.label, label) || other.label == label)&&(identical(other.playerId, playerId) || other.playerId == playerId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,at,side,label,playerId);
}

@override
String toString() {
    return 'BoardElement.marker(id: $id, at: $at, side: $side, label: $label, playerId: $playerId)';
}


}

/// @nodoc
abstract mixin class $MarkerElementCopyWith<$Res> implements $BoardElementCopyWith<$Res> {
  factory $MarkerElementCopyWith(MarkerElement value, $Res Function(MarkerElement) _then) = _$MarkerElementCopyWithImpl;
@override @useResult
$Res call({
 String id, BoardPoint at, MarkerSide side, String label, PlayerId? playerId
});




}
/// @nodoc
class _$MarkerElementCopyWithImpl<$Res>
    implements $MarkerElementCopyWith<$Res> {
  _$MarkerElementCopyWithImpl(this._self, this._then);

  final MarkerElement _self;
  final $Res Function(MarkerElement) _then;

/// Create a copy of BoardElement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? at = null,Object? side = null,Object? label = null,Object? playerId = freezed,}) {
  return _then(MarkerElement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as BoardPoint,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as MarkerSide,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,playerId: freezed == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as PlayerId?,
  ));
}


}

/// @nodoc


class ArrowElement implements BoardElement {
  const ArrowElement({required this.id, required this.kind, required  List<BoardPoint> points}): _points = points;
  

@override final  String id;
 final  ArrowKind kind;
 final  List<BoardPoint> _points;
 List<BoardPoint> get points {
  if (_points is EqualUnmodifiableListView) return _points;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_points);
}


/// Create a copy of BoardElement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArrowElementCopyWith<ArrowElement> get copyWith => _$ArrowElementCopyWithImpl<ArrowElement>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ArrowElement&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.points, _points));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,kind,const DeepCollectionEquality().hash(_points));
}

@override
String toString() {
    return 'BoardElement.arrow(id: $id, kind: $kind, points: $points)';
}


}

/// @nodoc
abstract mixin class $ArrowElementCopyWith<$Res> implements $BoardElementCopyWith<$Res> {
  factory $ArrowElementCopyWith(ArrowElement value, $Res Function(ArrowElement) _then) = _$ArrowElementCopyWithImpl;
@override @useResult
$Res call({
 String id, ArrowKind kind, List<BoardPoint> points
});




}
/// @nodoc
class _$ArrowElementCopyWithImpl<$Res>
    implements $ArrowElementCopyWith<$Res> {
  _$ArrowElementCopyWithImpl(this._self, this._then);

  final ArrowElement _self;
  final $Res Function(ArrowElement) _then;

/// Create a copy of BoardElement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? points = null,}) {
  return _then(ArrowElement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ArrowKind,points: null == points ? _self._points : points // ignore: cast_nullable_to_non_nullable
as List<BoardPoint>,
  ));
}


}

/// @nodoc


class LineElement implements BoardElement {
  const LineElement({required this.id, required  List<BoardPoint> points}): _points = points;
  

@override final  String id;
 final  List<BoardPoint> _points;
 List<BoardPoint> get points {
  if (_points is EqualUnmodifiableListView) return _points;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_points);
}


/// Create a copy of BoardElement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LineElementCopyWith<LineElement> get copyWith => _$LineElementCopyWithImpl<LineElement>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LineElement&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.points, _points));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_points));
}

@override
String toString() {
    return 'BoardElement.line(id: $id, points: $points)';
}


}

/// @nodoc
abstract mixin class $LineElementCopyWith<$Res> implements $BoardElementCopyWith<$Res> {
  factory $LineElementCopyWith(LineElement value, $Res Function(LineElement) _then) = _$LineElementCopyWithImpl;
@override @useResult
$Res call({
 String id, List<BoardPoint> points
});




}
/// @nodoc
class _$LineElementCopyWithImpl<$Res>
    implements $LineElementCopyWith<$Res> {
  _$LineElementCopyWithImpl(this._self, this._then);

  final LineElement _self;
  final $Res Function(LineElement) _then;

/// Create a copy of BoardElement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? points = null,}) {
  return _then(LineElement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self._points : points // ignore: cast_nullable_to_non_nullable
as List<BoardPoint>,
  ));
}


}

/// @nodoc


class NoteElement implements BoardElement {
  const NoteElement({required this.id, required this.at, required this.text});
  

@override final  String id;
 final  BoardPoint at;
 final  String text;

/// Create a copy of BoardElement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoteElementCopyWith<NoteElement> get copyWith => _$NoteElementCopyWithImpl<NoteElement>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NoteElement&&(identical(other.id, id) || other.id == id)&&(identical(other.at, at) || other.at == at)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,at,text);
}

@override
String toString() {
    return 'BoardElement.note(id: $id, at: $at, text: $text)';
}


}

/// @nodoc
abstract mixin class $NoteElementCopyWith<$Res> implements $BoardElementCopyWith<$Res> {
  factory $NoteElementCopyWith(NoteElement value, $Res Function(NoteElement) _then) = _$NoteElementCopyWithImpl;
@override @useResult
$Res call({
 String id, BoardPoint at, String text
});




}
/// @nodoc
class _$NoteElementCopyWithImpl<$Res>
    implements $NoteElementCopyWith<$Res> {
  _$NoteElementCopyWithImpl(this._self, this._then);

  final NoteElement _self;
  final $Res Function(NoteElement) _then;

/// Create a copy of BoardElement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? at = null,Object? text = null,}) {
  return _then(NoteElement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as BoardPoint,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$PlayStep {

 List<BoardElement> get elements;
/// Create a copy of PlayStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayStepCopyWith<PlayStep> get copyWith => _$PlayStepCopyWithImpl<PlayStep>(this as PlayStep, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlayStep;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayStep&&const DeepCollectionEquality().equals(other.elements, _this.elements));
}


@override
int get hashCode {
  final _this = this as PlayStep;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.elements));
}

@override
String toString() {
  final _this = this as PlayStep;
  return 'PlayStep(elements: ${_this.elements})';
}


}

/// @nodoc
abstract mixin class $PlayStepCopyWith<$Res>  {
  factory $PlayStepCopyWith(PlayStep value, $Res Function(PlayStep) _then) = _$PlayStepCopyWithImpl;
@useResult
$Res call({
 List<BoardElement> elements
});




}
/// @nodoc
class _$PlayStepCopyWithImpl<$Res>
    implements $PlayStepCopyWith<$Res> {
  _$PlayStepCopyWithImpl(this._self, this._then);

  final PlayStep _self;
  final $Res Function(PlayStep) _then;

/// Create a copy of PlayStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? elements = null,}) {
  return _then(PlayStep(
elements: null == elements ? _self.elements : elements // ignore: cast_nullable_to_non_nullable
as List<BoardElement>,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayStep].
extension PlayStepPatterns on PlayStep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayStep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayStep value)  $default,){
final _that = this;
switch (_that) {
case _PlayStep():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayStep value)?  $default,){
final _that = this;
switch (_that) {
case _PlayStep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BoardElement> elements)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayStep() when $default != null:
return $default(_that.elements);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BoardElement> elements)  $default,) {final _that = this;
switch (_that) {
case _PlayStep():
return $default(_that.elements);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BoardElement> elements)?  $default,) {final _that = this;
switch (_that) {
case _PlayStep() when $default != null:
return $default(_that.elements);case _:
  return null;

}
}

}

/// @nodoc


class _PlayStep implements PlayStep {
  const _PlayStep({ List<BoardElement> elements = const <BoardElement>[]}): _elements = elements;
  

 final  List<BoardElement> _elements;
@override@JsonKey() List<BoardElement> get elements {
  if (_elements is EqualUnmodifiableListView) return _elements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_elements);
}


/// Create a copy of PlayStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayStepCopyWith<_PlayStep> get copyWith => __$PlayStepCopyWithImpl<_PlayStep>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayStep&&const DeepCollectionEquality().equals(other.elements, _elements));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_elements));
}

@override
String toString() {
    return 'PlayStep(elements: $elements)';
}


}

/// @nodoc
abstract mixin class _$PlayStepCopyWith<$Res> implements $PlayStepCopyWith<$Res> {
  factory _$PlayStepCopyWith(_PlayStep value, $Res Function(_PlayStep) _then) = __$PlayStepCopyWithImpl;
@override @useResult
$Res call({
 List<BoardElement> elements
});




}
/// @nodoc
class __$PlayStepCopyWithImpl<$Res>
    implements _$PlayStepCopyWith<$Res> {
  __$PlayStepCopyWithImpl(this._self, this._then);

  final _PlayStep _self;
  final $Res Function(_PlayStep) _then;

/// Create a copy of PlayStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? elements = null,}) {
  return _then(_PlayStep(
elements: null == elements ? _self._elements : elements // ignore: cast_nullable_to_non_nullable
as List<BoardElement>,
  ));
}


}

/// @nodoc
mixin _$Play {

 PlayId get id; GroupId get groupId; PlayBoard get board; BoardVariant get variant; String get title; String get note; List<PlayStep> get steps; String? get createdBy; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of Play
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayCopyWith<Play> get copyWith => _$PlayCopyWithImpl<Play>(this as Play, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Play;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Play&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.board, _this.board) || other.board == _this.board)&&(identical(other.variant, _this.variant) || other.variant == _this.variant)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.note, _this.note) || other.note == _this.note)&&const DeepCollectionEquality().equals(other.steps, _this.steps)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}


@override
int get hashCode {
  final _this = this as Play;
  return Object.hash(runtimeType,_this.id,_this.groupId,_this.board,_this.variant,_this.title,_this.note,const DeepCollectionEquality().hash(_this.steps),_this.createdBy,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as Play;
  return 'Play(id: ${_this.id}, groupId: ${_this.groupId}, board: ${_this.board}, variant: ${_this.variant}, title: ${_this.title}, note: ${_this.note}, steps: ${_this.steps}, createdBy: ${_this.createdBy}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $PlayCopyWith<$Res>  {
  factory $PlayCopyWith(Play value, $Res Function(Play) _then) = _$PlayCopyWithImpl;
@useResult
$Res call({
 PlayId id, GroupId groupId, PlayBoard board, BoardVariant variant, String title, String note, List<PlayStep> steps, String? createdBy, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$PlayCopyWithImpl<$Res>
    implements $PlayCopyWith<$Res> {
  _$PlayCopyWithImpl(this._self, this._then);

  final Play _self;
  final $Res Function(Play) _then;

/// Create a copy of Play
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? groupId = null,Object? board = null,Object? variant = null,Object? title = null,Object? note = null,Object? steps = null,Object? createdBy = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(Play(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PlayId,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,board: null == board ? _self.board : board // ignore: cast_nullable_to_non_nullable
as PlayBoard,variant: null == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as BoardVariant,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<PlayStep>,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Play].
extension PlayPatterns on Play {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Play value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Play() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Play value)  $default,){
final _that = this;
switch (_that) {
case _Play():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Play value)?  $default,){
final _that = this;
switch (_that) {
case _Play() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlayId id,  GroupId groupId,  PlayBoard board,  BoardVariant variant,  String title,  String note,  List<PlayStep> steps,  String? createdBy,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Play() when $default != null:
return $default(_that.id,_that.groupId,_that.board,_that.variant,_that.title,_that.note,_that.steps,_that.createdBy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlayId id,  GroupId groupId,  PlayBoard board,  BoardVariant variant,  String title,  String note,  List<PlayStep> steps,  String? createdBy,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Play():
return $default(_that.id,_that.groupId,_that.board,_that.variant,_that.title,_that.note,_that.steps,_that.createdBy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlayId id,  GroupId groupId,  PlayBoard board,  BoardVariant variant,  String title,  String note,  List<PlayStep> steps,  String? createdBy,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Play() when $default != null:
return $default(_that.id,_that.groupId,_that.board,_that.variant,_that.title,_that.note,_that.steps,_that.createdBy,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Play implements Play {
  const _Play({required this.id, required this.groupId, required this.board, required this.variant, required this.title, this.note = '',  List<PlayStep> steps = const <PlayStep>[PlayStep()], this.createdBy, this.createdAt, this.updatedAt}): _steps = steps;
  

@override final  PlayId id;
@override final  GroupId groupId;
@override final  PlayBoard board;
@override final  BoardVariant variant;
@override final  String title;
@override@JsonKey() final  String note;
 final  List<PlayStep> _steps;
@override@JsonKey() List<PlayStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

@override final  String? createdBy;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of Play
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayCopyWith<_Play> get copyWith => __$PlayCopyWithImpl<_Play>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Play&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.board, board) || other.board == board)&&(identical(other.variant, variant) || other.variant == variant)&&(identical(other.title, title) || other.title == title)&&(identical(other.note, note) || other.note == note)&&const DeepCollectionEquality().equals(other.steps, _steps)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,groupId,board,variant,title,note,const DeepCollectionEquality().hash(_steps),createdBy,createdAt,updatedAt);
}

@override
String toString() {
    return 'Play(id: $id, groupId: $groupId, board: $board, variant: $variant, title: $title, note: $note, steps: $steps, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PlayCopyWith<$Res> implements $PlayCopyWith<$Res> {
  factory _$PlayCopyWith(_Play value, $Res Function(_Play) _then) = __$PlayCopyWithImpl;
@override @useResult
$Res call({
 PlayId id, GroupId groupId, PlayBoard board, BoardVariant variant, String title, String note, List<PlayStep> steps, String? createdBy, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$PlayCopyWithImpl<$Res>
    implements _$PlayCopyWith<$Res> {
  __$PlayCopyWithImpl(this._self, this._then);

  final _Play _self;
  final $Res Function(_Play) _then;

/// Create a copy of Play
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? groupId = null,Object? board = null,Object? variant = null,Object? title = null,Object? note = null,Object? steps = null,Object? createdBy = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Play(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PlayId,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as GroupId,board: null == board ? _self.board : board // ignore: cast_nullable_to_non_nullable
as PlayBoard,variant: null == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as BoardVariant,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<PlayStep>,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
