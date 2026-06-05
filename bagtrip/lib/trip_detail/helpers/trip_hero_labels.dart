import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String tripHeroCity(Trip trip, AppLocalizations l10n) {
  if (trip.destinationName != null && trip.destinationName!.isNotEmpty) {
    return trip.destinationName!;
  }
  if (trip.title != null && trip.title!.isNotEmpty) return trip.title!;
  return l10n.myTripFallback;
}

/// Locale-aware date range plus duration, e.g. "16 mai 2026 - 17 mai 2026 • 1 jour".
String tripHeroDateSubtitle(
  BuildContext context,
  Trip trip,
  int totalDays,
  AppLocalizations l10n,
) {
  if (trip.startDate == null || trip.endDate == null) return '';
  if (totalDays <= 0) return '';
  final locale = Localizations.localeOf(context).languageCode;
  final fmt = DateFormat('d MMM yyyy', locale);
  final range = '${fmt.format(trip.startDate!)} - ${fmt.format(trip.endDate!)}';
  return '$range • ${l10n.tripDurationDays(totalDays)}';
}

String? tripHeroCoverImageUrl(Trip trip) {
  final url = trip.coverImageUrl;
  if (url != null && url.isNotEmpty) return url;
  return null;
}
