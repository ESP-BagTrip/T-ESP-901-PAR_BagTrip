import { Router } from 'express';
import { validate } from '../../app/middleware/validate';
import { locationKeywordSearchQuerySchema, locationIdSearchQuerySchema } from './travel.validators';
import { searchLocationsByKeyword, searchLocationById } from './travel.controller';

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

export default r;
