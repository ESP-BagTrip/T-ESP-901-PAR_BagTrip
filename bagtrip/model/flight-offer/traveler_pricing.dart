import 'price.dart';
import 'fare_details_by_segment.dart';

class TravelerPricing {
  final String travelerId;
  final String fareOption;
  final String travelerType;
  final Price price;
  final List<FareDetailsBySegment> fareDetailsBySegment;

  TravelerPricing({
    required this.travelerId,
    required this.fareOption,
    required this.travelerType,
    required this.price,
    required this.fareDetailsBySegment,
  });

  factory TravelerPricing.fromJson(Map<String, dynamic> json) =>
      TravelerPricing(
        travelerId: json["travelerId"],
        fareOption: json["fareOption"],
        travelerType: json["travelerType"],
        price: Price.fromJson(json["price"]),
        fareDetailsBySegment: List<FareDetailsBySegment>.from(
          json["fareDetailsBySegment"].map(
            (x) => FareDetailsBySegment.fromJson(x),
          ),
        ),
      );

  Map<String, dynamic> toJson() => {
    "travelerId": travelerId,
    "fareOption": fareOption,
    "travelerType": travelerType,
    "price": price.toJson(),
    "fareDetailsBySegment": List<dynamic>.from(
      fareDetailsBySegment.map((x) => x.toJson()),
    ),
  };
}
