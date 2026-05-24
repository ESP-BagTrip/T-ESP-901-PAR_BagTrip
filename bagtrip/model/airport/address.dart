class Address {
  final String cityName;
  final String cityCode;
  final String countryName;
  final String countryCode;
  final String regionCode;

  Address({
    required this.cityName,
    required this.cityCode,
    required this.countryName,
    required this.countryCode,
    required this.regionCode,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    cityName: json["cityName"],
    cityCode: json["cityCode"],
    countryName: json["countryName"],
    countryCode: json["countryCode"],
    regionCode: json["regionCode"],
  );

  Map<String, dynamic> toJson() => {
    "cityName": cityName,
    "cityCode": cityCode,
    "countryName": countryName,
    "countryCode": countryCode,
    "regionCode": regionCode,
  };
}
