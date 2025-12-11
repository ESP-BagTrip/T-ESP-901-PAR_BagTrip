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
