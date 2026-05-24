// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget_breakdown.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BudgetBreakdown {

 double get flight; double get accommodation; double get food; double get transport; double get activity; double get other;
/// Create a copy of BudgetBreakdown
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BudgetBreakdownCopyWith<BudgetBreakdown> get copyWith => _$BudgetBreakdownCopyWithImpl<BudgetBreakdown>(this as BudgetBreakdown, _$identity);

  /// Serializes this BudgetBreakdown to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BudgetBreakdown&&(identical(other.flight, flight) || other.flight == flight)&&(identical(other.accommodation, accommodation) || other.accommodation == accommodation)&&(identical(other.food, food) || other.food == food)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.activity, activity) || other.activity == activity)&&(identical(other.other, this.other) || other.other == this.other));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,flight,accommodation,food,transport,activity,other);

@override
String toString() {
  return 'BudgetBreakdown(flight: $flight, accommodation: $accommodation, food: $food, transport: $transport, activity: $activity, other: $other)';
}


}

/// @nodoc
abstract mixin class $BudgetBreakdownCopyWith<$Res>  {
  factory $BudgetBreakdownCopyWith(BudgetBreakdown value, $Res Function(BudgetBreakdown) _then) = _$BudgetBreakdownCopyWithImpl;
@useResult
$Res call({
 double flight, double accommodation, double food, double transport, double activity, double other
});




}
/// @nodoc
class _$BudgetBreakdownCopyWithImpl<$Res>
    implements $BudgetBreakdownCopyWith<$Res> {
  _$BudgetBreakdownCopyWithImpl(this._self, this._then);

  final BudgetBreakdown _self;
  final $Res Function(BudgetBreakdown) _then;

/// Create a copy of BudgetBreakdown
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? flight = null,Object? accommodation = null,Object? food = null,Object? transport = null,Object? activity = null,Object? other = null,}) {
  return _then(_self.copyWith(
flight: null == flight ? _self.flight : flight // ignore: cast_nullable_to_non_nullable
as double,accommodation: null == accommodation ? _self.accommodation : accommodation // ignore: cast_nullable_to_non_nullable
as double,food: null == food ? _self.food : food // ignore: cast_nullable_to_non_nullable
as double,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as double,activity: null == activity ? _self.activity : activity // ignore: cast_nullable_to_non_nullable
as double,other: null == other ? _self.other : other // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [BudgetBreakdown].
extension BudgetBreakdownPatterns on BudgetBreakdown {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BudgetBreakdown value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BudgetBreakdown() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BudgetBreakdown value)  $default,){
final _that = this;
switch (_that) {
case _BudgetBreakdown():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BudgetBreakdown value)?  $default,){
final _that = this;
switch (_that) {
case _BudgetBreakdown() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double flight,  double accommodation,  double food,  double transport,  double activity,  double other)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BudgetBreakdown() when $default != null:
return $default(_that.flight,_that.accommodation,_that.food,_that.transport,_that.activity,_that.other);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double flight,  double accommodation,  double food,  double transport,  double activity,  double other)  $default,) {final _that = this;
switch (_that) {
case _BudgetBreakdown():
return $default(_that.flight,_that.accommodation,_that.food,_that.transport,_that.activity,_that.other);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double flight,  double accommodation,  double food,  double transport,  double activity,  double other)?  $default,) {final _that = this;
switch (_that) {
case _BudgetBreakdown() when $default != null:
return $default(_that.flight,_that.accommodation,_that.food,_that.transport,_that.activity,_that.other);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BudgetBreakdown extends BudgetBreakdown {
  const _BudgetBreakdown({this.flight = 0.0, this.accommodation = 0.0, this.food = 0.0, this.transport = 0.0, this.activity = 0.0, this.other = 0.0}): super._();
  factory _BudgetBreakdown.fromJson(Map<String, dynamic> json) => _$BudgetBreakdownFromJson(json);

@override@JsonKey() final  double flight;
@override@JsonKey() final  double accommodation;
@override@JsonKey() final  double food;
@override@JsonKey() final  double transport;
@override@JsonKey() final  double activity;
@override@JsonKey() final  double other;

/// Create a copy of BudgetBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BudgetBreakdownCopyWith<_BudgetBreakdown> get copyWith => __$BudgetBreakdownCopyWithImpl<_BudgetBreakdown>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BudgetBreakdownToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BudgetBreakdown&&(identical(other.flight, flight) || other.flight == flight)&&(identical(other.accommodation, accommodation) || other.accommodation == accommodation)&&(identical(other.food, food) || other.food == food)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.activity, activity) || other.activity == activity)&&(identical(other.other, this.other) || other.other == this.other));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,flight,accommodation,food,transport,activity,other);

@override
String toString() {
  return 'BudgetBreakdown(flight: $flight, accommodation: $accommodation, food: $food, transport: $transport, activity: $activity, other: $other)';
}


}

/// @nodoc
abstract mixin class _$BudgetBreakdownCopyWith<$Res> implements $BudgetBreakdownCopyWith<$Res> {
  factory _$BudgetBreakdownCopyWith(_BudgetBreakdown value, $Res Function(_BudgetBreakdown) _then) = __$BudgetBreakdownCopyWithImpl;
@override @useResult
$Res call({
 double flight, double accommodation, double food, double transport, double activity, double other
});




}
/// @nodoc
class __$BudgetBreakdownCopyWithImpl<$Res>
    implements _$BudgetBreakdownCopyWith<$Res> {
  __$BudgetBreakdownCopyWithImpl(this._self, this._then);

  final _BudgetBreakdown _self;
  final $Res Function(_BudgetBreakdown) _then;

/// Create a copy of BudgetBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? flight = null,Object? accommodation = null,Object? food = null,Object? transport = null,Object? activity = null,Object? other = null,}) {
  return _then(_BudgetBreakdown(
flight: null == flight ? _self.flight : flight // ignore: cast_nullable_to_non_nullable
as double,accommodation: null == accommodation ? _self.accommodation : accommodation // ignore: cast_nullable_to_non_nullable
as double,food: null == food ? _self.food : food // ignore: cast_nullable_to_non_nullable
as double,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as double,activity: null == activity ? _self.activity : activity // ignore: cast_nullable_to_non_nullable
as double,other: null == other ? _self.other : other // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
