// ============================================================================
// GOOGLE PLACES API (NEW) TYPES
// Documentation: https://developers.google.com/maps/documentation/places/web-service
// ============================================================================

// ============================================================================
// COMMON TYPES
// ============================================================================

export type LatLng = {
  latitude: number;
  longitude: number;
};

export type Circle = {
  center: LatLng;
  radius: number; // In meters, max 50000
};

export type LocationRestriction = {
  circle: Circle;
};

export type DisplayName = {
  text: string;
  languageCode: string;
};

export type AddressComponent = {
  longText: string;
  shortText: string;
  types: string[];
  languageCode: string;
};

export type Photo = {
  name: string;
  widthPx: number;
  heightPx: number;
  authorAttributions: Array<{
    displayName: string;
    uri: string;
    photoUri: string;
  }>;
};

// ============================================================================
// NEARBY SEARCH TYPES
// ============================================================================

export type NearbySearchRequest = {
  locationRestriction: LocationRestriction; // REQUIRED
  includedTypes?: string[]; // e.g., ["restaurant", "cafe"]
  excludedTypes?: string[];
  includedPrimaryTypes?: string[];
  excludedPrimaryTypes?: string[];
  maxResultCount?: number; // 1-20, default 20
  rankPreference?: 'POPULARITY' | 'DISTANCE'; // default POPULARITY
  languageCode?: string; // e.g., "en", "fr"
  regionCode?: string; // Two-letter CLDR code (e.g., "US", "FR")
};

export type Place = {
  id: string;
  name: string; // Resource name (e.g., "places/ChIJj61dQgK6j4AR4GeTYWZsKWw")
  displayName?: DisplayName;
  types?: string[];
  primaryType?: string;
  primaryTypeDisplayName?: DisplayName;
  formattedAddress?: string;
  shortFormattedAddress?: string;
  addressComponents?: AddressComponent[];
  location?: LatLng;
  rating?: number; // 1.0-5.0
  googleMapsUri?: string;
  websiteUri?: string;
  regularOpeningHours?: {
    openNow?: boolean;
    periods?: Array<{
      open: { day: number; hour: number; minute: number };
      close?: { day: number; hour: number; minute: number };
    }>;
    weekdayDescriptions?: string[];
  };
  businessStatus?: 'OPERATIONAL' | 'CLOSED_TEMPORARILY' | 'CLOSED_PERMANENTLY';
  priceLevel?: 'PRICE_LEVEL_FREE' | 'PRICE_LEVEL_INEXPENSIVE' | 'PRICE_LEVEL_MODERATE' | 'PRICE_LEVEL_EXPENSIVE' | 'PRICE_LEVEL_VERY_EXPENSIVE';
  userRatingCount?: number;
  iconMaskBaseUri?: string;
  iconBackgroundColor?: string;
  photos?: Photo[];
  nationalPhoneNumber?: string;
  internationalPhoneNumber?: string;
  editorialSummary?: DisplayName;
};

export type NearbySearchResponse = {
  places: Place[];
};

// ============================================================================
// TEXT SEARCH TYPES
// ============================================================================

export type TextSearchRequest = {
  textQuery: string; // REQUIRED - The text query (e.g., "restaurants in Paris")
  locationBias?: LocationRestriction; // Prefer results in this area
  includedType?: string; // Single type filter
  languageCode?: string;
  regionCode?: string;
  maxResultCount?: number; // 1-20
  rankPreference?: 'RELEVANCE' | 'DISTANCE'; // default RELEVANCE
  priceLevels?: Array<'PRICE_LEVEL_FREE' | 'PRICE_LEVEL_INEXPENSIVE' | 'PRICE_LEVEL_MODERATE' | 'PRICE_LEVEL_EXPENSIVE' | 'PRICE_LEVEL_VERY_EXPENSIVE'>;
  minRating?: number; // 0.0-5.0
  openNow?: boolean;
};

export type TextSearchResponse = {
  places: Place[];
};

// ============================================================================
// PLACE DETAILS TYPES
// ============================================================================

export type PlaceDetailsRequest = {
  placeId: string; // REQUIRED - The place ID
  languageCode?: string;
  regionCode?: string;
  sessionToken?: string;
};

export type PlaceDetailsResponse = {
  place: Place;
};

// ============================================================================
// FIELD MASK PRESETS
// Basic, Standard, and Advanced field sets
// ============================================================================

export const FIELD_MASKS = {
  // Basic fields (always available)
  BASIC: [
    'places.id',
    'places.name',
    'places.displayName',
    'places.types',
    'places.primaryType',
    'places.location',
    'places.formattedAddress',
  ].join(','),

  // Standard fields (Nearby Search Pro)
  STANDARD: [
    'places.id',
    'places.name',
    'places.displayName',
    'places.types',
    'places.primaryType',
    'places.location',
    'places.formattedAddress',
    'places.shortFormattedAddress',
    'places.addressComponents',
    'places.photos',
    'places.googleMapsUri',
    'places.businessStatus',
  ].join(','),

  // Advanced fields (Enterprise SKU)
  ADVANCED: [
    'places.id',
    'places.name',
    'places.displayName',
    'places.types',
    'places.primaryType',
    'places.location',
    'places.formattedAddress',
    'places.shortFormattedAddress',
    'places.addressComponents',
    'places.photos',
    'places.googleMapsUri',
    'places.businessStatus',
    'places.rating',
    'places.userRatingCount',
    'places.priceLevel',
    'places.websiteUri',
    'places.nationalPhoneNumber',
    'places.internationalPhoneNumber',
    'places.regularOpeningHours',
    'places.editorialSummary',
  ].join(','),

  // Place Details field mask (without "places." prefix)
  PLACE_DETAILS: [
    'id',
    'name',
    'displayName',
    'types',
    'primaryType',
    'location',
    'formattedAddress',
    'shortFormattedAddress',
    'addressComponents',
    'photos',
    'googleMapsUri',
    'businessStatus',
    'rating',
    'userRatingCount',
    'priceLevel',
    'websiteUri',
    'nationalPhoneNumber',
    'internationalPhoneNumber',
    'regularOpeningHours',
    'editorialSummary',
  ].join(','),
} as const;

// ============================================================================
// PLACE TYPES - Most common categories
// Full list: https://developers.google.com/maps/documentation/places/web-service/place-types
// ============================================================================

export const PLACE_TYPES = {
  // Food & Drink
  RESTAURANT: 'restaurant',
  CAFE: 'cafe',
  BAR: 'bar',
  BAKERY: 'bakery',
  FAST_FOOD: 'fast_food_restaurant',

  // Shopping
  STORE: 'store',
  SHOPPING_MALL: 'shopping_mall',
  SUPERMARKET: 'supermarket',
  CONVENIENCE_STORE: 'convenience_store',

  // Entertainment
  MUSEUM: 'museum',
  ART_GALLERY: 'art_gallery',
  TOURIST_ATTRACTION: 'tourist_attraction',
  PARK: 'park',
  ZOO: 'zoo',
  AMUSEMENT_PARK: 'amusement_park',
  MOVIE_THEATER: 'movie_theater',
  NIGHT_CLUB: 'night_club',

  // Services
  BANK: 'bank',
  ATM: 'atm',
  PHARMACY: 'pharmacy',
  HOSPITAL: 'hospital',
  GAS_STATION: 'gas_station',
  PARKING: 'parking',

  // Accommodation
  HOTEL: 'hotel',
  LODGING: 'lodging',

  // Transport
  AIRPORT: 'airport',
  TRAIN_STATION: 'train_station',
  BUS_STATION: 'bus_station',
  SUBWAY_STATION: 'subway_station',
  TAXI_STAND: 'taxi_stand',

  // Other
  GYM: 'gym',
  SPA: 'spa',
  CHURCH: 'church',
  MOSQUE: 'mosque',
  SYNAGOGUE: 'synagogue',
  SCHOOL: 'school',
  LIBRARY: 'library',
  POST_OFFICE: 'post_office',
} as const;
