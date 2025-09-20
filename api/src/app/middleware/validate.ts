import { ZodObject } from 'zod';
import { Request, Response, NextFunction } from 'express';

export const validate =
  (schema: ZodObject<any>) => (req: Request, res: Response, next: NextFunction) => {
    const parsed = schema.safeParse({
      body: req.body,
      query: req.query,
      params: req.params,
      headers: req.headers,
    });
    if (!parsed.success) {
      return res.status(422).json({
        error: 'VALIDATION_ERROR',
        details: parsed.error.issues,
      });
    }
    next();
  };
