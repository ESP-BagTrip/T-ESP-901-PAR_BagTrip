class IncludedBags {
  final int quantity;

  IncludedBags({required this.quantity});

  factory IncludedBags.fromJson(Map<String, dynamic> json) =>
      IncludedBags(quantity: json["quantity"]);

  Map<String, dynamic> toJson() => {"quantity": quantity};
}
