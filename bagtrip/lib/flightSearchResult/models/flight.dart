class Flight {
  final String id;
  final String departureTime;
  final String arrivalTime;
  final String departureAirport;
  final String departureCode;
  final String arrivalAirport;
  final String arrivalCode;
  final String duration;
  final String airline;
  final String aircraftType;
  final double price;
  final List<String> amenities;
  final int co2Offset;

  Flight({
    required this.id,
    required this.departureTime,
    required this.arrivalTime,
    required this.departureAirport,
    required this.departureCode,
    required this.arrivalAirport,
    required this.arrivalCode,
    required this.duration,
    required this.airline,
    required this.aircraftType,
    required this.price,
    required this.amenities,
    required this.co2Offset,
  });

  factory Flight.fromAmadeusJson(Map<String, dynamic> json) {
    // Helper to safely get deep nested values
    // ignore: unused_element
    dynamic getPath(Map<String, dynamic> obj, List<String> path) {
      dynamic current = obj;
      for (var key in path) {
        if (current is Map && current.containsKey(key)) {
          current = current[key];
        } else {
          return null;
        }
      }
      return current;
    }

    // Parse itineraries
    final itineraries = json['itineraries'] as List?;
    if (itineraries == null || itineraries.isEmpty) {
      throw Exception('No itineraries found in flight offer');
    }

    final firstItinerary = itineraries[0];
    final segments = firstItinerary['segments'] as List?;
    if (segments == null || segments.isEmpty) {
      throw Exception('No segments found in itinerary');
    }

    final firstSegment = segments.first;
    final lastSegment = segments.last;

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

    // Format duration (PT1H30M -> 1h30)
    String formatDuration(String? durationIso) {
      if (durationIso == null) return '';
      String duration = durationIso.replaceAll('PT', '').toLowerCase();
      return duration;
    }

    // Extract price
    final priceMap = json['price'];
    final grandTotal =
        double.tryParse(priceMap?['grandTotal']?.toString() ?? '0') ?? 0.0;

    // Extract Airline (validating carrier)
    final validatingAirlineCodes = json['validatingAirlineCodes'] as List?;
    final airlineCode =
        validatingAirlineCodes?.isNotEmpty == true
            ? validatingAirlineCodes![0]
            : 'Unknown Airline';

    // Departure/Arrival info
    final departure = firstSegment['departure'];
    final arrival = lastSegment['arrival'];

    return Flight(
      id: json['id']?.toString() ?? '',
      departureTime: formatTime(departure?['at']),
      arrivalTime: formatTime(arrival?['at']),
      departureAirport: departure?['iataCode'] ?? '',
      departureCode:
          '${departure?['iataCode'] ?? ''} ${departure?['terminal'] != null ? 'T${departure?['terminal']}' : ''}'
              .trim(),
      arrivalAirport: arrival?['iataCode'] ?? '',
      arrivalCode:
          '${arrival?['iataCode'] ?? ''} ${arrival?['terminal'] != null ? 'T${arrival?['terminal']}' : ''}'
              .trim(),
      duration: formatDuration(firstItinerary['duration']),
      airline: airlineCode, // In a real app, map code to name
      aircraftType: firstSegment['aircraft']?['code'] ?? 'Unknown',
      price: grandTotal,
      amenities: [
        'Bagage inclus',
      ], // Placeholder as detailed amenities might need extra parsing
      co2Offset: 0, // Placeholder
    );
  }

  Flight copyWith({
    String? id,
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
    int? co2Offset,
  }) {
    return Flight(
      id: id ?? this.id,
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
      co2Offset: co2Offset ?? this.co2Offset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Flight && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
