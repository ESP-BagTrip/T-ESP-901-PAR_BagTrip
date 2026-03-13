/// Model for the final trip summary (last page).
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

  factory TripSummary.fromJson(Map<String, dynamic> json) {
    return TripSummary(
      destination: json['destination'] ?? '',
      destinationCountry: json['destinationCountry'] ?? '',
      durationDays: json['durationDays'] ?? 0,
      budgetEur: json['budgetEur'] ?? 0,
      highlights:
          (json['highlights'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      accommodation: json['accommodation'] ?? '',
      dayByDayProgram:
          (json['dayByDayProgram'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      essentialItems:
          (json['essentialItems'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  final String destination;
  final String destinationCountry;
  final int durationDays;
  final int budgetEur;
  final List<String> highlights;
  final String accommodation;
  final List<String> dayByDayProgram;
  final List<String> essentialItems;
}
