export type FlightOfferQuery = {
  originLocationCode: string; // ex: "CDG"
  destinationLocationCode: string; // ex: "JFK"
  departureDate: string; // "YYYY-MM-DD"
  adults?: number; // défaut 1
  currencyCode?: string; // ex: "EUR"
  nonStop?: boolean; // optionnel
  max?: number; // nb max d'offres
};

export type FlightOffer = {
  id: string;
  price: { total: string; currency: string };
  itineraries: Array<{
    duration: string;
    segments: Array<{
      departure: { iataCode: string; at: string };
      arrival: { iataCode: string; at: string };
      carrierCode: string;
      number: string;
    }>;
  }>;
};

export type LocationSearchQuery = {
  subType: string; // "CITY,AIRPORT"
  keyword: string; // search keyword like "paris"
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
