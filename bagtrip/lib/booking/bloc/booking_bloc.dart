import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/booking_response.dart';
import 'package:bagtrip/models/recent_booking.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/repositories/booking_repository.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';

part 'booking_event.dart';
part 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc({BookingRepository? bookingRepository})
    : _bookingRepository = bookingRepository ?? getIt<BookingRepository>(),
      super(BookingInitial()) {
    on<LoadBookings>(_onLoadBookings);
  }

  final BookingRepository _bookingRepository;

  Future<void> _onLoadBookings(
    LoadBookings event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    final result = await _bookingRepository.listBookings();
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(
          BookingLoaded(
            recentBookings: data.map(_mapBookingToRecentBooking).toList(),
          ),
        );
      case Failure(:final error):
        emit(BookingError(message: toUserFriendlyMessage(error)));
    }
  }

  RecentBooking _mapBookingToRecentBooking(BookingResponse b) {
    return RecentBooking(
      id: b.id,
      route: 'Réservation',
      details: b.status,
      date: DateFormat(
        'd MMM yyyy',
        'fr',
      ).format(b.createdAt ?? DateTime.now()),
      price:
          '${NumberFormat.decimalPattern('fr').format(b.priceTotal)} ${b.currency}',
      status: b.status,
    );
  }
}
