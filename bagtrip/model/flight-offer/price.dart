import 'fee.dart';

class Price {
  final String currency;
  final String total;
  final String base;
  final List<Fee>? fees;
  final String? grandTotal;

  Price({
    required this.currency,
    required this.total,
    required this.base,
    this.fees,
    this.grandTotal,
  });

  factory Price.fromJson(Map<String, dynamic> json) => Price(
    currency: json["currency"],
    total: json["total"],
    base: json["base"],
    fees: json["fees"] == null
        ? null
        : List<Fee>.from(json["fees"].map((x) => Fee.fromJson(x))),
    grandTotal: json["grandTotal"],
  );

  Map<String, dynamic> toJson() => {
    "currency": currency,
    "total": total,
    "base": base,
    "fees": fees == null
        ? null
        : List<dynamic>.from(fees!.map((x) => x.toJson())),
    "grandTotal": grandTotal,
  };
}
