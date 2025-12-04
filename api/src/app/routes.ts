import { Router } from 'express';
import travelRoutes from '../api/travel/travel.routes';
import authRoutes from '../api/auth/auth.routes';
import placesRoutes from '../api/places/places.routes';

export const routes = () => {
  const r = Router();
  r.use('/auth', authRoutes);
  r.use('/travel', travelRoutes);
  r.use('/places', placesRoutes);
  return r;
};
