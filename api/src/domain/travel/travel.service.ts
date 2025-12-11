import { amadeusClient } from '../../integrations/amadeus/amadeus.client';
import {
  LocationIdSearchParams,
  LocationKeywordSearchParams,
  LocationSearchResult,
  LocationNearestSearchParams,
  FlightOfferSearchParams,
  FlightOfferSearchResult,
  FlightDestinationSearchParams,
  FlightDestinationSearchResult,
  FlightCheapestDateSearchParams,
  FlightCheapestDateSearchResult,
} from './travel.types';
import { AppError } from '../../utils/errors';
import {
  Location,
  FlightOfferResponse,
  FlightDestinationResponse,
  FlightDateResponse,
} from '../../integrations/amadeus/amadeus.types';

export async function searchLocationsByKeyword(
  params: LocationKeywordSearchParams
): Promise<LocationSearchResult> {
  if (!params.subType || !params.keyword) {
    throw new AppError('INVALID_QUERY', 400, 'subType and keyword are required');
  }

  const locations = (await amadeusClient.searchLocationsByKeyword({
    subType: params.subType,
    keyword: params.keyword,
  })) as Location[];

  return { locations, count: locations.length };
}

export async function searchLocationById(params: LocationIdSearchParams): Promise<Location> {
  if (!params.id) {
    throw new AppError('INVALID_QUERY', 400, 'id is required');
  }

  const location = (await amadeusClient.searchLocationById({ id: params.id })) as Location;
  return location;
}

export async function searchLocationNearest(
  params: LocationNearestSearchParams
): Promise<LocationSearchResult> {
  if (!params.latitude || !params.longitude) {
    throw new AppError('INVALID_QUERY', 400, 'latitude and longitude are required');
  }

  const locations = (await amadeusClient.searchLocationNearest({
    latitude: params.latitude,
    longitude: params.longitude,
  })) as Location[];

  return { locations, count: locations.length };
}

// ============================================================================
// FLIGHT SERVICES
// ============================================================================

export async function searchFlightOffers(
  params: FlightOfferSearchParams
): Promise<FlightOfferSearchResult> {
  if (!params.originLocationCode || !params.destinationLocationCode || !params.departureDate) {
    throw new AppError(
      'INVALID_QUERY',
      400,
      'originLocationCode, destinationLocationCode, and departureDate are required'
    );
  }

  if (!params.adults || params.adults < 1 || params.adults > 9) {
    throw new AppError('INVALID_QUERY', 400, 'adults must be between 1 and 9');
  }

  if (params.children !== undefined && (params.children < 0 || params.children > 9)) {
    throw new AppError('INVALID_QUERY', 400, 'children must be between 0 and 9');
  }

  if (params.infants !== undefined && (params.infants < 0 || params.infants > 9)) {
    throw new AppError('INVALID_QUERY', 400, 'infants must be between 0 and 9');
  }

  if (params.infants !== undefined && params.infants > params.adults) {
    throw new AppError('INVALID_QUERY', 400, 'infants cannot exceed the number of adults');
  }

  if (params.maxPrice !== undefined && params.maxPrice <= 0) {
    throw new AppError('INVALID_QUERY', 400, 'maxPrice must be a positive integer');
  }

  if (params.max !== undefined && (params.max < 1 || params.max > 250)) {
    throw new AppError('INVALID_QUERY', 400, 'max must be between 1 and 250');
  }

  const result = (await amadeusClient.searchFlightOffers(params)) as FlightOfferResponse;
  return result;
}

export async function searchFlightDestinations(
  params: FlightDestinationSearchParams
): Promise<FlightDestinationSearchResult> {
  if (!params.origin) {
    throw new AppError('INVALID_QUERY', 400, 'origin is required');
  }

  if (params.duration !== undefined && params.duration <= 0) {
    throw new AppError('INVALID_QUERY', 400, 'duration must be a positive integer');
  }

  if (params.maxPrice !== undefined && params.maxPrice <= 0) {
    throw new AppError('INVALID_QUERY', 400, 'maxPrice must be a positive integer');
  }

  const result = (await amadeusClient.searchFlightDestinations(
    params
  )) as FlightDestinationResponse;
  return result;
}

export async function searchFlightCheapestDates(
  params: FlightCheapestDateSearchParams
): Promise<FlightCheapestDateSearchResult> {
  if (!params.origin) {
    throw new AppError('INVALID_QUERY', 400, 'origin is required');
  }

  if (!params.destination) {
    throw new AppError('INVALID_QUERY', 400, 'destination is required');
  }

  if (params.duration !== undefined && params.duration <= 0) {
    throw new AppError('INVALID_QUERY', 400, 'duration must be a positive integer');
  }

  if (params.maxPrice !== undefined && params.maxPrice <= 0) {
    throw new AppError('INVALID_QUERY', 400, 'maxPrice must be a positive integer');
  }

  const result = (await amadeusClient.searchFlightCheapestDates(params)) as FlightDateResponse;
  return result;
}
