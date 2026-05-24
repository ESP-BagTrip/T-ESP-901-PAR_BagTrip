import 'arrival.dart';
import 'aircraft.dart';
import 'operating.dart';

class Segment {
  final Arrival departure;
  final Arrival arrival;
  final String carrierCode;
  final String number;
  final Aircraft aircraft;
  final Operating operating;
  final String duration;
  final String id;
  final int numberOfStops;
  final bool blacklistedInEU;

  Segment({
    required this.departure,
    required this.arrival,
    required this.carrierCode,
    required this.number,
    required this.aircraft,
    required this.operating,
    required this.duration,
    required this.id,
    required this.numberOfStops,
    required this.blacklistedInEU,
  });

  factory Segment.fromJson(Map<String, dynamic> json) => Segment(
    departure: Arrival.fromJson(json["departure"]),
    arrival: Arrival.fromJson(json["arrival"]),
    carrierCode: json["carrierCode"],
    number: json["number"],
    aircraft: Aircraft.fromJson(json["aircraft"]),
    operating: Operating.fromJson(json["operating"]),
    duration: json["duration"],
    id: json["id"],
    numberOfStops: json["numberOfStops"],
    blacklistedInEU: json["blacklistedInEU"],
  );

  Map<String, dynamic> toJson() => {
    "departure": departure.toJson(),
    "arrival": arrival.toJson(),
    "carrierCode": carrierCode,
    "number": number,
    "aircraft": aircraft.toJson(),
    "operating": operating.toJson(),
    "duration": duration,
    "id": id,
    "numberOfStops": numberOfStops,
    "blacklistedInEU": blacklistedInEU,
  };
}
