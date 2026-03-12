/// Mock model for the final trip summary (last page).
class TripSummary {
  const TripSummary({
    required this.destination,
    required this.destinationCountry,
    required this.durationDays,
    required this.budgetEur,
    required this.highlights,
    required this.accommodation,
    required this.dayByDayProgram,
    required this.essentialItems,
  });

  final String destination;
  final String destinationCountry;
  final int durationDays;
  final int budgetEur;
  final List<String> highlights;
  final String accommodation;
  final List<String> dayByDayProgram;
  final List<String> essentialItems;
}
