/// Typed baggage categories.
///
/// The wire format stays the backend string (`DOCUMENTS`, `CLOTHING`, ...) —
/// see [BaggageItem.category] and the create/update payloads — but every
/// display and picker path goes through this enum so the icon / color / label
/// have a single source of truth (see `BaggageCategoryPresentation` in
/// `category_mappers.dart`) and an unknown backend value can never crash the UI
/// ([fromApi] falls back to [BaggageCategory.other]).
enum BaggageCategory {
  documents('DOCUMENTS'),
  clothing('CLOTHING'),
  electronics('ELECTRONICS'),
  toiletries('TOILETRIES'),
  health('HEALTH'),
  accessories('ACCESSORIES'),
  other('OTHER');

  const BaggageCategory(this.apiValue);

  /// The exact string the backend expects/returns for this category.
  final String apiValue;

  /// Parse a backend value, falling back to [other] on null/unknown so a new
  /// server-side category never strands the client.
  static BaggageCategory fromApi(String? value) {
    if (value == null) return BaggageCategory.other;
    for (final c in BaggageCategory.values) {
      if (c.apiValue == value) return c;
    }
    return BaggageCategory.other;
  }
}
