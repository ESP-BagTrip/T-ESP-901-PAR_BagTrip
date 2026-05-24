import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:flutter/painting.dart';

enum FlightDisplayStatus { confirmed, pending }

/// Derives display status from [ManualFlight] data completeness.
///
/// **confirmed** — all 5 critical fields non-null:
///   departureAirport, arrivalAirport, departureDate, arrivalDate, airline.
/// **pending** — one or more fields absent.
FlightDisplayStatus deriveFlightStatus(ManualFlight flight) {
  if (flight.departureAirport != null &&
      flight.arrivalAirport != null &&
      flight.departureDate != null &&
      flight.arrivalDate != null &&
      flight.airline != null) {
    return FlightDisplayStatus.confirmed;
  }
  return FlightDisplayStatus.pending;
}

Color flightStatusColor(FlightDisplayStatus status) {
  return switch (status) {
    FlightDisplayStatus.confirmed => AppColors.success,
    FlightDisplayStatus.pending => AppColors.warning,
  };
}

String flightStatusLabel(FlightDisplayStatus status, AppLocalizations l10n) {
  return switch (status) {
    FlightDisplayStatus.confirmed => l10n.flightStatusConfirmed,
    FlightDisplayStatus.pending => l10n.flightStatusPending,
  };
}
