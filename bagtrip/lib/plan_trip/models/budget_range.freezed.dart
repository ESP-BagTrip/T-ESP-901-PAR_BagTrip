// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget_range.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BudgetRange {

 double get min; double get max;
/// Create a copy of BudgetRange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BudgetRangeCopyWith<BudgetRange> get copyWith => _$BudgetRangeCopyWithImpl<BudgetRange>(this as BudgetRange, _$identity);

  /// Serializes this BudgetRange to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BudgetRange&&(identical(other.min, min) || other.min == min)&&(identical(other.max, max) || other.max == max));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,min,max);

@override
String toString() {
  return 'BudgetRange(min: $min, max: $max)';
}


}

/// @nodoc
abstract mixin class $BudgetRangeCopyWith<$Res>  {
  factory $BudgetRangeCopyWith(BudgetRange value, $Res Function(BudgetRange) _then) = _$BudgetRangeCopyWithImpl;
@useResult
$Res call({
 double min, double max
});




}
/// @nodoc
class _$BudgetRangeCopyWithImpl<$Res>
    implements $BudgetRangeCopyWith<$Res> {
  _$BudgetRangeCopyWithImpl(this._self, this._then);

  final BudgetRange _self;
  final $Res Function(BudgetRange) _then;

/// Create a copy of BudgetRange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? min = null,Object? max = null,}) {
  return _then(_self.copyWith(
min: null == min ? _self.min : min // ignore: cast_nullable_to_non_nullable
as double,max: null == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [BudgetRange].
extension BudgetRangePatterns on BudgetRange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BudgetRange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BudgetRange() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BudgetRange value)  $default,){
final _that = this;
switch (_that) {
case _BudgetRange():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BudgetRange value)?  $default,){
final _that = this;
switch (_that) {
case _BudgetRange() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double min,  double max)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BudgetRange() when $default != null:
return $default(_that.min,_that.max);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double min,  double max)  $default,) {final _that = this;
switch (_that) {
case _BudgetRange():
return $default(_that.min,_that.max);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double min,  double max)?  $default,) {final _that = this;
switch (_that) {
case _BudgetRange() when $default != null:
return $default(_that.min,_that.max);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BudgetRange implements BudgetRange {
  const _BudgetRange({required this.min, required this.max});
  factory _BudgetRange.fromJson(Map<String, dynamic> json) => _$BudgetRangeFromJson(json);

@override final  double min;
@override final  double max;

/// Create a copy of BudgetRange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BudgetRangeCopyWith<_BudgetRange> get copyWith => __$BudgetRangeCopyWithImpl<_BudgetRange>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BudgetRangeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BudgetRange&&(identical(other.min, min) || other.min == min)&&(identical(other.max, max) || other.max == max));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,min,max);

@override
String toString() {
  return 'BudgetRange(min: $min, max: $max)';
}


}

/// @nodoc
abstract mixin class _$BudgetRangeCopyWith<$Res> implements $BudgetRangeCopyWith<$Res> {
  factory _$BudgetRangeCopyWith(_BudgetRange value, $Res Function(_BudgetRange) _then) = __$BudgetRangeCopyWithImpl;
@override @useResult
$Res call({
 double min, double max
});




}
/// @nodoc
class __$BudgetRangeCopyWithImpl<$Res>
    implements _$BudgetRangeCopyWith<$Res> {
  __$BudgetRangeCopyWithImpl(this._self, this._then);

  final _BudgetRange _self;
  final $Res Function(_BudgetRange) _then;

/// Create a copy of BudgetRange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? min = null,Object? max = null,}) {
  return _then(_BudgetRange(
min: null == min ? _self.min : min // ignore: cast_nullable_to_non_nullable
as double,max: null == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
