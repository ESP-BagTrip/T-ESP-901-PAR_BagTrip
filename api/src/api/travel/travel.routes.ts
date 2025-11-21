import { Router } from 'express';
import { validate } from '../../app/middleware/validate';
import {
  locationKeywordSearchQuerySchema,
  locationIdSearchQuerySchema,
  locationNearestSearchQuerySchema,
  flightOfferSearchQuerySchema,
  flightDestinationSearchQuerySchema,
  flightCheapestDateSearchQuerySchema,
} from './travel.validators';
import {
  searchLocationsByKeyword,
  searchLocationById,
  searchLocationNearest,
  searchFlightOffers,
  searchFlightDestinations,
  searchFlightCheapestDates,
} from './travel.controller';

const r = Router();

/**
 * @swagger
 * /api/travel/locations:
 *   get:
 *     summary: Search for locations (cities, airports, etc.)
 *     tags: [Travel]
 *     parameters:
 *       - in: query
 *         name: subType
 *         required: true
 *         schema:
 *           type: string
 *         description: Comma-separated list of location sub-types (e.g., "CITY,AIRPORT")
 *         example: CITY,AIRPORT
 *       - in: query
 *         name: keyword
 *         required: true
 *         schema:
 *           type: string
 *         description: Search keyword for location name
 *         example: paris
 *     responses:
 *       200:
 *         description: List of matching locations
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/LocationSearchResult'
 *       400:
 *         description: Bad request - Invalid query parameters
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Internal server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
// GET /api/travel/locations?subType=CITY,AIRPORT&keyword=paris
r.get('/locations', validate(locationKeywordSearchQuerySchema), searchLocationsByKeyword);

/**
 * @swagger
 * /api/travel/locations/nearest:
 *   get:
 *     summary: Search for locations nearest to a given latitude and longitude
 *     tags: [Travel]
 *     parameters:
 *       - in: query
 *         name: latitude
 *         required: true
 *         schema:
 *           type: number
 *         description: Latitude
 *         example: 49.0000
 *       - in: query
 *         name: longitude
 *         required: true
 *         schema:
 *           type: number
 *         description: Longitude
 *         example: 2.55
 *     responses:
 *       200:
 *         description: List of matching locations
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/LocationSearchResult'
 *       400:
 *         description: Bad request - Invalid query parameters
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Internal server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
// GET /api/travel/locations/nearest?latitude=48.8566&longitude=2.3522
r.get('/locations/nearest', validate(locationNearestSearchQuerySchema), searchLocationNearest);

/**
 * @swagger
 * /api/travel/locations/{id}:
 *   get:
 *     summary: Search for a location by id
 *     tags: [Travel]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Location id
 *         example: CMUC
 *     responses:
 *       200:
 *         description: Location details
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Location'
 *       400:
 *         description: Bad request - Invalid query parameters
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Internal server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
// GET /api/travel/locations/{id}
r.get('/locations/:id', validate(locationIdSearchQuerySchema), searchLocationById);

/**
 * @swagger
 * /api/travel/flight/offers:
 *   get:
 *     summary: Search for flight offers
 *     tags: [Travel]
 *     parameters:
 *       - in: query
 *         name: originLocationCode
 *         required: true
 *         schema:
 *           type: string
 *         description: IATA code of the departure city/airport
 *         example: PAR
 *       - in: query
 *         name: destinationLocationCode
 *         required: true
 *         schema:
 *           type: string
 *         description: IATA code of the arrival city/airport
 *         example: NYC
 *       - in: query
 *         name: departureDate
 *         required: true
 *         schema:
 *           type: string
 *           format: date
 *         description: Departure date (YYYY-MM-DD)
 *         example: 2025-12-15
 *       - in: query
 *         name: adults
 *         required: true
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 9
 *         description: Number of adult travelers (1-9)
 *         example: 2
 *       - in: query
 *         name: returnDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Return date for round-trip (YYYY-MM-DD)
 *         example: 2025-12-22
 *       - in: query
 *         name: children
 *         schema:
 *           type: integer
 *           minimum: 0
 *           maximum: 9
 *         description: Number of child travelers (0-9)
 *         example: 1
 *       - in: query
 *         name: infants
 *         schema:
 *           type: integer
 *           minimum: 0
 *           maximum: 9
 *         description: Number of infant travelers (0-9, cannot exceed adults)
 *         example: 0
 *       - in: query
 *         name: travelClass
 *         schema:
 *           type: string
 *           enum: [ECONOMY, PREMIUM_ECONOMY, BUSINESS, FIRST]
 *         description: Cabin class preference
 *         example: ECONOMY
 *       - in: query
 *         name: nonStop
 *         schema:
 *           type: boolean
 *         description: Search for non-stop flights only
 *         example: false
 *       - in: query
 *         name: currencyCode
 *         schema:
 *           type: string
 *           pattern: '^[A-Z]{3}$'
 *         description: Currency code (ISO 4217, 3 letters)
 *         example: EUR
 *       - in: query
 *         name: maxPrice
 *         schema:
 *           type: integer
 *         description: Maximum price per traveler
 *         example: 500
 *       - in: query
 *         name: max
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 250
 *         description: Maximum number of flight offers to return (1-250)
 *         example: 50
 *       - in: query
 *         name: includedAirlineCodes
 *         schema:
 *           type: string
 *         description: Comma-separated list of airline codes to include (e.g., "AF,BA")
 *         example: AF,BA
 *       - in: query
 *         name: excludedAirlineCodes
 *         schema:
 *           type: string
 *         description: Comma-separated list of airline codes to exclude
 *         example: LH
 *     responses:
 *       200:
 *         description: List of flight offers
 *       400:
 *         description: Bad request - Invalid parameters
 *       500:
 *         description: Internal server error
 */
r.get('/flight/offers', validate(flightOfferSearchQuerySchema), searchFlightOffers);

/**
 * @swagger
 * /api/travel/flight/destinations:
 *   get:
 *     summary: Search for flight destinations (inspiration)
 *     tags: [Travel]
 *     description: Find inspiring flight destinations from an origin, useful for "Where can I go?" queries
 *     parameters:
 *       - in: query
 *         name: origin
 *         required: true
 *         schema:
 *           type: string
 *         description: IATA code of the departure city/airport
 *         example: PAR
 *       - in: query
 *         name: departureDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Departure date or date range (YYYY-MM-DD or YYYY-MM-DD,YYYY-MM-DD)
 *         example: 2025-12-15
 *       - in: query
 *         name: oneWay
 *         schema:
 *           type: boolean
 *         description: Search for one-way trips only
 *         example: false
 *       - in: query
 *         name: duration
 *         schema:
 *           type: integer
 *         description: Trip duration in days
 *         example: 7
 *       - in: query
 *         name: nonStop
 *         schema:
 *           type: boolean
 *         description: Search for non-stop flights only
 *         example: false
 *       - in: query
 *         name: maxPrice
 *         schema:
 *           type: integer
 *         description: Maximum price per traveler
 *         example: 500
 *       - in: query
 *         name: viewBy
 *         schema:
 *           type: string
 *           enum: [DURATION, COUNTRY, DATE, DESTINATION, WEEK]
 *         description: Group results by specific criteria
 *         example: DESTINATION
 *     responses:
 *       200:
 *         description: List of flight destinations
 *       400:
 *         description: Bad request - Invalid parameters
 *       500:
 *         description: Internal server error
 */
r.get('/flight/destinations', validate(flightDestinationSearchQuerySchema), searchFlightDestinations);

/**
 * @swagger
 * /api/travel/flight/cheapest-dates:
 *   get:
 *     summary: Search for cheapest flight dates
 *     tags: [Travel]
 *     description: Find the cheapest dates to fly between two destinations
 *     parameters:
 *       - in: query
 *         name: origin
 *         required: true
 *         schema:
 *           type: string
 *         description: IATA code of the departure city/airport
 *         example: PAR
 *       - in: query
 *         name: destination
 *         required: true
 *         schema:
 *           type: string
 *         description: IATA code of the arrival city/airport
 *         example: NYC
 *       - in: query
 *         name: departureDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Departure date or date range (YYYY-MM-DD or YYYY-MM-DD,YYYY-MM-DD)
 *         example: 2025-12-15
 *       - in: query
 *         name: oneWay
 *         schema:
 *           type: boolean
 *         description: Search for one-way trips only
 *         example: false
 *       - in: query
 *         name: duration
 *         schema:
 *           type: integer
 *         description: Trip duration in days
 *         example: 7
 *       - in: query
 *         name: nonStop
 *         schema:
 *           type: boolean
 *         description: Search for non-stop flights only
 *         example: false
 *       - in: query
 *         name: maxPrice
 *         schema:
 *           type: integer
 *         description: Maximum price per traveler
 *         example: 500
 *       - in: query
 *         name: viewBy
 *         schema:
 *           type: string
 *           enum: [DATE, DURATION, WEEK]
 *         description: Group results by specific criteria
 *         example: DATE
 *     responses:
 *       200:
 *         description: List of cheapest dates with prices
 *       400:
 *         description: Bad request - Invalid parameters
 *       500:
 *         description: Internal server error
 */
r.get('/flight/cheapest-dates', validate(flightCheapestDateSearchQuerySchema), searchFlightCheapestDates);

export default r;
