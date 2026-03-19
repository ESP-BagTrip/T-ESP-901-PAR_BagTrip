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

 String get destination; String get destinationCountry; int get durationDays; int get budgetEur; List<String> get highlights; String get accommodation; List<String> get dayByDayProgram; List<String> get essentialItems;// Accommodation details (real data from Amadeus)
 String get accommodationSubtitle; double get accommodationPrice; String get accommodationSource;// Flight details (real data from Amadeus)
 String get flightRoute; String get flightDetails; double get flightPrice; String get flightSource;// Day-by-day descriptions and categories from activities
 List<String> get dayByDayDescriptions; List<String> get dayByDayCategories;// Baggage reasons
 List<String> get essentialReasons;// Budget breakdown
 Map<String, dynamic> get budgetBreakdown;// Weather data
 Map<String, dynamic> get weatherData;
/// Create a copy of TripSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripSummaryCopyWith<TripSummary> get copyWith => _$TripSummaryCopyWithImpl<TripSummary>(this as TripSummary, _$identity);

  /// Serializes this TripSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripSummary&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.destinationCountry, destinationCountry) || other.destinationCountry == destinationCountry)&&(identical(other.durationDays, durationDays) || other.durationDays == durationDays)&&(identical(other.budgetEur, budgetEur) || other.budgetEur == budgetEur)&&const DeepCollectionEquality().equals(other.highlights, highlights)&&(identical(other.accommodation, accommodation) || other.accommodation == accommodation)&&const DeepCollectionEquality().equals(other.dayByDayProgram, dayByDayProgram)&&const DeepCollectionEquality().equals(other.essentialItems, essentialItems)&&(identical(other.accommodationSubtitle, accommodationSubtitle) || other.accommodationSubtitle == accommodationSubtitle)&&(identical(other.accommodationPrice, accommodationPrice) || other.accommodationPrice == accommodationPrice)&&(identical(other.accommodationSource, accommodationSource) || other.accommodationSource == accommodationSource)&&(identical(other.flightRoute, flightRoute) || other.flightRoute == flightRoute)&&(identical(other.flightDetails, flightDetails) || other.flightDetails == flightDetails)&&(identical(other.flightPrice, flightPrice) || other.flightPrice == flightPrice)&&(identical(other.flightSource, flightSource) || other.flightSource == flightSource)&&const DeepCollectionEquality().equals(other.dayByDayDescriptions, dayByDayDescriptions)&&const DeepCollectionEquality().equals(other.dayByDayCategories, dayByDayCategories)&&const DeepCollectionEquality().equals(other.essentialReasons, essentialReasons)&&const DeepCollectionEquality().equals(other.budgetBreakdown, budgetBreakdown)&&const DeepCollectionEquality().equals(other.weatherData, weatherData));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,destination,destinationCountry,durationDays,budgetEur,const DeepCollectionEquality().hash(highlights),accommodation,const DeepCollectionEquality().hash(dayByDayProgram),const DeepCollectionEquality().hash(essentialItems),accommodationSubtitle,accommodationPrice,accommodationSource,flightRoute,flightDetails,flightPrice,flightSource,const DeepCollectionEquality().hash(dayByDayDescriptions),const DeepCollectionEquality().hash(dayByDayCategories),const DeepCollectionEquality().hash(essentialReasons),const DeepCollectionEquality().hash(budgetBreakdown),const DeepCollectionEquality().hash(weatherData)]);

@override
String toString() {
  return 'TripSummary(destination: $destination, destinationCountry: $destinationCountry, durationDays: $durationDays, budgetEur: $budgetEur, highlights: $highlights, accommodation: $accommodation, dayByDayProgram: $dayByDayProgram, essentialItems: $essentialItems, accommodationSubtitle: $accommodationSubtitle, accommodationPrice: $accommodationPrice, accommodationSource: $accommodationSource, flightRoute: $flightRoute, flightDetails: $flightDetails, flightPrice: $flightPrice, flightSource: $flightSource, dayByDayDescriptions: $dayByDayDescriptions, dayByDayCategories: $dayByDayCategories, essentialReasons: $essentialReasons, budgetBreakdown: $budgetBreakdown, weatherData: $weatherData)';
}


}

/// @nodoc
abstract mixin class $TripSummaryCopyWith<$Res>  {
  factory $TripSummaryCopyWith(TripSummary value, $Res Function(TripSummary) _then) = _$TripSummaryCopyWithImpl;
@useResult
$Res call({
 String destination, String destinationCountry, int durationDays, int budgetEur, List<String> highlights, String accommodation, List<String> dayByDayProgram, List<String> essentialItems, String accommodationSubtitle, double accommodationPrice, String accommodationSource, String flightRoute, String flightDetails, double flightPrice, String flightSource, List<String> dayByDayDescriptions, List<String> dayByDayCategories, List<String> essentialReasons, Map<String, dynamic> budgetBreakdown, Map<String, dynamic> weatherData
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
@pragma('vm:prefer-inline') @override $Res call({Object? destination = null,Object? destinationCountry = null,Object? durationDays = null,Object? budgetEur = null,Object? highlights = null,Object? accommodation = null,Object? dayByDayProgram = null,Object? essentialItems = null,Object? accommodationSubtitle = null,Object? accommodationPrice = null,Object? accommodationSource = null,Object? flightRoute = null,Object? flightDetails = null,Object? flightPrice = null,Object? flightSource = null,Object? dayByDayDescriptions = null,Object? dayByDayCategories = null,Object? essentialReasons = null,Object? budgetBreakdown = null,Object? weatherData = null,}) {
  return _then(_self.copyWith(
destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,destinationCountry: null == destinationCountry ? _self.destinationCountry : destinationCountry // ignore: cast_nullable_to_non_nullable
as String,durationDays: null == durationDays ? _self.durationDays : durationDays // ignore: cast_nullable_to_non_nullable
as int,budgetEur: null == budgetEur ? _self.budgetEur : budgetEur // ignore: cast_nullable_to_non_nullable
as int,highlights: null == highlights ? _self.highlights : highlights // ignore: cast_nullable_to_non_nullable
as List<String>,accommodation: null == accommodation ? _self.accommodation : accommodation // ignore: cast_nullable_to_non_nullable
as String,dayByDayProgram: null == dayByDayProgram ? _self.dayByDayProgram : dayByDayProgram // ignore: cast_nullable_to_non_nullable
as List<String>,essentialItems: null == essentialItems ? _self.essentialItems : essentialItems // ignore: cast_nullable_to_non_nullable
as List<String>,accommodationSubtitle: null == accommodationSubtitle ? _self.accommodationSubtitle : accommodationSubtitle // ignore: cast_nullable_to_non_nullable
as String,accommodationPrice: null == accommodationPrice ? _self.accommodationPrice : accommodationPrice // ignore: cast_nullable_to_non_nullable
as double,accommodationSource: null == accommodationSource ? _self.accommodationSource : accommodationSource // ignore: cast_nullable_to_non_nullable
as String,flightRoute: null == flightRoute ? _self.flightRoute : flightRoute // ignore: cast_nullable_to_non_nullable
as String,flightDetails: null == flightDetails ? _self.flightDetails : flightDetails // ignore: cast_nullable_to_non_nullable
as String,flightPrice: null == flightPrice ? _self.flightPrice : flightPrice // ignore: cast_nullable_to_non_nullable
as double,flightSource: null == flightSource ? _self.flightSource : flightSource // ignore: cast_nullable_to_non_nullable
as String,dayByDayDescriptions: null == dayByDayDescriptions ? _self.dayByDayDescriptions : dayByDayDescriptions // ignore: cast_nullable_to_non_nullable
as List<String>,dayByDayCategories: null == dayByDayCategories ? _self.dayByDayCategories : dayByDayCategories // ignore: cast_nullable_to_non_nullable
as List<String>,essentialReasons: null == essentialReasons ? _self.essentialReasons : essentialReasons // ignore: cast_nullable_to_non_nullable
as List<String>,budgetBreakdown: null == budgetBreakdown ? _self.budgetBreakdown : budgetBreakdown // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,weatherData: null == weatherData ? _self.weatherData : weatherData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String destination,  String destinationCountry,  int durationDays,  int budgetEur,  List<String> highlights,  String accommodation,  List<String> dayByDayProgram,  List<String> essentialItems,  String accommodationSubtitle,  double accommodationPrice,  String accommodationSource,  String flightRoute,  String flightDetails,  double flightPrice,  String flightSource,  List<String> dayByDayDescriptions,  List<String> dayByDayCategories,  List<String> essentialReasons,  Map<String, dynamic> budgetBreakdown,  Map<String, dynamic> weatherData)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripSummary() when $default != null:
return $default(_that.destination,_that.destinationCountry,_that.durationDays,_that.budgetEur,_that.highlights,_that.accommodation,_that.dayByDayProgram,_that.essentialItems,_that.accommodationSubtitle,_that.accommodationPrice,_that.accommodationSource,_that.flightRoute,_that.flightDetails,_that.flightPrice,_that.flightSource,_that.dayByDayDescriptions,_that.dayByDayCategories,_that.essentialReasons,_that.budgetBreakdown,_that.weatherData);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String destination,  String destinationCountry,  int durationDays,  int budgetEur,  List<String> highlights,  String accommodation,  List<String> dayByDayProgram,  List<String> essentialItems,  String accommodationSubtitle,  double accommodationPrice,  String accommodationSource,  String flightRoute,  String flightDetails,  double flightPrice,  String flightSource,  List<String> dayByDayDescriptions,  List<String> dayByDayCategories,  List<String> essentialReasons,  Map<String, dynamic> budgetBreakdown,  Map<String, dynamic> weatherData)  $default,) {final _that = this;
switch (_that) {
case _TripSummary():
return $default(_that.destination,_that.destinationCountry,_that.durationDays,_that.budgetEur,_that.highlights,_that.accommodation,_that.dayByDayProgram,_that.essentialItems,_that.accommodationSubtitle,_that.accommodationPrice,_that.accommodationSource,_that.flightRoute,_that.flightDetails,_that.flightPrice,_that.flightSource,_that.dayByDayDescriptions,_that.dayByDayCategories,_that.essentialReasons,_that.budgetBreakdown,_that.weatherData);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String destination,  String destinationCountry,  int durationDays,  int budgetEur,  List<String> highlights,  String accommodation,  List<String> dayByDayProgram,  List<String> essentialItems,  String accommodationSubtitle,  double accommodationPrice,  String accommodationSource,  String flightRoute,  String flightDetails,  double flightPrice,  String flightSource,  List<String> dayByDayDescriptions,  List<String> dayByDayCategories,  List<String> essentialReasons,  Map<String, dynamic> budgetBreakdown,  Map<String, dynamic> weatherData)?  $default,) {final _that = this;
switch (_that) {
case _TripSummary() when $default != null:
return $default(_that.destination,_that.destinationCountry,_that.durationDays,_that.budgetEur,_that.highlights,_that.accommodation,_that.dayByDayProgram,_that.essentialItems,_that.accommodationSubtitle,_that.accommodationPrice,_that.accommodationSource,_that.flightRoute,_that.flightDetails,_that.flightPrice,_that.flightSource,_that.dayByDayDescriptions,_that.dayByDayCategories,_that.essentialReasons,_that.budgetBreakdown,_that.weatherData);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripSummary implements TripSummary {
  const _TripSummary({this.destination = '', this.destinationCountry = '', this.durationDays = 0, this.budgetEur = 0, final  List<String> highlights = const [], this.accommodation = '', final  List<String> dayByDayProgram = const [], final  List<String> essentialItems = const [], this.accommodationSubtitle = '', this.accommodationPrice = 0.0, this.accommodationSource = 'estimated', this.flightRoute = '', this.flightDetails = '', this.flightPrice = 0.0, this.flightSource = 'estimated', final  List<String> dayByDayDescriptions = const [], final  List<String> dayByDayCategories = const [], final  List<String> essentialReasons = const [], final  Map<String, dynamic> budgetBreakdown = const {}, final  Map<String, dynamic> weatherData = const {}}): _highlights = highlights,_dayByDayProgram = dayByDayProgram,_essentialItems = essentialItems,_dayByDayDescriptions = dayByDayDescriptions,_dayByDayCategories = dayByDayCategories,_essentialReasons = essentialReasons,_budgetBreakdown = budgetBreakdown,_weatherData = weatherData;
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

// Accommodation details (real data from Amadeus)
@override@JsonKey() final  String accommodationSubtitle;
@override@JsonKey() final  double accommodationPrice;
@override@JsonKey() final  String accommodationSource;
// Flight details (real data from Amadeus)
@override@JsonKey() final  String flightRoute;
@override@JsonKey() final  String flightDetails;
@override@JsonKey() final  double flightPrice;
@override@JsonKey() final  String flightSource;
// Day-by-day descriptions and categories from activities
 final  List<String> _dayByDayDescriptions;
// Day-by-day descriptions and categories from activities
@override@JsonKey() List<String> get dayByDayDescriptions {
  if (_dayByDayDescriptions is EqualUnmodifiableListView) return _dayByDayDescriptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dayByDayDescriptions);
}

 final  List<String> _dayByDayCategories;
@override@JsonKey() List<String> get dayByDayCategories {
  if (_dayByDayCategories is EqualUnmodifiableListView) return _dayByDayCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dayByDayCategories);
}

// Baggage reasons
 final  List<String> _essentialReasons;
// Baggage reasons
@override@JsonKey() List<String> get essentialReasons {
  if (_essentialReasons is EqualUnmodifiableListView) return _essentialReasons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_essentialReasons);
}

// Budget breakdown
 final  Map<String, dynamic> _budgetBreakdown;
// Budget breakdown
@override@JsonKey() Map<String, dynamic> get budgetBreakdown {
  if (_budgetBreakdown is EqualUnmodifiableMapView) return _budgetBreakdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_budgetBreakdown);
}

// Weather data
 final  Map<String, dynamic> _weatherData;
// Weather data
@override@JsonKey() Map<String, dynamic> get weatherData {
  if (_weatherData is EqualUnmodifiableMapView) return _weatherData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_weatherData);
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripSummary&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.destinationCountry, destinationCountry) || other.destinationCountry == destinationCountry)&&(identical(other.durationDays, durationDays) || other.durationDays == durationDays)&&(identical(other.budgetEur, budgetEur) || other.budgetEur == budgetEur)&&const DeepCollectionEquality().equals(other._highlights, _highlights)&&(identical(other.accommodation, accommodation) || other.accommodation == accommodation)&&const DeepCollectionEquality().equals(other._dayByDayProgram, _dayByDayProgram)&&const DeepCollectionEquality().equals(other._essentialItems, _essentialItems)&&(identical(other.accommodationSubtitle, accommodationSubtitle) || other.accommodationSubtitle == accommodationSubtitle)&&(identical(other.accommodationPrice, accommodationPrice) || other.accommodationPrice == accommodationPrice)&&(identical(other.accommodationSource, accommodationSource) || other.accommodationSource == accommodationSource)&&(identical(other.flightRoute, flightRoute) || other.flightRoute == flightRoute)&&(identical(other.flightDetails, flightDetails) || other.flightDetails == flightDetails)&&(identical(other.flightPrice, flightPrice) || other.flightPrice == flightPrice)&&(identical(other.flightSource, flightSource) || other.flightSource == flightSource)&&const DeepCollectionEquality().equals(other._dayByDayDescriptions, _dayByDayDescriptions)&&const DeepCollectionEquality().equals(other._dayByDayCategories, _dayByDayCategories)&&const DeepCollectionEquality().equals(other._essentialReasons, _essentialReasons)&&const DeepCollectionEquality().equals(other._budgetBreakdown, _budgetBreakdown)&&const DeepCollectionEquality().equals(other._weatherData, _weatherData));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,destination,destinationCountry,durationDays,budgetEur,const DeepCollectionEquality().hash(_highlights),accommodation,const DeepCollectionEquality().hash(_dayByDayProgram),const DeepCollectionEquality().hash(_essentialItems),accommodationSubtitle,accommodationPrice,accommodationSource,flightRoute,flightDetails,flightPrice,flightSource,const DeepCollectionEquality().hash(_dayByDayDescriptions),const DeepCollectionEquality().hash(_dayByDayCategories),const DeepCollectionEquality().hash(_essentialReasons),const DeepCollectionEquality().hash(_budgetBreakdown),const DeepCollectionEquality().hash(_weatherData)]);

@override
String toString() {
  return 'TripSummary(destination: $destination, destinationCountry: $destinationCountry, durationDays: $durationDays, budgetEur: $budgetEur, highlights: $highlights, accommodation: $accommodation, dayByDayProgram: $dayByDayProgram, essentialItems: $essentialItems, accommodationSubtitle: $accommodationSubtitle, accommodationPrice: $accommodationPrice, accommodationSource: $accommodationSource, flightRoute: $flightRoute, flightDetails: $flightDetails, flightPrice: $flightPrice, flightSource: $flightSource, dayByDayDescriptions: $dayByDayDescriptions, dayByDayCategories: $dayByDayCategories, essentialReasons: $essentialReasons, budgetBreakdown: $budgetBreakdown, weatherData: $weatherData)';
}


}

/// @nodoc
abstract mixin class _$TripSummaryCopyWith<$Res> implements $TripSummaryCopyWith<$Res> {
  factory _$TripSummaryCopyWith(_TripSummary value, $Res Function(_TripSummary) _then) = __$TripSummaryCopyWithImpl;
@override @useResult
$Res call({
 String destination, String destinationCountry, int durationDays, int budgetEur, List<String> highlights, String accommodation, List<String> dayByDayProgram, List<String> essentialItems, String accommodationSubtitle, double accommodationPrice, String accommodationSource, String flightRoute, String flightDetails, double flightPrice, String flightSource, List<String> dayByDayDescriptions, List<String> dayByDayCategories, List<String> essentialReasons, Map<String, dynamic> budgetBreakdown, Map<String, dynamic> weatherData
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
@override @pragma('vm:prefer-inline') $Res call({Object? destination = null,Object? destinationCountry = null,Object? durationDays = null,Object? budgetEur = null,Object? highlights = null,Object? accommodation = null,Object? dayByDayProgram = null,Object? essentialItems = null,Object? accommodationSubtitle = null,Object? accommodationPrice = null,Object? accommodationSource = null,Object? flightRoute = null,Object? flightDetails = null,Object? flightPrice = null,Object? flightSource = null,Object? dayByDayDescriptions = null,Object? dayByDayCategories = null,Object? essentialReasons = null,Object? budgetBreakdown = null,Object? weatherData = null,}) {
  return _then(_TripSummary(
destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,destinationCountry: null == destinationCountry ? _self.destinationCountry : destinationCountry // ignore: cast_nullable_to_non_nullable
as String,durationDays: null == durationDays ? _self.durationDays : durationDays // ignore: cast_nullable_to_non_nullable
as int,budgetEur: null == budgetEur ? _self.budgetEur : budgetEur // ignore: cast_nullable_to_non_nullable
as int,highlights: null == highlights ? _self._highlights : highlights // ignore: cast_nullable_to_non_nullable
as List<String>,accommodation: null == accommodation ? _self.accommodation : accommodation // ignore: cast_nullable_to_non_nullable
as String,dayByDayProgram: null == dayByDayProgram ? _self._dayByDayProgram : dayByDayProgram // ignore: cast_nullable_to_non_nullable
as List<String>,essentialItems: null == essentialItems ? _self._essentialItems : essentialItems // ignore: cast_nullable_to_non_nullable
as List<String>,accommodationSubtitle: null == accommodationSubtitle ? _self.accommodationSubtitle : accommodationSubtitle // ignore: cast_nullable_to_non_nullable
as String,accommodationPrice: null == accommodationPrice ? _self.accommodationPrice : accommodationPrice // ignore: cast_nullable_to_non_nullable
as double,accommodationSource: null == accommodationSource ? _self.accommodationSource : accommodationSource // ignore: cast_nullable_to_non_nullable
as String,flightRoute: null == flightRoute ? _self.flightRoute : flightRoute // ignore: cast_nullable_to_non_nullable
as String,flightDetails: null == flightDetails ? _self.flightDetails : flightDetails // ignore: cast_nullable_to_non_nullable
as String,flightPrice: null == flightPrice ? _self.flightPrice : flightPrice // ignore: cast_nullable_to_non_nullable
as double,flightSource: null == flightSource ? _self.flightSource : flightSource // ignore: cast_nullable_to_non_nullable
as String,dayByDayDescriptions: null == dayByDayDescriptions ? _self._dayByDayDescriptions : dayByDayDescriptions // ignore: cast_nullable_to_non_nullable
as List<String>,dayByDayCategories: null == dayByDayCategories ? _self._dayByDayCategories : dayByDayCategories // ignore: cast_nullable_to_non_nullable
as List<String>,essentialReasons: null == essentialReasons ? _self._essentialReasons : essentialReasons // ignore: cast_nullable_to_non_nullable
as List<String>,budgetBreakdown: null == budgetBreakdown ? _self._budgetBreakdown : budgetBreakdown // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,weatherData: null == weatherData ? _self._weatherData : weatherData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
