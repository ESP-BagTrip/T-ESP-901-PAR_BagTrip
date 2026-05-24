enum QuickActionType {
  todaySchedule,
  weather,
  checkOut,
  navigate,
  expense,
  photo,
  nextActivity,
  aiSuggestion,
  map,
  todayExpenses,
  tomorrow,
  budget,
}

List<QuickActionType> resolveContextualActions({
  required int hour,
  required bool hasCurrentActivity,
  required bool hasNextActivity,
}) {
  // Priority 1: During an activity → navigate, expense, photo
  if (hasCurrentActivity) {
    return [
      QuickActionType.navigate,
      QuickActionType.expense,
      QuickActionType.photo,
    ];
  }

  // Priority 2: Morning with upcoming activity → schedule, weather, check-out
  if (hour < 12 && hasNextActivity) {
    return [
      QuickActionType.todaySchedule,
      QuickActionType.weather,
      QuickActionType.checkOut,
    ];
  }

  // Priority 3: Afternoon gap with next activity → next, AI, map
  if (!hasCurrentActivity && hasNextActivity) {
    return [
      QuickActionType.nextActivity,
      QuickActionType.aiSuggestion,
      QuickActionType.map,
    ];
  }

  // Priority 4: Evening, no more activities → today expenses, tomorrow, budget
  if (hour >= 18 && !hasNextActivity) {
    return [
      QuickActionType.todayExpenses,
      QuickActionType.tomorrow,
      QuickActionType.budget,
    ];
  }

  // Priority 5: Fallback → schedule, weather, budget
  return [
    QuickActionType.todaySchedule,
    QuickActionType.weather,
    QuickActionType.budget,
  ];
}
