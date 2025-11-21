import { makeBreaker } from '../../config/circuit';
import {
  LocationKeywordSearchQuery,
  LocationIdSearchQuery,
  LocationNearestSearchQuery,
  FlightOfferSearchQuery,
  FlightInspirationSearchQuery,
  FlightCheapestDateSearchQuery,
} from './amadeus.types';
import {
  searchLocationsByKeyword,
  searchLocationById,
  searchLocationNearest,
} from './amadeus.locations';
import {
  searchFlightOffers,
  searchFlightDestinations,
  searchFlightCheapestDates,
} from './amadeus.flights';

// Circuit breakers for locations
const locationByKeywordBreaker = makeBreaker(searchLocationsByKeyword);
const locationByIdBreaker = makeBreaker(searchLocationById);
const locationNearestBreaker = makeBreaker(searchLocationNearest);

// Circuit breakers for flights
const flightOffersBreaker = makeBreaker(searchFlightOffers);
const flightDestinationsBreaker = makeBreaker(searchFlightDestinations);
const flightCheapestDatesBreaker = makeBreaker(searchFlightCheapestDates);

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

  // Flight offers
  searchFlightOffers: (q: FlightOfferSearchQuery) => flightOffersBreaker.fire(q),
  resetFlightOffersBreaker: () => flightOffersBreaker.close(),
  getFlightOffersBreakerStats: () => flightOffersBreaker.stats,

  // Flight destinations (inspiration)
  searchFlightDestinations: (q: FlightInspirationSearchQuery) => flightDestinationsBreaker.fire(q),
  resetFlightDestinationsBreaker: () => flightDestinationsBreaker.close(),
  getFlightDestinationsBreakerStats: () => flightDestinationsBreaker.stats,

  // Flight cheapest dates
  searchFlightCheapestDates: (q: FlightCheapestDateSearchQuery) =>
    flightCheapestDatesBreaker.fire(q),
  resetFlightCheapestDatesBreaker: () => flightCheapestDatesBreaker.close(),
  getFlightCheapestDatesBreakerStats: () => flightCheapestDatesBreaker.stats,
};
