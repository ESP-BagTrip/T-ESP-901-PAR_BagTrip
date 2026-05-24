import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_method_preview.freezed.dart';
part 'payment_method_preview.g.dart';

/// PCI-safe preview of a saved card. Mirrors the `payment_method` object
/// exposed by `GET /v1/subscription/me` — never carries the PAN itself,
/// only what's needed to render "Visa ···· 4242 expires 12/2030".
@freezed
abstract class PaymentMethodPreview with _$PaymentMethodPreview {
  const PaymentMethodPreview._();

  const factory PaymentMethodPreview({
    String? brand,
    String? last4,
    @JsonKey(name: 'exp_month') int? expMonth,
    @JsonKey(name: 'exp_year') int? expYear,
  }) = _PaymentMethodPreview;

  factory PaymentMethodPreview.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodPreviewFromJson(json);

  /// `12 / 2030`. Returns `null` when month/year are missing so the UI can
  /// fall back to a single-line layout instead of showing `null / null`.
  String? get formattedExpiry {
    if (expMonth == null || expYear == null) return null;
    final mm = expMonth!.toString().padLeft(2, '0');
    return '$mm / $expYear';
  }

  /// Capitalized brand for display ("visa" → "Visa").
  String get brandDisplay {
    final value = brand;
    if (value == null || value.isEmpty) return 'Card';
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }
}
