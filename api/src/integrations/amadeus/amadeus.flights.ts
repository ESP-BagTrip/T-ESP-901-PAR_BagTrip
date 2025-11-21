import { http } from '../../config/http';
import { env } from '../../config/env';
import { logger } from '../../utils/logger';
import { fetchToken } from './amadeus.auth';
import {
  FlightOfferSearchQuery,
  FlightOfferResponse,
  FlightInspirationSearchQuery,
  FlightDestinationResponse,
  FlightCheapestDateSearchQuery,
  FlightDateResponse,
} from './amadeus.types';

/**
 * Appel Shopping Flight Offers: GET /v2/shopping/flight-offers
 * Recherche d'offres de vols.
 */
export async function searchFlightOffers(q: FlightOfferSearchQuery): Promise<FlightOfferResponse> {
  logger.debug('Starting flight offers search', { query: q });
  const token = await fetchToken();

  const url = `${env.AMADEUS_BASE_URL}/v2/shopping/flight-offers`;
  const params: any = {
    originLocationCode: q.originLocationCode,
    destinationLocationCode: q.destinationLocationCode,
    departureDate: q.departureDate,
    adults: q.adults,
  };

  // Add optional parameters
  if (q.returnDate) params.returnDate = q.returnDate;
  if (q.children !== undefined) params.children = q.children;
  if (q.infants !== undefined) params.infants = q.infants;
  if (q.travelClass) params.travelClass = q.travelClass;
  if (q.nonStop !== undefined) params.nonStop = q.nonStop;
  if (q.currencyCode) params.currencyCode = q.currencyCode;
  if (q.maxPrice !== undefined) params.maxPrice = q.maxPrice;
  if (q.max !== undefined) params.max = q.max;
  if (q.includedAirlineCodes) params.includedAirlineCodes = q.includedAirlineCodes;
  if (q.excludedAirlineCodes) params.excludedAirlineCodes = q.excludedAirlineCodes;

  try {
    logger.info('Making Amadeus flight offers search request', { url, params });
    const res = await http.get(url, {
      headers: { Authorization: `Bearer ${token}` },
      params,
      timeout: 20000, // 20 seconds for complex flight offers queries
    });

    logger.debug('Amadeus flight offers search response', {
      status: res.status,
      statusText: res.statusText,
      dataCount: res.data?.data?.length || 0,
    });

    const response: FlightOfferResponse = {
      meta: res.data?.meta || {
        count: res.data?.data?.length || 0,
        links: {
          self: url,
        },
      },
      data: res.data?.data ?? [],
      dictionaries: res.data?.dictionaries,
    };

    logger.info('Flight offers search completed successfully', {
      offersCount: response.data.length,
    });
    return response;
  } catch (error: any) {
    logger.error('Amadeus flight offers search failed', {
      message: error.message,
      code: error.code,
      response: error.response?.data,
      status: error.response?.status,
    });
    const err: any = new Error('Amadeus flight offers search failed');
    err.detail = error.response?.data || error.message;
    err.status = error.response?.status || (error.code === 'ECONNABORTED' ? 504 : 502);
    throw err;
  }
}

/**
 * Appel Shopping Flight Destinations: GET /v1/shopping/flight-destinations
 * Recherche de destinations inspirantes à partir d'un aéroport d'origine.
 */
export async function searchFlightDestinations(
  q: FlightInspirationSearchQuery
): Promise<FlightDestinationResponse> {
  logger.debug('Starting flight destinations search', { query: q });
  const token = await fetchToken();

  const url = `${env.AMADEUS_BASE_URL}/v1/shopping/flight-destinations`;
  const params: any = {
    origin: q.origin,
  };

  // Add optional parameters
  if (q.departureDate) params.departureDate = q.departureDate;
  if (q.oneWay !== undefined) params.oneWay = q.oneWay;
  if (q.duration !== undefined) params.duration = q.duration;
  if (q.nonStop !== undefined) params.nonStop = q.nonStop;
  if (q.maxPrice !== undefined) params.maxPrice = q.maxPrice;
  if (q.viewBy) params.viewBy = q.viewBy;

  try {
    logger.info('Making Amadeus flight destinations search request', { url, params });
    const res = await http.get(url, {
      headers: { Authorization: `Bearer ${token}` },
      params,
      timeout: 15000, // 15 seconds timeout
    });

    logger.debug('Amadeus flight destinations search response', {
      status: res.status,
      statusText: res.statusText,
      dataCount: res.data?.data?.length || 0,
    });

    const response: FlightDestinationResponse = {
      meta: res.data?.meta || {
        currency: 'EUR',
        links: {
          self: url,
        },
      },
      data: res.data?.data ?? [],
    };

    logger.info('Flight destinations search completed successfully', {
      destinationsCount: response.data.length,
    });
    return response;
  } catch (error: any) {
    logger.error('Amadeus flight destinations search failed', {
      message: error.message,
      code: error.code,
      response: error.response?.data,
      status: error.response?.status,
    });
    const err: any = new Error('Amadeus flight destinations search failed');
    err.detail = error.response?.data || error.message;
    err.status = error.response?.status || (error.code === 'ECONNABORTED' ? 504 : 502);
    throw err;
  }
}

/**
 * Appel Shopping Flight Dates: GET /v1/shopping/flight-dates
 * Recherche des dates les moins chères pour un trajet.
 */
export async function searchFlightCheapestDates(
  q: FlightCheapestDateSearchQuery
): Promise<FlightDateResponse> {
  logger.debug('Starting flight cheapest dates search', { query: q });
  const token = await fetchToken();

  const url = `${env.AMADEUS_BASE_URL}/v1/shopping/flight-dates`;
  const params: any = {
    origin: q.origin,
    destination: q.destination,
  };

  // Add optional parameters
  if (q.departureDate) params.departureDate = q.departureDate;
  if (q.oneWay !== undefined) params.oneWay = q.oneWay;
  if (q.duration !== undefined) params.duration = q.duration;
  if (q.nonStop !== undefined) params.nonStop = q.nonStop;
  if (q.maxPrice !== undefined) params.maxPrice = q.maxPrice;
  if (q.viewBy) params.viewBy = q.viewBy;

  try {
    logger.info('Making Amadeus flight cheapest dates search request', { url, params });
    const res = await http.get(url, {
      headers: { Authorization: `Bearer ${token}` },
      params,
      timeout: 15000, // 15 seconds timeout
    });

    logger.debug('Amadeus flight cheapest dates search response', {
      status: res.status,
      statusText: res.statusText,
      dataCount: res.data?.data?.length || 0,
    });

    const response: FlightDateResponse = {
      meta: res.data?.meta || {
        currency: 'EUR',
        links: {
          self: url,
        },
      },
      data: res.data?.data ?? [],
    };

    logger.info('Flight cheapest dates search completed successfully', {
      datesCount: response.data.length,
    });
    return response;
  } catch (error: any) {
    logger.error('Amadeus flight cheapest dates search failed', {
      message: error.message,
      code: error.code,
      response: error.response?.data,
      status: error.response?.status,
    });
    const err: any = new Error('Amadeus flight cheapest dates search failed');
    err.detail = error.response?.data || error.message;
    err.status = error.response?.status || (error.code === 'ECONNABORTED' ? 504 : 502);
    throw err;
  }
}
