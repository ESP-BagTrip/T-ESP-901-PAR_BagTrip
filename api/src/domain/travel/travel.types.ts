import { Location } from '../../integrations/amadeus/amadeus.types';

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
