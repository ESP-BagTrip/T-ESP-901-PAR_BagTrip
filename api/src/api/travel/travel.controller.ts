import { Request, Response, NextFunction } from 'express';
import * as svc from '../../domain/travel/travel.service';

export async function searchLocationsByKeyword(req: Request, res: Response, next: NextFunction) {
  try {
    const { subType, keyword } = req.query as any;
    const result = await svc.searchLocationsByKeyword({
      subType,
      keyword,
    });
    res.json(result);
  } catch (e) {
    next(e);
  }
}

export async function searchLocationById(req: Request, res: Response, next: NextFunction) {
  try {
    const { id } = req.params as any;
    const result = await svc.searchLocationById({ id });
    res.json(result);
  } catch (e) {
    next(e);
  }
}

export async function searchLocationNearest(req: Request, res: Response, next: NextFunction) {
  try {
    const { latitude, longitude } = req.query as any;
    const result = await svc.searchLocationNearest({
      latitude: Number(latitude),
      longitude: Number(longitude),
    });
    res.json(result);
  } catch (e) {
    next(e);
  }
}

// ============================================================================
// FLIGHT CONTROLLERS
// ============================================================================

export async function searchFlightOffers(req: Request, res: Response, next: NextFunction) {
  try {
    const {
      originLocationCode,
      destinationLocationCode,
      departureDate,
      adults,
      returnDate,
      children,
      infants,
      travelClass,
      nonStop,
      currencyCode,
      maxPrice,
      max,
      includedAirlineCodes,
      excludedAirlineCodes,
    } = req.query as any;

    const result = await svc.searchFlightOffers({
      originLocationCode,
      destinationLocationCode,
      departureDate,
      adults: Number(adults),
      returnDate,
      children: children !== undefined ? Number(children) : undefined,
      infants: infants !== undefined ? Number(infants) : undefined,
      travelClass,
      nonStop,
      currencyCode,
      maxPrice: maxPrice !== undefined ? Number(maxPrice) : undefined,
      max: max !== undefined ? Number(max) : undefined,
      includedAirlineCodes,
      excludedAirlineCodes,
    });
    res.json(result);
  } catch (e) {
    next(e);
  }
}

export async function searchFlightDestinations(req: Request, res: Response, next: NextFunction) {
  try {
    const { origin, departureDate, oneWay, duration, nonStop, maxPrice, viewBy } =
      req.query as any;

    const result = await svc.searchFlightDestinations({
      origin,
      departureDate,
      oneWay,
      duration: duration !== undefined ? Number(duration) : undefined,
      nonStop,
      maxPrice: maxPrice !== undefined ? Number(maxPrice) : undefined,
      viewBy,
    });
    res.json(result);
  } catch (e) {
    next(e);
  }
}

export async function searchFlightCheapestDates(req: Request, res: Response, next: NextFunction) {
  try {
    const { origin, destination, departureDate, oneWay, duration, nonStop, maxPrice, viewBy } =
      req.query as any;

    const result = await svc.searchFlightCheapestDates({
      origin,
      destination,
      departureDate,
      oneWay,
      duration: duration !== undefined ? Number(duration) : undefined,
      nonStop,
      maxPrice: maxPrice !== undefined ? Number(maxPrice) : undefined,
      viewBy,
    });
    res.json(result);
  } catch (e) {
    next(e);
  }
}
