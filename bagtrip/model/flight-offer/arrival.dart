class Arrival {
  final String iataCode;
  final String? terminal;
  final String at;

  Arrival({required this.iataCode, this.terminal, required this.at});

  factory Arrival.fromJson(Map<String, dynamic> json) => Arrival(
    iataCode: json["iataCode"],
    terminal: json["terminal"],
    at: json["at"],
  );

  Map<String, dynamic> toJson() => {
    "iataCode": iataCode,
    "terminal": terminal,
    "at": at,
  };
}
