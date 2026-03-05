import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

enum AirportType {
  departure('departure'),
  arrival('arrival');

  final String value;
  const AirportType(this.value);

  /// Return the raw string value (e.g. 'departure' / 'arrival')
  String asString() => value;

  /// A friendly hint used as default placeholder in the UI
  String getHintText(BuildContext context) {
    switch (this) {
      case AirportType.departure:
        return AppLocalizations.of(context)!.airportDepartureHint;
      case AirportType.arrival:
        return AppLocalizations.of(context)!.airportArrivalHint;
    }
  }
}
