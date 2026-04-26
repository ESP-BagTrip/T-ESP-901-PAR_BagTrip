import 'package:bagtrip/auth/bloc/auth_bloc.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/booking_response.dart';
import 'package:bagtrip/models/recent_booking.dart';
import 'package:bagtrip/repositories/booking_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

part 'booking_event.dart';
part 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc({
    BookingRepository? bookingRepository,
    AuthBloc? authBloc,
    ConnectivityService? connectivityService,
  }) : _bookingRepository = bookingRepository ?? getIt<BookingRepository>(),
       _authBloc = authBloc,
       _connectivityService =
           connectivityService ?? getIt<ConnectivityService>(),
       super(BookingInitial()) {
    on<LoadBookings>(_onLoadBookings);
    on<CreateBookingIntent>(_onCreateBookingIntent);
    on<AuthorizePayment>(_onAuthorizePayment);
    on<PresentPaymentSheet>(_onPresentPaymentSheet);
    on<CapturePayment>(_onCapturePayment);
    on<RefundPayment>(_onRefundPayment);
    on<ConfirmPaymentFromDeepLink>(_onConfirmFromDeepLink);
  }

  final BookingRepository _bookingRepository;
  // Optional: when present, payment success refreshes the user so any
  // server-side plan change (e.g. unlocked feature) lands in `User.plan`
  // without waiting for the next login.
  final AuthBloc? _authBloc;
  // Synchronous online/offline check — used to short-circuit payment
  // events before they hit Dio with a confusing connection_error.
  final ConnectivityService _connectivityService;

  /// Build a [PaymentFailed] state when offline. We keep the sentinel as a
  /// [NetworkError] (rather than a new error class) so existing UI that
  /// already maps NetworkError → "no connection" copy keeps working.
  PaymentFailed _offlineFailure() =>
      PaymentFailed(error: const NetworkError('connection_required'));

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

  Future<void> _onCreateBookingIntent(
    CreateBookingIntent event,
    Emitter<BookingState> emit,
  ) async {
    if (!_connectivityService.isOnline) {
      emit(_offlineFailure());
      return;
    }
    emit(PaymentAuthorizing());
    final result = await _bookingRepository.createBookingIntent(
      tripId: event.tripId,
      flightOfferId: event.flightOfferId,
    );
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        add(AuthorizePayment(intentId: data));
      case Failure(:final error):
        emit(PaymentFailed(error: error));
    }
  }

  Future<void> _onAuthorizePayment(
    AuthorizePayment event,
    Emitter<BookingState> emit,
  ) async {
    if (!_connectivityService.isOnline) {
      emit(_offlineFailure());
      return;
    }
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
          // Including `?intentId=…` so the deep-link handler can match the
          // returning 3DS flow back to the booking that started it.
          returnURL: 'bagtrip://payment/result?intentId=${event.intentId}',
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
    if (!_connectivityService.isOnline) {
      emit(_offlineFailure());
      return;
    }
    final result = await _bookingRepository.capturePayment(event.intentId);
    if (isClosed) return;
    switch (result) {
      case Success():
        emit(PaymentSuccess(intentId: event.intentId));
        // Refresh the user so any plan changes (e.g. quotas reset on a paid
        // booking) reflect in the gated UI without a manual reload.
        _authBloc?.add(UserRefreshRequested());
      case Failure(:final error):
        emit(PaymentFailed(error: error));
    }
  }

  Future<void> _onConfirmFromDeepLink(
    ConfirmPaymentFromDeepLink event,
    Emitter<BookingState> emit,
  ) async {
    // Validate the deep link's intentId against the in-flight payment. If
    // the user opens a stale URL or hits the route from outside a flow,
    // we don't blindly capture an unrelated booking.
    final current = state;
    final inFlightId = switch (current) {
      PaymentSheetReady(:final intentId) => intentId,
      PaymentAuthorizing() => null,
      _ => null,
    };
    if (inFlightId != null && inFlightId != event.intentId) {
      // Mismatch — leave the bloc as-is. The page will show the neutral
      // "payment processed" state.
      return;
    }
    add(CapturePayment(intentId: event.intentId));
  }

  Future<void> _onRefundPayment(
    RefundPayment event,
    Emitter<BookingState> emit,
  ) async {
    if (!_connectivityService.isOnline) {
      emit(_offlineFailure());
      return;
    }
    emit(RefundInProgress(intentId: event.intentId));
    final result = await _bookingRepository.refundPayment(
      event.intentId,
      amount: event.amount,
      reason: event.reason,
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        emit(RefundSucceeded(intentId: event.intentId));
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
