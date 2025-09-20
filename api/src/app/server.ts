import 'dotenv/config';
import { createApp } from './app';
import { env } from '../config/env';
import { logger } from '../utils/logger';

const app = createApp();

app.listen(env.PORT, () => {
  logger.info(`API listening on port ${env.PORT}`);

  // Test logger
  logger.info('Application started successfully');
});

export default app;
