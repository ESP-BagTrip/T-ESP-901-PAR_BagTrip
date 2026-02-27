/// Mock model for an AI-generated trip proposal (card on results page).
class AiTripProposal {
  const AiTripProposal({
    required this.id,
    required this.destination,
    required this.destinationCountry,
    required this.durationDays,
    required this.priceEur,
    required this.description,
  });

  final String id;
  final String destination;
  final String destinationCountry;
  final int durationDays;
  final int priceEur;
  final String description;
}
