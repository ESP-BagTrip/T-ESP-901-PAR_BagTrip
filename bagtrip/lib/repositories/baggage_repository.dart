import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/models/suggested_baggage_item.dart';

abstract class BaggageRepository {
  Future<Result<BaggageItem>> createBaggageItem(
    String tripId, {
    required String name,
    int? quantity,
    bool? isPacked,
    String? category,
    String? notes,
  });
  Future<Result<List<BaggageItem>>> getByTrip(String tripId);
  Future<Result<BaggageItem>> updateBaggageItem(
    String tripId,
    String baggageItemId,
    Map<String, dynamic> updates,
  );
  Future<Result<void>> deleteBaggageItem(String tripId, String baggageItemId);
  Future<Result<List<SuggestedBaggageItem>>> suggestBaggage(String tripId);
}
