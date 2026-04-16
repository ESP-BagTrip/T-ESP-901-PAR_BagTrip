/// Lightweight price formatting helpers.
///
/// The app currently sprinkles `price.toStringAsFixed(0)` and `'$price€'`
/// across 20+ widgets. These extensions provide a single place to tweak
/// formatting (decimals, symbol placement) if we later decide to use
/// `NumberFormat.simpleCurrency` or respect the locale.
extension PriceFormatExt on num {
  /// "`123 €`" — whole-number price with the given [currency] symbol
  /// appended (defaults to €). Use this instead of
  /// `'${price.toStringAsFixed(0)} €'` sprinkled all over the UI.
  String formatPrice({String currency = '€'}) =>
      '${toStringAsFixed(0)} $currency';
}
