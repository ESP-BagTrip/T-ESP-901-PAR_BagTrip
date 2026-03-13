class Accommodation {
  final String id;
  final String tripId;
  final String name;
  final String? address;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final double? price;
  final String? currency;
  final String? bookingReference;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Accommodation({
    required this.id,
    required this.tripId,
    required this.name,
    this.address,
    this.checkIn,
    this.checkOut,
    this.price,
    this.currency,
    this.bookingReference,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory Accommodation.fromJson(Map<String, dynamic> json) {
    return Accommodation(
      id: json['id'] as String,
      tripId: json['tripId'] as String? ?? json['trip_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      checkIn:
          json['checkIn'] != null
              ? DateTime.parse(json['checkIn'] as String)
              : json['check_in'] != null
              ? DateTime.parse(json['check_in'] as String)
              : null,
      checkOut:
          json['checkOut'] != null
              ? DateTime.parse(json['checkOut'] as String)
              : json['check_out'] != null
              ? DateTime.parse(json['check_out'] as String)
              : null,
      price:
          json['price'] != null
              ? (json['price'] is String
                  ? double.tryParse(json['price'] as String)
                  : (json['price'] as num).toDouble())
              : null,
      currency: json['currency'] as String?,
      bookingReference:
          json['bookingReference'] as String? ??
          json['booking_reference'] as String?,
      notes: json['notes'] as String?,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'name': name,
      'address': address,
      'checkIn': checkIn?.toIso8601String().split('T').first,
      'checkOut': checkOut?.toIso8601String().split('T').first,
      'price': price,
      'currency': currency,
      'bookingReference': bookingReference,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
