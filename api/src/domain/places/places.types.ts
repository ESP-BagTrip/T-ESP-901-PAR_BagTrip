import { Place } from '../../integrations/google/google-places.types';

// ============================================================================
// PLACES DOMAIN TYPES
// ============================================================================

export type LocationSource =
  | 'hotel' // From Amadeus hotel booking
  | 'manual' // User provided coordinates
  | 'current'; // User's current position

export type NearbyPlacesParams = {
  latitude: number;
  longitude: number;
  radius?: number; // In meters, default 1000, max 50000
  types?: string[]; // Place types to search for
  maxResults?: number; // 1-20, default 10
  rankBy?: 'POPULARITY' | 'DISTANCE'; // default POPULARITY
  language?: string; // ISO 639-1 code (e.g., "en", "fr")
  source?: LocationSource; // Where the location came from
};

export type TextSearchParams = {
  query: string; // Search query (e.g., "restaurants near Eiffel Tower")
  latitude?: number; // Optional: bias results near this location
  longitude?: number;
  radius?: number; // Optional: search radius if lat/lng provided
  type?: string; // Optional: filter by single type
  maxResults?: number; // 1-20, default 10
  language?: string;
  minRating?: number; // 0-5
  openNow?: boolean;
};

export type PlaceDetailsParams = {
  placeId: string;
  language?: string;
};

export type PlacesSearchResult = {
  places: Place[];
  source?: LocationSource;
  searchCenter?: {
    latitude: number;
    longitude: number;
  };
  radius?: number;
  totalResults: number;
};

export type HotelLocationExtract = {
  hotelId: string;
  hotelName: string;
  latitude: number;
  longitude: number;
  address?: string;
};
