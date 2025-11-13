class Location {
  final String cityCode;
  final String countryCode;

  Location({required this.cityCode, required this.countryCode});

  factory Location.fromJson(Map<String, dynamic> json) =>
      Location(cityCode: json["cityCode"], countryCode: json["countryCode"]);

  Map<String, dynamic> toJson() => {
    "cityCode": cityCode,
    "countryCode": countryCode,
  };
}
