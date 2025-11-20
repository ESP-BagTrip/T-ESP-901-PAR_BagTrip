import { Router } from 'express';
import travelRoutes from '../api/travel/travel.routes';
import hotelRoutes from '../api/hotel/hotel.routes';
import bookingRoutes from '../api/booking/booking.routes';
import authRoutes from '../api/auth/auth.routes';

export const routes = () => {
  const r = Router();
  r.use('/auth', authRoutes);
  r.use('/travel', travelRoutes);
  r.use('/hotel', hotelRoutes);
  r.use('/booking', bookingRoutes);
  return r;
};
