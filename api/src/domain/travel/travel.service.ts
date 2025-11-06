import { amadeusClient } from '../../integrations/amadeus/amadeus.client';
import {
  LocationIdSearchParams,
  LocationKeywordSearchParams,
  LocationSearchResult,
} from './travel.types';
import { AppError } from '../../utils/errors';
import { Location } from '../../integrations/amadeus/amadeus.types';

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
