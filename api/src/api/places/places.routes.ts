import { Router } from 'express';
import { validate } from '../../app/middleware/validate';
import {
  nearbySearchQuerySchema,
  textSearchQuerySchema,
  placeDetailsParamSchema,
} from './places.validators';
import {
  searchNearbyPlaces,
  searchPlacesByText,
  getPlaceDetails,
} from './places.controller';

const r = Router();

/**
 * @swagger
 * /api/places/nearby:
 *   get:
 *     summary: Search for nearby places around a location
 *     tags: [Places]
 *     description: Find places within a specified radius around coordinates (from hotel, user position, or manual entry)
 *     parameters:
 *       - in: query
 *         name: latitude
 *         required: true
 *         schema:
 *           type: number
 *           minimum: -90
 *           maximum: 90
 *         description: Latitude of the center point
 *         example: 48.8566
 *       - in: query
 *         name: longitude
 *         required: true
 *         schema:
 *           type: number
 *           minimum: -180
 *           maximum: 180
 *         description: Longitude of the center point
 *         example: 2.3522
 *       - in: query
 *         name: radius
 *         schema:
 *           type: number
 *           minimum: 1
 *           maximum: 50000
 *         description: Search radius in meters (default 1000m, max 50km)
 *         example: 2000
 *       - in: query
 *         name: types
 *         schema:
 *           type: string
 *         description: Comma-separated place types (e.g., "restaurant,cafe,museum")
 *         example: restaurant,cafe,tourist_attraction
 *       - in: query
 *         name: maxResults
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 20
 *         description: Maximum number of results to return (1-20, default 10)
 *         example: 10
 *       - in: query
 *         name: rankBy
 *         schema:
 *           type: string
 *           enum: [POPULARITY, DISTANCE]
 *         description: How to rank results (POPULARITY by default, DISTANCE for nearest first)
 *         example: POPULARITY
 *       - in: query
 *         name: language
 *         schema:
 *           type: string
 *           pattern: '^[a-z]{2}$'
 *         description: Language code (ISO 639-1, 2 letters, e.g., "en", "fr")
 *         example: en
 *       - in: query
 *         name: source
 *         schema:
 *           type: string
 *           enum: [hotel, manual, current]
 *         description: Source of the location (hotel=from Amadeus booking, manual=user entered, current=user GPS)
 *         example: hotel
 *     responses:
 *       200:
 *         description: List of nearby places with details
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 places:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: string
 *                       displayName:
 *                         type: object
 *                         properties:
 *                           text:
 *                             type: string
 *                       formattedAddress:
 *                         type: string
 *                       location:
 *                         type: object
 *                         properties:
 *                           latitude:
 *                             type: number
 *                           longitude:
 *                             type: number
 *                       types:
 *                         type: array
 *                         items:
 *                           type: string
 *                       rating:
 *                         type: number
 *                       googleMapsUri:
 *                         type: string
 *                 searchCenter:
 *                   type: object
 *                   properties:
 *                     latitude:
 *                       type: number
 *                     longitude:
 *                       type: number
 *                 radius:
 *                   type: number
 *                 totalResults:
 *                   type: number
 *                 source:
 *                   type: string
 *       400:
 *         description: Bad request - Invalid parameters
 *       500:
 *         description: Internal server error
 */
r.get('/nearby', validate(nearbySearchQuerySchema), searchNearbyPlaces);

/**
 * @swagger
 * /api/places/search:
 *   get:
 *     summary: Search places using text query
 *     tags: [Places]
 *     description: Search for places using a text query with optional location bias
 *     parameters:
 *       - in: query
 *         name: q
 *         required: true
 *         schema:
 *           type: string
 *         description: Search query text (e.g., "restaurants near Eiffel Tower")
 *         example: best restaurants in Paris
 *       - in: query
 *         name: latitude
 *         schema:
 *           type: number
 *           minimum: -90
 *           maximum: 90
 *         description: Optional latitude to bias search results
 *         example: 48.8566
 *       - in: query
 *         name: longitude
 *         schema:
 *           type: number
 *           minimum: -180
 *           maximum: 180
 *         description: Optional longitude to bias search results
 *         example: 2.3522
 *       - in: query
 *         name: radius
 *         schema:
 *           type: number
 *           minimum: 1
 *           maximum: 50000
 *         description: Search radius if lat/lng provided (default 5000m)
 *         example: 5000
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *         description: Filter by a single place type
 *         example: restaurant
 *       - in: query
 *         name: maxResults
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 20
 *         description: Maximum number of results (1-20, default 10)
 *         example: 10
 *       - in: query
 *         name: language
 *         schema:
 *           type: string
 *           pattern: '^[a-z]{2}$'
 *         description: Language code (ISO 639-1)
 *         example: en
 *       - in: query
 *         name: minRating
 *         schema:
 *           type: number
 *           minimum: 0
 *           maximum: 5
 *         description: Minimum rating filter (0-5)
 *         example: 4.0
 *       - in: query
 *         name: openNow
 *         schema:
 *           type: boolean
 *         description: Filter for places currently open
 *         example: true
 *     responses:
 *       200:
 *         description: List of matching places
 *       400:
 *         description: Bad request - Invalid parameters
 *       500:
 *         description: Internal server error
 */
r.get('/search', validate(textSearchQuerySchema), searchPlacesByText);

/**
 * @swagger
 * /api/places/{placeId}:
 *   get:
 *     summary: Get detailed information about a specific place
 *     tags: [Places]
 *     description: Retrieve comprehensive details for a place using its Google Place ID
 *     parameters:
 *       - in: path
 *         name: placeId
 *         required: true
 *         schema:
 *           type: string
 *         description: Google Place ID (obtained from search results)
 *         example: ChIJD7fiBh9u5kcRYJSMaMOCCwQ
 *       - in: query
 *         name: language
 *         schema:
 *           type: string
 *           pattern: '^[a-z]{2}$'
 *         description: Language code for the response (ISO 639-1)
 *         example: en
 *     responses:
 *       200:
 *         description: Detailed place information including hours, reviews, photos, etc.
 *       400:
 *         description: Bad request - Invalid place ID
 *       404:
 *         description: Place not found
 *       500:
 *         description: Internal server error
 */
r.get('/:placeId', validate(placeDetailsParamSchema), getPlaceDetails);

export default r;
