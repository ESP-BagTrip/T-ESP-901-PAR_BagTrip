import { Router } from 'express';
import { validate } from '../../app/middleware/validate';
import { locationSearchQuerySchema } from './travel.validators';
import { searchLocations } from './travel.controller';

const r = Router();

// GET /api/travel/locations?subType=CITY,AIRPORT&keyword=paris
r.get('/locations', validate(locationSearchQuerySchema), searchLocations);

export default r;
