// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feedback.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TripFeedback {

 String get id; String get tripId; String get userId; int get overallRating; String? get highlights; String? get lowlights; bool get wouldRecommend; int? get aiExperienceRating; DateTime? get createdAt;
/// Create a copy of TripFeedback
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripFeedbackCopyWith<TripFeedback> get copyWith => _$TripFeedbackCopyWithImpl<TripFeedback>(this as TripFeedback, _$identity);

  /// Serializes this TripFeedback to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripFeedback&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.overallRating, overallRating) || other.overallRating == overallRating)&&(identical(other.highlights, highlights) || other.highlights == highlights)&&(identical(other.lowlights, lowlights) || other.lowlights == lowlights)&&(identical(other.wouldRecommend, wouldRecommend) || other.wouldRecommend == wouldRecommend)&&(identical(other.aiExperienceRating, aiExperienceRating) || other.aiExperienceRating == aiExperienceRating)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,userId,overallRating,highlights,lowlights,wouldRecommend,aiExperienceRating,createdAt);

@override
String toString() {
  return 'TripFeedback(id: $id, tripId: $tripId, userId: $userId, overallRating: $overallRating, highlights: $highlights, lowlights: $lowlights, wouldRecommend: $wouldRecommend, aiExperienceRating: $aiExperienceRating, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $TripFeedbackCopyWith<$Res>  {
  factory $TripFeedbackCopyWith(TripFeedback value, $Res Function(TripFeedback) _then) = _$TripFeedbackCopyWithImpl;
@useResult
$Res call({
 String id, String tripId, String userId, int overallRating, String? highlights, String? lowlights, bool wouldRecommend, int? aiExperienceRating, DateTime? createdAt
});




}
/// @nodoc
class _$TripFeedbackCopyWithImpl<$Res>
    implements $TripFeedbackCopyWith<$Res> {
  _$TripFeedbackCopyWithImpl(this._self, this._then);

  final TripFeedback _self;
  final $Res Function(TripFeedback) _then;

/// Create a copy of TripFeedback
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? userId = null,Object? overallRating = null,Object? highlights = freezed,Object? lowlights = freezed,Object? wouldRecommend = null,Object? aiExperienceRating = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,overallRating: null == overallRating ? _self.overallRating : overallRating // ignore: cast_nullable_to_non_nullable
as int,highlights: freezed == highlights ? _self.highlights : highlights // ignore: cast_nullable_to_non_nullable
as String?,lowlights: freezed == lowlights ? _self.lowlights : lowlights // ignore: cast_nullable_to_non_nullable
as String?,wouldRecommend: null == wouldRecommend ? _self.wouldRecommend : wouldRecommend // ignore: cast_nullable_to_non_nullable
as bool,aiExperienceRating: freezed == aiExperienceRating ? _self.aiExperienceRating : aiExperienceRating // ignore: cast_nullable_to_non_nullable
as int?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [TripFeedback].
extension TripFeedbackPatterns on TripFeedback {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripFeedback value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripFeedback() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripFeedback value)  $default,){
final _that = this;
switch (_that) {
case _TripFeedback():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripFeedback value)?  $default,){
final _that = this;
switch (_that) {
case _TripFeedback() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tripId,  String userId,  int overallRating,  String? highlights,  String? lowlights,  bool wouldRecommend,  int? aiExperienceRating,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripFeedback() when $default != null:
return $default(_that.id,_that.tripId,_that.userId,_that.overallRating,_that.highlights,_that.lowlights,_that.wouldRecommend,_that.aiExperienceRating,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tripId,  String userId,  int overallRating,  String? highlights,  String? lowlights,  bool wouldRecommend,  int? aiExperienceRating,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _TripFeedback():
return $default(_that.id,_that.tripId,_that.userId,_that.overallRating,_that.highlights,_that.lowlights,_that.wouldRecommend,_that.aiExperienceRating,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tripId,  String userId,  int overallRating,  String? highlights,  String? lowlights,  bool wouldRecommend,  int? aiExperienceRating,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _TripFeedback() when $default != null:
return $default(_that.id,_that.tripId,_that.userId,_that.overallRating,_that.highlights,_that.lowlights,_that.wouldRecommend,_that.aiExperienceRating,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripFeedback implements TripFeedback {
  const _TripFeedback({required this.id, required this.tripId, required this.userId, required this.overallRating, this.highlights, this.lowlights, this.wouldRecommend = false, this.aiExperienceRating, this.createdAt});
  factory _TripFeedback.fromJson(Map<String, dynamic> json) => _$TripFeedbackFromJson(json);

@override final  String id;
@override final  String tripId;
@override final  String userId;
@override final  int overallRating;
@override final  String? highlights;
@override final  String? lowlights;
@override@JsonKey() final  bool wouldRecommend;
@override final  int? aiExperienceRating;
@override final  DateTime? createdAt;

/// Create a copy of TripFeedback
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripFeedbackCopyWith<_TripFeedback> get copyWith => __$TripFeedbackCopyWithImpl<_TripFeedback>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripFeedbackToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripFeedback&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.overallRating, overallRating) || other.overallRating == overallRating)&&(identical(other.highlights, highlights) || other.highlights == highlights)&&(identical(other.lowlights, lowlights) || other.lowlights == lowlights)&&(identical(other.wouldRecommend, wouldRecommend) || other.wouldRecommend == wouldRecommend)&&(identical(other.aiExperienceRating, aiExperienceRating) || other.aiExperienceRating == aiExperienceRating)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,userId,overallRating,highlights,lowlights,wouldRecommend,aiExperienceRating,createdAt);

@override
String toString() {
  return 'TripFeedback(id: $id, tripId: $tripId, userId: $userId, overallRating: $overallRating, highlights: $highlights, lowlights: $lowlights, wouldRecommend: $wouldRecommend, aiExperienceRating: $aiExperienceRating, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$TripFeedbackCopyWith<$Res> implements $TripFeedbackCopyWith<$Res> {
  factory _$TripFeedbackCopyWith(_TripFeedback value, $Res Function(_TripFeedback) _then) = __$TripFeedbackCopyWithImpl;
@override @useResult
$Res call({
 String id, String tripId, String userId, int overallRating, String? highlights, String? lowlights, bool wouldRecommend, int? aiExperienceRating, DateTime? createdAt
});




}
/// @nodoc
class __$TripFeedbackCopyWithImpl<$Res>
    implements _$TripFeedbackCopyWith<$Res> {
  __$TripFeedbackCopyWithImpl(this._self, this._then);

  final _TripFeedback _self;
  final $Res Function(_TripFeedback) _then;

/// Create a copy of TripFeedback
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? userId = null,Object? overallRating = null,Object? highlights = freezed,Object? lowlights = freezed,Object? wouldRecommend = null,Object? aiExperienceRating = freezed,Object? createdAt = freezed,}) {
  return _then(_TripFeedback(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,overallRating: null == overallRating ? _self.overallRating : overallRating // ignore: cast_nullable_to_non_nullable
as int,highlights: freezed == highlights ? _self.highlights : highlights // ignore: cast_nullable_to_non_nullable
as String?,lowlights: freezed == lowlights ? _self.lowlights : lowlights // ignore: cast_nullable_to_non_nullable
as String?,wouldRecommend: null == wouldRecommend ? _self.wouldRecommend : wouldRecommend // ignore: cast_nullable_to_non_nullable
as bool,aiExperienceRating: freezed == aiExperienceRating ? _self.aiExperienceRating : aiExperienceRating // ignore: cast_nullable_to_non_nullable
as int?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
