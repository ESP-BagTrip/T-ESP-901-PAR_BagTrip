import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:bagtrip/flight_search_result/models/baggage_info.dart';

part 'flight.freezed.dart';
part 'flight.g.dart';

@freezed
abstract class Flight with _$Flight {
  const Flight._();

  const factory Flight({
    required String id,
    @JsonKey(name: 'departureTime') required String departureTime,
    @JsonKey(name: 'arrivalTime') required String arrivalTime,
    @JsonKey(name: 'departureAirport') required String departureAirport,
    @JsonKey(name: 'departureCode') required String departureCode,
    @JsonKey(name: 'arrivalAirport') required String arrivalAirport,
    @JsonKey(name: 'arrivalCode') required String arrivalCode,
    required String duration,
    String? airline,
    @JsonKey(name: 'aircraftType') String? aircraftType,
    required double price,
    @Default([]) List<String> amenities,
    @JsonKey(name: 'departureDateTime') DateTime? departureDateTime,
    @JsonKey(name: 'arrivalDateTime') DateTime? arrivalDateTime,
    @JsonKey(name: 'outboundStops') @Default(0) int outboundStops,

    // Return flight details (nullable)
    @JsonKey(name: 'returnDepartureTime') String? returnDepartureTime,
    @JsonKey(name: 'returnArrivalTime') String? returnArrivalTime,
    @JsonKey(name: 'returnDepartureCode') String? returnDepartureCode,
    @JsonKey(name: 'returnArrivalCode') String? returnArrivalCode,
    @JsonKey(name: 'returnDuration') String? returnDuration,
    @JsonKey(name: 'returnAirline') String? returnAirline,
    @JsonKey(name: 'returnAircraftType') String? returnAircraftType,
    @JsonKey(name: 'returnDepartureDateTime') DateTime? returnDepartureDateTime,
    @JsonKey(name: 'returnArrivalDateTime') DateTime? returnArrivalDateTime,
    @JsonKey(name: 'returnStops') int? returnStops,

    // Extra details
    @JsonKey(name: 'numberOfBookableSeats')
    @Default(0)
    int numberOfBookableSeats,
    @JsonKey(name: 'lastTicketingDate') @Default('') String lastTicketingDate,
    @JsonKey(name: 'basePrice') @Default(0) double basePrice,
    @JsonKey(name: 'cabinClass') @Default('Unknown') String cabinClass,
    @JsonKey(name: 'bookingClass') @Default('Unknown') String bookingClass,
    @JsonKey(name: 'fareBasis') @Default('Unknown') String fareBasis,
    @JsonKey(name: 'checkedBags') BaggageInfo? checkedBags,
    @JsonKey(name: 'cabinBags') BaggageInfo? cabinBags,

    // Booking context (set when search is tied to a trip)
    @JsonKey(name: 'trip_id') String? tripId,
    @JsonKey(name: 'flight_offer_id') String? flightOfferId,
  }) = _Flight;

  factory Flight.fromJson(Map<String, dynamic> json) => _$FlightFromJson(json);

  /// Parse depuis la réponse Amadeus (logique custom préservée)
  static Flight fromAmadeusJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? dictionaries,
  }) {
    // Helper to lookup dictionary values
    String? lookupDictionary(String type, String code) {
      if (dictionaries == null) return null;
      final dict = dictionaries[type];
      if (dict is Map && dict.containsKey(code)) {
        return dict[code].toString();
      }
      return null;
    }

    // Parse itineraries
    final itineraries = json['itineraries'] as List?;
    if (itineraries == null || itineraries.isEmpty) {
      throw Exception('No itineraries found in flight offer');
    }

    // Format times
    String formatTime(String? dateTimeStr) {
      if (dateTimeStr == null) return '';
      try {
        final dt = DateTime.parse(dateTimeStr);
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        return dateTimeStr;
      }
    }

    DateTime? parseDateTime(String? dateTimeStr) {
      if (dateTimeStr == null) return null;
      try {
        return DateTime.parse(dateTimeStr);
      } catch (e) {
        return null;
      }
    }

    // Format duration (PT1H30M -> 1h30)
    String formatDuration(String? durationIso) {
      if (durationIso == null) return '';
      String duration = durationIso.replaceAll('PT', '').toLowerCase();
      return duration;
    }

    // Helper to extract validating airline
    final validatingAirlineCodes = json['validatingAirlineCodes'] as List?;
    final mainAirlineCode = validatingAirlineCodes?.isNotEmpty == true
        ? validatingAirlineCodes![0]
        : null;

    final mainAirlineName = mainAirlineCode != null
        ? lookupDictionary('carriers', mainAirlineCode)
        : null;

    // --- Outbound Parsing ---
    final outboundItinerary = itineraries[0];
    final outboundSegments = outboundItinerary['segments'] as List?;
    if (outboundSegments == null || outboundSegments.isEmpty) {
      throw Exception('No segments found in outbound itinerary');
    }
    final outboundFirst = outboundSegments.first;
    final outboundLast = outboundSegments.last;
    final outboundStops = outboundSegments.length - 1;

    final outboundAircraftCode = outboundFirst['aircraft']?['code'];
    final outboundAircraftName = outboundAircraftCode != null
        ? lookupDictionary('aircraft', outboundAircraftCode)
        : null;

    // --- Return Parsing (if exists) ---
    String? retDepTime,
        retArrTime,
        retDepCode,
        retArrCode,
        retDur,
        retAir,
        retAircraft;
    DateTime? retDepDate, retArrDate;
    int? retStops;

    if (itineraries.length > 1) {
      final returnItinerary = itineraries[1];
      final returnSegments = returnItinerary['segments'] as List?;
      if (returnSegments != null && returnSegments.isNotEmpty) {
        final returnFirst = returnSegments.first;
        final returnLast = returnSegments.last;
        retStops = returnSegments.length - 1;

        retDepTime = formatTime(returnFirst['departure']?['at']);
        retArrTime = formatTime(returnLast['arrival']?['at']);
        retDepCode =
            '${returnFirst['departure']?['iataCode'] ?? ''} ${returnFirst['departure']?['terminal'] != null ? 'T${returnFirst['departure']?['terminal']}' : ''}'
                .trim();
        retArrCode =
            '${returnLast['arrival']?['iataCode'] ?? ''} ${returnLast['arrival']?['terminal'] != null ? 'T${returnLast['arrival']?['terminal']}' : ''}'
                .trim();
        retDur = formatDuration(returnItinerary['duration']);
        retAir = mainAirlineName;

        final returnAircraftCode = returnFirst['aircraft']?['code'];
        retAircraft = returnAircraftCode != null
            ? lookupDictionary('aircraft', returnAircraftCode)
            : null;

        retDepDate = parseDateTime(returnFirst['departure']?['at']);
        retArrDate = parseDateTime(returnLast['arrival']?['at']);
      }
    }

    // Helper to robustly parse integers (e.g. "2 PCS" -> 2)
    int? parseIntSafe(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
        final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
        return int.tryParse(digits);
      }
      return null;
    }

    // Extract price
    final priceMap = json['price'];
    final grandTotal =
        double.tryParse(priceMap?['grandTotal']?.toString() ?? '0') ?? 0.0;
    final basePrice =
        double.tryParse(priceMap?['base']?.toString() ?? '0') ?? 0.0;

    // Extract extra details
    final numberOfBookableSeats =
        int.tryParse(json['numberOfBookableSeats']?.toString() ?? '0') ?? 0;
    final lastTicketingDate = json['lastTicketingDate']?.toString() ?? '';

    // Extract Traveler Pricing
    String cabinClass = 'Unknown';
    String bookingClass = 'Unknown';
    String fareBasis = 'Unknown';
    BaggageInfo? checkedBags;
    BaggageInfo? cabinBags;

    final travelerPricings = json['travelerPricings'] as List?;
    if (travelerPricings != null && travelerPricings.isNotEmpty) {
      final firstTraveler = travelerPricings[0];
      final fareDetails = firstTraveler['fareDetailsBySegment'] as List?;
      if (fareDetails != null && fareDetails.isNotEmpty) {
        final firstSegmentDetails = fareDetails[0];
        cabinClass = firstSegmentDetails['cabin'] ?? 'Unknown';
        bookingClass = firstSegmentDetails['class'] ?? 'Unknown';
        fareBasis = firstSegmentDetails['fareBasis'] ?? 'Unknown';

        final checked = firstSegmentDetails['includedCheckedBags'];
        if (checked != null) {
          final q = parseIntSafe(checked['quantity']);
          final w = parseIntSafe(checked['weight']);
          checkedBags = BaggageInfo(
            quantity: q,
            weight: w,
            weightUnit: checked['weightUnit'],
          );
        }

        final cabin = firstSegmentDetails['includedCabinBags'];
        if (cabin != null) {
          final q = parseIntSafe(cabin['quantity']);
          final w = parseIntSafe(cabin['weight']);
          cabinBags = BaggageInfo(
            quantity: q,
            weight: w,
            weightUnit: cabin['weightUnit'],
          );
        }
      }
    }

    return Flight(
      id: json['id']?.toString() ?? '',
      departureTime: formatTime(outboundFirst['departure']?['at']),
      arrivalTime: formatTime(outboundLast['arrival']?['at']),
      departureAirport: outboundFirst['departure']?['iataCode'] ?? '',
      departureCode:
          '${outboundFirst['departure']?['iataCode'] ?? ''} ${outboundFirst['departure']?['terminal'] != null ? 'T${outboundFirst['departure']?['terminal']}' : ''}'
              .trim(),
      arrivalAirport: outboundLast['arrival']?['iataCode'] ?? '',
      arrivalCode:
          '${outboundLast['arrival']?['iataCode'] ?? ''} ${outboundLast['arrival']?['terminal'] != null ? 'T${outboundLast['arrival']?['terminal']}' : ''}'
              .trim(),
      duration: formatDuration(outboundItinerary['duration']),
      airline: mainAirlineName,
      aircraftType: outboundAircraftName,
      price: grandTotal,
      amenities: [],
      departureDateTime: parseDateTime(outboundFirst['departure']?['at']),
      arrivalDateTime: parseDateTime(outboundLast['arrival']?['at']),
      outboundStops: outboundStops,
      returnDepartureTime: retDepTime,
      returnArrivalTime: retArrTime,
      returnDepartureCode: retDepCode,
      returnArrivalCode: retArrCode,
      returnDuration: retDur,
      returnAirline: retAir,
      returnAircraftType: retAircraft,
      returnDepartureDateTime: retDepDate,
      returnArrivalDateTime: retArrDate,
      returnStops: retStops,
      numberOfBookableSeats: numberOfBookableSeats,
      lastTicketingDate: lastTicketingDate,
      basePrice: basePrice,
      cabinClass: cabinClass,
      bookingClass: bookingClass,
      fareBasis: fareBasis,
      checkedBags: checkedBags,
      cabinBags: cabinBags,
    );
  }
}
