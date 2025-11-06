import { makeBreaker } from '../../config/circuit';
import {
  LocationKeywordSearchQuery,
  LocationIdSearchQuery,
  LocationNearestSearchQuery,
} from './amadeus.types';
import {
  searchLocationsByKeyword,
  searchLocationById,
  searchLocationNearest,
} from './amadeus.locations';

// Circuit breakers
const locationByKeywordBreaker = makeBreaker(searchLocationsByKeyword);
const locationByIdBreaker = makeBreaker(searchLocationById);
const locationNearestBreaker = makeBreaker(searchLocationNearest);

export const amadeusClient = {
  // Location by keyword
  searchLocationsByKeyword: (q: LocationKeywordSearchQuery) => locationByKeywordBreaker.fire(q),
  resetLocationByKeywordBreaker: () => locationByKeywordBreaker.close(),
  getLocationByKeywordBreakerStats: () => locationByKeywordBreaker.stats,

  // Location by id
  searchLocationById: (q: LocationIdSearchQuery) => locationByIdBreaker.fire(q),
  resetLocationByIdBreaker: () => locationByIdBreaker.close(),
  getLocationByIdBreakerStats: () => locationByIdBreaker.stats,

  // Location nearest
  searchLocationNearest: (q: LocationNearestSearchQuery) => locationNearestBreaker.fire(q),
  resetLocationNearestBreaker: () => locationNearestBreaker.close(),
  getLocationNearestBreakerStats: () => locationNearestBreaker.stats,
};
