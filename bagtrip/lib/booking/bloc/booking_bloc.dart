import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/booking_response.dart';
import 'package:bagtrip/models/recent_booking.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/repositories/booking_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

part 'booking_event.dart';
part 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc({BookingRepository? bookingRepository})
    : _bookingRepository = bookingRepository ?? getIt<BookingRepository>(),
      super(BookingInitial()) {
    on<LoadBookings>(_onLoadBookings);
    on<AuthorizePayment>(_onAuthorizePayment);
    on<PresentPaymentSheet>(_onPresentPaymentSheet);
    on<CapturePayment>(_onCapturePayment);
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
        emit(BookingError(error: error));
    }
  }

  Future<void> _onAuthorizePayment(
    AuthorizePayment event,
    Emitter<BookingState> emit,
  ) async {
    emit(PaymentAuthorizing());
    final result = await _bookingRepository.authorizePayment(event.intentId);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(
          PaymentSheetReady(
            clientSecret: data.clientSecret,
            intentId: event.intentId,
          ),
        );
      case Failure(:final error):
        emit(PaymentFailed(error: error));
    }
  }

  Future<void> _onPresentPaymentSheet(
    PresentPaymentSheet event,
    Emitter<BookingState> emit,
  ) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: event.clientSecret,
          merchantDisplayName: 'BagTrip',
          returnURL: 'bagtrip://payment/result',
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      if (isClosed) return;
      add(CapturePayment(intentId: event.intentId));
    } on StripeException catch (e) {
      if (isClosed) return;
      if (e.error.code == FailureCode.Canceled) {
        emit(PaymentCancelled());
      } else {
        emit(
          PaymentFailed(
            error: UnknownError(e.error.localizedMessage ?? 'Payment failed'),
          ),
        );
      }
    } catch (e) {
      if (isClosed) return;
      emit(PaymentFailed(error: UnknownError(e.toString(), originalError: e)));
    }
  }

  Future<void> _onCapturePayment(
    CapturePayment event,
    Emitter<BookingState> emit,
  ) async {
    final result = await _bookingRepository.capturePayment(event.intentId);
    if (isClosed) return;
    switch (result) {
      case Success():
        emit(PaymentSuccess(intentId: event.intentId));
      case Failure(:final error):
        emit(PaymentFailed(error: error));
    }
  }

  RecentBooking _mapBookingToRecentBooking(BookingResponse b) {
    return RecentBooking(
      id: b.id,
      details: b.status,
      date: b.createdAt ?? DateTime.now(),
      priceTotal: b.priceTotal,
      currency: b.currency,
      status: b.status,
    );
  }
}
