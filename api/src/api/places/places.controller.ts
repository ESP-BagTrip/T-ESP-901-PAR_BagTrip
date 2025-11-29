import { Request, Response, NextFunction } from 'express';
import * as svc from '../../domain/places/places.service';

export async function searchNearbyPlaces(req: Request, res: Response, next: NextFunction) {
  try {
    const { latitude, longitude, radius, types, maxResults, rankBy, language, source } = req.query as any;

    const result = await svc.searchNearby({
      latitude: Number(latitude),
      longitude: Number(longitude),
      radius: radius !== undefined ? Number(radius) : undefined,
      types: types,
      maxResults: maxResults !== undefined ? Number(maxResults) : undefined,
      rankBy: rankBy,
      language: language,
      source: source,
    });

    res.json(result);
  } catch (e) {
    next(e);
  }
}

export async function searchPlacesByText(req: Request, res: Response, next: NextFunction) {
  try {
    const { q, latitude, longitude, radius, type, maxResults, language, minRating, openNow } = req.query as any;

    const result = await svc.searchByText({
      query: q,
      latitude: latitude !== undefined ? Number(latitude) : undefined,
      longitude: longitude !== undefined ? Number(longitude) : undefined,
      radius: radius !== undefined ? Number(radius) : undefined,
      type: type,
      maxResults: maxResults !== undefined ? Number(maxResults) : undefined,
      language: language,
      minRating: minRating !== undefined ? Number(minRating) : undefined,
      openNow: openNow,
    });

    res.json(result);
  } catch (e) {
    next(e);
  }
}

export async function getPlaceDetails(req: Request, res: Response, next: NextFunction) {
  try {
    const { placeId } = req.params as any;
    const { language } = req.query as any;

    const result = await svc.getPlaceDetails({
      placeId: placeId,
      language: language,
    });

    res.json(result);
  } catch (e) {
    next(e);
  }
}
