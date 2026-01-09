class PaymentAuthorizeResponse {
  final String stripePaymentIntentId;
  final String clientSecret;
  final String status;

  PaymentAuthorizeResponse({
    required this.stripePaymentIntentId,
    required this.clientSecret,
    required this.status,
  });

  factory PaymentAuthorizeResponse.fromJson(Map<String, dynamic> json) {
    return PaymentAuthorizeResponse(
      stripePaymentIntentId: json['stripePaymentIntentId'] as String,
      clientSecret: json['clientSecret'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stripePaymentIntentId': stripePaymentIntentId,
      'clientSecret': clientSecret,
      'status': status,
    };
  }
}

class PaymentCaptureResponse {
  final Map<String, dynamic> bookingIntent;
  final Map<String, dynamic> stripe;

  PaymentCaptureResponse({required this.bookingIntent, required this.stripe});

  factory PaymentCaptureResponse.fromJson(Map<String, dynamic> json) {
    return PaymentCaptureResponse(
      bookingIntent: json['bookingIntent'] as Map<String, dynamic>,
      stripe: json['stripe'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {'bookingIntent': bookingIntent, 'stripe': stripe};
  }
}
