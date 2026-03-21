import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:flutter/painting.dart';

enum AccommodationDisplayStatus { confirmed, pending }

/// Derives display status from [Accommodation] data completeness.
///
/// **confirmed** — bookingReference is non-null and non-empty.
/// **pending** — bookingReference absent or empty.
AccommodationDisplayStatus deriveAccommodationStatus(Accommodation a) {
  if (a.bookingReference != null && a.bookingReference!.isNotEmpty) {
    return AccommodationDisplayStatus.confirmed;
  }
  return AccommodationDisplayStatus.pending;
}

Color accommodationStatusColor(AccommodationDisplayStatus status) {
  return switch (status) {
    AccommodationDisplayStatus.confirmed => AppColors.success,
    AccommodationDisplayStatus.pending => AppColors.warning,
  };
}

String accommodationStatusLabel(
  AccommodationDisplayStatus status,
  AppLocalizations l10n,
) {
  return switch (status) {
    AccommodationDisplayStatus.confirmed => l10n.accommodationStatusConfirmed,
    AccommodationDisplayStatus.pending => l10n.accommodationStatusPending,
  };
}
