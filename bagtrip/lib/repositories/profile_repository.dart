import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/traveler_profile.dart';

abstract class ProfileRepository {
  Future<Result<TravelerProfile>> getProfile();
  Future<Result<TravelerProfile>> updateProfile({
    List<String>? travelTypes,
    String? travelStyle,
    String? budget,
    String? companions,
  });
  Future<Result<ProfileCompletion>> checkCompletion();
}
