import axios from 'axios';
import axiosRetry from 'axios-retry';
import { env } from './env';

export const http = axios.create({
  timeout: env.REQUEST_TIMEOUT_MS,
  // Accept all status codes for better error handling
  validateStatus: () => true,
});

axiosRetry(http, {
  retries: 2,
  retryDelay: axiosRetry.exponentialDelay,
  retryCondition: (e) => axiosRetry.isNetworkOrIdempotentRequestError(e),
});
