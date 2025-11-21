export type LocationKeywordSearchQuery = {
  subType: string; // "CITY,AIRPORT"
  keyword: string; // search keyword like "paris"
};

export type LocationIdSearchQuery = {
  id: string;
};

export type LocationNearestSearchQuery = {
  latitude: number;
  longitude: number;
};

export type Location = {
  type: string;
  subType: string;
  name: string;
  detailedName: string;
  id: string;
  self: {
    href: string;
    methods: string[];
  };
  timeZoneOffset: string;
  iataCode?: string;
  geoCode: {
    latitude: number;
    longitude: number;
  };
  address: {
    cityName: string;
    cityCode: string;
    countryName: string;
    countryCode: string;
    regionCode: string;
  };
  analytics?: {
    travelers: {
      score: number;
    };
  };
};

// ============================================================================
// FLIGHT TYPES
// ============================================================================

// Flight Offers Search
export type FlightOfferSearchQuery = {
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

export type FlightOffer = {
  type: string;
  id: string;
  source: string;
  instantTicketingRequired: boolean;
  nonHomogeneous: boolean;
  oneWay: boolean;
  isUpsellOffer: boolean;
  lastTicketingDate?: string;
  lastTicketingDateTime?: string;
  numberOfBookableSeats?: number;
  itineraries: FlightItinerary[];
  price: FlightPrice;
  pricingOptions: FlightPricingOptions;
  validatingAirlineCodes: string[];
  travelerPricings: TravelerPricing[];
};

export type FlightItinerary = {
  duration: string;
  segments: FlightSegment[];
};

export type FlightSegment = {
  departure: FlightEndpoint;
  arrival: FlightEndpoint;
  carrierCode: string;
  number: string;
  aircraft?: {
    code: string;
  };
  operating?: {
    carrierCode: string;
  };
  duration: string;
  id: string;
  numberOfStops: number;
  blacklistedInEU: boolean;
};

export type FlightEndpoint = {
  iataCode: string;
  at: string;
  terminal?: string;
};

export type FlightPrice = {
  currency: string;
  total: string;
  base: string;
  fees?: Array<{
    amount: string;
    type: string;
  }>;
  grandTotal: string;
  additionalServices?: Array<{
    amount: string;
    type: string;
  }>;
};

export type FlightPricingOptions = {
  fareType: string[];
  includedCheckedBagsOnly: boolean;
};

export type TravelerPricing = {
  travelerId: string;
  fareOption: string;
  travelerType: string;
  price: {
    currency: string;
    total: string;
    base: string;
  };
  fareDetailsBySegment: FareDetailsBySegment[];
};

export type FareDetailsBySegment = {
  segmentId: string;
  cabin: string;
  fareBasis: string;
  class: string;
  includedCheckedBags?: {
    quantity: number;
  };
};

export type FlightOfferResponse = {
  meta: {
    count: number;
    links: {
      self: string;
    };
  };
  data: FlightOffer[];
  dictionaries?: {
    locations?: Record<string, { cityCode: string; countryCode: string }>;
    aircraft?: Record<string, string>;
    currencies?: Record<string, string>;
    carriers?: Record<string, string>;
  };
};

// Flight Inspiration Search (Destinations)
export type FlightInspirationSearchQuery = {
  origin: string; // IATA code
  departureDate?: string; // YYYY-MM-DD or YYYY-MM-DD,YYYY-MM-DD for range
  oneWay?: boolean;
  duration?: number; // in days
  nonStop?: boolean;
  maxPrice?: number;
  viewBy?: 'DURATION' | 'COUNTRY' | 'DATE' | 'DESTINATION' | 'WEEK';
};

export type FlightDestination = {
  type: string;
  origin: string;
  destination: string;
  departureDate: string;
  returnDate?: string;
  price: {
    total: string;
  };
  links?: {
    flightDates?: string;
    flightOffers?: string;
  };
};

export type FlightDestinationResponse = {
  meta: {
    currency: string;
    links?: {
      self: string;
    };
  };
  data: FlightDestination[];
};

// Flight Cheapest Date Search
export type FlightCheapestDateSearchQuery = {
  origin: string;
  destination: string;
  departureDate?: string; // YYYY-MM-DD or YYYY-MM-DD,YYYY-MM-DD for range
  oneWay?: boolean;
  duration?: number; // in days
  nonStop?: boolean;
  maxPrice?: number;
  viewBy?: 'DATE' | 'DURATION' | 'WEEK';
};

export type FlightDate = {
  type: string;
  origin: string;
  destination: string;
  departureDate: string;
  returnDate?: string;
  price: {
    total: string;
  };
  links?: {
    flightDestinations?: string;
    flightOffers?: string;
  };
};

export type FlightDateResponse = {
  meta: {
    currency: string;
    links?: {
      self: string;
    };
  };
  data: FlightDate[];
};
