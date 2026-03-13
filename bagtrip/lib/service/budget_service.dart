import 'package:bagtrip/models/budget_item.dart';
import 'package:bagtrip/service/api_client.dart';

class BudgetService {
  final ApiClient _apiClient;

  BudgetService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Get all budget items for a trip.
  Future<List<BudgetItem>> getBudgetItems(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/budget-items');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((json) => BudgetItem.fromJson(json)).toList();
        } else if (data is Map && data['items'] is List) {
          return (data['items'] as List)
              .map((json) => BudgetItem.fromJson(json))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to fetch budget items: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching budget items: $e');
    }
  }

  /// Get budget summary for a trip.
  Future<BudgetSummary> getBudgetSummary(String tripId) async {
    try {
      final response = await _apiClient.get(
        '/trips/$tripId/budget-items/summary',
      );

      if (response.statusCode == 200) {
        return BudgetSummary.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception(
          'Failed to fetch budget summary: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching budget summary: $e');
    }
  }

  /// Create a budget item for a trip.
  Future<BudgetItem> createBudgetItem(
    String tripId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/budget-items',
        data: data,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return BudgetItem.fromJson(response.data);
      } else {
        throw Exception('Failed to create budget item: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating budget item: $e');
    }
  }

  /// Update a budget item.
  Future<BudgetItem> updateBudgetItem(
    String tripId,
    String itemId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _apiClient.patch(
        '/trips/$tripId/budget-items/$itemId',
        data: updates,
      );

      if (response.statusCode == 200) {
        return BudgetItem.fromJson(response.data);
      } else {
        throw Exception('Failed to update budget item: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating budget item: $e');
    }
  }

  /// Delete a budget item.
  Future<void> deleteBudgetItem(String tripId, String itemId) async {
    try {
      final response = await _apiClient.delete(
        '/trips/$tripId/budget-items/$itemId',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete budget item: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting budget item: $e');
    }
  }
}
