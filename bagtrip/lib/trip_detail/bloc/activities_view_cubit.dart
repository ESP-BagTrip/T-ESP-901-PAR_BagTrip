import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/trip_detail/view/panels/activities_view_mode.dart';
import 'package:bagtrip/trip_detail/view/panels/activities_view_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's preferred Activities-tab layout + filters.
///
/// Three independent prefs (mode / validation / categories) — they
/// describe how the user reads their trip and tend to stick. Keeping
/// the cubit narrow to the panel keeps it decoupled from the rest of
/// the trip-detail state graph.
class ActivitiesViewCubit extends Cubit<ActivitiesViewState> {
  ActivitiesViewCubit({SharedPreferences? prefs})
    : _prefs = prefs,
      super(const ActivitiesViewState.initial()) {
    _restore();
  }

  static const String _modeKey = 'activities_view_mode';
  static const String _validationKey = 'activities_view_validation_filter';
  static const String _categoriesKey = 'activities_view_category_filters';

  SharedPreferences? _prefs;

  Future<void> _restore() async {
    _prefs ??= await SharedPreferences.getInstance();
    final mode = _readMode();
    final validation = _readValidation();
    final categories = _readCategories();
    final restored = ActivitiesViewState(
      mode: mode,
      validationFilter: validation,
      categoryFilters: categories,
    );
    if (restored != state) emit(restored);
  }

  ActivitiesViewMode _readMode() {
    final raw = _prefs?.getString(_modeKey);
    if (raw == null) return ActivitiesViewMode.timeline;
    return ActivitiesViewMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => ActivitiesViewMode.timeline,
    );
  }

  ValidationStatus? _readValidation() {
    final raw = _prefs?.getString(_validationKey);
    if (raw == null) return null;
    for (final s in ValidationStatus.values) {
      if (s.name == raw) return s;
    }
    return null;
  }

  Set<ActivityCategory> _readCategories() {
    final raw = _prefs?.getStringList(_categoriesKey);
    if (raw == null || raw.isEmpty) return const {};
    final out = <ActivityCategory>{};
    for (final name in raw) {
      for (final c in ActivityCategory.values) {
        if (c.name == name) {
          out.add(c);
          break;
        }
      }
    }
    return out;
  }

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> setMode(ActivitiesViewMode mode) async {
    if (mode == state.mode) return;
    emit(state.copyWith(mode: mode));
    await _ensurePrefs();
    await _prefs!.setString(_modeKey, mode.name);
  }

  Future<void> setValidationFilter(ValidationStatus? filter) async {
    if (filter == state.validationFilter) return;
    emit(
      state.copyWith(
        validationFilter: filter,
        clearValidationFilter: filter == null,
      ),
    );
    await _ensurePrefs();
    if (filter == null) {
      await _prefs!.remove(_validationKey);
    } else {
      await _prefs!.setString(_validationKey, filter.name);
    }
  }

  Future<void> toggleCategoryFilter(ActivityCategory category) async {
    final next = Set<ActivityCategory>.from(state.categoryFilters);
    if (!next.add(category)) next.remove(category);
    emit(state.copyWith(categoryFilters: next));
    await _ensurePrefs();
    if (next.isEmpty) {
      await _prefs!.remove(_categoriesKey);
    } else {
      await _prefs!.setStringList(
        _categoriesKey,
        next.map((c) => c.name).toList(),
      );
    }
  }

  Future<void> clearFilters() async {
    if (!state.hasActiveFilters) return;
    emit(
      state.copyWith(clearValidationFilter: true, categoryFilters: const {}),
    );
    await _ensurePrefs();
    await _prefs!.remove(_validationKey);
    await _prefs!.remove(_categoriesKey);
  }
}
