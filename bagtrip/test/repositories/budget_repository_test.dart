import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/service/budget_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_services.dart';

void main() {
  late MockApiClient mockApiClient;
  late BudgetRepositoryImpl repo;

  setUp(() {
    mockApiClient = MockApiClient();
    repo = BudgetRepositoryImpl(apiClient: mockApiClient);
  });

  final budgetItemJson = {
    'id': 'bi-1',
    'trip_id': 'trip-1',
    'label': 'Hotel night',
    'amount': 120.0,
    'category': 'ACCOMMODATION',
    'is_planned': true,
  };

  final budgetSummaryJson = {
    'totalBudget': 1500.0,
    'totalSpent': 400.0,
    'remaining': 1100.0,
    'byCategory': <String, dynamic>{'ACCOMMODATION': 300.0, 'FOOD': 100.0},
    'confirmedTotal': 300.0,
    'forecastedTotal': 1200.0,
  };

  final budgetEstimationJson = {
    'accommodationPerNight': 80.0,
    'mealsPerDayPerPerson': 35.0,
    'localTransportPerDay': 15.0,
    'activitiesTotal': 200.0,
    'totalMin': 800.0,
    'totalMax': 1200.0,
    'currency': 'EUR',
    'breakdownNotes': 'Estimated for 5 days',
  };

  group('getBudgetItems', () {
    test('returns Success(List<BudgetItem>) on 200', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: [budgetItemJson],
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1/budget-items'),
        ),
      );

      final result = await repo.getBudgetItems('trip-1');

      expect(result, isA<Success>());
      final items = (result as Success).data;
      expect(items, hasLength(1));
      expect(items.first.id, 'bi-1');
      expect(items.first.label, 'Hotel night');
      expect(items.first.amount, 120.0);
    });
  });

  group('getBudgetSummary', () {
    test('returns Success(BudgetSummary) on 200', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: budgetSummaryJson,
          statusCode: 200,
          requestOptions: RequestOptions(
            path: '/trips/trip-1/budget-items/summary',
          ),
        ),
      );

      final result = await repo.getBudgetSummary('trip-1');

      expect(result, isA<Success>());
      final summary = (result as Success).data;
      expect(summary.totalBudget, 1500.0);
      expect(summary.totalSpent, 400.0);
      expect(summary.remaining, 1100.0);
    });
  });

  group('createBudgetItem', () {
    test('returns Success(BudgetItem) on 201', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: budgetItemJson,
          statusCode: 201,
          requestOptions: RequestOptions(path: '/trips/trip-1/budget-items'),
        ),
      );

      final result = await repo.createBudgetItem('trip-1', {
        'label': 'Hotel night',
        'amount': 120.0,
        'category': 'ACCOMMODATION',
      });

      expect(result, isA<Success>());
      final item = (result as Success).data;
      expect(item.id, 'bi-1');
      expect(item.label, 'Hotel night');
    });
  });

  group('updateBudgetItem', () {
    test('returns Success(BudgetItem) on 200', () async {
      final updatedJson = {...budgetItemJson, 'amount': 150.0};

      when(
        () => mockApiClient.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: updatedJson,
          statusCode: 200,
          requestOptions: RequestOptions(
            path: '/trips/trip-1/budget-items/bi-1',
          ),
        ),
      );

      final result = await repo.updateBudgetItem('trip-1', 'bi-1', {
        'amount': 150.0,
      });

      expect(result, isA<Success>());
      final item = (result as Success).data;
      expect(item.amount, 150.0);
    });
  });

  group('deleteBudgetItem', () {
    test('returns Success(null) on 204', () async {
      when(
        () => mockApiClient.delete(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 204,
          requestOptions: RequestOptions(
            path: '/trips/trip-1/budget-items/bi-1',
          ),
        ),
      );

      final result = await repo.deleteBudgetItem('trip-1', 'bi-1');

      expect(result, isA<Success>());
    });
  });

  group('estimateBudget', () {
    test('returns Success(BudgetEstimation) on 200', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {'estimation': budgetEstimationJson},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1/budget/estimate'),
        ),
      );

      final result = await repo.estimateBudget('trip-1');

      expect(result, isA<Success>());
      final estimation = (result as Success).data;
      expect(estimation.totalMin, 800.0);
      expect(estimation.totalMax, 1200.0);
      expect(estimation.currency, 'EUR');
    });

    test('DioException 402 returns Failure(QuotaExceededError)', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/trips/trip-1/budget/estimate'),
          response: Response(
            statusCode: 402,
            data: {'detail': 'quota exceeded'},
            requestOptions: RequestOptions(
              path: '/trips/trip-1/budget/estimate',
            ),
          ),
        ),
      );

      final result = await repo.estimateBudget('trip-1');

      expect(result, isA<Failure>());
      final error = (result as Failure).error;
      expect(error, isA<QuotaExceededError>());
      expect(error.statusCode, 402);
      expect(error.message, 'quota exceeded');
    });
  });

  group('acceptBudgetEstimate', () {
    test('returns Success(null) on 200', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {'ok': true},
          statusCode: 200,
          requestOptions: RequestOptions(
            path: '/trips/trip-1/budget/estimate/accept',
          ),
        ),
      );

      final result = await repo.acceptBudgetEstimate('trip-1', 1200.0);

      expect(result, isA<Success>());
    });

    test('non-200 returns Failure', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(
            path: '/trips/trip-1/budget/estimate/accept',
          ),
        ),
      );
      expect(await repo.acceptBudgetEstimate('trip-1', 1200), isA<Failure>());
    });

    test('DioException returns Failure', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/trips/trip-1/budget/estimate/accept',
          ),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.acceptBudgetEstimate('trip-1', 1200), isA<Failure>());
    });
  });

  // ── Phase B reinforcement ─────────────────────────────────────────────

  group('getBudgetItems — reinforcement', () {
    test('items envelope accepted', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'items': [budgetItemJson],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1/budget-items'),
        ),
      );
      expect(await repo.getBudgetItems('trip-1'), isA<Success>());
    });

    test('unknown shape returns empty Success', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1/budget-items'),
        ),
      );
      final result = await repo.getBudgetItems('trip-1');
      expect(result, isA<Success>());
      expect((result as Success).data, isEmpty);
    });

    test('non-200 returns Failure', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(path: '/trips/trip-1/budget-items'),
        ),
      );
      expect(await repo.getBudgetItems('trip-1'), isA<Failure>());
    });

    test('DioException returns Failure', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/trips/trip-1/budget-items'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.getBudgetItems('trip-1'), isA<Failure>());
    });
  });

  group('getBudgetSummary — reinforcement', () {
    test('non-200 returns Failure', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(
            path: '/trips/trip-1/budget-items/summary',
          ),
        ),
      );
      expect(await repo.getBudgetSummary('trip-1'), isA<Failure>());
    });

    test('DioException returns Failure', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/trips/trip-1/budget-items/summary',
          ),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.getBudgetSummary('trip-1'), isA<Failure>());
    });
  });

  group('createBudgetItem — reinforcement', () {
    test('non-2xx returns Failure', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(path: '/trips/trip-1/budget-items'),
        ),
      );
      expect(
        await repo.createBudgetItem('trip-1', {'label': 'x'}),
        isA<Failure>(),
      );
    });

    test('DioException returns Failure', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/trips/trip-1/budget-items'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(
        await repo.createBudgetItem('trip-1', {'label': 'x'}),
        isA<Failure>(),
      );
    });
  });

  group('updateBudgetItem — reinforcement', () {
    test('non-200 returns Failure', () async {
      when(
        () => mockApiClient.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(
            path: '/trips/trip-1/budget-items/bi-1',
          ),
        ),
      );
      expect(await repo.updateBudgetItem('trip-1', 'bi-1', {}), isA<Failure>());
    });

    test('DioException returns Failure', () async {
      when(
        () => mockApiClient.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/trips/trip-1/budget-items/bi-1',
          ),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.updateBudgetItem('trip-1', 'bi-1', {}), isA<Failure>());
    });
  });

  group('deleteBudgetItem — reinforcement', () {
    test('non-2xx returns Failure', () async {
      when(
        () => mockApiClient.delete(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(
            path: '/trips/trip-1/budget-items/bi-1',
          ),
        ),
      );
      expect(await repo.deleteBudgetItem('trip-1', 'bi-1'), isA<Failure>());
    });

    test('DioException returns Failure', () async {
      when(
        () => mockApiClient.delete(any(), options: any(named: 'options')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/trips/trip-1/budget-items/bi-1',
          ),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.deleteBudgetItem('trip-1', 'bi-1'), isA<Failure>());
    });
  });

  group('estimateBudget — reinforcement', () {
    test('invalid shape returns Failure', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1/budget/estimate'),
        ),
      );
      expect(await repo.estimateBudget('trip-1'), isA<Failure>());
    });

    test('non-200 returns Failure', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(path: '/trips/trip-1/budget/estimate'),
        ),
      );
      expect(await repo.estimateBudget('trip-1'), isA<Failure>());
    });
  });
}
