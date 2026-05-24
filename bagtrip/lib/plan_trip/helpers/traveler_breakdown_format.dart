import 'package:bagtrip/l10n/app_localizations.dart';

/// Human-readable breakdown e.g. "2 adultes · 1 enfant" (non-zero segments only).
String formatTravelerBreakdownDetail(
  AppLocalizations l10n, {
  required int nbAdults,
  required int nbChildren,
  required int nbBabies,
}) {
  final parts = <String>[];
  if (nbAdults > 0) parts.add(l10n.travelerSegmentAdult(nbAdults));
  if (nbChildren > 0) parts.add(l10n.travelerSegmentChild(nbChildren));
  if (nbBabies > 0) parts.add(l10n.travelerSegmentBaby(nbBabies));
  return parts.join(' · ');
}
