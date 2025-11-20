import { http } from '../../config/http';
import { env } from '../../config/env';
import { logger } from '../../utils/logger';
import { fetchToken } from './amadeus.auth';
import {
  HotelListSearchQuery,
  HotelListResponse,
  HotelSearchQuery,
  HotelSearchResponse,
  HotelOfferDetailsQuery,
  HotelOfferDetailsResponse,
} from './amadeus.types';

/**
 * Hotel List: GET /v1/reference-data/locations/hotels/by-city
 * Retrieves a list of hotels in a specific city.
 */
export async function searchHotelsByCity(q: HotelListSearchQuery): Promise<HotelListResponse> {
  logger.debug('Starting hotel list search by city', { query: q });
  const token = await fetchToken();

  const url = `${env.AMADEUS_BASE_URL}/v1/reference-data/locations/hotels/by-city`;
  const params: any = {
    cityCode: q.cityCode,
  };

  // Add optional parameters
  if (q.radius !== undefined) params.radius = q.radius;
  if (q.radiusUnit) params.radiusUnit = q.radiusUnit;
  if (q.chainCodes) params.chainCodes = q.chainCodes;
  if (q.amenities) params.amenities = q.amenities;
  if (q.ratings) params.ratings = q.ratings;
  if (q.hotelSource) params.hotelSource = q.hotelSource;

  try {
    logger.info('Making Amadeus hotel list search request', { url, params });
    const res = await http.get(url, {
      headers: { Authorization: `Bearer ${token}` },
      params,
      timeout: 15000,
    });

    logger.debug('Amadeus hotel list search response', {
      status: res.status,
      statusText: res.statusText,
      dataCount: res.data?.data?.length || 0,
    });

    const response: HotelListResponse = {
      data: res.data?.data ?? [],
      meta: res.data?.meta,
    };

    logger.info('Hotel list search completed successfully', {
      hotelsCount: response.data.length,
    });
    return response;
  } catch (error: any) {
    logger.error('Amadeus hotel list search failed', {
      message: error.message,
      code: error.code,
      response: error.response?.data,
      status: error.response?.status,
    });
    const err: any = new Error('Amadeus hotel list search failed');
    err.detail = error.response?.data || error.message;
    err.status = error.response?.status || (error.code === 'ECONNABORTED' ? 504 : 502);
    throw err;
  }
}

/**
 * Hotel Search: GET /v3/shopping/hotel-offers
 * Searches for hotel offers with real-time pricing.
 */
export async function searchHotelOffers(q: HotelSearchQuery): Promise<HotelSearchResponse> {
  logger.debug('Starting hotel offers search', { query: q });
  const token = await fetchToken();

  const url = `${env.AMADEUS_BASE_URL}/v3/shopping/hotel-offers`;
  const params: any = {
    hotelIds: q.hotelIds,
    adults: q.adults,
  };

  // Add optional parameters
  if (q.checkInDate) params.checkInDate = q.checkInDate;
  if (q.checkOutDate) params.checkOutDate = q.checkOutDate;
  if (q.roomQuantity !== undefined) params.roomQuantity = q.roomQuantity;
  if (q.priceRange) params.priceRange = q.priceRange;
  if (q.currency) params.currency = q.currency;
  if (q.paymentPolicy) params.paymentPolicy = q.paymentPolicy;
  if (q.boardType) params.boardType = q.boardType;
  if (q.includeClosed !== undefined) params.includeClosed = q.includeClosed;
  if (q.bestRateOnly !== undefined) params.bestRateOnly = q.bestRateOnly;

  try {
    logger.info('Making Amadeus hotel offers search request', { url, params });
    const res = await http.get(url, {
      headers: { Authorization: `Bearer ${token}` },
      params,
      timeout: 20000,
    });

    logger.debug('Amadeus hotel offers search response', {
      status: res.status,
      statusText: res.statusText,
      dataCount: res.data?.data?.length || 0,
    });

    const response: HotelSearchResponse = {
      data: res.data?.data ?? [],
      meta: res.data?.meta,
    };

    logger.info('Hotel offers search completed successfully', {
      offersCount: response.data.length,
    });
    return response;
  } catch (error: any) {
    logger.error('Amadeus hotel offers search failed', {
      message: error.message,
      code: error.code,
      response: error.response?.data,
      status: error.response?.status,
    });
    const err: any = new Error('Amadeus hotel offers search failed');
    err.detail = error.response?.data || error.message;
    err.status = error.response?.status || (error.code === 'ECONNABORTED' ? 504 : 502);
    throw err;
  }
}

/**
 * Hotel Offer Details: GET /v3/shopping/hotel-offers/{offerId}
 * Retrieves details for a specific hotel offer.
 */
export async function getHotelOfferDetails(
  q: HotelOfferDetailsQuery
): Promise<HotelOfferDetailsResponse> {
  logger.debug('Starting hotel offer details request', { query: q });
  const token = await fetchToken();

  const url = `${env.AMADEUS_BASE_URL}/v3/shopping/hotel-offers/${q.offerId}`;

  try {
    logger.info('Making Amadeus hotel offer details request', { url });
    const res = await http.get(url, {
      headers: { Authorization: `Bearer ${token}` },
      timeout: 10000,
    });

    logger.debug('Amadeus hotel offer details response', {
      status: res.status,
      statusText: res.statusText,
    });

    const response: HotelOfferDetailsResponse = {
      data: res.data?.data,
      meta: res.data?.meta,
    };

    logger.info('Hotel offer details retrieved successfully');
    return response;
  } catch (error: any) {
    logger.error('Amadeus hotel offer details request failed', {
      message: error.message,
      code: error.code,
      response: error.response?.data,
      status: error.response?.status,
    });
    const err: any = new Error('Amadeus hotel offer details request failed');
    err.detail = error.response?.data || error.message;
    err.status = error.response?.status || (error.code === 'ECONNABORTED' ? 504 : 502);
    throw err;
  }
}
