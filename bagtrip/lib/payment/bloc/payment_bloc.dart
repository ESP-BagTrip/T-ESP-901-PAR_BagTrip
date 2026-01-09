// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'package:bagtrip/models/booking_intent.dart';
import 'package:bagtrip/models/payment.dart';
import 'package:bagtrip/service/booking_intent_service.dart';
import 'package:bagtrip/service/payment_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentService _paymentService;
  final BookingIntentService _bookingIntentService;
  Timer? _pollingTimer;
  int _pollingAttempts = 0;
  static const int _maxPollingAttempts = 20;

  PaymentBloc({
    PaymentService? paymentService,
    BookingIntentService? bookingIntentService,
  }) : _paymentService = paymentService ?? PaymentService(),
       _bookingIntentService = bookingIntentService ?? BookingIntentService(),
       super(PaymentInitial()) {
    on<AuthorizePayment>(_onAuthorizePayment);
    on<ConfirmPayment>(_onConfirmPayment);
    on<CapturePayment>(_onCapturePayment);
    on<PollPaymentStatus>(_onPollPaymentStatus);
    on<StopPolling>(_onStopPolling);
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }

  Future<void> _onAuthorizePayment(
    AuthorizePayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentAuthorizing());

    try {
      final paymentAuth = await _paymentService.authorizePayment(
        event.intentId,
        returnUrl: event.returnUrl,
      );

      emit(
        PaymentAuthorized(paymentAuth: paymentAuth, intentId: event.intentId),
      );
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onConfirmPayment(
    ConfirmPayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentConfirming());

    try {
      await _paymentService.confirmPaymentTest(event.intentId);

      // Start polling for status update
      add(PollPaymentStatus(intentId: event.intentId));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onCapturePayment(
    CapturePayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentCapturing());

    try {
      final captureResponse = await _paymentService.capturePayment(
        event.intentId,
      );

      emit(PaymentCaptured(captureResponse: captureResponse));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onPollPaymentStatus(
    PollPaymentStatus event,
    Emitter<PaymentState> emit,
  ) async {
    _pollingTimer?.cancel();
    _pollingAttempts = 0;

    // Poll immediately
    await _pollStatus(event.intentId, emit);

    // Then poll every 2 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      // Check if emit is still valid before polling
      if (!emit.isDone) {
        await _pollStatus(event.intentId, emit);
      } else {
        // Emit is done, cancel the timer
        timer.cancel();
        _pollingTimer = null;
      }
    });
  }

  Future<void> _pollStatus(String intentId, Emitter<PaymentState> emit) async {
    // Check if emit is still valid before proceeding
    if (emit.isDone) {
      _pollingTimer?.cancel();
      _pollingTimer = null;
      return;
    }

    try {
      _pollingAttempts++;

      // Check for timeout
      if (_pollingAttempts >= _maxPollingAttempts) {
        _pollingTimer?.cancel();
        _pollingTimer = null;
        if (!emit.isDone) {
          emit(
            const PaymentError(
              "Timeout: Le statut n'a pas été mis à jour à temps",
            ),
          );
        }
        return;
      }

      final bookingIntent = await _bookingIntentService.getBookingIntent(
        intentId,
      );

      // Check again if emit is still valid after async operation
      if (emit.isDone) {
        _pollingTimer?.cancel();
        _pollingTimer = null;
        return;
      }

      // Wait for AUTHORIZED status first (this is the key fix)
      if (bookingIntent.status == BookingIntentStatus.authorized) {
        _pollingTimer?.cancel();
        _pollingTimer = null;
        _pollingAttempts = 0;
        if (!emit.isDone) {
          emit(PaymentAuthorizedConfirmed(intentId: intentId));
        }
        return;
      }

      // Note: We don't check for BOOKED here anymore - that happens after booking
      // The flow should be: INIT -> AUTHORIZED (polling stops here) -> BOOKED (after booking) -> CAPTURED
    } catch (e) {
      // Continue polling on error, but log it
      debugPrint('Error polling payment status: $e');
      // If we've exceeded max attempts, stop polling
      if (_pollingAttempts >= _maxPollingAttempts) {
        _pollingTimer?.cancel();
        _pollingTimer = null;
        if (!emit.isDone) {
          emit(PaymentError('Erreur lors du polling: $e'));
        }
      }
    }
  }

  Future<void> _onStopPolling(
    StopPolling event,
    Emitter<PaymentState> emit,
  ) async {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _pollingAttempts = 0;
  }
}
