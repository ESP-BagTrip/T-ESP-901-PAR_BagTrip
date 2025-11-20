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

// ============================================================================
// HOTEL TYPES
// ============================================================================

// Hotel List Search (by city)
export type HotelListSearchQuery = {
  cityCode: string; // IATA city code (e.g., "PAR" for Paris)
  radius?: number; // Search radius
  radiusUnit?: 'KM' | 'MILE'; // Unit for radius
  chainCodes?: string; // Comma-separated hotel chain codes (e.g., "MC,RT")
  amenities?: string; // Comma-separated amenities (e.g., "SWIMMING_POOL,SPA")
  ratings?: string; // Comma-separated ratings (e.g., "4,5")
  hotelSource?: 'ALL' | 'BEDBANK' | 'DIRECTCHAIN'; // Source of hotel data
};

export type HotelBasicInfo = {
  type: string;
  hotelId: string;
  chainCode?: string;
  dupeId?: string;
  name: string;
  cityCode?: string;
  iataCode: string;
  geoCode?: {
    latitude: number;
    longitude: number;
  };
  address?: {
    countryCode: string;
  };
  distance?: {
    value: number;
    unit: string;
  };
  lastUpdate?: string;
};

export type HotelListResponse = {
  data: HotelBasicInfo[];
  meta?: {
    count?: number;
    links?: {
      self?: string;
      next?: string;
      last?: string;
    };
  };
};

// Hotel Search (offers with pricing)
export type HotelSearchQuery = {
  hotelIds: string; // Comma-separated Amadeus hotel IDs (e.g., "MCLONGHM,ADNYCCTB")
  adults: number; // Number of adult guests (1-9)
  checkInDate?: string; // Check-in date (YYYY-MM-DD)
  checkOutDate?: string; // Check-out date (YYYY-MM-DD)
  roomQuantity?: number; // Number of rooms (1-9)
  priceRange?: string; // Price range (e.g., "100-200")
  currency?: string; // Currency code (ISO 4217)
  paymentPolicy?: 'NONE' | 'GUARANTEE' | 'DEPOSIT'; // Payment policy
  boardType?: 'ROOM_ONLY' | 'BREAKFAST' | 'HALF_BOARD' | 'FULL_BOARD' | 'ALL_INCLUSIVE'; // Board type
  includeClosed?: boolean; // Include closed hotels
  bestRateOnly?: boolean; // Return only best rate per hotel
};

export type HotelOffer = {
  type: string;
  id: string; // Offer ID
  checkInDate?: string;
  checkOutDate?: string;
  rateCode?: string;
  rateFamilyEstimated?: {
    code: string;
    type: string;
  };
  room?: {
    type?: string;
    typeEstimated?: {
      category?: string;
      beds?: number;
      bedType?: string;
    };
    description?: {
      text?: string;
      lang?: string;
    };
  };
  guests?: {
    adults: number;
  };
  price?: {
    currency: string;
    base?: string;
    total: string;
    taxes?: Array<{
      amount?: string;
      currency?: string;
      code?: string;
      percentage?: string;
      included?: boolean;
      description?: string;
      pricingFrequency?: string;
      pricingMode?: string;
    }>;
    variations?: {
      average?: {
        base?: string;
        total?: string;
      };
      changes?: Array<{
        startDate?: string;
        endDate?: string;
        base?: string;
        total?: string;
      }>;
    };
  };
  policies?: {
    paymentType?: string;
    guarantee?: {
      acceptedPayments?: {
        creditCards?: string[];
        methods?: string[];
      };
    };
    deposit?: {
      acceptedPayments?: {
        creditCards?: string[];
        methods?: string[];
      };
      amount?: string;
      deadline?: string;
    };
    cancellation?: {
      type?: string;
      amount?: string;
      deadline?: string;
      description?: {
        text?: string;
        lang?: string;
      };
    };
  };
  self?: string;
};

export type HotelSearchResponse = {
  data: Array<{
    type: string;
    hotel: HotelBasicInfo;
    available: boolean;
    offers: HotelOffer[];
    self?: string;
  }>;
  meta?: any;
};

// Hotel Offer Details (by offerId)
export type HotelOfferDetailsQuery = {
  offerId: string;
};

export type HotelOfferDetailsResponse = {
  data: {
    type: string;
    hotel: HotelBasicInfo;
    available: boolean;
    offers: HotelOffer[];
    self?: string;
  };
  meta?: any;
};

// ============================================================================
// HOTEL BOOKING TYPES
// ============================================================================

export type HotelBookingGuest = {
  tid?: number;
  title: string; // MR, MRS, MS
  firstName: string;
  lastName: string;
  phone: string;
  email: string;
};

export type HotelBookingPayment = {
  method: 'CREDIT_CARD';
  paymentCard: {
    paymentCardInfo: {
      vendorCode: string; // VI (Visa), CA (Mastercard), AX (American Express)
      cardNumber: string;
      expiryDate: string; // YYYY-MM
      holderName: string;
    };
  };
};

export type HotelBookingRoomAssociation = {
  guestReferences: Array<{
    guestReference: string;
  }>;
  hotelOfferId: string;
};

export type HotelBookingRequest = {
  data: {
    type?: 'hotel-order';
    guests: HotelBookingGuest[];
    travelAgent?: {
      contact?: {
        email: string;
      };
    };
    roomAssociations: HotelBookingRoomAssociation[];
    payment: HotelBookingPayment;
  };
};

export type HotelBookingConfirmation = {
  type: string;
  id: string;
  providerConfirmationId?: string;
  associatedRecords?: Array<{
    reference: string;
    originSystemCode: string;
  }>;
  hotel?: HotelBasicInfo;
  bookingDate?: string;
  checkInDate?: string;
  checkOutDate?: string;
  room?: {
    type?: string;
    typeEstimated?: {
      category?: string;
      beds?: number;
      bedType?: string;
    };
    description?: {
      text?: string;
      lang?: string;
    };
  };
  guests?: HotelBookingGuest[];
  price?: {
    currency: string;
    base?: string;
    total: string;
    taxes?: any[];
  };
};

export type HotelBookingResponse = {
  data: HotelBookingConfirmation[];
  meta?: any;
};
