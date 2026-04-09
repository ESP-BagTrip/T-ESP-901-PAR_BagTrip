import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:bagtrip/repositories/budget_repository.dart';
import 'package:bagtrip/service/cached_budget_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_fixtures.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockCacheService extends Mock implements CacheService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockBudgetRepository mockRemote;
  late MockCacheService mockCache;
  late MockConnectivityService mockConnectivity;
  late CachedBudgetRepository repo;

  setUpAll(() {
    registerFallbackValue(const Duration(minutes: 15));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockRemote = MockBudgetRepository();
    mockCache = MockCacheService();
    mockConnectivity = MockConnectivityService();
    repo = CachedBudgetRepository(
      remote: mockRemote,
      cache: mockCache,
      connectivity: mockConnectivity,
    );
  });

  group('getBudgetItems', () {
    test('online + API success → caches and returns Success', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      final items = [makeBudgetItem(), makeBudgetItem(id: 'budget-2')];
      when(
        () => mockRemote.getBudgetItems('trip-1'),
      ).thenAnswer((_) async => Success(items));
      when(() => mockCache.put(any(), any(), any())).thenAnswer((_) async {});

      final result = await repo.getBudgetItems('trip-1');

      expect(result, isA<Success<List<BudgetItem>>>());
      verify(
        () => mockCache.put('budget_cache', 'budget_items:trip-1', any()),
      ).called(1);
    });

    test('online + API failure → returns Failure, no cache write', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.getBudgetItems('trip-1'),
      ).thenAnswer((_) async => const Failure(ServerError('fail')));

      final result = await repo.getBudgetItems('trip-1');

      expect(result, isA<Failure<List<BudgetItem>>>());
      verifyNever(() => mockCache.put(any(), any(), any()));
    });

    test('offline + cache hit → returns Success from cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      final item = makeBudgetItem();
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer(
        (_) async => {
          'items': [item.toJson()],
        },
      );

      final result = await repo.getBudgetItems('trip-1');

      expect(result, isA<Success<List<BudgetItem>>>());
      verifyNever(() => mockRemote.getBudgetItems(any()));
    });

    test('offline + cache miss → returns Failure', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer((_) async => null);

      final result = await repo.getBudgetItems('trip-1');

      expect(result, isA<Failure<List<BudgetItem>>>());
    });
  });

  group('getBudgetSummary', () {
    test('online + API success → caches and returns Success', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      final summary = makeBudgetSummary();
      when(
        () => mockRemote.getBudgetSummary('trip-1'),
      ).thenAnswer((_) async => Success(summary));
      when(() => mockCache.put(any(), any(), any())).thenAnswer((_) async {});

      final result = await repo.getBudgetSummary('trip-1');

      expect(result, isA<Success<BudgetSummary>>());
      verify(
        () => mockCache.put('budget_cache', 'budget_summary:trip-1', any()),
      ).called(1);
    });

    test('offline + cache hit → returns Success from cache', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      final summary = makeBudgetSummary();
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer((_) async => summary.toJson());

      final result = await repo.getBudgetSummary('trip-1');

      expect(result, isA<Success<BudgetSummary>>());
      verifyNever(() => mockRemote.getBudgetSummary(any()));
    });

    test('offline + cache miss → returns Failure', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer((_) async => null);

      final result = await repo.getBudgetSummary('trip-1');

      expect(result, isA<Failure<BudgetSummary>>());
    });
  });

  group('pass-through methods', () {
    test('estimateBudget delegates to remote', () async {
      when(
        () => mockRemote.estimateBudget('trip-1'),
      ).thenAnswer((_) async => const Failure(ServerError('not tested')));

      await repo.estimateBudget('trip-1');

      verify(() => mockRemote.estimateBudget('trip-1')).called(1);
    });
  });

  group('write operations', () {
    test('createBudgetItem success → invalidates both caches', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      final item = makeBudgetItem();
      when(
        () => mockRemote.createBudgetItem('trip-1', any()),
      ).thenAnswer((_) async => Success(item));
      when(() => mockCache.delete(any(), any())).thenAnswer((_) async {});

      final result = await repo.createBudgetItem('trip-1', {'label': 'Taxi'});

      expect(result, isA<Success<BudgetItem>>());
      verify(
        () => mockCache.delete('budget_cache', 'budget_items:trip-1'),
      ).called(1);
      verify(
        () => mockCache.delete('budget_cache', 'budget_summary:trip-1'),
      ).called(1);
    });

    test('createBudgetItem failure → does not invalidate', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.createBudgetItem('trip-1', any()),
      ).thenAnswer((_) async => const Failure(ServerError('fail')));

      final result = await repo.createBudgetItem('trip-1', {'label': 'Taxi'});

      expect(result, isA<Failure<BudgetItem>>());
      verifyNever(() => mockCache.delete(any(), any()));
    });

    test('updateBudgetItem success → invalidates both caches', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      final item = makeBudgetItem();
      when(
        () => mockRemote.updateBudgetItem('trip-1', 'budget-1', any()),
      ).thenAnswer((_) async => Success(item));
      when(() => mockCache.delete(any(), any())).thenAnswer((_) async {});

      final result = await repo.updateBudgetItem('trip-1', 'budget-1', {
        'amount': 200,
      });

      expect(result, isA<Success<BudgetItem>>());
      verify(
        () => mockCache.delete('budget_cache', 'budget_items:trip-1'),
      ).called(1);
      verify(
        () => mockCache.delete('budget_cache', 'budget_summary:trip-1'),
      ).called(1);
    });

    test('deleteBudgetItem success → invalidates both caches', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(
        () => mockRemote.deleteBudgetItem('trip-1', 'budget-1'),
      ).thenAnswer((_) async => const Success(null));
      when(() => mockCache.delete(any(), any())).thenAnswer((_) async {});

      final result = await repo.deleteBudgetItem('trip-1', 'budget-1');

      expect(result, isA<Success<void>>());
      verify(
        () => mockCache.delete('budget_cache', 'budget_items:trip-1'),
      ).called(1);
      verify(
        () => mockCache.delete('budget_cache', 'budget_summary:trip-1'),
      ).called(1);
    });

    test('acceptBudgetEstimate success → invalidates summary', () async {
      when(
        () => mockRemote.acceptBudgetEstimate('trip-1', 1500.0),
      ).thenAnswer((_) async => const Success(null));
      when(() => mockCache.delete(any(), any())).thenAnswer((_) async {});

      final result = await repo.acceptBudgetEstimate('trip-1', 1500.0);

      expect(result, isA<Success<void>>());
      verify(
        () => mockCache.delete('budget_cache', 'budget_summary:trip-1'),
      ).called(1);
    });
  });
}
