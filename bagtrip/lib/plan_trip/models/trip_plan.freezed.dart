// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TripPlan {

// Destination
 String get destinationCity; String get destinationCountry; String? get destinationIata;// Trip info
 int get durationDays;// Topic 03 (B5) — kept as `double` so the SSE breakdown stays
// precise. The wizard used to cast each category `.toInt()` before
// summing, losing up to ~2.50 € on a 5-category plan.
 double get budgetEur; List<String> get highlights;// Accommodation
 String get accommodationName; String get accommodationSubtitle; double get accommodationPrice; String get accommodationSource;// Flight
 String get flightRoute; String get flightDetails; double get flightPrice; String get flightSource;// Flight offer details (from Amadeus)
 String get originIata; String get flightAirline; String get flightNumber; String get flightDeparture; String get flightArrival; String get flightDuration; String get returnDeparture; String get returnArrival; String get returnDuration;// Day-by-day
 List<String> get dayProgram; List<String> get dayDescriptions; List<String> get dayCategories;// Baggage
 List<String> get essentialItems; List<String> get essentialReasons;// Hotel rating
 int get hotelRating;// Budget breakdown
 Map<String, dynamic> get budgetBreakdown;// Weather
 Map<String, dynamic> get weatherData;
/// Create a copy of TripPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripPlanCopyWith<TripPlan> get copyWith => _$TripPlanCopyWithImpl<TripPlan>(this as TripPlan, _$identity);

  /// Serializes this TripPlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripPlan&&(identical(other.destinationCity, destinationCity) || other.destinationCity == destinationCity)&&(identical(other.destinationCountry, destinationCountry) || other.destinationCountry == destinationCountry)&&(identical(other.destinationIata, destinationIata) || other.destinationIata == destinationIata)&&(identical(other.durationDays, durationDays) || other.durationDays == durationDays)&&(identical(other.budgetEur, budgetEur) || other.budgetEur == budgetEur)&&const DeepCollectionEquality().equals(other.highlights, highlights)&&(identical(other.accommodationName, accommodationName) || other.accommodationName == accommodationName)&&(identical(other.accommodationSubtitle, accommodationSubtitle) || other.accommodationSubtitle == accommodationSubtitle)&&(identical(other.accommodationPrice, accommodationPrice) || other.accommodationPrice == accommodationPrice)&&(identical(other.accommodationSource, accommodationSource) || other.accommodationSource == accommodationSource)&&(identical(other.flightRoute, flightRoute) || other.flightRoute == flightRoute)&&(identical(other.flightDetails, flightDetails) || other.flightDetails == flightDetails)&&(identical(other.flightPrice, flightPrice) || other.flightPrice == flightPrice)&&(identical(other.flightSource, flightSource) || other.flightSource == flightSource)&&(identical(other.originIata, originIata) || other.originIata == originIata)&&(identical(other.flightAirline, flightAirline) || other.flightAirline == flightAirline)&&(identical(other.flightNumber, flightNumber) || other.flightNumber == flightNumber)&&(identical(other.flightDeparture, flightDeparture) || other.flightDeparture == flightDeparture)&&(identical(other.flightArrival, flightArrival) || other.flightArrival == flightArrival)&&(identical(other.flightDuration, flightDuration) || other.flightDuration == flightDuration)&&(identical(other.returnDeparture, returnDeparture) || other.returnDeparture == returnDeparture)&&(identical(other.returnArrival, returnArrival) || other.returnArrival == returnArrival)&&(identical(other.returnDuration, returnDuration) || other.returnDuration == returnDuration)&&const DeepCollectionEquality().equals(other.dayProgram, dayProgram)&&const DeepCollectionEquality().equals(other.dayDescriptions, dayDescriptions)&&const DeepCollectionEquality().equals(other.dayCategories, dayCategories)&&const DeepCollectionEquality().equals(other.essentialItems, essentialItems)&&const DeepCollectionEquality().equals(other.essentialReasons, essentialReasons)&&(identical(other.hotelRating, hotelRating) || other.hotelRating == hotelRating)&&const DeepCollectionEquality().equals(other.budgetBreakdown, budgetBreakdown)&&const DeepCollectionEquality().equals(other.weatherData, weatherData));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,destinationCity,destinationCountry,destinationIata,durationDays,budgetEur,const DeepCollectionEquality().hash(highlights),accommodationName,accommodationSubtitle,accommodationPrice,accommodationSource,flightRoute,flightDetails,flightPrice,flightSource,originIata,flightAirline,flightNumber,flightDeparture,flightArrival,flightDuration,returnDeparture,returnArrival,returnDuration,const DeepCollectionEquality().hash(dayProgram),const DeepCollectionEquality().hash(dayDescriptions),const DeepCollectionEquality().hash(dayCategories),const DeepCollectionEquality().hash(essentialItems),const DeepCollectionEquality().hash(essentialReasons),hotelRating,const DeepCollectionEquality().hash(budgetBreakdown),const DeepCollectionEquality().hash(weatherData)]);

@override
String toString() {
  return 'TripPlan(destinationCity: $destinationCity, destinationCountry: $destinationCountry, destinationIata: $destinationIata, durationDays: $durationDays, budgetEur: $budgetEur, highlights: $highlights, accommodationName: $accommodationName, accommodationSubtitle: $accommodationSubtitle, accommodationPrice: $accommodationPrice, accommodationSource: $accommodationSource, flightRoute: $flightRoute, flightDetails: $flightDetails, flightPrice: $flightPrice, flightSource: $flightSource, originIata: $originIata, flightAirline: $flightAirline, flightNumber: $flightNumber, flightDeparture: $flightDeparture, flightArrival: $flightArrival, flightDuration: $flightDuration, returnDeparture: $returnDeparture, returnArrival: $returnArrival, returnDuration: $returnDuration, dayProgram: $dayProgram, dayDescriptions: $dayDescriptions, dayCategories: $dayCategories, essentialItems: $essentialItems, essentialReasons: $essentialReasons, hotelRating: $hotelRating, budgetBreakdown: $budgetBreakdown, weatherData: $weatherData)';
}


}

/// @nodoc
abstract mixin class $TripPlanCopyWith<$Res>  {
  factory $TripPlanCopyWith(TripPlan value, $Res Function(TripPlan) _then) = _$TripPlanCopyWithImpl;
@useResult
$Res call({
 String destinationCity, String destinationCountry, String? destinationIata, int durationDays, double budgetEur, List<String> highlights, String accommodationName, String accommodationSubtitle, double accommodationPrice, String accommodationSource, String flightRoute, String flightDetails, double flightPrice, String flightSource, String originIata, String flightAirline, String flightNumber, String flightDeparture, String flightArrival, String flightDuration, String returnDeparture, String returnArrival, String returnDuration, List<String> dayProgram, List<String> dayDescriptions, List<String> dayCategories, List<String> essentialItems, List<String> essentialReasons, int hotelRating, Map<String, dynamic> budgetBreakdown, Map<String, dynamic> weatherData
});




}
/// @nodoc
class _$TripPlanCopyWithImpl<$Res>
    implements $TripPlanCopyWith<$Res> {
  _$TripPlanCopyWithImpl(this._self, this._then);

  final TripPlan _self;
  final $Res Function(TripPlan) _then;

/// Create a copy of TripPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? destinationCity = null,Object? destinationCountry = null,Object? destinationIata = freezed,Object? durationDays = null,Object? budgetEur = null,Object? highlights = null,Object? accommodationName = null,Object? accommodationSubtitle = null,Object? accommodationPrice = null,Object? accommodationSource = null,Object? flightRoute = null,Object? flightDetails = null,Object? flightPrice = null,Object? flightSource = null,Object? originIata = null,Object? flightAirline = null,Object? flightNumber = null,Object? flightDeparture = null,Object? flightArrival = null,Object? flightDuration = null,Object? returnDeparture = null,Object? returnArrival = null,Object? returnDuration = null,Object? dayProgram = null,Object? dayDescriptions = null,Object? dayCategories = null,Object? essentialItems = null,Object? essentialReasons = null,Object? hotelRating = null,Object? budgetBreakdown = null,Object? weatherData = null,}) {
  return _then(_self.copyWith(
destinationCity: null == destinationCity ? _self.destinationCity : destinationCity // ignore: cast_nullable_to_non_nullable
as String,destinationCountry: null == destinationCountry ? _self.destinationCountry : destinationCountry // ignore: cast_nullable_to_non_nullable
as String,destinationIata: freezed == destinationIata ? _self.destinationIata : destinationIata // ignore: cast_nullable_to_non_nullable
as String?,durationDays: null == durationDays ? _self.durationDays : durationDays // ignore: cast_nullable_to_non_nullable
as int,budgetEur: null == budgetEur ? _self.budgetEur : budgetEur // ignore: cast_nullable_to_non_nullable
as double,highlights: null == highlights ? _self.highlights : highlights // ignore: cast_nullable_to_non_nullable
as List<String>,accommodationName: null == accommodationName ? _self.accommodationName : accommodationName // ignore: cast_nullable_to_non_nullable
as String,accommodationSubtitle: null == accommodationSubtitle ? _self.accommodationSubtitle : accommodationSubtitle // ignore: cast_nullable_to_non_nullable
as String,accommodationPrice: null == accommodationPrice ? _self.accommodationPrice : accommodationPrice // ignore: cast_nullable_to_non_nullable
as double,accommodationSource: null == accommodationSource ? _self.accommodationSource : accommodationSource // ignore: cast_nullable_to_non_nullable
as String,flightRoute: null == flightRoute ? _self.flightRoute : flightRoute // ignore: cast_nullable_to_non_nullable
as String,flightDetails: null == flightDetails ? _self.flightDetails : flightDetails // ignore: cast_nullable_to_non_nullable
as String,flightPrice: null == flightPrice ? _self.flightPrice : flightPrice // ignore: cast_nullable_to_non_nullable
as double,flightSource: null == flightSource ? _self.flightSource : flightSource // ignore: cast_nullable_to_non_nullable
as String,originIata: null == originIata ? _self.originIata : originIata // ignore: cast_nullable_to_non_nullable
as String,flightAirline: null == flightAirline ? _self.flightAirline : flightAirline // ignore: cast_nullable_to_non_nullable
as String,flightNumber: null == flightNumber ? _self.flightNumber : flightNumber // ignore: cast_nullable_to_non_nullable
as String,flightDeparture: null == flightDeparture ? _self.flightDeparture : flightDeparture // ignore: cast_nullable_to_non_nullable
as String,flightArrival: null == flightArrival ? _self.flightArrival : flightArrival // ignore: cast_nullable_to_non_nullable
as String,flightDuration: null == flightDuration ? _self.flightDuration : flightDuration // ignore: cast_nullable_to_non_nullable
as String,returnDeparture: null == returnDeparture ? _self.returnDeparture : returnDeparture // ignore: cast_nullable_to_non_nullable
as String,returnArrival: null == returnArrival ? _self.returnArrival : returnArrival // ignore: cast_nullable_to_non_nullable
as String,returnDuration: null == returnDuration ? _self.returnDuration : returnDuration // ignore: cast_nullable_to_non_nullable
as String,dayProgram: null == dayProgram ? _self.dayProgram : dayProgram // ignore: cast_nullable_to_non_nullable
as List<String>,dayDescriptions: null == dayDescriptions ? _self.dayDescriptions : dayDescriptions // ignore: cast_nullable_to_non_nullable
as List<String>,dayCategories: null == dayCategories ? _self.dayCategories : dayCategories // ignore: cast_nullable_to_non_nullable
as List<String>,essentialItems: null == essentialItems ? _self.essentialItems : essentialItems // ignore: cast_nullable_to_non_nullable
as List<String>,essentialReasons: null == essentialReasons ? _self.essentialReasons : essentialReasons // ignore: cast_nullable_to_non_nullable
as List<String>,hotelRating: null == hotelRating ? _self.hotelRating : hotelRating // ignore: cast_nullable_to_non_nullable
as int,budgetBreakdown: null == budgetBreakdown ? _self.budgetBreakdown : budgetBreakdown // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,weatherData: null == weatherData ? _self.weatherData : weatherData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [TripPlan].
extension TripPlanPatterns on TripPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripPlan value)  $default,){
final _that = this;
switch (_that) {
case _TripPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripPlan value)?  $default,){
final _that = this;
switch (_that) {
case _TripPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String destinationCity,  String destinationCountry,  String? destinationIata,  int durationDays,  double budgetEur,  List<String> highlights,  String accommodationName,  String accommodationSubtitle,  double accommodationPrice,  String accommodationSource,  String flightRoute,  String flightDetails,  double flightPrice,  String flightSource,  String originIata,  String flightAirline,  String flightNumber,  String flightDeparture,  String flightArrival,  String flightDuration,  String returnDeparture,  String returnArrival,  String returnDuration,  List<String> dayProgram,  List<String> dayDescriptions,  List<String> dayCategories,  List<String> essentialItems,  List<String> essentialReasons,  int hotelRating,  Map<String, dynamic> budgetBreakdown,  Map<String, dynamic> weatherData)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripPlan() when $default != null:
return $default(_that.destinationCity,_that.destinationCountry,_that.destinationIata,_that.durationDays,_that.budgetEur,_that.highlights,_that.accommodationName,_that.accommodationSubtitle,_that.accommodationPrice,_that.accommodationSource,_that.flightRoute,_that.flightDetails,_that.flightPrice,_that.flightSource,_that.originIata,_that.flightAirline,_that.flightNumber,_that.flightDeparture,_that.flightArrival,_that.flightDuration,_that.returnDeparture,_that.returnArrival,_that.returnDuration,_that.dayProgram,_that.dayDescriptions,_that.dayCategories,_that.essentialItems,_that.essentialReasons,_that.hotelRating,_that.budgetBreakdown,_that.weatherData);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String destinationCity,  String destinationCountry,  String? destinationIata,  int durationDays,  double budgetEur,  List<String> highlights,  String accommodationName,  String accommodationSubtitle,  double accommodationPrice,  String accommodationSource,  String flightRoute,  String flightDetails,  double flightPrice,  String flightSource,  String originIata,  String flightAirline,  String flightNumber,  String flightDeparture,  String flightArrival,  String flightDuration,  String returnDeparture,  String returnArrival,  String returnDuration,  List<String> dayProgram,  List<String> dayDescriptions,  List<String> dayCategories,  List<String> essentialItems,  List<String> essentialReasons,  int hotelRating,  Map<String, dynamic> budgetBreakdown,  Map<String, dynamic> weatherData)  $default,) {final _that = this;
switch (_that) {
case _TripPlan():
return $default(_that.destinationCity,_that.destinationCountry,_that.destinationIata,_that.durationDays,_that.budgetEur,_that.highlights,_that.accommodationName,_that.accommodationSubtitle,_that.accommodationPrice,_that.accommodationSource,_that.flightRoute,_that.flightDetails,_that.flightPrice,_that.flightSource,_that.originIata,_that.flightAirline,_that.flightNumber,_that.flightDeparture,_that.flightArrival,_that.flightDuration,_that.returnDeparture,_that.returnArrival,_that.returnDuration,_that.dayProgram,_that.dayDescriptions,_that.dayCategories,_that.essentialItems,_that.essentialReasons,_that.hotelRating,_that.budgetBreakdown,_that.weatherData);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String destinationCity,  String destinationCountry,  String? destinationIata,  int durationDays,  double budgetEur,  List<String> highlights,  String accommodationName,  String accommodationSubtitle,  double accommodationPrice,  String accommodationSource,  String flightRoute,  String flightDetails,  double flightPrice,  String flightSource,  String originIata,  String flightAirline,  String flightNumber,  String flightDeparture,  String flightArrival,  String flightDuration,  String returnDeparture,  String returnArrival,  String returnDuration,  List<String> dayProgram,  List<String> dayDescriptions,  List<String> dayCategories,  List<String> essentialItems,  List<String> essentialReasons,  int hotelRating,  Map<String, dynamic> budgetBreakdown,  Map<String, dynamic> weatherData)?  $default,) {final _that = this;
switch (_that) {
case _TripPlan() when $default != null:
return $default(_that.destinationCity,_that.destinationCountry,_that.destinationIata,_that.durationDays,_that.budgetEur,_that.highlights,_that.accommodationName,_that.accommodationSubtitle,_that.accommodationPrice,_that.accommodationSource,_that.flightRoute,_that.flightDetails,_that.flightPrice,_that.flightSource,_that.originIata,_that.flightAirline,_that.flightNumber,_that.flightDeparture,_that.flightArrival,_that.flightDuration,_that.returnDeparture,_that.returnArrival,_that.returnDuration,_that.dayProgram,_that.dayDescriptions,_that.dayCategories,_that.essentialItems,_that.essentialReasons,_that.hotelRating,_that.budgetBreakdown,_that.weatherData);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripPlan implements TripPlan {
  const _TripPlan({this.destinationCity = '', this.destinationCountry = '', this.destinationIata, this.durationDays = 7, this.budgetEur = 0.0, final  List<String> highlights = const [], this.accommodationName = '', this.accommodationSubtitle = '', this.accommodationPrice = 0.0, this.accommodationSource = 'estimated', this.flightRoute = '', this.flightDetails = '', this.flightPrice = 0.0, this.flightSource = 'estimated', this.originIata = '', this.flightAirline = '', this.flightNumber = '', this.flightDeparture = '', this.flightArrival = '', this.flightDuration = '', this.returnDeparture = '', this.returnArrival = '', this.returnDuration = '', final  List<String> dayProgram = const [], final  List<String> dayDescriptions = const [], final  List<String> dayCategories = const [], final  List<String> essentialItems = const [], final  List<String> essentialReasons = const [], this.hotelRating = 0, final  Map<String, dynamic> budgetBreakdown = const {}, final  Map<String, dynamic> weatherData = const {}}): _highlights = highlights,_dayProgram = dayProgram,_dayDescriptions = dayDescriptions,_dayCategories = dayCategories,_essentialItems = essentialItems,_essentialReasons = essentialReasons,_budgetBreakdown = budgetBreakdown,_weatherData = weatherData;
  factory _TripPlan.fromJson(Map<String, dynamic> json) => _$TripPlanFromJson(json);

// Destination
@override@JsonKey() final  String destinationCity;
@override@JsonKey() final  String destinationCountry;
@override final  String? destinationIata;
// Trip info
@override@JsonKey() final  int durationDays;
// Topic 03 (B5) — kept as `double` so the SSE breakdown stays
// precise. The wizard used to cast each category `.toInt()` before
// summing, losing up to ~2.50 € on a 5-category plan.
@override@JsonKey() final  double budgetEur;
 final  List<String> _highlights;
@override@JsonKey() List<String> get highlights {
  if (_highlights is EqualUnmodifiableListView) return _highlights;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_highlights);
}

// Accommodation
@override@JsonKey() final  String accommodationName;
@override@JsonKey() final  String accommodationSubtitle;
@override@JsonKey() final  double accommodationPrice;
@override@JsonKey() final  String accommodationSource;
// Flight
@override@JsonKey() final  String flightRoute;
@override@JsonKey() final  String flightDetails;
@override@JsonKey() final  double flightPrice;
@override@JsonKey() final  String flightSource;
// Flight offer details (from Amadeus)
@override@JsonKey() final  String originIata;
@override@JsonKey() final  String flightAirline;
@override@JsonKey() final  String flightNumber;
@override@JsonKey() final  String flightDeparture;
@override@JsonKey() final  String flightArrival;
@override@JsonKey() final  String flightDuration;
@override@JsonKey() final  String returnDeparture;
@override@JsonKey() final  String returnArrival;
@override@JsonKey() final  String returnDuration;
// Day-by-day
 final  List<String> _dayProgram;
// Day-by-day
@override@JsonKey() List<String> get dayProgram {
  if (_dayProgram is EqualUnmodifiableListView) return _dayProgram;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dayProgram);
}

 final  List<String> _dayDescriptions;
@override@JsonKey() List<String> get dayDescriptions {
  if (_dayDescriptions is EqualUnmodifiableListView) return _dayDescriptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dayDescriptions);
}

 final  List<String> _dayCategories;
@override@JsonKey() List<String> get dayCategories {
  if (_dayCategories is EqualUnmodifiableListView) return _dayCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dayCategories);
}

// Baggage
 final  List<String> _essentialItems;
// Baggage
@override@JsonKey() List<String> get essentialItems {
  if (_essentialItems is EqualUnmodifiableListView) return _essentialItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_essentialItems);
}

 final  List<String> _essentialReasons;
@override@JsonKey() List<String> get essentialReasons {
  if (_essentialReasons is EqualUnmodifiableListView) return _essentialReasons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_essentialReasons);
}

// Hotel rating
@override@JsonKey() final  int hotelRating;
// Budget breakdown
 final  Map<String, dynamic> _budgetBreakdown;
// Budget breakdown
@override@JsonKey() Map<String, dynamic> get budgetBreakdown {
  if (_budgetBreakdown is EqualUnmodifiableMapView) return _budgetBreakdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_budgetBreakdown);
}

// Weather
 final  Map<String, dynamic> _weatherData;
// Weather
@override@JsonKey() Map<String, dynamic> get weatherData {
  if (_weatherData is EqualUnmodifiableMapView) return _weatherData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_weatherData);
}


/// Create a copy of TripPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripPlanCopyWith<_TripPlan> get copyWith => __$TripPlanCopyWithImpl<_TripPlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripPlanToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripPlan&&(identical(other.destinationCity, destinationCity) || other.destinationCity == destinationCity)&&(identical(other.destinationCountry, destinationCountry) || other.destinationCountry == destinationCountry)&&(identical(other.destinationIata, destinationIata) || other.destinationIata == destinationIata)&&(identical(other.durationDays, durationDays) || other.durationDays == durationDays)&&(identical(other.budgetEur, budgetEur) || other.budgetEur == budgetEur)&&const DeepCollectionEquality().equals(other._highlights, _highlights)&&(identical(other.accommodationName, accommodationName) || other.accommodationName == accommodationName)&&(identical(other.accommodationSubtitle, accommodationSubtitle) || other.accommodationSubtitle == accommodationSubtitle)&&(identical(other.accommodationPrice, accommodationPrice) || other.accommodationPrice == accommodationPrice)&&(identical(other.accommodationSource, accommodationSource) || other.accommodationSource == accommodationSource)&&(identical(other.flightRoute, flightRoute) || other.flightRoute == flightRoute)&&(identical(other.flightDetails, flightDetails) || other.flightDetails == flightDetails)&&(identical(other.flightPrice, flightPrice) || other.flightPrice == flightPrice)&&(identical(other.flightSource, flightSource) || other.flightSource == flightSource)&&(identical(other.originIata, originIata) || other.originIata == originIata)&&(identical(other.flightAirline, flightAirline) || other.flightAirline == flightAirline)&&(identical(other.flightNumber, flightNumber) || other.flightNumber == flightNumber)&&(identical(other.flightDeparture, flightDeparture) || other.flightDeparture == flightDeparture)&&(identical(other.flightArrival, flightArrival) || other.flightArrival == flightArrival)&&(identical(other.flightDuration, flightDuration) || other.flightDuration == flightDuration)&&(identical(other.returnDeparture, returnDeparture) || other.returnDeparture == returnDeparture)&&(identical(other.returnArrival, returnArrival) || other.returnArrival == returnArrival)&&(identical(other.returnDuration, returnDuration) || other.returnDuration == returnDuration)&&const DeepCollectionEquality().equals(other._dayProgram, _dayProgram)&&const DeepCollectionEquality().equals(other._dayDescriptions, _dayDescriptions)&&const DeepCollectionEquality().equals(other._dayCategories, _dayCategories)&&const DeepCollectionEquality().equals(other._essentialItems, _essentialItems)&&const DeepCollectionEquality().equals(other._essentialReasons, _essentialReasons)&&(identical(other.hotelRating, hotelRating) || other.hotelRating == hotelRating)&&const DeepCollectionEquality().equals(other._budgetBreakdown, _budgetBreakdown)&&const DeepCollectionEquality().equals(other._weatherData, _weatherData));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,destinationCity,destinationCountry,destinationIata,durationDays,budgetEur,const DeepCollectionEquality().hash(_highlights),accommodationName,accommodationSubtitle,accommodationPrice,accommodationSource,flightRoute,flightDetails,flightPrice,flightSource,originIata,flightAirline,flightNumber,flightDeparture,flightArrival,flightDuration,returnDeparture,returnArrival,returnDuration,const DeepCollectionEquality().hash(_dayProgram),const DeepCollectionEquality().hash(_dayDescriptions),const DeepCollectionEquality().hash(_dayCategories),const DeepCollectionEquality().hash(_essentialItems),const DeepCollectionEquality().hash(_essentialReasons),hotelRating,const DeepCollectionEquality().hash(_budgetBreakdown),const DeepCollectionEquality().hash(_weatherData)]);

@override
String toString() {
  return 'TripPlan(destinationCity: $destinationCity, destinationCountry: $destinationCountry, destinationIata: $destinationIata, durationDays: $durationDays, budgetEur: $budgetEur, highlights: $highlights, accommodationName: $accommodationName, accommodationSubtitle: $accommodationSubtitle, accommodationPrice: $accommodationPrice, accommodationSource: $accommodationSource, flightRoute: $flightRoute, flightDetails: $flightDetails, flightPrice: $flightPrice, flightSource: $flightSource, originIata: $originIata, flightAirline: $flightAirline, flightNumber: $flightNumber, flightDeparture: $flightDeparture, flightArrival: $flightArrival, flightDuration: $flightDuration, returnDeparture: $returnDeparture, returnArrival: $returnArrival, returnDuration: $returnDuration, dayProgram: $dayProgram, dayDescriptions: $dayDescriptions, dayCategories: $dayCategories, essentialItems: $essentialItems, essentialReasons: $essentialReasons, hotelRating: $hotelRating, budgetBreakdown: $budgetBreakdown, weatherData: $weatherData)';
}


}

/// @nodoc
abstract mixin class _$TripPlanCopyWith<$Res> implements $TripPlanCopyWith<$Res> {
  factory _$TripPlanCopyWith(_TripPlan value, $Res Function(_TripPlan) _then) = __$TripPlanCopyWithImpl;
@override @useResult
$Res call({
 String destinationCity, String destinationCountry, String? destinationIata, int durationDays, double budgetEur, List<String> highlights, String accommodationName, String accommodationSubtitle, double accommodationPrice, String accommodationSource, String flightRoute, String flightDetails, double flightPrice, String flightSource, String originIata, String flightAirline, String flightNumber, String flightDeparture, String flightArrival, String flightDuration, String returnDeparture, String returnArrival, String returnDuration, List<String> dayProgram, List<String> dayDescriptions, List<String> dayCategories, List<String> essentialItems, List<String> essentialReasons, int hotelRating, Map<String, dynamic> budgetBreakdown, Map<String, dynamic> weatherData
});




}
/// @nodoc
class __$TripPlanCopyWithImpl<$Res>
    implements _$TripPlanCopyWith<$Res> {
  __$TripPlanCopyWithImpl(this._self, this._then);

  final _TripPlan _self;
  final $Res Function(_TripPlan) _then;

/// Create a copy of TripPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? destinationCity = null,Object? destinationCountry = null,Object? destinationIata = freezed,Object? durationDays = null,Object? budgetEur = null,Object? highlights = null,Object? accommodationName = null,Object? accommodationSubtitle = null,Object? accommodationPrice = null,Object? accommodationSource = null,Object? flightRoute = null,Object? flightDetails = null,Object? flightPrice = null,Object? flightSource = null,Object? originIata = null,Object? flightAirline = null,Object? flightNumber = null,Object? flightDeparture = null,Object? flightArrival = null,Object? flightDuration = null,Object? returnDeparture = null,Object? returnArrival = null,Object? returnDuration = null,Object? dayProgram = null,Object? dayDescriptions = null,Object? dayCategories = null,Object? essentialItems = null,Object? essentialReasons = null,Object? hotelRating = null,Object? budgetBreakdown = null,Object? weatherData = null,}) {
  return _then(_TripPlan(
destinationCity: null == destinationCity ? _self.destinationCity : destinationCity // ignore: cast_nullable_to_non_nullable
as String,destinationCountry: null == destinationCountry ? _self.destinationCountry : destinationCountry // ignore: cast_nullable_to_non_nullable
as String,destinationIata: freezed == destinationIata ? _self.destinationIata : destinationIata // ignore: cast_nullable_to_non_nullable
as String?,durationDays: null == durationDays ? _self.durationDays : durationDays // ignore: cast_nullable_to_non_nullable
as int,budgetEur: null == budgetEur ? _self.budgetEur : budgetEur // ignore: cast_nullable_to_non_nullable
as double,highlights: null == highlights ? _self._highlights : highlights // ignore: cast_nullable_to_non_nullable
as List<String>,accommodationName: null == accommodationName ? _self.accommodationName : accommodationName // ignore: cast_nullable_to_non_nullable
as String,accommodationSubtitle: null == accommodationSubtitle ? _self.accommodationSubtitle : accommodationSubtitle // ignore: cast_nullable_to_non_nullable
as String,accommodationPrice: null == accommodationPrice ? _self.accommodationPrice : accommodationPrice // ignore: cast_nullable_to_non_nullable
as double,accommodationSource: null == accommodationSource ? _self.accommodationSource : accommodationSource // ignore: cast_nullable_to_non_nullable
as String,flightRoute: null == flightRoute ? _self.flightRoute : flightRoute // ignore: cast_nullable_to_non_nullable
as String,flightDetails: null == flightDetails ? _self.flightDetails : flightDetails // ignore: cast_nullable_to_non_nullable
as String,flightPrice: null == flightPrice ? _self.flightPrice : flightPrice // ignore: cast_nullable_to_non_nullable
as double,flightSource: null == flightSource ? _self.flightSource : flightSource // ignore: cast_nullable_to_non_nullable
as String,originIata: null == originIata ? _self.originIata : originIata // ignore: cast_nullable_to_non_nullable
as String,flightAirline: null == flightAirline ? _self.flightAirline : flightAirline // ignore: cast_nullable_to_non_nullable
as String,flightNumber: null == flightNumber ? _self.flightNumber : flightNumber // ignore: cast_nullable_to_non_nullable
as String,flightDeparture: null == flightDeparture ? _self.flightDeparture : flightDeparture // ignore: cast_nullable_to_non_nullable
as String,flightArrival: null == flightArrival ? _self.flightArrival : flightArrival // ignore: cast_nullable_to_non_nullable
as String,flightDuration: null == flightDuration ? _self.flightDuration : flightDuration // ignore: cast_nullable_to_non_nullable
as String,returnDeparture: null == returnDeparture ? _self.returnDeparture : returnDeparture // ignore: cast_nullable_to_non_nullable
as String,returnArrival: null == returnArrival ? _self.returnArrival : returnArrival // ignore: cast_nullable_to_non_nullable
as String,returnDuration: null == returnDuration ? _self.returnDuration : returnDuration // ignore: cast_nullable_to_non_nullable
as String,dayProgram: null == dayProgram ? _self._dayProgram : dayProgram // ignore: cast_nullable_to_non_nullable
as List<String>,dayDescriptions: null == dayDescriptions ? _self._dayDescriptions : dayDescriptions // ignore: cast_nullable_to_non_nullable
as List<String>,dayCategories: null == dayCategories ? _self._dayCategories : dayCategories // ignore: cast_nullable_to_non_nullable
as List<String>,essentialItems: null == essentialItems ? _self._essentialItems : essentialItems // ignore: cast_nullable_to_non_nullable
as List<String>,essentialReasons: null == essentialReasons ? _self._essentialReasons : essentialReasons // ignore: cast_nullable_to_non_nullable
as List<String>,hotelRating: null == hotelRating ? _self.hotelRating : hotelRating // ignore: cast_nullable_to_non_nullable
as int,budgetBreakdown: null == budgetBreakdown ? _self._budgetBreakdown : budgetBreakdown // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,weatherData: null == weatherData ? _self._weatherData : weatherData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
