import 'package:bagtrip/flightSearchResult/models/baggage_info.dart';

class Flight {
  final String id;
  final String? databaseOfferId; // Database offer ID from FlightSearchResponse
  final String departureTime;
  final String arrivalTime;
  final String departureAirport;
  final String departureCode;
  final String arrivalAirport;
  final String arrivalCode;
  final String duration;
  final String? airline;
  final String? aircraftType;
  final double price;
  final List<String> amenities;
  final DateTime? departureDateTime;
  final DateTime? arrivalDateTime;
  final int outboundStops;

  // Return flight details (nullable)
  final String? returnDepartureTime;
  final String? returnArrivalTime;
  final String? returnDepartureCode;
  final String? returnArrivalCode;
  final String? returnDuration;
  final String? returnAirline;
  final String? returnAircraftType;
  final DateTime? returnDepartureDateTime;
  final DateTime? returnArrivalDateTime;
  final int? returnStops;

  // New fields for details
  final int numberOfBookableSeats;
  final String lastTicketingDate;
  final double basePrice;
  final String cabinClass;
  final String bookingClass;
  final String fareBasis;
  final BaggageInfo? checkedBags;
  final BaggageInfo? cabinBags;

  Flight({
    required this.id,
    this.databaseOfferId,
    required this.departureTime,
    required this.arrivalTime,
    required this.departureAirport,
    required this.departureCode,
    required this.arrivalAirport,
    required this.arrivalCode,
    required this.duration,
    this.airline,
    this.aircraftType,
    required this.price,
    required this.amenities,
    this.departureDateTime,
    this.arrivalDateTime,
    this.outboundStops = 0,
    this.returnDepartureTime,
    this.returnArrivalTime,
    this.returnDepartureCode,
    this.returnArrivalCode,
    this.returnDuration,
    this.returnAirline,
    this.returnAircraftType,
    this.returnDepartureDateTime,
    this.returnArrivalDateTime,
    this.returnStops,
    required this.numberOfBookableSeats,
    required this.lastTicketingDate,
    required this.basePrice,
    required this.cabinClass,
    required this.bookingClass,
    required this.fareBasis,
    this.checkedBags,
    this.cabinBags,
  });

  factory Flight.fromAmadeusJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? dictionaries,
    String? databaseOfferId,
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
    final mainAirlineCode =
        validatingAirlineCodes?.isNotEmpty == true
            ? validatingAirlineCodes![0]
            : null;

    final mainAirlineName =
        mainAirlineCode != null
            ? lookupDictionary('carriers', mainAirlineCode)
            : null;

    // Parse itineraries
    // (Already checked above)

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
    final outboundAircraftName =
        outboundAircraftCode != null
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
        retAir = mainAirlineName; // Usually same airline for return

        final returnAircraftCode = returnFirst['aircraft']?['code'];
        retAircraft =
            returnAircraftCode != null
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
        // Try direct parse
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
        // Try extracting digits
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

    // Extract Traveler Pricing (first traveler, first segment usually)
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

        // Baggage
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
      databaseOfferId: databaseOfferId,
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

  Flight copyWith({
    String? id,
    String? databaseOfferId,
    String? departureTime,
    String? arrivalTime,
    String? departureAirport,
    String? departureCode,
    String? arrivalAirport,
    String? arrivalCode,
    String? duration,
    String? airline,
    String? aircraftType,
    double? price,
    List<String>? amenities,
    DateTime? departureDateTime,
    DateTime? arrivalDateTime,
    int? outboundStops,
    String? returnDepartureTime,
    String? returnArrivalTime,
    String? returnDepartureCode,
    String? returnArrivalCode,
    String? returnDuration,
    String? returnAirline,
    String? returnAircraftType,
    DateTime? returnDepartureDateTime,
    DateTime? returnArrivalDateTime,
    int? returnStops,
    int? numberOfBookableSeats,
    String? lastTicketingDate,
    double? basePrice,
    String? cabinClass,
    String? bookingClass,
    String? fareBasis,
    BaggageInfo? checkedBags,
    BaggageInfo? cabinBags,
  }) {
    return Flight(
      id: id ?? this.id,
      databaseOfferId: databaseOfferId ?? this.databaseOfferId,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      departureAirport: departureAirport ?? this.departureAirport,
      departureCode: departureCode ?? this.departureCode,
      arrivalAirport: arrivalAirport ?? this.arrivalAirport,
      arrivalCode: arrivalCode ?? this.arrivalCode,
      duration: duration ?? this.duration,
      airline: airline ?? this.airline,
      aircraftType: aircraftType ?? this.aircraftType,
      price: price ?? this.price,
      amenities: amenities ?? this.amenities,
      departureDateTime: departureDateTime ?? this.departureDateTime,
      arrivalDateTime: arrivalDateTime ?? this.arrivalDateTime,
      outboundStops: outboundStops ?? this.outboundStops,
      returnDepartureTime: returnDepartureTime ?? this.returnDepartureTime,
      returnArrivalTime: returnArrivalTime ?? this.returnArrivalTime,
      returnDepartureCode: returnDepartureCode ?? this.returnDepartureCode,
      returnArrivalCode: returnArrivalCode ?? this.returnArrivalCode,
      returnDuration: returnDuration ?? this.returnDuration,
      returnAirline: returnAirline ?? this.returnAirline,
      returnAircraftType: returnAircraftType ?? this.returnAircraftType,
      returnDepartureDateTime:
          returnDepartureDateTime ?? this.returnDepartureDateTime,
      returnArrivalDateTime:
          returnArrivalDateTime ?? this.returnArrivalDateTime,
      returnStops: returnStops ?? this.returnStops,
      numberOfBookableSeats:
          numberOfBookableSeats ?? this.numberOfBookableSeats,
      lastTicketingDate: lastTicketingDate ?? this.lastTicketingDate,
      basePrice: basePrice ?? this.basePrice,
      cabinClass: cabinClass ?? this.cabinClass,
      bookingClass: bookingClass ?? this.bookingClass,
      fareBasis: fareBasis ?? this.fareBasis,
      checkedBags: checkedBags ?? this.checkedBags,
      cabinBags: cabinBags ?? this.cabinBags,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Flight && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
