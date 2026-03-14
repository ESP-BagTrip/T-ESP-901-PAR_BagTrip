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
          expect(rb.route, 'Réservation');
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
  });
}
