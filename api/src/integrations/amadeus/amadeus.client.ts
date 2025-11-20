import { makeBreaker } from '../../config/circuit';
import {
  LocationKeywordSearchQuery,
  LocationIdSearchQuery,
  LocationNearestSearchQuery,
  FlightOfferSearchQuery,
  FlightInspirationSearchQuery,
  FlightCheapestDateSearchQuery,
  HotelListSearchQuery,
  HotelSearchQuery,
  HotelOfferDetailsQuery,
  HotelBookingRequest,
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
import {
  searchHotelsByCity,
  searchHotelOffers,
  getHotelOfferDetails,
} from './amadeus.hotels';
import { createHotelBooking } from './amadeus.bookings';

// Circuit breakers for locations
const locationByKeywordBreaker = makeBreaker(searchLocationsByKeyword);
const locationByIdBreaker = makeBreaker(searchLocationById);
const locationNearestBreaker = makeBreaker(searchLocationNearest);

// Circuit breakers for flights
const flightOffersBreaker = makeBreaker(searchFlightOffers);
const flightDestinationsBreaker = makeBreaker(searchFlightDestinations);
const flightCheapestDatesBreaker = makeBreaker(searchFlightCheapestDates);

// Circuit breakers for hotels
const hotelsByCityBreaker = makeBreaker(searchHotelsByCity);
const hotelOffersBreaker = makeBreaker(searchHotelOffers);
const hotelOfferDetailsBreaker = makeBreaker(getHotelOfferDetails);

// Circuit breakers for bookings
const hotelBookingBreaker = makeBreaker(createHotelBooking);

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

  // Hotels by city
  searchHotelsByCity: (q: HotelListSearchQuery) => hotelsByCityBreaker.fire(q),
  resetHotelsByCityBreaker: () => hotelsByCityBreaker.close(),
  getHotelsByCityBreakerStats: () => hotelsByCityBreaker.stats,

  // Hotel offers
  searchHotelOffers: (q: HotelSearchQuery) => hotelOffersBreaker.fire(q),
  resetHotelOffersBreaker: () => hotelOffersBreaker.close(),
  getHotelOffersBreakerStats: () => hotelOffersBreaker.stats,

  // Hotel offer details
  getHotelOfferDetails: (q: HotelOfferDetailsQuery) => hotelOfferDetailsBreaker.fire(q),
  resetHotelOfferDetailsBreaker: () => hotelOfferDetailsBreaker.close(),
  getHotelOfferDetailsBreakerStats: () => hotelOfferDetailsBreaker.stats,

  // Hotel booking
  createHotelBooking: (booking: HotelBookingRequest) => hotelBookingBreaker.fire(booking),
  resetHotelBookingBreaker: () => hotelBookingBreaker.close(),
  getHotelBookingBreakerStats: () => hotelBookingBreaker.stats,
};
