import 'package:bagtrip/booking/bloc/booking_bloc.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockBookingRepository mockRepo;

  setUpAll(() async {
    await initializeDateFormatting('fr');
  });

  setUp(() {
    mockRepo = MockBookingRepository();
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
          return BookingBloc(bookingRepository: mockRepo);
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
          return BookingBloc(bookingRepository: mockRepo);
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
          return BookingBloc(bookingRepository: mockRepo);
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
          return BookingBloc(bookingRepository: mockRepo);
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
          return BookingBloc(bookingRepository: mockRepo);
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
          return BookingBloc(bookingRepository: mockRepo);
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
          return BookingBloc(bookingRepository: mockRepo);
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
          return BookingBloc(bookingRepository: mockRepo);
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
          return BookingBloc(bookingRepository: mockRepo);
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
          return BookingBloc(bookingRepository: mockRepo);
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
          return BookingBloc(bookingRepository: mockRepo);
        },
        act: (bloc) => bloc.add(CapturePayment(intentId: 'intent-1')),
        expect: () => [isA<PaymentFailed>()],
      );
    });
  });
}
