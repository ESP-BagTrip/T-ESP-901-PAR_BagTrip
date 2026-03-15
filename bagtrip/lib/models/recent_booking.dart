class RecentBooking {
  final String id;
  final String details;
  final DateTime date;
  final double priceTotal;
  final String currency;
  final String status;

  RecentBooking({
    required this.id,
    required this.details,
    required this.date,
    required this.priceTotal,
    required this.currency,
    required this.status,
  });
}
