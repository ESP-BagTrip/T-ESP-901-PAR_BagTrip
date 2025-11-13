class PricingOptions {
  final List<String> fareType;
  final bool includedCheckedBagsOnly;

  PricingOptions({
    required this.fareType,
    required this.includedCheckedBagsOnly,
  });

  factory PricingOptions.fromJson(Map<String, dynamic> json) => PricingOptions(
    fareType: List<String>.from(json["fareType"].map((x) => x)),
    includedCheckedBagsOnly: json["includedCheckedBagsOnly"],
  );

  Map<String, dynamic> toJson() => {
    "fareType": List<dynamic>.from(fareType.map((x) => x)),
    "includedCheckedBagsOnly": includedCheckedBagsOnly,
  };
}
