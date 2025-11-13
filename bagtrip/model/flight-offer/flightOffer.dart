// ignore_for_file: file_names

import 'itinerary.dart';
import 'price.dart';
import 'pricing_options.dart';
import 'traveler_pricing.dart';

class FlightOffer {
  final String type;
  final String id;
  final String source;
  final bool instantTicketingRequired;
  final bool nonHomogeneous;
  final bool oneWay;
  final bool isUpsellOffer;
  final String lastTicketingDate;
  final String lastTicketingDateTime;
  final int numberOfBookableSeats;
  final List<Itinerary> itineraries;
  final Price price;
  final PricingOptions pricingOptions;
  final List<String> validatingAirlineCodes;
  final List<TravelerPricing> travelerPricings;

  FlightOffer({
    required this.type,
    required this.id,
    required this.source,
    required this.instantTicketingRequired,
    required this.nonHomogeneous,
    required this.oneWay,
    required this.isUpsellOffer,
    required this.lastTicketingDate,
    required this.lastTicketingDateTime,
    required this.numberOfBookableSeats,
    required this.itineraries,
    required this.price,
    required this.pricingOptions,
    required this.validatingAirlineCodes,
    required this.travelerPricings,
  });

  factory FlightOffer.fromJson(Map<String, dynamic> json) => FlightOffer(
    type: json["type"],
    id: json["id"],
    source: json["source"],
    instantTicketingRequired: json["instantTicketingRequired"],
    nonHomogeneous: json["nonHomogeneous"],
    oneWay: json["oneWay"],
    isUpsellOffer: json["isUpsellOffer"],
    lastTicketingDate: json["lastTicketingDate"],
    lastTicketingDateTime: json["lastTicketingDateTime"],
    numberOfBookableSeats: json["numberOfBookableSeats"],
    itineraries: List<Itinerary>.from(
      json["itineraries"].map((x) => Itinerary.fromJson(x)),
    ),
    price: Price.fromJson(json["price"]),
    pricingOptions: PricingOptions.fromJson(json["pricingOptions"]),
    validatingAirlineCodes: List<String>.from(
      json["validatingAirlineCodes"].map((x) => x),
    ),
    travelerPricings: List<TravelerPricing>.from(
      json["travelerPricings"].map((x) => TravelerPricing.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "id": id,
    "source": source,
    "instantTicketingRequired": instantTicketingRequired,
    "nonHomogeneous": nonHomogeneous,
    "oneWay": oneWay,
    "isUpsellOffer": isUpsellOffer,
    "lastTicketingDate": lastTicketingDate,
    "lastTicketingDateTime": lastTicketingDateTime,
    "numberOfBookableSeats": numberOfBookableSeats,
    "itineraries": List<dynamic>.from(itineraries.map((x) => x.toJson())),
    "price": price.toJson(),
    "pricingOptions": pricingOptions.toJson(),
    "validatingAirlineCodes": List<dynamic>.from(
      validatingAirlineCodes.map((x) => x),
    ),
    "travelerPricings": List<dynamic>.from(
      travelerPricings.map((x) => x.toJson()),
    ),
  };
}
