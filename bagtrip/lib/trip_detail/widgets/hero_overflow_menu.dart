import 'package:bagtrip/components/adaptive/adaptive_action_sheet.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:flutter/material.dart';

/// Entries surfaced in the trip-detail hero overflow menu. Mirrors the
/// status-dependent CTAs that the legacy `TripDetailView` rendered inline
/// at the bottom of the scroll (Mark as ready, Trip complete, Delete trip…).
enum HeroOverflowAction {
  editTitle,
  editTravelers,
  share,
  markAsReady,
  markAsCompleted,
  giveReview,
  deleteTrip,
}

/// Opens a platform-appropriate overflow menu for the trip-detail hero.
///
/// [canEdit] gates edit-only entries (title/travelers/mark-as-ready/delete).
/// [isOwner] is required for share/delete. [status] drives status transitions
/// (draft→planned, ongoing→completed).
Future<HeroOverflowAction?> showHeroOverflowMenu({
  required BuildContext context,
  required Trip trip,
  required bool canEdit,
  required bool isOwner,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final completer = _ActionCollector();

  final actions = <AdaptiveAction>[];

  if (canEdit) {
    actions.add(
      AdaptiveAction(
        label: l10n.editTripTitle,
        icon: Icons.edit_outlined,
        onPressed: () => completer.result = HeroOverflowAction.editTitle,
      ),
    );
    actions.add(
      AdaptiveAction(
        label: l10n.tripTravelers,
        icon: Icons.people_outline_rounded,
        onPressed: () => completer.result = HeroOverflowAction.editTravelers,
      ),
    );
  }

  if (isOwner) {
    actions.add(
      AdaptiveAction(
        label: l10n.shareTooltip,
        icon: Icons.ios_share_rounded,
        onPressed: () => completer.result = HeroOverflowAction.share,
      ),
    );
  }

  if (canEdit) {
    if (trip.status == TripStatus.draft) {
      actions.add(
        AdaptiveAction(
          label: l10n.markAsReady,
          icon: Icons.check_circle_outline_rounded,
          onPressed: () => completer.result = HeroOverflowAction.markAsReady,
        ),
      );
    }
    if (trip.status == TripStatus.ongoing) {
      actions.add(
        AdaptiveAction(
          label: l10n.tripComplete,
          icon: Icons.flag_outlined,
          onPressed: () =>
              completer.result = HeroOverflowAction.markAsCompleted,
        ),
      );
    }
  }

  if (trip.status == TripStatus.completed) {
    actions.add(
      AdaptiveAction(
        label: l10n.tripGiveReview,
        icon: Icons.rate_review_outlined,
        onPressed: () => completer.result = HeroOverflowAction.giveReview,
      ),
    );
  }

  if (canEdit && isOwner && trip.status == TripStatus.draft) {
    actions.add(
      AdaptiveAction(
        label: l10n.tripDeleteTitle,
        icon: Icons.delete_outline_rounded,
        isDestructive: true,
        onPressed: () => completer.result = HeroOverflowAction.deleteTrip,
      ),
    );
  }

  if (actions.isEmpty) return null;

  await showAdaptiveActionSheet(
    context: context,
    cancelLabel: l10n.cancelButton,
    actions: actions,
  );

  return completer.result;
}

class _ActionCollector {
  HeroOverflowAction? result;
}
