import { amadeusClient } from '../../integrations/amadeus/amadeus.client';
import { LocationSearchParams, LocationSearchResult } from './travel.types';
import { AppError } from '../../utils/errors';
import { Location } from '../../integrations/amadeus/amadeus.types';

export async function searchLocations(params: LocationSearchParams): Promise<LocationSearchResult> {
  if (!params.subType || !params.keyword) {
    throw new AppError('INVALID_QUERY', 400, 'subType and keyword are required');
  }

  const locations = (await amadeusClient.searchLocations({
    subType: params.subType,
    keyword: params.keyword,
  })) as Location[];

  return { locations, count: locations.length };
}
