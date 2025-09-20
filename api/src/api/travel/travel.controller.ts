import { Request, Response, NextFunction } from 'express';
import * as svc from '../../domain/travel/travel.service';

export async function searchLocations(req: Request, res: Response, next: NextFunction) {
  try {
    const { subType, keyword } = req.query as any;
    const result = await svc.searchLocations({
      subType,
      keyword,
    });
    res.json(result);
  } catch (e) {
    next(e);
  }
}
