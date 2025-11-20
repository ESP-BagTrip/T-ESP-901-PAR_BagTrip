import { Router } from 'express';
import { validate } from '../../app/middleware/validate';
import {
  hotelListSearchQuerySchema,
  hotelSearchQuerySchema,
  hotelOfferDetailsParamSchema,
} from './hotel.validators';
import { searchHotelsByCity, searchHotelOffers, getHotelOfferDetails } from './hotel.controller';

const r = Router();

/**
 * @swagger
 * /api/hotel/search/city:
 *   get:
 *     summary: Search hotels by city code
 *     tags: [Hotel]
 *     description: Retrieve a list of hotels in a specific city using IATA city code
 *     parameters:
 *       - in: query
 *         name: cityCode
 *         required: true
 *         schema:
 *           type: string
 *           pattern: '^[A-Z]{3}$'
 *         description: IATA city code (3 uppercase letters, e.g., PAR for Paris, LON for London)
 *         example: PAR
 *       - in: query
 *         name: radius
 *         schema:
 *           type: number
 *           minimum: 0
 *         description: Search radius around the city center
 *         example: 5
 *       - in: query
 *         name: radiusUnit
 *         schema:
 *           type: string
 *           enum: [KM, MILE]
 *         description: Unit of measurement for the radius
 *         example: KM
 *       - in: query
 *         name: chainCodes
 *         schema:
 *           type: string
 *         description: Comma-separated hotel chain codes to filter results (e.g., "MC" for Marriott, "RT" for Accor)
 *         example: MC,RT
 *       - in: query
 *         name: amenities
 *         schema:
 *           type: string
 *         description: Comma-separated amenities to filter hotels (e.g., SWIMMING_POOL, SPA, PARKING, WIFI, GYM)
 *         example: SWIMMING_POOL,WIFI
 *       - in: query
 *         name: ratings
 *         schema:
 *           type: string
 *         description: Comma-separated star ratings to filter hotels (e.g., "3,4,5" for 3 to 5 star hotels)
 *         example: 4,5
 *       - in: query
 *         name: hotelSource
 *         schema:
 *           type: string
 *           enum: [ALL, BEDBANK, DIRECTCHAIN]
 *         description: Source of hotel data (ALL for all sources, BEDBANK for aggregators, DIRECTCHAIN for GDS/Distribution)
 *         example: ALL
 *     responses:
 *       200:
 *         description: List of hotels matching the search criteria
 *       400:
 *         description: Bad request - Invalid parameters
 *       500:
 *         description: Internal server error
 */
r.get('/search/city', validate(hotelListSearchQuerySchema), searchHotelsByCity);

/**
 * @swagger
 * /api/hotel/offers:
 *   get:
 *     summary: Search hotel offers with real-time pricing
 *     tags: [Hotel]
 *     description: Get available rooms and real-time pricing for specific hotels
 *     parameters:
 *       - in: query
 *         name: hotelIds
 *         required: true
 *         schema:
 *           type: string
 *         description: Comma-separated Amadeus hotel IDs (obtained from hotel search by city)
 *         example: MCLONGHM,ADNYCCTB
 *       - in: query
 *         name: adults
 *         required: true
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 9
 *         description: Number of adult guests per room (1-9)
 *         example: 2
 *       - in: query
 *         name: checkInDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Check-in date (YYYY-MM-DD format)
 *         example: 2025-12-15
 *       - in: query
 *         name: checkOutDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Check-out date (YYYY-MM-DD format)
 *         example: 2025-12-20
 *       - in: query
 *         name: roomQuantity
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 9
 *         description: Number of rooms to book (1-9)
 *         example: 1
 *       - in: query
 *         name: priceRange
 *         schema:
 *           type: string
 *         description: Price range filter (e.g., "100-500" for prices between 100 and 500)
 *         example: 100-500
 *       - in: query
 *         name: currency
 *         schema:
 *           type: string
 *           pattern: '^[A-Z]{3}$'
 *         description: Preferred currency code (ISO 4217, 3 letters)
 *         example: EUR
 *       - in: query
 *         name: paymentPolicy
 *         schema:
 *           type: string
 *           enum: [NONE, GUARANTEE, DEPOSIT]
 *         description: Required payment policy type (NONE=no prepayment, GUARANTEE=card guarantee, DEPOSIT=upfront deposit)
 *         example: GUARANTEE
 *       - in: query
 *         name: boardType
 *         schema:
 *           type: string
 *           enum: [ROOM_ONLY, BREAKFAST, HALF_BOARD, FULL_BOARD, ALL_INCLUSIVE]
 *         description: Meal plan type included in the rate
 *         example: BREAKFAST
 *       - in: query
 *         name: includeClosed
 *         schema:
 *           type: boolean
 *         description: Include hotels that are temporarily closed
 *         example: false
 *       - in: query
 *         name: bestRateOnly
 *         schema:
 *           type: boolean
 *         description: Return only the best (lowest) rate per hotel
 *         example: true
 *     responses:
 *       200:
 *         description: List of hotel offers with real-time availability and pricing
 *       400:
 *         description: Bad request - Invalid parameters
 *       500:
 *         description: Internal server error
 */
r.get('/offers', validate(hotelSearchQuerySchema), searchHotelOffers);

/**
 * @swagger
 * /api/hotel/offers/{offerId}:
 *   get:
 *     summary: Get hotel offer details by offerId
 *     tags: [Hotel]
 *     description: Retrieve detailed information for a specific hotel offer, useful for validation before booking
 *     parameters:
 *       - in: path
 *         name: offerId
 *         required: true
 *         schema:
 *           type: string
 *         description: Unique hotel offer ID obtained from hotel offers search
 *         example: 4L8PRJPEN7
 *     responses:
 *       200:
 *         description: Detailed hotel offer information including room details, pricing, and policies
 *       400:
 *         description: Bad request - Invalid offer ID
 *       404:
 *         description: Offer not found or expired
 *       500:
 *         description: Internal server error
 */
r.get('/offers/:offerId', validate(hotelOfferDetailsParamSchema), getHotelOfferDetails);

export default r;
