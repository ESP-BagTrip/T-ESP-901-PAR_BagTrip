import 'package:bagtrip/trips/bloc/trip_share_bloc.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/trip_share.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockTripShareRepository mockRepo;

  setUp(() {
    mockRepo = MockTripShareRepository();
  });

  group('TripShareBloc', () {
    // ── LoadShares ─────────────────────────────────────────────────────

    group('LoadShares', () {
      blocTest<TripShareBloc, TripShareState>(
        'emits [TripShareLoading, TripShareLoaded] when getSharesByTrip succeeds',
        build: () {
          when(
            () => mockRepo.getSharesByTrip(any()),
          ).thenAnswer((_) async => Success([makeTripShare()]));
          return TripShareBloc(tripShareRepository: mockRepo);
        },
        act: (bloc) => bloc.add(LoadShares(tripId: 'trip-1')),
        expect: () => [isA<TripShareLoading>(), isA<TripShareLoaded>()],
        verify: (_) {
          verify(() => mockRepo.getSharesByTrip('trip-1')).called(1);
        },
      );

      blocTest<TripShareBloc, TripShareState>(
        'emits [TripShareLoading, TripShareError] when getSharesByTrip fails',
        build: () {
          when(
            () => mockRepo.getSharesByTrip(any()),
          ).thenAnswer((_) async => const Failure(NetworkError('err')));
          return TripShareBloc(tripShareRepository: mockRepo);
        },
        act: (bloc) => bloc.add(LoadShares(tripId: 'trip-1')),
        expect: () => [isA<TripShareLoading>(), isA<TripShareError>()],
      );
    });

    // ── CreateShare ────────────────────────────────────────────────────

    group('CreateShare', () {
      blocTest<TripShareBloc, TripShareState>(
        'emits [TripShareLoading, TripShareLoading, TripShareLoaded] when createShare succeeds and reloads',
        build: () {
          when(
            () => mockRepo.createShare(any(), email: any(named: 'email')),
          ).thenAnswer((_) async => Success(makeTripShare()));
          when(
            () => mockRepo.getSharesByTrip(any()),
          ).thenAnswer((_) async => Success([makeTripShare()]));
          return TripShareBloc(tripShareRepository: mockRepo);
        },
        act: (bloc) => bloc.add(
          CreateShare(tripId: 'trip-1', email: 'viewer@example.com'),
        ),
        expect: () => [
          isA<TripShareLoading>(),
          isA<TripShareLoading>(),
          isA<TripShareLoaded>(),
        ],
        verify: (_) {
          verify(
            () => mockRepo.createShare('trip-1', email: 'viewer@example.com'),
          ).called(1);
          verify(() => mockRepo.getSharesByTrip('trip-1')).called(1);
        },
      );

      blocTest<TripShareBloc, TripShareState>(
        'emits [TripShareLoading, TripShareQuotaExceeded] when createShare fails with QuotaExceededError',
        build: () {
          when(
            () => mockRepo.createShare(any(), email: any(named: 'email')),
          ).thenAnswer(
            (_) async => const Failure(QuotaExceededError('quota exceeded')),
          );
          return TripShareBloc(tripShareRepository: mockRepo);
        },
        act: (bloc) => bloc.add(
          CreateShare(tripId: 'trip-1', email: 'viewer@example.com'),
        ),
        expect: () => [isA<TripShareLoading>(), isA<TripShareQuotaExceeded>()],
      );

      blocTest<TripShareBloc, TripShareState>(
        'emits [TripShareLoading, TripShareError] when createShare fails with non-quota error',
        build: () {
          when(
            () => mockRepo.createShare(any(), email: any(named: 'email')),
          ).thenAnswer(
            (_) async => const Failure(NetworkError('network error')),
          );
          return TripShareBloc(tripShareRepository: mockRepo);
        },
        act: (bloc) => bloc.add(
          CreateShare(tripId: 'trip-1', email: 'viewer@example.com'),
        ),
        expect: () => [isA<TripShareLoading>(), isA<TripShareError>()],
      );
    });

    // ── DeleteShare ────────────────────────────────────────────────────

    group('DeleteShare', () {
      blocTest<TripShareBloc, TripShareState>(
        'emits [TripShareLoading, TripShareLoading, TripShareLoaded] when deleteShare succeeds and reloads',
        build: () {
          when(
            () => mockRepo.deleteShare(any(), any()),
          ).thenAnswer((_) async => const Success(null));
          when(
            () => mockRepo.getSharesByTrip(any()),
          ).thenAnswer((_) async => const Success(<TripShare>[]));
          return TripShareBloc(tripShareRepository: mockRepo);
        },
        act: (bloc) =>
            bloc.add(DeleteShare(tripId: 'trip-1', shareId: 'share-1')),
        expect: () => [
          isA<TripShareLoading>(),
          isA<TripShareLoading>(),
          isA<TripShareLoaded>(),
        ],
        verify: (_) {
          verify(() => mockRepo.deleteShare('trip-1', 'share-1')).called(1);
          verify(() => mockRepo.getSharesByTrip('trip-1')).called(1);
        },
      );

      blocTest<TripShareBloc, TripShareState>(
        'emits [TripShareLoading, TripShareError] when deleteShare fails',
        build: () {
          when(
            () => mockRepo.deleteShare(any(), any()),
          ).thenAnswer((_) async => const Failure(ServerError('err')));
          return TripShareBloc(tripShareRepository: mockRepo);
        },
        act: (bloc) =>
            bloc.add(DeleteShare(tripId: 'trip-1', shareId: 'share-1')),
        expect: () => [isA<TripShareLoading>(), isA<TripShareError>()],
      );
    });
  });
}
