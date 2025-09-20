import express from 'express';
import { routes } from './routes';
import { errorHandler } from './middleware/error-handler';
import { requestLogger } from './middleware/request-logger';

export const createApp = () => {
  const app = express();
  app.disable('x-powered-by');
  app.use(express.json({ limit: '1mb' }));

  // Add request logging
  app.use(requestLogger);

  app.use('/api', routes());

  // dernier middleware: gestion d'erreurs
  app.use(errorHandler(process.env.NODE_ENV || 'development'));
  return app;
};
