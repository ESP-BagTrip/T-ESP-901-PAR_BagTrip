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

      blocTest<TripShareBloc, TripShareState>(
        'emits [TripShareLoading, TripShareLoaded] with empty list when getSharesByTrip returns no shares',
        build: () {
          when(
            () => mockRepo.getSharesByTrip(any()),
          ).thenAnswer((_) async => const Success(<TripShare>[]));
          return TripShareBloc(tripShareRepository: mockRepo);
        },
        act: (bloc) => bloc.add(LoadShares(tripId: 'trip-1')),
        expect: () => [isA<TripShareLoading>(), isA<TripShareLoaded>()],
        verify: (bloc) {
          expect((bloc.state as TripShareLoaded).shares.isEmpty, true);
        },
      );
    });

    // ── CreateShare ────────────────────────────────────────────────────

    group('CreateShare', () {
      blocTest<TripShareBloc, TripShareState>(
        'emits [TripShareLoading, TripShareLoading, TripShareLoaded] when createShare succeeds and reloads',
        build: () {
          when(
            () => mockRepo.createShare(
              any(),
              email: any(named: 'email'),
              message: any(named: 'message'),
              role: any(named: 'role'),
            ),
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
            () => mockRepo.createShare(
              any(),
              email: any(named: 'email'),
              message: any(named: 'message'),
              role: any(named: 'role'),
            ),
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
            () => mockRepo.createShare(
              any(),
              email: any(named: 'email'),
              message: any(named: 'message'),
              role: any(named: 'role'),
            ),
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

      blocTest<TripShareBloc, TripShareState>(
        'emits [TripShareLoading, TripShareError] when createShare fails with ServerError (already shared)',
        build: () {
          when(
            () => mockRepo.createShare(
              any(),
              email: any(named: 'email'),
              message: any(named: 'message'),
              role: any(named: 'role'),
            ),
          ).thenAnswer(
            (_) async => const Failure(ServerError('already shared')),
          );
          return TripShareBloc(tripShareRepository: mockRepo);
        },
        act: (bloc) => bloc.add(
          CreateShare(tripId: 'trip-1', email: 'viewer@example.com'),
        ),
        expect: () => [isA<TripShareLoading>(), isA<TripShareError>()],
      );

      blocTest<TripShareBloc, TripShareState>(
        'emits [TripShareLoading, TripShareError] when createShare fails with NotFoundError (user not found)',
        build: () {
          when(
            () => mockRepo.createShare(
              any(),
              email: any(named: 'email'),
              message: any(named: 'message'),
              role: any(named: 'role'),
            ),
          ).thenAnswer(
            (_) async => const Failure(NotFoundError('user not found')),
          );
          return TripShareBloc(tripShareRepository: mockRepo);
        },
        act: (bloc) => bloc.add(
          CreateShare(tripId: 'trip-1', email: 'viewer@example.com'),
        ),
        expect: () => [isA<TripShareLoading>(), isA<TripShareError>()],
      );

      blocTest<TripShareBloc, TripShareState>(
        'emits [TripShareLoading, TripShareInvitePending, TripShareLoading, TripShareLoaded] when createShare returns pending invite',
        build: () {
          when(
            () => mockRepo.createShare(
              any(),
              email: any(named: 'email'),
              message: any(named: 'message'),
              role: any(named: 'role'),
            ),
          ).thenAnswer(
            (_) async => Success(
              makeTripShare().copyWith(
                status: 'pending',
                inviteToken: 'tok-123',
              ),
            ),
          );
          when(
            () => mockRepo.getSharesByTrip(any()),
          ).thenAnswer((_) async => const Success(<TripShare>[]));
          return TripShareBloc(tripShareRepository: mockRepo);
        },
        act: (bloc) =>
            bloc.add(CreateShare(tripId: 'trip-1', email: 'new@example.com')),
        expect: () => [
          isA<TripShareLoading>(),
          isA<TripShareInvitePending>(),
          isA<TripShareLoading>(),
          isA<TripShareLoaded>(),
        ],
        verify: (bloc) {
          // Verify the pending state had the correct token
        },
      );

      blocTest<TripShareBloc, TripShareState>(
        'passes role parameter to repository when creating share',
        build: () {
          when(
            () => mockRepo.createShare(
              any(),
              email: any(named: 'email'),
              message: any(named: 'message'),
              role: any(named: 'role'),
            ),
          ).thenAnswer((_) async => Success(makeTripShare()));
          when(
            () => mockRepo.getSharesByTrip(any()),
          ).thenAnswer((_) async => Success([makeTripShare()]));
          return TripShareBloc(tripShareRepository: mockRepo);
        },
        act: (bloc) => bloc.add(
          CreateShare(
            tripId: 'trip-1',
            email: 'editor@example.com',
            role: 'EDITOR',
          ),
        ),
        expect: () => [
          isA<TripShareLoading>(),
          isA<TripShareLoading>(),
          isA<TripShareLoaded>(),
        ],
        verify: (_) {
          verify(
            () => mockRepo.createShare(
              'trip-1',
              email: 'editor@example.com',
              role: 'EDITOR',
            ),
          ).called(1);
        },
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

      blocTest<TripShareBloc, TripShareState>(
        'emits [TripShareLoading, TripShareError] when deleteShare fails with NetworkError',
        build: () {
          when(
            () => mockRepo.deleteShare(any(), any()),
          ).thenAnswer((_) async => const Failure(NetworkError('err')));
          return TripShareBloc(tripShareRepository: mockRepo);
        },
        act: (bloc) =>
            bloc.add(DeleteShare(tripId: 'trip-1', shareId: 'share-1')),
        expect: () => [isA<TripShareLoading>(), isA<TripShareError>()],
      );
    });
  });
}
