// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'baggage_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BaggageInfo {

 int? get quantity; int? get weight; String? get weightUnit;
/// Create a copy of BaggageInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BaggageInfoCopyWith<BaggageInfo> get copyWith => _$BaggageInfoCopyWithImpl<BaggageInfo>(this as BaggageInfo, _$identity);

  /// Serializes this BaggageInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BaggageInfo&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.weightUnit, weightUnit) || other.weightUnit == weightUnit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quantity,weight,weightUnit);

@override
String toString() {
  return 'BaggageInfo(quantity: $quantity, weight: $weight, weightUnit: $weightUnit)';
}


}

/// @nodoc
abstract mixin class $BaggageInfoCopyWith<$Res>  {
  factory $BaggageInfoCopyWith(BaggageInfo value, $Res Function(BaggageInfo) _then) = _$BaggageInfoCopyWithImpl;
@useResult
$Res call({
 int? quantity, int? weight, String? weightUnit
});




}
/// @nodoc
class _$BaggageInfoCopyWithImpl<$Res>
    implements $BaggageInfoCopyWith<$Res> {
  _$BaggageInfoCopyWithImpl(this._self, this._then);

  final BaggageInfo _self;
  final $Res Function(BaggageInfo) _then;

/// Create a copy of BaggageInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? quantity = freezed,Object? weight = freezed,Object? weightUnit = freezed,}) {
  return _then(_self.copyWith(
quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int?,weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as int?,weightUnit: freezed == weightUnit ? _self.weightUnit : weightUnit // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BaggageInfo].
extension BaggageInfoPatterns on BaggageInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BaggageInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BaggageInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BaggageInfo value)  $default,){
final _that = this;
switch (_that) {
case _BaggageInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BaggageInfo value)?  $default,){
final _that = this;
switch (_that) {
case _BaggageInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? quantity,  int? weight,  String? weightUnit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BaggageInfo() when $default != null:
return $default(_that.quantity,_that.weight,_that.weightUnit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? quantity,  int? weight,  String? weightUnit)  $default,) {final _that = this;
switch (_that) {
case _BaggageInfo():
return $default(_that.quantity,_that.weight,_that.weightUnit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? quantity,  int? weight,  String? weightUnit)?  $default,) {final _that = this;
switch (_that) {
case _BaggageInfo() when $default != null:
return $default(_that.quantity,_that.weight,_that.weightUnit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BaggageInfo implements BaggageInfo {
  const _BaggageInfo({this.quantity, this.weight, this.weightUnit});
  factory _BaggageInfo.fromJson(Map<String, dynamic> json) => _$BaggageInfoFromJson(json);

@override final  int? quantity;
@override final  int? weight;
@override final  String? weightUnit;

/// Create a copy of BaggageInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BaggageInfoCopyWith<_BaggageInfo> get copyWith => __$BaggageInfoCopyWithImpl<_BaggageInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BaggageInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BaggageInfo&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.weightUnit, weightUnit) || other.weightUnit == weightUnit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quantity,weight,weightUnit);

@override
String toString() {
  return 'BaggageInfo(quantity: $quantity, weight: $weight, weightUnit: $weightUnit)';
}


}

/// @nodoc
abstract mixin class _$BaggageInfoCopyWith<$Res> implements $BaggageInfoCopyWith<$Res> {
  factory _$BaggageInfoCopyWith(_BaggageInfo value, $Res Function(_BaggageInfo) _then) = __$BaggageInfoCopyWithImpl;
@override @useResult
$Res call({
 int? quantity, int? weight, String? weightUnit
});




}
/// @nodoc
class __$BaggageInfoCopyWithImpl<$Res>
    implements _$BaggageInfoCopyWith<$Res> {
  __$BaggageInfoCopyWithImpl(this._self, this._then);

  final _BaggageInfo _self;
  final $Res Function(_BaggageInfo) _then;

/// Create a copy of BaggageInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? quantity = freezed,Object? weight = freezed,Object? weightUnit = freezed,}) {
  return _then(_BaggageInfo(
quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int?,weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as int?,weightUnit: freezed == weightUnit ? _self.weightUnit : weightUnit // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
