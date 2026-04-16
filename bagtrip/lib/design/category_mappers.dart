import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:flutter/material.dart';

/// Single source of truth for activity category presentation.
///
/// Before this extension the same switch (icon / color / label) was
/// duplicated across activity_card, activity_form, timeline_activity_card
/// and timeline_activity_row — any time we added a category we had to
/// remember to touch 4 files, and the colors had already drifted into
/// hardcoded hex values.
extension ActivityCategoryPresentation on ActivityCategory {
  IconData get icon => switch (this) {
    ActivityCategory.culture => Icons.museum_outlined,
    ActivityCategory.nature => Icons.park_outlined,
    ActivityCategory.food => Icons.restaurant_outlined,
    ActivityCategory.sport => Icons.fitness_center_outlined,
    ActivityCategory.shopping => Icons.shopping_bag_outlined,
    ActivityCategory.nightlife => Icons.nightlife_outlined,
    ActivityCategory.relaxation => Icons.spa_outlined,
    ActivityCategory.other => Icons.event_outlined,
  };

  Color get color => switch (this) {
    ActivityCategory.culture => AppColors.activityCulture,
    ActivityCategory.nature => AppColors.activityNature,
    ActivityCategory.food => AppColors.activityFood,
    ActivityCategory.sport => AppColors.activitySport,
    ActivityCategory.shopping => AppColors.activityShopping,
    ActivityCategory.nightlife => AppColors.activityNightlife,
    ActivityCategory.relaxation => AppColors.activityRelaxation,
    ActivityCategory.other => AppColors.secondary,
  };

  String label(AppLocalizations l10n) => switch (this) {
    ActivityCategory.culture => l10n.categoryCulture,
    ActivityCategory.nature => l10n.categoryNature,
    ActivityCategory.food => l10n.categoryFoodDrink,
    ActivityCategory.sport => l10n.categorySport,
    ActivityCategory.shopping => l10n.categoryShopping,
    ActivityCategory.nightlife => l10n.categoryNightlife,
    ActivityCategory.relaxation => l10n.categoryRelaxation,
    ActivityCategory.other => l10n.categoryOtherActivity,
  };
}

/// Single source of truth for budget category presentation. Same
/// motivation as [ActivityCategoryPresentation] — previously replicated
/// in budget_item_card and budget_item_form.
extension BudgetCategoryPresentation on BudgetCategory {
  IconData get icon => switch (this) {
    BudgetCategory.flight => Icons.flight,
    BudgetCategory.accommodation => Icons.hotel,
    BudgetCategory.food => Icons.restaurant,
    BudgetCategory.activity => Icons.sports_tennis,
    BudgetCategory.transport => Icons.directions_car,
    BudgetCategory.other => Icons.receipt_long,
  };

  String label(AppLocalizations l10n) => switch (this) {
    BudgetCategory.flight => l10n.reviewBudgetFlights,
    BudgetCategory.accommodation => l10n.reviewBudgetAccommodation,
    BudgetCategory.food => l10n.reviewBudgetMeals,
    BudgetCategory.activity => l10n.reviewBudgetActivities,
    BudgetCategory.transport => l10n.reviewBudgetTransport,
    BudgetCategory.other => l10n.reviewBudgetOther,
  };
}
