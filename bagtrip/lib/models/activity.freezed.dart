// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'activity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Activity {

 String get id;@JsonKey(name: 'trip_id') String get tripId; String get title; String? get description; DateTime get date;@JsonKey(name: 'start_time') String? get startTime;@JsonKey(name: 'end_time') String? get endTime; String? get location;@JsonKey(unknownEnumValue: ActivityCategory.other) ActivityCategory get category;@JsonKey(name: 'estimated_cost') double? get estimatedCost;@JsonKey(name: 'is_booked') bool get isBooked;@JsonKey(name: 'validation_status') ValidationStatus get validationStatus; int? get suggestedDay;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivityCopyWith<Activity> get copyWith => _$ActivityCopyWithImpl<Activity>(this as Activity, _$identity);

  /// Serializes this Activity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Activity&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.date, date) || other.date == date)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.location, location) || other.location == location)&&(identical(other.category, category) || other.category == category)&&(identical(other.estimatedCost, estimatedCost) || other.estimatedCost == estimatedCost)&&(identical(other.isBooked, isBooked) || other.isBooked == isBooked)&&(identical(other.validationStatus, validationStatus) || other.validationStatus == validationStatus)&&(identical(other.suggestedDay, suggestedDay) || other.suggestedDay == suggestedDay)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,title,description,date,startTime,endTime,location,category,estimatedCost,isBooked,validationStatus,suggestedDay,createdAt,updatedAt);

@override
String toString() {
  return 'Activity(id: $id, tripId: $tripId, title: $title, description: $description, date: $date, startTime: $startTime, endTime: $endTime, location: $location, category: $category, estimatedCost: $estimatedCost, isBooked: $isBooked, validationStatus: $validationStatus, suggestedDay: $suggestedDay, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ActivityCopyWith<$Res>  {
  factory $ActivityCopyWith(Activity value, $Res Function(Activity) _then) = _$ActivityCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'trip_id') String tripId, String title, String? description, DateTime date,@JsonKey(name: 'start_time') String? startTime,@JsonKey(name: 'end_time') String? endTime, String? location,@JsonKey(unknownEnumValue: ActivityCategory.other) ActivityCategory category,@JsonKey(name: 'estimated_cost') double? estimatedCost,@JsonKey(name: 'is_booked') bool isBooked,@JsonKey(name: 'validation_status') ValidationStatus validationStatus, int? suggestedDay,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$ActivityCopyWithImpl<$Res>
    implements $ActivityCopyWith<$Res> {
  _$ActivityCopyWithImpl(this._self, this._then);

  final Activity _self;
  final $Res Function(Activity) _then;

/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? title = null,Object? description = freezed,Object? date = null,Object? startTime = freezed,Object? endTime = freezed,Object? location = freezed,Object? category = null,Object? estimatedCost = freezed,Object? isBooked = null,Object? validationStatus = null,Object? suggestedDay = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ActivityCategory,estimatedCost: freezed == estimatedCost ? _self.estimatedCost : estimatedCost // ignore: cast_nullable_to_non_nullable
as double?,isBooked: null == isBooked ? _self.isBooked : isBooked // ignore: cast_nullable_to_non_nullable
as bool,validationStatus: null == validationStatus ? _self.validationStatus : validationStatus // ignore: cast_nullable_to_non_nullable
as ValidationStatus,suggestedDay: freezed == suggestedDay ? _self.suggestedDay : suggestedDay // ignore: cast_nullable_to_non_nullable
as int?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Activity].
extension ActivityPatterns on Activity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Activity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Activity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Activity value)  $default,){
final _that = this;
switch (_that) {
case _Activity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Activity value)?  $default,){
final _that = this;
switch (_that) {
case _Activity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'trip_id')  String tripId,  String title,  String? description,  DateTime date, @JsonKey(name: 'start_time')  String? startTime, @JsonKey(name: 'end_time')  String? endTime,  String? location, @JsonKey(unknownEnumValue: ActivityCategory.other)  ActivityCategory category, @JsonKey(name: 'estimated_cost')  double? estimatedCost, @JsonKey(name: 'is_booked')  bool isBooked, @JsonKey(name: 'validation_status')  ValidationStatus validationStatus,  int? suggestedDay, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Activity() when $default != null:
return $default(_that.id,_that.tripId,_that.title,_that.description,_that.date,_that.startTime,_that.endTime,_that.location,_that.category,_that.estimatedCost,_that.isBooked,_that.validationStatus,_that.suggestedDay,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'trip_id')  String tripId,  String title,  String? description,  DateTime date, @JsonKey(name: 'start_time')  String? startTime, @JsonKey(name: 'end_time')  String? endTime,  String? location, @JsonKey(unknownEnumValue: ActivityCategory.other)  ActivityCategory category, @JsonKey(name: 'estimated_cost')  double? estimatedCost, @JsonKey(name: 'is_booked')  bool isBooked, @JsonKey(name: 'validation_status')  ValidationStatus validationStatus,  int? suggestedDay, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Activity():
return $default(_that.id,_that.tripId,_that.title,_that.description,_that.date,_that.startTime,_that.endTime,_that.location,_that.category,_that.estimatedCost,_that.isBooked,_that.validationStatus,_that.suggestedDay,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'trip_id')  String tripId,  String title,  String? description,  DateTime date, @JsonKey(name: 'start_time')  String? startTime, @JsonKey(name: 'end_time')  String? endTime,  String? location, @JsonKey(unknownEnumValue: ActivityCategory.other)  ActivityCategory category, @JsonKey(name: 'estimated_cost')  double? estimatedCost, @JsonKey(name: 'is_booked')  bool isBooked, @JsonKey(name: 'validation_status')  ValidationStatus validationStatus,  int? suggestedDay, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Activity() when $default != null:
return $default(_that.id,_that.tripId,_that.title,_that.description,_that.date,_that.startTime,_that.endTime,_that.location,_that.category,_that.estimatedCost,_that.isBooked,_that.validationStatus,_that.suggestedDay,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Activity implements Activity {
  const _Activity({required this.id, @JsonKey(name: 'trip_id') required this.tripId, required this.title, this.description, required this.date, @JsonKey(name: 'start_time') this.startTime, @JsonKey(name: 'end_time') this.endTime, this.location, @JsonKey(unknownEnumValue: ActivityCategory.other) this.category = ActivityCategory.other, @JsonKey(name: 'estimated_cost') this.estimatedCost, @JsonKey(name: 'is_booked') this.isBooked = false, @JsonKey(name: 'validation_status') this.validationStatus = ValidationStatus.manual, this.suggestedDay, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt});
  factory _Activity.fromJson(Map<String, dynamic> json) => _$ActivityFromJson(json);

@override final  String id;
@override@JsonKey(name: 'trip_id') final  String tripId;
@override final  String title;
@override final  String? description;
@override final  DateTime date;
@override@JsonKey(name: 'start_time') final  String? startTime;
@override@JsonKey(name: 'end_time') final  String? endTime;
@override final  String? location;
@override@JsonKey(unknownEnumValue: ActivityCategory.other) final  ActivityCategory category;
@override@JsonKey(name: 'estimated_cost') final  double? estimatedCost;
@override@JsonKey(name: 'is_booked') final  bool isBooked;
@override@JsonKey(name: 'validation_status') final  ValidationStatus validationStatus;
@override final  int? suggestedDay;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivityCopyWith<_Activity> get copyWith => __$ActivityCopyWithImpl<_Activity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActivityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Activity&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.date, date) || other.date == date)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.location, location) || other.location == location)&&(identical(other.category, category) || other.category == category)&&(identical(other.estimatedCost, estimatedCost) || other.estimatedCost == estimatedCost)&&(identical(other.isBooked, isBooked) || other.isBooked == isBooked)&&(identical(other.validationStatus, validationStatus) || other.validationStatus == validationStatus)&&(identical(other.suggestedDay, suggestedDay) || other.suggestedDay == suggestedDay)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,title,description,date,startTime,endTime,location,category,estimatedCost,isBooked,validationStatus,suggestedDay,createdAt,updatedAt);

@override
String toString() {
  return 'Activity(id: $id, tripId: $tripId, title: $title, description: $description, date: $date, startTime: $startTime, endTime: $endTime, location: $location, category: $category, estimatedCost: $estimatedCost, isBooked: $isBooked, validationStatus: $validationStatus, suggestedDay: $suggestedDay, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ActivityCopyWith<$Res> implements $ActivityCopyWith<$Res> {
  factory _$ActivityCopyWith(_Activity value, $Res Function(_Activity) _then) = __$ActivityCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'trip_id') String tripId, String title, String? description, DateTime date,@JsonKey(name: 'start_time') String? startTime,@JsonKey(name: 'end_time') String? endTime, String? location,@JsonKey(unknownEnumValue: ActivityCategory.other) ActivityCategory category,@JsonKey(name: 'estimated_cost') double? estimatedCost,@JsonKey(name: 'is_booked') bool isBooked,@JsonKey(name: 'validation_status') ValidationStatus validationStatus, int? suggestedDay,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$ActivityCopyWithImpl<$Res>
    implements _$ActivityCopyWith<$Res> {
  __$ActivityCopyWithImpl(this._self, this._then);

  final _Activity _self;
  final $Res Function(_Activity) _then;

/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? title = null,Object? description = freezed,Object? date = null,Object? startTime = freezed,Object? endTime = freezed,Object? location = freezed,Object? category = null,Object? estimatedCost = freezed,Object? isBooked = null,Object? validationStatus = null,Object? suggestedDay = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Activity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ActivityCategory,estimatedCost: freezed == estimatedCost ? _self.estimatedCost : estimatedCost // ignore: cast_nullable_to_non_nullable
as double?,isBooked: null == isBooked ? _self.isBooked : isBooked // ignore: cast_nullable_to_non_nullable
as bool,validationStatus: null == validationStatus ? _self.validationStatus : validationStatus // ignore: cast_nullable_to_non_nullable
as ValidationStatus,suggestedDay: freezed == suggestedDay ? _self.suggestedDay : suggestedDay // ignore: cast_nullable_to_non_nullable
as int?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
