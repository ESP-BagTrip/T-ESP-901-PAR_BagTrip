import { Request, Response, NextFunction } from 'express';
import { logger } from '../../utils/logger';

export const errorHandler =
  (env: string) => (err: any, req: Request, res: Response, next: NextFunction) => {
    const status = err.status ?? 500;

    // Log the error with full details
    logger.error('Request error occurred', {
      method: req.method,
      url: req.url,
      status,
      error: err.message,
      stack: err.stack,
      detail: err.detail,
      body: req.body,
      query: req.query,
      params: req.params,
    });

    const body: any = { error: err.code ?? 'INTERNAL_ERROR' };
    if (env !== 'production') {
      body.message = err.message;
      body.stack = err.stack;
      body.detail = err.detail;
    }
    res.status(status).json(body);
    next();
  };
