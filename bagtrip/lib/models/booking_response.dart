/// Response model for a single booking from GET /v1/booking/list.
class BookingResponse {
  final String id;
  final String amadeusOrderId;
  final String status;
  final double priceTotal;
  final String currency;
  final DateTime createdAt;

  BookingResponse({
    required this.id,
    required this.amadeusOrderId,
    required this.status,
    required this.priceTotal,
    required this.currency,
    required this.createdAt,
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    return BookingResponse(
      id: json['id']?.toString() ?? '',
      amadeusOrderId:
          json['amadeusOrderId']?.toString() ??
          json['amadeus_order_id']?.toString() ??
          '',
      status: json['status']?.toString() ?? '',
      priceTotal: (json['priceTotal'] ?? json['price_total'] ?? 0).toDouble(),
      currency: json['currency']?.toString() ?? '',
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
    );
  }
}
