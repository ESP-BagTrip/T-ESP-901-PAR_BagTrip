import { Router } from 'express';
import travelRoutes from '../api/travel/travel.routes';

export const routes = () => {
  const r = Router();
  r.use('/travel', travelRoutes);
  return r;
};
