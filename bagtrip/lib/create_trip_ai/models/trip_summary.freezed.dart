// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TripSummary {

 String get destination; String get destinationCountry; int get durationDays; int get budgetEur; List<String> get highlights; String get accommodation; List<String> get dayByDayProgram; List<String> get essentialItems;
/// Create a copy of TripSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripSummaryCopyWith<TripSummary> get copyWith => _$TripSummaryCopyWithImpl<TripSummary>(this as TripSummary, _$identity);

  /// Serializes this TripSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripSummary&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.destinationCountry, destinationCountry) || other.destinationCountry == destinationCountry)&&(identical(other.durationDays, durationDays) || other.durationDays == durationDays)&&(identical(other.budgetEur, budgetEur) || other.budgetEur == budgetEur)&&const DeepCollectionEquality().equals(other.highlights, highlights)&&(identical(other.accommodation, accommodation) || other.accommodation == accommodation)&&const DeepCollectionEquality().equals(other.dayByDayProgram, dayByDayProgram)&&const DeepCollectionEquality().equals(other.essentialItems, essentialItems));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,destination,destinationCountry,durationDays,budgetEur,const DeepCollectionEquality().hash(highlights),accommodation,const DeepCollectionEquality().hash(dayByDayProgram),const DeepCollectionEquality().hash(essentialItems));

@override
String toString() {
  return 'TripSummary(destination: $destination, destinationCountry: $destinationCountry, durationDays: $durationDays, budgetEur: $budgetEur, highlights: $highlights, accommodation: $accommodation, dayByDayProgram: $dayByDayProgram, essentialItems: $essentialItems)';
}


}

/// @nodoc
abstract mixin class $TripSummaryCopyWith<$Res>  {
  factory $TripSummaryCopyWith(TripSummary value, $Res Function(TripSummary) _then) = _$TripSummaryCopyWithImpl;
@useResult
$Res call({
 String destination, String destinationCountry, int durationDays, int budgetEur, List<String> highlights, String accommodation, List<String> dayByDayProgram, List<String> essentialItems
});




}
/// @nodoc
class _$TripSummaryCopyWithImpl<$Res>
    implements $TripSummaryCopyWith<$Res> {
  _$TripSummaryCopyWithImpl(this._self, this._then);

  final TripSummary _self;
  final $Res Function(TripSummary) _then;

/// Create a copy of TripSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? destination = null,Object? destinationCountry = null,Object? durationDays = null,Object? budgetEur = null,Object? highlights = null,Object? accommodation = null,Object? dayByDayProgram = null,Object? essentialItems = null,}) {
  return _then(_self.copyWith(
destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,destinationCountry: null == destinationCountry ? _self.destinationCountry : destinationCountry // ignore: cast_nullable_to_non_nullable
as String,durationDays: null == durationDays ? _self.durationDays : durationDays // ignore: cast_nullable_to_non_nullable
as int,budgetEur: null == budgetEur ? _self.budgetEur : budgetEur // ignore: cast_nullable_to_non_nullable
as int,highlights: null == highlights ? _self.highlights : highlights // ignore: cast_nullable_to_non_nullable
as List<String>,accommodation: null == accommodation ? _self.accommodation : accommodation // ignore: cast_nullable_to_non_nullable
as String,dayByDayProgram: null == dayByDayProgram ? _self.dayByDayProgram : dayByDayProgram // ignore: cast_nullable_to_non_nullable
as List<String>,essentialItems: null == essentialItems ? _self.essentialItems : essentialItems // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [TripSummary].
extension TripSummaryPatterns on TripSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripSummary value)  $default,){
final _that = this;
switch (_that) {
case _TripSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripSummary value)?  $default,){
final _that = this;
switch (_that) {
case _TripSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String destination,  String destinationCountry,  int durationDays,  int budgetEur,  List<String> highlights,  String accommodation,  List<String> dayByDayProgram,  List<String> essentialItems)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripSummary() when $default != null:
return $default(_that.destination,_that.destinationCountry,_that.durationDays,_that.budgetEur,_that.highlights,_that.accommodation,_that.dayByDayProgram,_that.essentialItems);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String destination,  String destinationCountry,  int durationDays,  int budgetEur,  List<String> highlights,  String accommodation,  List<String> dayByDayProgram,  List<String> essentialItems)  $default,) {final _that = this;
switch (_that) {
case _TripSummary():
return $default(_that.destination,_that.destinationCountry,_that.durationDays,_that.budgetEur,_that.highlights,_that.accommodation,_that.dayByDayProgram,_that.essentialItems);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String destination,  String destinationCountry,  int durationDays,  int budgetEur,  List<String> highlights,  String accommodation,  List<String> dayByDayProgram,  List<String> essentialItems)?  $default,) {final _that = this;
switch (_that) {
case _TripSummary() when $default != null:
return $default(_that.destination,_that.destinationCountry,_that.durationDays,_that.budgetEur,_that.highlights,_that.accommodation,_that.dayByDayProgram,_that.essentialItems);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripSummary implements TripSummary {
  const _TripSummary({this.destination = '', this.destinationCountry = '', this.durationDays = 0, this.budgetEur = 0, final  List<String> highlights = const [], this.accommodation = '', final  List<String> dayByDayProgram = const [], final  List<String> essentialItems = const []}): _highlights = highlights,_dayByDayProgram = dayByDayProgram,_essentialItems = essentialItems;
  factory _TripSummary.fromJson(Map<String, dynamic> json) => _$TripSummaryFromJson(json);

@override@JsonKey() final  String destination;
@override@JsonKey() final  String destinationCountry;
@override@JsonKey() final  int durationDays;
@override@JsonKey() final  int budgetEur;
 final  List<String> _highlights;
@override@JsonKey() List<String> get highlights {
  if (_highlights is EqualUnmodifiableListView) return _highlights;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_highlights);
}

@override@JsonKey() final  String accommodation;
 final  List<String> _dayByDayProgram;
@override@JsonKey() List<String> get dayByDayProgram {
  if (_dayByDayProgram is EqualUnmodifiableListView) return _dayByDayProgram;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dayByDayProgram);
}

 final  List<String> _essentialItems;
@override@JsonKey() List<String> get essentialItems {
  if (_essentialItems is EqualUnmodifiableListView) return _essentialItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_essentialItems);
}


/// Create a copy of TripSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripSummaryCopyWith<_TripSummary> get copyWith => __$TripSummaryCopyWithImpl<_TripSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripSummary&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.destinationCountry, destinationCountry) || other.destinationCountry == destinationCountry)&&(identical(other.durationDays, durationDays) || other.durationDays == durationDays)&&(identical(other.budgetEur, budgetEur) || other.budgetEur == budgetEur)&&const DeepCollectionEquality().equals(other._highlights, _highlights)&&(identical(other.accommodation, accommodation) || other.accommodation == accommodation)&&const DeepCollectionEquality().equals(other._dayByDayProgram, _dayByDayProgram)&&const DeepCollectionEquality().equals(other._essentialItems, _essentialItems));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,destination,destinationCountry,durationDays,budgetEur,const DeepCollectionEquality().hash(_highlights),accommodation,const DeepCollectionEquality().hash(_dayByDayProgram),const DeepCollectionEquality().hash(_essentialItems));

@override
String toString() {
  return 'TripSummary(destination: $destination, destinationCountry: $destinationCountry, durationDays: $durationDays, budgetEur: $budgetEur, highlights: $highlights, accommodation: $accommodation, dayByDayProgram: $dayByDayProgram, essentialItems: $essentialItems)';
}


}

/// @nodoc
abstract mixin class _$TripSummaryCopyWith<$Res> implements $TripSummaryCopyWith<$Res> {
  factory _$TripSummaryCopyWith(_TripSummary value, $Res Function(_TripSummary) _then) = __$TripSummaryCopyWithImpl;
@override @useResult
$Res call({
 String destination, String destinationCountry, int durationDays, int budgetEur, List<String> highlights, String accommodation, List<String> dayByDayProgram, List<String> essentialItems
});




}
/// @nodoc
class __$TripSummaryCopyWithImpl<$Res>
    implements _$TripSummaryCopyWith<$Res> {
  __$TripSummaryCopyWithImpl(this._self, this._then);

  final _TripSummary _self;
  final $Res Function(_TripSummary) _then;

/// Create a copy of TripSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? destination = null,Object? destinationCountry = null,Object? durationDays = null,Object? budgetEur = null,Object? highlights = null,Object? accommodation = null,Object? dayByDayProgram = null,Object? essentialItems = null,}) {
  return _then(_TripSummary(
destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,destinationCountry: null == destinationCountry ? _self.destinationCountry : destinationCountry // ignore: cast_nullable_to_non_nullable
as String,durationDays: null == durationDays ? _self.durationDays : durationDays // ignore: cast_nullable_to_non_nullable
as int,budgetEur: null == budgetEur ? _self.budgetEur : budgetEur // ignore: cast_nullable_to_non_nullable
as int,highlights: null == highlights ? _self._highlights : highlights // ignore: cast_nullable_to_non_nullable
as List<String>,accommodation: null == accommodation ? _self.accommodation : accommodation // ignore: cast_nullable_to_non_nullable
as String,dayByDayProgram: null == dayByDayProgram ? _self._dayByDayProgram : dayByDayProgram // ignore: cast_nullable_to_non_nullable
as List<String>,essentialItems: null == essentialItems ? _self._essentialItems : essentialItems // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
