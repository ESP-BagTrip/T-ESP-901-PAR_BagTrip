import { http } from '../../config/http';
import { env } from '../../config/env';
import { makeBreaker } from '../../config/circuit';
import { logger } from '../../utils/logger';
import { LocationKeywordSearchQuery, Location, LocationIdSearchQuery } from './amadeus.types';

/**
 * Auth OAuth2 client_credentials avec cache mémoire simple.
 */
let tokenCache: { access_token: string; expires_at: number } | null = null;

async function fetchToken(): Promise<string> {
  const now = Date.now();
  if (tokenCache && tokenCache.expires_at > now + 5_000) {
    return tokenCache.access_token;
  }

  const url = `${env.AMADEUS_BASE_URL}/v1/security/oauth2/token`;
  const form = new URLSearchParams({
    grant_type: 'client_credentials',
    client_id: env.AMADEUS_CLIENT_ID,
    client_secret: env.AMADEUS_CLIENT_SECRET,
  });

  logger.debug('Amadeus token request', {
    url,
    baseUrl: env.AMADEUS_BASE_URL,
    clientId: env.AMADEUS_CLIENT_ID,
    clientSecretLength: env.AMADEUS_CLIENT_SECRET?.length,
    formData: form.toString(),
    timeout: env.REQUEST_TIMEOUT_MS,
  });

  let res: any;
  try {
    logger.info('Making Amadeus token request', { url });
    res = await http.post(url, form.toString(), {
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    });

    logger.debug('Amadeus token response', {
      status: res.status,
      statusText: res.statusText,
      data: res.data,
    });

    if (!res.data?.access_token) {
      logger.error('Amadeus token response missing access_token', {
        status: res.status,
        data: res.data,
      });
      const err: any = new Error('Amadeus token error');
      err.detail = res.data;
      err.status = res.status || 502;
      throw err;
    }

    logger.info('Amadeus token obtained successfully', {
      tokenType: res.data.token_type,
      expiresIn: res.data.expires_in,
    });
  } catch (error: any) {
    logger.error('Amadeus token request failed', {
      message: error.message,
      status: error.response?.status,
      statusText: error.response?.statusText,
      data: error.response?.data,
      url: error.config?.url,
      stack: error.stack,
    });
    const err: any = new Error('Amadeus token request failed');
    err.detail = error.response?.data || error.message;
    err.status = error.response?.status || 502;
    throw err;
  }

  const expires_in = Number(res.data.expires_in ?? 1799) * 1000; // fallback ~30m
  tokenCache = {
    access_token: res.data.access_token,
    expires_at: Date.now() + expires_in,
  };
  return tokenCache.access_token;
}

/**
 * Appel Reference Data Locations: GET /v1/reference-data/locations
 */
async function _searchLocationsByKeyword(q: LocationKeywordSearchQuery): Promise<Location[]> {
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

async function _searchLocationById(q: LocationIdSearchQuery): Promise<Location> {
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

// Circuit breakers
const locationBreaker = makeBreaker(_searchLocationsByKeyword);
const locationByIdBreaker = makeBreaker(_searchLocationById);

export const amadeusClient = {
  // Location by keyword
  searchLocationsByKeyword: (q: LocationKeywordSearchQuery) => locationBreaker.fire(q),
  resetLocationByKeywordBreaker: () => locationBreaker.close(),
  getLocationByKeywordBreakerStats: () => locationBreaker.stats,

  // Location by id
  searchLocationById: (q: LocationIdSearchQuery) => locationByIdBreaker.fire(q),
  resetLocationByIdBreaker: () => locationByIdBreaker.close(),
  getLocationByIdBreakerStats: () => locationByIdBreaker.stats,
};
