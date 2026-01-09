// ignore_for_file: depend_on_referenced_packages

import 'package:bagtrip/models/booking_intent.dart';
import 'package:bagtrip/service/booking_intent_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'booking_intent_event.dart';
part 'booking_intent_state.dart';

class BookingIntentBloc extends Bloc<BookingIntentEvent, BookingIntentState> {
  final BookingIntentService _bookingIntentService;

  BookingIntentBloc({BookingIntentService? bookingIntentService})
    : _bookingIntentService = bookingIntentService ?? BookingIntentService(),
      super(BookingIntentInitial()) {
    on<CreateBookingIntent>(_onCreateBookingIntent);
    on<GetBookingIntent>(_onGetBookingIntent);
    on<BookFlight>(_onBookFlight);
  }

  Future<void> _onCreateBookingIntent(
    CreateBookingIntent event,
    Emitter<BookingIntentState> emit,
  ) async {
    emit(BookingIntentLoading());

    try {
      final bookingIntent = await _bookingIntentService.createBookingIntent(
        event.tripId,
        type: event.type,
        flightOfferId: event.flightOfferId,
        hotelOfferId: event.hotelOfferId,
      );

      emit(BookingIntentCreated(bookingIntent: bookingIntent));
    } catch (e) {
      emit(BookingIntentError(e.toString()));
    }
  }

  Future<void> _onGetBookingIntent(
    GetBookingIntent event,
    Emitter<BookingIntentState> emit,
  ) async {
    emit(BookingIntentLoading());

    try {
      final bookingIntent = await _bookingIntentService.getBookingIntent(
        event.intentId,
      );

      emit(BookingIntentCreated(bookingIntent: bookingIntent));
    } catch (e) {
      emit(BookingIntentError(e.toString()));
    }
  }

  Future<void> _onBookFlight(
    BookFlight event,
    Emitter<BookingIntentState> emit,
  ) async {
    final currentState = state;
    if (currentState is! BookingIntentCreated) {
      emit(const BookingIntentError('No booking intent available'));
      return;
    }

    emit(BookingIntentLoading());

    try {
      await _bookingIntentService.bookFlight(
        event.intentId,
        travelerIds: event.travelerIds,
        contacts: event.contacts,
      );

      // Refresh booking intent to get updated status
      final updatedIntent = await _bookingIntentService.getBookingIntent(
        event.intentId,
      );

      emit(BookingIntentCreated(bookingIntent: updatedIntent));
    } catch (e) {
      emit(BookingIntentError(e.toString()));
    }
  }
}
