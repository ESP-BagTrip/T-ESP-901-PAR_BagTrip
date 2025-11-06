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
