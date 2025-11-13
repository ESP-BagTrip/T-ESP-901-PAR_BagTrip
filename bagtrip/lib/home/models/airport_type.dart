enum AirportType {
  departure('departure'),
  arrival('arrival');

  final String value;
  const AirportType(this.value);

  /// Return the raw string value (e.g. 'departure' / 'arrival')
  String asString() => value;

  /// A friendly hint used as default placeholder in the UI
  String get hintText {
    switch (this) {
      case AirportType.departure:
        return 'Aéroport de départ';
      case AirportType.arrival:
        return 'Aéroport de destination';
    }
  }
}
