import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:bagtrip/repositories/accommodation_repository.dart';
import 'package:bagtrip/repositories/activity_repository.dart';
import 'package:bagtrip/repositories/budget_repository.dart';
import 'package:bagtrip/repositories/transport_repository.dart';

/// One gesture, one outcome.
///
/// Validating a SUGGESTED item — whether activity, vol, hôtel, or
/// dépense — is the same backend operation: PATCH the row with
/// `{validationStatus: 'VALIDATED'}`. These extensions make that
/// uniformity visible at the call site so the bloc handlers don't
/// drift into one bespoke shape per domain.
///
/// The payload key is camelCase to align with the rest of the Flutter
/// client (BagtripRequestModel accepts both, the modern call sites
/// use camelCase — see `activity_form.dart`).
const _kValidatePayload = {'validationStatus': 'VALIDATED'};

extension ActivityValidation on ActivityRepository {
  Future<Result<Activity>> validate(String tripId, String activityId) =>
      updateActivity(tripId, activityId, _kValidatePayload);
}

extension TransportValidation on TransportRepository {
  Future<Result<ManualFlight>> validate(String tripId, String flightId) =>
      updateManualFlight(tripId, flightId, _kValidatePayload);
}

extension AccommodationValidation on AccommodationRepository {
  Future<Result<Accommodation>> validate(
    String tripId,
    String accommodationId,
  ) => updateAccommodation(tripId, accommodationId, _kValidatePayload);
}

extension BudgetItemValidation on BudgetRepository {
  Future<Result<BudgetItem>> validate(String tripId, String itemId) =>
      updateBudgetItem(tripId, itemId, _kValidatePayload);
}
