import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/notification_preferences.dart';
import 'package:bagtrip/repositories/notification_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Which preference field a toggle targets.
enum NotificationPreferenceField {
  pushEnabled,
  flightReminders,
  activityReminders,
  tripUpdates,
  budgetAlerts,
  social,
}

sealed class NotificationPreferencesState {
  const NotificationPreferencesState();
}

class NotificationPreferencesInitial extends NotificationPreferencesState {
  const NotificationPreferencesInitial();
}

class NotificationPreferencesLoading extends NotificationPreferencesState {
  const NotificationPreferencesLoading();
}

class NotificationPreferencesLoaded extends NotificationPreferencesState {
  final NotificationPreferences preferences;

  /// Set when the last optimistic update was rolled back; the view shows a
  /// toaster then clears it on the next emit.
  final AppError? operationError;

  const NotificationPreferencesLoaded({
    required this.preferences,
    this.operationError,
  });

  NotificationPreferencesLoaded copyWith({
    NotificationPreferences? preferences,
    AppError? operationError,
    bool clearError = false,
  }) {
    return NotificationPreferencesLoaded(
      preferences: preferences ?? this.preferences,
      operationError: clearError
          ? null
          : (operationError ?? this.operationError),
    );
  }
}

class NotificationPreferencesError extends NotificationPreferencesState {
  final AppError error;
  const NotificationPreferencesError({required this.error});
}

class NotificationPreferencesCubit extends Cubit<NotificationPreferencesState> {
  final NotificationRepository _repo;

  NotificationPreferencesCubit({NotificationRepository? repo})
    : _repo = repo ?? getIt<NotificationRepository>(),
      super(const NotificationPreferencesInitial());

  Future<void> load() async {
    emit(const NotificationPreferencesLoading());
    final result = await _repo.getNotificationPreferences();
    switch (result) {
      case Success(:final data):
        emit(NotificationPreferencesLoaded(preferences: data));
      case Failure(:final error):
        emit(NotificationPreferencesError(error: error));
    }
  }

  /// Optimistically flips [field] to [value], persists via PATCH, and rolls
  /// back on failure (surfacing the error through [operationError]).
  Future<void> toggle(NotificationPreferenceField field, bool value) async {
    final current = state;
    if (current is! NotificationPreferencesLoaded) return;

    final previous = current.preferences;
    final updated = _apply(previous, field, value);

    // Optimistic emit (no error — operationError defaults to null).
    emit(NotificationPreferencesLoaded(preferences: updated));

    final result = await _repo.updateNotificationPreferences(updated);
    switch (result) {
      case Success(:final data):
        emit(NotificationPreferencesLoaded(preferences: data));
      case Failure(:final error):
        // Rollback to the previous snapshot and surface the error.
        emit(
          NotificationPreferencesLoaded(
            preferences: previous,
            operationError: error,
          ),
        );
    }
  }

  NotificationPreferences _apply(
    NotificationPreferences prefs,
    NotificationPreferenceField field,
    bool value,
  ) {
    return switch (field) {
      NotificationPreferenceField.pushEnabled => prefs.copyWith(
        pushEnabled: value,
      ),
      NotificationPreferenceField.flightReminders => prefs.copyWith(
        flightReminders: value,
      ),
      NotificationPreferenceField.activityReminders => prefs.copyWith(
        activityReminders: value,
      ),
      NotificationPreferenceField.tripUpdates => prefs.copyWith(
        tripUpdates: value,
      ),
      NotificationPreferenceField.budgetAlerts => prefs.copyWith(
        budgetAlerts: value,
      ),
      NotificationPreferenceField.social => prefs.copyWith(social: value),
    };
  }
}
