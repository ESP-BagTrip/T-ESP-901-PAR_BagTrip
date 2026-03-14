// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Trip {

 String get id; String get userId; String? get title; String? get originIata; String? get destinationIata; DateTime? get startDate; DateTime? get endDate;@TripStatusConverter() TripStatus get status; String? get description; String? get destinationName; int? get nbTravelers; String? get coverImageUrl; double? get budgetTotal; String? get origin; String? get role; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripCopyWith<Trip> get copyWith => _$TripCopyWithImpl<Trip>(this as Trip, _$identity);

  /// Serializes this Trip to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Trip&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.title, title) || other.title == title)&&(identical(other.originIata, originIata) || other.originIata == originIata)&&(identical(other.destinationIata, destinationIata) || other.destinationIata == destinationIata)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.description, description) || other.description == description)&&(identical(other.destinationName, destinationName) || other.destinationName == destinationName)&&(identical(other.nbTravelers, nbTravelers) || other.nbTravelers == nbTravelers)&&(identical(other.coverImageUrl, coverImageUrl) || other.coverImageUrl == coverImageUrl)&&(identical(other.budgetTotal, budgetTotal) || other.budgetTotal == budgetTotal)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.role, role) || other.role == role)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,title,originIata,destinationIata,startDate,endDate,status,description,destinationName,nbTravelers,coverImageUrl,budgetTotal,origin,role,createdAt,updatedAt);

@override
String toString() {
  return 'Trip(id: $id, userId: $userId, title: $title, originIata: $originIata, destinationIata: $destinationIata, startDate: $startDate, endDate: $endDate, status: $status, description: $description, destinationName: $destinationName, nbTravelers: $nbTravelers, coverImageUrl: $coverImageUrl, budgetTotal: $budgetTotal, origin: $origin, role: $role, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TripCopyWith<$Res>  {
  factory $TripCopyWith(Trip value, $Res Function(Trip) _then) = _$TripCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String? title, String? originIata, String? destinationIata, DateTime? startDate, DateTime? endDate,@TripStatusConverter() TripStatus status, String? description, String? destinationName, int? nbTravelers, String? coverImageUrl, double? budgetTotal, String? origin, String? role, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$TripCopyWithImpl<$Res>
    implements $TripCopyWith<$Res> {
  _$TripCopyWithImpl(this._self, this._then);

  final Trip _self;
  final $Res Function(Trip) _then;

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? title = freezed,Object? originIata = freezed,Object? destinationIata = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? status = null,Object? description = freezed,Object? destinationName = freezed,Object? nbTravelers = freezed,Object? coverImageUrl = freezed,Object? budgetTotal = freezed,Object? origin = freezed,Object? role = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,originIata: freezed == originIata ? _self.originIata : originIata // ignore: cast_nullable_to_non_nullable
as String?,destinationIata: freezed == destinationIata ? _self.destinationIata : destinationIata // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TripStatus,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,destinationName: freezed == destinationName ? _self.destinationName : destinationName // ignore: cast_nullable_to_non_nullable
as String?,nbTravelers: freezed == nbTravelers ? _self.nbTravelers : nbTravelers // ignore: cast_nullable_to_non_nullable
as int?,coverImageUrl: freezed == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String?,budgetTotal: freezed == budgetTotal ? _self.budgetTotal : budgetTotal // ignore: cast_nullable_to_non_nullable
as double?,origin: freezed == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as String?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Trip].
extension TripPatterns on Trip {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Trip value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Trip() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Trip value)  $default,){
final _that = this;
switch (_that) {
case _Trip():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Trip value)?  $default,){
final _that = this;
switch (_that) {
case _Trip() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String? title,  String? originIata,  String? destinationIata,  DateTime? startDate,  DateTime? endDate, @TripStatusConverter()  TripStatus status,  String? description,  String? destinationName,  int? nbTravelers,  String? coverImageUrl,  double? budgetTotal,  String? origin,  String? role,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Trip() when $default != null:
return $default(_that.id,_that.userId,_that.title,_that.originIata,_that.destinationIata,_that.startDate,_that.endDate,_that.status,_that.description,_that.destinationName,_that.nbTravelers,_that.coverImageUrl,_that.budgetTotal,_that.origin,_that.role,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String? title,  String? originIata,  String? destinationIata,  DateTime? startDate,  DateTime? endDate, @TripStatusConverter()  TripStatus status,  String? description,  String? destinationName,  int? nbTravelers,  String? coverImageUrl,  double? budgetTotal,  String? origin,  String? role,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Trip():
return $default(_that.id,_that.userId,_that.title,_that.originIata,_that.destinationIata,_that.startDate,_that.endDate,_that.status,_that.description,_that.destinationName,_that.nbTravelers,_that.coverImageUrl,_that.budgetTotal,_that.origin,_that.role,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String? title,  String? originIata,  String? destinationIata,  DateTime? startDate,  DateTime? endDate, @TripStatusConverter()  TripStatus status,  String? description,  String? destinationName,  int? nbTravelers,  String? coverImageUrl,  double? budgetTotal,  String? origin,  String? role,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Trip() when $default != null:
return $default(_that.id,_that.userId,_that.title,_that.originIata,_that.destinationIata,_that.startDate,_that.endDate,_that.status,_that.description,_that.destinationName,_that.nbTravelers,_that.coverImageUrl,_that.budgetTotal,_that.origin,_that.role,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Trip implements Trip {
  const _Trip({required this.id, required this.userId, this.title, this.originIata, this.destinationIata, this.startDate, this.endDate, @TripStatusConverter() this.status = TripStatus.draft, this.description, this.destinationName, this.nbTravelers, this.coverImageUrl, this.budgetTotal, this.origin, this.role, this.createdAt, this.updatedAt});
  factory _Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String? title;
@override final  String? originIata;
@override final  String? destinationIata;
@override final  DateTime? startDate;
@override final  DateTime? endDate;
@override@JsonKey()@TripStatusConverter() final  TripStatus status;
@override final  String? description;
@override final  String? destinationName;
@override final  int? nbTravelers;
@override final  String? coverImageUrl;
@override final  double? budgetTotal;
@override final  String? origin;
@override final  String? role;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripCopyWith<_Trip> get copyWith => __$TripCopyWithImpl<_Trip>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Trip&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.title, title) || other.title == title)&&(identical(other.originIata, originIata) || other.originIata == originIata)&&(identical(other.destinationIata, destinationIata) || other.destinationIata == destinationIata)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.description, description) || other.description == description)&&(identical(other.destinationName, destinationName) || other.destinationName == destinationName)&&(identical(other.nbTravelers, nbTravelers) || other.nbTravelers == nbTravelers)&&(identical(other.coverImageUrl, coverImageUrl) || other.coverImageUrl == coverImageUrl)&&(identical(other.budgetTotal, budgetTotal) || other.budgetTotal == budgetTotal)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.role, role) || other.role == role)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,title,originIata,destinationIata,startDate,endDate,status,description,destinationName,nbTravelers,coverImageUrl,budgetTotal,origin,role,createdAt,updatedAt);

@override
String toString() {
  return 'Trip(id: $id, userId: $userId, title: $title, originIata: $originIata, destinationIata: $destinationIata, startDate: $startDate, endDate: $endDate, status: $status, description: $description, destinationName: $destinationName, nbTravelers: $nbTravelers, coverImageUrl: $coverImageUrl, budgetTotal: $budgetTotal, origin: $origin, role: $role, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TripCopyWith<$Res> implements $TripCopyWith<$Res> {
  factory _$TripCopyWith(_Trip value, $Res Function(_Trip) _then) = __$TripCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String? title, String? originIata, String? destinationIata, DateTime? startDate, DateTime? endDate,@TripStatusConverter() TripStatus status, String? description, String? destinationName, int? nbTravelers, String? coverImageUrl, double? budgetTotal, String? origin, String? role, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$TripCopyWithImpl<$Res>
    implements _$TripCopyWith<$Res> {
  __$TripCopyWithImpl(this._self, this._then);

  final _Trip _self;
  final $Res Function(_Trip) _then;

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? title = freezed,Object? originIata = freezed,Object? destinationIata = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? status = null,Object? description = freezed,Object? destinationName = freezed,Object? nbTravelers = freezed,Object? coverImageUrl = freezed,Object? budgetTotal = freezed,Object? origin = freezed,Object? role = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Trip(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,originIata: freezed == originIata ? _self.originIata : originIata // ignore: cast_nullable_to_non_nullable
as String?,destinationIata: freezed == destinationIata ? _self.destinationIata : destinationIata // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TripStatus,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,destinationName: freezed == destinationName ? _self.destinationName : destinationName // ignore: cast_nullable_to_non_nullable
as String?,nbTravelers: freezed == nbTravelers ? _self.nbTravelers : nbTravelers // ignore: cast_nullable_to_non_nullable
as int?,coverImageUrl: freezed == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String?,budgetTotal: freezed == budgetTotal ? _self.budgetTotal : budgetTotal // ignore: cast_nullable_to_non_nullable
as double?,origin: freezed == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as String?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
