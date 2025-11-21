import {
  Location,
  FlightOfferResponse,
  FlightDestinationResponse,
  FlightDateResponse,
} from '../../integrations/amadeus/amadeus.types';

// ============================================================================
// LOCATION TYPES
// ============================================================================

export type LocationKeywordSearchParams = {
  subType: string; // "CITY,AIRPORT"
  keyword: string; // search keyword like "paris"
};

export type LocationSearchResult = {
  locations: Location[];
  count: number;
};

export type LocationIdSearchParams = {
  id: string;
};

export type LocationNearestSearchParams = {
  latitude: number;
  longitude: number;
};

// ============================================================================
// FLIGHT TYPES
// ============================================================================

export type FlightOfferSearchParams = {
  originLocationCode: string;
  destinationLocationCode: string;
  departureDate: string; // YYYY-MM-DD
  adults: number;
  returnDate?: string; // YYYY-MM-DD
  children?: number;
  infants?: number;
  travelClass?: 'ECONOMY' | 'PREMIUM_ECONOMY' | 'BUSINESS' | 'FIRST';
  nonStop?: boolean;
  currencyCode?: string;
  maxPrice?: number;
  max?: number;
  includedAirlineCodes?: string; // Comma-separated airline codes
  excludedAirlineCodes?: string; // Comma-separated airline codes
};

export type FlightDestinationSearchParams = {
  origin: string;
  departureDate?: string; // YYYY-MM-DD or range
  oneWay?: boolean;
  duration?: number;
  nonStop?: boolean;
  maxPrice?: number;
  viewBy?: 'DURATION' | 'COUNTRY' | 'DATE' | 'DESTINATION' | 'WEEK';
};

export type FlightCheapestDateSearchParams = {
  origin: string;
  destination: string;
  departureDate?: string; // YYYY-MM-DD or range
  oneWay?: boolean;
  duration?: number;
  nonStop?: boolean;
  maxPrice?: number;
  viewBy?: 'DATE' | 'DURATION' | 'WEEK';
};

export type FlightOfferSearchResult = FlightOfferResponse;
export type FlightDestinationSearchResult = FlightDestinationResponse;
export type FlightCheapestDateSearchResult = FlightDateResponse;
