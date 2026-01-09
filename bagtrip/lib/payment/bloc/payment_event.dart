part of 'payment_bloc.dart';

sealed class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class AuthorizePayment extends PaymentEvent {
  final String intentId;
  final String? returnUrl;

  const AuthorizePayment({required this.intentId, this.returnUrl});

  @override
  List<Object?> get props => [intentId, returnUrl];
}

class ConfirmPayment extends PaymentEvent {
  final String intentId;

  const ConfirmPayment({required this.intentId});

  @override
  List<Object?> get props => [intentId];
}

class CapturePayment extends PaymentEvent {
  final String intentId;

  const CapturePayment({required this.intentId});

  @override
  List<Object?> get props => [intentId];
}

class PollPaymentStatus extends PaymentEvent {
  final String intentId;

  const PollPaymentStatus({required this.intentId});

  @override
  List<Object?> get props => [intentId];
}

class StopPolling extends PaymentEvent {
  const StopPolling();
}
