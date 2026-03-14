class PaymentCard {
  final String id;
  final String lastFourDigits;
  final String expiryDate;
  final bool isDefault;

  PaymentCard({
    required this.id,
    required this.lastFourDigits,
    required this.expiryDate,
    required this.isDefault,
  });
}
