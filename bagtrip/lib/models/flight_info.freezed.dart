// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'flight_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FlightInfo {

@JsonKey(name: 'flightIata') String? get flightIata;@JsonKey(name: 'airlineIata') String? get airlineIata;@JsonKey(name: 'airlineName') String? get airlineName; String? get status;@JsonKey(name: 'departureIata') String? get departureIata;@JsonKey(name: 'departureTerminal') String? get departureTerminal;@JsonKey(name: 'departureGate') String? get departureGate;@JsonKey(name: 'departureTime') String? get departureTime;@JsonKey(name: 'departureActual') String? get departureActual;@JsonKey(name: 'departureDelay') int? get departureDelay;@JsonKey(name: 'arrivalIata') String? get arrivalIata;@JsonKey(name: 'arrivalTerminal') String? get arrivalTerminal;@JsonKey(name: 'arrivalGate') String? get arrivalGate;@JsonKey(name: 'arrivalTime') String? get arrivalTime;@JsonKey(name: 'arrivalActual') String? get arrivalActual;@JsonKey(name: 'arrivalDelay') int? get arrivalDelay;
/// Create a copy of FlightInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FlightInfoCopyWith<FlightInfo> get copyWith => _$FlightInfoCopyWithImpl<FlightInfo>(this as FlightInfo, _$identity);

  /// Serializes this FlightInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FlightInfo&&(identical(other.flightIata, flightIata) || other.flightIata == flightIata)&&(identical(other.airlineIata, airlineIata) || other.airlineIata == airlineIata)&&(identical(other.airlineName, airlineName) || other.airlineName == airlineName)&&(identical(other.status, status) || other.status == status)&&(identical(other.departureIata, departureIata) || other.departureIata == departureIata)&&(identical(other.departureTerminal, departureTerminal) || other.departureTerminal == departureTerminal)&&(identical(other.departureGate, departureGate) || other.departureGate == departureGate)&&(identical(other.departureTime, departureTime) || other.departureTime == departureTime)&&(identical(other.departureActual, departureActual) || other.departureActual == departureActual)&&(identical(other.departureDelay, departureDelay) || other.departureDelay == departureDelay)&&(identical(other.arrivalIata, arrivalIata) || other.arrivalIata == arrivalIata)&&(identical(other.arrivalTerminal, arrivalTerminal) || other.arrivalTerminal == arrivalTerminal)&&(identical(other.arrivalGate, arrivalGate) || other.arrivalGate == arrivalGate)&&(identical(other.arrivalTime, arrivalTime) || other.arrivalTime == arrivalTime)&&(identical(other.arrivalActual, arrivalActual) || other.arrivalActual == arrivalActual)&&(identical(other.arrivalDelay, arrivalDelay) || other.arrivalDelay == arrivalDelay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,flightIata,airlineIata,airlineName,status,departureIata,departureTerminal,departureGate,departureTime,departureActual,departureDelay,arrivalIata,arrivalTerminal,arrivalGate,arrivalTime,arrivalActual,arrivalDelay);

@override
String toString() {
  return 'FlightInfo(flightIata: $flightIata, airlineIata: $airlineIata, airlineName: $airlineName, status: $status, departureIata: $departureIata, departureTerminal: $departureTerminal, departureGate: $departureGate, departureTime: $departureTime, departureActual: $departureActual, departureDelay: $departureDelay, arrivalIata: $arrivalIata, arrivalTerminal: $arrivalTerminal, arrivalGate: $arrivalGate, arrivalTime: $arrivalTime, arrivalActual: $arrivalActual, arrivalDelay: $arrivalDelay)';
}


}

/// @nodoc
abstract mixin class $FlightInfoCopyWith<$Res>  {
  factory $FlightInfoCopyWith(FlightInfo value, $Res Function(FlightInfo) _then) = _$FlightInfoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'flightIata') String? flightIata,@JsonKey(name: 'airlineIata') String? airlineIata,@JsonKey(name: 'airlineName') String? airlineName, String? status,@JsonKey(name: 'departureIata') String? departureIata,@JsonKey(name: 'departureTerminal') String? departureTerminal,@JsonKey(name: 'departureGate') String? departureGate,@JsonKey(name: 'departureTime') String? departureTime,@JsonKey(name: 'departureActual') String? departureActual,@JsonKey(name: 'departureDelay') int? departureDelay,@JsonKey(name: 'arrivalIata') String? arrivalIata,@JsonKey(name: 'arrivalTerminal') String? arrivalTerminal,@JsonKey(name: 'arrivalGate') String? arrivalGate,@JsonKey(name: 'arrivalTime') String? arrivalTime,@JsonKey(name: 'arrivalActual') String? arrivalActual,@JsonKey(name: 'arrivalDelay') int? arrivalDelay
});




}
/// @nodoc
class _$FlightInfoCopyWithImpl<$Res>
    implements $FlightInfoCopyWith<$Res> {
  _$FlightInfoCopyWithImpl(this._self, this._then);

  final FlightInfo _self;
  final $Res Function(FlightInfo) _then;

/// Create a copy of FlightInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? flightIata = freezed,Object? airlineIata = freezed,Object? airlineName = freezed,Object? status = freezed,Object? departureIata = freezed,Object? departureTerminal = freezed,Object? departureGate = freezed,Object? departureTime = freezed,Object? departureActual = freezed,Object? departureDelay = freezed,Object? arrivalIata = freezed,Object? arrivalTerminal = freezed,Object? arrivalGate = freezed,Object? arrivalTime = freezed,Object? arrivalActual = freezed,Object? arrivalDelay = freezed,}) {
  return _then(_self.copyWith(
flightIata: freezed == flightIata ? _self.flightIata : flightIata // ignore: cast_nullable_to_non_nullable
as String?,airlineIata: freezed == airlineIata ? _self.airlineIata : airlineIata // ignore: cast_nullable_to_non_nullable
as String?,airlineName: freezed == airlineName ? _self.airlineName : airlineName // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,departureIata: freezed == departureIata ? _self.departureIata : departureIata // ignore: cast_nullable_to_non_nullable
as String?,departureTerminal: freezed == departureTerminal ? _self.departureTerminal : departureTerminal // ignore: cast_nullable_to_non_nullable
as String?,departureGate: freezed == departureGate ? _self.departureGate : departureGate // ignore: cast_nullable_to_non_nullable
as String?,departureTime: freezed == departureTime ? _self.departureTime : departureTime // ignore: cast_nullable_to_non_nullable
as String?,departureActual: freezed == departureActual ? _self.departureActual : departureActual // ignore: cast_nullable_to_non_nullable
as String?,departureDelay: freezed == departureDelay ? _self.departureDelay : departureDelay // ignore: cast_nullable_to_non_nullable
as int?,arrivalIata: freezed == arrivalIata ? _self.arrivalIata : arrivalIata // ignore: cast_nullable_to_non_nullable
as String?,arrivalTerminal: freezed == arrivalTerminal ? _self.arrivalTerminal : arrivalTerminal // ignore: cast_nullable_to_non_nullable
as String?,arrivalGate: freezed == arrivalGate ? _self.arrivalGate : arrivalGate // ignore: cast_nullable_to_non_nullable
as String?,arrivalTime: freezed == arrivalTime ? _self.arrivalTime : arrivalTime // ignore: cast_nullable_to_non_nullable
as String?,arrivalActual: freezed == arrivalActual ? _self.arrivalActual : arrivalActual // ignore: cast_nullable_to_non_nullable
as String?,arrivalDelay: freezed == arrivalDelay ? _self.arrivalDelay : arrivalDelay // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [FlightInfo].
extension FlightInfoPatterns on FlightInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FlightInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FlightInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FlightInfo value)  $default,){
final _that = this;
switch (_that) {
case _FlightInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FlightInfo value)?  $default,){
final _that = this;
switch (_that) {
case _FlightInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'flightIata')  String? flightIata, @JsonKey(name: 'airlineIata')  String? airlineIata, @JsonKey(name: 'airlineName')  String? airlineName,  String? status, @JsonKey(name: 'departureIata')  String? departureIata, @JsonKey(name: 'departureTerminal')  String? departureTerminal, @JsonKey(name: 'departureGate')  String? departureGate, @JsonKey(name: 'departureTime')  String? departureTime, @JsonKey(name: 'departureActual')  String? departureActual, @JsonKey(name: 'departureDelay')  int? departureDelay, @JsonKey(name: 'arrivalIata')  String? arrivalIata, @JsonKey(name: 'arrivalTerminal')  String? arrivalTerminal, @JsonKey(name: 'arrivalGate')  String? arrivalGate, @JsonKey(name: 'arrivalTime')  String? arrivalTime, @JsonKey(name: 'arrivalActual')  String? arrivalActual, @JsonKey(name: 'arrivalDelay')  int? arrivalDelay)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FlightInfo() when $default != null:
return $default(_that.flightIata,_that.airlineIata,_that.airlineName,_that.status,_that.departureIata,_that.departureTerminal,_that.departureGate,_that.departureTime,_that.departureActual,_that.departureDelay,_that.arrivalIata,_that.arrivalTerminal,_that.arrivalGate,_that.arrivalTime,_that.arrivalActual,_that.arrivalDelay);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'flightIata')  String? flightIata, @JsonKey(name: 'airlineIata')  String? airlineIata, @JsonKey(name: 'airlineName')  String? airlineName,  String? status, @JsonKey(name: 'departureIata')  String? departureIata, @JsonKey(name: 'departureTerminal')  String? departureTerminal, @JsonKey(name: 'departureGate')  String? departureGate, @JsonKey(name: 'departureTime')  String? departureTime, @JsonKey(name: 'departureActual')  String? departureActual, @JsonKey(name: 'departureDelay')  int? departureDelay, @JsonKey(name: 'arrivalIata')  String? arrivalIata, @JsonKey(name: 'arrivalTerminal')  String? arrivalTerminal, @JsonKey(name: 'arrivalGate')  String? arrivalGate, @JsonKey(name: 'arrivalTime')  String? arrivalTime, @JsonKey(name: 'arrivalActual')  String? arrivalActual, @JsonKey(name: 'arrivalDelay')  int? arrivalDelay)  $default,) {final _that = this;
switch (_that) {
case _FlightInfo():
return $default(_that.flightIata,_that.airlineIata,_that.airlineName,_that.status,_that.departureIata,_that.departureTerminal,_that.departureGate,_that.departureTime,_that.departureActual,_that.departureDelay,_that.arrivalIata,_that.arrivalTerminal,_that.arrivalGate,_that.arrivalTime,_that.arrivalActual,_that.arrivalDelay);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'flightIata')  String? flightIata, @JsonKey(name: 'airlineIata')  String? airlineIata, @JsonKey(name: 'airlineName')  String? airlineName,  String? status, @JsonKey(name: 'departureIata')  String? departureIata, @JsonKey(name: 'departureTerminal')  String? departureTerminal, @JsonKey(name: 'departureGate')  String? departureGate, @JsonKey(name: 'departureTime')  String? departureTime, @JsonKey(name: 'departureActual')  String? departureActual, @JsonKey(name: 'departureDelay')  int? departureDelay, @JsonKey(name: 'arrivalIata')  String? arrivalIata, @JsonKey(name: 'arrivalTerminal')  String? arrivalTerminal, @JsonKey(name: 'arrivalGate')  String? arrivalGate, @JsonKey(name: 'arrivalTime')  String? arrivalTime, @JsonKey(name: 'arrivalActual')  String? arrivalActual, @JsonKey(name: 'arrivalDelay')  int? arrivalDelay)?  $default,) {final _that = this;
switch (_that) {
case _FlightInfo() when $default != null:
return $default(_that.flightIata,_that.airlineIata,_that.airlineName,_that.status,_that.departureIata,_that.departureTerminal,_that.departureGate,_that.departureTime,_that.departureActual,_that.departureDelay,_that.arrivalIata,_that.arrivalTerminal,_that.arrivalGate,_that.arrivalTime,_that.arrivalActual,_that.arrivalDelay);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FlightInfo implements FlightInfo {
  const _FlightInfo({@JsonKey(name: 'flightIata') this.flightIata, @JsonKey(name: 'airlineIata') this.airlineIata, @JsonKey(name: 'airlineName') this.airlineName, this.status, @JsonKey(name: 'departureIata') this.departureIata, @JsonKey(name: 'departureTerminal') this.departureTerminal, @JsonKey(name: 'departureGate') this.departureGate, @JsonKey(name: 'departureTime') this.departureTime, @JsonKey(name: 'departureActual') this.departureActual, @JsonKey(name: 'departureDelay') this.departureDelay, @JsonKey(name: 'arrivalIata') this.arrivalIata, @JsonKey(name: 'arrivalTerminal') this.arrivalTerminal, @JsonKey(name: 'arrivalGate') this.arrivalGate, @JsonKey(name: 'arrivalTime') this.arrivalTime, @JsonKey(name: 'arrivalActual') this.arrivalActual, @JsonKey(name: 'arrivalDelay') this.arrivalDelay});
  factory _FlightInfo.fromJson(Map<String, dynamic> json) => _$FlightInfoFromJson(json);

@override@JsonKey(name: 'flightIata') final  String? flightIata;
@override@JsonKey(name: 'airlineIata') final  String? airlineIata;
@override@JsonKey(name: 'airlineName') final  String? airlineName;
@override final  String? status;
@override@JsonKey(name: 'departureIata') final  String? departureIata;
@override@JsonKey(name: 'departureTerminal') final  String? departureTerminal;
@override@JsonKey(name: 'departureGate') final  String? departureGate;
@override@JsonKey(name: 'departureTime') final  String? departureTime;
@override@JsonKey(name: 'departureActual') final  String? departureActual;
@override@JsonKey(name: 'departureDelay') final  int? departureDelay;
@override@JsonKey(name: 'arrivalIata') final  String? arrivalIata;
@override@JsonKey(name: 'arrivalTerminal') final  String? arrivalTerminal;
@override@JsonKey(name: 'arrivalGate') final  String? arrivalGate;
@override@JsonKey(name: 'arrivalTime') final  String? arrivalTime;
@override@JsonKey(name: 'arrivalActual') final  String? arrivalActual;
@override@JsonKey(name: 'arrivalDelay') final  int? arrivalDelay;

/// Create a copy of FlightInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FlightInfoCopyWith<_FlightInfo> get copyWith => __$FlightInfoCopyWithImpl<_FlightInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FlightInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FlightInfo&&(identical(other.flightIata, flightIata) || other.flightIata == flightIata)&&(identical(other.airlineIata, airlineIata) || other.airlineIata == airlineIata)&&(identical(other.airlineName, airlineName) || other.airlineName == airlineName)&&(identical(other.status, status) || other.status == status)&&(identical(other.departureIata, departureIata) || other.departureIata == departureIata)&&(identical(other.departureTerminal, departureTerminal) || other.departureTerminal == departureTerminal)&&(identical(other.departureGate, departureGate) || other.departureGate == departureGate)&&(identical(other.departureTime, departureTime) || other.departureTime == departureTime)&&(identical(other.departureActual, departureActual) || other.departureActual == departureActual)&&(identical(other.departureDelay, departureDelay) || other.departureDelay == departureDelay)&&(identical(other.arrivalIata, arrivalIata) || other.arrivalIata == arrivalIata)&&(identical(other.arrivalTerminal, arrivalTerminal) || other.arrivalTerminal == arrivalTerminal)&&(identical(other.arrivalGate, arrivalGate) || other.arrivalGate == arrivalGate)&&(identical(other.arrivalTime, arrivalTime) || other.arrivalTime == arrivalTime)&&(identical(other.arrivalActual, arrivalActual) || other.arrivalActual == arrivalActual)&&(identical(other.arrivalDelay, arrivalDelay) || other.arrivalDelay == arrivalDelay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,flightIata,airlineIata,airlineName,status,departureIata,departureTerminal,departureGate,departureTime,departureActual,departureDelay,arrivalIata,arrivalTerminal,arrivalGate,arrivalTime,arrivalActual,arrivalDelay);

@override
String toString() {
  return 'FlightInfo(flightIata: $flightIata, airlineIata: $airlineIata, airlineName: $airlineName, status: $status, departureIata: $departureIata, departureTerminal: $departureTerminal, departureGate: $departureGate, departureTime: $departureTime, departureActual: $departureActual, departureDelay: $departureDelay, arrivalIata: $arrivalIata, arrivalTerminal: $arrivalTerminal, arrivalGate: $arrivalGate, arrivalTime: $arrivalTime, arrivalActual: $arrivalActual, arrivalDelay: $arrivalDelay)';
}


}

/// @nodoc
abstract mixin class _$FlightInfoCopyWith<$Res> implements $FlightInfoCopyWith<$Res> {
  factory _$FlightInfoCopyWith(_FlightInfo value, $Res Function(_FlightInfo) _then) = __$FlightInfoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'flightIata') String? flightIata,@JsonKey(name: 'airlineIata') String? airlineIata,@JsonKey(name: 'airlineName') String? airlineName, String? status,@JsonKey(name: 'departureIata') String? departureIata,@JsonKey(name: 'departureTerminal') String? departureTerminal,@JsonKey(name: 'departureGate') String? departureGate,@JsonKey(name: 'departureTime') String? departureTime,@JsonKey(name: 'departureActual') String? departureActual,@JsonKey(name: 'departureDelay') int? departureDelay,@JsonKey(name: 'arrivalIata') String? arrivalIata,@JsonKey(name: 'arrivalTerminal') String? arrivalTerminal,@JsonKey(name: 'arrivalGate') String? arrivalGate,@JsonKey(name: 'arrivalTime') String? arrivalTime,@JsonKey(name: 'arrivalActual') String? arrivalActual,@JsonKey(name: 'arrivalDelay') int? arrivalDelay
});




}
/// @nodoc
class __$FlightInfoCopyWithImpl<$Res>
    implements _$FlightInfoCopyWith<$Res> {
  __$FlightInfoCopyWithImpl(this._self, this._then);

  final _FlightInfo _self;
  final $Res Function(_FlightInfo) _then;

/// Create a copy of FlightInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? flightIata = freezed,Object? airlineIata = freezed,Object? airlineName = freezed,Object? status = freezed,Object? departureIata = freezed,Object? departureTerminal = freezed,Object? departureGate = freezed,Object? departureTime = freezed,Object? departureActual = freezed,Object? departureDelay = freezed,Object? arrivalIata = freezed,Object? arrivalTerminal = freezed,Object? arrivalGate = freezed,Object? arrivalTime = freezed,Object? arrivalActual = freezed,Object? arrivalDelay = freezed,}) {
  return _then(_FlightInfo(
flightIata: freezed == flightIata ? _self.flightIata : flightIata // ignore: cast_nullable_to_non_nullable
as String?,airlineIata: freezed == airlineIata ? _self.airlineIata : airlineIata // ignore: cast_nullable_to_non_nullable
as String?,airlineName: freezed == airlineName ? _self.airlineName : airlineName // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,departureIata: freezed == departureIata ? _self.departureIata : departureIata // ignore: cast_nullable_to_non_nullable
as String?,departureTerminal: freezed == departureTerminal ? _self.departureTerminal : departureTerminal // ignore: cast_nullable_to_non_nullable
as String?,departureGate: freezed == departureGate ? _self.departureGate : departureGate // ignore: cast_nullable_to_non_nullable
as String?,departureTime: freezed == departureTime ? _self.departureTime : departureTime // ignore: cast_nullable_to_non_nullable
as String?,departureActual: freezed == departureActual ? _self.departureActual : departureActual // ignore: cast_nullable_to_non_nullable
as String?,departureDelay: freezed == departureDelay ? _self.departureDelay : departureDelay // ignore: cast_nullable_to_non_nullable
as int?,arrivalIata: freezed == arrivalIata ? _self.arrivalIata : arrivalIata // ignore: cast_nullable_to_non_nullable
as String?,arrivalTerminal: freezed == arrivalTerminal ? _self.arrivalTerminal : arrivalTerminal // ignore: cast_nullable_to_non_nullable
as String?,arrivalGate: freezed == arrivalGate ? _self.arrivalGate : arrivalGate // ignore: cast_nullable_to_non_nullable
as String?,arrivalTime: freezed == arrivalTime ? _self.arrivalTime : arrivalTime // ignore: cast_nullable_to_non_nullable
as String?,arrivalActual: freezed == arrivalActual ? _self.arrivalActual : arrivalActual // ignore: cast_nullable_to_non_nullable
as String?,arrivalDelay: freezed == arrivalDelay ? _self.arrivalDelay : arrivalDelay // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
