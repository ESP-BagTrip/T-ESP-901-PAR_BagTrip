enum BookingIntentStatus {
  init('INIT'),
  authorized('AUTHORIZED'),
  booked('BOOKED'),
  captured('CAPTURED'),
  cancelled('CANCELLED');

  final String value;
  const BookingIntentStatus(this.value);

  static BookingIntentStatus fromString(String value) {
    return BookingIntentStatus.values.firstWhere(
      (e) => e.value == value.toUpperCase(),
      orElse: () => BookingIntentStatus.init,
    );
  }
}

enum BookingIntentType {
  flight('flight'),
  hotel('hotel');

  final String value;
  const BookingIntentType(this.value);

  static BookingIntentType fromString(String value) {
    return BookingIntentType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => BookingIntentType.flight,
    );
  }
}

class BookingIntent {
  final String id;
  final BookingIntentType type;
  final BookingIntentStatus status;
  final double amount;
  final String currency;
  final String? selectedOfferId;

  BookingIntent({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    this.selectedOfferId,
  });

  factory BookingIntent.fromJson(Map<String, dynamic> json) {
    return BookingIntent(
      id: json['id'] as String,
      type: BookingIntentType.fromString(json['type'] as String? ?? 'flight'),
      status: BookingIntentStatus.fromString(
        json['status'] as String? ?? 'INIT',
      ),
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      selectedOfferId: json['selectedOfferId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'status': status.value,
      'amount': amount,
      'currency': currency,
      if (selectedOfferId != null) 'selectedOfferId': selectedOfferId,
    };
  }
}
