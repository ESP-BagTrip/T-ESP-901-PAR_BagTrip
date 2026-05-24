import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/traveler.dart';

abstract class TravelerRepository {
  Future<Result<Traveler>> createTraveler(
    String tripId, {
    String? amadeusTravelerRef,
    required String travelerType,
    required String firstName,
    required String lastName,
    DateTime? dateOfBirth,
    String? gender,
    List<Map<String, dynamic>>? documents,
    Map<String, dynamic>? contacts,
  });
  Future<Result<List<Traveler>>> getTravelersByTrip(String tripId);
  Future<Result<Traveler>> updateTraveler(
    String tripId,
    String travelerId,
    Map<String, dynamic> updates,
  );
  Future<Result<void>> deleteTraveler(String tripId, String travelerId);
}
