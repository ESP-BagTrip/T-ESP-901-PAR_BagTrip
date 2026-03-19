import 'package:bagtrip/baggage/bloc/baggage_bloc.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockBaggageRepository mockBaggageRepo;

  setUp(() {
    mockBaggageRepo = MockBaggageRepository();
  });

  group('BaggageBloc', () {
    // ── LoadBaggage ─────────────────────────────────────────────────────

    blocTest<BaggageBloc, BaggageState>(
      'emits [BaggageLoading, BaggageLoaded] when LoadBaggage succeeds',
      build: () {
        when(() => mockBaggageRepo.getByTrip(any())).thenAnswer(
          (_) async => Success([
            makeBaggageItem(isPacked: true),
            makeBaggageItem(id: 'bag-2', name: 'Charger'),
          ]),
        );
        return BaggageBloc(baggageRepository: mockBaggageRepo);
      },
      act: (bloc) => bloc.add(LoadBaggage(tripId: 'trip-1')),
      expect: () => [isA<BaggageLoading>(), isA<BaggageLoaded>()],
      verify: (bloc) {
        final state = bloc.state as BaggageLoaded;
        expect(state.items.length, 2);
        expect(state.packedCount, 1);
        expect(state.totalCount, 2);
      },
    );

    blocTest<BaggageBloc, BaggageState>(
      'emits [BaggageLoading, BaggageError] when LoadBaggage fails',
      build: () {
        when(
          () => mockBaggageRepo.getByTrip(any()),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return BaggageBloc(baggageRepository: mockBaggageRepo);
      },
      act: (bloc) => bloc.add(LoadBaggage(tripId: 'trip-1')),
      expect: () => [isA<BaggageLoading>(), isA<BaggageError>()],
    );

    // ── TogglePacked ────────────────────────────────────────────────────

    blocTest<BaggageBloc, BaggageState>(
      'TogglePacked updates item and recalculates packedCount',
      build: () {
        final toggled = makeBaggageItem(isPacked: true);
        when(
          () => mockBaggageRepo.updateBaggageItem(any(), any(), any()),
        ).thenAnswer((_) async => Success(toggled));
        return BaggageBloc(baggageRepository: mockBaggageRepo);
      },
      seed: () => BaggageLoaded(
        items: [
          makeBaggageItem(),
          makeBaggageItem(id: 'bag-2', name: 'Charger', isPacked: true),
        ],
        packedCount: 1,
        totalCount: 2,
      ),
      act: (bloc) =>
          bloc.add(TogglePacked(tripId: 'trip-1', item: makeBaggageItem())),
      expect: () => [isA<BaggageLoaded>()],
      verify: (bloc) {
        final state = bloc.state as BaggageLoaded;
        expect(state.packedCount, 2);
        expect(state.totalCount, 2);
        expect(state.items.first.isPacked, true);
        verifyNever(() => mockBaggageRepo.getByTrip(any()));
      },
    );

    blocTest<BaggageBloc, BaggageState>(
      'TogglePacked falls back to LoadBaggage when state is not BaggageLoaded',
      build: () {
        when(
          () => mockBaggageRepo.updateBaggageItem(any(), any(), any()),
        ).thenAnswer((_) async => Success(makeBaggageItem(isPacked: true)));
        when(
          () => mockBaggageRepo.getByTrip(any()),
        ).thenAnswer((_) async => Success([makeBaggageItem(isPacked: true)]));
        return BaggageBloc(baggageRepository: mockBaggageRepo);
      },
      act: (bloc) =>
          bloc.add(TogglePacked(tripId: 'trip-1', item: makeBaggageItem())),
      wait: const Duration(milliseconds: 100),
      expect: () => [isA<BaggageLoading>(), isA<BaggageLoaded>()],
    );

    // ── DeleteBaggageItem ───────────────────────────────────────────────

    blocTest<BaggageBloc, BaggageState>(
      'DeleteBaggageItem removes item and recalculates counts',
      build: () {
        when(
          () => mockBaggageRepo.deleteBaggageItem(any(), any()),
        ).thenAnswer((_) async => const Success(null));
        return BaggageBloc(baggageRepository: mockBaggageRepo);
      },
      seed: () => BaggageLoaded(
        items: [
          makeBaggageItem(isPacked: true),
          makeBaggageItem(id: 'bag-2', name: 'Charger'),
        ],
        packedCount: 1,
        totalCount: 2,
      ),
      act: (bloc) =>
          bloc.add(DeleteBaggageItem(tripId: 'trip-1', itemId: 'bag-1')),
      expect: () => [isA<BaggageLoaded>()],
      verify: (bloc) {
        final state = bloc.state as BaggageLoaded;
        expect(state.items.length, 1);
        expect(state.items.first.id, 'bag-2');
        expect(state.packedCount, 0);
        expect(state.totalCount, 1);
        verifyNever(() => mockBaggageRepo.getByTrip(any()));
      },
    );

    blocTest<BaggageBloc, BaggageState>(
      'DeleteBaggageItem falls back to LoadBaggage when state is not BaggageLoaded',
      build: () {
        when(
          () => mockBaggageRepo.deleteBaggageItem(any(), any()),
        ).thenAnswer((_) async => const Success(null));
        when(
          () => mockBaggageRepo.getByTrip(any()),
        ).thenAnswer((_) async => const Success([]));
        return BaggageBloc(baggageRepository: mockBaggageRepo);
      },
      act: (bloc) =>
          bloc.add(DeleteBaggageItem(tripId: 'trip-1', itemId: 'bag-1')),
      wait: const Duration(milliseconds: 100),
      expect: () => [isA<BaggageLoading>(), isA<BaggageLoaded>()],
    );

    // ── CreateBaggageItem ───────────────────────────────────────────────

    blocTest<BaggageBloc, BaggageState>(
      'CreateBaggageItem appends item and recalculates counts',
      build: () {
        final newItem = makeBaggageItem(id: 'bag-new', name: 'Sunglasses');
        when(
          () => mockBaggageRepo.createBaggageItem(
            any(),
            name: any(named: 'name'),
            quantity: any(named: 'quantity'),
            category: any(named: 'category'),
          ),
        ).thenAnswer((_) async => Success(newItem));
        return BaggageBloc(baggageRepository: mockBaggageRepo);
      },
      seed: () => BaggageLoaded(
        items: [makeBaggageItem(isPacked: true)],
        packedCount: 1,
        totalCount: 1,
      ),
      act: (bloc) => bloc.add(
        CreateBaggageItem(
          tripId: 'trip-1',
          name: 'Sunglasses',
          quantity: 1,
          category: 'accessories',
        ),
      ),
      expect: () => [isA<BaggageLoaded>()],
      verify: (bloc) {
        final state = bloc.state as BaggageLoaded;
        expect(state.items.length, 2);
        expect(state.items.last.id, 'bag-new');
        expect(state.packedCount, 1);
        expect(state.totalCount, 2);
        verifyNever(() => mockBaggageRepo.getByTrip(any()));
      },
    );

    blocTest<BaggageBloc, BaggageState>(
      'CreateBaggageItem falls back to LoadBaggage when state is not BaggageLoaded',
      build: () {
        when(
          () => mockBaggageRepo.createBaggageItem(
            any(),
            name: any(named: 'name'),
            quantity: any(named: 'quantity'),
            category: any(named: 'category'),
          ),
        ).thenAnswer((_) async => Success(makeBaggageItem()));
        when(
          () => mockBaggageRepo.getByTrip(any()),
        ).thenAnswer((_) async => Success([makeBaggageItem()]));
        return BaggageBloc(baggageRepository: mockBaggageRepo);
      },
      act: (bloc) => bloc.add(
        CreateBaggageItem(
          tripId: 'trip-1',
          name: 'Passport',
          quantity: 1,
          category: 'documents',
        ),
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => [isA<BaggageLoading>(), isA<BaggageLoaded>()],
    );

    // ── Error handling ──────────────────────────────────────────────────

    blocTest<BaggageBloc, BaggageState>(
      'emits BaggageError when CreateBaggageItem fails',
      build: () {
        when(
          () => mockBaggageRepo.createBaggageItem(
            any(),
            name: any(named: 'name'),
            quantity: any(named: 'quantity'),
            category: any(named: 'category'),
          ),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return BaggageBloc(baggageRepository: mockBaggageRepo);
      },
      act: (bloc) => bloc.add(
        CreateBaggageItem(
          tripId: 'trip-1',
          name: 'Passport',
          quantity: 1,
          category: 'documents',
        ),
      ),
      expect: () => [isA<BaggageError>()],
    );
  });
}
