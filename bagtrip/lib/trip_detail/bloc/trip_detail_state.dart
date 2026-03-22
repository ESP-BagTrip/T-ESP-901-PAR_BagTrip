part of 'trip_detail_bloc.dart';

sealed class TripDetailState {}

final class TripDetailInitial extends TripDetailState {}

final class TripDetailLoading extends TripDetailState {}

final class TripDetailLoaded extends TripDetailState {
  final Trip trip;
  final List<Activity> activities;
  final List<ManualFlight> flights;
  final List<Accommodation> accommodations;
  final List<BaggageItem> baggageItems;
  final BudgetSummary? budgetSummary;
  final List<TripShare> shares;
  final int selectedDayIndex;
  final String userRole;
  final CompletionResult completionResult;
  final Set<String> collapsedSections;
  final String? validationError;
  final int? suggestingForDay;
  final List<Map<String, dynamic>>? daySuggestions;
  final int? suggestionsForDay;
  final bool deferredLoaded;

  TripDetailLoaded({
    required this.trip,
    required this.activities,
    required this.flights,
    required this.accommodations,
    required this.baggageItems,
    this.budgetSummary,
    required this.shares,
    this.selectedDayIndex = 0,
    this.userRole = 'OWNER',
    required this.completionResult,
    this.collapsedSections = const {},
    this.validationError,
    this.suggestingForDay,
    this.daySuggestions,
    this.suggestionsForDay,
    this.deferredLoaded = false,
  });

  int get completionPercentage => completionResult.percentage;

  bool get isViewer => userRole == 'VIEWER';
  bool get isOwner => userRole == 'OWNER';
  bool get isCompleted => trip.status == TripStatus.completed;

  int get totalDays {
    if (trip.startDate == null || trip.endDate == null) return 0;
    return trip.endDate!.difference(trip.startDate!).inDays + 1;
  }

  int? get daysUntilTrip {
    if (trip.startDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      trip.startDate!.year,
      trip.startDate!.month,
      trip.startDate!.day,
    );
    final diff = start.difference(today).inDays;
    return diff > 0 ? diff : null;
  }

  int? get currentDay {
    if (trip.startDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      trip.startDate!.year,
      trip.startDate!.month,
      trip.startDate!.day,
    );
    final diff = today.difference(start).inDays;
    return diff < 0 ? null : diff + 1;
  }

  bool get isOngoing {
    if (trip.startDate == null || trip.endDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      trip.startDate!.year,
      trip.startDate!.month,
      trip.startDate!.day,
    );
    final end = DateTime(
      trip.endDate!.year,
      trip.endDate!.month,
      trip.endDate!.day,
    );
    return !today.isBefore(start) && !today.isAfter(end);
  }

  int get baggagePackedCount => baggageItems.where((b) => b.isPacked).length;

  TripDetailLoaded copyWith({
    Trip? trip,
    List<Activity>? activities,
    List<ManualFlight>? flights,
    List<Accommodation>? accommodations,
    List<BaggageItem>? baggageItems,
    BudgetSummary? budgetSummary,
    bool clearBudgetSummary = false,
    List<TripShare>? shares,
    int? selectedDayIndex,
    String? userRole,
    CompletionResult? completionResult,
    Set<String>? collapsedSections,
    String? validationError,
    bool clearValidationError = false,
    int? suggestingForDay,
    bool clearSuggestingForDay = false,
    List<Map<String, dynamic>>? daySuggestions,
    bool clearDaySuggestions = false,
    int? suggestionsForDay,
    bool clearSuggestionsForDay = false,
    bool? deferredLoaded,
  }) {
    return TripDetailLoaded(
      trip: trip ?? this.trip,
      activities: activities ?? this.activities,
      flights: flights ?? this.flights,
      accommodations: accommodations ?? this.accommodations,
      baggageItems: baggageItems ?? this.baggageItems,
      budgetSummary: clearBudgetSummary
          ? null
          : (budgetSummary ?? this.budgetSummary),
      shares: shares ?? this.shares,
      selectedDayIndex: selectedDayIndex ?? this.selectedDayIndex,
      userRole: userRole ?? this.userRole,
      completionResult: completionResult ?? this.completionResult,
      collapsedSections: collapsedSections ?? this.collapsedSections,
      validationError: clearValidationError
          ? null
          : (validationError ?? this.validationError),
      suggestingForDay: clearSuggestingForDay
          ? null
          : (suggestingForDay ?? this.suggestingForDay),
      daySuggestions: clearDaySuggestions
          ? null
          : (daySuggestions ?? this.daySuggestions),
      suggestionsForDay: clearSuggestionsForDay
          ? null
          : (suggestionsForDay ?? this.suggestionsForDay),
      deferredLoaded: deferredLoaded ?? this.deferredLoaded,
    );
  }
}

final class TripDetailError extends TripDetailState {
  final AppError error;
  TripDetailError({required this.error});
}

final class TripDetailDeleted extends TripDetailState {}
