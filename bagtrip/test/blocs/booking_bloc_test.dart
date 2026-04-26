import 'package:bagtrip/booking/bloc/booking_bloc.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/repositories/booking_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

/// Stub returning `online == true` so the bloc's connectivity gate is a
/// no-op in tests that don't care about offline behaviour. Tests that *do*
/// care construct their own [_OfflineConnectivity].
class _OnlineConnectivity extends Fake implements ConnectivityService {
  @override
  bool get isOnline => true;
}

class _OfflineConnectivity extends Fake implements ConnectivityService {
  @override
  bool get isOnline => false;
}

void main() {
  late MockBookingRepository mockRepo;
  late ConnectivityService connectivity;

  setUpAll(() async {
    await initializeDateFormatting('fr');
  });

  setUp(() {
    mockRepo = MockBookingRepository();
    connectivity = _OnlineConnectivity();
  });

  group('BookingBloc', () {
    // ── LoadBookings ───────────────────────────────────────────────────

    group('LoadBookings', () {
      blocTest<BookingBloc, BookingState>(
        'emits [BookingLoading, BookingLoaded] when listBookings succeeds',
        build: () {
          when(
            () => mockRepo.listBookings(),
          ).thenAnswer((_) async => Success([makeBookingResponse()]));
          return BookingBloc(
            bookingRepository: mockRepo,
            connectivityService: connectivity,
          );
        },
        act: (bloc) => bloc.add(LoadBookings()),
        expect: () => [isA<BookingLoading>(), isA<BookingLoaded>()],
        verify: (_) {
          verify(() => mockRepo.listBookings()).called(1);
        },
      );

      blocTest<BookingBloc, BookingState>(
        'emits BookingLoaded with correctly mapped recentBookings',
        build: () {
          when(() => mockRepo.listBookings()).thenAnswer(
            (_) async =>
                Success([makeBookingResponse(createdAt: DateTime(2024, 5))]),
          );
          return BookingBloc(
            bookingRepository: mockRepo,
            connectivityService: connectivity,
          );
        },
        act: (bloc) => bloc.add(LoadBookings()),
        expect: () => [isA<BookingLoading>(), isA<BookingLoaded>()],
        verify: (bloc) {
          final loaded = bloc.state as BookingLoaded;
          expect(loaded.recentBookings, hasLength(1));
          final rb = loaded.recentBookings.first;
          expect(rb.id, 'book-1');
          expect(rb.status, 'confirmed');
        },
      );

      blocTest<BookingBloc, BookingState>(
        'emits BookingLoaded with empty list when no bookings exist',
        build: () {
          when(
            () => mockRepo.listBookings(),
          ).thenAnswer((_) async => const Success([]));
          return BookingBloc(
            bookingRepository: mockRepo,
            connectivityService: connectivity,
          );
        },
        act: (bloc) => bloc.add(LoadBookings()),
        expect: () => [isA<BookingLoading>(), isA<BookingLoaded>()],
        verify: (bloc) {
          final loaded = bloc.state as BookingLoaded;
          expect(loaded.recentBookings, isEmpty);
        },
      );

      blocTest<BookingBloc, BookingState>(
        'emits [BookingLoading, BookingError] when listBookings fails',
        build: () {
          when(
            () => mockRepo.listBookings(),
          ).thenAnswer((_) async => const Failure(NetworkError('err')));
          return BookingBloc(
            bookingRepository: mockRepo,
            connectivityService: connectivity,
          );
        },
        act: (bloc) => bloc.add(LoadBookings()),
        expect: () => [isA<BookingLoading>(), isA<BookingError>()],
      );

      blocTest<BookingBloc, BookingState>(
        'emits [BookingLoading, BookingError] when listBookings fails with ServerError',
        build: () {
          when(
            () => mockRepo.listBookings(),
          ).thenAnswer((_) async => const Failure(ServerError('server down')));
          return BookingBloc(
            bookingRepository: mockRepo,
            connectivityService: connectivity,
          );
        },
        act: (bloc) => bloc.add(LoadBookings()),
        expect: () => [isA<BookingLoading>(), isA<BookingError>()],
      );
    });

    // ── CreateBookingIntent ────────────────────────────────────────────

    group('CreateBookingIntent', () {
      blocTest<BookingBloc, BookingState>(
        'on Success dispatches AuthorizePayment → PaymentSheetReady',
        build: () {
          when(
            () => mockRepo.createBookingIntent(
              tripId: any(named: 'tripId'),
              flightOfferId: any(named: 'flightOfferId'),
            ),
          ).thenAnswer((_) async => const Success('intent-42'));
          when(
            () => mockRepo.authorizePayment('intent-42'),
          ).thenAnswer((_) async => Success(makePaymentAuthorizeResponse()));
          return BookingBloc(
            bookingRepository: mockRepo,
            connectivityService: connectivity,
          );
        },
        act: (bloc) => bloc.add(
          CreateBookingIntent(tripId: 't-1', flightOfferId: 'offer-1'),
        ),
        // First PaymentAuthorizing from CreateBookingIntent, then from the
        // internal AuthorizePayment dispatch, then PaymentSheetReady.
        expect: () => [
          isA<PaymentAuthorizing>(),
          isA<PaymentAuthorizing>(),
          isA<PaymentSheetReady>(),
        ],
        verify: (bloc) {
          final ready = bloc.state as PaymentSheetReady;
          expect(ready.intentId, 'intent-42');
          expect(ready.clientSecret, 'secret_123');
          verify(
            () => mockRepo.createBookingIntent(
              tripId: 't-1',
              flightOfferId: 'offer-1',
            ),
          ).called(1);
          verify(() => mockRepo.authorizePayment('intent-42')).called(1);
        },
      );

      blocTest<BookingBloc, BookingState>(
        'on Failure emits [PaymentAuthorizing, PaymentFailed]',
        build: () {
          when(
            () => mockRepo.createBookingIntent(
              tripId: any(named: 'tripId'),
              flightOfferId: any(named: 'flightOfferId'),
            ),
          ).thenAnswer((_) async => const Failure(NetworkError('offline')));
          return BookingBloc(
            bookingRepository: mockRepo,
            connectivityService: connectivity,
          );
        },
        act: (bloc) => bloc.add(
          CreateBookingIntent(tripId: 't-1', flightOfferId: 'offer-1'),
        ),
        expect: () => [isA<PaymentAuthorizing>(), isA<PaymentFailed>()],
        verify: (bloc) {
          final failed = bloc.state as PaymentFailed;
          expect(failed.error, isA<NetworkError>());
        },
      );
    });

    // ── AuthorizePayment (directly dispatched) ─────────────────────────

    group('AuthorizePayment', () {
      blocTest<BookingBloc, BookingState>(
        'on Success emits [PaymentAuthorizing, PaymentSheetReady]',
        build: () {
          when(
            () => mockRepo.authorizePayment('intent-1'),
          ).thenAnswer((_) async => Success(makePaymentAuthorizeResponse()));
          return BookingBloc(
            bookingRepository: mockRepo,
            connectivityService: connectivity,
          );
        },
        act: (bloc) => bloc.add(AuthorizePayment(intentId: 'intent-1')),
        expect: () => [isA<PaymentAuthorizing>(), isA<PaymentSheetReady>()],
      );

      blocTest<BookingBloc, BookingState>(
        'on Failure emits [PaymentAuthorizing, PaymentFailed]',
        build: () {
          when(
            () => mockRepo.authorizePayment('intent-1'),
          ).thenAnswer((_) async => const Failure(ServerError('stripe down')));
          return BookingBloc(
            bookingRepository: mockRepo,
            connectivityService: connectivity,
          );
        },
        act: (bloc) => bloc.add(AuthorizePayment(intentId: 'intent-1')),
        expect: () => [isA<PaymentAuthorizing>(), isA<PaymentFailed>()],
      );
    });

    // ── CapturePayment ─────────────────────────────────────────────────

    group('CapturePayment', () {
      blocTest<BookingBloc, BookingState>(
        'on Success emits PaymentSuccess',
        build: () {
          when(
            () => mockRepo.capturePayment('intent-1'),
          ).thenAnswer((_) async => const Success(null));
          return BookingBloc(
            bookingRepository: mockRepo,
            connectivityService: connectivity,
          );
        },
        act: (bloc) => bloc.add(CapturePayment(intentId: 'intent-1')),
        expect: () => [isA<PaymentSuccess>()],
        verify: (bloc) {
          final success = bloc.state as PaymentSuccess;
          expect(success.intentId, 'intent-1');
        },
      );

      blocTest<BookingBloc, BookingState>(
        'on Failure emits PaymentFailed',
        build: () {
          when(
            () => mockRepo.capturePayment('intent-1'),
          ).thenAnswer((_) async => const Failure(ServerError('nope')));
          return BookingBloc(
            bookingRepository: mockRepo,
            connectivityService: connectivity,
          );
        },
        act: (bloc) => bloc.add(CapturePayment(intentId: 'intent-1')),
        expect: () => [isA<PaymentFailed>()],
      );
    });

    // ── RefundPayment ────────────────────────────────────────────────────

    group('RefundPayment', () {
      blocTest<BookingBloc, BookingState>(
        'full refund: emits RefundInProgress then RefundSucceeded',
        build: () {
          when(
            () => mockRepo.refundPayment(
              'intent-1',
              amount: any(named: 'amount'),
              reason: any(named: 'reason'),
            ),
          ).thenAnswer((_) async => const Success(null));
          return BookingBloc(
            bookingRepository: mockRepo,
            connectivityService: connectivity,
          );
        },
        act: (bloc) => bloc.add(RefundPayment(intentId: 'intent-1')),
        expect: () => [isA<RefundInProgress>(), isA<RefundSucceeded>()],
        verify: (_) {
          final captured = verify(
            () => mockRepo.refundPayment(
              'intent-1',
              amount: captureAny(named: 'amount'),
              reason: captureAny(named: 'reason'),
            ),
          ).captured;
          // Full refund → amount nullified.
          expect(captured[0], isNull);
        },
      );

      blocTest<BookingBloc, BookingState>(
        'partial refund: forwards amount + reason as-is',
        build: () {
          when(
            () => mockRepo.refundPayment(
              'intent-1',
              amount: 500,
              reason: RefundReason.requestedByCustomer,
            ),
          ).thenAnswer((_) async => const Success(null));
          return BookingBloc(
            bookingRepository: mockRepo,
            connectivityService: connectivity,
          );
        },
        act: (bloc) => bloc.add(
          RefundPayment(
            intentId: 'intent-1',
            amount: 500,
            reason: RefundReason.requestedByCustomer,
          ),
        ),
        expect: () => [isA<RefundInProgress>(), isA<RefundSucceeded>()],
      );

      blocTest<BookingBloc, BookingState>(
        'failure: maps to PaymentFailed with the AppError',
        build: () {
          when(
            () => mockRepo.refundPayment(
              'intent-1',
              amount: any(named: 'amount'),
              reason: any(named: 'reason'),
            ),
          ).thenAnswer(
            (_) async => const Failure(
              ValidationError(
                'too much',
                code: 'REFUND_AMOUNT_EXCEEDS_REMAINING',
              ),
            ),
          );
          return BookingBloc(
            bookingRepository: mockRepo,
            connectivityService: connectivity,
          );
        },
        act: (bloc) =>
            bloc.add(RefundPayment(intentId: 'intent-1', amount: 99999)),
        expect: () => [
          isA<RefundInProgress>(),
          predicate<BookingState>(
            (s) =>
                s is PaymentFailed &&
                s.error.code == 'REFUND_AMOUNT_EXCEEDS_REMAINING',
            'PaymentFailed carries backend code',
          ),
        ],
      );
    });

    // ── Offline guard ────────────────────────────────────────────────────

    group('Offline guard', () {
      blocTest<BookingBloc, BookingState>(
        'authorize while offline: emits PaymentFailed(NetworkError) without hitting Stripe',
        build: () => BookingBloc(
          bookingRepository: mockRepo,
          connectivityService: _OfflineConnectivity(),
        ),
        act: (bloc) => bloc.add(AuthorizePayment(intentId: 'intent-1')),
        expect: () => [
          predicate<BookingState>(
            (s) => s is PaymentFailed && s.error is NetworkError,
          ),
        ],
        verify: (_) {
          verifyNever(() => mockRepo.authorizePayment(any()));
        },
      );

      blocTest<BookingBloc, BookingState>(
        'capture while offline: rejected — local state is the source of truth',
        build: () => BookingBloc(
          bookingRepository: mockRepo,
          connectivityService: _OfflineConnectivity(),
        ),
        act: (bloc) => bloc.add(CapturePayment(intentId: 'intent-1')),
        expect: () => [
          predicate<BookingState>(
            (s) => s is PaymentFailed && s.error is NetworkError,
          ),
        ],
        verify: (_) {
          verifyNever(() => mockRepo.capturePayment(any()));
        },
      );

      blocTest<BookingBloc, BookingState>(
        'refund while offline: rejected before request',
        build: () => BookingBloc(
          bookingRepository: mockRepo,
          connectivityService: _OfflineConnectivity(),
        ),
        act: (bloc) => bloc.add(RefundPayment(intentId: 'intent-1')),
        expect: () => [
          predicate<BookingState>(
            (s) => s is PaymentFailed && s.error is NetworkError,
          ),
        ],
        verify: (_) {
          verifyNever(
            () => mockRepo.refundPayment(
              any(),
              amount: any(named: 'amount'),
              reason: any(named: 'reason'),
            ),
          );
        },
      );
    });

    // ── ConfirmPaymentFromDeepLink ───────────────────────────────────────

    group('ConfirmPaymentFromDeepLink', () {
      blocTest<BookingBloc, BookingState>(
        'matching intentId in PaymentSheetReady → captures',
        build: () {
          when(
            () => mockRepo.capturePayment('intent-1'),
          ).thenAnswer((_) async => const Success(null));
          return BookingBloc(
            bookingRepository: mockRepo,
            connectivityService: connectivity,
          );
        },
        seed: () =>
            PaymentSheetReady(clientSecret: 'secret', intentId: 'intent-1'),
        act: (bloc) =>
            bloc.add(ConfirmPaymentFromDeepLink(intentId: 'intent-1')),
        expect: () => [isA<PaymentSuccess>()],
        verify: (_) {
          verify(() => mockRepo.capturePayment('intent-1')).called(1);
        },
      );

      blocTest<BookingBloc, BookingState>(
        'mismatched intentId: ignored — does not capture an unrelated booking',
        build: () => BookingBloc(
          bookingRepository: mockRepo,
          connectivityService: connectivity,
        ),
        seed: () => PaymentSheetReady(
          clientSecret: 'secret',
          intentId: 'intent-current',
        ),
        act: (bloc) =>
            bloc.add(ConfirmPaymentFromDeepLink(intentId: 'intent-stale')),
        expect: () => <BookingState>[],
        verify: (_) {
          verifyNever(() => mockRepo.capturePayment(any()));
        },
      );
    });
  });
}
