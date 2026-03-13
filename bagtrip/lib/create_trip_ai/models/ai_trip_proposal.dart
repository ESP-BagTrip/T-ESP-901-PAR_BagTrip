/// Model for an AI-generated trip proposal (card on results page).
class AiTripProposal {
  const AiTripProposal({
    required this.id,
    required this.destination,
    required this.destinationCountry,
    required this.durationDays,
    required this.priceEur,
    required this.description,
    this.activities = const [],
  });

  factory AiTripProposal.fromJson(Map<String, dynamic> json, {String? id}) {
    return AiTripProposal(
      id: id ?? '',
      destination: json['destination'] ?? '',
      destinationCountry: json['destinationCountry'] ?? '',
      durationDays: json['durationDays'] ?? 0,
      priceEur: json['budgetEur'] ?? 0,
      description: json['description'] ?? '',
      activities:
          (json['activities'] as List?)
              ?.map((a) => Map<String, dynamic>.from(a))
              .toList() ??
          [],
    );
  }

  final String id;
  final String destination;
  final String destinationCountry;
  final int durationDays;
  final int priceEur;
  final String description;
  final List<Map<String, dynamic>> activities;

  /// Convert back to JSON for API calls.
  Map<String, dynamic> toJson() => {
    'destination': destination,
    'destinationCountry': destinationCountry,
    'durationDays': durationDays,
    'budgetEur': priceEur,
    'description': description,
    'activities': activities,
  };
}
