import { Router } from 'express';
import travelRoutes from '../api/travel/travel.routes';
import authRoutes from '../api/auth/auth.routes';

export const routes = () => {
  const r = Router();
  r.use('/auth', authRoutes);
  r.use('/travel', travelRoutes);
  return r;
};
