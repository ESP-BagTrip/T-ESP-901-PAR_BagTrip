part of 'payment_bloc.dart';

sealed class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

final class PaymentInitial extends PaymentState {}

final class PaymentAuthorizing extends PaymentState {}

final class PaymentAuthorized extends PaymentState {
  final PaymentAuthorizeResponse paymentAuth;
  final String intentId;

  const PaymentAuthorized({required this.paymentAuth, required this.intentId});

  @override
  List<Object?> get props => [paymentAuth, intentId];
}

final class PaymentConfirming extends PaymentState {}

final class PaymentAuthorizedConfirmed extends PaymentState {
  final String intentId;

  const PaymentAuthorizedConfirmed({required this.intentId});

  @override
  List<Object?> get props => [intentId];
}

final class PaymentConfirmed extends PaymentState {
  final String intentId;

  const PaymentConfirmed({required this.intentId});

  @override
  List<Object?> get props => [intentId];
}

final class PaymentCapturing extends PaymentState {}

final class PaymentCaptured extends PaymentState {
  final PaymentCaptureResponse captureResponse;

  const PaymentCaptured({required this.captureResponse});

  @override
  List<Object?> get props => [captureResponse];
}

final class PaymentError extends PaymentState {
  final String message;

  const PaymentError(this.message);

  @override
  List<Object?> get props => [message];
}
