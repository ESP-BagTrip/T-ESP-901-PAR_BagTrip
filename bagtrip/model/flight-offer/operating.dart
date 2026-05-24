class Operating {
  final String carrierCode;

  Operating({required this.carrierCode});

  factory Operating.fromJson(Map<String, dynamic> json) =>
      Operating(carrierCode: json["carrierCode"]);

  Map<String, dynamic> toJson() => {"carrierCode": carrierCode};
}
