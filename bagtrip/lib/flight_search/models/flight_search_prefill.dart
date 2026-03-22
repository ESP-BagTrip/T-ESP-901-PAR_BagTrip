class FlightSearchPrefill {
  final String? originIata;
  final String? destinationIata;
  final DateTime? departureDate;
  final DateTime? returnDate;
  final int? nbTravelers;

  const FlightSearchPrefill({
    this.originIata,
    this.destinationIata,
    this.departureDate,
    this.returnDate,
    this.nbTravelers,
  });
}
