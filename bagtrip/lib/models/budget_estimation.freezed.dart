// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget_estimation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BudgetEstimation {

@JsonKey(name: 'accommodationPerNight') double? get accommodationPerNight;@JsonKey(name: 'mealsPerDayPerPerson') double? get mealsPerDayPerPerson;@JsonKey(name: 'localTransportPerDay') double? get localTransportPerDay;@JsonKey(name: 'activitiesTotal') double? get activitiesTotal;@JsonKey(name: 'totalMin') double? get totalMin;@JsonKey(name: 'totalMax') double? get totalMax; String get currency;@JsonKey(name: 'breakdownNotes') String? get breakdownNotes;
/// Create a copy of BudgetEstimation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BudgetEstimationCopyWith<BudgetEstimation> get copyWith => _$BudgetEstimationCopyWithImpl<BudgetEstimation>(this as BudgetEstimation, _$identity);

  /// Serializes this BudgetEstimation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BudgetEstimation&&(identical(other.accommodationPerNight, accommodationPerNight) || other.accommodationPerNight == accommodationPerNight)&&(identical(other.mealsPerDayPerPerson, mealsPerDayPerPerson) || other.mealsPerDayPerPerson == mealsPerDayPerPerson)&&(identical(other.localTransportPerDay, localTransportPerDay) || other.localTransportPerDay == localTransportPerDay)&&(identical(other.activitiesTotal, activitiesTotal) || other.activitiesTotal == activitiesTotal)&&(identical(other.totalMin, totalMin) || other.totalMin == totalMin)&&(identical(other.totalMax, totalMax) || other.totalMax == totalMax)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.breakdownNotes, breakdownNotes) || other.breakdownNotes == breakdownNotes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accommodationPerNight,mealsPerDayPerPerson,localTransportPerDay,activitiesTotal,totalMin,totalMax,currency,breakdownNotes);

@override
String toString() {
  return 'BudgetEstimation(accommodationPerNight: $accommodationPerNight, mealsPerDayPerPerson: $mealsPerDayPerPerson, localTransportPerDay: $localTransportPerDay, activitiesTotal: $activitiesTotal, totalMin: $totalMin, totalMax: $totalMax, currency: $currency, breakdownNotes: $breakdownNotes)';
}


}

/// @nodoc
abstract mixin class $BudgetEstimationCopyWith<$Res>  {
  factory $BudgetEstimationCopyWith(BudgetEstimation value, $Res Function(BudgetEstimation) _then) = _$BudgetEstimationCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'accommodationPerNight') double? accommodationPerNight,@JsonKey(name: 'mealsPerDayPerPerson') double? mealsPerDayPerPerson,@JsonKey(name: 'localTransportPerDay') double? localTransportPerDay,@JsonKey(name: 'activitiesTotal') double? activitiesTotal,@JsonKey(name: 'totalMin') double? totalMin,@JsonKey(name: 'totalMax') double? totalMax, String currency,@JsonKey(name: 'breakdownNotes') String? breakdownNotes
});




}
/// @nodoc
class _$BudgetEstimationCopyWithImpl<$Res>
    implements $BudgetEstimationCopyWith<$Res> {
  _$BudgetEstimationCopyWithImpl(this._self, this._then);

  final BudgetEstimation _self;
  final $Res Function(BudgetEstimation) _then;

/// Create a copy of BudgetEstimation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accommodationPerNight = freezed,Object? mealsPerDayPerPerson = freezed,Object? localTransportPerDay = freezed,Object? activitiesTotal = freezed,Object? totalMin = freezed,Object? totalMax = freezed,Object? currency = null,Object? breakdownNotes = freezed,}) {
  return _then(_self.copyWith(
accommodationPerNight: freezed == accommodationPerNight ? _self.accommodationPerNight : accommodationPerNight // ignore: cast_nullable_to_non_nullable
as double?,mealsPerDayPerPerson: freezed == mealsPerDayPerPerson ? _self.mealsPerDayPerPerson : mealsPerDayPerPerson // ignore: cast_nullable_to_non_nullable
as double?,localTransportPerDay: freezed == localTransportPerDay ? _self.localTransportPerDay : localTransportPerDay // ignore: cast_nullable_to_non_nullable
as double?,activitiesTotal: freezed == activitiesTotal ? _self.activitiesTotal : activitiesTotal // ignore: cast_nullable_to_non_nullable
as double?,totalMin: freezed == totalMin ? _self.totalMin : totalMin // ignore: cast_nullable_to_non_nullable
as double?,totalMax: freezed == totalMax ? _self.totalMax : totalMax // ignore: cast_nullable_to_non_nullable
as double?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,breakdownNotes: freezed == breakdownNotes ? _self.breakdownNotes : breakdownNotes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BudgetEstimation].
extension BudgetEstimationPatterns on BudgetEstimation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BudgetEstimation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BudgetEstimation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BudgetEstimation value)  $default,){
final _that = this;
switch (_that) {
case _BudgetEstimation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BudgetEstimation value)?  $default,){
final _that = this;
switch (_that) {
case _BudgetEstimation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'accommodationPerNight')  double? accommodationPerNight, @JsonKey(name: 'mealsPerDayPerPerson')  double? mealsPerDayPerPerson, @JsonKey(name: 'localTransportPerDay')  double? localTransportPerDay, @JsonKey(name: 'activitiesTotal')  double? activitiesTotal, @JsonKey(name: 'totalMin')  double? totalMin, @JsonKey(name: 'totalMax')  double? totalMax,  String currency, @JsonKey(name: 'breakdownNotes')  String? breakdownNotes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BudgetEstimation() when $default != null:
return $default(_that.accommodationPerNight,_that.mealsPerDayPerPerson,_that.localTransportPerDay,_that.activitiesTotal,_that.totalMin,_that.totalMax,_that.currency,_that.breakdownNotes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'accommodationPerNight')  double? accommodationPerNight, @JsonKey(name: 'mealsPerDayPerPerson')  double? mealsPerDayPerPerson, @JsonKey(name: 'localTransportPerDay')  double? localTransportPerDay, @JsonKey(name: 'activitiesTotal')  double? activitiesTotal, @JsonKey(name: 'totalMin')  double? totalMin, @JsonKey(name: 'totalMax')  double? totalMax,  String currency, @JsonKey(name: 'breakdownNotes')  String? breakdownNotes)  $default,) {final _that = this;
switch (_that) {
case _BudgetEstimation():
return $default(_that.accommodationPerNight,_that.mealsPerDayPerPerson,_that.localTransportPerDay,_that.activitiesTotal,_that.totalMin,_that.totalMax,_that.currency,_that.breakdownNotes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'accommodationPerNight')  double? accommodationPerNight, @JsonKey(name: 'mealsPerDayPerPerson')  double? mealsPerDayPerPerson, @JsonKey(name: 'localTransportPerDay')  double? localTransportPerDay, @JsonKey(name: 'activitiesTotal')  double? activitiesTotal, @JsonKey(name: 'totalMin')  double? totalMin, @JsonKey(name: 'totalMax')  double? totalMax,  String currency, @JsonKey(name: 'breakdownNotes')  String? breakdownNotes)?  $default,) {final _that = this;
switch (_that) {
case _BudgetEstimation() when $default != null:
return $default(_that.accommodationPerNight,_that.mealsPerDayPerPerson,_that.localTransportPerDay,_that.activitiesTotal,_that.totalMin,_that.totalMax,_that.currency,_that.breakdownNotes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BudgetEstimation implements BudgetEstimation {
  const _BudgetEstimation({@JsonKey(name: 'accommodationPerNight') this.accommodationPerNight, @JsonKey(name: 'mealsPerDayPerPerson') this.mealsPerDayPerPerson, @JsonKey(name: 'localTransportPerDay') this.localTransportPerDay, @JsonKey(name: 'activitiesTotal') this.activitiesTotal, @JsonKey(name: 'totalMin') this.totalMin, @JsonKey(name: 'totalMax') this.totalMax, this.currency = 'EUR', @JsonKey(name: 'breakdownNotes') this.breakdownNotes});
  factory _BudgetEstimation.fromJson(Map<String, dynamic> json) => _$BudgetEstimationFromJson(json);

@override@JsonKey(name: 'accommodationPerNight') final  double? accommodationPerNight;
@override@JsonKey(name: 'mealsPerDayPerPerson') final  double? mealsPerDayPerPerson;
@override@JsonKey(name: 'localTransportPerDay') final  double? localTransportPerDay;
@override@JsonKey(name: 'activitiesTotal') final  double? activitiesTotal;
@override@JsonKey(name: 'totalMin') final  double? totalMin;
@override@JsonKey(name: 'totalMax') final  double? totalMax;
@override@JsonKey() final  String currency;
@override@JsonKey(name: 'breakdownNotes') final  String? breakdownNotes;

/// Create a copy of BudgetEstimation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BudgetEstimationCopyWith<_BudgetEstimation> get copyWith => __$BudgetEstimationCopyWithImpl<_BudgetEstimation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BudgetEstimationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BudgetEstimation&&(identical(other.accommodationPerNight, accommodationPerNight) || other.accommodationPerNight == accommodationPerNight)&&(identical(other.mealsPerDayPerPerson, mealsPerDayPerPerson) || other.mealsPerDayPerPerson == mealsPerDayPerPerson)&&(identical(other.localTransportPerDay, localTransportPerDay) || other.localTransportPerDay == localTransportPerDay)&&(identical(other.activitiesTotal, activitiesTotal) || other.activitiesTotal == activitiesTotal)&&(identical(other.totalMin, totalMin) || other.totalMin == totalMin)&&(identical(other.totalMax, totalMax) || other.totalMax == totalMax)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.breakdownNotes, breakdownNotes) || other.breakdownNotes == breakdownNotes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accommodationPerNight,mealsPerDayPerPerson,localTransportPerDay,activitiesTotal,totalMin,totalMax,currency,breakdownNotes);

@override
String toString() {
  return 'BudgetEstimation(accommodationPerNight: $accommodationPerNight, mealsPerDayPerPerson: $mealsPerDayPerPerson, localTransportPerDay: $localTransportPerDay, activitiesTotal: $activitiesTotal, totalMin: $totalMin, totalMax: $totalMax, currency: $currency, breakdownNotes: $breakdownNotes)';
}


}

/// @nodoc
abstract mixin class _$BudgetEstimationCopyWith<$Res> implements $BudgetEstimationCopyWith<$Res> {
  factory _$BudgetEstimationCopyWith(_BudgetEstimation value, $Res Function(_BudgetEstimation) _then) = __$BudgetEstimationCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'accommodationPerNight') double? accommodationPerNight,@JsonKey(name: 'mealsPerDayPerPerson') double? mealsPerDayPerPerson,@JsonKey(name: 'localTransportPerDay') double? localTransportPerDay,@JsonKey(name: 'activitiesTotal') double? activitiesTotal,@JsonKey(name: 'totalMin') double? totalMin,@JsonKey(name: 'totalMax') double? totalMax, String currency,@JsonKey(name: 'breakdownNotes') String? breakdownNotes
});




}
/// @nodoc
class __$BudgetEstimationCopyWithImpl<$Res>
    implements _$BudgetEstimationCopyWith<$Res> {
  __$BudgetEstimationCopyWithImpl(this._self, this._then);

  final _BudgetEstimation _self;
  final $Res Function(_BudgetEstimation) _then;

/// Create a copy of BudgetEstimation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accommodationPerNight = freezed,Object? mealsPerDayPerPerson = freezed,Object? localTransportPerDay = freezed,Object? activitiesTotal = freezed,Object? totalMin = freezed,Object? totalMax = freezed,Object? currency = null,Object? breakdownNotes = freezed,}) {
  return _then(_BudgetEstimation(
accommodationPerNight: freezed == accommodationPerNight ? _self.accommodationPerNight : accommodationPerNight // ignore: cast_nullable_to_non_nullable
as double?,mealsPerDayPerPerson: freezed == mealsPerDayPerPerson ? _self.mealsPerDayPerPerson : mealsPerDayPerPerson // ignore: cast_nullable_to_non_nullable
as double?,localTransportPerDay: freezed == localTransportPerDay ? _self.localTransportPerDay : localTransportPerDay // ignore: cast_nullable_to_non_nullable
as double?,activitiesTotal: freezed == activitiesTotal ? _self.activitiesTotal : activitiesTotal // ignore: cast_nullable_to_non_nullable
as double?,totalMin: freezed == totalMin ? _self.totalMin : totalMin // ignore: cast_nullable_to_non_nullable
as double?,totalMax: freezed == totalMax ? _self.totalMax : totalMax // ignore: cast_nullable_to_non_nullable
as double?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,breakdownNotes: freezed == breakdownNotes ? _self.breakdownNotes : breakdownNotes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
