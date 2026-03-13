import 'package:bagtrip/service/api_client.dart';

class SubscriptionService {
  final ApiClient _apiClient;

  SubscriptionService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<String> getCheckoutUrl() async {
    final response = await _apiClient.post('/subscription/checkout');
    return response.data['url'] as String;
  }

  Future<String> getPortalUrl() async {
    final response = await _apiClient.post('/subscription/portal');
    return response.data['url'] as String;
  }

  Future<Map<String, dynamic>> getStatus() async {
    final response = await _apiClient.get('/subscription/status');
    return response.data as Map<String, dynamic>;
  }
}
