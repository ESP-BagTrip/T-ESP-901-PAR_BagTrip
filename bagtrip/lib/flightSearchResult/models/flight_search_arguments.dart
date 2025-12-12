class FlightSearchArguments {
  final String departureCode;
  final String arrivalCode;
  final DateTime departureDate;
  final DateTime? returnDate;
  final int adults;
  final int children;
  final int infants;
  final String travelClass;

  FlightSearchArguments({
    required this.departureCode,
    required this.arrivalCode,
    required this.departureDate,
    this.returnDate,
    required this.adults,
    required this.children,
    required this.infants,
    required this.travelClass,
  });
}
