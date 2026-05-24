class Fee {
  final String amount;
  final String type;

  Fee({required this.amount, required this.type});

  factory Fee.fromJson(Map<String, dynamic> json) =>
      Fee(amount: json["amount"], type: json["type"]);

  Map<String, dynamic> toJson() => {"amount": amount, "type": type};
}
