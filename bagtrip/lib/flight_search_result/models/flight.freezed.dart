// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'flight.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Flight {

 String get id; String get departureTime; String get arrivalTime; String get departureAirport; String get departureCode; String get arrivalAirport; String get arrivalCode; String get duration; String? get airline; String? get aircraftType; double get price; List<String> get amenities; DateTime? get departureDateTime; DateTime? get arrivalDateTime; int get outboundStops;// Return flight details (nullable)
 String? get returnDepartureTime; String? get returnArrivalTime; String? get returnDepartureCode; String? get returnArrivalCode; String? get returnDuration; String? get returnAirline; String? get returnAircraftType; DateTime? get returnDepartureDateTime; DateTime? get returnArrivalDateTime; int? get returnStops;// Extra details
 int get numberOfBookableSeats; String get lastTicketingDate; double get basePrice; String get cabinClass; String get bookingClass; String get fareBasis; BaggageInfo? get checkedBags; BaggageInfo? get cabinBags;
/// Create a copy of Flight
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FlightCopyWith<Flight> get copyWith => _$FlightCopyWithImpl<Flight>(this as Flight, _$identity);

  /// Serializes this Flight to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Flight&&(identical(other.id, id) || other.id == id)&&(identical(other.departureTime, departureTime) || other.departureTime == departureTime)&&(identical(other.arrivalTime, arrivalTime) || other.arrivalTime == arrivalTime)&&(identical(other.departureAirport, departureAirport) || other.departureAirport == departureAirport)&&(identical(other.departureCode, departureCode) || other.departureCode == departureCode)&&(identical(other.arrivalAirport, arrivalAirport) || other.arrivalAirport == arrivalAirport)&&(identical(other.arrivalCode, arrivalCode) || other.arrivalCode == arrivalCode)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.airline, airline) || other.airline == airline)&&(identical(other.aircraftType, aircraftType) || other.aircraftType == aircraftType)&&(identical(other.price, price) || other.price == price)&&const DeepCollectionEquality().equals(other.amenities, amenities)&&(identical(other.departureDateTime, departureDateTime) || other.departureDateTime == departureDateTime)&&(identical(other.arrivalDateTime, arrivalDateTime) || other.arrivalDateTime == arrivalDateTime)&&(identical(other.outboundStops, outboundStops) || other.outboundStops == outboundStops)&&(identical(other.returnDepartureTime, returnDepartureTime) || other.returnDepartureTime == returnDepartureTime)&&(identical(other.returnArrivalTime, returnArrivalTime) || other.returnArrivalTime == returnArrivalTime)&&(identical(other.returnDepartureCode, returnDepartureCode) || other.returnDepartureCode == returnDepartureCode)&&(identical(other.returnArrivalCode, returnArrivalCode) || other.returnArrivalCode == returnArrivalCode)&&(identical(other.returnDuration, returnDuration) || other.returnDuration == returnDuration)&&(identical(other.returnAirline, returnAirline) || other.returnAirline == returnAirline)&&(identical(other.returnAircraftType, returnAircraftType) || other.returnAircraftType == returnAircraftType)&&(identical(other.returnDepartureDateTime, returnDepartureDateTime) || other.returnDepartureDateTime == returnDepartureDateTime)&&(identical(other.returnArrivalDateTime, returnArrivalDateTime) || other.returnArrivalDateTime == returnArrivalDateTime)&&(identical(other.returnStops, returnStops) || other.returnStops == returnStops)&&(identical(other.numberOfBookableSeats, numberOfBookableSeats) || other.numberOfBookableSeats == numberOfBookableSeats)&&(identical(other.lastTicketingDate, lastTicketingDate) || other.lastTicketingDate == lastTicketingDate)&&(identical(other.basePrice, basePrice) || other.basePrice == basePrice)&&(identical(other.cabinClass, cabinClass) || other.cabinClass == cabinClass)&&(identical(other.bookingClass, bookingClass) || other.bookingClass == bookingClass)&&(identical(other.fareBasis, fareBasis) || other.fareBasis == fareBasis)&&(identical(other.checkedBags, checkedBags) || other.checkedBags == checkedBags)&&(identical(other.cabinBags, cabinBags) || other.cabinBags == cabinBags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,departureTime,arrivalTime,departureAirport,departureCode,arrivalAirport,arrivalCode,duration,airline,aircraftType,price,const DeepCollectionEquality().hash(amenities),departureDateTime,arrivalDateTime,outboundStops,returnDepartureTime,returnArrivalTime,returnDepartureCode,returnArrivalCode,returnDuration,returnAirline,returnAircraftType,returnDepartureDateTime,returnArrivalDateTime,returnStops,numberOfBookableSeats,lastTicketingDate,basePrice,cabinClass,bookingClass,fareBasis,checkedBags,cabinBags]);

@override
String toString() {
  return 'Flight(id: $id, departureTime: $departureTime, arrivalTime: $arrivalTime, departureAirport: $departureAirport, departureCode: $departureCode, arrivalAirport: $arrivalAirport, arrivalCode: $arrivalCode, duration: $duration, airline: $airline, aircraftType: $aircraftType, price: $price, amenities: $amenities, departureDateTime: $departureDateTime, arrivalDateTime: $arrivalDateTime, outboundStops: $outboundStops, returnDepartureTime: $returnDepartureTime, returnArrivalTime: $returnArrivalTime, returnDepartureCode: $returnDepartureCode, returnArrivalCode: $returnArrivalCode, returnDuration: $returnDuration, returnAirline: $returnAirline, returnAircraftType: $returnAircraftType, returnDepartureDateTime: $returnDepartureDateTime, returnArrivalDateTime: $returnArrivalDateTime, returnStops: $returnStops, numberOfBookableSeats: $numberOfBookableSeats, lastTicketingDate: $lastTicketingDate, basePrice: $basePrice, cabinClass: $cabinClass, bookingClass: $bookingClass, fareBasis: $fareBasis, checkedBags: $checkedBags, cabinBags: $cabinBags)';
}


}

/// @nodoc
abstract mixin class $FlightCopyWith<$Res>  {
  factory $FlightCopyWith(Flight value, $Res Function(Flight) _then) = _$FlightCopyWithImpl;
@useResult
$Res call({
 String id, String departureTime, String arrivalTime, String departureAirport, String departureCode, String arrivalAirport, String arrivalCode, String duration, String? airline, String? aircraftType, double price, List<String> amenities, DateTime? departureDateTime, DateTime? arrivalDateTime, int outboundStops, String? returnDepartureTime, String? returnArrivalTime, String? returnDepartureCode, String? returnArrivalCode, String? returnDuration, String? returnAirline, String? returnAircraftType, DateTime? returnDepartureDateTime, DateTime? returnArrivalDateTime, int? returnStops, int numberOfBookableSeats, String lastTicketingDate, double basePrice, String cabinClass, String bookingClass, String fareBasis, BaggageInfo? checkedBags, BaggageInfo? cabinBags
});


$BaggageInfoCopyWith<$Res>? get checkedBags;$BaggageInfoCopyWith<$Res>? get cabinBags;

}
/// @nodoc
class _$FlightCopyWithImpl<$Res>
    implements $FlightCopyWith<$Res> {
  _$FlightCopyWithImpl(this._self, this._then);

  final Flight _self;
  final $Res Function(Flight) _then;

/// Create a copy of Flight
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? departureTime = null,Object? arrivalTime = null,Object? departureAirport = null,Object? departureCode = null,Object? arrivalAirport = null,Object? arrivalCode = null,Object? duration = null,Object? airline = freezed,Object? aircraftType = freezed,Object? price = null,Object? amenities = null,Object? departureDateTime = freezed,Object? arrivalDateTime = freezed,Object? outboundStops = null,Object? returnDepartureTime = freezed,Object? returnArrivalTime = freezed,Object? returnDepartureCode = freezed,Object? returnArrivalCode = freezed,Object? returnDuration = freezed,Object? returnAirline = freezed,Object? returnAircraftType = freezed,Object? returnDepartureDateTime = freezed,Object? returnArrivalDateTime = freezed,Object? returnStops = freezed,Object? numberOfBookableSeats = null,Object? lastTicketingDate = null,Object? basePrice = null,Object? cabinClass = null,Object? bookingClass = null,Object? fareBasis = null,Object? checkedBags = freezed,Object? cabinBags = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,departureTime: null == departureTime ? _self.departureTime : departureTime // ignore: cast_nullable_to_non_nullable
as String,arrivalTime: null == arrivalTime ? _self.arrivalTime : arrivalTime // ignore: cast_nullable_to_non_nullable
as String,departureAirport: null == departureAirport ? _self.departureAirport : departureAirport // ignore: cast_nullable_to_non_nullable
as String,departureCode: null == departureCode ? _self.departureCode : departureCode // ignore: cast_nullable_to_non_nullable
as String,arrivalAirport: null == arrivalAirport ? _self.arrivalAirport : arrivalAirport // ignore: cast_nullable_to_non_nullable
as String,arrivalCode: null == arrivalCode ? _self.arrivalCode : arrivalCode // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String,airline: freezed == airline ? _self.airline : airline // ignore: cast_nullable_to_non_nullable
as String?,aircraftType: freezed == aircraftType ? _self.aircraftType : aircraftType // ignore: cast_nullable_to_non_nullable
as String?,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,amenities: null == amenities ? _self.amenities : amenities // ignore: cast_nullable_to_non_nullable
as List<String>,departureDateTime: freezed == departureDateTime ? _self.departureDateTime : departureDateTime // ignore: cast_nullable_to_non_nullable
as DateTime?,arrivalDateTime: freezed == arrivalDateTime ? _self.arrivalDateTime : arrivalDateTime // ignore: cast_nullable_to_non_nullable
as DateTime?,outboundStops: null == outboundStops ? _self.outboundStops : outboundStops // ignore: cast_nullable_to_non_nullable
as int,returnDepartureTime: freezed == returnDepartureTime ? _self.returnDepartureTime : returnDepartureTime // ignore: cast_nullable_to_non_nullable
as String?,returnArrivalTime: freezed == returnArrivalTime ? _self.returnArrivalTime : returnArrivalTime // ignore: cast_nullable_to_non_nullable
as String?,returnDepartureCode: freezed == returnDepartureCode ? _self.returnDepartureCode : returnDepartureCode // ignore: cast_nullable_to_non_nullable
as String?,returnArrivalCode: freezed == returnArrivalCode ? _self.returnArrivalCode : returnArrivalCode // ignore: cast_nullable_to_non_nullable
as String?,returnDuration: freezed == returnDuration ? _self.returnDuration : returnDuration // ignore: cast_nullable_to_non_nullable
as String?,returnAirline: freezed == returnAirline ? _self.returnAirline : returnAirline // ignore: cast_nullable_to_non_nullable
as String?,returnAircraftType: freezed == returnAircraftType ? _self.returnAircraftType : returnAircraftType // ignore: cast_nullable_to_non_nullable
as String?,returnDepartureDateTime: freezed == returnDepartureDateTime ? _self.returnDepartureDateTime : returnDepartureDateTime // ignore: cast_nullable_to_non_nullable
as DateTime?,returnArrivalDateTime: freezed == returnArrivalDateTime ? _self.returnArrivalDateTime : returnArrivalDateTime // ignore: cast_nullable_to_non_nullable
as DateTime?,returnStops: freezed == returnStops ? _self.returnStops : returnStops // ignore: cast_nullable_to_non_nullable
as int?,numberOfBookableSeats: null == numberOfBookableSeats ? _self.numberOfBookableSeats : numberOfBookableSeats // ignore: cast_nullable_to_non_nullable
as int,lastTicketingDate: null == lastTicketingDate ? _self.lastTicketingDate : lastTicketingDate // ignore: cast_nullable_to_non_nullable
as String,basePrice: null == basePrice ? _self.basePrice : basePrice // ignore: cast_nullable_to_non_nullable
as double,cabinClass: null == cabinClass ? _self.cabinClass : cabinClass // ignore: cast_nullable_to_non_nullable
as String,bookingClass: null == bookingClass ? _self.bookingClass : bookingClass // ignore: cast_nullable_to_non_nullable
as String,fareBasis: null == fareBasis ? _self.fareBasis : fareBasis // ignore: cast_nullable_to_non_nullable
as String,checkedBags: freezed == checkedBags ? _self.checkedBags : checkedBags // ignore: cast_nullable_to_non_nullable
as BaggageInfo?,cabinBags: freezed == cabinBags ? _self.cabinBags : cabinBags // ignore: cast_nullable_to_non_nullable
as BaggageInfo?,
  ));
}
/// Create a copy of Flight
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BaggageInfoCopyWith<$Res>? get checkedBags {
    if (_self.checkedBags == null) {
    return null;
  }

  return $BaggageInfoCopyWith<$Res>(_self.checkedBags!, (value) {
    return _then(_self.copyWith(checkedBags: value));
  });
}/// Create a copy of Flight
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BaggageInfoCopyWith<$Res>? get cabinBags {
    if (_self.cabinBags == null) {
    return null;
  }

  return $BaggageInfoCopyWith<$Res>(_self.cabinBags!, (value) {
    return _then(_self.copyWith(cabinBags: value));
  });
}
}


/// Adds pattern-matching-related methods to [Flight].
extension FlightPatterns on Flight {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Flight value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Flight() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Flight value)  $default,){
final _that = this;
switch (_that) {
case _Flight():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Flight value)?  $default,){
final _that = this;
switch (_that) {
case _Flight() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String departureTime,  String arrivalTime,  String departureAirport,  String departureCode,  String arrivalAirport,  String arrivalCode,  String duration,  String? airline,  String? aircraftType,  double price,  List<String> amenities,  DateTime? departureDateTime,  DateTime? arrivalDateTime,  int outboundStops,  String? returnDepartureTime,  String? returnArrivalTime,  String? returnDepartureCode,  String? returnArrivalCode,  String? returnDuration,  String? returnAirline,  String? returnAircraftType,  DateTime? returnDepartureDateTime,  DateTime? returnArrivalDateTime,  int? returnStops,  int numberOfBookableSeats,  String lastTicketingDate,  double basePrice,  String cabinClass,  String bookingClass,  String fareBasis,  BaggageInfo? checkedBags,  BaggageInfo? cabinBags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Flight() when $default != null:
return $default(_that.id,_that.departureTime,_that.arrivalTime,_that.departureAirport,_that.departureCode,_that.arrivalAirport,_that.arrivalCode,_that.duration,_that.airline,_that.aircraftType,_that.price,_that.amenities,_that.departureDateTime,_that.arrivalDateTime,_that.outboundStops,_that.returnDepartureTime,_that.returnArrivalTime,_that.returnDepartureCode,_that.returnArrivalCode,_that.returnDuration,_that.returnAirline,_that.returnAircraftType,_that.returnDepartureDateTime,_that.returnArrivalDateTime,_that.returnStops,_that.numberOfBookableSeats,_that.lastTicketingDate,_that.basePrice,_that.cabinClass,_that.bookingClass,_that.fareBasis,_that.checkedBags,_that.cabinBags);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String departureTime,  String arrivalTime,  String departureAirport,  String departureCode,  String arrivalAirport,  String arrivalCode,  String duration,  String? airline,  String? aircraftType,  double price,  List<String> amenities,  DateTime? departureDateTime,  DateTime? arrivalDateTime,  int outboundStops,  String? returnDepartureTime,  String? returnArrivalTime,  String? returnDepartureCode,  String? returnArrivalCode,  String? returnDuration,  String? returnAirline,  String? returnAircraftType,  DateTime? returnDepartureDateTime,  DateTime? returnArrivalDateTime,  int? returnStops,  int numberOfBookableSeats,  String lastTicketingDate,  double basePrice,  String cabinClass,  String bookingClass,  String fareBasis,  BaggageInfo? checkedBags,  BaggageInfo? cabinBags)  $default,) {final _that = this;
switch (_that) {
case _Flight():
return $default(_that.id,_that.departureTime,_that.arrivalTime,_that.departureAirport,_that.departureCode,_that.arrivalAirport,_that.arrivalCode,_that.duration,_that.airline,_that.aircraftType,_that.price,_that.amenities,_that.departureDateTime,_that.arrivalDateTime,_that.outboundStops,_that.returnDepartureTime,_that.returnArrivalTime,_that.returnDepartureCode,_that.returnArrivalCode,_that.returnDuration,_that.returnAirline,_that.returnAircraftType,_that.returnDepartureDateTime,_that.returnArrivalDateTime,_that.returnStops,_that.numberOfBookableSeats,_that.lastTicketingDate,_that.basePrice,_that.cabinClass,_that.bookingClass,_that.fareBasis,_that.checkedBags,_that.cabinBags);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String departureTime,  String arrivalTime,  String departureAirport,  String departureCode,  String arrivalAirport,  String arrivalCode,  String duration,  String? airline,  String? aircraftType,  double price,  List<String> amenities,  DateTime? departureDateTime,  DateTime? arrivalDateTime,  int outboundStops,  String? returnDepartureTime,  String? returnArrivalTime,  String? returnDepartureCode,  String? returnArrivalCode,  String? returnDuration,  String? returnAirline,  String? returnAircraftType,  DateTime? returnDepartureDateTime,  DateTime? returnArrivalDateTime,  int? returnStops,  int numberOfBookableSeats,  String lastTicketingDate,  double basePrice,  String cabinClass,  String bookingClass,  String fareBasis,  BaggageInfo? checkedBags,  BaggageInfo? cabinBags)?  $default,) {final _that = this;
switch (_that) {
case _Flight() when $default != null:
return $default(_that.id,_that.departureTime,_that.arrivalTime,_that.departureAirport,_that.departureCode,_that.arrivalAirport,_that.arrivalCode,_that.duration,_that.airline,_that.aircraftType,_that.price,_that.amenities,_that.departureDateTime,_that.arrivalDateTime,_that.outboundStops,_that.returnDepartureTime,_that.returnArrivalTime,_that.returnDepartureCode,_that.returnArrivalCode,_that.returnDuration,_that.returnAirline,_that.returnAircraftType,_that.returnDepartureDateTime,_that.returnArrivalDateTime,_that.returnStops,_that.numberOfBookableSeats,_that.lastTicketingDate,_that.basePrice,_that.cabinClass,_that.bookingClass,_that.fareBasis,_that.checkedBags,_that.cabinBags);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Flight extends Flight {
  const _Flight({required this.id, required this.departureTime, required this.arrivalTime, required this.departureAirport, required this.departureCode, required this.arrivalAirport, required this.arrivalCode, required this.duration, this.airline, this.aircraftType, required this.price, final  List<String> amenities = const [], this.departureDateTime, this.arrivalDateTime, this.outboundStops = 0, this.returnDepartureTime, this.returnArrivalTime, this.returnDepartureCode, this.returnArrivalCode, this.returnDuration, this.returnAirline, this.returnAircraftType, this.returnDepartureDateTime, this.returnArrivalDateTime, this.returnStops, this.numberOfBookableSeats = 0, this.lastTicketingDate = '', this.basePrice = 0, this.cabinClass = 'Unknown', this.bookingClass = 'Unknown', this.fareBasis = 'Unknown', this.checkedBags, this.cabinBags}): _amenities = amenities,super._();
  factory _Flight.fromJson(Map<String, dynamic> json) => _$FlightFromJson(json);

@override final  String id;
@override final  String departureTime;
@override final  String arrivalTime;
@override final  String departureAirport;
@override final  String departureCode;
@override final  String arrivalAirport;
@override final  String arrivalCode;
@override final  String duration;
@override final  String? airline;
@override final  String? aircraftType;
@override final  double price;
 final  List<String> _amenities;
@override@JsonKey() List<String> get amenities {
  if (_amenities is EqualUnmodifiableListView) return _amenities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_amenities);
}

@override final  DateTime? departureDateTime;
@override final  DateTime? arrivalDateTime;
@override@JsonKey() final  int outboundStops;
// Return flight details (nullable)
@override final  String? returnDepartureTime;
@override final  String? returnArrivalTime;
@override final  String? returnDepartureCode;
@override final  String? returnArrivalCode;
@override final  String? returnDuration;
@override final  String? returnAirline;
@override final  String? returnAircraftType;
@override final  DateTime? returnDepartureDateTime;
@override final  DateTime? returnArrivalDateTime;
@override final  int? returnStops;
// Extra details
@override@JsonKey() final  int numberOfBookableSeats;
@override@JsonKey() final  String lastTicketingDate;
@override@JsonKey() final  double basePrice;
@override@JsonKey() final  String cabinClass;
@override@JsonKey() final  String bookingClass;
@override@JsonKey() final  String fareBasis;
@override final  BaggageInfo? checkedBags;
@override final  BaggageInfo? cabinBags;

/// Create a copy of Flight
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FlightCopyWith<_Flight> get copyWith => __$FlightCopyWithImpl<_Flight>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FlightToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Flight&&(identical(other.id, id) || other.id == id)&&(identical(other.departureTime, departureTime) || other.departureTime == departureTime)&&(identical(other.arrivalTime, arrivalTime) || other.arrivalTime == arrivalTime)&&(identical(other.departureAirport, departureAirport) || other.departureAirport == departureAirport)&&(identical(other.departureCode, departureCode) || other.departureCode == departureCode)&&(identical(other.arrivalAirport, arrivalAirport) || other.arrivalAirport == arrivalAirport)&&(identical(other.arrivalCode, arrivalCode) || other.arrivalCode == arrivalCode)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.airline, airline) || other.airline == airline)&&(identical(other.aircraftType, aircraftType) || other.aircraftType == aircraftType)&&(identical(other.price, price) || other.price == price)&&const DeepCollectionEquality().equals(other._amenities, _amenities)&&(identical(other.departureDateTime, departureDateTime) || other.departureDateTime == departureDateTime)&&(identical(other.arrivalDateTime, arrivalDateTime) || other.arrivalDateTime == arrivalDateTime)&&(identical(other.outboundStops, outboundStops) || other.outboundStops == outboundStops)&&(identical(other.returnDepartureTime, returnDepartureTime) || other.returnDepartureTime == returnDepartureTime)&&(identical(other.returnArrivalTime, returnArrivalTime) || other.returnArrivalTime == returnArrivalTime)&&(identical(other.returnDepartureCode, returnDepartureCode) || other.returnDepartureCode == returnDepartureCode)&&(identical(other.returnArrivalCode, returnArrivalCode) || other.returnArrivalCode == returnArrivalCode)&&(identical(other.returnDuration, returnDuration) || other.returnDuration == returnDuration)&&(identical(other.returnAirline, returnAirline) || other.returnAirline == returnAirline)&&(identical(other.returnAircraftType, returnAircraftType) || other.returnAircraftType == returnAircraftType)&&(identical(other.returnDepartureDateTime, returnDepartureDateTime) || other.returnDepartureDateTime == returnDepartureDateTime)&&(identical(other.returnArrivalDateTime, returnArrivalDateTime) || other.returnArrivalDateTime == returnArrivalDateTime)&&(identical(other.returnStops, returnStops) || other.returnStops == returnStops)&&(identical(other.numberOfBookableSeats, numberOfBookableSeats) || other.numberOfBookableSeats == numberOfBookableSeats)&&(identical(other.lastTicketingDate, lastTicketingDate) || other.lastTicketingDate == lastTicketingDate)&&(identical(other.basePrice, basePrice) || other.basePrice == basePrice)&&(identical(other.cabinClass, cabinClass) || other.cabinClass == cabinClass)&&(identical(other.bookingClass, bookingClass) || other.bookingClass == bookingClass)&&(identical(other.fareBasis, fareBasis) || other.fareBasis == fareBasis)&&(identical(other.checkedBags, checkedBags) || other.checkedBags == checkedBags)&&(identical(other.cabinBags, cabinBags) || other.cabinBags == cabinBags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,departureTime,arrivalTime,departureAirport,departureCode,arrivalAirport,arrivalCode,duration,airline,aircraftType,price,const DeepCollectionEquality().hash(_amenities),departureDateTime,arrivalDateTime,outboundStops,returnDepartureTime,returnArrivalTime,returnDepartureCode,returnArrivalCode,returnDuration,returnAirline,returnAircraftType,returnDepartureDateTime,returnArrivalDateTime,returnStops,numberOfBookableSeats,lastTicketingDate,basePrice,cabinClass,bookingClass,fareBasis,checkedBags,cabinBags]);

@override
String toString() {
  return 'Flight(id: $id, departureTime: $departureTime, arrivalTime: $arrivalTime, departureAirport: $departureAirport, departureCode: $departureCode, arrivalAirport: $arrivalAirport, arrivalCode: $arrivalCode, duration: $duration, airline: $airline, aircraftType: $aircraftType, price: $price, amenities: $amenities, departureDateTime: $departureDateTime, arrivalDateTime: $arrivalDateTime, outboundStops: $outboundStops, returnDepartureTime: $returnDepartureTime, returnArrivalTime: $returnArrivalTime, returnDepartureCode: $returnDepartureCode, returnArrivalCode: $returnArrivalCode, returnDuration: $returnDuration, returnAirline: $returnAirline, returnAircraftType: $returnAircraftType, returnDepartureDateTime: $returnDepartureDateTime, returnArrivalDateTime: $returnArrivalDateTime, returnStops: $returnStops, numberOfBookableSeats: $numberOfBookableSeats, lastTicketingDate: $lastTicketingDate, basePrice: $basePrice, cabinClass: $cabinClass, bookingClass: $bookingClass, fareBasis: $fareBasis, checkedBags: $checkedBags, cabinBags: $cabinBags)';
}


}

/// @nodoc
abstract mixin class _$FlightCopyWith<$Res> implements $FlightCopyWith<$Res> {
  factory _$FlightCopyWith(_Flight value, $Res Function(_Flight) _then) = __$FlightCopyWithImpl;
@override @useResult
$Res call({
 String id, String departureTime, String arrivalTime, String departureAirport, String departureCode, String arrivalAirport, String arrivalCode, String duration, String? airline, String? aircraftType, double price, List<String> amenities, DateTime? departureDateTime, DateTime? arrivalDateTime, int outboundStops, String? returnDepartureTime, String? returnArrivalTime, String? returnDepartureCode, String? returnArrivalCode, String? returnDuration, String? returnAirline, String? returnAircraftType, DateTime? returnDepartureDateTime, DateTime? returnArrivalDateTime, int? returnStops, int numberOfBookableSeats, String lastTicketingDate, double basePrice, String cabinClass, String bookingClass, String fareBasis, BaggageInfo? checkedBags, BaggageInfo? cabinBags
});


@override $BaggageInfoCopyWith<$Res>? get checkedBags;@override $BaggageInfoCopyWith<$Res>? get cabinBags;

}
/// @nodoc
class __$FlightCopyWithImpl<$Res>
    implements _$FlightCopyWith<$Res> {
  __$FlightCopyWithImpl(this._self, this._then);

  final _Flight _self;
  final $Res Function(_Flight) _then;

/// Create a copy of Flight
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? departureTime = null,Object? arrivalTime = null,Object? departureAirport = null,Object? departureCode = null,Object? arrivalAirport = null,Object? arrivalCode = null,Object? duration = null,Object? airline = freezed,Object? aircraftType = freezed,Object? price = null,Object? amenities = null,Object? departureDateTime = freezed,Object? arrivalDateTime = freezed,Object? outboundStops = null,Object? returnDepartureTime = freezed,Object? returnArrivalTime = freezed,Object? returnDepartureCode = freezed,Object? returnArrivalCode = freezed,Object? returnDuration = freezed,Object? returnAirline = freezed,Object? returnAircraftType = freezed,Object? returnDepartureDateTime = freezed,Object? returnArrivalDateTime = freezed,Object? returnStops = freezed,Object? numberOfBookableSeats = null,Object? lastTicketingDate = null,Object? basePrice = null,Object? cabinClass = null,Object? bookingClass = null,Object? fareBasis = null,Object? checkedBags = freezed,Object? cabinBags = freezed,}) {
  return _then(_Flight(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,departureTime: null == departureTime ? _self.departureTime : departureTime // ignore: cast_nullable_to_non_nullable
as String,arrivalTime: null == arrivalTime ? _self.arrivalTime : arrivalTime // ignore: cast_nullable_to_non_nullable
as String,departureAirport: null == departureAirport ? _self.departureAirport : departureAirport // ignore: cast_nullable_to_non_nullable
as String,departureCode: null == departureCode ? _self.departureCode : departureCode // ignore: cast_nullable_to_non_nullable
as String,arrivalAirport: null == arrivalAirport ? _self.arrivalAirport : arrivalAirport // ignore: cast_nullable_to_non_nullable
as String,arrivalCode: null == arrivalCode ? _self.arrivalCode : arrivalCode // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String,airline: freezed == airline ? _self.airline : airline // ignore: cast_nullable_to_non_nullable
as String?,aircraftType: freezed == aircraftType ? _self.aircraftType : aircraftType // ignore: cast_nullable_to_non_nullable
as String?,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,amenities: null == amenities ? _self._amenities : amenities // ignore: cast_nullable_to_non_nullable
as List<String>,departureDateTime: freezed == departureDateTime ? _self.departureDateTime : departureDateTime // ignore: cast_nullable_to_non_nullable
as DateTime?,arrivalDateTime: freezed == arrivalDateTime ? _self.arrivalDateTime : arrivalDateTime // ignore: cast_nullable_to_non_nullable
as DateTime?,outboundStops: null == outboundStops ? _self.outboundStops : outboundStops // ignore: cast_nullable_to_non_nullable
as int,returnDepartureTime: freezed == returnDepartureTime ? _self.returnDepartureTime : returnDepartureTime // ignore: cast_nullable_to_non_nullable
as String?,returnArrivalTime: freezed == returnArrivalTime ? _self.returnArrivalTime : returnArrivalTime // ignore: cast_nullable_to_non_nullable
as String?,returnDepartureCode: freezed == returnDepartureCode ? _self.returnDepartureCode : returnDepartureCode // ignore: cast_nullable_to_non_nullable
as String?,returnArrivalCode: freezed == returnArrivalCode ? _self.returnArrivalCode : returnArrivalCode // ignore: cast_nullable_to_non_nullable
as String?,returnDuration: freezed == returnDuration ? _self.returnDuration : returnDuration // ignore: cast_nullable_to_non_nullable
as String?,returnAirline: freezed == returnAirline ? _self.returnAirline : returnAirline // ignore: cast_nullable_to_non_nullable
as String?,returnAircraftType: freezed == returnAircraftType ? _self.returnAircraftType : returnAircraftType // ignore: cast_nullable_to_non_nullable
as String?,returnDepartureDateTime: freezed == returnDepartureDateTime ? _self.returnDepartureDateTime : returnDepartureDateTime // ignore: cast_nullable_to_non_nullable
as DateTime?,returnArrivalDateTime: freezed == returnArrivalDateTime ? _self.returnArrivalDateTime : returnArrivalDateTime // ignore: cast_nullable_to_non_nullable
as DateTime?,returnStops: freezed == returnStops ? _self.returnStops : returnStops // ignore: cast_nullable_to_non_nullable
as int?,numberOfBookableSeats: null == numberOfBookableSeats ? _self.numberOfBookableSeats : numberOfBookableSeats // ignore: cast_nullable_to_non_nullable
as int,lastTicketingDate: null == lastTicketingDate ? _self.lastTicketingDate : lastTicketingDate // ignore: cast_nullable_to_non_nullable
as String,basePrice: null == basePrice ? _self.basePrice : basePrice // ignore: cast_nullable_to_non_nullable
as double,cabinClass: null == cabinClass ? _self.cabinClass : cabinClass // ignore: cast_nullable_to_non_nullable
as String,bookingClass: null == bookingClass ? _self.bookingClass : bookingClass // ignore: cast_nullable_to_non_nullable
as String,fareBasis: null == fareBasis ? _self.fareBasis : fareBasis // ignore: cast_nullable_to_non_nullable
as String,checkedBags: freezed == checkedBags ? _self.checkedBags : checkedBags // ignore: cast_nullable_to_non_nullable
as BaggageInfo?,cabinBags: freezed == cabinBags ? _self.cabinBags : cabinBags // ignore: cast_nullable_to_non_nullable
as BaggageInfo?,
  ));
}

/// Create a copy of Flight
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BaggageInfoCopyWith<$Res>? get checkedBags {
    if (_self.checkedBags == null) {
    return null;
  }

  return $BaggageInfoCopyWith<$Res>(_self.checkedBags!, (value) {
    return _then(_self.copyWith(checkedBags: value));
  });
}/// Create a copy of Flight
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BaggageInfoCopyWith<$Res>? get cabinBags {
    if (_self.cabinBags == null) {
    return null;
  }

  return $BaggageInfoCopyWith<$Res>(_self.cabinBags!, (value) {
    return _then(_self.copyWith(cabinBags: value));
  });
}
}

// dart format on
