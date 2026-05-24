import 'address.dart';
import 'geo_code.dart';

class Location {
  final String type;
  final String subType;
  final String name;
  final String detailedName;
  final String id;
  final String iataCode;
  final GeoCode geoCode;
  final Address address;
  final String timeZoneOffset;

  Location({
    required this.type,
    required this.subType,
    required this.name,
    required this.detailedName,
    required this.id,
    required this.iataCode,
    required this.geoCode,
    required this.address,
    required this.timeZoneOffset,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    type: json["type"],
    subType: json["subType"],
    name: json["name"],
    detailedName: json["detailedName"],
    id: json["id"],
    iataCode: json["iataCode"],
    geoCode: GeoCode.fromJson(json["geoCode"]),
    address: Address.fromJson(json["address"]),
    timeZoneOffset: json["timeZoneOffset"],
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "subType": subType,
    "name": name,
    "detailedName": detailedName,
    "id": id,
    "iataCode": iataCode,
    "geoCode": geoCode.toJson(),
    "address": address.toJson(),
    "timeZoneOffset": timeZoneOffset,
  };
}
