import { amadeusClient } from '../../integrations/amadeus/amadeus.client';
import {
  HotelListSearchParams,
  HotelListResult,
  HotelSearchParams,
  HotelSearchResult,
  HotelOfferDetailsParams,
  HotelOfferDetailsResult,
} from './hotel.types';
import { AppError } from '../../utils/errors';
import {
  HotelListResponse,
  HotelSearchResponse,
  HotelOfferDetailsResponse,
} from '../../integrations/amadeus/amadeus.types';

/**
 * Search hotels by city code.
 */
export async function searchHotelsByCity(params: HotelListSearchParams): Promise<HotelListResult> {
  if (!params.cityCode) {
    throw new AppError('INVALID_QUERY', 400, 'cityCode is required');
  }

  if (params.cityCode.length !== 3) {
    throw new AppError('INVALID_QUERY', 400, 'cityCode must be a 3-letter IATA code');
  }

  if (params.radius !== undefined && params.radius <= 0) {
    throw new AppError('INVALID_QUERY', 400, 'radius must be a positive number');
  }

  const result = (await amadeusClient.searchHotelsByCity({
    cityCode: params.cityCode,
    radius: params.radius,
    radiusUnit: params.radiusUnit,
    chainCodes: params.chainCodes,
    amenities: params.amenities,
    ratings: params.ratings,
    hotelSource: params.hotelSource,
  })) as HotelListResponse;

  return result;
}

/**
 * Search hotel offers with real-time pricing.
 */
export async function searchHotelOffers(params: HotelSearchParams): Promise<HotelSearchResult> {
  if (!params.hotelIds) {
    throw new AppError('INVALID_QUERY', 400, 'hotelIds is required');
  }

  if (!params.adults || params.adults < 1 || params.adults > 9) {
    throw new AppError('INVALID_QUERY', 400, 'adults must be between 1 and 9');
  }

  if (params.roomQuantity !== undefined && (params.roomQuantity < 1 || params.roomQuantity > 9)) {
    throw new AppError('INVALID_QUERY', 400, 'roomQuantity must be between 1 and 9');
  }

  const result = (await amadeusClient.searchHotelOffers({
    hotelIds: params.hotelIds,
    adults: params.adults,
    checkInDate: params.checkInDate,
    checkOutDate: params.checkOutDate,
    roomQuantity: params.roomQuantity,
    priceRange: params.priceRange,
    currency: params.currency,
    paymentPolicy: params.paymentPolicy,
    boardType: params.boardType,
    includeClosed: params.includeClosed,
    bestRateOnly: params.bestRateOnly,
  })) as HotelSearchResponse;

  return result;
}

/**
 * Get hotel offer details by offerId.
 */
export async function getHotelOfferDetails(
  params: HotelOfferDetailsParams
): Promise<HotelOfferDetailsResult> {
  if (!params.offerId) {
    throw new AppError('INVALID_QUERY', 400, 'offerId is required');
  }

  const result = (await amadeusClient.getHotelOfferDetails({
    offerId: params.offerId,
  })) as HotelOfferDetailsResponse;

  return result;
}
