import { Router } from 'express';
import { validate } from '../../app/middleware/validate';
import { locationSearchQuerySchema } from './travel.validators';
import { searchLocations } from './travel.controller';

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
r.get('/locations', validate(locationSearchQuerySchema), searchLocations);

export default r;
