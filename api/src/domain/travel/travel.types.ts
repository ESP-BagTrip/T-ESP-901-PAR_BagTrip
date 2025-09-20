import { Location } from '../../integrations/amadeus/amadeus.types';

export type LocationSearchParams = {
  subType: string; // "CITY,AIRPORT"
  keyword: string; // search keyword like "paris"
};

export type LocationSearchResult = {
  locations: Location[];
  count: number;
};
