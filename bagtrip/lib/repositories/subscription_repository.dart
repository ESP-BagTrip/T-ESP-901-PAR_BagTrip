import 'package:bagtrip/core/result.dart';

abstract class SubscriptionRepository {
  Future<Result<String>> getCheckoutUrl();
  Future<Result<String>> getPortalUrl();
  Future<Result<Map<String, dynamic>>> getStatus();
}
