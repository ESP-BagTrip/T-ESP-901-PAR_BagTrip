// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flight.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Flight _$FlightFromJson(Map<String, dynamic> json) => _Flight(
  id: json['id'] as String,
  departureTime: json['departureTime'] as String,
  arrivalTime: json['arrivalTime'] as String,
  departureAirport: json['departureAirport'] as String,
  departureCode: json['departureCode'] as String,
  arrivalAirport: json['arrivalAirport'] as String,
  arrivalCode: json['arrivalCode'] as String,
  duration: json['duration'] as String,
  airline: json['airline'] as String?,
  aircraftType: json['aircraftType'] as String?,
  price: (json['price'] as num).toDouble(),
  amenities:
      (json['amenities'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  departureDateTime: json['departureDateTime'] == null
      ? null
      : DateTime.parse(json['departureDateTime'] as String),
  arrivalDateTime: json['arrivalDateTime'] == null
      ? null
      : DateTime.parse(json['arrivalDateTime'] as String),
  outboundStops: (json['outboundStops'] as num?)?.toInt() ?? 0,
  returnDepartureTime: json['returnDepartureTime'] as String?,
  returnArrivalTime: json['returnArrivalTime'] as String?,
  returnDepartureCode: json['returnDepartureCode'] as String?,
  returnArrivalCode: json['returnArrivalCode'] as String?,
  returnDuration: json['returnDuration'] as String?,
  returnAirline: json['returnAirline'] as String?,
  returnAircraftType: json['returnAircraftType'] as String?,
  returnDepartureDateTime: json['returnDepartureDateTime'] == null
      ? null
      : DateTime.parse(json['returnDepartureDateTime'] as String),
  returnArrivalDateTime: json['returnArrivalDateTime'] == null
      ? null
      : DateTime.parse(json['returnArrivalDateTime'] as String),
  returnStops: (json['returnStops'] as num?)?.toInt(),
  numberOfBookableSeats: (json['numberOfBookableSeats'] as num?)?.toInt() ?? 0,
  lastTicketingDate: json['lastTicketingDate'] as String? ?? '',
  basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0,
  cabinClass: json['cabinClass'] as String? ?? 'Unknown',
  bookingClass: json['bookingClass'] as String? ?? 'Unknown',
  fareBasis: json['fareBasis'] as String? ?? 'Unknown',
  checkedBags: json['checkedBags'] == null
      ? null
      : BaggageInfo.fromJson(json['checkedBags'] as Map<String, dynamic>),
  cabinBags: json['cabinBags'] == null
      ? null
      : BaggageInfo.fromJson(json['cabinBags'] as Map<String, dynamic>),
);

Map<String, dynamic> _$FlightToJson(_Flight instance) => <String, dynamic>{
  'id': instance.id,
  'departureTime': instance.departureTime,
  'arrivalTime': instance.arrivalTime,
  'departureAirport': instance.departureAirport,
  'departureCode': instance.departureCode,
  'arrivalAirport': instance.arrivalAirport,
  'arrivalCode': instance.arrivalCode,
  'duration': instance.duration,
  'airline': instance.airline,
  'aircraftType': instance.aircraftType,
  'price': instance.price,
  'amenities': instance.amenities,
  'departureDateTime': instance.departureDateTime?.toIso8601String(),
  'arrivalDateTime': instance.arrivalDateTime?.toIso8601String(),
  'outboundStops': instance.outboundStops,
  'returnDepartureTime': instance.returnDepartureTime,
  'returnArrivalTime': instance.returnArrivalTime,
  'returnDepartureCode': instance.returnDepartureCode,
  'returnArrivalCode': instance.returnArrivalCode,
  'returnDuration': instance.returnDuration,
  'returnAirline': instance.returnAirline,
  'returnAircraftType': instance.returnAircraftType,
  'returnDepartureDateTime': instance.returnDepartureDateTime
      ?.toIso8601String(),
  'returnArrivalDateTime': instance.returnArrivalDateTime?.toIso8601String(),
  'returnStops': instance.returnStops,
  'numberOfBookableSeats': instance.numberOfBookableSeats,
  'lastTicketingDate': instance.lastTicketingDate,
  'basePrice': instance.basePrice,
  'cabinClass': instance.cabinClass,
  'bookingClass': instance.bookingClass,
  'fareBasis': instance.fareBasis,
  'checkedBags': instance.checkedBags?.toJson(),
  'cabinBags': instance.cabinBags?.toJson(),
};
