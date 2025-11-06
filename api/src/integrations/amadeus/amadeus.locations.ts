import { http } from '../../config/http';
import { env } from '../../config/env';
import { logger } from '../../utils/logger';
import { fetchToken } from './amadeus.auth';
import {
  LocationKeywordSearchQuery,
  Location,
  LocationIdSearchQuery,
  LocationNearestSearchQuery,
} from './amadeus.types';

/**
 * Appel Reference Data Locations: GET /v1/reference-data/locations
 * Recherche de locations par mot-clé.
 */
export async function searchLocationsByKeyword(q: LocationKeywordSearchQuery): Promise<Location[]> {
  logger.debug('Starting location search by keyword', { query: q });
  const token = await fetchToken();

  const url = `${env.AMADEUS_BASE_URL}/v1/reference-data/locations`;
  const params: any = q;

  try {
    logger.info('Making Amadeus location search request', { url, params });
    const res = await http.get(url, {
      headers: { Authorization: `Bearer ${token}` },
      params,
    });

    logger.debug('Amadeus location search response', {
      status: res.status,
      statusText: res.statusText,
      dataCount: res.data?.data?.length || 0,
    });

    const locations = res.data?.data ?? [];

    logger.info('Location search completed successfully', { locationsCount: locations.length });
    return locations;
  } catch (error: any) {
    logger.error('Amadeus location search failed', error);
    const err: any = new Error('Amadeus location search failed');
    err.detail = error.response?.data || error.message;
    err.status = error.response?.status || 502;
    throw err;
  }
}

/**
 * Recherche une location par son ID.
 * Appel Reference Data Locations: GET /v1/reference-data/locations/{id}
 */
export async function searchLocationById(q: LocationIdSearchQuery): Promise<Location> {
  logger.debug('Starting location search by id', { query: q });
  const token = await fetchToken();

  const url = `${env.AMADEUS_BASE_URL}/v1/reference-data/locations/${q.id}`;
  try {
    logger.info('Making Amadeus location search request', { url });
    const res = await http.get(url, {
      headers: { Authorization: `Bearer ${token}` },
    });
    logger.debug('Amadeus location search response', {
      status: res.status,
      statusText: res.statusText,
      data: res.data,
    });
    const location = res.data?.data ?? null;
    logger.info('Location search completed successfully', { location });
    return location;
  } catch (error: any) {
    logger.error('Amadeus location search failed', error);
    const err: any = new Error('Amadeus location search failed');
    err.detail = error.response?.data || error.message;
    err.status = error.response?.status || 502;
    throw err;
  }
}

/**
 * Recherche les aéroports les plus proches d'une position géographique.
 * Appel Reference Data Locations: GET /v1/reference-data/locations/airports
 */
export async function searchLocationNearest(q: LocationNearestSearchQuery): Promise<Location[]> {
  logger.debug('Starting location nearest search', { query: q });
  const token = await fetchToken();

  const url = `${env.AMADEUS_BASE_URL}/v1/reference-data/locations/airports`;
  const params: any = q;

  try {
    logger.info('Making Amadeus location nearest search request', { url, params });
    const res = await http.get(url, {
      headers: { Authorization: `Bearer ${token}` },
      params,
    });

    logger.debug('Amadeus location nearest search response', {
      status: res.status,
      statusText: res.statusText,
      data: res.data,
    });

    const locations = res.data?.data ?? [];

    logger.info('Location nearest search completed successfully', {
      locationsCount: locations.length,
    });

    return locations;
  } catch (error: any) {
    logger.error('Amadeus location nearest search failed', error);
    const err: any = new Error('Amadeus location nearest search failed');
    err.detail = error.response?.data || error.message;
    err.status = error.response?.status || 502;
    throw err;
  }
}
