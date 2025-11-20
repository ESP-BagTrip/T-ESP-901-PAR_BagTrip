import { Request, Response, NextFunction } from 'express';
import * as svc from '../../domain/booking/booking.service';

export async function createHotelBooking(req: Request, res: Response, next: NextFunction) {
  try {
    const { guests, travelAgentEmail, roomAssociations, payment } = req.body;

    const result = await svc.createHotelBooking({
      guests,
      travelAgentEmail,
      roomAssociations,
      payment,
    });
    res.status(201).json(result);
  } catch (e) {
    next(e);
  }
}
