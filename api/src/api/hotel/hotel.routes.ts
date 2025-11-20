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
 *     parameters:
 *       - in: query
 *         name: cityCode
 *         required: true
 *         schema:
 *           type: string
 *         description: IATA city code (3 letters)
 *         example: PAR
 *       - in: query
 *         name: radius
 *         schema:
 *           type: number
 *         description: Search radius
 *         example: 5
 *       - in: query
 *         name: radiusUnit
 *         schema:
 *           type: string
 *           enum: [KM, MILE]
 *         description: Unit for radius
 *         example: KM
 *       - in: query
 *         name: chainCodes
 *         schema:
 *           type: string
 *         description: Comma-separated hotel chain codes (e.g., "MC,RT")
 *         example: MC
 *       - in: query
 *         name: amenities
 *         schema:
 *           type: string
 *         description: Comma-separated amenities (e.g., "SWIMMING_POOL,SPA")
 *         example: SWIMMING_POOL
 *       - in: query
 *         name: ratings
 *         schema:
 *           type: string
 *         description: Comma-separated ratings (e.g., "4,5")
 *         example: 4,5
 *       - in: query
 *         name: hotelSource
 *         schema:
 *           type: string
 *           enum: [ALL, BEDBANK, DIRECTCHAIN]
 *         description: Source of hotel data
 *         example: ALL
 *     responses:
 *       200:
 *         description: List of hotels
 *       400:
 *         description: Bad request
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
 *     parameters:
 *       - in: query
 *         name: hotelIds
 *         required: true
 *         schema:
 *           type: string
 *         description: Comma-separated Amadeus hotel IDs
 *         example: MCLONGHM,ADNYCCTB
 *       - in: query
 *         name: adults
 *         required: true
 *         schema:
 *           type: integer
 *         description: Number of adult guests (1-9)
 *         example: 2
 *       - in: query
 *         name: checkInDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Check-in date
 *         example: 2025-12-15
 *       - in: query
 *         name: checkOutDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Check-out date
 *         example: 2025-12-20
 *       - in: query
 *         name: roomQuantity
 *         schema:
 *           type: integer
 *         description: Number of rooms (1-9)
 *         example: 1
 *       - in: query
 *         name: priceRange
 *         schema:
 *           type: string
 *         description: Price range (e.g., "100-200")
 *         example: 100-500
 *       - in: query
 *         name: currency
 *         schema:
 *           type: string
 *         description: Currency code (ISO 4217)
 *         example: EUR
 *       - in: query
 *         name: paymentPolicy
 *         schema:
 *           type: string
 *           enum: [NONE, GUARANTEE, DEPOSIT]
 *         description: Payment policy
 *       - in: query
 *         name: boardType
 *         schema:
 *           type: string
 *           enum: [ROOM_ONLY, BREAKFAST, HALF_BOARD, FULL_BOARD, ALL_INCLUSIVE]
 *         description: Board type
 *       - in: query
 *         name: includeClosed
 *         schema:
 *           type: boolean
 *         description: Include closed hotels
 *       - in: query
 *         name: bestRateOnly
 *         schema:
 *           type: boolean
 *         description: Return only best rate per hotel
 *     responses:
 *       200:
 *         description: List of hotel offers
 *       400:
 *         description: Bad request
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
 *     parameters:
 *       - in: path
 *         name: offerId
 *         required: true
 *         schema:
 *           type: string
 *         description: Hotel offer ID
 *         example: 4L8PRJPEN7
 *     responses:
 *       200:
 *         description: Hotel offer details
 *       400:
 *         description: Bad request
 *       500:
 *         description: Internal server error
 */
r.get('/offers/:offerId', validate(hotelOfferDetailsParamSchema), getHotelOfferDetails);

export default r;
