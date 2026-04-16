/// Formats a number as a price string. Defaults to EUR.
extension PriceFormatExt on num {
  String formatPrice({String currency = '€'}) =>
      '${toStringAsFixed(0)} $currency';
}
