import { http } from '../../config/http';
import { env } from '../../config/env';
import { logger } from '../../utils/logger';
import {
  NearbySearchRequest,
  NearbySearchResponse,
  TextSearchRequest,
  TextSearchResponse,
  PlaceDetailsRequest,
  PlaceDetailsResponse,
  FIELD_MASKS,
} from './google-places.types';

const GOOGLE_PLACES_BASE_URL = 'https://places.googleapis.com/v1';

/**
 * Nearby Search (New) - POST /v1/places:searchNearby
 * Find places within a specified area
 */
export async function searchNearbyPlaces(
  request: NearbySearchRequest,
  fieldMask: string = FIELD_MASKS.STANDARD
): Promise<NearbySearchResponse> {
  logger.debug('Starting Google Places nearby search', { request });

  if (!env.GOOGLE_PLACES_API_KEY) {
    throw new Error('GOOGLE_PLACES_API_KEY is not configured');
  }

  const url = `${GOOGLE_PLACES_BASE_URL}/places:searchNearby`;

  try {
    logger.info('Making Google Places nearby search request', { url, request });

    const res = await http.post(url, request, {
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': env.GOOGLE_PLACES_API_KEY,
        'X-Goog-FieldMask': fieldMask,
      },
      timeout: 10000,
    });

    logger.debug('Google Places nearby search response', {
      status: res.status,
      placesCount: res.data?.places?.length || 0,
    });

    const response: NearbySearchResponse = {
      places: res.data?.places || [],
    };

    logger.info('Google Places nearby search completed successfully', {
      placesCount: response.places.length,
    });

    return response;
  } catch (error: any) {
    logger.error('Google Places nearby search failed', {
      message: error.message,
      code: error.code,
      response: error.response?.data,
      status: error.response?.status,
    });

    const err: any = new Error('Google Places nearby search failed');
    err.detail = error.response?.data || error.message;
    err.status = error.response?.status || (error.code === 'ECONNABORTED' ? 504 : 502);
    throw err;
  }
}

/**
 * Text Search (New) - POST /v1/places:searchText
 * Search places using text query
 */
export async function searchPlacesByText(
  request: TextSearchRequest,
  fieldMask: string = FIELD_MASKS.STANDARD
): Promise<TextSearchResponse> {
  logger.debug('Starting Google Places text search', { request });

  if (!env.GOOGLE_PLACES_API_KEY) {
    throw new Error('GOOGLE_PLACES_API_KEY is not configured');
  }

  const url = `${GOOGLE_PLACES_BASE_URL}/places:searchText`;

  try {
    logger.info('Making Google Places text search request', { url, request });

    const res = await http.post(url, request, {
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': env.GOOGLE_PLACES_API_KEY,
        'X-Goog-FieldMask': fieldMask,
      },
      timeout: 10000,
    });

    logger.debug('Google Places text search response', {
      status: res.status,
      placesCount: res.data?.places?.length || 0,
    });

    const response: TextSearchResponse = {
      places: res.data?.places || [],
    };

    logger.info('Google Places text search completed successfully', {
      placesCount: response.places.length,
    });

    return response;
  } catch (error: any) {
    logger.error('Google Places text search failed', {
      message: error.message,
      code: error.code,
      response: error.response?.data,
      status: error.response?.status,
    });

    const err: any = new Error('Google Places text search failed');
    err.detail = error.response?.data || error.message;
    err.status = error.response?.status || (error.code === 'ECONNABORTED' ? 504 : 502);
    throw err;
  }
}

/**
 * Place Details (New) - GET /v1/places/{placeId}
 * Get detailed information about a specific place
 */
export async function getPlaceDetails(
  request: PlaceDetailsRequest,
  fieldMask: string = FIELD_MASKS.PLACE_DETAILS
): Promise<PlaceDetailsResponse> {
  logger.debug('Starting Google Places details request', { request });

  if (!env.GOOGLE_PLACES_API_KEY) {
    throw new Error('GOOGLE_PLACES_API_KEY is not configured');
  }

  const url = `${GOOGLE_PLACES_BASE_URL}/places/${request.placeId}`;
  const params: any = {};

  if (request.languageCode) params.languageCode = request.languageCode;
  if (request.regionCode) params.regionCode = request.regionCode;
  if (request.sessionToken) params.sessionToken = request.sessionToken;

  try {
    logger.info('Making Google Places details request', { url, placeId: request.placeId });

    const res = await http.get(url, {
      headers: {
        'X-Goog-Api-Key': env.GOOGLE_PLACES_API_KEY,
        'X-Goog-FieldMask': fieldMask,
      },
      params,
      timeout: 10000,
    });

    logger.debug('Google Places details response', {
      status: res.status,
    });

    const response: PlaceDetailsResponse = {
      place: res.data,
    };

    logger.info('Google Places details retrieved successfully');
    return response;
  } catch (error: any) {
    logger.error('Google Places details request failed', {
      message: error.message,
      code: error.code,
      response: error.response?.data,
      status: error.response?.status,
    });

    const err: any = new Error('Google Places details request failed');
    err.detail = error.response?.data || error.message;
    err.status = error.response?.status || (error.code === 'ECONNABORTED' ? 504 : 502);
    throw err;
  }
}
