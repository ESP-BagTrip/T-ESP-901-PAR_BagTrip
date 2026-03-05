class FlightSegment {
  final Map<String, dynamic>? departureAirport;
  final Map<String, dynamic>? arrivalAirport;
  final DateTime? departureDate;

  FlightSegment({
    this.departureAirport,
    this.arrivalAirport,
    this.departureDate,
  });

  FlightSegment copyWith({
    Map<String, dynamic>? departureAirport,
    Map<String, dynamic>? arrivalAirport,
    DateTime? departureDate,
  }) {
    return FlightSegment(
      departureAirport: departureAirport ?? this.departureAirport,
      arrivalAirport: arrivalAirport ?? this.arrivalAirport,
      departureDate: departureDate ?? this.departureDate,
    );
  }
}
