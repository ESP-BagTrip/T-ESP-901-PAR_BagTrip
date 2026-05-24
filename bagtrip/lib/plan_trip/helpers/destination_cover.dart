/// Known-good landscape Unsplash URLs keyed by continent — mirrors the
/// backend fallback in `api/src/integrations/unsplash/client.py`. Kept in
/// sync manually since the list is tiny and rarely changes.
///
/// Used by the review step to show a destination-coherent cover when the
/// AI pipeline doesn't return an `image_url` (manual flow, Unsplash miss,
/// offline generation test fixtures).
const _continentFallbacks = <String, String>{
  'europe':
      'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=1080',
  'asia': 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=1080',
  'north_america':
      'https://images.unsplash.com/photo-1485738422979-f5c462d49f04?w=1080',
  'south_america':
      'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?w=1080',
  'africa':
      'https://images.unsplash.com/photo-1523805009345-7448845a9e53?w=1080',
  'oceania':
      'https://images.unsplash.com/photo-1523482580672-f109ba8cb9be?w=1080',
  'default':
      'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=1080',
};

const _continentKeywords = <String, List<String>>{
  'europe': [
    'paris',
    'london',
    'rome',
    'berlin',
    'madrid',
    'barcelona',
    'amsterdam',
    'vienna',
    'prague',
    'lisbon',
    'lisboa',
    'athens',
    'zurich',
    'brussels',
    'dublin',
    'stockholm',
    'oslo',
    'copenhagen',
    'helsinki',
    'warsaw',
    'budapest',
    'france',
    'spain',
    'italy',
    'germany',
    'portugal',
    'greece',
    'uk',
    'england',
    'switzerland',
    'netherlands',
    'belgium',
    'austria',
    'sweden',
    'norway',
    'denmark',
    'finland',
    'poland',
    'hungary',
    'czech',
  ],
  'asia': [
    'tokyo',
    'beijing',
    'shanghai',
    'bangkok',
    'singapore',
    'seoul',
    'mumbai',
    'delhi',
    'dubai',
    'istanbul',
    'hong kong',
    'taipei',
    'kuala lumpur',
    'hanoi',
    'bali',
    'jakarta',
    'japan',
    'china',
    'thailand',
    'india',
    'vietnam',
    'indonesia',
    'malaysia',
    'korea',
    'taiwan',
    'philippines',
    'uae',
    'turkey',
  ],
  'north_america': [
    'new york',
    'los angeles',
    'chicago',
    'miami',
    'san francisco',
    'toronto',
    'vancouver',
    'mexico city',
    'cancun',
    'montreal',
    'usa',
    'canada',
    'mexico',
    'united states',
  ],
  'south_america': [
    'rio',
    'buenos aires',
    'lima',
    'bogota',
    'santiago',
    'sao paulo',
    'brazil',
    'argentina',
    'colombia',
    'peru',
    'chile',
  ],
  'africa': [
    'cairo',
    'cape town',
    'marrakech',
    'nairobi',
    'lagos',
    'casablanca',
    'egypt',
    'morocco',
    'south africa',
    'kenya',
    'nigeria',
    'tunisia',
  ],
  'oceania': [
    'sydney',
    'melbourne',
    'auckland',
    'fiji',
    'bora bora',
    'australia',
    'new zealand',
  ],
};

/// Best-effort country/city → cover image URL. Returns the generic default
/// when no keyword matches. Never null — the caller can always render.
String destinationCoverUrl({required String city, required String country}) {
  final haystack = '$city $country'.toLowerCase();
  for (final entry in _continentKeywords.entries) {
    if (entry.value.any(haystack.contains)) {
      return _continentFallbacks[entry.key]!;
    }
  }
  return _continentFallbacks['default']!;
}
