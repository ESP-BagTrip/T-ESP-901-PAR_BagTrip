// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_method_preview.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaymentMethodPreview {

 String? get brand; String? get last4;@JsonKey(name: 'exp_month') int? get expMonth;@JsonKey(name: 'exp_year') int? get expYear;
/// Create a copy of PaymentMethodPreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentMethodPreviewCopyWith<PaymentMethodPreview> get copyWith => _$PaymentMethodPreviewCopyWithImpl<PaymentMethodPreview>(this as PaymentMethodPreview, _$identity);

  /// Serializes this PaymentMethodPreview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentMethodPreview&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.last4, last4) || other.last4 == last4)&&(identical(other.expMonth, expMonth) || other.expMonth == expMonth)&&(identical(other.expYear, expYear) || other.expYear == expYear));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,brand,last4,expMonth,expYear);

@override
String toString() {
  return 'PaymentMethodPreview(brand: $brand, last4: $last4, expMonth: $expMonth, expYear: $expYear)';
}


}

/// @nodoc
abstract mixin class $PaymentMethodPreviewCopyWith<$Res>  {
  factory $PaymentMethodPreviewCopyWith(PaymentMethodPreview value, $Res Function(PaymentMethodPreview) _then) = _$PaymentMethodPreviewCopyWithImpl;
@useResult
$Res call({
 String? brand, String? last4,@JsonKey(name: 'exp_month') int? expMonth,@JsonKey(name: 'exp_year') int? expYear
});




}
/// @nodoc
class _$PaymentMethodPreviewCopyWithImpl<$Res>
    implements $PaymentMethodPreviewCopyWith<$Res> {
  _$PaymentMethodPreviewCopyWithImpl(this._self, this._then);

  final PaymentMethodPreview _self;
  final $Res Function(PaymentMethodPreview) _then;

/// Create a copy of PaymentMethodPreview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? brand = freezed,Object? last4 = freezed,Object? expMonth = freezed,Object? expYear = freezed,}) {
  return _then(_self.copyWith(
brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,last4: freezed == last4 ? _self.last4 : last4 // ignore: cast_nullable_to_non_nullable
as String?,expMonth: freezed == expMonth ? _self.expMonth : expMonth // ignore: cast_nullable_to_non_nullable
as int?,expYear: freezed == expYear ? _self.expYear : expYear // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentMethodPreview].
extension PaymentMethodPreviewPatterns on PaymentMethodPreview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentMethodPreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentMethodPreview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentMethodPreview value)  $default,){
final _that = this;
switch (_that) {
case _PaymentMethodPreview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentMethodPreview value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentMethodPreview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? brand,  String? last4, @JsonKey(name: 'exp_month')  int? expMonth, @JsonKey(name: 'exp_year')  int? expYear)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentMethodPreview() when $default != null:
return $default(_that.brand,_that.last4,_that.expMonth,_that.expYear);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? brand,  String? last4, @JsonKey(name: 'exp_month')  int? expMonth, @JsonKey(name: 'exp_year')  int? expYear)  $default,) {final _that = this;
switch (_that) {
case _PaymentMethodPreview():
return $default(_that.brand,_that.last4,_that.expMonth,_that.expYear);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? brand,  String? last4, @JsonKey(name: 'exp_month')  int? expMonth, @JsonKey(name: 'exp_year')  int? expYear)?  $default,) {final _that = this;
switch (_that) {
case _PaymentMethodPreview() when $default != null:
return $default(_that.brand,_that.last4,_that.expMonth,_that.expYear);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentMethodPreview extends PaymentMethodPreview {
  const _PaymentMethodPreview({this.brand, this.last4, @JsonKey(name: 'exp_month') this.expMonth, @JsonKey(name: 'exp_year') this.expYear}): super._();
  factory _PaymentMethodPreview.fromJson(Map<String, dynamic> json) => _$PaymentMethodPreviewFromJson(json);

@override final  String? brand;
@override final  String? last4;
@override@JsonKey(name: 'exp_month') final  int? expMonth;
@override@JsonKey(name: 'exp_year') final  int? expYear;

/// Create a copy of PaymentMethodPreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentMethodPreviewCopyWith<_PaymentMethodPreview> get copyWith => __$PaymentMethodPreviewCopyWithImpl<_PaymentMethodPreview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentMethodPreviewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentMethodPreview&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.last4, last4) || other.last4 == last4)&&(identical(other.expMonth, expMonth) || other.expMonth == expMonth)&&(identical(other.expYear, expYear) || other.expYear == expYear));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,brand,last4,expMonth,expYear);

@override
String toString() {
  return 'PaymentMethodPreview(brand: $brand, last4: $last4, expMonth: $expMonth, expYear: $expYear)';
}


}

/// @nodoc
abstract mixin class _$PaymentMethodPreviewCopyWith<$Res> implements $PaymentMethodPreviewCopyWith<$Res> {
  factory _$PaymentMethodPreviewCopyWith(_PaymentMethodPreview value, $Res Function(_PaymentMethodPreview) _then) = __$PaymentMethodPreviewCopyWithImpl;
@override @useResult
$Res call({
 String? brand, String? last4,@JsonKey(name: 'exp_month') int? expMonth,@JsonKey(name: 'exp_year') int? expYear
});




}
/// @nodoc
class __$PaymentMethodPreviewCopyWithImpl<$Res>
    implements _$PaymentMethodPreviewCopyWith<$Res> {
  __$PaymentMethodPreviewCopyWithImpl(this._self, this._then);

  final _PaymentMethodPreview _self;
  final $Res Function(_PaymentMethodPreview) _then;

/// Create a copy of PaymentMethodPreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? brand = freezed,Object? last4 = freezed,Object? expMonth = freezed,Object? expYear = freezed,}) {
  return _then(_PaymentMethodPreview(
brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,last4: freezed == last4 ? _self.last4 : last4 // ignore: cast_nullable_to_non_nullable
as String?,expMonth: freezed == expMonth ? _self.expMonth : expMonth // ignore: cast_nullable_to_non_nullable
as int?,expYear: freezed == expYear ? _self.expYear : expYear // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
