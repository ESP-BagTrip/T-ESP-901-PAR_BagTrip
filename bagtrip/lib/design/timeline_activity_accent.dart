import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:flutter/material.dart';

/// Same border as [ActiveTripQuickActionsSection] `_surfaceCard` (non-tinted).
BorderSide get timelineCardBorderSide =>
    const BorderSide(color: ColorName.primarySoftLight);

/// Same drop shadow as quick-action surface cards.
List<BoxShadow> get timelineCardBoxShadows => [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.04),
    offset: const Offset(0, 2),
    blurRadius: 8,
  ),
];

/// Teal used for the active-trip timeline "now" chip — shared with cards.
const Color timelineNowAccent = Color(0xFF34B7A4);

/// Stable per-activity accent (hash of [Activity.id]) for timeline cards.
/// When [isNow] is true, returns [timelineNowAccent] regardless of id.
Color timelineCardAccent({required Activity activity, required bool isNow}) {
  if (isNow) return timelineNowAccent;
  final i = (activity.id.hashCode & 0x7fffffff) % _accentPalette.length;
  return _accentPalette[i];
}

/// Pastel capsule background for a given accent.
Color timelineCapsuleBackground(Color accent) => accent.withValues(alpha: 0.15);

/// Icon circle fill (slightly stronger than capsule).
Color timelineIconCircleBackground(Color accent) =>
    accent.withValues(alpha: 0.22);

/// Height of the time capsule and diameter of the category icon circle so they
/// align on one row (matches [ActiveTripQuickActionsSection] row density).
const double timelineActivityLeadingSize = 28;

const List<Color> _accentPalette = [
  Color(0xFF5C8AC7), // blue
  Color(0xFFE67E22), // orange
  Color(0xFFD4A017), // amber
  Color(0xFFE91E8C), // pink
  Color(0xFF8E6CCF), // violet
  Color(0xFF2BB5A0), // teal variant
  Color(0xFF6B8E6B), // sage
  Color(0xFFC75C7A), // rose
];
