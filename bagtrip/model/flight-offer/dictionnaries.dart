import 'location.dart';

class Dictionaries {
  final Map<String, Location> locations;
  final Map<String, String> aircraft;
  final Map<String, String> currencies;
  final Map<String, String> carriers;

  Dictionaries({
    required this.locations,
    required this.aircraft,
    required this.currencies,
    required this.carriers,
  });

  factory Dictionaries.fromJson(Map<String, dynamic> json) => Dictionaries(
    locations: Map.from(
      json["locations"],
    ).map((k, v) => MapEntry(k, Location.fromJson(v))),
    aircraft: Map.from(
      json["aircraft"],
    ).map((k, v) => MapEntry(k, v as String)),
    currencies: Map.from(
      json["currencies"],
    ).map((k, v) => MapEntry(k, v as String)),
    carriers: Map.from(
      json["carriers"],
    ).map((k, v) => MapEntry(k, v as String)),
  );

  Map<String, dynamic> toJson() => {
    "locations": Map.from(locations).map((k, v) => MapEntry(k, v.toJson())),
    "aircraft": Map.from(aircraft),
    "currencies": Map.from(currencies),
    "carriers": Map.from(carriers),
  };
}
