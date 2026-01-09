class FlightOfferSummary {
  final String id;
  final double? grandTotal;
  final String? currency;
  final Map<String, dynamic>? summary;

  FlightOfferSummary({
    required this.id,
    this.grandTotal,
    this.currency,
    this.summary,
  });

  factory FlightOfferSummary.fromJson(Map<String, dynamic> json) {
    return FlightOfferSummary(
      id: json['id'] as String,
      grandTotal:
          json['grandTotal'] != null
              ? (json['grandTotal'] as num).toDouble()
              : null,
      currency: json['currency'] as String?,
      summary: json['summary'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (grandTotal != null) 'grandTotal': grandTotal,
      if (currency != null) 'currency': currency,
      if (summary != null) 'summary': summary,
    };
  }
}

class FlightSearchResponse {
  final String searchId;
  final List<FlightOfferSummary> offers;

  FlightSearchResponse({required this.searchId, required this.offers});

  factory FlightSearchResponse.fromJson(Map<String, dynamic> json) {
    return FlightSearchResponse(
      searchId: json['searchId'] as String,
      offers:
          (json['offers'] as List<dynamic>?)
              ?.map(
                (offer) =>
                    FlightOfferSummary.fromJson(offer as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'searchId': searchId,
      'offers': offers.map((offer) => offer.toJson()).toList(),
    };
  }
}
