import 'included_bags.dart';
import 'amenity.dart';

class FareDetailsBySegment {
  final String segmentId;
  final String cabin;
  final String fareBasis;
  final String brandedFare;
  final String brandedFareLabel;
  final String flightClass;
  final IncludedBags includedCheckedBags;
  final IncludedBags includedCabinBags;
  final List<Amenity> amenities;

  FareDetailsBySegment({
    required this.segmentId,
    required this.cabin,
    required this.fareBasis,
    required this.brandedFare,
    required this.brandedFareLabel,
    required this.flightClass,
    required this.includedCheckedBags,
    required this.includedCabinBags,
    required this.amenities,
  });

  factory FareDetailsBySegment.fromJson(Map<String, dynamic> json) =>
      FareDetailsBySegment(
        segmentId: json["segmentId"],
        cabin: json["cabin"],
        fareBasis: json["fareBasis"],
        brandedFare: json["brandedFare"],
        brandedFareLabel: json["brandedFareLabel"],
        flightClass: json["class"],
        includedCheckedBags: IncludedBags.fromJson(json["includedCheckedBags"]),
        includedCabinBags: IncludedBags.fromJson(json["includedCabinBags"]),
        amenities: List<Amenity>.from(
          json["amenities"].map((x) => Amenity.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() => {
    "segmentId": segmentId,
    "cabin": cabin,
    "fareBasis": fareBasis,
    "brandedFare": brandedFare,
    "brandedFareLabel": brandedFareLabel,
    "class": flightClass,
    "includedCheckedBags": includedCheckedBags.toJson(),
    "includedCabinBags": includedCabinBags.toJson(),
    "amenities": List<dynamic>.from(amenities.map((x) => x.toJson())),
  };
}
