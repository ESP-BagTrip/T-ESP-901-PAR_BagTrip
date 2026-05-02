/// Display copy for the Premium price.
///
/// Centralised so the paywall, the manage screen FREE body, and the
/// renewal summary on the manage screen PREMIUM body all read from a
/// single source. Hardcoding the same string in three different
/// widgets used to drift each time pricing was tweaked, and since
/// `/subscription/start` only returns the live amount once the user
/// taps "Try Premium", we still need a reliable display string for
/// every screen that lists the price *before* hitting Stripe.
///
/// When pricing actually changes, this is the only place to update.
class PremiumPricing {
  const PremiumPricing._();

  /// Display string passed to `l10n.premiumPriceLabel('{price}')`.
  static const String displayPrice = '9,99 €';
}
