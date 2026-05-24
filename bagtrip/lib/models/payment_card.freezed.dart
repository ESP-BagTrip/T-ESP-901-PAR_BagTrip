// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaymentCard {

 String get id;@JsonKey(name: 'lastFourDigits') String get lastFourDigits;@JsonKey(name: 'expiryDate') String get expiryDate;@JsonKey(name: 'isDefault') bool get isDefault;
/// Create a copy of PaymentCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentCardCopyWith<PaymentCard> get copyWith => _$PaymentCardCopyWithImpl<PaymentCard>(this as PaymentCard, _$identity);

  /// Serializes this PaymentCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentCard&&(identical(other.id, id) || other.id == id)&&(identical(other.lastFourDigits, lastFourDigits) || other.lastFourDigits == lastFourDigits)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,lastFourDigits,expiryDate,isDefault);

@override
String toString() {
  return 'PaymentCard(id: $id, lastFourDigits: $lastFourDigits, expiryDate: $expiryDate, isDefault: $isDefault)';
}


}

/// @nodoc
abstract mixin class $PaymentCardCopyWith<$Res>  {
  factory $PaymentCardCopyWith(PaymentCard value, $Res Function(PaymentCard) _then) = _$PaymentCardCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'lastFourDigits') String lastFourDigits,@JsonKey(name: 'expiryDate') String expiryDate,@JsonKey(name: 'isDefault') bool isDefault
});




}
/// @nodoc
class _$PaymentCardCopyWithImpl<$Res>
    implements $PaymentCardCopyWith<$Res> {
  _$PaymentCardCopyWithImpl(this._self, this._then);

  final PaymentCard _self;
  final $Res Function(PaymentCard) _then;

/// Create a copy of PaymentCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? lastFourDigits = null,Object? expiryDate = null,Object? isDefault = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lastFourDigits: null == lastFourDigits ? _self.lastFourDigits : lastFourDigits // ignore: cast_nullable_to_non_nullable
as String,expiryDate: null == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as String,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentCard].
extension PaymentCardPatterns on PaymentCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentCard value)  $default,){
final _that = this;
switch (_that) {
case _PaymentCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentCard value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'lastFourDigits')  String lastFourDigits, @JsonKey(name: 'expiryDate')  String expiryDate, @JsonKey(name: 'isDefault')  bool isDefault)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentCard() when $default != null:
return $default(_that.id,_that.lastFourDigits,_that.expiryDate,_that.isDefault);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'lastFourDigits')  String lastFourDigits, @JsonKey(name: 'expiryDate')  String expiryDate, @JsonKey(name: 'isDefault')  bool isDefault)  $default,) {final _that = this;
switch (_that) {
case _PaymentCard():
return $default(_that.id,_that.lastFourDigits,_that.expiryDate,_that.isDefault);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'lastFourDigits')  String lastFourDigits, @JsonKey(name: 'expiryDate')  String expiryDate, @JsonKey(name: 'isDefault')  bool isDefault)?  $default,) {final _that = this;
switch (_that) {
case _PaymentCard() when $default != null:
return $default(_that.id,_that.lastFourDigits,_that.expiryDate,_that.isDefault);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentCard implements PaymentCard {
  const _PaymentCard({required this.id, @JsonKey(name: 'lastFourDigits') required this.lastFourDigits, @JsonKey(name: 'expiryDate') required this.expiryDate, @JsonKey(name: 'isDefault') required this.isDefault});
  factory _PaymentCard.fromJson(Map<String, dynamic> json) => _$PaymentCardFromJson(json);

@override final  String id;
@override@JsonKey(name: 'lastFourDigits') final  String lastFourDigits;
@override@JsonKey(name: 'expiryDate') final  String expiryDate;
@override@JsonKey(name: 'isDefault') final  bool isDefault;

/// Create a copy of PaymentCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentCardCopyWith<_PaymentCard> get copyWith => __$PaymentCardCopyWithImpl<_PaymentCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentCardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentCard&&(identical(other.id, id) || other.id == id)&&(identical(other.lastFourDigits, lastFourDigits) || other.lastFourDigits == lastFourDigits)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,lastFourDigits,expiryDate,isDefault);

@override
String toString() {
  return 'PaymentCard(id: $id, lastFourDigits: $lastFourDigits, expiryDate: $expiryDate, isDefault: $isDefault)';
}


}

/// @nodoc
abstract mixin class _$PaymentCardCopyWith<$Res> implements $PaymentCardCopyWith<$Res> {
  factory _$PaymentCardCopyWith(_PaymentCard value, $Res Function(_PaymentCard) _then) = __$PaymentCardCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'lastFourDigits') String lastFourDigits,@JsonKey(name: 'expiryDate') String expiryDate,@JsonKey(name: 'isDefault') bool isDefault
});




}
/// @nodoc
class __$PaymentCardCopyWithImpl<$Res>
    implements _$PaymentCardCopyWith<$Res> {
  __$PaymentCardCopyWithImpl(this._self, this._then);

  final _PaymentCard _self;
  final $Res Function(_PaymentCard) _then;

/// Create a copy of PaymentCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? lastFourDigits = null,Object? expiryDate = null,Object? isDefault = null,}) {
  return _then(_PaymentCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lastFourDigits: null == lastFourDigits ? _self.lastFourDigits : lastFourDigits // ignore: cast_nullable_to_non_nullable
as String,expiryDate: null == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as String,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
