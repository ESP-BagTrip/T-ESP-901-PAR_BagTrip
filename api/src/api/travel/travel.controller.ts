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
