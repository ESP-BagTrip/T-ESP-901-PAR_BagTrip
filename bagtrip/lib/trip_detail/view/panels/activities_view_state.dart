import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/trip_detail/view/panels/activities_view_mode.dart';

/// Layout + cross-cutting filters applied to the Activities tab.
///
/// All three views (timeline / list / category) read the **filtered**
/// activity list from [applyTo] — the filtering logic lives in one
/// place so a new view only has to consume the result and a new filter
/// only has to be threaded through here.
class ActivitiesViewState {
  const ActivitiesViewState({
    required this.mode,
    this.validationFilter,
    this.categoryFilters = const {},
  });

  /// Default state used on the very first launch and as a fallback
  /// when persisted prefs deserialise to garbage.
  const ActivitiesViewState.initial()
    : mode = ActivitiesViewMode.timeline,
      validationFilter = null,
      categoryFilters = const {};

  /// Layout picker (timeline / list / category).
  final ActivitiesViewMode mode;

  /// ``null`` means "no validation filter" — show suggested + validated
  /// + manual together. A non-null value keeps only the activities
  /// matching that exact status.
  final ValidationStatus? validationFilter;

  /// Empty means "no category filter" — show every category. A
  /// non-empty set keeps only the activities whose category is in it.
  final Set<ActivityCategory> categoryFilters;

  bool get hasActiveFilters =>
      validationFilter != null || categoryFilters.isNotEmpty;

  /// Apply the active filters to ``activities`` in-order. Order is
  /// preserved on purpose — sorting happens inside the views, never
  /// here, because the right sort key depends on the layout.
  List<Activity> applyTo(List<Activity> activities) {
    if (!hasActiveFilters) return activities;
    return activities.where((a) {
      if (validationFilter != null && a.validationStatus != validationFilter) {
        return false;
      }
      if (categoryFilters.isNotEmpty && !categoryFilters.contains(a.category)) {
        return false;
      }
      return true;
    }).toList();
  }

  ActivitiesViewState copyWith({
    ActivitiesViewMode? mode,
    ValidationStatus? validationFilter,
    bool clearValidationFilter = false,
    Set<ActivityCategory>? categoryFilters,
  }) {
    return ActivitiesViewState(
      mode: mode ?? this.mode,
      validationFilter: clearValidationFilter
          ? null
          : (validationFilter ?? this.validationFilter),
      categoryFilters: categoryFilters ?? this.categoryFilters,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivitiesViewState &&
          other.mode == mode &&
          other.validationFilter == validationFilter &&
          _setEquals(other.categoryFilters, categoryFilters);

  @override
  int get hashCode => Object.hash(
    mode,
    validationFilter,
    Object.hashAllUnordered(categoryFilters),
  );
}

bool _setEquals<T>(Set<T> a, Set<T> b) {
  if (a.length != b.length) return false;
  for (final v in a) {
    if (!b.contains(v)) return false;
  }
  return true;
}
