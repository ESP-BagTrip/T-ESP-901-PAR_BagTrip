// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'suggested_baggage_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SuggestedBaggageItem {

 String get name; int get quantity; String get category; String? get reason;
/// Create a copy of SuggestedBaggageItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SuggestedBaggageItemCopyWith<SuggestedBaggageItem> get copyWith => _$SuggestedBaggageItemCopyWithImpl<SuggestedBaggageItem>(this as SuggestedBaggageItem, _$identity);

  /// Serializes this SuggestedBaggageItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SuggestedBaggageItem&&(identical(other.name, name) || other.name == name)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.category, category) || other.category == category)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,quantity,category,reason);

@override
String toString() {
  return 'SuggestedBaggageItem(name: $name, quantity: $quantity, category: $category, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $SuggestedBaggageItemCopyWith<$Res>  {
  factory $SuggestedBaggageItemCopyWith(SuggestedBaggageItem value, $Res Function(SuggestedBaggageItem) _then) = _$SuggestedBaggageItemCopyWithImpl;
@useResult
$Res call({
 String name, int quantity, String category, String? reason
});




}
/// @nodoc
class _$SuggestedBaggageItemCopyWithImpl<$Res>
    implements $SuggestedBaggageItemCopyWith<$Res> {
  _$SuggestedBaggageItemCopyWithImpl(this._self, this._then);

  final SuggestedBaggageItem _self;
  final $Res Function(SuggestedBaggageItem) _then;

/// Create a copy of SuggestedBaggageItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? quantity = null,Object? category = null,Object? reason = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SuggestedBaggageItem].
extension SuggestedBaggageItemPatterns on SuggestedBaggageItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SuggestedBaggageItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SuggestedBaggageItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SuggestedBaggageItem value)  $default,){
final _that = this;
switch (_that) {
case _SuggestedBaggageItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SuggestedBaggageItem value)?  $default,){
final _that = this;
switch (_that) {
case _SuggestedBaggageItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  int quantity,  String category,  String? reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SuggestedBaggageItem() when $default != null:
return $default(_that.name,_that.quantity,_that.category,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  int quantity,  String category,  String? reason)  $default,) {final _that = this;
switch (_that) {
case _SuggestedBaggageItem():
return $default(_that.name,_that.quantity,_that.category,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  int quantity,  String category,  String? reason)?  $default,) {final _that = this;
switch (_that) {
case _SuggestedBaggageItem() when $default != null:
return $default(_that.name,_that.quantity,_that.category,_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SuggestedBaggageItem implements SuggestedBaggageItem {
  const _SuggestedBaggageItem({required this.name, this.quantity = 1, this.category = 'Autre', this.reason});
  factory _SuggestedBaggageItem.fromJson(Map<String, dynamic> json) => _$SuggestedBaggageItemFromJson(json);

@override final  String name;
@override@JsonKey() final  int quantity;
@override@JsonKey() final  String category;
@override final  String? reason;

/// Create a copy of SuggestedBaggageItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SuggestedBaggageItemCopyWith<_SuggestedBaggageItem> get copyWith => __$SuggestedBaggageItemCopyWithImpl<_SuggestedBaggageItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SuggestedBaggageItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SuggestedBaggageItem&&(identical(other.name, name) || other.name == name)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.category, category) || other.category == category)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,quantity,category,reason);

@override
String toString() {
  return 'SuggestedBaggageItem(name: $name, quantity: $quantity, category: $category, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$SuggestedBaggageItemCopyWith<$Res> implements $SuggestedBaggageItemCopyWith<$Res> {
  factory _$SuggestedBaggageItemCopyWith(_SuggestedBaggageItem value, $Res Function(_SuggestedBaggageItem) _then) = __$SuggestedBaggageItemCopyWithImpl;
@override @useResult
$Res call({
 String name, int quantity, String category, String? reason
});




}
/// @nodoc
class __$SuggestedBaggageItemCopyWithImpl<$Res>
    implements _$SuggestedBaggageItemCopyWith<$Res> {
  __$SuggestedBaggageItemCopyWithImpl(this._self, this._then);

  final _SuggestedBaggageItem _self;
  final $Res Function(_SuggestedBaggageItem) _then;

/// Create a copy of SuggestedBaggageItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? quantity = null,Object? category = null,Object? reason = freezed,}) {
  return _then(_SuggestedBaggageItem(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
