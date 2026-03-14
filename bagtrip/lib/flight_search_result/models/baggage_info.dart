class BaggageInfo {
  final int? quantity;
  final int? weight;
  final String? weightUnit;

  const BaggageInfo({this.quantity, this.weight, this.weightUnit});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaggageInfo &&
          runtimeType == other.runtimeType &&
          quantity == other.quantity &&
          weight == other.weight &&
          weightUnit == other.weightUnit;

  @override
  int get hashCode => quantity.hashCode ^ weight.hashCode ^ weightUnit.hashCode;
}
