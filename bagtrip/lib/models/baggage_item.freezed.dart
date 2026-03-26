// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'baggage_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BaggageItem {

 String get id; String get tripId; String get name; int? get quantity; bool get isPacked; String? get category; String? get notes; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of BaggageItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BaggageItemCopyWith<BaggageItem> get copyWith => _$BaggageItemCopyWithImpl<BaggageItem>(this as BaggageItem, _$identity);

  /// Serializes this BaggageItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BaggageItem&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.name, name) || other.name == name)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.isPacked, isPacked) || other.isPacked == isPacked)&&(identical(other.category, category) || other.category == category)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,name,quantity,isPacked,category,notes,createdAt,updatedAt);

@override
String toString() {
  return 'BaggageItem(id: $id, tripId: $tripId, name: $name, quantity: $quantity, isPacked: $isPacked, category: $category, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $BaggageItemCopyWith<$Res>  {
  factory $BaggageItemCopyWith(BaggageItem value, $Res Function(BaggageItem) _then) = _$BaggageItemCopyWithImpl;
@useResult
$Res call({
 String id, String tripId, String name, int? quantity, bool isPacked, String? category, String? notes, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$BaggageItemCopyWithImpl<$Res>
    implements $BaggageItemCopyWith<$Res> {
  _$BaggageItemCopyWithImpl(this._self, this._then);

  final BaggageItem _self;
  final $Res Function(BaggageItem) _then;

/// Create a copy of BaggageItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? name = null,Object? quantity = freezed,Object? isPacked = null,Object? category = freezed,Object? notes = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int?,isPacked: null == isPacked ? _self.isPacked : isPacked // ignore: cast_nullable_to_non_nullable
as bool,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [BaggageItem].
extension BaggageItemPatterns on BaggageItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BaggageItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BaggageItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BaggageItem value)  $default,){
final _that = this;
switch (_that) {
case _BaggageItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BaggageItem value)?  $default,){
final _that = this;
switch (_that) {
case _BaggageItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tripId,  String name,  int? quantity,  bool isPacked,  String? category,  String? notes,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BaggageItem() when $default != null:
return $default(_that.id,_that.tripId,_that.name,_that.quantity,_that.isPacked,_that.category,_that.notes,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tripId,  String name,  int? quantity,  bool isPacked,  String? category,  String? notes,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _BaggageItem():
return $default(_that.id,_that.tripId,_that.name,_that.quantity,_that.isPacked,_that.category,_that.notes,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tripId,  String name,  int? quantity,  bool isPacked,  String? category,  String? notes,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _BaggageItem() when $default != null:
return $default(_that.id,_that.tripId,_that.name,_that.quantity,_that.isPacked,_that.category,_that.notes,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BaggageItem implements BaggageItem {
  const _BaggageItem({required this.id, required this.tripId, required this.name, this.quantity, this.isPacked = false, this.category, this.notes, this.createdAt, this.updatedAt});
  factory _BaggageItem.fromJson(Map<String, dynamic> json) => _$BaggageItemFromJson(json);

@override final  String id;
@override final  String tripId;
@override final  String name;
@override final  int? quantity;
@override@JsonKey() final  bool isPacked;
@override final  String? category;
@override final  String? notes;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of BaggageItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BaggageItemCopyWith<_BaggageItem> get copyWith => __$BaggageItemCopyWithImpl<_BaggageItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BaggageItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BaggageItem&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.name, name) || other.name == name)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.isPacked, isPacked) || other.isPacked == isPacked)&&(identical(other.category, category) || other.category == category)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,name,quantity,isPacked,category,notes,createdAt,updatedAt);

@override
String toString() {
  return 'BaggageItem(id: $id, tripId: $tripId, name: $name, quantity: $quantity, isPacked: $isPacked, category: $category, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$BaggageItemCopyWith<$Res> implements $BaggageItemCopyWith<$Res> {
  factory _$BaggageItemCopyWith(_BaggageItem value, $Res Function(_BaggageItem) _then) = __$BaggageItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String tripId, String name, int? quantity, bool isPacked, String? category, String? notes, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$BaggageItemCopyWithImpl<$Res>
    implements _$BaggageItemCopyWith<$Res> {
  __$BaggageItemCopyWithImpl(this._self, this._then);

  final _BaggageItem _self;
  final $Res Function(_BaggageItem) _then;

/// Create a copy of BaggageItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? name = null,Object? quantity = freezed,Object? isPacked = null,Object? category = freezed,Object? notes = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_BaggageItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int?,isPacked: null == isPacked ? _self.isPacked : isPacked // ignore: cast_nullable_to_non_nullable
as bool,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
