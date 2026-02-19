import 'package:bagtrip/models/traveler_profile.dart';
import 'package:bagtrip/service/api_client.dart';

class ProfileApiService {
  final ApiClient _apiClient;

  ProfileApiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Get the current user's traveler profile.
  Future<TravelerProfile> getProfile() async {
    final response = await _apiClient.get('/profile');
    return TravelerProfile.fromJson(response.data as Map<String, dynamic>);
  }

  /// Create or update the traveler profile.
  Future<TravelerProfile> updateProfile({
    List<String>? travelTypes,
    String? travelStyle,
    String? budget,
    String? companions,
  }) async {
    final response = await _apiClient.put(
      '/profile',
      data: {
        if (travelTypes != null) 'travelTypes': travelTypes,
        if (travelStyle != null) 'travelStyle': travelStyle,
        if (budget != null) 'budget': budget,
        if (companions != null) 'companions': companions,
      },
    );
    return TravelerProfile.fromJson(response.data as Map<String, dynamic>);
  }

  /// Check profile completion status.
  Future<ProfileCompletion> checkCompletion() async {
    final response = await _apiClient.get('/profile/completion');
    return ProfileCompletion.fromJson(response.data as Map<String, dynamic>);
  }
}
