// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_grouped.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TripGrouped {

 List<Trip> get ongoing; List<Trip> get planned; List<Trip> get completed;
/// Create a copy of TripGrouped
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripGroupedCopyWith<TripGrouped> get copyWith => _$TripGroupedCopyWithImpl<TripGrouped>(this as TripGrouped, _$identity);

  /// Serializes this TripGrouped to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripGrouped&&const DeepCollectionEquality().equals(other.ongoing, ongoing)&&const DeepCollectionEquality().equals(other.planned, planned)&&const DeepCollectionEquality().equals(other.completed, completed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(ongoing),const DeepCollectionEquality().hash(planned),const DeepCollectionEquality().hash(completed));

@override
String toString() {
  return 'TripGrouped(ongoing: $ongoing, planned: $planned, completed: $completed)';
}


}

/// @nodoc
abstract mixin class $TripGroupedCopyWith<$Res>  {
  factory $TripGroupedCopyWith(TripGrouped value, $Res Function(TripGrouped) _then) = _$TripGroupedCopyWithImpl;
@useResult
$Res call({
 List<Trip> ongoing, List<Trip> planned, List<Trip> completed
});




}
/// @nodoc
class _$TripGroupedCopyWithImpl<$Res>
    implements $TripGroupedCopyWith<$Res> {
  _$TripGroupedCopyWithImpl(this._self, this._then);

  final TripGrouped _self;
  final $Res Function(TripGrouped) _then;

/// Create a copy of TripGrouped
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ongoing = null,Object? planned = null,Object? completed = null,}) {
  return _then(_self.copyWith(
ongoing: null == ongoing ? _self.ongoing : ongoing // ignore: cast_nullable_to_non_nullable
as List<Trip>,planned: null == planned ? _self.planned : planned // ignore: cast_nullable_to_non_nullable
as List<Trip>,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as List<Trip>,
  ));
}

}


/// Adds pattern-matching-related methods to [TripGrouped].
extension TripGroupedPatterns on TripGrouped {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripGrouped value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripGrouped() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripGrouped value)  $default,){
final _that = this;
switch (_that) {
case _TripGrouped():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripGrouped value)?  $default,){
final _that = this;
switch (_that) {
case _TripGrouped() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Trip> ongoing,  List<Trip> planned,  List<Trip> completed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripGrouped() when $default != null:
return $default(_that.ongoing,_that.planned,_that.completed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Trip> ongoing,  List<Trip> planned,  List<Trip> completed)  $default,) {final _that = this;
switch (_that) {
case _TripGrouped():
return $default(_that.ongoing,_that.planned,_that.completed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Trip> ongoing,  List<Trip> planned,  List<Trip> completed)?  $default,) {final _that = this;
switch (_that) {
case _TripGrouped() when $default != null:
return $default(_that.ongoing,_that.planned,_that.completed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripGrouped implements TripGrouped {
  const _TripGrouped({final  List<Trip> ongoing = const [], final  List<Trip> planned = const [], final  List<Trip> completed = const []}): _ongoing = ongoing,_planned = planned,_completed = completed;
  factory _TripGrouped.fromJson(Map<String, dynamic> json) => _$TripGroupedFromJson(json);

 final  List<Trip> _ongoing;
@override@JsonKey() List<Trip> get ongoing {
  if (_ongoing is EqualUnmodifiableListView) return _ongoing;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ongoing);
}

 final  List<Trip> _planned;
@override@JsonKey() List<Trip> get planned {
  if (_planned is EqualUnmodifiableListView) return _planned;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_planned);
}

 final  List<Trip> _completed;
@override@JsonKey() List<Trip> get completed {
  if (_completed is EqualUnmodifiableListView) return _completed;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_completed);
}


/// Create a copy of TripGrouped
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripGroupedCopyWith<_TripGrouped> get copyWith => __$TripGroupedCopyWithImpl<_TripGrouped>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripGroupedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripGrouped&&const DeepCollectionEquality().equals(other._ongoing, _ongoing)&&const DeepCollectionEquality().equals(other._planned, _planned)&&const DeepCollectionEquality().equals(other._completed, _completed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_ongoing),const DeepCollectionEquality().hash(_planned),const DeepCollectionEquality().hash(_completed));

@override
String toString() {
  return 'TripGrouped(ongoing: $ongoing, planned: $planned, completed: $completed)';
}


}

/// @nodoc
abstract mixin class _$TripGroupedCopyWith<$Res> implements $TripGroupedCopyWith<$Res> {
  factory _$TripGroupedCopyWith(_TripGrouped value, $Res Function(_TripGrouped) _then) = __$TripGroupedCopyWithImpl;
@override @useResult
$Res call({
 List<Trip> ongoing, List<Trip> planned, List<Trip> completed
});




}
/// @nodoc
class __$TripGroupedCopyWithImpl<$Res>
    implements _$TripGroupedCopyWith<$Res> {
  __$TripGroupedCopyWithImpl(this._self, this._then);

  final _TripGrouped _self;
  final $Res Function(_TripGrouped) _then;

/// Create a copy of TripGrouped
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ongoing = null,Object? planned = null,Object? completed = null,}) {
  return _then(_TripGrouped(
ongoing: null == ongoing ? _self._ongoing : ongoing // ignore: cast_nullable_to_non_nullable
as List<Trip>,planned: null == planned ? _self._planned : planned // ignore: cast_nullable_to_non_nullable
as List<Trip>,completed: null == completed ? _self._completed : completed // ignore: cast_nullable_to_non_nullable
as List<Trip>,
  ));
}


}

// dart format on
