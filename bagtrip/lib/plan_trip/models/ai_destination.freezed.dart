// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_destination.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AiDestination {

 String get city; String get country; String? get iata; double? get lat; double? get lon;@JsonKey(name: 'match_reason') String? get matchReason;@JsonKey(name: 'weather_summary') String? get weatherSummary;@JsonKey(name: 'image_url') String? get imageUrl; List<String> get topActivities; BudgetRange? get estimatedBudgetRange;
/// Create a copy of AiDestination
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiDestinationCopyWith<AiDestination> get copyWith => _$AiDestinationCopyWithImpl<AiDestination>(this as AiDestination, _$identity);

  /// Serializes this AiDestination to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiDestination&&(identical(other.city, city) || other.city == city)&&(identical(other.country, country) || other.country == country)&&(identical(other.iata, iata) || other.iata == iata)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lon, lon) || other.lon == lon)&&(identical(other.matchReason, matchReason) || other.matchReason == matchReason)&&(identical(other.weatherSummary, weatherSummary) || other.weatherSummary == weatherSummary)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&const DeepCollectionEquality().equals(other.topActivities, topActivities)&&(identical(other.estimatedBudgetRange, estimatedBudgetRange) || other.estimatedBudgetRange == estimatedBudgetRange));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,city,country,iata,lat,lon,matchReason,weatherSummary,imageUrl,const DeepCollectionEquality().hash(topActivities),estimatedBudgetRange);

@override
String toString() {
  return 'AiDestination(city: $city, country: $country, iata: $iata, lat: $lat, lon: $lon, matchReason: $matchReason, weatherSummary: $weatherSummary, imageUrl: $imageUrl, topActivities: $topActivities, estimatedBudgetRange: $estimatedBudgetRange)';
}


}

/// @nodoc
abstract mixin class $AiDestinationCopyWith<$Res>  {
  factory $AiDestinationCopyWith(AiDestination value, $Res Function(AiDestination) _then) = _$AiDestinationCopyWithImpl;
@useResult
$Res call({
 String city, String country, String? iata, double? lat, double? lon,@JsonKey(name: 'match_reason') String? matchReason,@JsonKey(name: 'weather_summary') String? weatherSummary,@JsonKey(name: 'image_url') String? imageUrl, List<String> topActivities, BudgetRange? estimatedBudgetRange
});


$BudgetRangeCopyWith<$Res>? get estimatedBudgetRange;

}
/// @nodoc
class _$AiDestinationCopyWithImpl<$Res>
    implements $AiDestinationCopyWith<$Res> {
  _$AiDestinationCopyWithImpl(this._self, this._then);

  final AiDestination _self;
  final $Res Function(AiDestination) _then;

/// Create a copy of AiDestination
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? city = null,Object? country = null,Object? iata = freezed,Object? lat = freezed,Object? lon = freezed,Object? matchReason = freezed,Object? weatherSummary = freezed,Object? imageUrl = freezed,Object? topActivities = null,Object? estimatedBudgetRange = freezed,}) {
  return _then(_self.copyWith(
city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,iata: freezed == iata ? _self.iata : iata // ignore: cast_nullable_to_non_nullable
as String?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lon: freezed == lon ? _self.lon : lon // ignore: cast_nullable_to_non_nullable
as double?,matchReason: freezed == matchReason ? _self.matchReason : matchReason // ignore: cast_nullable_to_non_nullable
as String?,weatherSummary: freezed == weatherSummary ? _self.weatherSummary : weatherSummary // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,topActivities: null == topActivities ? _self.topActivities : topActivities // ignore: cast_nullable_to_non_nullable
as List<String>,estimatedBudgetRange: freezed == estimatedBudgetRange ? _self.estimatedBudgetRange : estimatedBudgetRange // ignore: cast_nullable_to_non_nullable
as BudgetRange?,
  ));
}
/// Create a copy of AiDestination
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BudgetRangeCopyWith<$Res>? get estimatedBudgetRange {
    if (_self.estimatedBudgetRange == null) {
    return null;
  }

  return $BudgetRangeCopyWith<$Res>(_self.estimatedBudgetRange!, (value) {
    return _then(_self.copyWith(estimatedBudgetRange: value));
  });
}
}


/// Adds pattern-matching-related methods to [AiDestination].
extension AiDestinationPatterns on AiDestination {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AiDestination value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AiDestination() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AiDestination value)  $default,){
final _that = this;
switch (_that) {
case _AiDestination():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AiDestination value)?  $default,){
final _that = this;
switch (_that) {
case _AiDestination() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String city,  String country,  String? iata,  double? lat,  double? lon, @JsonKey(name: 'match_reason')  String? matchReason, @JsonKey(name: 'weather_summary')  String? weatherSummary, @JsonKey(name: 'image_url')  String? imageUrl,  List<String> topActivities,  BudgetRange? estimatedBudgetRange)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AiDestination() when $default != null:
return $default(_that.city,_that.country,_that.iata,_that.lat,_that.lon,_that.matchReason,_that.weatherSummary,_that.imageUrl,_that.topActivities,_that.estimatedBudgetRange);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String city,  String country,  String? iata,  double? lat,  double? lon, @JsonKey(name: 'match_reason')  String? matchReason, @JsonKey(name: 'weather_summary')  String? weatherSummary, @JsonKey(name: 'image_url')  String? imageUrl,  List<String> topActivities,  BudgetRange? estimatedBudgetRange)  $default,) {final _that = this;
switch (_that) {
case _AiDestination():
return $default(_that.city,_that.country,_that.iata,_that.lat,_that.lon,_that.matchReason,_that.weatherSummary,_that.imageUrl,_that.topActivities,_that.estimatedBudgetRange);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String city,  String country,  String? iata,  double? lat,  double? lon, @JsonKey(name: 'match_reason')  String? matchReason, @JsonKey(name: 'weather_summary')  String? weatherSummary, @JsonKey(name: 'image_url')  String? imageUrl,  List<String> topActivities,  BudgetRange? estimatedBudgetRange)?  $default,) {final _that = this;
switch (_that) {
case _AiDestination() when $default != null:
return $default(_that.city,_that.country,_that.iata,_that.lat,_that.lon,_that.matchReason,_that.weatherSummary,_that.imageUrl,_that.topActivities,_that.estimatedBudgetRange);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AiDestination implements AiDestination {
  const _AiDestination({required this.city, required this.country, this.iata, this.lat, this.lon, @JsonKey(name: 'match_reason') this.matchReason, @JsonKey(name: 'weather_summary') this.weatherSummary, @JsonKey(name: 'image_url') this.imageUrl, final  List<String> topActivities = const [], this.estimatedBudgetRange}): _topActivities = topActivities;
  factory _AiDestination.fromJson(Map<String, dynamic> json) => _$AiDestinationFromJson(json);

@override final  String city;
@override final  String country;
@override final  String? iata;
@override final  double? lat;
@override final  double? lon;
@override@JsonKey(name: 'match_reason') final  String? matchReason;
@override@JsonKey(name: 'weather_summary') final  String? weatherSummary;
@override@JsonKey(name: 'image_url') final  String? imageUrl;
 final  List<String> _topActivities;
@override@JsonKey() List<String> get topActivities {
  if (_topActivities is EqualUnmodifiableListView) return _topActivities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topActivities);
}

@override final  BudgetRange? estimatedBudgetRange;

/// Create a copy of AiDestination
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiDestinationCopyWith<_AiDestination> get copyWith => __$AiDestinationCopyWithImpl<_AiDestination>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AiDestinationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiDestination&&(identical(other.city, city) || other.city == city)&&(identical(other.country, country) || other.country == country)&&(identical(other.iata, iata) || other.iata == iata)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lon, lon) || other.lon == lon)&&(identical(other.matchReason, matchReason) || other.matchReason == matchReason)&&(identical(other.weatherSummary, weatherSummary) || other.weatherSummary == weatherSummary)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&const DeepCollectionEquality().equals(other._topActivities, _topActivities)&&(identical(other.estimatedBudgetRange, estimatedBudgetRange) || other.estimatedBudgetRange == estimatedBudgetRange));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,city,country,iata,lat,lon,matchReason,weatherSummary,imageUrl,const DeepCollectionEquality().hash(_topActivities),estimatedBudgetRange);

@override
String toString() {
  return 'AiDestination(city: $city, country: $country, iata: $iata, lat: $lat, lon: $lon, matchReason: $matchReason, weatherSummary: $weatherSummary, imageUrl: $imageUrl, topActivities: $topActivities, estimatedBudgetRange: $estimatedBudgetRange)';
}


}

/// @nodoc
abstract mixin class _$AiDestinationCopyWith<$Res> implements $AiDestinationCopyWith<$Res> {
  factory _$AiDestinationCopyWith(_AiDestination value, $Res Function(_AiDestination) _then) = __$AiDestinationCopyWithImpl;
@override @useResult
$Res call({
 String city, String country, String? iata, double? lat, double? lon,@JsonKey(name: 'match_reason') String? matchReason,@JsonKey(name: 'weather_summary') String? weatherSummary,@JsonKey(name: 'image_url') String? imageUrl, List<String> topActivities, BudgetRange? estimatedBudgetRange
});


@override $BudgetRangeCopyWith<$Res>? get estimatedBudgetRange;

}
/// @nodoc
class __$AiDestinationCopyWithImpl<$Res>
    implements _$AiDestinationCopyWith<$Res> {
  __$AiDestinationCopyWithImpl(this._self, this._then);

  final _AiDestination _self;
  final $Res Function(_AiDestination) _then;

/// Create a copy of AiDestination
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? city = null,Object? country = null,Object? iata = freezed,Object? lat = freezed,Object? lon = freezed,Object? matchReason = freezed,Object? weatherSummary = freezed,Object? imageUrl = freezed,Object? topActivities = null,Object? estimatedBudgetRange = freezed,}) {
  return _then(_AiDestination(
city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,iata: freezed == iata ? _self.iata : iata // ignore: cast_nullable_to_non_nullable
as String?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lon: freezed == lon ? _self.lon : lon // ignore: cast_nullable_to_non_nullable
as double?,matchReason: freezed == matchReason ? _self.matchReason : matchReason // ignore: cast_nullable_to_non_nullable
as String?,weatherSummary: freezed == weatherSummary ? _self.weatherSummary : weatherSummary // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,topActivities: null == topActivities ? _self._topActivities : topActivities // ignore: cast_nullable_to_non_nullable
as List<String>,estimatedBudgetRange: freezed == estimatedBudgetRange ? _self.estimatedBudgetRange : estimatedBudgetRange // ignore: cast_nullable_to_non_nullable
as BudgetRange?,
  ));
}

/// Create a copy of AiDestination
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BudgetRangeCopyWith<$Res>? get estimatedBudgetRange {
    if (_self.estimatedBudgetRange == null) {
    return null;
  }

  return $BudgetRangeCopyWith<$Res>(_self.estimatedBudgetRange!, (value) {
    return _then(_self.copyWith(estimatedBudgetRange: value));
  });
}
}

// dart format on
