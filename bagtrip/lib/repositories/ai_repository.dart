import 'package:bagtrip/core/result.dart';

abstract class AiRepository {
  Future<Result<List<Map<String, dynamic>>>> getInspiration({
    String? travelTypes,
    String? budgetRange,
    int? durationDays,
    String? companions,
    String? season,
    String? constraints,
  });
  Future<Result<Map<String, dynamic>>> acceptInspiration(
    Map<String, dynamic> suggestion, {
    String? startDate,
    String? endDate,
  });
  Future<Result<Map<String, dynamic>>> getPostTripSuggestion();
}
