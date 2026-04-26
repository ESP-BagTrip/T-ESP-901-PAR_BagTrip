import 'package:freezed_annotation/freezed_annotation.dart';

part 'invoice.freezed.dart';
part 'invoice.g.dart';

/// Stripe invoice — used by the "Billing history" screen.
///
/// Mirrors `GET /v1/subscription/invoices`. We don't store invoices locally;
/// they're always fetched live from Stripe so cancellations and refunds
/// reflect immediately.
@freezed
abstract class Invoice with _$Invoice {
  const Invoice._();

  const factory Invoice({
    required String id,
    String? number,
    String? status,
    @JsonKey(name: 'amount_paid') int? amountPaid,
    String? currency,
    DateTime? created,
    @JsonKey(name: 'hosted_invoice_url') String? hostedInvoiceUrl,
    @JsonKey(name: 'invoice_pdf') String? invoicePdf,
  }) = _Invoice;

  factory Invoice.fromJson(Map<String, dynamic> json) =>
      _$InvoiceFromJson(json);

  /// Amount as a decimal in the invoice currency (`999` cents → `9.99`).
  /// Returns `null` if the amount is unknown.
  double? get amountPaidMajor => amountPaid == null ? null : amountPaid! / 100;
}
