import { Request, Response, NextFunction } from 'express';
import * as svc from '../../domain/hotel/hotel.service';

export async function searchHotelsByCity(req: Request, res: Response, next: NextFunction) {
  try {
    const { cityCode, radius, radiusUnit, chainCodes, amenities, ratings, hotelSource } =
      req.query as any;
    const result = await svc.searchHotelsByCity({
      cityCode,
      radius: radius !== undefined ? Number(radius) : undefined,
      radiusUnit,
      chainCodes,
      amenities,
      ratings,
      hotelSource,
    });
    res.json(result);
  } catch (e) {
    next(e);
  }
}

export async function searchHotelOffers(req: Request, res: Response, next: NextFunction) {
  try {
    const {
      hotelIds,
      adults,
      checkInDate,
      checkOutDate,
      roomQuantity,
      priceRange,
      currency,
      paymentPolicy,
      boardType,
      includeClosed,
      bestRateOnly,
    } = req.query as any;

    const result = await svc.searchHotelOffers({
      hotelIds,
      adults: Number(adults),
      checkInDate,
      checkOutDate,
      roomQuantity: roomQuantity !== undefined ? Number(roomQuantity) : undefined,
      priceRange,
      currency,
      paymentPolicy,
      boardType,
      includeClosed,
      bestRateOnly,
    });
    res.json(result);
  } catch (e) {
    next(e);
  }
}

export async function getHotelOfferDetails(req: Request, res: Response, next: NextFunction) {
  try {
    const { offerId } = req.params as any;
    const result = await svc.getHotelOfferDetails({ offerId });
    res.json(result);
  } catch (e) {
    next(e);
  }
}
