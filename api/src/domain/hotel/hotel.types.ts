import {
  HotelListResponse,
  HotelSearchResponse,
  HotelOfferDetailsResponse,
} from '../../integrations/amadeus/amadeus.types';

// ============================================================================
// HOTEL LIST TYPES
// ============================================================================

export type HotelListSearchParams = {
  cityCode: string;
  radius?: number;
  radiusUnit?: 'KM' | 'MILE';
  chainCodes?: string;
  amenities?: string;
  ratings?: string;
  hotelSource?: 'ALL' | 'BEDBANK' | 'DIRECTCHAIN';
};

export type HotelListResult = HotelListResponse;

// ============================================================================
// HOTEL SEARCH TYPES
// ============================================================================

export type HotelSearchParams = {
  hotelIds: string;
  adults: number;
  checkInDate?: string;
  checkOutDate?: string;
  roomQuantity?: number;
  priceRange?: string;
  currency?: string;
  paymentPolicy?: 'NONE' | 'GUARANTEE' | 'DEPOSIT';
  boardType?: 'ROOM_ONLY' | 'BREAKFAST' | 'HALF_BOARD' | 'FULL_BOARD' | 'ALL_INCLUSIVE';
  includeClosed?: boolean;
  bestRateOnly?: boolean;
};

export type HotelSearchResult = HotelSearchResponse;

// ============================================================================
// HOTEL OFFER DETAILS TYPES
// ============================================================================

export type HotelOfferDetailsParams = {
  offerId: string;
};

export type HotelOfferDetailsResult = HotelOfferDetailsResponse;
