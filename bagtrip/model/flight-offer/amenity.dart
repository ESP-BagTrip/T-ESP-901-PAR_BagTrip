class Amenity {
  final String description;
  final bool isChargeable;
  final String amenityType;
  final AmenityProvider amenityProvider;

  Amenity({
    required this.description,
    required this.isChargeable,
    required this.amenityType,
    required this.amenityProvider,
  });

  factory Amenity.fromJson(Map<String, dynamic> json) => Amenity(
    description: json["description"],
    isChargeable: json["isChargeable"],
    amenityType: json["amenityType"],
    amenityProvider: AmenityProvider.fromJson(json["amenityProvider"]),
  );

  Map<String, dynamic> toJson() => {
    "description": description,
    "isChargeable": isChargeable,
    "amenityType": amenityType,
    "amenityProvider": amenityProvider.toJson(),
  };
}

class AmenityProvider {
  final String name;

  AmenityProvider({required this.name});

  factory AmenityProvider.fromJson(Map<String, dynamic> json) =>
      AmenityProvider(name: json["name"]);

  Map<String, dynamic> toJson() => {"name": name};
}
