import {
  searchNearbyPlaces,
  searchPlacesByText,
  getPlaceDetails as getPlaceDetailsFromGoogle,
} from '../../integrations/google/google-places.client';
import {
  FIELD_MASKS,
  PLACE_TYPES,
} from '../../integrations/google/google-places.types';
import {
  NearbyPlacesParams,
  TextSearchParams,
  PlaceDetailsParams,
  PlacesSearchResult,
  HotelLocationExtract,
} from './places.types';
import { AppError } from '../../utils/errors';

/**
 * Search for nearby places around a location
 */
export async function searchNearby(params: NearbyPlacesParams): Promise<PlacesSearchResult> {
  // Validate coordinates
  if (!params.latitude || !params.longitude) {
    throw new AppError('INVALID_QUERY', 400, 'latitude and longitude are required');
  }

  if (params.latitude < -90 || params.latitude > 90) {
    throw new AppError('INVALID_QUERY', 400, 'latitude must be between -90 and 90');
  }

  if (params.longitude < -180 || params.longitude > 180) {
    throw new AppError('INVALID_QUERY', 400, 'longitude must be between -180 and 180');
  }

  // Validate radius
  const radius = params.radius || 1000; // Default 1km
  if (radius <= 0 || radius > 50000) {
    throw new AppError('INVALID_QUERY', 400, 'radius must be between 0 and 50000 meters');
  }

  // Validate maxResults
  const maxResults = params.maxResults || 10;
  if (maxResults < 1 || maxResults > 20) {
    throw new AppError('INVALID_QUERY', 400, 'maxResults must be between 1 and 20');
  }

  const response = await searchNearbyPlaces({
    locationRestriction: {
      circle: {
        center: {
          latitude: params.latitude,
          longitude: params.longitude,
        },
        radius: radius,
      },
    },
    includedTypes: params.types,
    maxResultCount: maxResults,
    rankPreference: params.rankBy || 'POPULARITY',
    languageCode: params.language || 'en',
  });

  return {
    places: response.places,
    source: params.source,
    searchCenter: {
      latitude: params.latitude,
      longitude: params.longitude,
    },
    radius: radius,
    totalResults: response.places.length,
  };
}

/**
 * Search places by text query
 */
export async function searchByText(params: TextSearchParams): Promise<PlacesSearchResult> {
  if (!params.query || params.query.trim().length === 0) {
    throw new AppError('INVALID_QUERY', 400, 'query is required');
  }

  const maxResults = params.maxResults || 10;
  if (maxResults < 1 || maxResults > 20) {
    throw new AppError('INVALID_QUERY', 400, 'maxResults must be between 1 and 20');
  }

  const request: any = {
    textQuery: params.query,
    maxResultCount: maxResults,
    languageCode: params.language || 'en',
  };

  // Add location bias if coordinates provided
  if (params.latitude !== undefined && params.longitude !== undefined) {
    const radius = params.radius || 5000; // Default 5km for text search
    request.locationBias = {
      circle: {
        center: {
          latitude: params.latitude,
          longitude: params.longitude,
        },
        radius: radius,
      },
    };
  }

  if (params.type) {
    request.includedType = params.type;
  }

  if (params.minRating !== undefined) {
    request.minRating = params.minRating;
  }

  if (params.openNow !== undefined) {
    request.openNow = params.openNow;
  }

  const response = await searchPlacesByText(request);

  return {
    places: response.places,
    searchCenter:
      params.latitude && params.longitude
        ? { latitude: params.latitude, longitude: params.longitude }
        : undefined,
    radius: params.radius,
    totalResults: response.places.length,
  };
}

/**
 * Get detailed information about a specific place
 */
export async function getPlaceDetails(params: PlaceDetailsParams) {
  if (!params.placeId || params.placeId.trim().length === 0) {
    throw new AppError('INVALID_QUERY', 400, 'placeId is required');
  }

  const response = await getPlaceDetailsFromGoogle({
    placeId: params.placeId,
    languageCode: params.language || 'en',
  });

  return response.place;
}

/**
 * Extract location from Amadeus hotel data
 * This can be used to get coordinates from hotel bookings
 */
export function extractHotelLocation(hotelData: any): HotelLocationExtract | null {
  if (!hotelData) {
    return null;
  }

  // Extract from hotel data (Amadeus format)
  const geoCode = hotelData.geoCode || hotelData.hotel?.geoCode;
  const hotelId = hotelData.hotelId || hotelData.hotel?.hotelId;
  const name = hotelData.name || hotelData.hotel?.name;
  const address = hotelData.formattedAddress || hotelData.hotel?.address?.lines?.join(', ');

  if (!geoCode || !geoCode.latitude || !geoCode.longitude) {
    return null;
  }

  return {
    hotelId: hotelId || 'unknown',
    hotelName: name || 'Unknown Hotel',
    latitude: geoCode.latitude,
    longitude: geoCode.longitude,
    address: address,
  };
}

/**
 * Get recommended places near a hotel
 * Convenience method that combines hotel location extraction and nearby search
 */
export async function getRecommendationsNearHotel(
  hotelData: any,
  types?: string[],
  radius?: number
): Promise<PlacesSearchResult> {
  const location = extractHotelLocation(hotelData);

  if (!location) {
    throw new AppError('INVALID_QUERY', 400, 'Unable to extract location from hotel data');
  }

  return searchNearby({
    latitude: location.latitude,
    longitude: location.longitude,
    radius: radius || 2000, // Default 2km around hotel
    types: types || [
      PLACE_TYPES.RESTAURANT,
      PLACE_TYPES.CAFE,
      PLACE_TYPES.TOURIST_ATTRACTION,
      PLACE_TYPES.MUSEUM,
      PLACE_TYPES.PARK,
    ],
    maxResults: 20,
    source: 'hotel',
  });
}
